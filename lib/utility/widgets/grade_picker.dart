import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';

class GradePicker extends StatelessWidget {
  final double grade;
  final Function(double) onGradeChanged;

  const GradePicker({super.key, required this.grade, required this.onGradeChanged});

  @override
  Widget build(BuildContext context) {
    final grades = List.generate(11, (i) => i * .5 + 1);
    final controller = FixedExtentScrollController(initialItem: grades.indexOf(grade));

    return SizedBox(
      height: 52,
      child: Stack(
        alignment: .center,
        children: [
          IgnorePointer(
            child: Align(
              alignment: .center,
              child: Container(
                width: 56,
                height: 48,
                decoration: BoxDecoration(borderRadius: .circular(AppRadius.s), color: AppColors.tertiaryBackground.adaptTo(context)),
              ),
            ),
          ),
          RotatedBox(
            quarterTurns: -1,
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: 58,
              diameterRatio: 2,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                onGradeChanged(grades[index]);
                HapticFeedback.selectionClick();
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: grades.length,
                builder: (context, index) {
                  final thisGrade = grades[index];
                  final isWhole = thisGrade % 1 == 0;
                  final display = isWhole ? thisGrade.toInt().toString() : thisGrade.toStringAsFixed(1);
                  final isSelected = grade == thisGrade;

                  return GestureDetector(
                    onTap: () => controller.animateToItem(index, duration: Duration(milliseconds: 200), curve: Curves.easeOut),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Center(
                        child: Text(
                          display,
                          style: (isSelected ? AppStyles.secondaryHeader(context).copyWith(fontWeight: .w700) : AppStyles.primaryText(context)).copyWith(
                            color: isSelected ? null : AppColors.tertiaryText.adaptTo(context),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
