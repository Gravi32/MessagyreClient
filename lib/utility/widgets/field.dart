import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';

class Field extends StatefulWidget {
  final String placeholder;
  final IconData? icon;
  final Function(String content)? onSubmitted;
  final Function(String content)? onChanged;
  final String? suffix;
  final String? error;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextStyle? textStyle;
  final FocusNode? focusNode;
  final ScrollPhysics? scrollPhysics;
  final int? maxLines;
  final bool thin;
  final bool isPassword;
  final bool alwaysHidePassword;
  final bool enabled;

  const Field({
    super.key,
    required this.placeholder,
    this.icon,
    this.onSubmitted,
    this.onChanged,
    this.suffix,
    this.error,
    this.controller,
    this.keyboardType,
    this.textStyle,
    this.focusNode,
    this.scrollPhysics,
    this.maxLines = 1,
    this.thin = false,
    this.isPassword = false,
    this.alwaysHidePassword = false,
    this.enabled = true,
  });

  factory Field.password({
    Function(String content)? onChanged,
    String? error,
    TextEditingController? controller,
    bool enabled = true,
    bool isConfirmPassword = false,
    bool alwaysHidePassword = false,
  }) {
    return Field(
      placeholder: isConfirmPassword ? "Confirmer le mot de passe" : "Mot de passe",
      onChanged: onChanged,
      error: error,
      controller: controller,
      keyboardType: .visiblePassword,
      isPassword: true,
      alwaysHidePassword: alwaysHidePassword,
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
              padding: .only(right: 16),
              decoration: BoxDecoration(
                color: color.withTransparency(widget.enabled ? 0.25 : 0.75),
                border: .all(color: color, width: 2),
                borderRadius: .circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      padding: .only(left: 16, top: widget.thin ? 8 : 16, bottom: widget.thin ? 8 : 16),
                      placeholder: widget.placeholder,
                      placeholderStyle: (isNumeric ? AppStyles.placeholder(context).copyWith(fontSize: 20) : AppStyles.placeholder(context)).merge(
                        widget.textStyle,
                      ),
                      minLines: 1,
                      maxLines: widget.maxLines ?? (isNumeric ? 1 : (_obscureText ? 1 : null)),
                      scrollPadding: const .only(bottom: 60), // Distance from the keyboard
                      decoration: const BoxDecoration(),
                      controller: widget.controller,
                      keyboardType: widget.keyboardType,
                      onSubmitted: widget.onSubmitted,
                      onChanged: widget.onChanged,
                      obscureText: _obscureText,
                      focusNode: widget.focusNode,
                      scrollPhysics: widget.scrollPhysics,
                      textAlign: isNumeric ? .center : .start,
                      style: widget.textStyle,
                      onTapOutside: widget.focusNode == null ? (_) => FocusScope.of(context).unfocus() : null,
                    ),
                  ),
                  if (widget.suffix != null) Text(widget.suffix!),
                  if (widget.icon != null) Icon(widget.icon),
                ],
              ),
            ),
            if (widget.isPassword && !widget.alwaysHidePassword)
              Positioned(
                right: 6,
                top: 6,
                bottom: 6,
                child: Button.icon(
                  context,
                  onTap: () => setState(() => _obscureText = !_obscureText),
                  icon: _obscureText ? HugeIcons.strokeRoundedView : HugeIcons.strokeRoundedViewOff,
                  enabled: widget.enabled,
                ),
              ),
          ],
        ),
        if (showingError)
          Padding(
            padding: const .only(top: 4, left: 16, right: 16),
            child: CustomText(widget.error!, style: AppStyles.error(context)),
          ),
      ],
    );
  }
}
