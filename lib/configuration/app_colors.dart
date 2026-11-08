import 'package:flutter/material.dart';

/// The app's palette. Every neutral is a shade of the icon's purple (barely tinted), so that light and dark mode look
/// like the same app; the [accent] fills, the [tint] colors text and icons (lighter in dark mode, to stay readable).
class AppColors {
  // Accent
  /// The brand's purple, for filled surfaces with white on top (buttons, sent bubbles, badges)
  static const accent = Color.fromRGBO(171, 12, 179, 1.0);

  /// The accent for text and icons on the app's backgrounds: readable in both modes
  static const tint = AppColor(light: Color.fromRGBO(150, 8, 160, 1.0), dark: Color.fromRGBO(226, 136, 240, 1.0));

  /// A faint wash of the accent, behind a tinted icon or a selected item
  static const accentSoft = AppColor(light: Color.fromRGBO(171, 12, 179, .09), dark: Color.fromRGBO(190, 60, 205, .22));

  /// The app icon's background (sampled from assets/icons/full.png): the brand's color for the surfaces that carry
  /// the Gymnase's shape, the main buttons and the selected tab
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(175, 0, 184, 1.0), Color.fromRGBO(99, 25, 104, 1.0)],
  );

  /// The sent bubbles: the icon's gradient, softened so a long message stays easy to read
  static const sentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(178, 22, 187, 1.0), Color.fromRGBO(132, 18, 143, 1.0)],
  );

  // Backgrounds
  /// The pages
  static const background = AppColor(light: Color.fromRGBO(245, 243, 248, 1.0), dark: Color.fromRGBO(15, 12, 20, 1.0));

  /// The cards, lists and controls laid on a page (lighter than it, in both modes)
  static const secondaryBackground = AppColor(light: Color.fromRGBO(255, 255, 255, 1.0), dark: Color.fromRGBO(29, 25, 36, 1.0));

  /// What sits inside a card: fields, the track of a switch, a selected segment
  static const tertiaryBackground = AppColor(light: Color.fromRGBO(238, 234, 243, 1.0), dark: Color.fromRGBO(43, 37, 52, 1.0));
  static const separator = AppColor(light: Color.fromRGBO(30, 16, 40, .11), dark: Color.fromRGBO(255, 255, 255, .09));

  /// The hairline around a card, so it stands out from the page
  static const outline = AppColor(light: Color.fromRGBO(30, 16, 40, .07), dark: Color.fromRGBO(255, 255, 255, .06));

  // Text
  static const text = AppColor(light: Color.fromRGBO(28, 22, 34, 1.0), dark: Color.fromRGBO(244, 240, 248, 1.0));
  static const secondaryText = AppColor(light: Color.fromRGBO(28, 22, 34, .64), dark: Color.fromRGBO(244, 240, 248, .66));
  static const tertiaryText = AppColor(light: Color.fromRGBO(28, 22, 34, .44), dark: Color.fromRGBO(244, 240, 248, .44));
  static const quaternaryText = AppColor(light: Color.fromRGBO(28, 22, 34, .3), dark: Color.fromRGBO(244, 240, 248, .3));
  static const placeholderText = AppColor(light: Color.fromRGBO(28, 22, 34, .38), dark: Color.fromRGBO(244, 240, 248, .38));

  // Buttons
  static const secondaryButton = AppColor(light: Color.fromRGBO(229, 223, 235, 1.0), dark: Color.fromRGBO(54, 47, 64, 1.0));

  // Chat bubbles
  // Sent: white text on the accent; received: the normal text color on the cards' color (readable in both modes)
  static const sentBubble = AppColor(light: Color.fromRGBO(162, 16, 170, 1.0), dark: Color.fromRGBO(140, 22, 156, 1.0));
  static const receivedBubble = AppColor(light: Color.fromRGBO(255, 255, 255, 1.0), dark: Color.fromRGBO(40, 34, 49, 1.0));

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
  static const inactive = AppColor(light: Color.fromRGBO(160, 154, 167, 1.0), dark: Color.fromRGBO(94, 87, 102, 1.0));

  static bool isDark(BuildContext context) => MediaQuery.maybePlatformBrightnessOf(context) == .dark;

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
  Color adaptTo(BuildContext context) => AppColors.isDark(context) ? dark : light;
}
