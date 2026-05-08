import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

class AppStyles {
  // Titles
  static TextStyle header(BuildContext context) => .new(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text.adaptTo(context));
  static TextStyle secondaryText(BuildContext context) => .new(color: AppColors.secondaryText.adaptTo(context));
  static TextStyle tertiaryText(BuildContext context) => .new(color: AppColors.tertiaryText.adaptTo(context));

  // Secondary
  static TextStyle placeholder(BuildContext context) => .new(fontWeight: .w600, color: AppColors.placeholderText.adaptTo(context));
  static TextStyle error(BuildContext context) => .new(fontSize: 16, color: AppColors.red);
}
