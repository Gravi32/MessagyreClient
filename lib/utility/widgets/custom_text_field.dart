import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/utility/utility.dart';

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
          style: TextStyle(
            color:
                widget.disabled
                    ? CupertinoColors.inactiveGray
                    : adaptiveColor(context, CupertinoColors.black, CupertinoColors.white),
          ),
          decoration: BoxDecoration(
            color:
                widget.disabled
                    ? adaptiveColor(context, CupertinoColors.systemGrey5, CupertinoColors.darkBackgroundGray) 
                    : adaptiveColor(context, CupertinoColors.white, CupertinoColors.darkBackgroundGray),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: adaptiveColor(context, CupertinoColors.systemGrey5, Colors.transparent))
          ),
          suffix:
              widget.suffix ??
              ((isPasswordField && !widget.alwaysHidePassword)
                  ? CupertinoButton(
                    padding: EdgeInsets.zero,

                    onPressed:
                        widget.disabled
                            ? null
                            : () {
                              setState(() {
                                isPasswordHidden = !isPasswordHidden;
                              });
                            },
                    child: Icon(
                      isPasswordHidden
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      color:
                          widget.disabled ? CupertinoColors.inactiveGray : null,
                    ),
                  )
                  : null),

          onChanged: widget.disabled ? null : widget.onChanged,
          onSubmitted: widget.disabled ? null : widget.onSubmitted,
        ),

        SizedBox(height: 5),
        if (widget.error != null)
          Text(
            widget.error!,
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.destructiveRed,
            ),
          ),
      ],
    );
  }
}
