import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/features/chat/widgets/chat_message_tile.dart';
import 'package:pet/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

ChatMessage _replyMessage() {
  return ChatMessage(
    id: 'msg-2',
    roomId: 'room-1',
    senderId: 'user-2',
    type: 'text',
    body: 'See you at 8',
    imageUrl: null,
    caption: null,
    coinsAwarded: 0,
    createdAt: DateTime(2026, 3, 8, 12, 0),
    clientCreatedAt: null,
    labels: const <Map<String, dynamic>>[],
    localImagePath: null,
    replyToMessageId: 'msg-1',
    replyPreview: ChatReplyPreview(
      id: 'msg-1',
      senderId: 'user-1',
      type: 'text',
      body: 'Dinner tonight?',
      imageUrl: null,
      caption: null,
    ),
  );
}

void main() {
  testWidgets('renders quoted reply preview inside text bubble', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ChatMessageTile(
          message: _replyMessage(),
          isMe: false,
          isOptimistic: false,
          senderName: 'Alex',
          replySenderName: 'Jamie',
        ),
      ),
    );

    expect(find.text('Jamie'), findsOneWidget);
    expect(find.text('Dinner tonight?'), findsOneWidget);
    expect(find.text('See you at 8'), findsOneWidget);
  });

  testWidgets('swiping left triggers reply callback once', (tester) async {
    var replyCount = 0;

    await tester.pumpWidget(
      _wrap(
        ChatMessageTile(
          message: _replyMessage(),
          isMe: false,
          isOptimistic: false,
          senderName: 'Alex',
          replySenderName: 'Jamie',
          onSwipeReply: () {
            replyCount += 1;
          },
        ),
      ),
    );

    await tester.drag(find.text('See you at 8'), const Offset(-90, 0));
    await tester.pumpAndSettle();

    expect(replyCount, 1);
  });
}
