import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/onboarding_focus_utils.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'resolveOnboardingFocusTargetRects returns both room entry rects',
    (WidgetTester tester) async {
      final createKey = GlobalKey();
      final joinKey = GlobalKey();
      BuildContext? overlayContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: Builder(
                    builder: (context) {
                      overlayContext = context;
                      return const SizedBox.expand();
                    },
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 40,
                  child: SizedBox(key: createKey, width: 180, height: 54),
                ),
                Positioned(
                  right: 20,
                  top: 12,
                  child: SizedBox(key: joinKey, width: 150, height: 40),
                ),
              ],
            ),
          ),
        ),
      );

      final rects = resolveOnboardingFocusTargetRects(
        overlayContext: overlayContext!,
        targetKeys: <GlobalKey>[createKey, joinKey],
      );

      expect(rects, hasLength(2));
      expect(rects[0], tester.getRect(find.byKey(createKey)));
      expect(rects[1], tester.getRect(find.byKey(joinKey)));
    },
  );

  testWidgets('english onboarding room entry copy mentions both choices', (
    WidgetTester tester,
  ) async {
    String? title;
    String? body;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            title = l10n.onboardingRoomEntryPromptTitle;
            body = l10n.onboardingRoomEntryPromptBody;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(title, 'Create a room or enter an invite code.');
    expect(
      body,
      'Start your pet home by creating a new room, or join one with a code.',
    );
  });
}
