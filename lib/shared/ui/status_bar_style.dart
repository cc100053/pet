import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppStatusBarStyles {
  const AppStatusBarStyles._();

  static const SystemUiOverlayStyle light = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light, // iOS: dark content
    statusBarIconBrightness: Brightness.dark, // Android: dark icons
  );

  static const SystemUiOverlayStyle dark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark, // iOS: light content
    statusBarIconBrightness: Brightness.light, // Android: light icons
  );

  static SystemUiOverlayStyle forBackground({required bool isDark}) {
    return isDark ? dark : light;
  }
}
