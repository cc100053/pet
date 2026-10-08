import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/invite_polaroid_card.dart';
import 'package:pet/features/pet/pet_catalog.dart';

void main() {
  testWidgets('captures the polaroid as a PNG for sharing', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: InvitePolaroidCard(
              petAsset: PetCatalog.byId(PetCatalog.defaultPetId).stayAsset,
              caption: 'Help me raise Mochi?',
              code: 'AB12CD',
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('AB12CD'), findsOneWidget);

    final file = await tester.runAsync(() => captureInviteCardImage(key));
    expect(file, isNotNull);
    expect(file!.mimeType, 'image/png');
    final bytes = await tester.runAsync(file.readAsBytes);
    // PNG signature.
    expect(bytes!.take(4), [0x89, 0x50, 0x4E, 0x47]);
  });

  test('returns null when the card is not mounted', () async {
    expect(await captureInviteCardImage(GlobalKey()), isNull);
  });
}
