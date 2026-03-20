import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/widgets/chat_reply_preview_panel.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 280, child: Material(child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'compact one-line reply preview stays flatter than regular mode',
    (tester) async {
      final compactKey = GlobalKey();
      final regularKey = GlobalKey();
      const previewText =
          'This is a fairly long reply preview that should truncate cleanly.';

      await tester.pumpWidget(
        _wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChatReplyPreviewPanel(
                key: compactKey,
                senderName: 'Other',
                previewText: previewText,
                accentColor: Colors.teal,
                senderColor: Colors.black,
                previewTextColor: Colors.black54,
                backgroundColor: Colors.teal.shade50,
                compact: true,
                maxLines: 1,
                showJumpIcon: true,
              ),
              const SizedBox(height: 16),
              ChatReplyPreviewPanel(
                key: regularKey,
                senderName: 'Other',
                previewText: previewText,
                accentColor: Colors.teal,
                senderColor: Colors.black,
                previewTextColor: Colors.black54,
                backgroundColor: Colors.teal.shade50,
                compact: false,
                maxLines: 2,
                showJumpIcon: true,
              ),
            ],
          ),
        ),
      );

      final compactHeight = tester.getSize(find.byKey(compactKey)).height;
      final regularHeight = tester.getSize(find.byKey(regularKey)).height;

      expect(compactHeight, lessThan(regularHeight));
      expect(compactHeight, lessThan(48));
    },
  );
}
