import 'package:flutter/cupertino.dart';

class CustomTextField extends StatefulWidget {
  final String title;
  final String placeholder;
  final String? error;
  final Widget? suffix;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final bool alwaysHidePassword;
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
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          suffix:
              widget.suffix ??
              ((isPasswordField && !widget.alwaysHidePassword)
                  ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      isPasswordHidden
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordHidden = !isPasswordHidden;
                      });
                    },
                  )
                  : null),
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
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
