import 'package:hive_flutter/hive_flutter.dart';

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
        .toList(growable: false);
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
    await box.delete(tempId);
  }
}
