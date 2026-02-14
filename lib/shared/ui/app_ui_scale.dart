double appUiScale(double screenWidth) {
  if (!screenWidth.isFinite || screenWidth <= 0) {
    return 1.0;
  }
  if (screenWidth <= 360) {
    return 0.76;
  }
  if (screenWidth <= 430) {
    return 0.92;
  }
  return 1.0;
}
