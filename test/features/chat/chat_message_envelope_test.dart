import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/features/chat/widgets/chat_message_envelope.dart';
import 'package:pet/shared/ui/user_avatar.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 360, child: child)),
    ),
  );
}

Widget _bubble({Key? key}) {
  return Container(
    key: key,
    width: 120,
    height: 48,
    decoration: BoxDecoration(
      color: Colors.teal.shade100,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

void main() {
  testWidgets(
    'received ungrouped message shows avatar and shifts bubble column',
    (tester) async {
      final avatarSlotKey = GlobalKey();
      final avatarKey = GlobalKey();
      final bubbleColumnKey = GlobalKey();
      final bubbleKey = GlobalKey();

      await tester.pumpWidget(
        _wrap(
          Align(
            alignment: Alignment.centerLeft,
            child: ChatMessageEnvelope(
              isSentByMe: false,
              isDarkBackground: false,
              reactions: const <ChatMessageReactionSummary>[],
              avatar: 'preset:1',
              fallbackText: 'Alex',
              showReceivedAvatar: true,
              avatarSlotKey: avatarSlotKey,
              avatarKey: avatarKey,
              bubbleColumnKey: bubbleColumnKey,
              child: _bubble(key: bubbleKey),
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);

      final avatarSlotLeft = tester.getTopLeft(find.byKey(avatarSlotKey)).dx;
      final bubbleColumnLeft = tester
          .getTopLeft(find.byKey(bubbleColumnKey))
          .dx;

      expect(
        bubbleColumnLeft - avatarSlotLeft,
        closeTo(ChatMessageEnvelope.receivedAvatarSlotWidth, 0.1),
      );
      final avatarBottom = tester.getBottomLeft(find.byKey(avatarKey)).dy;
      final bubbleBottom = tester.getBottomLeft(find.byKey(bubbleKey)).dy;
      expect(
        bubbleBottom - avatarBottom,
        closeTo(ChatMessageEnvelope.receivedAvatarVerticalOffset.abs(), 0.1),
      );
    },
  );

  testWidgets(
    'received grouped non-last message keeps bubble column position without avatar',
    (tester) async {
      final avatarSlotKey = GlobalKey();
      final bubbleColumnKey = GlobalKey();

      Future<double> pumpEnvelope({required bool showReceivedAvatar}) async {
        await tester.pumpWidget(
          _wrap(
            Align(
              alignment: Alignment.centerLeft,
              child: ChatMessageEnvelope(
                isSentByMe: false,
                isDarkBackground: false,
                reactions: const <ChatMessageReactionSummary>[],
                avatar: 'preset:1',
                fallbackText: 'Alex',
                showReceivedAvatar: showReceivedAvatar,
                avatarSlotKey: avatarSlotKey,
                bubbleColumnKey: bubbleColumnKey,
                child: _bubble(),
              ),
            ),
          ),
        );
        return tester.getTopLeft(find.byKey(bubbleColumnKey)).dx;
      }

      final withAvatarLeft = await pumpEnvelope(showReceivedAvatar: true);
      expect(find.byType(UserAvatar), findsOneWidget);

      final hiddenAvatarLeft = await pumpEnvelope(showReceivedAvatar: false);
      expect(find.byType(UserAvatar), findsNothing);

      final avatarSlotLeft = tester.getTopLeft(find.byKey(avatarSlotKey)).dx;
      expect(hiddenAvatarLeft, closeTo(withAvatarLeft, 0.1));
      expect(
        hiddenAvatarLeft - avatarSlotLeft,
        closeTo(ChatMessageEnvelope.receivedAvatarSlotWidth, 0.1),
      );
    },
  );

  testWidgets('sent message stays right aligned without avatar slot', (
    tester,
  ) async {
    final hostKey = GlobalKey();
    final bubbleColumnKey = GlobalKey();

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          key: hostKey,
          width: 320,
          child: Align(
            alignment: Alignment.centerRight,
            child: ChatMessageEnvelope(
              isSentByMe: true,
              isDarkBackground: false,
              reactions: const <ChatMessageReactionSummary>[],
              bubbleColumnKey: bubbleColumnKey,
              child: _bubble(),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(UserAvatar), findsNothing);

    final hostRight = tester.getTopRight(find.byKey(hostKey)).dx;
    final bubbleColumnRight = tester
        .getTopRight(find.byKey(bubbleColumnKey))
        .dx;

    expect(bubbleColumnRight, closeTo(hostRight - 2, 0.1));
  });

  testWidgets('reaction bar stays under bubble column instead of avatar slot', (
    tester,
  ) async {
    final bubbleColumnKey = GlobalKey();
    final reactionBarKey = GlobalKey();
    final avatarKey = GlobalKey();

    await tester.pumpWidget(
      _wrap(
        Align(
          alignment: Alignment.centerLeft,
          child: ChatMessageEnvelope(
            isSentByMe: false,
            isDarkBackground: false,
            reactions: const <ChatMessageReactionSummary>[
              ChatMessageReactionSummary(
                emoji: '👍',
                count: 2,
                reactedByMe: false,
              ),
            ],
            avatar: 'preset:1',
            fallbackText: 'Alex',
            showReceivedAvatar: true,
            avatarKey: avatarKey,
            bubbleColumnKey: bubbleColumnKey,
            reactionBarKey: reactionBarKey,
            child: _bubble(),
          ),
        ),
      ),
    );

    final avatarRight = tester.getTopRight(find.byKey(avatarKey)).dx;
    final bubbleColumnLeft = tester.getTopLeft(find.byKey(bubbleColumnKey)).dx;
    final reactionBarLeft = tester.getTopLeft(find.byKey(reactionBarKey)).dx;

    expect(reactionBarLeft, greaterThan(avatarRight));
    expect(reactionBarLeft, greaterThanOrEqualTo(bubbleColumnLeft));
  });
}
