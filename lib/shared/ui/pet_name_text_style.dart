import 'package:flutter/material.dart';

TextStyle petNameTextStyle({
  double? fontSize,
  Color color = Colors.black,
  double? height,
}) {
  return TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: fontSize,
    color: color,
    height: height,
  );
}
