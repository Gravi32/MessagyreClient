import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

/// The app's typography. Every text should use one of these styles (with `copyWith` for a color or weight),
/// so that sizes stay consistent from one page to another.
///
/// Scale: largeTitle 32 · header 24 · secondaryHeader 20 · body 17 · callout 16 · subheadline 15 · footnote 13 · caption 12
class AppStyles {
  // Headers
  static TextStyle largeTitle(BuildContext context) => .new(inherit: false, fontSize: 32, fontWeight: .w800, color: AppColors.text.adaptTo(context));
  static TextStyle header(BuildContext context) => .new(inherit: false, fontSize: 24, fontWeight: .w700, color: AppColors.text.adaptTo(context));
  static TextStyle secondaryHeader(BuildContext context) => .new(inherit: false, fontSize: 20, fontWeight: .w700, color: AppColors.text.adaptTo(context));

  // Body text
  static TextStyle primaryText(BuildContext context) => .new(inherit: false, fontSize: 17, color: AppColors.text.adaptTo(context));
  static TextStyle strongText(BuildContext context) => .new(inherit: false, fontSize: 17, fontWeight: .w600, color: AppColors.text.adaptTo(context));
  static TextStyle secondaryText(BuildContext context) => .new(inherit: false, fontSize: 17, color: AppColors.secondaryText.adaptTo(context));
  static TextStyle tertiaryText(BuildContext context) => .new(inherit: false, fontSize: 17, color: AppColors.tertiaryText.adaptTo(context));

  // Smaller text
  static TextStyle callout(BuildContext context) => .new(inherit: false, fontSize: 16, color: AppColors.secondaryText.adaptTo(context));
  static TextStyle subheadline(BuildContext context) => .new(inherit: false, fontSize: 15, color: AppColors.secondaryText.adaptTo(context));
  static TextStyle footnote(BuildContext context) => .new(inherit: false, fontSize: 13, color: AppColors.tertiaryText.adaptTo(context));
  static TextStyle caption(BuildContext context) => .new(inherit: false, fontSize: 12, color: AppColors.tertiaryText.adaptTo(context));

  // Footers (under the list sections)
  static TextStyle footer(BuildContext context) => .new(inherit: false, fontSize: 15, color: AppColors.tertiaryText.adaptTo(context));

  // Controls
  static TextStyle button(BuildContext context) => .new(inherit: false, fontSize: 18, fontWeight: .w600, color: AppColors.text.adaptTo(context));
  static TextStyle tag(BuildContext context) => const .new(inherit: false, fontSize: 13, letterSpacing: .3, fontWeight: .w800, color: AppColors.white);
  static TextStyle badge(BuildContext context) => const .new(inherit: false, fontSize: 13, fontWeight: .w600, color: AppColors.white);

  // Secondary
  static TextStyle placeholder(BuildContext context) =>
      .new(inherit: false, fontSize: 17, fontWeight: .w500, color: AppColors.placeholderText.adaptTo(context));
  static TextStyle error(BuildContext context) => .new(inherit: false, fontSize: 16, color: AppColors.red);
}
