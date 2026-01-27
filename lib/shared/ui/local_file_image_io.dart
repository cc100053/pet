import 'dart:io';

import 'package:flutter/widgets.dart';

Widget? buildLocalFileImageImpl(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  if (path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('data:')) {
    return null;
  }

  final isWindowsPath = RegExp(r'^[a-zA-Z]:\\').hasMatch(path);
  if (!path.startsWith('file://') && !path.startsWith('/') && !isWindowsPath) {
    return null;
  }

  final filePath = path.startsWith('file://')
      ? Uri.parse(path).toFilePath(windows: Platform.isWindows)
      : path;
  if (filePath.isEmpty) {
    return null;
  }
  final file = File(filePath);
  if (!file.existsSync()) {
    return null;
  }
  return Image.file(file, fit: fit, width: width, height: height);
}
