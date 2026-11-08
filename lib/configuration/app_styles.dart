import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

/// The app's typography. Every text uses one of these styles (with `copyWith` for a color or a weight, never for a
/// size), so that sizes stay consistent from one page to another.
///
/// Seven sizes, as on iOS, plus one for the big figures: 44 (an average, a class) · 32 (page title) · 22 (title of a sheet, a big figure) · 20 (section) · 17 (body, rows,
/// buttons) · 15 (secondary lines) · 13 (footnotes, footers) · 12 (captions, tab labels, badges).
class AppStyles {
  /// The platform's font when null (the app). The screenshot tests set a real font here: without a family, Flutter's
  /// tests draw every letter as a block.
  static String? fontFamily;

  static TextStyle _style(BuildContext context, double size, {FontWeight weight = .w400, double? letterSpacing, Color? color, double? height}) => .new(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
    color: color ?? AppColors.text.adaptTo(context),
  );

  /// The sizes, for the rare widget that must scale a text itself (a grade in a ring)
  static const double sizeDisplay = 44,
      sizeLargeTitle = 32,
      sizeTitle = 22,
      sizeSection = 20,
      sizeBody = 17,
      sizeSubheadline = 15,
      sizeFootnote = 13,
      sizeCaption = 12;

  // Headers
  /// A big figure: the general average, the class being chosen
  static TextStyle display(BuildContext context) =>
      _style(context, sizeDisplay, weight: .w700, letterSpacing: -1, height: 1.1).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// The title of a main page
  static TextStyle largeTitle(BuildContext context) => _style(context, sizeLargeTitle, weight: .w700, letterSpacing: -.5);

  /// The title of a sheet or a hero, a big figure
  static TextStyle header(BuildContext context) => _style(context, sizeTitle, weight: .w700, letterSpacing: -.3);

  /// The title above a group of cards or rows ("Par branche", "Apparence"): the same everywhere
  static TextStyle section(BuildContext context) => _style(context, sizeSection, weight: .w700, letterSpacing: -.2);
  static TextStyle secondaryHeader(BuildContext context) => _style(context, sizeSection, weight: .w600, letterSpacing: -.2);

  /// The title in a top bar (a form, a pushed page)
  static TextStyle barTitle(BuildContext context) => _style(context, sizeBody, weight: .w600);

  // Body text
  static TextStyle primaryText(BuildContext context) => _style(context, sizeBody);
  static TextStyle strongText(BuildContext context) => _style(context, sizeBody, weight: .w600);
  static TextStyle secondaryText(BuildContext context) => _style(context, sizeBody, color: AppColors.secondaryText.adaptTo(context));
  static TextStyle tertiaryText(BuildContext context) => _style(context, sizeBody, color: AppColors.tertiaryText.adaptTo(context));

  // Smaller text
  static TextStyle callout(BuildContext context) => _style(context, sizeSubheadline, color: AppColors.secondaryText.adaptTo(context));
  static TextStyle subheadline(BuildContext context) => _style(context, sizeSubheadline, color: AppColors.secondaryText.adaptTo(context));
  static TextStyle footnote(BuildContext context) => _style(context, sizeFootnote, color: AppColors.tertiaryText.adaptTo(context));
  static TextStyle caption(BuildContext context) => _style(context, sizeCaption, color: AppColors.tertiaryText.adaptTo(context));

  /// A small uppercase label above a figure ("MOYENNE", "CETTE SEMAINE")
  static TextStyle overline(BuildContext context) =>
      _style(context, sizeCaption, weight: .w600, letterSpacing: .6, color: AppColors.tertiaryText.adaptTo(context));

  // Footers (under the list sections)
  static TextStyle footer(BuildContext context) => _style(context, sizeFootnote, color: AppColors.tertiaryText.adaptTo(context));

  // Controls
  static TextStyle button(BuildContext context) => _style(context, sizeBody, weight: .w600);
  static TextStyle tag(BuildContext context) => _style(context, sizeCaption, weight: .w700, letterSpacing: .3, color: AppColors.white);
  static TextStyle badge(BuildContext context) => _style(context, sizeCaption, weight: .w600, color: AppColors.white);

  // Secondary
  static TextStyle placeholder(BuildContext context) => _style(context, sizeBody, color: AppColors.placeholderText.adaptTo(context));
  static TextStyle error(BuildContext context) => _style(context, sizeSubheadline, color: AppColors.red);
}
