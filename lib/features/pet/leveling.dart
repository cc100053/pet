const int kMaxPetLevel = 999;

int xpRequiredForNextLevel(int level) {
  final safeLevel = level < 1 ? 1 : level;
  if (safeLevel >= kMaxPetLevel) {
    return 0;
  }
  return 50 * safeLevel;
}

double expProgress({required int level, required int exp}) {
  if (level >= kMaxPetLevel) {
    return 1.0;
  }
  final required = xpRequiredForNextLevel(level);
  if (required <= 0) {
    return 0.0;
  }
  final safeExp = exp < 0 ? 0 : exp;
  return (safeExp / required).clamp(0.0, 1.0);
}
