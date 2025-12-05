import 'dart:async';
import 'package:animated_line_through/animated_line_through.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';

class HomeworkCardController {
  final key = GlobalKey();

  void Function()? _bounceEffectTrigger;
  void triggerBounceEffect() => _bounceEffectTrigger?.call();
}

class HomeworkCard extends StatefulWidget {
  final Homework homework;
  final VoidCallback? onEditButtonClicked, onDeleteButtonClicked;
  final Function(bool isMarkedAsDone)? onMarkAsDoneButtonClicked;
  final VoidCallback? onCardTap;
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
    this.onCardTap,
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
    widget.controller?._bounceEffectTrigger = triggerBounceEffect;
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
    HapticFeedback.mediumImpact();
    widget.onMarkAsDoneButtonClicked?.call(newValue);

    widget.homework.save();
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

    final title =
        isTest ? "Test ${SubjectHelper.withPreposition(widget.homework.subject)}" : SubjectHelper.toFrenchOrNull(widget.homework.subject)?.capitalize();

    return AnimatedScale(
      key: controller.key,
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
          Container(
            decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withBrightness(-.02), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                if (isPreview)
                  Padding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 12, vertical: 6),
                    child: Opacity(
                      opacity: .5,
                      child: Row(
                        spacing: 6,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedDashedLine02, color: CupertinoColors.label.resolveFrom(context), size: 14,),
                          Text("Aperçu du devoir", style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                CupertinoPressable(
                  onTap:
                      isPreview
                          ? widget.onCardTap
                          : () {
                            toggleExpanded();
                            HapticFeedback.lightImpact();
                          },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    key: mainContainerKey,
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withBrightness(isMarkedAsDone && !isExpanded ? -.025 : 0),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),

                      boxShadow: [
                        if (data.appBrightness == Brightness.dark || isPreview)
                          BoxShadow(color: CupertinoColors.black.withAlpha(50), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 12).add(const EdgeInsets.only(top: 6)),
                          child: Row(
                            spacing: 6,
                            children: [
                              // Icon or checkbox
                              SizedBox(
                                height: 30,
                                child:
                                    isTest
                                        ? HugeIcon(icon: HugeIcons.strokeRoundedTextCheck, color: CupertinoColors.systemRed, size: 22)
                                        : GestureDetector(
                                          onTap: isPreview ? null : markAsDone,
                                          child: HugeIcon(
                                            icon: isMarkedAsDone ? HugeIcons.strokeRoundedCheckmarkSquare04 : HugeIcons.strokeRoundedSquare,
                                            size: 30,
                                            color: isMarkedAsDone ? CupertinoColors.activeGreen : CupertinoColors.secondaryLabel.resolveFrom(context),
                                          ),
                                        ),
                              ),

                              // Subject label
                              Expanded(
                                child: Row(
                                  spacing: 4,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (isGraded)
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedCheckmarkBadge04,
                                        color: adaptiveColor(CupertinoColors.tertiaryLabel, CupertinoColors.white),
                                        size: 20,
                                      ),
                                    Expanded(
                                      child: AnimatedLineThrough(
                                        duration: const Duration(milliseconds: 150),
                                        isCrossed: isMarkedAsDone,
                                        strokeWidth: 1,
                                        child: Text(
                                          title ?? "Branche",
                                          style: TextStyle(
                                            color:
                                                isTest
                                                    ? CupertinoColors.systemRed.resolveFrom(context)
                                                    : CupertinoColors.label.resolveFrom(context).withValues(alpha: (isMarkedAsDone || title == null) ? .5 : 1),
                                            fontWeight: title == null ? FontWeight.w500 : FontWeight.w700,
                                            fontSize: 20,
                                          ),
                                          softWrap: true,
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Dashed separator
                        if (!isTest)
                          Padding(
                            padding: EdgeInsetsGeometry.only(top: 10, bottom: 4),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Dash(
                                  direction: Axis.horizontal,
                                  length: constraints.maxWidth,
                                  dashLength: 6,
                                  dashGap: 3,
                                  dashThickness: 1,
                                  dashColor: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
                                  dashBorderRadius: 2,
                                );
                              },
                            ),
                          ),

                        // Homework content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12).add(EdgeInsetsGeometry.only(top: 6, bottom: 10)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedLineThrough(
                                duration: const Duration(milliseconds: 150),
                                isCrossed: isMarkedAsDone,
                                strokeWidth: .5,
                                child: CustomText(
                                  isPreviewDescriptionEmpty ? "Description du ${isTest ? "test" : "devoir"}" : widget.homework.content,
                                  style: TextStyle(
                                    color: CupertinoColors.label.resolveFrom(context).withValues(alpha: isPreviewDescriptionEmpty || isMarkedAsDone ? .5 : .9),
                                    fontWeight: isTest ? FontWeight.w600 : null,
                                    fontSize: isTest ? 20 : null,
                                  ),

                                  boldWeight: FontWeight.w800,
                                  overflow: TextOverflow.fade,
                                  maxLines: isPreview ? 3 : null,
                                ),
                              ),

                              if (!isPreview)
                                Opacity(
                                  opacity: .3,
                                  child: HugeIcon(
                                    icon: isExpanded ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
                                    size: 18,
                                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Positioned(top: -5, right: -5, child: Opacity(opacity: isMarkedAsDone ? .5 : 1, child: Image.asset("assets/pin.png", width: 30, height: 30))),
        ],
      ),
    );
  }
}
