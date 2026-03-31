import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/widgets/chat_reaction_details_sheet.dart';
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

List<ChatReactionDetailsSheetEntry> _entries() {
  return <ChatReactionDetailsSheetEntry>[
    ChatReactionDetailsSheetEntry(
      userId: 'me',
      displayName: 'You',
      emoji: '👍',
      createdAt: DateTime.utc(2026, 3, 31, 10),
      isCurrentUser: true,
    ),
    ChatReactionDetailsSheetEntry(
      userId: 'other',
      displayName: 'Other',
      emoji: '❤️',
      createdAt: DateTime.utc(2026, 3, 31, 9),
    ),
  ];
}

void main() {
  testWidgets('renders reaction header, filters, and participant rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ChatReactionDetailsSheet(
          reactionOptions: const <String>['👍', '❤️'],
          entries: _entries(),
          selectedReactionEmoji: '👍',
          initialFilterEmoji: '👍',
          copyEnabled: true,
          isMine: false,
          isBlocked: false,
          onReactionSelected: (_) async => null,
        ),
      ),
    );

    expect(find.text('2 reactions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chatReactionSheetFilterAll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chatReactionSheetFilter_👍')),
      findsOneWidget,
    );
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Other'), findsNothing);
  });

  testWidgets('all filter reveals all reaction rows', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChatReactionDetailsSheet(
          reactionOptions: const <String>['👍', '❤️'],
          entries: _entries(),
          selectedReactionEmoji: '👍',
          initialFilterEmoji: '👍',
          copyEnabled: true,
          isMine: false,
          isBlocked: false,
          onReactionSelected: (_) async => null,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('chatReactionSheetFilterAll')));
    await tester.pump();

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
  });

  testWidgets('reaction tap updates entries and stays filtered to new emoji', (
    tester,
  ) async {
    String? selectedEmoji;

    await tester.pumpWidget(
      _wrap(
        ChatReactionDetailsSheet(
          reactionOptions: const <String>['👍', '❤️'],
          entries: _entries(),
          selectedReactionEmoji: '👍',
          initialFilterEmoji: '👍',
          copyEnabled: true,
          isMine: false,
          isBlocked: false,
          onReactionSelected: (emoji) async {
            selectedEmoji = emoji;
            return ChatReactionDetailsSheetUpdate(
              entries: <ChatReactionDetailsSheetEntry>[
                ChatReactionDetailsSheetEntry(
                  userId: 'me',
                  displayName: 'You',
                  emoji: '❤️',
                  createdAt: DateTime.utc(2026, 3, 31, 11),
                  isCurrentUser: true,
                ),
                ChatReactionDetailsSheetEntry(
                  userId: 'other',
                  displayName: 'Other',
                  emoji: '❤️',
                  createdAt: DateTime.utc(2026, 3, 31, 10),
                ),
              ],
              selectedReactionEmoji: '❤️',
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('chatReactionSheetFilter_❤️')));
    await tester.pump();
    await tester.pump();

    expect(selectedEmoji, '❤️');
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('2 reactions'), findsOneWidget);
  });

  testWidgets('own-message sheet hides moderation actions', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChatReactionDetailsSheet(
          reactionOptions: const <String>['👍', '❤️'],
          entries: _entries(),
          selectedReactionEmoji: '👍',
          initialFilterEmoji: '👍',
          copyEnabled: true,
          isMine: true,
          isBlocked: false,
          onReactionSelected: (_) async => null,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('chatReactionSheetReplyAction')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chatReactionSheetCopyAction')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chatReactionSheetReportAction')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('chatReactionSheetBlockAction')),
      findsNothing,
    );
  });

  testWidgets('can hide message actions entirely for reaction-only sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ChatReactionDetailsSheet(
          reactionOptions: const <String>['👍', '❤️'],
          entries: _entries(),
          selectedReactionEmoji: '👍',
          initialFilterEmoji: '👍',
          copyEnabled: false,
          isMine: false,
          isBlocked: false,
          showMessageActions: false,
          onReactionSelected: (_) async => null,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('chatReactionSheetReplyAction')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('chatReactionSheetCopyAction')),
      findsNothing,
    );
  });
}
