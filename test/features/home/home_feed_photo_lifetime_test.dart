import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home retains feed photos until animation releases them', () {
    // Run the actual terminal handlers without Home's platform services/realtime.
    final source = File(
      'lib/features/home/controllers/home_feed_orchestrator.dart',
    ).readAsStringSync();
    final methods =
        [
          '_handleQueuedFeedCompleted',
          '_handleQueuedFeedFailed',
          '_acknowledgeQueuedFeed',
        ].map((name) {
          final match = RegExp(
            '  (?:Future<void>|void) $name'
            r'\([\s\S]*?\n  \}(?=\n)',
          ).firstMatch(source);
          if (name != '_acknowledgeQueuedFeed') expect(match, isNotNull);
          return match?.group(0) ?? '';
        });
    final directory = Directory.systemTemp.createTempSync('feed_lifetime_');
    try {
      final harness = File('${directory.path}/harness.dart')
        ..writeAsStringSync(
          _harness.replaceFirst('// METHODS', methods.join('\n')),
        );
      final root = Platform.environment['FLUTTER_ROOT'];
      final result = Process.runSync(root == null ? 'dart' : '$root/bin/dart', [
        harness.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect('PASS '.allMatches(result.stdout as String), hasLength(5));
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
}

const _harness = r'''
import 'dart:async';
import 'dart:io';

class FeedUploadJob {
  FeedUploadJob(this.localImagePath);
  final String localImagePath;
  final String tempId = 'job';
}
class FeedUploadResult {
  FeedUploadResult copyWith({required bool reconciled}) => this;
}
class FeedUploadCompleted {
  FeedUploadCompleted(this.job);
  final FeedUploadJob job;
  final result = FeedUploadResult();
}
class FeedUploadFailed {
  FeedUploadFailed(this.job);
  final FeedUploadJob job;
  final error = Exception('upload failed');
}
class Queue {
  Queue(this.photo);
  final File photo;
  var acknowledgements = 0;
  Future<void> acknowledge(String id) async {
    if (await photo.exists()) await photo.delete();
    acknowledgements++;
  }
}
class Home {
  Home(this._feedUploadQueue);
  final Queue _feedUploadQueue;
  final _handledFeedUploadTerminalTempIds = <String>{};
  String? _photoFoodImageSource;
  bool mounted = true;
  void _handleFeedUploadCompleted(FeedUploadResult result) {}
  void _handleFeedUploadFailed(String id, Object error) {}
  // METHODS
}
void check(bool value, String message) {
  if (!value) throw StateError(message);
}
Future<void> main() async {
  final directory = await Directory.systemTemp.createTemp('feed_photos_');
  try {
    for (final scenario in ['complete', 'failed', 'replaced', 'disposed', 'unrelated']) {
      final photo = await File('${directory.path}/$scenario.image').writeAsBytes([1, 2, 3]);
      final job = FeedUploadJob(photo.path);
      final queue = Queue(photo);
      final home = Home(queue).._photoFoodImageSource = scenario == 'unrelated' ? '/other.image' : photo.path;
      try {
        if (scenario == 'failed') {
          home._handleQueuedFeedFailed(FeedUploadFailed(job));
        } else {
          home._handleQueuedFeedCompleted(FeedUploadCompleted(job));
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (scenario != 'unrelated') {
          check(await photo.exists(), '$scenario deleted the photo before animation finished');
          check(queue.acknowledgements == 0, '$scenario acknowledged too soon');
          if (scenario == 'disposed') {
            home.mounted = false;
          } else {
            home._photoFoodImageSource = scenario == 'replaced' ? '/next.image' : null;
          }
        }
        final deadline = DateTime.now().add(const Duration(seconds: 2));
        while (queue.acknowledgements == 0 && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        check(queue.acknowledgements == 1, '$scenario never acknowledged after release');
        check(!await photo.exists(), '$scenario leaked its released photo');
        print('PASS $scenario');
      } finally {
        home.mounted = false;
      }
    }
  } finally {
    await directory.delete(recursive: true);
  }
}
''';
