import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

@Deprecated("Use 'Field' from 'utility/widgets/field.dart' instead.")
class DismissableTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autocorrect;
  final bool autofocus;
  final bool expands;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final String? placeholder;
  final TextStyle? style;
  final TextStyle? placeholderStyle;
  final Brightness? keyboardAppearance;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final bool? showCursor;
  final Widget? prefix;
  final Widget? suffix;
  final OverlayVisibilityMode suffixMode;
  final GestureTapCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final List<TextInputFormatter>? inputFormatters;
  final bool enableSuggestions;
  final bool? enableInteractiveSelection;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;

  const DismissableTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.autofocus = false,
    this.expands = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.padding,
    this.decoration,
    this.placeholder,
    this.style,
    this.placeholderStyle,
    this.keyboardAppearance,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.strutStyle,
    this.textDirection,
    this.showCursor,
    this.prefix,
    this.suffix,
    this.suffixMode = OverlayVisibilityMode.always,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.inputFormatters,
    this.enableSuggestions = true,
    this.enableInteractiveSelection,
    this.scrollController,
    this.scrollPhysics,
  });

  @override
  State<DismissableTextField> createState() => _DismissableTextFieldState();
}

class _DismissableTextFieldState extends State<DismissableTextField> {
  late final FocusNode focusNode = widget.focusNode ?? FocusNode();

  @override
  void dispose() {
    if (widget.focusNode == null) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: widget.controller,
      focusNode: focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      autofocus: widget.autofocus,
      expands: widget.expands,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      padding: widget.padding ?? EdgeInsets.zero,
      decoration: widget.decoration,
      placeholder: widget.placeholder,
      style: widget.style,
      placeholderStyle: widget.placeholderStyle,
      keyboardAppearance: widget.keyboardAppearance,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      strutStyle: widget.strutStyle,
      textDirection: widget.textDirection,
      showCursor: widget.showCursor,
      prefix: widget.prefix,
      suffix: widget.suffix,
      suffixMode: widget.suffixMode,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      inputFormatters: widget.inputFormatters,
      enableSuggestions: widget.enableSuggestions,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      scrollController: widget.scrollController,
      scrollPhysics: widget.scrollPhysics,
      onTapOutside: (_) => focusNode.unfocus(),
    );
  }
}
