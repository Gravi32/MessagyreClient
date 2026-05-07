import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/utility.dart';

class Field extends StatelessWidget {
  final IconData? icon;
  final Function(String content)? onSubmitted;
  final Function(String content)? onChanged;
  final String placeholder;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool obscureText;

  const Field({
    super.key,
    this.icon,
    this.onSubmitted,
    this.onChanged,
    required this.placeholder,
    this.controller,
    this.keyboardType,
    this.maxLines,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isNumeric = keyboardType == .number;

    return Container(
      padding: .all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryButton.adaptTo(context).withTransparency(.25),
        border: .all(color: AppColors.secondaryButton.adaptTo(context), width: 2),
        borderRadius: .circular(34),
      ),
      child: Row(
        spacing: 6,
        children: [
          Expanded(
            child: CupertinoTextField(
              padding: .zero,
              placeholder: placeholder,
              placeholderStyle: isNumeric ? AppStyles.placeholder(context).copyWith(fontSize: 20) : AppStyles.placeholder(context),
              maxLines: maxLines ?? (isNumeric ? 1 : null),
              decoration: BoxDecoration(),
              controller: controller,
              keyboardType: keyboardType,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              obscureText: obscureText,
              textAlign: isNumeric ? .center : .start,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          if (icon != null) Icon(icon),
        ],
      ),
    );
  }
}
