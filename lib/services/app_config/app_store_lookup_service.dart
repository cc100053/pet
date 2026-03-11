import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_store_lookup_http_client_stub.dart'
    if (dart.library.io) 'app_store_lookup_http_client_io.dart';

class AppStoreVersionLookupResult {
  const AppStoreVersionLookupResult({
    required this.version,
    required this.storeUrl,
  });

  final String version;
  final String storeUrl;
}

typedef AppStoreLookupBodyLoader = Future<String?> Function(Uri uri);

class AppStoreVersionLookupService {
  AppStoreVersionLookupService({
    AppStoreLookupBodyLoader? bodyLoader,
    String? preferredCountryCode,
    this.appId = '6757725650',
    this.fallbackStoreUrl = 'https://apps.apple.com/app/id6757725650',
  }) : _bodyLoader = bodyLoader ?? fetchAppStoreLookupBody,
       _preferredCountryCode = preferredCountryCode;

  final AppStoreLookupBodyLoader _bodyLoader;
  final String? _preferredCountryCode;
  final String appId;
  final String fallbackStoreUrl;

  Future<AppStoreVersionLookupResult?> fetchLatestVersion() async {
    for (final uri in buildLookupUris()) {
      try {
        final body = await _bodyLoader(uri);
        final result = parseLookupResponse(
          body,
          fallbackStoreUrl: fallbackStoreUrl,
        );
        if (result != null) {
          return result;
        }
      } catch (_) {
        // Best effort. We'll try the next storefront candidate.
      }
    }
    return null;
  }

  @visibleForTesting
  List<Uri> buildLookupUris() {
    final countries = <String?>[
      _normalizedCountryCode(_preferredCountryCode),
      _normalizedCountryCode(PlatformDispatcher.instance.locale.countryCode),
      'JP',
      'US',
      null,
    ];
    final seen = <String>{};
    final uris = <Uri>[];
    for (final country in countries) {
      final dedupeKey = country ?? '_default';
      if (!seen.add(dedupeKey)) {
        continue;
      }
      uris.add(
        Uri.https('itunes.apple.com', '/lookup', {
          'id': appId,
          ...?country == null ? null : {'country': country},
        }),
      );
    }
    return uris;
  }

  @visibleForTesting
  static AppStoreVersionLookupResult? parseLookupResponse(
    String? body, {
    required String fallbackStoreUrl,
  }) {
    if (body == null || body.trim().isEmpty) {
      return null;
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final results = decoded['results'];
    if (results is! List || results.isEmpty) {
      return null;
    }
    final first = results.first;
    if (first is! Map) {
      return null;
    }
    final rawVersion = first['version']?.toString().trim();
    if (rawVersion == null || rawVersion.isEmpty) {
      return null;
    }
    final rawStoreUrl = first['trackViewUrl']?.toString().trim();
    return AppStoreVersionLookupResult(
      version: rawVersion,
      storeUrl: (rawStoreUrl == null || rawStoreUrl.isEmpty)
          ? fallbackStoreUrl
          : rawStoreUrl,
    );
  }

  String? _normalizedCountryCode(String? countryCode) {
    final normalized = countryCode?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
