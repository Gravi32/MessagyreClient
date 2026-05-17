import 'package:flutter/material.dart';

class AppColors {
  // Accent
  static const accent = Color.fromRGBO(171, 12, 179, 1.0);

  // Backgrounds
  static const background = AppColor(light: Color.fromRGBO(242, 242, 247, 1.0), dark: Color.fromRGBO(16, 25, 34, 1.0));
  static const secondaryBackground = AppColor(light: Color.fromRGBO(232, 232, 237, 1.0), dark: Color.fromRGBO(24, 31, 48, 1.0));
  static const tertiaryBackground = AppColor(light: Color.fromRGBO(223, 223, 228, 1.0), dark: Color.fromRGBO(32, 41, 54, 1.0));
  static const separator = AppColor(light: Color.fromRGBO(0, 0, 0, 0.2), dark: Color.fromRGBO(255, 255, 255, 0.2));

  // Text
  static const text = AppColor(light: Color.fromRGBO(80, 80, 80, 1.0), dark: Color.fromRGBO(229, 229, 234, 1.0));
  static const secondaryText = AppColor(light: Color.fromRGBO(80, 80, 80, 0.6), dark: Color.fromRGBO(255, 255, 255, 0.6));
  static const tertiaryText = AppColor(light: Color.fromRGBO(80, 80, 80, 0.4), dark: Color.fromRGBO(255, 255, 255, 0.4));
  static const quaternaryText = AppColor(light: Color.fromRGBO(80, 80, 80, 0.33), dark: Color.fromRGBO(255, 255, 255, 0.33));
  static const placeholderText = AppColor(light: Color.fromRGBO(60, 60, 67, .5), dark: Color.fromRGBO(142, 142, 147, 1.0));

  // Buttons
  static const secondaryButton = AppColor(light: Color.fromRGBO(192, 192, 197, 1.0), dark: Color.fromRGBO(54, 61, 78, 1.0));

  // Chat bubbles
  static const sentBubble = AppColor(light: Color.fromRGBO(216, 161, 255, 1.0), dark: Color.fromRGBO(156, 0, 179, 1.0));
  static const receivedBubble = AppColor(light: Color.fromRGBO(209, 209, 214, 1.0), dark: Color.fromRGBO(46, 46, 60, 1.0));

  // Vivid colors
  static const white = Color.fromRGBO(255, 255, 255, 1.0);
  static const black = Color.fromRGBO(0, 0, 0, 1.0);
  static const grey = Color.fromRGBO(142, 142, 147, 1.0);

  static const red = Color.fromRGBO(255, 59, 48, 1.0);
  static const orange = Color.fromRGBO(255, 149, 0, 1.0);
  static const yellow = Color.fromRGBO(255, 204, 0, 1.0);
  static const green = Color.fromRGBO(52, 199, 89, 1.0);
  static const mint = Color.fromRGBO(0, 199, 190, 1.0);
  static const teal = Color.fromRGBO(48, 176, 199, 1.0);
  static const cyan = Color.fromRGBO(50, 173, 230, 1.0);
  static const blue = Color.fromRGBO(0, 122, 255, 1.0);
  static const indigo = Color.fromRGBO(88, 86, 214, 1.0);
  static const purple = Color.fromRGBO(175, 82, 222, 1.0);
  static const pink = Color.fromRGBO(255, 45, 85, 1.0);
  static const brown = Color.fromRGBO(162, 132, 94, 1.0);

  // Extra Vivid
  static const lime = Color.fromRGBO(191, 255, 0, 1.0);
  static const amber = Color.fromRGBO(255, 191, 0, 1.0);
  static const deepOrange = Color.fromRGBO(255, 87, 34, 1.0);
  static const magenta = Color.fromRGBO(255, 0, 255, 1.0);
  static const violet = Color.fromRGBO(143, 0, 255, 1.0);
  static const skyBlue = Color.fromRGBO(0, 191, 255, 1.0);
  static const gold = Color.fromRGBO(255, 215, 0, 1.0);
  static const silver = Color.fromRGBO(192, 192, 192, 1.0);

  // Special colors
  static const transparent = Color.fromRGBO(0, 0, 0, 0.0);
  static const inactive = AppColor(light: Color.fromRGBO(142, 142, 147, 1.0), dark: Color.fromRGBO(99, 99, 102, 1.0));

  // Getter
  static Color? fromName(String? name, {BuildContext? context}) => switch (name?.toLowerCase()) {
    "white" => AppColors.white,
    "black" => AppColors.black,
    "grey" => AppColors.grey,
    "red" => AppColors.red,
    "orange" => AppColors.orange,
    "yellow" => AppColors.yellow,
    "green" => AppColors.green,
    "mint" => AppColors.mint,
    "teal" => AppColors.teal,
    "cyan" => AppColors.cyan,
    "blue" => AppColors.blue,
    "indigo" => AppColors.indigo,
    "purple" => AppColors.purple,
    "pink" => AppColors.pink,
    "brown" => AppColors.brown,
    "accent" => AppColors.accent,
    "lime" => AppColors.lime,
    "amber" => AppColors.amber,
    "deeporange" => AppColors.deepOrange,
    "magenta" => AppColors.magenta,
    "violet" => AppColors.violet,
    "skyblue" => AppColors.skyBlue,
    "gold" => AppColors.gold,
    "silver" => AppColors.silver,
    _ => null,
  };
}

class AppColor extends Color {
  final Color light, dark;

  const AppColor({required this.light, required this.dark}) : super(0);

  /// Adapts the color to the current platform brightness.
  Color adaptTo(BuildContext context) => MediaQuery.maybePlatformBrightnessOf(context) == .dark ? dark : light;
}
