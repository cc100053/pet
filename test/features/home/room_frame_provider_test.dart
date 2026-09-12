import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pet/features/home/providers/room_frame_provider.dart';
import 'package:pet/features/home/widgets/room_frame_skins.dart';
import 'package:pet/services/settings/app_settings_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousOverrides = HttpOverrides.current;
  late Directory directory;
  late HttpServer server;
  late SupabaseClient client;
  late ProviderContainer container;
  late Future<Object> Function(HttpRequest) respond;
  late List<String> methods;

  Map<String, Object> row(String style, int second) => {
    'room_id': 'room-1',
    'style': style,
    'updated_at': DateTime.utc(2026, 9, 13, 0, 0, second).toIso8601String(),
  };

  setUpAll(() async {
    // Exercise the real PostgREST request/parser against a local HTTP server.
    HttpOverrides.global = null;
    directory = await Directory.systemTemp.createTemp('shared-room-frame-test');
    Hive.init(directory.path);
    await AppSettingsRepository.instance.init();
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    HttpOverrides.global = previousOverrides;
  });

  setUp(() async {
    await Hive.box<dynamic>('app_settings').clear();
    await AppSettingsRepository.instance.setRoomFrameStyle(
      'room-1',
      'polaroid_classic',
    );
    methods = [];
    respond = (_) async => <Object>[];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      methods.add(request.method);
      final body = await respond(request);
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(body));
      await request.response.close();
    });
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'test-key');
    container = ProviderContainer(
      overrides: [roomFrameClientProvider.overrideWithValue(client)],
    );
  });

  tearDown(() async {
    container.dispose();
    await client.dispose();
    await server.close(force: true);
  });

  test('legacy fallback is read-only until explicit confirmation', () async {
    final notifier = container.read(roomFrameProvider.notifier);
    await notifier.refresh(['room-1']);
    expect(
      container.read(roomFrameProvider)['room-1'],
      RoomFrameStyle.polaroidClassic,
    );
    expect(methods, ['GET']);
    respond = (request) async {
      expect(jsonDecode(await utf8.decoder.bind(request).join()), {
        'room_id': 'room-1',
        'style': 'polaroid_classic',
      });
      return row('polaroid_classic', 1);
    };
    await notifier.equip('room-1', RoomFrameStyle.polaroidClassic);
    expect(methods, ['GET', 'POST']);
  });

  test(
    'shared refresh replaces cache and unknown styles safely fall back',
    () async {
      final notifier = container.read(roomFrameProvider.notifier);
      respond = (_) async => [row('gold_leaf', 1)];
      await notifier.refresh(['room-1']);
      expect(
        container.read(roomFrameProvider)['room-1'],
        RoomFrameStyle.goldLeaf,
      );
      expect(
        AppSettingsRepository.instance.roomFrameStyles['room-1'],
        'gold_leaf',
      );
      respond = (_) async => [row('future_frame', 2)];
      await notifier.refresh(['room-1']);
      expect(
        container.read(roomFrameProvider)['room-1'],
        RoomFrameStyle.original,
      );
      expect(methods, ['GET', 'GET']);
    },
  );

  test('failed save leaves provider and durable cache unchanged', () async {
    respond = (request) async {
      request.response.statusCode = 403;
      return {'code': '42501', 'message': 'room_frame_level_required'};
    };
    final notifier = container.read(roomFrameProvider.notifier);
    await expectLater(
      notifier.equip('room-1', RoomFrameStyle.goldLeaf),
      throwsA(isA<PostgrestException>()),
    );
    expect(
      container.read(roomFrameProvider)['room-1'],
      RoomFrameStyle.polaroidClassic,
    );
    expect(
      AppSettingsRepository.instance.roomFrameStyles['room-1'],
      'polaroid_classic',
    );
  });

  test(
    'slow snapshots cannot overwrite a newer save or a stopped session',
    () async {
      final notifier = container.read(roomFrameProvider.notifier);
      final started = Completer<void>();
      final snapshot = Completer<Object>();
      respond = (request) async {
        if (request.method == 'GET') {
          started.complete();
          return snapshot.future;
        }
        return row('night_glow', 2);
      };
      final refresh = notifier.refresh(['room-1']);
      await started.future;
      await notifier.equip('room-1', RoomFrameStyle.nightGlow);
      snapshot.complete([row('gold_leaf', 1)]);
      await refresh;
      expect(
        container.read(roomFrameProvider)['room-1'],
        RoomFrameStyle.nightGlow,
      );

      final secondStarted = Completer<void>();
      final secondSnapshot = Completer<Object>();
      respond = (_) async {
        secondStarted.complete();
        return secondSnapshot.future;
      };
      final stoppedRefresh = notifier.refresh(['room-1']);
      await secondStarted.future;
      notifier.stopSync();
      secondSnapshot.complete([row('corkboard', 3)]);
      await stoppedRefresh;
      expect(
        container.read(roomFrameProvider)['room-1'],
        RoomFrameStyle.nightGlow,
      );
    },
  );
}
