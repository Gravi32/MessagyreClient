import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/presets.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/paged_card.dart';
import 'package:messagyre_client/utility/widgets/progress_bar.dart';
import 'package:text_gradiate/text_gradiate.dart';

class AssignmentsTopCard extends StatefulWidget {
  const AssignmentsTopCard({super.key});

  @override
  State<AssignmentsTopCard> createState() => _AssignmentsTopCardState();
}

class _AssignmentsTopCardState extends State<AssignmentsTopCard> {
  final database = DatabaseService();

  late final today = DateTime.now().dateOnly();
  late final monday =
      today.weekday >= DateTime.saturday ? today.add(Duration(days: 8 - today.weekday)) : today.subtract(Duration(days: today.weekday - DateTime.monday));

  late final String nextHolidayName;
  late final DateTime nextHolidayDate;
  late DateTime lastHolidayDate;

  Widget buildWeekPeek(List<Assignment> allAssignments, {required DateTime weekStart, required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20), overflow: TextOverflow.ellipsis, maxLines: 1),

        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 2, mainAxisExtent: 70),
          itemCount: 7,
          itemBuilder: (context, index) {
            final thisDay = weekStart.add(Duration(days: index));
            final thisDaysAssignments = allAssignments.where((a) => a.dueDate.isSameDayAs(thisDay));
            final isSelected = thisDay.isSameDayAs(today);

            return Container(
              padding: EdgeInsets.all(4),
              margin: EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(color: AppColors.text.adaptTo(context).withAlpha(isSelected ? 20 : 5), borderRadius: BorderRadius.circular(12)),
              child: Opacity(
                opacity: (thisDay.weekday + 1) % 7 < 2 ? .4 : 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat("EEE", 'fr_CH').format(thisDay).replaceAll('.', ''),
                      style:
                          isSelected
                              ? TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)
                              : TextStyle(color: AppColors.secondaryText.adaptTo(context)),
                    ),
                    Text(thisDay.day.toString(), style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 20)),
                    SizedBox(height: 6),
                    Row(
                      spacing: 2,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(min(thisDaysAssignments.length, 3), (index) {
                        final thisDaysAssignment = thisDaysAssignments.elementAtOrNull(index);
                        if (thisDaysAssignment == null) return SizedBox.shrink();

                        final thisDaysAssignmentSubject = thisDaysAssignment.subject.value;

                        return thisDaysAssignment.type == AssignmentType.leave
                            ? Icon(Icons.star_rounded, color: AppColors.orange, size: 7)
                            : Container(width: 4, height: 4, decoration: BoxDecoration(color: thisDaysAssignmentSubject?.color, shape: BoxShape.circle));
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildWeekPeekTab(List<Assignment> allAssignments) {
    return buildWeekPeek(allAssignments, weekStart: monday, title: "Pour cette semaine :");
  }

  Widget buildNextWeekPeekTab(List<Assignment> allAssignments) {
    return buildWeekPeek(allAssignments, weekStart: monday.add(Duration(days: 7)), title: "Pour la semaine prochaine :");
  }

  Widget buildNextHolidaysTab() {
    final daysDistance = nextHolidayDate.difference(lastHolidayDate).inDays;
    final daysLeft = nextHolidayDate.difference(today).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        Text("Prochaines vacances", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: AppColors.tertiaryText.adaptTo(context))),
        TextGradiate(
          text: Text(nextHolidayName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
          colors: [AppColors.orange.withBrightness(.1), AppColors.yellow],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: 6,
          children: [
            Text(daysLeft.toString(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 30)),
            Text("jours restants", style: TextStyle(color: AppColors.tertiaryText.adaptTo(context))),
          ],
        ),

        // Progress bar
        ProgressBar(progress: 1 - daysLeft / daysDistance, height: 6, gradient: LinearGradient(colors: [AppColors.orange, AppColors.yellow])),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    for (var entry in vaudSchoolHolidays.entries) {
      if (entry.value.isAfter(today)) {
        nextHolidayName = entry.key;
        nextHolidayDate = entry.value;
        break;
      }
      lastHolidayDate = entry.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAssignments = database.assignments.getAll();

    return PagedCard(height: 110, pages: [buildWeekPeekTab(allAssignments), buildNextWeekPeekTab(allAssignments), buildNextHolidaysTab()]);
  }
}
