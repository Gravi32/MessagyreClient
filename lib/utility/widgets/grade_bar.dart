import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';

class GradeBar extends StatelessWidget {
  final Grade gradeData;
  final Function() onTap;

  const GradeBar({super.key, required this.gradeData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Row(
            children: [
              GradeDisplay(grade: gradeData.grade, weight: gradeData.weight),

              SizedBox(width: 12),

              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        CustomText(
                          gradeData.title,
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: adaptiveColor(CupertinoColors.black, CupertinoColors.white)),
                        ),
                        if (gradeData.details != null && gradeData.details!.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsetsGeometry.symmetric(vertical: 4),
                            child: Row(
                              spacing: 6,
                              children: [
                                Opacity(
                                  opacity: .5,
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedTextAlignLeft,
                                    size: 16,
                                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                                  ),
                                ),
                                CustomText(
                                  gradeData.details!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: CupertinoColors.separator.resolveFrom(context), fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          formatDate(gradeData.date).capitalize(),
                          maxLines: 2,
                          overflow: TextOverflow.fade,
                          softWrap: true,
                          style: TextStyle(color: CupertinoColors.separator.resolveFrom(context), fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Divider(indent: 60, color: CupertinoColors.separator.resolveFrom(context).withAlpha(30)),
      ],
    );
  }
}
