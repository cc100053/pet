import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/ui/keyboard_dismiss_utils.dart';

void main() {
  group('keyboard dismiss helpers', () {
    testWidgets('tap outside unfocuses the active text field', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: SizedBox()),
                Center(
                  child: SizedBox(
                    width: 240,
                    child: TextField(
                      focusNode: focusNode,
                      onTapOutside: dismissKeyboardOnTapOutside,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tapAt(const Offset(12, 12));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('scroll drag dismisses keyboard on form surfaces', (
      tester,
    ) async {
      final focusNode = FocusNode();
      final controller = ScrollController(initialScrollOffset: 200);
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              keyboardDismissBehavior: formScrollKeyboardDismissBehavior,
              child: Column(
                children: [
                  const SizedBox(height: 320),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: TextField(
                      focusNode: focusNode,
                      onTapOutside: dismissKeyboardOnTapOutside,
                    ),
                  ),
                  const SizedBox(height: 800),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 160),
      );
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });
  });
}
