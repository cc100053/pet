import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureRequestService {
  static Future<void> submit(String body) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    final info = await PackageInfo.fromPlatform();
    await client.from('feature_requests').insert({
      'user_id': userId,
      'body': body.trim(),
      'app_version': info.version,
    });
  }
}
