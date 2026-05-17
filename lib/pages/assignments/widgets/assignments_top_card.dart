import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/presets.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
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
  late final monday = today.weekday >= DateTime.saturday
      ? today.add(Duration(days: 8 - today.weekday))
      : today.subtract(Duration(days: today.weekday - DateTime.monday));

  late final String nextHolidayName;
  late final DateTime nextHolidayDate;
  late DateTime lastHolidayDate;

  Widget buildWeekPeek(List<Assignment> allAssignments, {required DateTime weekStart, required String title}) {
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 10,
      children: [
        Text(title, style: AppStyles.secondaryHeader(context)),

        GridView.builder(
          padding: .zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 2, mainAxisExtent: 70),
          itemCount: 7,
          itemBuilder: (context, index) {
            final thisDay = weekStart.add(Duration(days: index));
            final thisDaysAssignments = allAssignments.where((a) => a.dueDate.isSameDayAs(thisDay));
            final isToday = thisDay.isSameDayAs(today);

            return Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .stretch,
              children: [
                Text(
                  DateFormat("EEE", 'fr_CH').format(thisDay).replaceAll('.', ''),
                  textAlign: .center,
                  overflow: .fade,
                  maxLines: 1,
                  style: isToday ? TextStyle(color: AppColors.accent, fontWeight: .w600) : TextStyle(color: AppColors.secondaryText.adaptTo(context)),
                ),
                Expanded(
                  child: RoundContainer(
                    padding: .all(2),
                    opacity: (thisDay.weekday + 1) % 7 < 2 ? .4 : 1,
                    child: Column(
                      mainAxisAlignment: .center,
                      crossAxisAlignment: .stretch,
                      children: [
                        Spacer(),
                        Text(
                          thisDay.day.toString(),
                          textAlign: .center,
                          overflow: .fade,
                          maxLines: 1,
                          style: AppStyles.header(context).copyWith(fontWeight: isToday ? .w700 : .w500),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            spacing: 2,
                            mainAxisAlignment: .center,
                            crossAxisAlignment: .center,
                            children: List.generate(min(thisDaysAssignments.length, 3), (index) {
                              final thisDaysAssignment = thisDaysAssignments.elementAtOrNull(index);
                              if (thisDaysAssignment == null) return SizedBox.shrink();

                              final thisDaysAssignmentSubject = thisDaysAssignment.subject.value;

                              return thisDaysAssignment.type == AssignmentType.leave
                                  ? Icon(Icons.star_rounded, color: AppColors.orange, size: 7)
                                  : Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(color: thisDaysAssignmentSubject?.color, shape: .circle),
                                    );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
      crossAxisAlignment: .stretch,
      spacing: 6,
      children: [
        Text("Prochaines vacances", style: AppStyles.secondaryHeader(context)),

        Spacer(),

        Row(
          crossAxisAlignment: .baseline,
          textBaseline: .alphabetic,
          spacing: 6,
          children: [
            Expanded(
              child: TextGradiate(
                text: Text(nextHolidayName, style: AppStyles.header(context), maxLines: 1, overflow: .ellipsis),
                colors: [AppColors.orange.withBrightness(.1), AppColors.yellow],
                begin: .bottomLeft,
                end: .topRight,
              ),
            ),
            Text(daysLeft.toString(), style: AppStyles.header(context)),
            Text("jours restants", style: AppStyles.primaryText(context)),
          ],
        ),

        // Progress bar
        ProgressBar(
          progress: 1 - daysLeft / daysDistance,
          height: 6,
          gradient: LinearGradient(colors: [AppColors.orange, AppColors.yellow]),
        ),

        Spacer(),
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

    return PagedCard(
      height: 110,
      pages: [
        buildWeekPeek(allAssignments, weekStart: monday, title: "Cette semaine"),
        buildWeekPeek(allAssignments, weekStart: monday.add(Duration(days: 7)), title: "La semaine d'après"),
        buildNextHolidaysTab(),
      ],
    );
  }
}
