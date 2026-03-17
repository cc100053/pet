import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/services/performance/memory_diagnostics_service.dart';
import 'package:pet/shared/debug/memory_diagnostics_sheet.dart';

void main() {
  testWidgets('renders empty state when no snapshots exist', (tester) async {
    final snapshots = ValueNotifier<List<MemoryDiagnosticsSnapshot>>(
      const <MemoryDiagnosticsSnapshot>[],
    );

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
          body: MemoryDiagnosticsSheet(snapshotsListenable: snapshots),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('memory-diagnostics-sheet-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('memory-diagnostics-sheet-empty')),
      findsOneWidget,
    );
  });

  testWidgets('renders recent snapshot summaries', (tester) async {
    final snapshots = ValueNotifier<List<MemoryDiagnosticsSnapshot>>(
      <MemoryDiagnosticsSnapshot>[
        MemoryDiagnosticsSnapshot(
          capturedAt: DateTime(2026, 3, 17, 9, 30),
          source: 'chat_initial_messages_loaded',
          route: 'chat_room_view_v2',
          roomId: 'room-1',
          imageCacheCount: 12,
          imageCacheBytes: 24 * 1024 * 1024,
          imageCacheLiveImages: 2,
          imageCachePendingImages: 0,
          imageCacheMaxCount: 150,
          imageCacheMaxBytes: 192 * 1024 * 1024,
          activeChannels: 3,
          messageCount: 20,
          imageMessageCount: 6,
          optimisticMessageCount: 1,
          deltaImageCacheBytes: 4 * 1024 * 1024,
          deltaActiveChannels: 1,
          deltaMessageCount: 5,
        ),
      ],
    );

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
          body: MemoryDiagnosticsSheet(snapshotsListenable: snapshots),
        ),
      ),
    );

    expect(find.text('Memory Diagnostics'), findsOneWidget);
    expect(find.textContaining('chat_initial_messages_loaded'), findsOneWidget);
    expect(find.textContaining('messages=20'), findsOneWidget);
  });
}
