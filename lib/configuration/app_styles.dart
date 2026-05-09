import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

class AppStyles {
  // Headers
  static TextStyle header(BuildContext context) => .new(inherit: false, fontSize: 24, fontWeight: .w700, color: AppColors.text.adaptTo(context));
  static TextStyle secondaryHeader(BuildContext context) =>
      .new(inherit: false, fontSize: 20, fontWeight: .w700, color: AppColors.text.adaptTo(context));

  // Text
  static TextStyle primaryText(BuildContext context) => .new(inherit: false, fontSize: 17, color: AppColors.text.adaptTo(context));
  static TextStyle secondaryText(BuildContext context) => .new(inherit: false, fontSize: 17, color: AppColors.secondaryText.adaptTo(context));
  static TextStyle tertiaryText(BuildContext context) => .new(inherit: false, fontSize: 17, color: AppColors.tertiaryText.adaptTo(context));

  // Secondary
  static TextStyle placeholder(BuildContext context) => .new(inherit: false, fontWeight: .w600, color: AppColors.placeholderText.adaptTo(context));
  static TextStyle error(BuildContext context) => .new(inherit: false, fontSize: 16, color: AppColors.red);
}
