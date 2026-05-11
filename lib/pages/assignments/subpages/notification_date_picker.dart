import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/picker.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';

void showNotificationOptionsPicker() {}

class NotificationDatePicker extends StatefulWidget {
  final DateTime? notificationDate;
  final DateTime dueDate;
  final Map<int, String> notificationDayOptions;
  final ValueChanged<DateTime?> onNotificationDateChanged;

  const NotificationDatePicker({
    super.key,
    required this.notificationDate,
    required this.dueDate,
    required this.notificationDayOptions,
    required this.onNotificationDateChanged,
  });

  @override
  State<NotificationDatePicker> createState() => _NotificationDatePickerState();
}

class _NotificationDatePickerState extends State<NotificationDatePicker> {
  final List<int> hours = List.generate(24, (i) => i);
  final List<int> minutes = [0, 15, 30, 45];

  late DateTime? chosenDateTime;

  late FixedExtentScrollController daysBeforePickerController;
  late FixedExtentScrollController hourPickerController;
  late FixedExtentScrollController minutesPickerController;

  bool isValid(DateTime? dateTime, {bool countTimeToo = true}) =>
      dateTime == null ? true : (countTimeToo ? dateTime : dateTime.copyWith(hour: 23, minute: 59)).isAfter(DateTime.now());

  int getDaysBefore() => chosenDateTime == null ? -1 : widget.dueDate.dateOnly().difference(chosenDateTime!.dateOnly()).inDays;

  @override
  void initState() {
    super.initState();

    chosenDateTime = widget.notificationDate;

    if (!isValid(chosenDateTime)) {
      final firstValidDaysBefore = widget.notificationDayOptions.keys.firstWhere(
        (daysBefore) => hours.any((hour) => minutes.any((minute) => isValid(chosenDateTime?.addDays(-daysBefore).copyWith(hour: hour, minute: minute)))),
        orElse: () => widget.notificationDayOptions.keys.last,
      );

      chosenDateTime = widget.dueDate.addDays(-firstValidDaysBefore);

      chosenDateTime = chosenDateTime?.copyWith(
        hour: hours.firstWhere(
          (hour) => minutes.any((minute) => isValid(chosenDateTime?.copyWith(hour: hour, minute: minute))),
          orElse: () => 0,
        ),
      );

      chosenDateTime = chosenDateTime?.copyWith(
        minute: minutes.firstWhere((minute) => isValid(chosenDateTime?.copyWith(minute: minute)), orElse: () => 0),
      );
    }

    int initialIndex = widget.notificationDayOptions.keys.toList().indexOf(getDaysBefore());
    if (initialIndex == -1) initialIndex = widget.notificationDayOptions.length - 1;

    daysBeforePickerController = FixedExtentScrollController(initialItem: initialIndex);
    hourPickerController = FixedExtentScrollController(initialItem: chosenDateTime?.hour ?? 0);
    minutesPickerController = FixedExtentScrollController(
      initialItem: !minutes.contains(chosenDateTime?.minute) ? 0 : minutes.indexOf(chosenDateTime?.minute ?? 0),
    );
  }

  @override
  void dispose() {
    daysBeforePickerController.dispose();
    hourPickerController.dispose();
    minutesPickerController.dispose();
    super.dispose();
  }

  void scrollToFirstAvailableDaysBefore() {
    DateTime? firstValidDate;
    int firstValidIndex = widget.notificationDayOptions.keys.indexed.firstWhere((item) {
      if (isValid(widget.dueDate.addDays(-item.$2), countTimeToo: false)) {
        firstValidDate = widget.dueDate.addDays(-item.$2);
        return true;
      }
      return false;
    }, orElse: () => (widget.notificationDayOptions.keys.length - 1, -1)).$1;

    daysBeforePickerController.animateToItem(firstValidIndex, duration: Duration(milliseconds: 200), curve: Curves.easeInOut);

    chosenDateTime = firstValidDate?.copyWith(hour: chosenDateTime?.hour, minute: chosenDateTime?.minute);
  }

  void scrollToFirstAvailableHour() {
    int firstValidHour = 0;
    int firstValidIndex = hours.indexWhere((hour) {
      if (isValid(chosenDateTime?.copyWith(hour: hour, minute: 44))) {
        firstValidHour = hour;
        return true;
      }
      return false;
    });

    hourPickerController.animateToItem(firstValidIndex, duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
    chosenDateTime = chosenDateTime?.copyWith(hour: firstValidHour);
  }

  void scrollToFirstAvailableMinutes() {
    int firstValidMinutes = 0;
    int firstValidIndex = minutes.indexWhere((minute) {
      if (isValid(chosenDateTime?.copyWith(minute: minute))) {
        firstValidMinutes = minute;
        return true;
      }
      return false;
    });

    minutesPickerController.animateToItem(firstValidIndex, duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
    // Fix: era `hour: firstValidMinutes`, deve essere `minute`
    chosenDateTime = chosenDateTime?.copyWith(minute: firstValidMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return RoundContainer(
      padding: .all(16).copyWith(top: 0),
      margin: .all(10),
      height: 250,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            TopBar.form(
              context,
              title: "Me rappeler",
              trailing: Button.icon(
                context,
                icon: HugeIcons.strokeRoundedTick02,
                onTap: () {
                  widget.onNotificationDateChanged(chosenDateTime);
                  Navigator.of(context).pop();
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: .symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    // "Days Before" Picker
                    Expanded(
                      flex: 2,
                      child: Picker(
                        controller: daysBeforePickerController,
                        onChanged: (index) {
                          final daysBefore = widget.notificationDayOptions.keys.toList()[index];

                          if (!isValid(widget.dueDate.addDays(-daysBefore), countTimeToo: false)) {
                            scrollToFirstAvailableDaysBefore();
                            return;
                          }

                          setState(() {
                            if (daysBefore == -1) {
                              chosenDateTime = null;
                            } else {
                              DateTime result = widget.dueDate.addDays(-daysBefore).dateOnly();

                              if (chosenDateTime == null) {
                                result = result.copyWith(hour: 17);
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => hourPickerController.animateToItem(17, duration: Duration(milliseconds: 200), curve: Curves.easeInOut),
                                );
                              } else {
                                result = result.withTheTimeOf(chosenDateTime!);
                              }

                              chosenDateTime = result;
                            }

                            if (!isValid(chosenDateTime)) {
                              scrollToFirstAvailableHour();
                              scrollToFirstAvailableMinutes();
                            }
                          });
                        },
                        children: widget.notificationDayOptions.values.mapIndexed((index, text) {
                          final daysBefore = widget.notificationDayOptions.keys.toList()[index];
                          return Center(
                            child: Text(
                              text,
                              style: TextStyle(
                                color: isValid(widget.dueDate.addDays(-daysBefore), countTimeToo: false) ? null : AppColors.inactive.adaptTo(context),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Hour Picker
                    if (chosenDateTime != null)
                      Expanded(
                        child: Picker(
                          controller: hourPickerController,
                          onChanged: (index) {
                            final resultDateTime = chosenDateTime?.copyWith(hour: hours[index]);

                            if (!isValid(resultDateTime)) {
                              scrollToFirstAvailableHour();
                              return;
                            }

                            setState(() => chosenDateTime = resultDateTime);
                          },
                          children: hours
                              .map(
                                (hour) => Center(
                                  child: Text(
                                    hour.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      color: isValid(chosenDateTime?.copyWith(hour: hour, minute: 44)) ? null : AppColors.inactive.adaptTo(context),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                    // Minutes Picker
                    if (chosenDateTime != null)
                      Expanded(
                        child: Picker(
                          controller: minutesPickerController,
                          onChanged: (index) {
                            final resultTime = chosenDateTime?.copyWith(minute: minutes[index]);

                            if (!isValid(resultTime)) {
                              scrollToFirstAvailableMinutes();
                              return;
                            }

                            setState(() {
                              chosenDateTime = resultTime;
                            });
                          },
                          children: minutes
                              .map(
                                (minute) => Center(
                                  child: Text(
                                    minute.toString().padLeft(2, '0'),
                                    style: TextStyle(color: isValid(chosenDateTime?.copyWith(minute: minute)) ? null : AppColors.inactive.adaptTo(context)),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
