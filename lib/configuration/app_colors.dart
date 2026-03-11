import 'package:flutter/material.dart';
import 'package:messagyre_client/services/globals_service.dart';

class AppColors {
  // Accent
  static const accent = Color.fromRGBO(171, 12, 179, 1.0);

  // Backgrounds
  static const background = AppColor(light: Color.fromRGBO(242, 242, 247, 1.0), dark: Color.fromRGBO(16, 25, 34, 1.0));
  static const secondaryBackground = AppColor(light: Color.fromRGBO(232, 232, 237, 1.0), dark: Color.fromRGBO(24, 31, 48, 1.0));
  static const tertiaryBackground = AppColor(light: Color.fromRGBO(223, 223, 228, 1.0), dark: Color.fromRGBO(32, 41, 54, 1.0));
  static const separator = AppColor(light: Color.fromRGBO(0, 0, 0, 0.2), dark: Color.fromRGBO(255, 255, 255, 0.2));

  // Text
  static const text = AppColor(light: Color.fromRGBO(28, 28, 30, 1.0), dark: Color.fromRGBO(229, 229, 234, 1.0));
  static const secondaryText = AppColor(light: Color.fromRGBO(28, 28, 30, 0.6), dark: Color.fromRGBO(255, 255, 255, 0.6));
  static const tertiaryText = AppColor(light: Color.fromRGBO(28, 28, 30, 0.4), dark: Color.fromRGBO(255, 255, 255, 0.4));
  static const quaternaryText = AppColor(light: Color.fromRGBO(28, 28, 30, 0.33), dark: Color.fromRGBO(255, 255, 255, 0.33));
  static const placeholderText = AppColor(light: Color.fromRGBO(60, 60, 67, .5), dark: Color.fromRGBO(142, 142, 147, 1.0));

  // Chat bubbles
  static const sentBubble = AppColor(light: Color.fromRGBO(216, 161, 255, 1.0), dark: Color.fromRGBO(156, 0, 179, 1.0));
  static const receivedBubble = AppColor(light: Color.fromRGBO(229, 229, 234, 1.0), dark: Color.fromRGBO(46, 46, 60, 1.0));

  // Vivid colors
  static const white = Color.fromRGBO(255, 255, 255, 1.0);
  static const red = Color.fromRGBO(240, 100, 100, 1.0);
  static const orange = Color.fromRGBO(255, 149, 0, 1.0);
  static const yellow = Color.fromRGBO(255, 204, 0, 1.0);
  static const green = Color.fromRGBO(52, 199, 89, 1.0);
  static const grey = Color.fromRGBO(142, 142, 147, 1.0);
  static const black = Color.fromRGBO(0, 0, 0, 1.0);

  // Special colors
  static const transparent = Color.fromRGBO(0, 0, 0, 0.0);
  static const inactive = AppColor(light: Color.fromRGBO(142, 142, 147, 1.0), dark: Color.fromRGBO(99, 99, 102, 1.0));
}

class AppColor extends Color {
  final Color light, dark;

  const AppColor({required this.light, required this.dark}) : super(0);

  /// Adapts the color to the current platform brightness.
  Color adaptTo(BuildContext context) => GlobalsService().appBrightness == Brightness.dark ? dark : light;
}
