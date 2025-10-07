import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/utility/utility.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final bool allowFuture;
  final bool allowPast;
  final ValueChanged<DateTime> onDateSelected;

  const CustomDatePicker({super.key, required this.initialDate, required this.onDateSelected, this.allowFuture = true, this.allowPast = true});

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
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
    return Container(
      height: 450,
      decoration: BoxDecoration(color: CupertinoColors.systemBackground.resolveFrom(context), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        children: [
          Container(
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
                    final days = daysInMonth(date.year, date.month);
                    final firstWeekday = DateTime(date.year, date.month, 1).weekday;
                    final totalCells = days.length + (firstWeekday - 1);

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
                            children:
                                ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
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
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4),
                              itemCount: totalCells,
                              itemBuilder: (context, i) {
                                if (i < firstWeekday - 1) return SizedBox();

                                final dayNumber = i - (firstWeekday - 2);
                                final dayDate = DateTime(date.year, date.month, dayNumber);
                                final today = DateTime.now();
                                final isSelected = tempDate.day == dayNumber && tempDate.month == date.month && tempDate.year == date.year;
                                final isToday = today.day == dayNumber && today.month == date.month && today.year == date.year;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() => tempDate = dayDate);
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? CupertinoTheme.of(context).primaryColor
                                                  : CupertinoColors.secondarySystemBackground.resolveFrom(context),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(dayNumber.toString(), style: TextStyle(fontSize: 16, color: CupertinoColors.label.resolveFrom(context))),
                                      ),
                                      if(isToday) Positioned(top: 5, left: 5, child: HugeIcon(icon: HugeIcons.strokeRoundedCalendar04, size: 10, color: CupertinoColors.label.resolveFrom(context),)),
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
