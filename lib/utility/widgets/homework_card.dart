import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';

class HomeworkCard extends StatefulWidget {
  final Homework homework;
  final VoidCallback onTap;

  const HomeworkCard({super.key, required this.homework, required this.onTap});

  @override
  State<HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<HomeworkCard> {
  final data = Data();
  final subjectContainerKey = GlobalKey();
  double? subjectWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidth());
  }

  void _measureWidth() {
    final context = subjectContainerKey.currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox;
      setState(() {
        subjectWidth = box.size.width;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 100),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              boxShadow: [BoxShadow(color: CupertinoColors.black.withAlpha(50), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5))],
            ),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.homework.title[0].toUpperCase() + widget.homework.title.substring(1),
                  style: TextStyle(
                    color: adaptiveColor(context, CupertinoTheme.of(context).primaryColor, CupertinoColors.white),
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                ),

                if (widget.homework.description != null && widget.homework.description!.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 8, bottom: 6), child: Text(widget.homework.description!)),
              ],
            ),
          ),

          if (widget.homework.isGraded && subjectWidth != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: subjectWidth! + 28,
                height: 26,
                decoration: BoxDecoration(
                  color: adaptiveColor(context, CupertinoColors.systemGrey4.resolveFrom(context), CupertinoColors.systemGrey4.resolveFrom(context)),
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Icon(
                    CupertinoIcons.chart_bar_alt_fill,
                    color: widget.homework.isTest ? CupertinoColors.systemRed : CupertinoColors.tertiaryLabel.resolveFrom(context),
                    size: 16,
                  ),
                ),
              ),
            ),

          Positioned(
            right: 0,
            top: 0,
            child: Container(
              height: 26,
              key: subjectContainerKey,
              decoration: BoxDecoration(
                color: adaptiveColor(context, CupertinoColors.systemGrey5.resolveFrom(context), CupertinoColors.systemGrey3.resolveFrom(context)),
                borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(SubjectHelper.toFrench(widget.homework.subject)),
            ),
          ),
        ],
      ),
    );
  }
}
