import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/report_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class SubjectAutocomplete extends StatefulWidget {
  final void Function(Subject subject) onSelected;
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
  final bool enabled;
  final bool useCompositeSubjects;

  const SubjectAutocomplete({
    super.key,
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
    this.enabled = true,
    this.useCompositeSubjects = false,
  });

  @override
  State<SubjectAutocomplete> createState() => _SubjectAutocompleteState();
}

class _SubjectAutocompleteState extends State<SubjectAutocomplete> {
  final database = DatabaseService();
  final report = ReportService();

  late TextEditingController _controller;
  late FocusNode _focusNode;
  late final List<MapEntry<Subject, String>> _subjectsNormalized;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _subjectsNormalized =
        (widget.useCompositeSubjects ? report.allSubjects : database.subjects.getAll()).map((subject) => MapEntry(subject, _normalize(subject.name))).toList();
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

  Subject? _matchSubject(String input) {
    final normalized = _normalize(input);
    for (final e in _subjectsNormalized) {
      if (e.value == normalized) return e.key;
    }
    return null;
  }

  void _validateAndFix() {
    final match = _matchSubject(_controller.text);
    if (match != null) {
      widget.onSelected(match);
      _controller.text = match.name;
    } else {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return CupertinoTextField(
        controller: _controller,
        focusNode: _focusNode,
        placeholder: widget.placeholder ?? 'Branche',
        prefix: widget.prefix,
        suffix: widget.suffix,
        suffixMode: widget.suffixMode,
        style: widget.style ?? TextStyle(color: AppColors.inactive.adaptTo(context)),
        placeholderStyle: widget.placeholderStyle ?? TextStyle(color: AppColors.inactive.adaptTo(context)),
        decoration: widget.decoration ?? const BoxDecoration(),
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8),
        enabled: false,
      );
    }

    return RawAutocomplete<Subject>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        if (value.text.isEmpty) return const Iterable<Subject>.empty();
        final input = _normalize(value.text);
        return _subjectsNormalized.where((e) => e.value.contains(input)).map((e) => e.key);
      },
      displayStringForOption: (Subject option) => option.name,
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return CupertinoTextField(
          controller: controller,
          focusNode: focusNode,
          placeholder: widget.placeholder ?? 'Branche',
          prefix: widget.prefix,
          suffix: widget.suffix,
          suffixMode: widget.suffixMode,
          style: widget.style,
          placeholderStyle: widget.placeholderStyle ?? TextStyle(color: AppColors.placeholderText.adaptTo(context)),
          decoration: widget.decoration ?? const BoxDecoration(),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8),
          onSubmitted: (value) {
            if (widget.forceValid) {
              _validateAndFix();
            } else {
              onFieldSubmitted();
            }
          },
          onTapOutside: (event) {
            // Close the keyboard unless user is scrolling
            if (event.kind != PointerDeviceKind.touch) focusNode.unfocus();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, rawOptions) {
        final options = rawOptions.toList();

        return Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: BoxConstraints(maxHeight: widget.optionsMaxHeight),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground.adaptTo(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppColors.black.withAlpha(150), blurRadius: 10)],
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          spacing: 15,
                          children: [
                            SubjectBadge(subject: option),
                            Text.rich(
                              TextSpan(
                                children: highlightSearchMatch(option.name, _controller.text, useCache: true),
                                style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (index < options.length - 1) Divider(height: 1, color: AppColors.separator.adaptTo(context).withAlpha(.1.toByte())),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
