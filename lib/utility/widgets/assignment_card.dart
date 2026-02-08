import 'dart:async';
import 'package:animated_line_through/animated_line_through.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';

class AssignmentCardController {
  final key = GlobalKey();

  void Function()? _bounceEffectTrigger;
  void triggerBounceEffect() => _bounceEffectTrigger?.call();
}

class AssignmentCard extends StatefulWidget {
  final Assignment assignment;
  final VoidCallback? onEditButtonClicked, onDeleteButtonClicked;
  final Function(bool isMarkedAsDone)? onMarkAsDoneButtonClicked;
  final VoidCallback? onCardTap;
  final bool isPreview;
  final AssignmentCardController? controller;

  final bounceDuration = const Duration(milliseconds: 600);

  const AssignmentCard({
    super.key,
    required this.assignment,
    this.isPreview = false,
    this.onEditButtonClicked,
    this.onDeleteButtonClicked,
    this.onMarkAsDoneButtonClicked,
    this.onCardTap,
    this.controller,
  });

  @override
  State<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<AssignmentCard> with SingleTickerProviderStateMixin {
  final globals = GlobalsService();
  final mainContainerKey = GlobalKey();
  late final controller = widget.controller ?? AssignmentCardController();

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
    final newValue = !widget.assignment.isMarkedAsDone;
    setState(() => widget.assignment.isMarkedAsDone = newValue);
    HapticFeedback.mediumImpact();
    widget.onMarkAsDoneButtonClicked?.call(newValue);

    widget.assignment.save();
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
            color: AppColors.secondaryBackground.adaptTo(context).withAlpha(isExpanded ? 255 : 200),
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
    final isTest = widget.assignment.isTest;
    final isPreview = widget.isPreview;
    final isPreviewTitleEmpty = isPreview && (widget.assignment.title == null || widget.assignment.title!.isEmpty);
    final isPreviewDescriptionEmpty = isPreview && widget.assignment.content.isEmpty;
    final isMarkedAsDone = widget.assignment.isMarkedAsDone;
    final isGraded = widget.assignment.isGraded;

    final title =
        isTest
            ? "Test ${SubjectHelper.withPreposition(widget.assignment.subject) ?? ""}"
            : SubjectHelper.toFrenchOrNull(widget.assignment.subject)?.capitalize();

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
              buildButton(0, "Supprimer", HugeIcons.strokeRoundedDelete04, AppColors.text.adaptTo(context), () => widget.onDeleteButtonClicked?.call()),
              buildButton(1, "Modifier", HugeIcons.strokeRoundedPencilEdit02, AppColors.text.adaptTo(context), () {
                toggleExpanded();
                widget.onEditButtonClicked?.call();
              }),
              if (!isTest) buildButton(2, "Terminé", HugeIcons.strokeRoundedCheckmarkSquare04, AppColors.text.adaptTo(context), markAsDone),
            ],
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context).withBrightness(-.02), borderRadius: BorderRadius.circular(12)),
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
                          HugeIcon(icon: HugeIcons.strokeRoundedDashedLine02, color: AppColors.text.adaptTo(context), size: 14),
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
                      color: AppColors.secondaryBackground.adaptTo(context).withBrightness(isMarkedAsDone && !isExpanded ? -.025 : 0),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),

                      boxShadow: [
                        if (globals.appBrightness == Brightness.dark || isPreview)
                          BoxShadow(color: AppColors.black.withAlpha(50), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 12).add(const EdgeInsets.only(top: 6)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 6,
                            children: [
                              // Icon or checkbox
                              SizedBox(
                                height: 30,
                                child:
                                    isTest
                                        ? HugeIcon(icon: HugeIcons.strokeRoundedTextCheck, color: AppColors.red, size: 22)
                                        : GestureDetector(
                                          onTap: isPreview ? null : markAsDone,
                                          child: HugeIcon(
                                            icon: isMarkedAsDone ? HugeIcons.strokeRoundedCheckmarkSquare04 : HugeIcons.strokeRoundedSquare,
                                            size: 30,
                                            color: isMarkedAsDone ? AppColors.green : AppColors.secondaryText.adaptTo(context),
                                          ),
                                        ),
                              ),

                              // Subject label
                              Expanded(
                                child: Row(
                                  spacing: 4,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (isGraded) HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge04, color: AppColors.text.adaptTo(context), size: 20),
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
                                                    ? AppColors.red
                                                    : AppColors.text.adaptTo(context).withAlpha(((isMarkedAsDone || title == null) ? .5 : 1.0).toByte()),
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
                              if (!isPreview)
                                HugeIcon(
                                  icon: isExpanded ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
                                  size: 18,
                                  color: AppColors.tertiaryText.adaptTo(context),
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
                                  dashColor: AppColors.tertiaryBackground.adaptTo(context),
                                  dashBorderRadius: 2,
                                );
                              },
                            ),
                          ),

                        // Title
                        if (isTest || isGraded)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12).add(EdgeInsetsGeometry.only(top: 6, bottom: 10)),
                            child: CustomText(
                              isPreviewTitleEmpty
                                  ? "Titre du ${isTest ? "test" : "devoir noté"}"
                                  : widget.assignment.title ?? "${isTest ? "Test" : "Devoir noté"} sans titre",
                              style: TextStyle(
                                color: AppColors.text.adaptTo(context).withAlpha((isPreviewTitleEmpty || isMarkedAsDone ? .5 : .9).toByte()),
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),

                              boldWeight: FontWeight.w800,
                              overflow: TextOverflow.fade,
                              maxLines: isPreview ? 3 : null,
                            ),
                          ),

                        // Assignment content
                        if (isPreview || widget.assignment.content.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12).add(EdgeInsetsGeometry.only(top: 6, bottom: 10)),
                            child: AnimatedLineThrough(
                              duration: const Duration(milliseconds: 150),
                              isCrossed: isMarkedAsDone,
                              strokeWidth: .5,
                              child: CustomText(
                                isPreviewDescriptionEmpty ? "Description du devoir" : widget.assignment.content,
                                style: TextStyle(
                                  color: AppColors.text.adaptTo(context).withAlpha((isPreviewDescriptionEmpty || isMarkedAsDone ? .5 : .9).toByte()),
                                ),
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
            ),
          ),
          // Positioned(top: -5, right: -5, child: Opacity(opacity: isMarkedAsDone ? .5 : 1, child: Image.asset("assets/pin.png", width: 30, height: 30))),
        ],
      ),
    );
  }
}
