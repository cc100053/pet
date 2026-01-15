import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _TestEnv {
  _TestEnv({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.refreshToken,
    required this.skipReason,
  });

  final String? supabaseUrl;
  final String? supabaseAnonKey;
  final String? refreshToken;
  final String? skipReason;

  static _TestEnv load() {
    final envFile = File('.env');
    if (envFile.existsSync()) {
      dotenv.testLoad(fileInput: envFile.readAsStringSync());
    }

    String? readEnv(String key) =>
        Platform.environment[key] ?? dotenv.env[key];

    final url = readEnv('SUPABASE_URL');
    final anonKey = readEnv('SUPABASE_ANON_KEY');
    final refreshToken = readEnv('SUPABASE_TEST_REFRESH_TOKEN');

    String? skip;
    if (url == null || anonKey == null || refreshToken == null) {
      skip = 'Set SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_TEST_REFRESH_TOKEN.';
    }

    return _TestEnv(
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      refreshToken: refreshToken,
      skipReason: skip,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final env = _TestEnv.load();

  test(
    'feed_validate writes message to chat',
    () async {
      final client = SupabaseClient(
        env.supabaseUrl!,
        env.supabaseAnonKey!,
      );
      String? roomId;
      try {
        final authResponse = await client.auth.setSession(env.refreshToken!);
        final session = authResponse.session;
        expect(session, isNotNull);

        final accessToken = session!.accessToken;
        client.functions.setAuth(accessToken);

        final roomResponse = await client
            .rpc('create_room', params: {'p_name': 'Integration Test Room'})
            .single();
        roomId = roomResponse['room_id'] as String?;
        expect(roomId, isNotNull);

        final imageUrl = 'https://example.com/test.jpg';
        final response = await client.functions.invoke(
          'feed_validate',
          body: {
            'room_id': roomId,
            'labels': [
              {
                'text': 'Coffee',
                'confidence': 0.95,
                'canonical_tag': 'beverage.coffee',
              },
              {
                'text': 'Cup',
                'confidence': 0.7,
                'canonical_tag': 'beverage.coffee',
              },
            ],
            'canonical_tags': ['beverage.coffee'],
            'caption': 'Integration test feed',
            'image_url': imageUrl,
            'client_created_at': DateTime.now().toUtc().toIso8601String(),
          },
        );

        expect(response.status, 200);
        final data = response.data;
        expect(data, isA<Map<String, dynamic>>());
        final payload = Map<String, dynamic>.from(data as Map);
        final messageId = payload['message_id'] as String?;
        expect(messageId, isNotNull);

        final message = await client
            .from('messages')
            .select('id, room_id, type, image_url')
            .eq('id', messageId!)
            .maybeSingle();

        expect(message, isNotNull);
        expect(message?['room_id'], roomId);
        expect(message?['type'], 'image_feed');
        expect(message?['image_url'], imageUrl);
      } finally {
        try {
          if (roomId != null) {
            await client.from('rooms').delete().eq('id', roomId);
          }
        } catch (_) {}
        await client.dispose();
      }
    },
    skip: env.skipReason,
  );
}
