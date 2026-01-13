import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet/features/auth/sign_in_view.dart';

void main() {
  testWidgets('Sign-in view renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SignInView()),
    );
    expect(find.text('PicPet'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
  });
}
