import 'package:firebase_core/firebase_core.dart';

// CI-only placeholders; never use for a device build or release.
class DefaultFirebaseOptions {
  static const currentPlatform = FirebaseOptions(
    apiKey: 'ci-not-a-real-api-key',
    appId: '1:0:ios:ci',
    messagingSenderId: '0',
    projectId: 'demo-pettomo-ci',
  );
}
