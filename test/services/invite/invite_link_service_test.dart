import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/invite/invite_link_service.dart';
import 'package:pet/services/invite/pending_invite_code_store.dart';

void main() {
  group('AppInviteLinkService', () {
    test('parses hosted invite links', () {
      final uri = Uri.parse('https://pet-app-702be.web.app/invite?code=12ab34');

      expect(AppInviteLinkService.parseInviteCode(uri), '12AB34');
    });

    test('parses custom scheme invite links', () {
      final uri = Uri.parse('com.cc100053.pet://invite?code=987654');

      expect(AppInviteLinkService.parseInviteCode(uri), '987654');
    });

    test('rejects unrelated or malformed invite links', () {
      expect(
        AppInviteLinkService.parseInviteCode(
          Uri.parse('https://example.com/invite?code=123456'),
        ),
        isNull,
      );
      expect(
        AppInviteLinkService.parseInviteCode(
          Uri.parse('https://pet-app-702be.web.app/invite?code=12345'),
        ),
        isNull,
      );
    });

    test('builds localized share text with the hosted invite link', () {
      final text = AppInviteLinkService.shareText(
        caption: 'Join me in Petttomo',
        code: 'abc123',
      );

      expect(text, contains('Join me in Petttomo'));
      expect(
        text,
        contains('https://pet-app-702be.web.app/invite?code=ABC123'),
      );
    });

    test('stores pending invite code from initial link and stream', () async {
      final gateway = _FakeInviteLinkGateway(
        initialLink: Uri.parse(
          'https://pet-app-702be.web.app/invite?code=111222',
        ),
      );
      final store = _FakePendingInviteCodeStore();
      final service = AppInviteLinkService(
        gateway: gateway,
        settingsStore: store,
      );

      await service.initialize();

      expect(store.pendingInviteCode, '111222');

      final emittedInvite = expectLater(service.inviteCodes, emits('ABC123'));
      gateway.add(Uri.parse('com.cc100053.pet://invite?code=abc123'));
      await emittedInvite;

      expect(store.pendingInviteCode, 'ABC123');
      await service.clearPendingInviteCode();
      expect(store.pendingInviteCode, isNull);
      await service.dispose();
    });
  });
}

class _FakeInviteLinkGateway implements InviteLinkGateway {
  _FakeInviteLinkGateway({this.initialLink});

  final Uri? initialLink;
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> getInitialLink() async => initialLink;

  @override
  Stream<Uri> get uriLinkStream => _controller.stream;

  void add(Uri uri) {
    _controller.add(uri);
  }
}

class _FakePendingInviteCodeStore implements PendingInviteCodeStore {
  @override
  String? pendingInviteCode;

  @override
  Future<void> setPendingInviteCode(String? code) async {
    pendingInviteCode = code;
  }
}
