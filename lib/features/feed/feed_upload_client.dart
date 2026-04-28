import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth/session_utils.dart';
import '../../shared/upload_limits.dart';
import 'feed_reconciliation.dart';
import 'feed_upload_models.dart';

abstract class FeedUploadClient {
  Future<FeedUploadResult?> findCompletedUpload(FeedUploadJob job);

  Future<FeedUploadResult> upload(FeedUploadJob job, {Uint8List? initialBytes});
}

class SupabaseFeedUploadClient implements FeedUploadClient {
  SupabaseFeedUploadClient({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const int _feedCompressionTargetBytes = 5 * 1024 * 1024;
  static const int _feedCompressionMinBytesToAttempt = 512 * 1024;
  static const List<_FeedCompressionProfile> _feedCompressionProfiles =
      <_FeedCompressionProfile>[
        _FeedCompressionProfile(maxDimension: 2048, quality: 90),
        _FeedCompressionProfile(maxDimension: 1920, quality: 84),
        _FeedCompressionProfile(maxDimension: 1600, quality: 78),
      ];
  static const List<_FeedCompressionProfile> _feedCompressionEmergencyProfiles =
      <_FeedCompressionProfile>[
        _FeedCompressionProfile(maxDimension: 1400, quality: 70),
        _FeedCompressionProfile(maxDimension: 1280, quality: 66),
        _FeedCompressionProfile(maxDimension: 1080, quality: 62),
      ];

  final SupabaseClient _client;

  @override
  Future<FeedUploadResult?> findCompletedUpload(FeedUploadJob job) async {
    final createdAt = job.clientCreatedAt.toUtc();
    final lower = createdAt
        .subtract(kFeedClientCreatedAtTolerance)
        .toIso8601String();
    final upper = createdAt
        .add(kFeedClientCreatedAtTolerance)
        .toIso8601String();
    final rows = await _client
        .from('messages')
        .select(
          'id,image_url,caption,coins_awarded,client_created_at,created_at',
        )
        .eq('room_id', job.roomId)
        .eq('sender_id', job.senderId)
        .eq('type', 'image_feed')
        .gte('client_created_at', lower)
        .lte('client_created_at', upper)
        .order('created_at', ascending: false)
        .limit(5);

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      if (!matchesFeedIdentity(
        expectedRoomId: job.roomId,
        expectedSenderId: job.senderId,
        expectedCaption: job.caption,
        expectedClientCreatedAt: job.clientCreatedAt,
        roomId: job.roomId,
        senderId: job.senderId,
        caption: map['caption'] as String?,
        messageId: map['id'] as String?,
        clientCreatedAt: parseFeedDate(map['client_created_at']),
        createdAt: parseFeedDate(map['created_at']),
      )) {
        continue;
      }
      final imageUrl = map['image_url'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) {
        continue;
      }
      return FeedUploadResult(
        tempId: job.tempId,
        coinsAwarded: _parseInt(map['coins_awarded']),
        messageId: _parseString(map['id']),
        imageUrl: imageUrl,
        rewardStatus: 'reconciled',
        reconciled: true,
      );
    }
    return null;
  }

  @override
  Future<FeedUploadResult> upload(
    FeedUploadJob job, {
    Uint8List? initialBytes,
  }) async {
    final originalBytes =
        initialBytes ?? await XFile(job.localImagePath).readAsBytes();
    final compressed = await _compressForUpload(
      path: job.localImagePath,
      originalBytes: originalBytes,
    );
    final imageContentType = compressed.contentType;
    final imageBytes = compressed.bytes;
    if (!kAllowedUploadImageContentTypes.contains(imageContentType)) {
      throw Exception('invalid_image_content_type');
    }
    if (imageBytes.length > kMaxUploadImageBytes) {
      throw Exception('image_too_large');
    }
    final dataUri = 'data:$imageContentType;base64,${base64Encode(imageBytes)}';

    Future<FunctionResponse> invokeWithToken(String token) {
      return _client.functions.invoke(
        'feed_validate',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'room_id': job.roomId,
          'labels': job.labels,
          'canonical_tags': const <String>[],
          'caption': job.caption,
          'image_base64': dataUri,
          'image_content_type': imageContentType,
          'client_created_at': job.clientCreatedAt.toUtc().toIso8601String(),
        },
      );
    }

    final accessToken = await ensureValidAccessToken();
    if (accessToken == null) {
      throw Exception('missing_session');
    }

    FunctionResponse response;
    try {
      response = await invokeWithToken(accessToken);
    } on FunctionException catch (error) {
      if (error.status != 401) {
        rethrow;
      }
      final refreshed = await ensureValidAccessTokenWithDebug(
        forceRefresh: true,
      );
      final refreshedToken = refreshed.token;
      if (refreshedToken == null) {
        rethrow;
      }
      response = await invokeWithToken(refreshedToken);
    }

    if (response.status < 200 || response.status >= 300) {
      throw Exception(
        'feed_validate_failed:${_responseErrorSummary(response)}',
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('feed_validate_invalid_response');
    }
    if (data['ok'] != true) {
      throw Exception('feed_validate_rejected');
    }
    final cooldownPayload = data['cooldown'];
    final cooldown = cooldownPayload is Map<String, dynamic>
        ? cooldownPayload
        : <String, dynamic>{};

    return FeedUploadResult(
      tempId: job.tempId,
      coinsAwarded: _parseInt(data['coins_awarded']),
      messageId: _parseString(data['message_id']),
      imageUrl: _parseString(data['image_url']),
      rewardStatus: _parseString(data['reward_status']),
      cooldownActive: cooldown['is_active'] == true,
      lastFedAt: _parseString(cooldown['last_fed_at']),
      nextEligibleAt: _parseString(cooldown['next_eligible_at']),
    );
  }

  String _responseErrorSummary(FunctionResponse response) {
    final data = response.data;
    if (data is Map) {
      final error = data['error']?.toString();
      final detail = data['detail']?.toString();
      if (error != null && error.isNotEmpty) {
        if (detail != null && detail.isNotEmpty) {
          return '$error:$detail';
        }
        return error;
      }
    }
    return 'status_${response.status}';
  }

  String _contentTypeForPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  String _detectImageContentType(Uint8List bytes, String path) {
    if (_isPng(bytes)) {
      return 'image/png';
    }
    if (_isJpeg(bytes)) {
      return 'image/jpeg';
    }
    if (_isWebp(bytes)) {
      return 'image/webp';
    }
    if (_isHeicOrHeif(bytes)) {
      return 'image/heic';
    }
    return _contentTypeForPath(path);
  }

  bool _isJpeg(Uint8List bytes) {
    return bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;
  }

  bool _isPng(Uint8List bytes) {
    return bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A;
  }

  bool _isWebp(Uint8List bytes) {
    if (bytes.length < 12) {
      return false;
    }
    final riff =
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46;
    final webp =
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    return riff && webp;
  }

  bool _isHeicOrHeif(Uint8List bytes) {
    if (bytes.length < 12) {
      return false;
    }
    final hasFtyp =
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70;
    if (!hasFtyp) {
      return false;
    }
    final brand = String.fromCharCodes(bytes.sublist(8, 12));
    const heifBrands = <String>{
      'heic',
      'heix',
      'hevc',
      'hevx',
      'heim',
      'heis',
      'mif1',
      'msf1',
    };
    return heifBrands.contains(brand);
  }

  Future<_CompressedImage> _compressForUpload({
    required String path,
    required Uint8List originalBytes,
  }) async {
    final detectedContentType = _detectImageContentType(originalBytes, path);
    if (kIsWeb || originalBytes.length < _feedCompressionMinBytesToAttempt) {
      return _CompressedImage(
        bytes: originalBytes,
        contentType: detectedContentType,
      );
    }

    Uint8List? bestCandidate;
    for (final profile in _feedCompressionProfiles) {
      final candidate = await _compressWithProfile(originalBytes, profile);
      if (candidate == null || candidate.length >= originalBytes.length) {
        continue;
      }
      if (bestCandidate == null || candidate.length < bestCandidate.length) {
        bestCandidate = candidate;
      }
      if (candidate.length <= _feedCompressionTargetBytes ||
          candidate.length <= kMaxUploadImageBytes) {
        return _CompressedImage(bytes: candidate, contentType: 'image/webp');
      }
    }

    if (originalBytes.length > kMaxUploadImageBytes) {
      for (final profile in _feedCompressionEmergencyProfiles) {
        final candidate = await _compressWithProfile(originalBytes, profile);
        if (candidate == null || candidate.isEmpty) {
          continue;
        }
        if (candidate.length <= kMaxUploadImageBytes) {
          return _CompressedImage(bytes: candidate, contentType: 'image/webp');
        }
        if (bestCandidate == null || candidate.length < bestCandidate.length) {
          bestCandidate = candidate;
        }
      }
      if (bestCandidate != null) {
        return _CompressedImage(
          bytes: bestCandidate,
          contentType: 'image/webp',
        );
      }
    }

    return _CompressedImage(
      bytes: originalBytes,
      contentType: detectedContentType,
    );
  }

  Future<Uint8List?> _compressWithProfile(
    Uint8List bytes,
    _FeedCompressionProfile profile,
  ) async {
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: profile.quality,
        minWidth: profile.maxDimension,
        minHeight: profile.maxDimension,
        format: CompressFormat.webp,
      );
      if (compressed.isEmpty) {
        return null;
      }
      return compressed;
    } catch (_) {
      return null;
    }
  }
}

class _CompressedImage {
  const _CompressedImage({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

class _FeedCompressionProfile {
  const _FeedCompressionProfile({
    required this.maxDimension,
    required this.quality,
  });

  final int maxDimension;
  final int quality;
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String? _parseString(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}
