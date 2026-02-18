import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/features/chat/widgets/chat_message_tile.dart';
import 'package:pet/l10n/app_localizations.dart';

ChatMessage _systemMessage({required String body, int coinsAwarded = 0}) {
  return ChatMessage(
    id: 'msg-1',
    roomId: 'room-1',
    senderId: null,
    type: 'system',
    body: body,
    imageUrl: null,
    caption: null,
    coinsAwarded: coinsAwarded,
    createdAt: DateTime(2026, 1, 1),
    clientCreatedAt: null,
    labels: const <Map<String, dynamic>>[],
    localImagePath: null,
  );
}

Future<void> _pumpSystemTile(
  WidgetTester tester, {
  required ChatMessage message,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatMessageTile(
          message: message,
          isMe: false,
          isOptimistic: false,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders urgent hunger alert with pet name', (tester) async {
    await _pumpSystemTile(
      tester,
      message: _systemMessage(body: 'hunger_alert_10::Milo'),
    );

    expect(find.text('Milo is very hungry! Please feed now!'), findsOneWidget);
  });

  testWidgets('uses fallback pet name for empty hunger alert payload', (
    tester,
  ) async {
    await _pumpSystemTile(
      tester,
      message: _systemMessage(body: 'hunger_alert_30::'),
    );

    expect(
      find.text('Your pet is getting hungry. Time to feed!'),
      findsOneWidget,
    );
  });

  testWidgets('localizes clean-poop system message and candy label', (
    tester,
  ) async {
    await _pumpSystemTile(
      tester,
      message: _systemMessage(body: 'Alex cleaned the poop', coinsAwarded: 7),
    );

    expect(find.text('Alex cleaned the poop: +7 Candys.'), findsOneWidget);
  });
}
