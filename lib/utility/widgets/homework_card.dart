import 'dart:async';
import 'package:animated_line_through/animated_line_through.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';

class HomeworkCardController {
  void Function(Color color)? _trigger;
  void trigger(Color color) => _trigger?.call(color);
}

class HomeworkCard extends StatefulWidget {
  final Homework homework;
  final VoidCallback? onEditButtonClicked, onDeleteButtonClicked;
  final Function(bool isMarkedAsDone)? onMarkAsDoneButtonClicked;
  final bool isPreview;
  final HomeworkCardController? controller;

  const HomeworkCard({
    super.key,
    required this.homework,
    this.isPreview = false,
    this.onEditButtonClicked,
    this.onDeleteButtonClicked,
    this.onMarkAsDoneButtonClicked,
    this.controller,
  });

  @override
  State<HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<HomeworkCard> with SingleTickerProviderStateMixin {
  final data = Data();
  final mainContainerKey = GlobalKey();
  late final controller = widget.controller ?? HomeworkCardController();

  double? mainContainerHeight;
  bool isExpanded = false;

  Color? borderColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => calculateSizes());
    widget.controller?._trigger = triggerBorderEffect;
  }

  void triggerBorderEffect(Color color) {
    setState(() => borderColor = color);

    Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => borderColor = CupertinoColors.secondarySystemBackground.resolveFrom(context));
    });
  }

  void calculateSizes() {
    final mainContainerContext = mainContainerKey.currentContext;
    if (mainContainerContext != null) {
      final box = mainContainerContext.findRenderObject() as RenderBox;
      setState(() => mainContainerHeight = box.size.height);
    }
  }

  void markAsDone() {
    final newValue = !widget.homework.isMarkedAsDone;
    setState(() => widget.homework.isMarkedAsDone = newValue);

    if (widget.onMarkAsDoneButtonClicked != null) widget.onMarkAsDoneButtonClicked!(newValue);
    if (newValue) triggerBorderEffect(CupertinoColors.activeGreen);
  }

  Widget buildButton(int popupOrderIndex, List<List> icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300 + 50 * popupOrderIndex),
          curve: isExpanded ? Curves.easeOutBack : Curves.easeInBack,
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withAlpha(isExpanded ? 255 : 200),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          padding: EdgeInsets.only(top: isExpanded ? (mainContainerHeight?.abs() ?? 10) + 10 : 10, bottom: 10),
          child: HugeIcon(icon: icon, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTest = widget.homework.isTest;
    final isPreview = widget.isPreview;
    final isPreviewDescriptionEmpty = isPreview && widget.homework.content.isEmpty;
    final isMarkedAsDone = widget.homework.isMarkedAsDone;
    final isGraded = widget.homework.isGraded;

    final effectiveBorderColor = borderColor ?? CupertinoColors.secondarySystemBackground.resolveFrom(context);

    calculateSizes();
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildButton(0, HugeIcons.strokeRoundedDelete04, CupertinoColors.label.resolveFrom(context), () => widget.onDeleteButtonClicked?.call()),
            buildButton(1, HugeIcons.strokeRoundedPencilEdit02, CupertinoColors.label.resolveFrom(context), () => widget.onEditButtonClicked?.call()),
            if (!isTest) buildButton(2, HugeIcons.strokeRoundedCheckmarkSquare04, CupertinoColors.label.resolveFrom(context), markAsDone),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          key: mainContainerKey,
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(color: effectiveBorderColor, width: .5),
            boxShadow: [
              if (data.appBrightness == Brightness.dark || isPreview)
                BoxShadow(color: CupertinoColors.black.withAlpha(50), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5)),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: CupertinoPressable(
            onTap: isPreview ? null : () => setState(() => isExpanded = !isExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    SizedBox(
                      height: 30,
                      child:
                          isTest
                              ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                textBaseline: TextBaseline.alphabetic,
                                spacing: 2,
                                children: [
                                  HugeIcon(icon: HugeIcons.strokeRoundedTextCheck, color: CupertinoColors.systemRed, size: 20),
                                  const Text("TEST", style: TextStyle(color: CupertinoColors.systemRed, fontWeight: FontWeight.w700, fontSize: 20)),
                                ],
                              )
                              : GestureDetector(
                                onTap: isPreview ? null : markAsDone,
                                child: HugeIcon(
                                  icon: isMarkedAsDone ? HugeIcons.strokeRoundedCheckmarkSquare04 : HugeIcons.strokeRoundedSquare,
                                  size: 30,
                                  color: isMarkedAsDone ? CupertinoColors.activeGreen : CupertinoColors.secondaryLabel.resolveFrom(context),
                                ),
                              ),
                    ),
                    Expanded(
                      child: Row(
                        spacing: 4,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: AnimatedLineThrough(
                              duration: const Duration(milliseconds: 150),
                              isCrossed: isMarkedAsDone,
                              strokeWidth: 1,
                              child: Text(
                                SubjectHelper.toFrench(widget.homework.subject).capitalize(),
                                style: TextStyle(
                                  color: CupertinoColors.label.resolveFrom(context).withOpacity(isMarkedAsDone ? .5 : 1),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.fade,
                              ),
                            ),
                          ),
                          if (isGraded)
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkBadge04,
                              color: adaptiveColor(CupertinoColors.tertiaryLabel, CupertinoColors.white),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: AnimatedLineThrough(
                    duration: const Duration(milliseconds: 150),
                    isCrossed: isMarkedAsDone,
                    strokeWidth: .5,
                    child: CustomText(
                      isPreviewDescriptionEmpty ? "Description du ${isTest ? "test" : "devoir"}" : widget.homework.content,
                      style: TextStyle(color: CupertinoColors.label.resolveFrom(context).withOpacity(isPreviewDescriptionEmpty || isMarkedAsDone ? .5 : .9)),
                      boldWeight: FontWeight.w800,
                      overflow: TextOverflow.fade,
                      maxLines: isPreview ? 3 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
