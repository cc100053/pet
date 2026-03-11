import 'package:flutter/material.dart';

const ScrollViewKeyboardDismissBehavior formScrollKeyboardDismissBehavior =
    ScrollViewKeyboardDismissBehavior.onDrag;

void dismissKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
}

void dismissKeyboardOnTapOutside(PointerDownEvent _) {
  dismissKeyboard();
}
