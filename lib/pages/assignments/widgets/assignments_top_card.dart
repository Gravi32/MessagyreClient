import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/presets.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/progress_bar.dart';

/// The top of the assignments page: the week (swipe for the next one), each day with a dot per assignment, then the
/// countdown to the next holidays
class AssignmentsTopCard extends StatefulWidget {
  const AssignmentsTopCard({super.key});

  @override
  State<AssignmentsTopCard> createState() => _AssignmentsTopCardState();
}

class _AssignmentsTopCardState extends State<AssignmentsTopCard> {
  final database = DatabaseService();
  final weekController = PageController();
  int week = 0;

  late final today = DateTime.now().dateOnly();
  late final monday = today.weekday >= DateTime.saturday
      ? today.add(Duration(days: 8 - today.weekday))
      : today.subtract(Duration(days: today.weekday - DateTime.monday));

  // Null when the holidays calendar (presets.dart) has no date after today: the card is then hidden
  String? nextHolidayName;
  DateTime? nextHolidayDate;
  DateTime? lastHolidayDate;

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
  void dispose() {
    weekController.dispose();
    super.dispose();
  }

  Widget buildWeek(List<Assignment> allAssignments, DateTime weekStart) {
    return Row(
      children: [
        for (var index = 0; index < 7; index++)
          Expanded(
            child: () {
              final day = weekStart.add(Duration(days: index));
              final dayAssignments = allAssignments.where((assignment) => assignment.dueDate.isSameDayAs(day)).toList();
              final isToday = day.isSameDayAs(today);
              final isWeekend = day.weekday >= DateTime.saturday;
              final text = AppColors.text.adaptTo(context);

              return Opacity(
                opacity: isWeekend ? .45 : 1,
                child: Column(
                  spacing: AppSpacing.s - 2,
                  children: [
                    Text(
                      DateFormat("EEE", 'fr_CH').format(day).replaceAll('.', '').substring(0, 1).toUpperCase(),
                      style: AppStyles.caption(context).copyWith(fontWeight: .w600),
                    ),
                    // Today: on the icon's gradient
                    Container(
                      width: 36,
                      height: 36,
                      alignment: .center,
                      decoration: BoxDecoration(shape: .circle, gradient: isToday ? AppColors.accentGradient : null),
                      child: Text(
                        day.day.toString(),
                        style: AppStyles.strongText(context).copyWith(fontFamily: AppStyles.titleFontFamily, fontWeight: .w600, color: isToday ? AppColors.white : text),
                      ),
                    ),
                    // A dot per assignment (a star for a leave), in its subject's color
                    SizedBox(
                      height: 6,
                      child: Row(
                        mainAxisAlignment: .center,
                        spacing: 3,
                        children: [
                          for (final assignment in dayAssignments.take(min(dayAssignments.length, 3)))
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: .circle,
                                color: assignment.type == AssignmentType.leave ? AppColors.orange : (assignment.subject.value?.color ?? AppColors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }(),
          ),
      ],
    );
  }

  Widget buildWeekCard(List<Assignment> allAssignments) {
    return RoundContainer(
      watermark: true,
      padding: const .fromLTRB(AppSpacing.s, AppSpacing.l, AppSpacing.s, AppSpacing.m),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.m,
        children: [
          Padding(
            padding: const .symmetric(horizontal: AppSpacing.s),
            child: Row(
              children: [
                Expanded(child: Text(week == 0 ? AppStrings.thisWeek : AppStrings.nextWeek, style: AppStyles.strongText(context))),
                Text(DateFormat("MMMM", 'fr_CH').format(monday.add(Duration(days: week * 7))).capitalize(), style: AppStyles.subheadline(context)),
              ],
            ),
          ),
          SizedBox(
            height: 70,
            child: PageView(
              controller: weekController,
              onPageChanged: (page) => setState(() => week = page),
              children: [buildWeek(allAssignments, monday), buildWeek(allAssignments, monday.add(const Duration(days: 7)))],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHolidaysCard(String name, DateTime date) {
    // Before the first holidays of the calendar, the countdown starts with the school year
    final start = lastHolidayDate ?? DateTime(today.month >= 8 ? today.year : today.year - 1, 8, 18);
    final span = date.difference(start).inDays.clamp(1, 1000);
    final daysLeft = date.difference(today).inDays;

    return RoundContainer(
      padding: const .all(AppSpacing.l),
      child: Row(
        spacing: AppSpacing.m,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: .center,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: AppColors.isDark(context) ? .2 : .14),
              borderRadius: .circular(10),
            ),
            child: const HugeIcon(icon: HugeIcons.strokeRoundedSun03, size: 20, color: AppColors.orange),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: AppSpacing.s - 2,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name, maxLines: 1, overflow: .ellipsis, style: AppStyles.strongText(context)),
                    ),
                    Text(daysLeft == 1 ? "demain" : "dans $daysLeft jours", style: AppStyles.subheadline(context)),
                  ],
                ),
                ProgressBar(progress: (1 - daysLeft / span).clamp(0.0, 1.0), height: 5, color: AppColors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAssignments = database.assignments.getAll();
    final holidayName = nextHolidayName, holidayDate = nextHolidayDate;

    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.m,
      children: [buildWeekCard(allAssignments), if (holidayName != null && holidayDate != null) buildHolidaysCard(holidayName, holidayDate)],
    );
  }
}
