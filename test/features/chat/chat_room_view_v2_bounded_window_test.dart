import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/features/chat/chat_mentions.dart';
import 'package:pet/features/chat/chat_room_view_runtime.dart';
import 'package:pet/features/chat/chat_room_view_v2.dart';
import 'package:pet/features/feed/feed_upload_models.dart';
import 'package:pet/features/feed/feed_upload_queue.dart';
import 'package:pet/features/feed/feed_upload_repository.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/services/chat/chat_message_action_service.dart';
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
    Map<String, List<ChatMessageReactionDetail>> reactionDetailsByMessageId =
        const <String, List<ChatMessageReactionDetail>>{},
    this.loadMoreGate,
  }) : _cachedMessages = List<ChatMessage>.from(cachedMessages),
       _canonicalMessages = List<ChatMessage>.from(canonicalMessages),
       _reactionDetailsByMessageId = {
         for (final entry in reactionDetailsByMessageId.entries)
           entry.key: List<ChatMessageReactionDetail>.from(entry.value),
       },
       super();

  final List<ChatMessage> _cachedMessages;
  final List<ChatMessage> _canonicalMessages;
  final Map<String, List<ChatMessageReactionDetail>>
  _reactionDetailsByMessageId;
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
    final result = <String, List<ChatMessageReactionSummary>>{};
    for (final messageId in messageIds) {
      final details = _reactionDetailsByMessageId[messageId];
      if (details == null || details.isEmpty) {
        continue;
      }
      final counts = <String, int>{};
      String? myEmoji;
      for (final detail in details) {
        counts.update(detail.emoji, (value) => value + 1, ifAbsent: () => 1);
        if (detail.userId == currentUserId) {
          myEmoji = detail.emoji;
        }
      }
      final summaries =
          counts.entries
              .map(
                (entry) => ChatMessageReactionSummary(
                  emoji: entry.key,
                  count: entry.value,
                  reactedByMe: entry.key == myEmoji,
                ),
              )
              .toList()
            ..sort((a, b) {
              final countCompare = b.count.compareTo(a.count);
              if (countCompare != 0) {
                return countCompare;
              }
              return a.emoji.compareTo(b.emoji);
            });
      result[messageId] = summaries;
    }
    return result;
  }

  @override
  Future<List<ChatMessageReactionDetail>> fetchReactionDetails({
    required String roomId,
    required String messageId,
  }) async {
    return List<ChatMessageReactionDetail>.from(
      _reactionDetailsByMessageId[messageId] ??
          const <ChatMessageReactionDetail>[],
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void appendCanonical(ChatMessage message) {
    _canonicalMessages.add(message);
    _cachedMessages.insert(0, message);
  }

  void setReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) {
    final next = List<ChatMessageReactionDetail>.from(
      _reactionDetailsByMessageId[messageId] ??
          const <ChatMessageReactionDetail>[],
    )..removeWhere((detail) => detail.userId == userId);
    next.add(
      ChatMessageReactionDetail(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
        createdAt: DateTime.utc(2026, 3, 31, 12, next.length),
      ),
    );
    _reactionDetailsByMessageId[messageId] = next;
  }

  void removeReaction({required String messageId, required String userId}) {
    final next = List<ChatMessageReactionDetail>.from(
      _reactionDetailsByMessageId[messageId] ??
          const <ChatMessageReactionDetail>[],
    )..removeWhere((detail) => detail.userId == userId);
    if (next.isEmpty) {
      _reactionDetailsByMessageId.remove(messageId);
      return;
    }
    _reactionDetailsByMessageId[messageId] = next;
  }
}

class _NoopFeedUploadRepository extends FeedUploadRepository {
  @override
  Future<void> init() async {}

  @override
  List<FeedUploadJob> loadJobs() => const <FeedUploadJob>[];

  @override
  Future<void> saveJob(FeedUploadJob job) async {}

  @override
  Future<void> deleteJob(String tempId) async {}
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
      replyToMessageId: null,
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
    String? replyToMessageId,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? deletedBy,
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
      editedAt: editedAt,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
      replyToMessageId: replyToMessageId,
    );
  }

  Map<String, dynamic> textMessageRow({
    required String id,
    required String senderId,
    required String body,
    required DateTime createdAt,
    String? replyToMessageId,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return <String, dynamic>{
      'id': id,
      'room_id': 'room-1',
      'sender_id': senderId,
      'type': 'text',
      'body': body,
      'image_url': null,
      'caption': null,
      'coins_awarded': 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'client_created_at': createdAt.toUtc().toIso8601String(),
      'labels': const <Map<String, dynamic>>[],
      'reply_to_message_id': replyToMessageId,
      'edited_at': editedAt?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'deleted_by': deletedBy,
    };
  }

  ChatMessage feedMessage({
    required String id,
    required String senderId,
    required String caption,
    required DateTime createdAt,
    String? replyToMessageId,
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
      replyToMessageId: replyToMessageId,
    );
  }

  Future<void> pumpChatRoom(
    WidgetTester tester, {
    required _FakeChatMessageRepository repository,
    required ChatRoomViewRuntime runtime,
    ChatMessageActionService? messageActionService,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedUploadRepositoryProvider.overrideWithValue(
            _NoopFeedUploadRepository(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatRoomViewV2(
            roomId: 'room-1',
            petName: 'Mochi',
            memberCount: 2,
            repository: repository,
            runtime: runtime,
            messageActionService: messageActionService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> setKeyboardInset(WidgetTester tester, double bottomInset) async {
    tester.view.viewInsets = FakeViewPadding(bottom: bottomInset);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpAndSettle();
  }

  Future<void> focusComposerAndOpenKeyboard(WidgetTester tester) async {
    final composerFinder = find.byKey(const ValueKey('chatComposerTextField'));
    await tester.tap(composerFinder);
    await tester.pump();
    await tester.showKeyboard(composerFinder);
    await setKeyboardInset(tester, 320);
  }

  ScrollController timelineController(WidgetTester tester) {
    final listView = tester.widget<ListView>(
      find.byKey(const ValueKey('chatTimelineList')),
    );
    return listView.controller!;
  }

  Finder findRenderedText(String text) {
    return find.byWidgetPredicate((widget) {
      if (widget is Text) {
        return (widget.data ?? widget.textSpan?.toPlainText()) == text;
      }
      if (widget is RichText) {
        return widget.text.toPlainText().contains(text);
      }
      return false;
    });
  }

  double composerTop(WidgetTester tester) {
    return tester
        .getTopLeft(find.byKey(const ValueKey('chatComposerTextField')))
        .dy;
  }

  double composerBottom(WidgetTester tester) {
    return tester
        .getBottomLeft(find.byKey(const ValueKey('chatComposerTextField')))
        .dy;
  }

  bool composerHasFocus(WidgetTester tester) {
    final editable = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('chatComposerTextField')),
        matching: find.byType(EditableText),
      ),
    );
    return editable.focusNode.hasFocus;
  }

  String composerText(WidgetTester tester) {
    final editable = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('chatComposerTextField')),
        matching: find.byType(EditableText),
      ),
    );
    return editable.controller.text;
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
    expect(find.text('message 20'), findsNothing);
    expect(repository.fetchCalls, hasLength(1));
    expect(repository.lastPersistedMessages.length, 20);
    expect(repository.lastPersistedMessages.first.id, 'm21');
    expect(repository.lastPersistedMessages.last.id, 'm40');
  });

  testWidgets(
    'room open keeps newest message fully visible after delayed reply preview expands it',
    (tester) async {
      final replyPreviewCompleter = Completer<Map<String, ChatReplyPreview>>();
      addTearDown(() {
        if (!replyPreviewCompleter.isCompleted) {
          replyPreviewCompleter.complete(<String, ChatReplyPreview>{
            'm10': ChatReplyPreview(
              id: 'm10',
              senderId: 'someone-else',
              type: 'text',
              body: 'earlier replied message',
              imageUrl: null,
              caption: null,
            ),
          });
        }
      });

      final messages = List<ChatMessage>.generate(
        40,
        (index) => message(index + 1),
      );
      messages[39] = textMessage(
        id: 'm40',
        senderId: 'other',
        body: 'latest reply message',
        createdAt: DateTime.utc(2026, 3, 19).add(const Duration(minutes: 40)),
        replyToMessageId: 'm10',
      );
      final repository = _FakeChatMessageRepository(
        cachedMessages: messages.reversed.toList(),
        canonicalMessages: messages,
      );
      final runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
        fetchReplyPreviews: (_) => replyPreviewCompleter.future,
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);

      replyPreviewCompleter.complete(<String, ChatReplyPreview>{
        'm10': ChatReplyPreview(
          id: 'm10',
          senderId: 'someone-else',
          type: 'text',
          body: 'earlier replied message',
          imageUrl: null,
          caption: null,
        ),
      });
      await tester.pumpAndSettle();

      final latestMessageBottom = tester
          .getBottomLeft(find.byKey(const ValueKey('chatMessageSurface_m40')))
          .dy;
      final composerTop = tester
          .getTopLeft(find.byKey(const ValueKey('chatComposerTextField')))
          .dy;

      expect(latestMessageBottom, lessThanOrEqualTo(composerTop + 1));
    },
  );

  testWidgets(
    'room open keeps newest message fully visible when keyboard is already open',
    (tester) async {
      addTearDown(tester.view.resetViewInsets);
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);

      final messages = List<ChatMessage>.generate(
        40,
        (index) => message(index + 1),
      );
      final repository = _FakeChatMessageRepository(
        cachedMessages: messages.reversed.toList(),
        canonicalMessages: messages,
      );
      const runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);

      final latestMessageBottom = tester
          .getBottomLeft(find.byKey(const ValueKey('chatMessageSurface_m40')))
          .dy;
      final composerTop = tester
          .getTopLeft(find.byKey(const ValueKey('chatComposerTextField')))
          .dy;

      expect(latestMessageBottom, lessThanOrEqualTo(composerTop + 1));
    },
  );

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
      find.byKey(const ValueKey('chatTimelineList')),
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
        find.byKey(const ValueKey('chatTimelineList')),
        const Offset(0, 2400),
      );
      await tester.pump();

      final overlayFinder = find.byKey(
        const ValueKey('chatHistoryLoadOverlay'),
      );
      expect(overlayFinder, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('chatTimelineList')),
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
    'opening the keyboard while browsing history pushes the viewed message upward and keeps it visible',
    (tester) async {
      addTearDown(tester.view.resetViewInsets);

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
        find.byKey(const ValueKey('chatTimelineList')),
        const Offset(0, 2400),
      );
      await tester.pumpAndSettle();

      final anchorFinder = find.byKey(const ValueKey('chatMessageSurface_m42'));
      expect(anchorFinder, findsOneWidget);
      final beforeDy = tester.getCenter(anchorFinder).dy;

      await focusComposerAndOpenKeyboard(tester);

      final afterDy = tester.getCenter(anchorFinder).dy;
      expect(afterDy, lessThan(beforeDy - 40));
      expect(
        tester.getBottomLeft(anchorFinder).dy,
        lessThanOrEqualTo(composerTop(tester) + 1),
      );
    },
  );

  testWidgets('opening the keyboard moves the composer upward', (tester) async {
    addTearDown(tester.view.resetViewInsets);

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
    final beforeBottom = composerBottom(tester);
    await focusComposerAndOpenKeyboard(tester);

    expect(composerBottom(tester), lessThan(beforeBottom - 40));
  });

  testWidgets(
    'typing @ shows other active room members without moving composer',
    (tester) async {
      final repository = _FakeChatMessageRepository(
        cachedMessages: const <ChatMessage>[],
        canonicalMessages: const <ChatMessage>[],
      );
      final runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
        loadBlockedUserIds: (_) async => <String>{'blocked'},
        fetchMentionCandidates: (_) async => const <ChatMentionCandidate>[
          ChatMentionCandidate(userId: 'me', displayName: 'Me'),
          ChatMentionCandidate(userId: 'alice', displayName: 'Alice'),
          ChatMentionCandidate(userId: 'blocked', displayName: 'Blocked'),
        ],
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);

      final beforeTop = composerTop(tester);
      await tester.enterText(
        find.byKey(const ValueKey('chatComposerTextField')),
        '@',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('chatMentionSuggestionsPanel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chatMentionSuggestion_alice')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chatMentionSuggestion_me')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('chatMentionSuggestion_blocked')),
        findsNothing,
      );
      expect(composerTop(tester), closeTo(beforeTop, 1));
    },
  );

  testWidgets('selecting a mention inserts display text and keeps focus', (
    tester,
  ) async {
    final repository = _FakeChatMessageRepository(
      cachedMessages: const <ChatMessage>[],
      canonicalMessages: const <ChatMessage>[],
    );
    final runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
      loadBlockedUserIds: (_) async => <String>{},
      fetchMentionCandidates: (_) async => const <ChatMentionCandidate>[
        ChatMentionCandidate(userId: 'alice', displayName: 'Alice'),
      ],
    );

    await pumpChatRoom(tester, repository: repository, runtime: runtime);
    await tester.tap(find.byKey(const ValueKey('chatComposerTextField')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('chatComposerTextField')),
      'hi @Al',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chatMentionSuggestion_alice')));
    await tester.pumpAndSettle();

    expect(composerText(tester), 'hi @Alice ');
    expect(composerHasFocus(tester), isTrue);
    expect(
      find.byKey(const ValueKey('chatMentionSuggestionsPanel')),
      findsNothing,
    );
  });

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
        find.byKey(const ValueKey('chatTimelineList')),
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
      expect(
        find.byKey(const ValueKey('chatJumpToLatestButton')),
        findsOneWidget,
      );
      expect(find.text('Latest'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('chatJumpToLatestButton')));
      await tester.pumpAndSettle();

      expect(find.text('message 61'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chatScrollToLatestPendingCount')),
        findsNothing,
      );
    },
  );

  testWidgets('send failure restores composer text and clears optimistic UI', (
    tester,
  ) async {
    final repository = _FakeChatMessageRepository(
      cachedMessages: const <ChatMessage>[],
      canonicalMessages: const <ChatMessage>[],
    );
    final messageActionService = ChatMessageActionService(
      insertText: (_) async => throw StateError('insert_failed'),
      notifyTextMessage: ({required roomId, required messageId}) async {},
    );
    const runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
    );

    await pumpChatRoom(
      tester,
      repository: repository,
      runtime: runtime,
      messageActionService: messageActionService,
    );

    await tester.enterText(
      find.byKey(const ValueKey('chatComposerTextField')),
      'please send',
    );
    await tester.tap(find.byKey(const ValueKey('chatComposerSendButton')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(composerText(tester), 'please send');
    expect(repository.lastPersistedMessages, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'successful send replaces optimistic message with confirmed row without disappearing',
    (tester) async {
      final insertCompleter = Completer<Map<String, dynamic>>();
      addTearDown(() {
        if (!insertCompleter.isCompleted) {
          insertCompleter.complete(
            textMessageRow(
              id: 'server-send',
              senderId: 'me',
              body: 'smooth send',
              createdAt: DateTime.utc(2026, 3, 31, 12),
            ),
          );
        }
      });
      final repository = _FakeChatMessageRepository(
        cachedMessages: <ChatMessage>[message(1)],
        canonicalMessages: <ChatMessage>[message(1)],
      );
      final messageActionService = ChatMessageActionService(
        insertText: (_) => insertCompleter.future,
        notifyTextMessage: ({required roomId, required messageId}) async {},
      );
      const runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
      );

      await pumpChatRoom(
        tester,
        repository: repository,
        runtime: runtime,
        messageActionService: messageActionService,
      );

      final controller = timelineController(tester);
      final offsets = <double>[controller.position.pixels];
      await tester.enterText(
        find.byKey(const ValueKey('chatComposerTextField')),
        'smooth send',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chatComposerSendButton')));
      await tester.pump();
      offsets.add(controller.position.pixels);
      expect(composerText(tester), isEmpty);
      expect(find.text('smooth send'), findsOneWidget);

      insertCompleter.complete(
        textMessageRow(
          id: 'server-send',
          senderId: 'me',
          body: 'smooth send',
          createdAt: DateTime.utc(2026, 3, 31, 12),
        ),
      );
      for (var frame = 0; frame < 6; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        offsets.add(controller.position.pixels);
        expect(find.text('smooth send'), findsOneWidget);
      }
      await tester.pumpAndSettle();
      offsets.add(controller.position.pixels);

      expect(
        find.byKey(const ValueKey('chatMessageSurface_server-send')),
        findsOneWidget,
      );
      expect(
        repository.lastPersistedMessages.map((entry) => entry.id),
        contains('server-send'),
      );
      for (var index = 1; index < offsets.length; index += 1) {
        expect(offsets[index], lessThanOrEqualTo(offsets[index - 1] + 1));
      }
    },
  );

  testWidgets('stale runtime messages after dispose are ignored', (
    tester,
  ) async {
    final incomingController = StreamController<ChatMessage>.broadcast();
    addTearDown(incomingController.close);

    final repository = _FakeChatMessageRepository(
      cachedMessages: <ChatMessage>[message(1)],
      canonicalMessages: <ChatMessage>[message(1)],
    );
    final runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      incomingMessages: incomingController.stream,
      loadBlockedUserIds: (_) async => <String>{},
    );

    await pumpChatRoom(tester, repository: repository, runtime: runtime);

    await tester.pumpWidget(const SizedBox.shrink());
    incomingController.add(message(2));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'latest button keeps newest message visible after delayed reply preview expands it',
    (tester) async {
      final replyPreviewCompleter = Completer<Map<String, ChatReplyPreview>>();
      addTearDown(() {
        if (!replyPreviewCompleter.isCompleted) {
          replyPreviewCompleter.complete(<String, ChatReplyPreview>{
            'm10': ChatReplyPreview(
              id: 'm10',
              senderId: 'someone-else',
              type: 'text',
              body: 'earlier replied message',
              imageUrl: null,
              caption: null,
            ),
          });
        }
      });

      final messages = List<ChatMessage>.generate(
        60,
        (index) => message(index + 1),
      );
      messages[59] = textMessage(
        id: 'm60',
        senderId: 'other',
        body: 'latest delayed reply',
        createdAt: DateTime.utc(2026, 3, 19).add(const Duration(minutes: 60)),
        replyToMessageId: 'm10',
      );
      final repository = _FakeChatMessageRepository(
        cachedMessages: messages.reversed.toList(),
        canonicalMessages: messages,
      );
      final runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
        fetchReplyPreviews: (_) => replyPreviewCompleter.future,
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);

      await tester.drag(
        find.byKey(const ValueKey('chatTimelineList')),
        const Offset(0, 2400),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('chatJumpToLatestButton')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('chatJumpToLatestButton')));
      await tester.pump();

      replyPreviewCompleter.complete(<String, ChatReplyPreview>{
        'm10': ChatReplyPreview(
          id: 'm10',
          senderId: 'someone-else',
          type: 'text',
          body: 'earlier replied message',
          imageUrl: null,
          caption: null,
        ),
      });
      await tester.pumpAndSettle();

      final latestMessageBottom = tester
          .getBottomLeft(find.byKey(const ValueKey('chatMessageSurface_m60')))
          .dy;
      final composerTop = tester
          .getTopLeft(find.byKey(const ValueKey('chatComposerTextField')))
          .dy;

      expect(latestMessageBottom, lessThanOrEqualTo(composerTop + 1));
    },
  );

  testWidgets(
    'latest button keeps newest message visible with keyboard open after delayed reply preview expands it',
    (tester) async {
      addTearDown(tester.view.resetViewInsets);

      final replyPreviewCompleter = Completer<Map<String, ChatReplyPreview>>();
      addTearDown(() {
        if (!replyPreviewCompleter.isCompleted) {
          replyPreviewCompleter.complete(<String, ChatReplyPreview>{
            'm10': ChatReplyPreview(
              id: 'm10',
              senderId: 'someone-else',
              type: 'text',
              body: 'earlier replied message',
              imageUrl: null,
              caption: null,
            ),
          });
        }
      });

      final messages = List<ChatMessage>.generate(
        60,
        (index) => message(index + 1),
      );
      messages[59] = textMessage(
        id: 'm60',
        senderId: 'other',
        body: 'latest delayed keyboard reply',
        createdAt: DateTime.utc(2026, 3, 19).add(const Duration(minutes: 60)),
        replyToMessageId: 'm10',
      );
      final repository = _FakeChatMessageRepository(
        cachedMessages: messages.reversed.toList(),
        canonicalMessages: messages,
      );
      final runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
        fetchReplyPreviews: (_) => replyPreviewCompleter.future,
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);

      await tester.drag(
        find.byKey(const ValueKey('chatTimelineList')),
        const Offset(0, 2400),
      );
      await tester.pumpAndSettle();

      await setKeyboardInset(tester, 320);

      expect(
        find.byKey(const ValueKey('chatJumpToLatestButton')),
        findsOneWidget,
      );
      final offsets = <double>[timelineController(tester).position.pixels];
      await tester.tap(find.byKey(const ValueKey('chatJumpToLatestButton')));
      await tester.pump();
      offsets.add(timelineController(tester).position.pixels);

      for (var frame = 0; frame < 3; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        offsets.add(timelineController(tester).position.pixels);
      }

      replyPreviewCompleter.complete(<String, ChatReplyPreview>{
        'm10': ChatReplyPreview(
          id: 'm10',
          senderId: 'someone-else',
          type: 'text',
          body: 'earlier replied message',
          imageUrl: null,
          caption: null,
        ),
      });
      for (var frame = 0; frame < 24; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        offsets.add(timelineController(tester).position.pixels);
      }
      await tester.pumpAndSettle();
      offsets.add(timelineController(tester).position.pixels);

      for (var index = 1; index < offsets.length; index += 1) {
        expect(offsets[index], lessThanOrEqualTo(offsets[index - 1] + 1));
      }

      final latestMessageBottom = tester
          .getBottomLeft(find.byKey(const ValueKey('chatMessageSurface_m60')))
          .dy;
      final composerTop = tester
          .getTopLeft(find.byKey(const ValueKey('chatComposerTextField')))
          .dy;

      expect(latestMessageBottom, lessThanOrEqualTo(composerTop + 1));
    },
  );

  testWidgets('latest button keeps composer focus while keyboard is open', (
    tester,
  ) async {
    addTearDown(tester.view.resetViewInsets);

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
      find.byKey(const ValueKey('chatTimelineList')),
      const Offset(0, 2400),
    );
    await tester.pumpAndSettle();

    await focusComposerAndOpenKeyboard(tester);
    expect(composerHasFocus(tester), isTrue);

    await tester.tap(find.byKey(const ValueKey('chatJumpToLatestButton')));
    await tester.pumpAndSettle();

    expect(composerHasFocus(tester), isTrue);
    expect(
      find.byKey(const ValueKey('chatMessageSurface_m60')),
      findsOneWidget,
    );
  });

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

  testWidgets(
    'grouped text messages stack with tighter spacing than split runs',
    (tester) async {
      final firstCreatedAt = DateTime.utc(2026, 3, 20, 14, 0);
      final secondCreatedAt = firstCreatedAt.add(const Duration(minutes: 1));
      final thirdCreatedAt = firstCreatedAt.add(const Duration(minutes: 8));
      final messages = <ChatMessage>[
        textMessage(
          id: 'group-spacing-1',
          senderId: 'other',
          body: 'first grouped',
          createdAt: firstCreatedAt,
        ),
        textMessage(
          id: 'group-spacing-2',
          senderId: 'other',
          body: 'second grouped',
          createdAt: secondCreatedAt,
        ),
        textMessage(
          id: 'group-spacing-3',
          senderId: 'other',
          body: 'after split',
          createdAt: thirdCreatedAt,
        ),
      ];
      final repository = _FakeChatMessageRepository(
        cachedMessages: messages.reversed.toList(),
        canonicalMessages: messages,
      );
      const runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);

      final firstBubble = find.byKey(
        const ValueKey('chatMessageSurface_group-spacing-1'),
      );
      final secondBubble = find.byKey(
        const ValueKey('chatMessageSurface_group-spacing-2'),
      );
      final thirdBubble = find.byKey(
        const ValueKey('chatMessageSurface_group-spacing-3'),
      );

      final groupedGap =
          tester.getTopLeft(secondBubble).dy -
          tester.getBottomLeft(firstBubble).dy;
      final separatedGap =
          tester.getTopLeft(thirdBubble).dy -
          tester.getBottomLeft(secondBubble).dy;

      expect(groupedGap, lessThan(separatedGap));
    },
  );

  testWidgets('long press opens legacy message action sheet', (tester) async {
    final createdAt = DateTime.utc(2026, 3, 31, 10);
    final message = textMessage(
      id: 'reaction-target',
      senderId: 'other',
      body: 'hold me',
      createdAt: createdAt,
    );
    final repository = _FakeChatMessageRepository(
      cachedMessages: <ChatMessage>[message],
      canonicalMessages: <ChatMessage>[message],
    );
    const runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
    );

    await pumpChatRoom(tester, repository: repository, runtime: runtime);

    await tester.longPress(
      find.byKey(const ValueKey('chatMessageSurface_reaction-target')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chatMessageActionOverlayScrim')),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Report message'), findsOneWidget);
    expect(find.text('Block user'), findsOneWidget);
    expect(find.text('0 reactions'), findsNothing);
  });

  testWidgets(
    'tapping a reaction chip opens the details sheet for that emoji',
    (tester) async {
      final createdAt = DateTime.utc(2026, 3, 31, 11);
      final message = textMessage(
        id: 'reaction-chip-target',
        senderId: 'other',
        body: 'tap chip',
        createdAt: createdAt,
      );
      final repository = _FakeChatMessageRepository(
        cachedMessages: <ChatMessage>[message],
        canonicalMessages: <ChatMessage>[message],
        reactionDetailsByMessageId: <String, List<ChatMessageReactionDetail>>{
          'reaction-chip-target': <ChatMessageReactionDetail>[
            ChatMessageReactionDetail(
              messageId: 'reaction-chip-target',
              userId: 'me',
              emoji: '👍',
              createdAt: DateTime.utc(2026, 3, 31, 11, 3),
            ),
            ChatMessageReactionDetail(
              messageId: 'reaction-chip-target',
              userId: 'other',
              emoji: '👍',
              createdAt: DateTime.utc(2026, 3, 31, 11, 2),
            ),
            ChatMessageReactionDetail(
              messageId: 'reaction-chip-target',
              userId: 'someone-else',
              emoji: '❤️',
              createdAt: DateTime.utc(2026, 3, 31, 11, 1),
            ),
          ],
        },
      );
      const runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
      );

      await pumpChatRoom(tester, repository: repository, runtime: runtime);

      await tester.tap(find.byKey(const ValueKey('chatReactionChip_👍_2')));
      await tester.pumpAndSettle();

      expect(find.text('3 reactions'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chatReactionSheetRow_me_👍')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chatReactionSheetRow_other_👍')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chatReactionSheetRow_someone-else_❤️')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'selecting an emoji in the long-press action sheet updates inline reaction chips optimistically',
    (tester) async {
      final createdAt = DateTime.utc(2026, 3, 31, 12);
      final message = textMessage(
        id: 'reaction-update-target',
        senderId: 'other',
        body: 'react to me',
        createdAt: createdAt,
      );
      final repository = _FakeChatMessageRepository(
        cachedMessages: <ChatMessage>[message],
        canonicalMessages: <ChatMessage>[message],
      );
      final messageActionService = ChatMessageActionService(
        deleteReaction: ({required messageId, required userId}) async {
          repository.removeReaction(messageId: messageId, userId: userId);
        },
        upsertReaction: (payload) async {
          repository.setReaction(
            messageId: payload['message_id'] as String,
            userId: payload['user_id'] as String,
            emoji: payload['emoji'] as String,
          );
        },
      );
      const runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
      );

      await pumpChatRoom(
        tester,
        repository: repository,
        runtime: runtime,
        messageActionService: messageActionService,
      );

      await tester.longPress(
        find.byKey(const ValueKey('chatMessageSurface_reaction-update-target')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('chatMessageActionSheetReactionRail')),
        findsOneWidget,
      );
      await tester.tap(find.text('❤️'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('chatReactionChip_❤️_1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'selecting a custom emoji through more reactions updates inline chips optimistically',
    (tester) async {
      final createdAt = DateTime.utc(2026, 3, 31, 12, 30);
      final message = textMessage(
        id: 'reaction-more-target',
        senderId: 'other',
        body: 'more emoji',
        createdAt: createdAt,
      );
      final repository = _FakeChatMessageRepository(
        cachedMessages: <ChatMessage>[message],
        canonicalMessages: <ChatMessage>[message],
      );
      final messageActionService = ChatMessageActionService(
        deleteReaction: ({required messageId, required userId}) async {
          repository.removeReaction(messageId: messageId, userId: userId);
        },
        upsertReaction: (payload) async {
          repository.setReaction(
            messageId: payload['message_id'] as String,
            userId: payload['user_id'] as String,
            emoji: payload['emoji'] as String,
          );
        },
      );
      const runtime = ChatRoomViewRuntime(
        currentUserId: 'me',
        disableRealtime: true,
      );

      await pumpChatRoom(
        tester,
        repository: repository,
        runtime: runtime,
        messageActionService: messageActionService,
      );

      await tester.longPress(
        find.byKey(const ValueKey('chatMessageSurface_reaction-more-target')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('chatMessageActionOverlayScrim')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('chatMessageActionSheetMoreReactions')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey('chatEmojiPickerTitle')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('chatEmojiPickerSuggestion_😀')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey('chatReactionChip_😀_1')),
        findsOneWidget,
      );
    },
  );

  testWidgets('editing own text message updates body and edited marker', (
    tester,
  ) async {
    final createdAt = DateTime.utc(2026, 4, 19, 12);
    final message = textMessage(
      id: 'editable-message',
      senderId: 'me',
      body: 'before edit',
      createdAt: createdAt,
    );
    final repository = _FakeChatMessageRepository(
      cachedMessages: <ChatMessage>[message],
      canonicalMessages: <ChatMessage>[message],
    );
    final messageActionService = ChatMessageActionService(
      editText: ({required roomId, required messageId, required text}) async {
        return textMessageRow(
          id: messageId,
          senderId: 'me',
          body: text,
          createdAt: createdAt,
          editedAt: DateTime.utc(2026, 4, 19, 12, 1),
        );
      },
    );
    const runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
    );

    await pumpChatRoom(
      tester,
      repository: repository,
      runtime: runtime,
      messageActionService: messageActionService,
    );

    await tester.longPress(
      find.byKey(const ValueKey('chatMessageSurface_editable-message')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chatEditMessageTextField')),
      'after edit',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(findRenderedText('after edit'), findsOneWidget);
    expect(find.text('before edit'), findsNothing);
    expect(find.text('edited'), findsOneWidget);
  });

  testWidgets('deleting own text message renders deleted placeholder', (
    tester,
  ) async {
    final createdAt = DateTime.utc(2026, 4, 19, 12);
    final message = textMessage(
      id: 'delete-message',
      senderId: 'me',
      body: 'delete me',
      createdAt: createdAt,
    );
    final repository = _FakeChatMessageRepository(
      cachedMessages: <ChatMessage>[message],
      canonicalMessages: <ChatMessage>[message],
    );
    var deleteCalled = false;
    final messageActionService = ChatMessageActionService(
      deleteText: ({required roomId, required messageId}) async {
        deleteCalled = true;
        return textMessageRow(
          id: messageId,
          senderId: 'me',
          body: '',
          createdAt: createdAt,
          deletedAt: DateTime.utc(2026, 4, 19, 12, 1),
          deletedBy: 'me',
        )..['body'] = null;
      },
    );
    const runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
    );

    await pumpChatRoom(
      tester,
      repository: repository,
      runtime: runtime,
      messageActionService: messageActionService,
    );

    await tester.longPress(
      find.byKey(const ValueKey('chatMessageSurface_delete-message')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete message'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('chatDeleteMessageConfirmButton')),
    );
    await tester.pumpAndSettle();

    expect(deleteCalled, isTrue);
    expect(findRenderedText('Message deleted'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! RichText ||
            widget.text.toPlainText() != 'Message deleted') {
          return false;
        }
        final textSpan = widget.text;
        if (textSpan is! TextSpan || textSpan.children?.isEmpty != false) {
          return false;
        }
        final deletedSpan = textSpan.children!.first;
        return deletedSpan is TextSpan &&
            deletedSpan.style?.fontSize == 13 &&
            deletedSpan.style?.fontStyle == FontStyle.italic &&
            deletedSpan.style?.color != null;
      }),
      findsOneWidget,
    );
    expect(find.text('delete me'), findsNothing);
  });

  testWidgets('deleted messages do not open long-press actions', (
    tester,
  ) async {
    final message = textMessage(
      id: 'deleted-message',
      senderId: 'me',
      body: '',
      createdAt: DateTime.utc(2026, 4, 19, 12),
      deletedAt: DateTime.utc(2026, 4, 19, 12, 1),
      deletedBy: 'me',
    ).copyWith(clearBody: true);
    final repository = _FakeChatMessageRepository(
      cachedMessages: <ChatMessage>[message],
      canonicalMessages: <ChatMessage>[message],
    );
    const runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
    );

    await pumpChatRoom(tester, repository: repository, runtime: runtime);

    await tester.longPress(
      find.byKey(const ValueKey('chatMessageSurface_deleted-message')),
    );
    await tester.pumpAndSettle();

    expect(findRenderedText('Message deleted'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chatMessageActionSheetOptionsCard')),
      findsNothing,
    );
  });

  testWidgets('runtime message update edits visible row in place', (
    tester,
  ) async {
    final updatedMessages = StreamController<ChatMessage>.broadcast(sync: true);
    addTearDown(updatedMessages.close);
    final createdAt = DateTime.utc(2026, 4, 19, 12);
    final message = textMessage(
      id: 'runtime-update-message',
      senderId: 'other',
      body: 'before realtime',
      createdAt: createdAt,
    );
    final repository = _FakeChatMessageRepository(
      cachedMessages: <ChatMessage>[message],
      canonicalMessages: <ChatMessage>[message],
    );
    final runtime = ChatRoomViewRuntime(
      currentUserId: 'me',
      disableRealtime: true,
      updatedMessages: updatedMessages.stream,
    );

    await pumpChatRoom(tester, repository: repository, runtime: runtime);

    updatedMessages.add(
      message.copyWith(
        body: 'after realtime',
        editedAt: DateTime.utc(2026, 4, 19, 12, 1),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(findRenderedText('after realtime'), findsOneWidget);
    expect(find.text('before realtime'), findsNothing);
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
