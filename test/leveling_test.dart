import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/leveling.dart';

void main() {
  test('xpRequiredForNextLevel uses 50 * level', () {
    expect(xpRequiredForNextLevel(1), 50);
    expect(xpRequiredForNextLevel(2), 100);
    expect(xpRequiredForNextLevel(3), 150);
  });

  test('xpRequiredForNextLevel is 0 at max level', () {
    expect(xpRequiredForNextLevel(kMaxPetLevel), 0);
    expect(xpRequiredForNextLevel(kMaxPetLevel + 1), 0);
  });

  test('expProgress clamps to 0..1', () {
    expect(expProgress(level: 1, exp: -10), 0.0);
    expect(expProgress(level: 1, exp: 0), 0.0);
    expect(expProgress(level: 1, exp: 25), 0.5);
    expect(expProgress(level: 1, exp: 50), 1.0);
    expect(expProgress(level: 1, exp: 500), 1.0);
  });

  test('expProgress is 1.0 at max level', () {
    expect(expProgress(level: kMaxPetLevel, exp: 0), 1.0);
    expect(expProgress(level: kMaxPetLevel, exp: 999999), 1.0);
  });
}
