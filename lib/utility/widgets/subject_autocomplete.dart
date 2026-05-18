import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/composite_subject_badge.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class SubjectOption {
  final Subject? subject;
  final CompositeSubject? compositeSubject;

  SubjectOption.subject(this.subject) : compositeSubject = null;
  SubjectOption.composite(this.compositeSubject) : subject = null;

  String get name => subject?.name ?? compositeSubject!.name;

  bool get isSubject => subject != null;
}

class SubjectAutocomplete extends StatefulWidget {
  final void Function(Subject subject)? onSubjectSelected;
  final void Function(CompositeSubject compositeSubject)? onCompositeSubjectSelected;
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
    this.onSubjectSelected,
    this.onCompositeSubjectSelected,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.style,
    this.placeholderStyle,
    this.prefix,
    this.suffix,
    this.suffixMode = .always,
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

  late TextEditingController controller;
  late FocusNode focusNode;

  late final List<MapEntry<SubjectOption, String>> normalizedOptions;
  String? currentOption; // If it's not empty, the subject has already been chosen and we're not showing other options

  @override
  void initState() {
    super.initState();

    controller = widget.controller ?? TextEditingController();
    focusNode = widget.focusNode ?? FocusNode();

    final subjects = database.subjects.getAll();
    final compositeSubjects = database.compositeSubjects.getAll();

    final subjectsInsideComposite = <String>{};

    for (final compositeSubject in compositeSubjects) {
      final firstSubject = compositeSubject.firstSubject.value;
      final secondSubject = compositeSubject.secondSubject.value;
      subjectsInsideComposite.addAll([if (firstSubject != null) firstSubject.code, if (secondSubject != null) secondSubject.code]);
    }

    normalizedOptions = [];

    if (widget.useCompositeSubjects) {
      for (final composite in compositeSubjects) {
        normalizedOptions.add(MapEntry(SubjectOption.composite(composite), _normalize(composite.name)));
      }

      for (final subject in subjects) {
        if (subject.isLocked || subjectsInsideComposite.contains(subject.code)) continue;
        normalizedOptions.add(MapEntry(SubjectOption.subject(subject), _normalize(subject.name)));
      }
    } else {
      for (final subject in subjects) {
        if (subject.isLocked) continue;
        normalizedOptions.add(MapEntry(SubjectOption.subject(subject), _normalize(subject.name)));
      }
    }

    if (widget.forceValid) {
      focusNode.addListener(() {
        if (!focusNode.hasFocus) _validateAndFix();
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    if (widget.focusNode == null) focusNode.dispose();
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

  void _validateAndFix() {
    final normalizedInput = _normalize(controller.text);

    for (final entry in normalizedOptions) {
      if (entry.value == normalizedInput) {
        final option = entry.key;

        if (option.isSubject) {
          widget.onSubjectSelected?.call(option.subject!);
        } else {
          widget.onCompositeSubjectSelected?.call(option.compositeSubject!);
        }

        controller.text = option.name;
        currentOption = option.name;
        return;
      }
    }

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: widget.placeholder ?? 'Branche',
        prefix: widget.prefix,
        suffix: widget.suffix,
        suffixMode: widget.suffixMode,
        style: widget.style?.merge(AppStyles.placeholder(context)) ?? TextStyle(color: AppColors.inactive.adaptTo(context)),
        placeholderStyle: widget.placeholderStyle ?? TextStyle(color: AppColors.inactive.adaptTo(context)),
        decoration: widget.decoration ?? const BoxDecoration(),
        padding: widget.padding ?? const .symmetric(horizontal: 8),
        enabled: false,
      );
    }

    return RawAutocomplete<SubjectOption>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsViewOpenDirection: .up,

      optionsBuilder: (query) {
        if (query.text.isEmpty || currentOption != null) {
          return const Iterable<SubjectOption>.empty();
        }

        final input = _normalize(query.text);

        return normalizedOptions.where((e) => e.value.contains(input)).map((e) => e.key);
      },

      displayStringForOption: (option) => option.name,

      onSelected: (option) {
        if (option.isSubject) {
          widget.onSubjectSelected?.call(option.subject!);
        } else {
          widget.onCompositeSubjectSelected?.call(option.compositeSubject!);
        }
      },

      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return CupertinoTextField(
          controller: controller,
          focusNode: focusNode,
          placeholder: widget.placeholder ?? 'Branche',
          prefix: widget.prefix,
          suffix: widget.suffix,
          suffixMode: widget.suffixMode,
          style: widget.style ?? AppStyles.primaryText(context),
          placeholderStyle: widget.placeholderStyle ?? AppStyles.placeholder(context),
          decoration: widget.decoration ?? const BoxDecoration(),
          padding: widget.padding ?? const .symmetric(horizontal: 8),

          onSubmitted: (value) {
            if (widget.forceValid) {
              _validateAndFix();
            } else {
              onFieldSubmitted();
            }
          },

          onChanged: (_) => currentOption = null,

          onTapOutside: (event) {
            if (event.kind != PointerDeviceKind.touch) {
              focusNode.unfocus();
            }
          },
        );
      },

      optionsViewBuilder: (context, onSelected, rawOptions) {
        final options = rawOptions.toList();

        return RoundContainer(
          margin: const .only(bottom: 8),
          padding: .zero,
          constraints: BoxConstraints(maxHeight: widget.optionsMaxHeight),
          color: AppColors.secondaryBackground.adaptTo(context),
          child: ListView.separated(
            shrinkWrap: true,
            reverse: true,
            padding: .zero,
            itemCount: options.length,

            itemBuilder: (context, index) {
              final option = options[index];

              return Column(
                crossAxisAlignment: .stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(option),

                    child: Padding(
                      padding: const .symmetric(vertical: 10, horizontal: 16),

                      child: Align(
                        alignment: .centerLeft,

                        child: Row(
                          spacing: 15,
                          children: [
                            option.isSubject ? SubjectBadge(subject: option.subject!) : CompositeSubjectBadge(compositeSubject: option.compositeSubject!),

                            Text.rich(
                              TextSpan(
                                children: highlightSearchMatch(option.name, controller.text, useCache: true),
                                style: AppStyles.secondaryHeader(context).copyWith(fontWeight: .w400),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },

            separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.secondaryBackground.adaptTo(context)),
          ),
        );
      },
    );
  }
}
