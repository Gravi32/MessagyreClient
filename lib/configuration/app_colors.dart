import 'package:flutter/material.dart';

/// The app's palette: quiet neutral greys (in light and dark mode alike) and the icon's purple kept for the few
/// things that matter (the main button, the sent bubbles, what is unread or selected). The [accent] fills, the [tint]
/// colors text and icons (lighter in dark mode, to stay readable).
class AppColors {
  // Accent
  /// The brand's purple, for filled surfaces with white on top (main buttons, sent bubbles, badges)
  static const accent = Color.fromRGBO(160, 20, 170, 1.0);

  /// The accent for text and icons on the app's backgrounds: readable in both modes
  static const tint = AppColor(light: Color.fromRGBO(146, 22, 156, 1.0), dark: Color.fromRGBO(218, 140, 232, 1.0));

  /// A faint wash of the accent, behind a selected item
  static const accentSoft = AppColor(light: Color.fromRGBO(160, 20, 170, .08), dark: Color.fromRGBO(200, 110, 215, .16));

  /// The app icon's background (sampled from assets/icons/full.png): only for the surfaces that carry the Gymnase's
  /// shape (the profile card, the class card)
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(170, 10, 180, 1.0), Color.fromRGBO(99, 25, 104, 1.0)],
  );

  /// The sent bubbles: the accent, barely shaded so a long message stays easy to read
  static const sentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.fromRGBO(140, 34, 152, 1.0), Color.fromRGBO(126, 30, 138, 1.0)],
  );

  // Backgrounds
  /// The pages
  static const background = AppColor(light: Color.fromRGBO(244, 244, 246, 1.0), dark: Color.fromRGBO(10, 10, 12, 1.0));

  /// The cards, lists and controls laid on a page (lighter than it, in both modes)
  static const secondaryBackground = AppColor(light: Color.fromRGBO(255, 255, 255, 1.0), dark: Color.fromRGBO(27, 27, 30, 1.0));

  /// What sits inside a card: fields, the track of a switch, a selected segment
  static const tertiaryBackground = AppColor(light: Color.fromRGBO(239, 239, 242, 1.0), dark: Color.fromRGBO(42, 42, 46, 1.0));
  static const separator = AppColor(light: Color.fromRGBO(20, 20, 30, .1), dark: Color.fromRGBO(255, 255, 255, .09));

  /// The hairline around a card, so it stands out from the page
  static const outline = AppColor(light: Color.fromRGBO(20, 20, 30, .07), dark: Color.fromRGBO(255, 255, 255, .07));

  // Text
  static const text = AppColor(light: Color.fromRGBO(22, 22, 26, 1.0), dark: Color.fromRGBO(244, 244, 246, 1.0));
  static const secondaryText = AppColor(light: Color.fromRGBO(22, 22, 26, .62), dark: Color.fromRGBO(244, 244, 246, .64));
  static const tertiaryText = AppColor(light: Color.fromRGBO(22, 22, 26, .42), dark: Color.fromRGBO(244, 244, 246, .42));
  static const quaternaryText = AppColor(light: Color.fromRGBO(22, 22, 26, .26), dark: Color.fromRGBO(244, 244, 246, .26));
  static const placeholderText = AppColor(light: Color.fromRGBO(22, 22, 26, .36), dark: Color.fromRGBO(244, 244, 246, .36));

  // Buttons
  static const secondaryButton = AppColor(light: Color.fromRGBO(232, 232, 236, 1.0), dark: Color.fromRGBO(50, 50, 55, 1.0));

  // Chat bubbles
  // Sent: white text on the accent; received: the normal text color on the cards' color (readable in both modes)
  static const sentBubble = AppColor(light: Color.fromRGBO(134, 32, 146, 1.0), dark: Color.fromRGBO(118, 30, 130, 1.0));
  static const receivedBubble = AppColor(light: Color.fromRGBO(255, 255, 255, 1.0), dark: Color.fromRGBO(38, 38, 42, 1.0));

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
  static const inactive = AppColor(light: Color.fromRGBO(160, 160, 166, 1.0), dark: Color.fromRGBO(92, 92, 98, 1.0));

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
