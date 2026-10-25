import 'dart:io';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/errors/user_facing_error.dart';
import 'feed_upload_models.dart';

class FeedUploadRepository {
  FeedUploadRepository({Box<dynamic>? box}) : _box = box;

  static final FeedUploadRepository instance = FeedUploadRepository();
  static const String boxName = 'feed_upload_jobs';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(boxName);
  }

  List<FeedUploadJob> loadJobs() {
    final box = _box;
    if (box == null) {
      return const <FeedUploadJob>[];
    }
    return box.values
        .whereType<Map>()
        .map(
          (entry) => FeedUploadJob.fromJson(Map<String, dynamic>.from(entry)),
        )
        .where((job) => job.tempId.isNotEmpty && job.roomId.isNotEmpty)
        .map((job) {
          // iOS can move the app container during an upgrade.
          final image = _imageFile(job.tempId);
          return image.existsSync()
              ? job.copyWith(localImagePath: image.path)
              : job;
        })
        .toList(growable: false);
  }

  File _imageFile(String tempId) => File(
    '${File(_box!.path!).parent.path}/feed_upload_images/${Uri.encodeComponent(tempId)}.image',
  );

  Future<String> saveImage(
    String tempId,
    String sourcePath, {
    Uint8List? bytes,
  }) async {
    final image = _imageFile(tempId);
    if (await image.exists()) {
      return image.path;
    }
    await image.parent.create(recursive: true);
    final staging = File('${image.path}.pending');
    try {
      if (bytes == null) {
        await File(sourcePath).copy(staging.path);
      } else {
        await staging.writeAsBytes(bytes, flush: true);
      }
      await staging.rename(image.path);
    } catch (_) {
      await _deleteImage(staging);
      rethrow;
    }
    return image.path;
  }

  Future<void> deleteImage(String tempId) async {
    await _deleteImage(_imageFile(tempId));
  }

  Future<void> _deleteImage(File image) async {
    try {
      if (await image.exists()) {
        await image.delete();
      }
    } catch (error, stackTrace) {
      reportSwallowedError(
        error,
        stackTrace,
        source: 'feed_upload_photo_cleanup',
      );
    }
  }

  Future<void> saveJob(FeedUploadJob job) async {
    final box = _box;
    if (box == null) {
      return;
    }
    await box.put(job.tempId, job.toJson());
  }

  Future<void> deleteJob(String tempId) async {
    final box = _box;
    if (box == null) {
      return;
    }
    await deleteImage(tempId);
    await box.delete(tempId);
  }
}
