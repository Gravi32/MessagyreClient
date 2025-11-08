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
  void Function(Color color)? _borderEffectTrigger;
  void Function()? _bounceEffectTrigger;
  void triggerBorderEffect(Color color) => _borderEffectTrigger?.call(color);
  void triggerBounceEffect() => _bounceEffectTrigger?.call();
}

class HomeworkCard extends StatefulWidget {
  final Homework homework;
  final VoidCallback? onEditButtonClicked, onDeleteButtonClicked;
  final Function(bool isMarkedAsDone)? onMarkAsDoneButtonClicked;
  final bool isPreview;
  final HomeworkCardController? controller;

  final bounceDuration = const Duration(milliseconds: 600);

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
  bool isBouncing = false;
  Color? borderColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => calculateSizes());
    widget.controller?._borderEffectTrigger = triggerBorderEffect;
    widget.controller?._bounceEffectTrigger = triggerBounceEffect;
  }

  void triggerBorderEffect(Color color) {
    setState(() => borderColor = color);
    Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => borderColor = null);
    });
  }

  void triggerBounceEffect() async {
    if (isBouncing) return;
    setState(() => isBouncing = true);

    await Future.delayed(widget.bounceDuration);
    if (!mounted) return;
    setState(() => isBouncing = false);
  }

  void calculateSizes() {
    final mainContainerContext = mainContainerKey.currentContext;
    if (mainContainerContext != null) {
      final box = mainContainerContext.findRenderObject() as RenderBox;
      mainContainerHeight = box.size.height;
    }
  }

  void markAsDone() {
    final newValue = !widget.homework.isMarkedAsDone;
    setState(() => widget.homework.isMarkedAsDone = newValue);
    widget.onMarkAsDoneButtonClicked?.call(newValue);
    if (newValue) triggerBorderEffect(CupertinoColors.activeGreen);
  }

  void toggleExpanded() {
    setState(() => isExpanded = !isExpanded);
    WidgetsBinding.instance.addPostFrameCallback((_) => calculateSizes());
  }

  Widget buildButton(int popupOrderIndex, String label, List<List> icon, Color color, VoidCallback onTap) {
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
          child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 6, children: [HugeIcon(icon: icon, color: color, size: 20), Text(label)]),
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

    return AnimatedScale(
      scale: isBouncing ? 1.05 : 1,
      duration: widget.bounceDuration,
      curve: Curves.easeOutBack,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildButton(
                0,
                "Supprimer",
                HugeIcons.strokeRoundedDelete04,
                CupertinoColors.label.resolveFrom(context),
                () => widget.onDeleteButtonClicked?.call(),
              ),
              buildButton(
                1,
                "Modifier",
                HugeIcons.strokeRoundedPencilEdit02,
                CupertinoColors.label.resolveFrom(context),
                () => widget.onEditButtonClicked?.call(),
              ),
              if (!isTest) buildButton(2, "Terminé", HugeIcons.strokeRoundedCheckmarkSquare04, CupertinoColors.label.resolveFrom(context), markAsDone),
            ],
          ),
          CupertinoPressable(
            onTap: isPreview ? null : toggleExpanded,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              key: mainContainerKey,
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withBrightness(isMarkedAsDone && !isExpanded ? -.025 : 0),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: borderColor != null ? Border.all(color: borderColor!, width: .5, strokeAlign: BorderSide.strokeAlignOutside) : null,
                boxShadow: [
                  if (data.appBrightness == Brightness.dark || isPreview)
                    BoxShadow(color: CupertinoColors.black.withAlpha(50), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5)),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
          Positioned(top: -5, right: -5, child: Opacity(opacity: isMarkedAsDone ? .5 : 1, child: Image.asset("assets/pin.png", width: 30, height: 30))),
        ],
      ),
    );
  }
}
