import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/widgets/chat_message_action_sheet.dart';
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
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('own-message sheet hides moderation actions', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChatMessageActionSheet(
          reactionOptions: const <String>['👍', '❤️'],
          selectedReaction: '👍',
          copyEnabled: true,
          isMine: true,
          isBlocked: false,
          onReactionSelected: (_) {},
          onReply: () {},
          onCopy: () {},
          onReport: () {},
          onBlock: () {},
        ),
      ),
    );

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Report message'), findsNothing);
    expect(find.text('Block user'), findsNothing);
  });

  testWidgets('other-message sheet shows moderation actions', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChatMessageActionSheet(
          reactionOptions: const <String>['👍', '❤️'],
          selectedReaction: null,
          copyEnabled: false,
          isMine: false,
          isBlocked: false,
          onReactionSelected: (_) {},
          onReply: () {},
          onCopy: () {},
          onReport: () {},
          onBlock: () {},
        ),
      ),
    );

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Report message'), findsOneWidget);
    expect(find.text('Block user'), findsOneWidget);
  });

  testWidgets('reaction tap returns selected emoji', (tester) async {
    String? selectedEmoji;

    await tester.pumpWidget(
      _wrap(
        ChatMessageActionSheet(
          reactionOptions: const <String>['👍', '❤️'],
          selectedReaction: null,
          copyEnabled: true,
          isMine: false,
          isBlocked: false,
          onReactionSelected: (emoji) => selectedEmoji = emoji,
          onReply: () {},
          onCopy: () {},
          onReport: () {},
          onBlock: () {},
        ),
      ),
    );

    await tester.tap(find.text('❤️'));
    await tester.pump();

    expect(selectedEmoji, '❤️');
  });
}
