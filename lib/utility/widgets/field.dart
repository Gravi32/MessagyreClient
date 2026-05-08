import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';

class Field extends StatefulWidget {
  final String placeholder;
  final IconData? icon;
  final Function(String content)? onSubmitted;
  final Function(String content)? onChanged;
  final String? error;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool isPassword;
  final bool enabled;

  const Field({
    super.key,
    required this.placeholder,
    this.icon,
    this.onSubmitted,
    this.onChanged,
    this.error,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.isPassword = false,
    this.enabled = true,
  });

  factory Field.password({Function(String content)? onChanged, String? error, TextEditingController? controller, bool enabled = true}) {
    return Field(
      placeholder: "Mot de passe",
      onChanged: onChanged,
      error: error,
      controller: controller,
      keyboardType: .visiblePassword,
      isPassword: true,
      enabled: enabled,
    );
  }

  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.secondaryButton.adaptTo(context);
    bool isNumeric = widget.keyboardType == .number;
    bool showingError = (widget.error ?? "").isNotEmpty;

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withTransparency(widget.enabled ? 0.25 : 0.75),
                border: .all(color: color, width: 2),
                borderRadius: .circular(34),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      padding: .all(16),
                      placeholder: widget.placeholder,
                      placeholderStyle: isNumeric ? AppStyles.placeholder(context).copyWith(fontSize: 20) : AppStyles.placeholder(context),
                      maxLines: widget.maxLines ?? (isNumeric ? 1 : (_obscureText ? 1 : null)),
                      scrollPadding: const EdgeInsets.only(bottom: 60), // Distance from the keyboard
                      decoration: const BoxDecoration(),
                      controller: widget.controller,
                      keyboardType: widget.keyboardType,
                      onSubmitted: widget.onSubmitted,
                      onChanged: widget.onChanged,
                      obscureText: _obscureText,
                      textAlign: isNumeric ? .center : .start,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                  if (widget.icon != null) Icon(widget.icon),
                ],
              ),
            ),
            if (widget.isPassword)
              Positioned(
                right: 6,
                top: 6,
                bottom: 6,
                child: Button.icon(
                  onTap: () => setState(() => _obscureText = !_obscureText),
                  icon: _obscureText ? HugeIcons.strokeRoundedView : HugeIcons.strokeRoundedViewOff,
                  enabled: widget.enabled,
                  transparent: true,
                  color: AppColors.secondaryButton.adaptTo(context),
                  iconColor: AppColors.text.adaptTo(context),
                ),
              ),
          ],
        ),
        if (showingError)
          Padding(
            padding: const .only(top: 4, left: 16, right: 16),
            child: Text(widget.error!, style: AppStyles.error(context)),
          ),
      ],
    );
  }
}
