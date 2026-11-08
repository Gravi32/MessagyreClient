import 'package:flutter/material.dart';

/// The app's palette: a night blue in dark mode, a faint lavender in light mode, and the icon's purple for what
/// matters (the main buttons, the sent bubbles, the selected tab, what is unread). The [accent] fills, the [tint]
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
  static const background = AppColor(light: Color.fromRGBO(244, 242, 250, 1.0), dark: Color.fromRGBO(13, 21, 36, 1.0));

  /// The cards, lists and controls laid on a page (lighter than it, in both modes)
  static const secondaryBackground = AppColor(light: Color.fromRGBO(255, 255, 255, 1.0), dark: Color.fromRGBO(23, 33, 53, 1.0));

  /// What sits inside a card: fields, the track of a switch, a selected segment
  static const tertiaryBackground = AppColor(light: Color.fromRGBO(238, 235, 246, 1.0), dark: Color.fromRGBO(35, 47, 70, 1.0));
  static const separator = AppColor(light: Color.fromRGBO(40, 20, 80, .1), dark: Color.fromRGBO(200, 215, 255, .1));

  /// The hairline around a card, so it stands out from the page
  static const outline = AppColor(light: Color.fromRGBO(40, 20, 80, .08), dark: Color.fromRGBO(200, 215, 255, .08));

  /// The solid "lip" under the cards (no blur): gives them a slightly cartoonish, stuck-on look
  static const cardLip = AppColor(light: Color.fromRGBO(70, 40, 120, .09), dark: Color.fromRGBO(0, 0, 0, .38));

  // Text
  static const text = AppColor(light: Color.fromRGBO(30, 24, 48, 1.0), dark: Color.fromRGBO(236, 240, 250, 1.0));
  static const secondaryText = AppColor(light: Color.fromRGBO(30, 24, 48, .64), dark: Color.fromRGBO(236, 240, 250, .66));
  static const tertiaryText = AppColor(light: Color.fromRGBO(30, 24, 48, .44), dark: Color.fromRGBO(236, 240, 250, .44));
  static const quaternaryText = AppColor(light: Color.fromRGBO(30, 24, 48, .26), dark: Color.fromRGBO(236, 240, 250, .26));
  static const placeholderText = AppColor(light: Color.fromRGBO(30, 24, 48, .36), dark: Color.fromRGBO(236, 240, 250, .36));

  // Buttons
  static const secondaryButton = AppColor(light: Color.fromRGBO(230, 226, 240, 1.0), dark: Color.fromRGBO(46, 58, 82, 1.0));

  // Chat bubbles
  // Sent: white text on the accent; received: the normal text color on the cards' color (readable in both modes)
  static const sentBubble = AppColor(light: Color.fromRGBO(134, 32, 146, 1.0), dark: Color.fromRGBO(118, 30, 130, 1.0));
  static const receivedBubble = AppColor(light: Color.fromRGBO(255, 255, 255, 1.0), dark: Color.fromRGBO(32, 44, 68, 1.0));

  // Grades
  /// An insufficient grade: a soft coral rather than an alarm red, so that a page with several of them stays
  /// encouraging (still clearly different from the normal text)
  static const gradeLow = AppColor(light: Color.fromRGBO(196, 104, 98, 1.0), dark: Color.fromRGBO(232, 146, 136, 1.0));

  /// A grade just under 4 (3.75 < grade < 4): a soft amber
  static const gradeBorderline = AppColor(light: Color.fromRGBO(190, 134, 52, 1.0), dark: Color.fromRGBO(228, 180, 108, 1.0));

  /// Good news about the grades (no insufficient grade, positive compensation): a calm green
  static const gradeGood = AppColor(light: Color.fromRGBO(62, 150, 98, 1.0), dark: Color.fromRGBO(120, 200, 150, 1.0));

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
  static const inactive = AppColor(light: Color.fromRGBO(160, 156, 172, 1.0), dark: Color.fromRGBO(84, 96, 120, 1.0));

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
