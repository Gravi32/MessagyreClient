import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/utility/utility.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final bool allowFuture;
  final bool allowPast;
  final ValueChanged<DateTime> onDateSelected;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    this.allowFuture = true,
    this.allowPast = true,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime tempDate;

  @override
  void initState() {
    super.initState();
    tempDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final schoolStart = DateTime(now.year, 8, 18);
    final schoolEnd =
        now.isBefore(schoolStart)
            ? DateTime(now.year, 6, 6)
            : DateTime(now.year + 1, 6, 6);

    final minDate = widget.allowPast ? schoolStart : now;
    final maxDate = widget.allowFuture ? schoolEnd : now;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Annuler"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  "Date",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
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
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: tempDate,
              minimumDate: minDate,
              maximumDate: maxDate,
              minimumYear: minDate.year,
              maximumYear: maxDate.year,
              onDateTimeChanged: (value) => tempDate = value,
            ),
          ),
        ],
      ),
    );
  }
}
