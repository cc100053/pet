import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet/features/onboarding/onboarding_entry_view.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/services/invite/invite_link_service.dart';
import 'package:pet/services/invite/pending_invite_code_store.dart';

class _MemoryStore implements PendingInviteCodeStore {
  _MemoryStore([this.pendingInviteCode]);

  @override
  String? pendingInviteCode;

  @override
  Future<void> setPendingInviteCode(String? code) async {
    pendingInviteCode = code;
  }
}

class _NoLinks implements InviteLinkGateway {
  @override
  Future<Uri?> getInitialLink() async => null;

  @override
  Stream<Uri> get uriLinkStream => const Stream.empty();
}

Future<_MemoryStore> _pump(WidgetTester tester, {String? pending}) async {
  final store = _MemoryStore(pending);
  final service = AppInviteLinkService(
    gateway: _NoLinks(),
    settingsStore: store,
  );
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OnboardingEntryView(inviteLinkService: service),
    ),
  );
  await _settle(tester);
  return store;
}

// Pet animations loop forever, so pump bounded time instead of settling.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const _welcomeTitle = 'Raise a pet together';
const _invitedTitle = "You've been invited to raise a pet";

void main() {
  testWidgets('fresh install shows the welcome fork', (tester) async {
    await _pump(tester);
    expect(find.text(_welcomeTitle), findsOneWidget);
    expect(find.text('Start a new pet'), findsOneWidget);
    expect(find.text('I was invited'), findsOneWidget);
  });

  testWidgets('start new opens sign-in, back returns to welcome', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Start a new pet'));
    await _settle(tester);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text(_invitedTitle), findsNothing);

    await tester.tap(find.byType(OnboardingBackButton));
    await _settle(tester);
    expect(find.text(_welcomeTitle), findsOneWidget);
  });

  testWidgets('pending invite link skips the fork', (tester) async {
    await _pump(tester, pending: 'AB12CD');
    expect(find.text(_welcomeTitle), findsNothing);
    expect(find.text(_invitedTitle), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('invite code entry validates, stores and lands invited', (
    tester,
  ) async {
    final store = await _pump(tester);
    await tester.tap(find.text('I was invited'));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'ab1');
    await tester.tap(find.text('Continue'));
    await _settle(tester);
    expect(
      find.text('That invite code is invalid or expired.'),
      findsOneWidget,
    );
    expect(store.pendingInviteCode, isNull);

    await tester.enterText(find.byType(TextField), 'ab12cd');
    await tester.tap(find.text('Continue'));
    await _settle(tester);
    expect(store.pendingInviteCode, 'AB12CD');
    expect(find.text(_invitedTitle), findsOneWidget);
  });

  testWidgets('back from invited sign-in clears the pending code', (
    tester,
  ) async {
    final store = await _pump(tester, pending: 'AB12CD');
    await tester.tap(find.byType(OnboardingBackButton));
    await _settle(tester);
    expect(store.pendingInviteCode, isNull);
    expect(find.text(_welcomeTitle), findsOneWidget);
  });
}
