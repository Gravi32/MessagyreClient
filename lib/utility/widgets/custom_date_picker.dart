import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/singletons/data.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final bool allowFuture;
  final bool allowPast;
  final ValueChanged<DateTime> onDateSelected;
  final bool isPreviewMode;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    this.allowFuture = true,
    this.allowPast = true,
    this.isPreviewMode = false
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  final data = Data();

  late DateTime tempDate;
  late PageController monthController;
  late DateTime minDate;
  late DateTime maxDate;

  @override
  void initState() {
    super.initState();
    tempDate = widget.initialDate;

    final now = DateTime.now();
    final schoolStart = DateTime(now.year, 8, 18);
    final schoolEnd = now.isBefore(schoolStart) ? DateTime(now.year, 6, 6) : DateTime(now.year + 1, 6, 6);

    minDate = widget.allowPast ? schoolStart : now;
    maxDate = widget.allowFuture ? schoolEnd : now;

    final monthDiff = (widget.initialDate.year - minDate.year) * 12 + (widget.initialDate.month - minDate.month);

    monthController = PageController(initialPage: monthDiff.clamp(0, 11));
  }

  List<DateTime> daysInMonth(int year, int month) {
    int daysCount = DateUtils.getDaysInMonth(year, month);
    return List.generate(daysCount, (i) => DateTime(year, month, i + 1));
  }

  @override
  Widget build(BuildContext context) {
    final includeWeekends = data.settings.includeWeekends;
    final daysOfTheWeek = includeWeekends
        ? ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
        : ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'];

    return Container(
      height: 400,
      decoration: BoxDecoration(color: CupertinoColors.systemBackground.resolveFrom(context), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        children: [
          if (!widget.isPreviewMode) Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Annuler"), onPressed: () => Navigator.of(context).pop()),
                Text("Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                CupertinoButton(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Terminé"),
                  onPressed: () {
                    widget.onDateSelected(tempDate);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: PageView.builder(
                  controller: monthController,
                  itemCount: 12,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  physics: PageScrollPhysics(),
                  itemBuilder: (context, index) {
                    final date = DateTime(minDate.year, minDate.month + index, 1);
                    final allDays = daysInMonth(date.year, date.month);

                    final visibleDays = includeWeekends ? allDays : allDays.where((d) => d.weekday >= DateTime.monday && d.weekday <= DateTime.friday).toList();

                    int offset;
                    if (visibleDays.isEmpty) {
                      offset = 0;
                    } else {
                      if (includeWeekends) {
                        offset = DateTime(date.year, date.month, 1).weekday - 1;
                      } else {
                        offset = visibleDays.first.weekday - 1; // 0..4
                      }
                    }

                    final totalCells = offset + visibleDays.length;
                    final crossAxisCount = includeWeekends ? 7 : 5;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            DateFormat("MMMM", 'fr_CH').format(date).capitalize(),
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: CupertinoColors.label.resolveFrom(context)),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: daysOfTheWeek
                                .map(
                                  (d) => Expanded(
                                    child: Center(
                                      child: Text(
                                        d,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          SizedBox(height: 6),
                          Expanded(
                            child: GridView.builder(
                              padding: EdgeInsets.zero,
                              physics: ClampingScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              itemCount: totalCells,
                              itemBuilder: (context, i) {
                                if (i < offset) return SizedBox();

                                final dayIndex = i - offset;
                                if (dayIndex >= visibleDays.length) return SizedBox();

                                final dayDate = visibleDays[dayIndex];
                                final dayNumber = dayDate.day;

                                final today = DateTime.now();
                                final isSelected = tempDate.year == dayDate.year && tempDate.month == dayDate.month && tempDate.day == dayDate.day;
                                final isToday = today.year == dayDate.year && today.month == dayDate.month && today.day == dayDate.day;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() => tempDate = dayDate);
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected ? CupertinoTheme.of(context).primaryColor : CupertinoColors.secondarySystemBackground.resolveFrom(context),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(dayNumber.toString(), style: TextStyle(fontSize: 16, color: CupertinoColors.label.resolveFrom(context))),
                                      ),
                                      if (isToday)
                                        Positioned(
                                          top: 5,
                                          left: 5,
                                          child: HugeIcon(icon: HugeIcons.strokeRoundedCalendar04, size: 10, color: CupertinoColors.label.resolveFrom(context)),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
