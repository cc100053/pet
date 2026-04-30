import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/pet_animated_image.dart';

void main() {
  testWidgets('keeps image element unkeyed across pet action swaps', (
    tester,
  ) async {
    Future<void> pumpAction(String sourceAsset) {
      return tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: PetAnimatedImage(
              sourceAsset: sourceAsset,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    await pumpAction('assets/pet/ghost/ghost_stay.gif');

    final stayImage = tester.widget<Image>(find.byType(Image));
    expect(stayImage.key, isNull);
    expect(
      (stayImage.image as AssetImage).assetName,
      'assets/pet_sequences/ghost/stay/ghost_stay-01.png',
    );

    await pumpAction('assets/pet/ghost/ghost_sleep.gif');

    final sleepImage = tester.widget<Image>(find.byType(Image));
    expect(sleepImage.key, isNull);
    expect(
      (sleepImage.image as AssetImage).assetName,
      'assets/pet_sequences/ghost/sleep/ghost_sleep-01.png',
    );
  });
}
