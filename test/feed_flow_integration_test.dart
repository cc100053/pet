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

  static _TestEnv load({Map<String, String>? environment}) {
    final processEnv = environment ?? Platform.environment;
    // Credentials alone must never authorize writes during the normal suite.
    if (processEnv['PET_RUN_LIVE_FEED_TEST'] != '1') {
      return _TestEnv(
        supabaseUrl: null,
        supabaseAnonKey: null,
        refreshToken: null,
        skipReason: 'Set PET_RUN_LIVE_FEED_TEST=1 for an authorized live test.',
      );
    }

    final envFile = File('.env');
    if (envFile.existsSync()) {
      dotenv.loadFromString(envString: envFile.readAsStringSync());
    }

    String? readEnv(String key) {
      final value = (processEnv[key] ?? dotenv.env[key])?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    final url = readEnv('SUPABASE_URL');
    final anonKey = readEnv('SUPABASE_ANON_KEY');
    final refreshToken = readEnv('SUPABASE_TEST_REFRESH_TOKEN');

    String? skip;
    if (url == null || anonKey == null || refreshToken == null) {
      skip =
          'Set SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_TEST_REFRESH_TOKEN.';
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

  test('credentials alone do not enable live service writes', () {
    final config = _TestEnv.load(
      environment: {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'fake-key',
        'SUPABASE_TEST_REFRESH_TOKEN': 'fake-token',
      },
    );
    expect(config.skipReason, contains('PET_RUN_LIVE_FEED_TEST=1'));
    expect(config.refreshToken, isNull);
  });

  test('explicit opt-in still requires nonblank credentials', () {
    final config = _TestEnv.load(
      environment: {
        'PET_RUN_LIVE_FEED_TEST': '1',
        'SUPABASE_URL': '',
        'SUPABASE_ANON_KEY': ' ',
        'SUPABASE_TEST_REFRESH_TOKEN': '',
      },
    );
    expect(config.skipReason, contains('SUPABASE_TEST_REFRESH_TOKEN'));
  });

  test('explicit opt-in loads the supplied test credentials', () {
    final config = _TestEnv.load(
      environment: {
        'PET_RUN_LIVE_FEED_TEST': '1',
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'SUPABASE_ANON_KEY': 'fake-key',
        'SUPABASE_TEST_REFRESH_TOKEN': 'fake-token',
      },
    );
    expect(config.skipReason, isNull);
    expect(config.refreshToken, 'fake-token');
  });

  test('feed_validate writes message to chat', () async {
    final client = SupabaseClient(env.supabaseUrl!, env.supabaseAnonKey!);
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
  }, skip: env.skipReason);
}
