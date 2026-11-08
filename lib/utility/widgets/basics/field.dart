import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';

/// The app's text field. A single-line field always has the same height ([AppSizes.control], or
/// [AppSizes.compactControl] when [thin]), so it fits in fixed-height places such as the pinned search bars.
class Field extends StatefulWidget {
  final String placeholder;
  final List<List<dynamic>>? icon;
  final Function(String content)? onSubmitted;
  final Function(String content)? onChanged;
  final Function()? onTap;
  final Function()? onClear;
  final String? suffix;
  final String? error;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? textStyle;
  final FocusNode? focusNode;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsets? margin;
  final int? maxLines;
  final int? minLines;
  final bool thin;

  /// Filled with the sunken color, for a field laid on a card or a bar rather than on the page
  final bool sunken;
  final bool isPassword;
  final bool isSearch;
  final bool alwaysHidePassword;
  final bool enabled;
  final bool autofocus;

  const Field({
    super.key,
    required this.placeholder,
    this.icon,
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.onClear,
    this.suffix,
    this.error,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.textStyle,
    this.focusNode,
    this.scrollPhysics,
    this.margin,
    this.maxLines = 1,
    this.minLines = 1,
    this.thin = false,
    this.sunken = false,
    this.isPassword = false,
    this.isSearch = false,
    this.alwaysHidePassword = false,
    this.enabled = true,
    this.autofocus = false,
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
      textCapitalization: TextCapitalization.none,
      isPassword: true,
      alwaysHidePassword: alwaysHidePassword,
      enabled: enabled,
    );
  }

  factory Field.search({
    String? placeholder,
    Function(String content)? onChanged,
    Function()? onClear,
    TextEditingController? controller,
    FocusNode? focusNode,
  }) {
    return Field(
      placeholder: placeholder ?? AppStrings.search,
      icon: AppIcons.search,
      onChanged: onChanged,
      onClear: onClear,
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.none,
      thin: true,
      isSearch: true,
    );
  }

  /// Height of a single-line field
  static double heightOf({bool thin = false}) => thin ? AppSizes.compactControl : AppSizes.control;

  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  late bool _obscureText = widget.isPassword;
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;
  bool _hasFocus = false;

  TextEditingController get _controller => widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant Field oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() {
    if (mounted && _focusNode.hasFocus != _hasFocus) setState(() => _hasFocus = _focusNode.hasFocus);
  }

  bool get _isSingleLine => widget.maxLines == 1 && (widget.minLines ?? 1) <= 1;

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  Widget _trailingButton({required List<List<dynamic>> icon, required VoidCallback onTap}) {
    final color = AppColors.secondaryText.adaptTo(context);
    return CupertinoButton(
      padding: const .symmetric(horizontal: AppSpacing.m),
      minimumSize: const Size.square(AppSizes.compactControl),
      onPressed: widget.enabled ? onTap : null,
      child: AppIcon(icon: icon, color: color, size: widget.thin ? AppSizes.smallIcon : 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNumeric = widget.keyboardType == .number;
    final showingError = (widget.error ?? "").isNotEmpty;
    final height = Field.heightOf(thin: widget.thin);
    // A single-line field has a fixed height: its text is centered in it (2 × 1 px of border, ~26 px of text line)
    final verticalPadding = _isSingleLine ? ((height - 2 - 26) / 2).clamp(0.0, AppSpacing.l) : (widget.thin ? AppSpacing.s + 2 : AppSpacing.l);

    final textField = CupertinoTextField(
      padding: .only(left: widget.icon != null ? AppSpacing.s : AppSpacing.l, right: AppSpacing.l, top: verticalPadding, bottom: verticalPadding),
      placeholder: widget.placeholder,
      placeholderStyle: AppStyles.placeholder(context).copyWith(fontSize: isNumeric ? AppStyles.sizeSection : null),
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      expands: false,
      scrollPadding: const .only(bottom: 80), // Distance from the keyboard
      decoration: const BoxDecoration(),
      controller: _controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      obscureText: _obscureText,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      scrollPhysics: widget.scrollPhysics,
      textAlign: isNumeric ? .center : .start,
      textAlignVertical: TextAlignVertical.center,
      style: AppStyles.primaryText(context).merge(widget.textStyle?.copyWith(inherit: true)),
      onTapOutside: widget.focusNode == null && !(widget.isPassword && !widget.alwaysHidePassword) ? (_) => FocusScope.of(context).unfocus() : null,
      onTap: widget.onTap,
    );

    final field = Container(
      height: _isSingleLine ? height : null,
      constraints: _isSingleLine ? null : BoxConstraints(minHeight: height),
      decoration: BoxDecoration(
        color: (widget.enabled && !widget.sunken ? AppColors.secondaryBackground : AppColors.tertiaryBackground).adaptTo(context),
        border: .all(
          color: showingError
              ? AppColors.red
              : _hasFocus
              ? AppColors.text.adaptTo(context).withValues(alpha: .35)
              : widget.sunken
              ? AppColors.transparent
              : AppColors.separator.adaptTo(context),
        ),
        borderRadius: .circular(widget.thin ? height / 2 : AppRadius.m),
      ),
      child: Row(
        crossAxisAlignment: _isSingleLine ? .center : .end,
        children: [
          if (widget.icon != null)
            Padding(
              padding: EdgeInsets.only(left: AppSpacing.l, bottom: _isSingleLine ? 0 : verticalPadding),
              child: AppIcon(icon: widget.icon!, color: AppColors.secondaryText.adaptTo(context), size: widget.thin ? AppSizes.smallIcon + 2 : AppSizes.icon),
            ),
          Expanded(child: textField),
          if (widget.suffix != null)
            Padding(
              padding: const .only(right: AppSpacing.l),
              child: Text(widget.suffix!, style: AppStyles.secondaryText(context)),
            ),
          if (widget.isPassword && !widget.alwaysHidePassword)
            _trailingButton(
              icon: _obscureText ? HugeIcons.strokeRoundedView : HugeIcons.strokeRoundedViewOff,
              onTap: () => setState(() => _obscureText = !_obscureText),
            ),
          if (widget.isSearch)
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : _trailingButton(
                      icon: AppIcons.clear,
                      onTap: () {
                        _controller.clear();
                        widget.onChanged?.call("");
                        widget.onClear?.call();
                      },
                    ),
            ),
        ],
      ),
    );

    return Padding(
      padding: widget.margin ?? .zero,
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          field,
          if (showingError)
            Padding(
              padding: const .only(top: AppSpacing.xs, left: AppSpacing.l, right: AppSpacing.l),
              child: CustomText(widget.error!, style: AppStyles.error(context)),
            ),
        ],
      ),
    );
  }
}
