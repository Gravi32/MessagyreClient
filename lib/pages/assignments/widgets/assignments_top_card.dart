import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/presets.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/paged_card.dart';

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

  Widget buildWeekPeekTab(List<Assignment> allAssignments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Text("Cette semaine en un coup d'oeil", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),

        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 2, mainAxisExtent: 65),
          itemCount: 7,
          itemBuilder: (context, index) {
            final thisDay = monday.add(Duration(days: index));
            final thisDaysAssignments = allAssignments.where((a) => a.dueDate.isSameDayAs(thisDay));
            final isSelected = thisDay.isSameDayAs(today);

            return Container(
              padding: EdgeInsets.all(4),
              decoration: isSelected ? BoxDecoration(color: AppColors.white.withAlpha(20), borderRadius: BorderRadius.circular(12)) : null,
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
                            ? Align(alignment: Alignment.bottomCenter, child: Icon(Icons.star_rounded, color: AppColors.orange, size: 7))
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

  Widget buildNextHolidaysTab() {
    final daysDistance = nextHolidayDate.difference(lastHolidayDate).inDays;
    final daysLeft = nextHolidayDate.difference(today).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        Text("Prochaines vacances", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: AppColors.tertiaryText.adaptTo(context))),
        Text(nextHolidayName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
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
        Container(
          height: 6,
          decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progress = 1 - daysLeft / daysDistance;
              return Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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

    return PagedCard(height: 101, pages: [buildWeekPeekTab(allAssignments), buildNextHolidaysTab()]);
  }
}
