import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet/features/auth/sign_in_view.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  testWidgets('Sign-in view renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SignInView(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/app/LoginPage.png',
        description: 'LoginPage image asset',
      ),
      findsOneWidget,
    );
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
  });
}
