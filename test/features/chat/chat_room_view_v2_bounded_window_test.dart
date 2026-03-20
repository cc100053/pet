import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/features/chat/chat_room_view_runtime.dart';
import 'package:pet/features/chat/chat_room_view_v2.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/services/chat/chat_message_repository.dart';
import 'package:pet/services/profile/profile_cache_service.dart';

class _FetchCall {
  const _FetchCall({this.beforeCreatedAt, this.beforeId, required this.limit});

  final String? beforeCreatedAt;
  final String? beforeId;
  final int limit;
}

class _FakeChatMessageRepository extends ChatMessageRepository {
  _FakeChatMessageRepository({
    required List<ChatMessage> cachedMessages,
    required List<ChatMessage> canonicalMessages,
    this.loadMoreGate,
  }) : _cachedMessages = List<ChatMessage>.from(cachedMessages),
       _canonicalMessages = List<ChatMessage>.from(canonicalMessages),
       super();

  final List<ChatMessage> _cachedMessages;
  final List<ChatMessage> _canonicalMessages;
  final Completer<void>? loadMoreGate;
  final List<_FetchCall> fetchCalls = <_FetchCall>[];
  List<ChatMessage> lastPersistedMessages = const <ChatMessage>[];

  @override
  bool get isReady => true;

  @override
  Future<List<ChatMessage>> loadCachedMessages(
    String roomId, {
    int limit = 20,
  }) async {
    return _cachedMessages.take(limit).toList();
  }

  @override
  Future<void> cacheMessages(String roomId, List<ChatMessage> messages) async {
    lastPersistedMessages = List<ChatMessage>.from(messages);
  }

  @override
  Future<List<ChatMessage>> fetchMessages({
    required String roomId,
    String? beforeCreatedAt,
    String? beforeId,
    int limit = 20,
  }) async {
    fetchCalls.add(
      _FetchCall(
        beforeCreatedAt: beforeCreatedAt,
        beforeId: beforeId,
        limit: limit,
      ),
    );

    final descending = List<ChatMessage>.from(_canonicalMessages)
      ..sort((a, b) {
        final createdCompare = b.createdAt.compareTo(a.createdAt);
        if (createdCompare != 0) {
          return createdCompare;
        }
        return b.id.compareTo(a.id);
      });

    Iterable<ChatMessage> page = descending;
    if (beforeCreatedAt != null && beforeId != null) {
      final gate = loadMoreGate;
      if (gate != null && !gate.isCompleted) {
        await gate.future;
      }
      final before = DateTime.parse(beforeCreatedAt);
      page = page.where((message) {
        final createdCompare = message.createdAt.compareTo(before);
        return createdCompare < 0 ||
            (createdCompare == 0 && message.id.compareTo(beforeId) < 0);
      });
    }
    return page.take(limit).toList();
  }

  @override
  Future<Map<String, List<ChatMessageReactionSummary>>> fetchReactionSummaries({
    required String roomId,
    required List<String> messageIds,
    required String currentUserId,
  }) async {
    return const <String, List<ChatMessageReactionSummary>>{};
  }

  void appendCanonical(ChatMessage message) {
    _canonicalMessages.add(message);
    _cachedMessages.insert(0, message);
  }
}

void main() {
  ChatMessage message(int index) {
    final createdAt = DateTime.utc(2026, 3, 19).add(Duration(minutes: index));
    return ChatMessage(
      id: 'm$index',
      roomId: 'room-1',
      senderId: 'other',
      type: 'text',
      body: 'message $index',
      imageUrl: null,
      caption: null,
      coinsAwarded: 0,
      createdAt: createdAt,
      clientCreatedAt: createdAt,
      labels: const <Map<String, dynamic>>[],
      localImagePath: null,
    );
  }

  ChatMessage systemMessage(String body) {
    final createdAt = DateTime.utc(2026, 3, 19, 12);
    return ChatMessage(
      id: 'system-1',
      roomId: 'room-1',
      senderId: null,
      type: 'system',
      body: body,
      imageUrl: null,
      caption: null,
      coinsAwarded: 0,
      createdAt: createdAt,
      clientCreatedAt: createdAt,
      labels: const <Map<String, dynamic>>[],
      localImagePath: null,
    );
  }

  ChatMessage textMessage({
    required String id,
    required String senderId,
    required String body,
    required DateTime createdAt,
  }) {
    return ChatMessage(
      id: id,
      roomId: 'room-1',
      senderId: senderId,
      type: 'text',
      body: body,
      imageUrl: null,
      caption: null,
      coinsAwarded: 0,
      createdAt: createdAt,
      clientCreatedAt: createdAt,
      labels: const <Map<String, dynamic>>[],
      localImagePath: null,
    );
  }

  ChatMessage feedMessage({
    required String id,
    required String senderId,
    required String caption,
    required DateTime createdAt,
  }) {
    return ChatMessage(
      id: id,
      roomId: 'room-1',
      senderId: senderId,
      type: 'image_feed',
      body: null,
      imageUrl: null,
      caption: caption,
      coinsAwarded: 0,
      createdAt: createdAt,
      clientCreatedAt: createdAt,
      labels: const <Map<String, dynamic>>[],
      localImagePath: null,
    );
  }

  Future<void> pumpChatRoom(
    WidgetTester tester, {
    required _FakeChatMessageRepository repository,
    required ChatRoomViewRuntime runtime,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChatRoomViewV2(
          roomId: 'room-1',
          petName: 'Mochi',
          memberCount: 2,
          repository: repository,
          runtime: runtime,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    ProfileCacheService.instance.clear();
    ProfileCacheService.instance.prime(
      const ProfileSummary(userId: 'other', nickname: 'Other', avatarUrl: null),
    );
    ProfileCacheService.instance.prime(
      const ProfileSummary(
        userId: 'someone-else',
        nickname: 'Someone Else',
        avatarUrl: null,
      ),
    );
  });

  tearDown(() {
    ProfileCacheService.instance.clear();
  });

  testWidgets('room open hydrates only the latest slice from cache/network', (
    tester,
  ) async {
    final repository = _FakeChatMessageRepository(
      cachedMessages: List<ChatMessage>.generate(
        40,
        (index) => message(40 - index),
      ),
      canonicalMessages: List<ChatMessage>.generate(
        40,
        (index) => message(index + 1),
      ),
    );
    const runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
    );

    await pumpChatRoom(tester, repository: repository, runtime: runtime);

    expect(find.text('message 40'), findsOneWidget);
    expect(find.text('message 21'), findsOneWidget);
    expect(find.text('message 20'), findsNothing);
    expect(repository.fetchCalls, hasLength(1));
    expect(repository.lastPersistedMessages.length, 20);
  });

  testWidgets('scrolling near top loads older messages automatically', (
    tester,
  ) async {
    final repository = _FakeChatMessageRepository(
      cachedMessages: List<ChatMessage>.generate(
        60,
        (index) => message(60 - index),
      ),
      canonicalMessages: List<ChatMessage>.generate(
        60,
        (index) => message(index + 1),
      ),
    );
    const runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
    );

    await pumpChatRoom(tester, repository: repository, runtime: runtime);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 2400),
    );
    await tester.pumpAndSettle();

    expect(repository.fetchCalls.length, greaterThanOrEqualTo(2));
    expect(repository.fetchCalls[1].beforeId, 'm41');
  });

  testWidgets(
    'load-more overlay stays outside timeline and preserves viewport anchor',
    (tester) async {
      final loadMoreGate = Completer<void>();
      addTearDown(() {
        if (!loadMoreGate.isCompleted) {
          loadMoreGate.complete();
        }
      });

      final repository = _FakeChatMessageRepository(
        cachedMessages: List<ChatMessage>.generate(
          60,
          (index) => message(60 - index),
        ),
        canonicalMessages: List<ChatMessage>.generate(
          60,
          (index) => message(index + 1),
        ),
        loadMoreGate: loadMoreGate,
      );
      const runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 2400),
      );
      await tester.pump();

      final overlayFinder = find.byKey(
        const ValueKey('chatHistoryLoadOverlay'),
      );
      expect(overlayFinder, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: overlayFinder,
        ),
        findsNothing,
      );

      final anchorFinder = find.byKey(const ValueKey('chatMessageSurface_m42'));
      expect(anchorFinder, findsOneWidget);
      final beforeDy = tester.getTopLeft(anchorFinder).dy;

      loadMoreGate.complete();
      await tester.pumpAndSettle();

      expect(overlayFinder, findsNothing);
      final afterDy = tester.getTopLeft(anchorFinder).dy;
      expect(afterDy, closeTo(beforeDy, 8));
    },
  );

  testWidgets(
    'history mode buffers live messages and jump button resets to latest',
    (tester) async {
      final incomingController = StreamController<ChatMessage>();
      addTearDown(incomingController.close);

      final repository = _FakeChatMessageRepository(
        cachedMessages: List<ChatMessage>.generate(
          60,
          (index) => message(60 - index),
        ),
        canonicalMessages: List<ChatMessage>.generate(
          60,
          (index) => message(index + 1),
        ),
      );
      final runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        incomingMessages: incomingController.stream,
        loadBlockedUserIds: (_) async => <String>{},
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 2400),
      );
      await tester.pumpAndSettle();

      final latestMessage = message(61);
      repository.appendCanonical(latestMessage);
      incomingController.add(latestMessage);
      await tester.pumpAndSettle();

      expect(find.text('message 61'), findsNothing);
      expect(
        find.byKey(const ValueKey('chatScrollToLatestPendingCount')),
        findsOneWidget,
      );
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('message 61'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chatScrollToLatestPendingCount')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'resuming the app refreshes latest messages after a backgrounded gap',
    (tester) async {
      final repository = _FakeChatMessageRepository(
        cachedMessages: List<ChatMessage>.generate(
          60,
          (index) => message(60 - index),
        ),
        canonicalMessages: List<ChatMessage>.generate(
          60,
          (index) => message(index + 1),
        ),
      );
      const runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);

      final latestMessage = message(61);
      repository.appendCanonical(latestMessage);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('message 61'), findsOneWidget);
      expect(repository.fetchCalls.length, greaterThanOrEqualTo(2));
    },
  );

  testWidgets(
    'grouped received text and feed messages show sender name only once',
    (tester) async {
      final firstCreatedAt = DateTime.utc(2026, 3, 20, 12, 0);
      final secondCreatedAt = firstCreatedAt.add(const Duration(minutes: 1));
      final groupedMessages = <ChatMessage>[
        textMessage(
          id: 'group-text',
          senderId: 'other',
          body: 'first grouped message',
          createdAt: firstCreatedAt,
        ),
        feedMessage(
          id: 'group-feed',
          senderId: 'other',
          caption: 'grouped feed caption',
          createdAt: secondCreatedAt,
        ),
      ];
      final repository = _FakeChatMessageRepository(
        cachedMessages: groupedMessages.reversed.toList(),
        canonicalMessages: groupedMessages,
      );
      const runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);

      expect(find.text('first grouped message'), findsOneWidget);
      expect(find.text('grouped feed caption'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    },
  );

  testWidgets('received sender name reappears after grouping timeout breaks', (
    tester,
  ) async {
    final firstCreatedAt = DateTime.utc(2026, 3, 20, 13, 0);
    final secondCreatedAt = firstCreatedAt.add(const Duration(minutes: 6));
    final separatedMessages = <ChatMessage>[
      textMessage(
        id: 'timeout-text-1',
        senderId: 'other',
        body: 'before timeout',
        createdAt: firstCreatedAt,
      ),
      textMessage(
        id: 'timeout-text-2',
        senderId: 'other',
        body: 'after timeout',
        createdAt: secondCreatedAt,
      ),
    ];
    final repository = _FakeChatMessageRepository(
      cachedMessages: separatedMessages.reversed.toList(),
      canonicalMessages: separatedMessages,
    );
    const runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
    );

    await pumpChatRoom(tester, repository: repository, runtime: runtime);

    expect(find.text('before timeout'), findsOneWidget);
    expect(find.text('after timeout'), findsOneWidget);
    expect(find.text('Other'), findsNWidgets(2));
  });

  testWidgets('system messages stay horizontally centered', (tester) async {
    final repository = _FakeChatMessageRepository(
      cachedMessages: <ChatMessage>[systemMessage('System update')],
      canonicalMessages: <ChatMessage>[systemMessage('System update')],
    );
    const runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
    );

    await pumpChatRoom(tester, repository: repository, runtime: runtime);

    final scaffoldCenter = tester.getCenter(find.byType(Scaffold)).dx;
    final systemCenter = tester.getCenter(find.text('System update')).dx;

    expect(systemCenter, closeTo(scaffoldCenter, 1));
  });
}
