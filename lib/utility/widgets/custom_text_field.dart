import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class CustomTextField extends StatefulWidget {
  final String title;
  final String placeholder;
  final String? error;
  final Widget? suffix;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final bool alwaysHidePassword;
  final bool disabled;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  @Deprecated("Use 'Field' from 'utility/widgets/basics/field.dart' instead.")
  const CustomTextField({
    super.key,
    required this.title,
    required this.placeholder,
    this.error,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.alwaysHidePassword = false,
    this.disabled = false,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<StatefulWidget> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    bool isPasswordField = widget.keyboardType == TextInputType.visiblePassword;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: TextStyle(fontSize: 12)),
        SizedBox(height: 5),

        CupertinoTextField(
          controller: widget.controller,
          obscureText: isPasswordField && isPasswordHidden,
          keyboardType: widget.keyboardType,
          placeholder: widget.placeholder,
          enabled: !widget.disabled,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          style: TextStyle(color: widget.disabled ? AppColors.inactive.adaptTo(context) : adaptiveColor(AppColors.black, AppColors.white)),
          decoration: BoxDecoration(
            color: widget.disabled ? AppColors.inactive.adaptTo(context).withAlpha(50) : AppColors.secondaryBackground.adaptTo(context).withAlpha(200),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: adaptiveColor(AppColors.grey, Colors.transparent)),
          ),
          suffix:
              widget.suffix ??
              ((isPasswordField && !widget.alwaysHidePassword)
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,

                      onPressed: widget.disabled
                          ? null
                          : () {
                              setState(() {
                                isPasswordHidden = !isPasswordHidden;
                              });
                            },
                      child: CustomIcon(
                        icon: isPasswordHidden ? HugeIcons.strokeRoundedView : HugeIcons.strokeRoundedViewOff,
                        color: widget.disabled ? AppColors.inactive.adaptTo(context) : null,
                      ),
                    )
                  : null),

          onChanged: widget.disabled ? null : widget.onChanged,
          onSubmitted: widget.disabled ? null : widget.onSubmitted,
        ),

        SizedBox(height: 5),
        if (widget.error != null) Text(widget.error!, style: TextStyle(fontSize: 12, color: AppColors.red)),
      ],
    );
  }
}
