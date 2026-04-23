import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/debug/dress_up_fit_tool_page.dart';

void main() {
  Widget buildHarness() {
    return const MaterialApp(home: DressUpFitToolPage());
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('shows selectors and generated snippets', (tester) async {
    await tester.pumpWidget(buildHarness());

    expect(find.text('Dress-up Fit Tool'), findsOneWidget);
    expect(find.byKey(const Key('dress_up_fit_pet_dropdown')), findsOneWidget);
    expect(
      find.byKey(const Key('dress_up_fit_equipment_dropdown')),
      findsOneWidget,
    );
    expect(find.text('Pet socket snippet'), findsOneWidget);
    expect(
      find.text('PetEquipmentSlot.head: PetSocket(x: 0.50, y: 0.23),'),
      findsOneWidget,
    );
  });

  testWidgets('changing socket slider updates generated snippet', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness());

    final slider = tester.widget<Slider>(
      find.byKey(const Key('dress_up_fit_socket_x_slider')),
    );
    slider.onChanged!(0.61);
    await tester.pump();

    expect(
      find.text('PetEquipmentSlot.head: PetSocket(x: 0.61, y: 0.23),'),
      findsOneWidget,
    );
  });

  testWidgets('reset socket restores catalog value', (tester) async {
    await tester.pumpWidget(buildHarness());

    final slider = tester.widget<Slider>(
      find.byKey(const Key('dress_up_fit_socket_x_slider')),
    );
    slider.onChanged!(0.61);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Reset socket'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Reset socket'));
    await tester.pump();

    expect(
      find.text('PetEquipmentSlot.head: PetSocket(x: 0.50, y: 0.23),'),
      findsOneWidget,
    );
  });

  testWidgets('copy button writes snippet and shows copied feedback', (
    tester,
  ) async {
    final methodCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          methodCalls.add(call);
          return null;
        });

    await tester.pumpWidget(buildHarness());
    await tester.scrollUntilVisible(
      find.text('Pet socket snippet'),
      700,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Copy').first);
    await tester.pump();

    expect(
      methodCalls.where((call) => call.method == 'Clipboard.setData'),
      isNotEmpty,
    );
    expect(find.text('Copied pet socket snippet.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
