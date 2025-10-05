import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';

class HomeworkCard extends StatefulWidget {
  final Homework homework;
  final VoidCallback? onEditButtonClicked, onDeleteButtonClicked;
  final bool isPreview;

  const HomeworkCard({super.key, required this.homework, this.isPreview = false, this.onEditButtonClicked, this.onDeleteButtonClicked});

  @override
  State<HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<HomeworkCard> {
  final data = Data();
  final mainContainerKey = GlobalKey();
  final subjectContainerKey = GlobalKey();
  double? mainContainerHeight, subjectContainerWidth;

  bool isExpanded = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => calculateSizes);
  }

  void calculateSizes() {
    final mainContainerContext = mainContainerKey.currentContext;
    final subjectContainerContext = subjectContainerKey.currentContext;

    if (mainContainerContext != null) {
      final box = mainContainerContext.findRenderObject() as RenderBox;
      setState(() => mainContainerHeight = box.size.height);
    }

    if (subjectContainerContext != null) {
      final box = subjectContainerContext.findRenderObject() as RenderBox;
      setState(() => subjectContainerWidth = box.size.width);
    }
  }

  Widget buildButton(int popupOrderIndex, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300 + 50 * popupOrderIndex),
          curve: isExpanded ? Curves.easeOutBack : Curves.easeInBack,
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withAlpha(isExpanded ? 255 : 200),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          padding: EdgeInsets.only(top: isExpanded ? (mainContainerHeight?.abs() ?? 10) + 10 : 10, bottom: 10),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonsColor = adaptiveColor(CupertinoTheme.of(context).primaryColor, CupertinoColors.white);

    final isPreview = widget.isPreview;
    final isPreviewDescriptionEmpty = isPreview && widget.homework.content.isEmpty;
    final isMarkedAsDone = widget.homework.isMarkedAsDone;
    final isGraded = widget.homework.isGraded;
    final isTest = widget.homework.isTest;

    calculateSizes();

    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildButton(0, CupertinoIcons.delete, buttonsColor, () {
              if (widget.onDeleteButtonClicked != null) widget.onDeleteButtonClicked!();
            }),
            buildButton(1, CupertinoIcons.pen, buttonsColor, () {
              if (widget.onEditButtonClicked != null) widget.onEditButtonClicked!();
            }),
            if (!isTest)
              buildButton(2, CupertinoIcons.check_mark, buttonsColor, () {
                setState(() => widget.homework.isMarkedAsDone = !widget.homework.isMarkedAsDone);
              }),
          ],
        ),

        CupertinoPressable(
          onTap: isPreview ? null : () => setState(() => isExpanded = !isExpanded),
          key: mainContainerKey,
          constraints: BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            boxShadow:
                data.appBrightness == Brightness.dark || isPreview
                    ? [BoxShadow(color: CupertinoColors.black.withAlpha(50), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5))]
                    : null,
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
                                Icon(
                                  CupertinoIcons.chart_bar_alt_fill,
                                  color: isTest ? CupertinoColors.systemRed : adaptiveColor(CupertinoColors.tertiaryLabel, CupertinoColors.white),
                                  size: 20,
                                ),
                                Text("TEST", style: TextStyle(color: CupertinoColors.systemRed, fontWeight: FontWeight.w700, fontSize: 20)),
                              ],
                            )
                            : GestureDetector(
                              onTap:
                                  isPreview
                                      ? null
                                      : () => setState(() {
                                        widget.homework.isMarkedAsDone = !widget.homework.isMarkedAsDone;
                                      }),

                              child: Icon(isMarkedAsDone ? CupertinoIcons.checkmark_square : CupertinoIcons.square, size: 30),
                            ),
                  ),

                  Expanded(
                    child: Row(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          SubjectHelper.toFrench(widget.homework.subject).capitalize(),
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context).withOpacity(isMarkedAsDone ? .5 : 1),
                            fontWeight: FontWeight.w700,
                            decoration: isMarkedAsDone ? TextDecoration.lineThrough : null,
                            fontSize: 20,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.fade,
                        ),
                        if (isGraded)
                          Icon(CupertinoIcons.chart_bar_alt_fill, color: adaptiveColor(CupertinoColors.tertiaryLabel, CupertinoColors.white), size: 20),
                      ],
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  isPreviewDescriptionEmpty ? "Description du ${isTest ? "test" : "devoir"}" : widget.homework.content,

                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context).withOpacity(isPreviewDescriptionEmpty || isMarkedAsDone ? .5 : .9),
                    decoration: isMarkedAsDone ? TextDecoration.lineThrough : null,
                  ),

                  overflow: TextOverflow.fade,
                  maxLines: isPreview ? 3 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
