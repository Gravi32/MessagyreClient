import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AutocompleteField extends StatefulWidget {
  final List<Object> items;
  final Widget Function(Object item, String query) itemBuilder;
  final void Function(Object item) onSelected;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final TextStyle? style;
  final TextStyle? placeholderStyle;
  final Widget? prefix;
  final Widget? suffix;
  final OverlayVisibilityMode suffixMode;
  final BoxDecoration? decoration;
  final EdgeInsets? padding;
  final double optionsMaxHeight;
  final bool forceValid;

  const AutocompleteField({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onSelected,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.style,
    this.placeholderStyle,
    this.prefix,
    this.suffix,
    this.suffixMode = OverlayVisibilityMode.always,
    this.decoration,
    this.padding,
    this.optionsMaxHeight = 180,
    this.forceValid = true,
  });

  @override
  State<AutocompleteField> createState() => _AutocompleteFieldState();
}

class _AutocompleteFieldState extends State<AutocompleteField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late List<MapEntry<Object, String>> _normalized;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _normalized = widget.items.map((e) => MapEntry(e, _normalize(e.toString()))).toList();
    if (widget.forceValid) {
      _focusNode.addListener(() {
        if (!_focusNode.hasFocus) _validateAndFix();
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[ïî]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  Object? _matchItem(String input) {
    final n = _normalize(input);
    for (final e in _normalized) {
      if (e.value == n) return e.key;
    }
    return null;
  }

  void _validateAndFix() {
    final match = _matchItem(_controller.text);
    if (match != null) {
      widget.onSelected(match);
      _controller.text = match.toString();
    } else {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Object>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        if (value.text.isEmpty) return const Iterable<Object>.empty();
        final input = _normalize(value.text);
        return _normalized.where((e) => e.value.contains(input)).map((e) => e.key);
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, controller, focusNode, _) {
        return CupertinoTextField(
          controller: controller,
          focusNode: focusNode,
          placeholder: widget.placeholder,
          prefix: widget.prefix,
          suffix: widget.suffix,
          suffixMode: widget.suffixMode,
          style: widget.style,
          placeholderStyle: widget.placeholderStyle ?? TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context)),
          decoration: widget.decoration ?? const BoxDecoration(),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8),

          onSubmitted: (value) {
            if (widget.forceValid) _validateAndFix();
          },
          onTapOutside: (event) => focusNode.unfocus(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: BoxConstraints(maxHeight: widget.optionsMaxHeight),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: CupertinoColors.black.withAlpha(150), blurRadius: 10)],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(option),
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), child: widget.itemBuilder(option, _controller.text)),
                  ),
                  if (index < options.length - 1) Divider(height: 1, color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: .1)),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
