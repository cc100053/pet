import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/widgets/chat_keyboard_dismiss_shell.dart';

void main() {
  const composerFieldKey = ValueKey('composerField');
  const composerHandleKey = ValueKey('composerHandle');
  const timelineKey = ValueKey('timeline');
  const backdropKey = ValueKey('backdrop');

  bool composerHasFocus(WidgetTester tester) {
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    return editable.focusNode.hasFocus;
  }

  Future<void> focusComposer(WidgetTester tester) async {
    await tester.tap(find.byKey(composerFieldKey));
    await tester.pump();
    await tester.showKeyboard(find.byKey(composerFieldKey));
    await tester.pump();
  }

  group('chat keyboard dismiss UX', () {
    test(
      'keyboard bottom inset never drops below safe area during dismiss',
      () {
        expect(
          resolveChatKeyboardBottomInset(keyboardInset: 20, safeAreaInset: 34),
          34,
        );
        expect(
          resolveChatKeyboardBottomInset(keyboardInset: 120, safeAreaInset: 34),
          120,
        );
        expect(
          resolveChatKeyboardBottomInset(keyboardInset: 0, safeAreaInset: 34),
          34,
        );
      },
    );

    testWidgets('dragging the timeline keeps composer focus', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _ChatKeyboardHarness()));

      await focusComposer(tester);
      expect(composerHasFocus(tester), isTrue);

      await tester.drag(find.byKey(timelineKey), const Offset(0, -180));
      await tester.pump();

      expect(composerHasFocus(tester), isTrue);
    });

    testWidgets('tapping outside dismisses the composer focus', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _ChatKeyboardHarness()));

      await focusComposer(tester);
      expect(composerHasFocus(tester), isTrue);

      await tester.tap(find.byKey(backdropKey));
      await tester.pump();

      expect(composerHasFocus(tester), isFalse);
    });

    testWidgets('dragging down from the composer handle dismisses focus', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: _ChatKeyboardHarness()));

      await focusComposer(tester);
      expect(composerHasFocus(tester), isTrue);

      await tester.drag(find.byKey(composerHandleKey), const Offset(0, 42));
      await tester.pump();

      expect(composerHasFocus(tester), isFalse);
    });

    testWidgets('dragging from timeline into composer dismisses focus', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: _ChatKeyboardHarness()));

      await focusComposer(tester);
      expect(composerHasFocus(tester), isTrue);

      final timelineCenter = tester.getCenter(find.byKey(timelineKey));
      final composerRect = tester.getRect(find.byKey(composerFieldKey));
      final gesture = await tester.startGesture(
        Offset(timelineCenter.dx, timelineCenter.dy - 120),
      );
      await tester.pump();
      await gesture.moveTo(
        Offset(composerRect.center.dx, composerRect.top + 6),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 36));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(composerHasFocus(tester), isFalse);
    });

    testWidgets('entering composer then dragging back up keeps focus', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: _ChatKeyboardHarness()));

      await focusComposer(tester);
      expect(composerHasFocus(tester), isTrue);

      final timelineCenter = tester.getCenter(find.byKey(timelineKey));
      final composerRect = tester.getRect(find.byKey(composerFieldKey));
      final gesture = await tester.startGesture(
        Offset(timelineCenter.dx, timelineCenter.dy - 120),
      );
      await tester.pump();
      await gesture.moveTo(
        Offset(composerRect.center.dx, composerRect.top + 6),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -28));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(composerHasFocus(tester), isTrue);
    });

    testWidgets('shared chat timeline keyboard dismiss behavior stays manual', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: _ChatKeyboardHarness()));

      final timeline = tester.widget<ListView>(find.byKey(timelineKey));

      expect(
        timeline.keyboardDismissBehavior,
        chatTimelineKeyboardDismissBehavior,
      );
      expect(
        chatTimelineKeyboardDismissBehavior,
        ScrollViewKeyboardDismissBehavior.manual,
      );
    });

    testWidgets('right drag from left half triggers pop', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _BackSwipeHarness()));

      final size = tester.getSize(find.byType(Scaffold));
      final gesture = await tester.startGesture(Offset(size.width * 0.2, 160));
      await tester.pump();
      await gesture.moveBy(const Offset(90, 6));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(find.text('popped'), findsOneWidget);
    });

    testWidgets('right drag from right half does not trigger pop', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: _BackSwipeHarness()));

      final size = tester.getSize(find.byType(Scaffold));
      final gesture = await tester.startGesture(Offset(size.width * 0.8, 160));
      await tester.pump();
      await gesture.moveBy(const Offset(90, 6));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(find.text('popped'), findsNothing);
    });

    testWidgets('composer region is excluded from back swipe pop', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: _BackSwipeHarness()));

      final composerRect = tester.getRect(
        find.byKey(const ValueKey('composerRegionFinder')),
      );
      final gesture = await tester.startGesture(
        composerRect.centerLeft + const Offset(4, 0),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(90, 4));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(find.text('popped'), findsNothing);
    });
  });
}

class _ChatKeyboardHarness extends StatefulWidget {
  const _ChatKeyboardHarness();

  @override
  State<_ChatKeyboardHarness> createState() => _ChatKeyboardHarnessState();
}

class _ChatKeyboardHarnessState extends State<_ChatKeyboardHarness> {
  static const _composerFieldKey = ValueKey('composerField');
  static const _composerHandleKey = ValueKey('composerHandle');
  static const _timelineKey = ValueKey('timeline');
  static const _backdropKey = ValueKey('backdrop');

  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  final GlobalKey _composerSurfaceKey = GlobalKey();
  final GlobalKey _composerInputRegionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = _focusNode.hasFocus ? 320.0 : 0.0;

    return Scaffold(
      body: ChatKeyboardSweepDismissLayer(
        focusNode: _focusNode,
        keyboardInset: keyboardInset,
        composerKey: _composerSurfaceKey,
        protectedRegionKey: _composerInputRegionKey,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: _backdropKey,
                behavior: HitTestBehavior.translucent,
                onTap: _focusNode.unfocus,
                child: ListView.builder(
                  key: _timelineKey,
                  reverse: true,
                  keyboardDismissBehavior: chatTimelineKeyboardDismissBehavior,
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 120),
                  itemCount: 20,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: index.isEven
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('Message $index'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: ChatComposerDismissShell(
                focusNode: _focusNode,
                keyboardInset: keyboardInset,
                contentKey: _composerSurfaceKey,
                handleKey: _composerHandleKey,
                child: Material(
                  color: Colors.white,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Container(
                      key: _composerInputRegionKey,
                      child: TextField(
                        key: _composerFieldKey,
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Message',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackSwipeHarness extends StatefulWidget {
  const _BackSwipeHarness();

  @override
  State<_BackSwipeHarness> createState() => _BackSwipeHarnessState();
}

class _BackSwipeHarnessState extends State<_BackSwipeHarness> {
  final GlobalKey _composerRegionKey = GlobalKey();
  var _didPop = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatBackSwipePopLayer(
        excludedRegionKey: _composerRegionKey,
        onPop: () => setState(() => _didPop = true),
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.blueGrey.shade50)),
            if (_didPop)
              const Positioned(top: 40, left: 20, child: Text('popped')),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                key: _composerRegionKey,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const KeyedSubtree(
                  key: ValueKey('composerRegionFinder'),
                  child: Text('Composer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
