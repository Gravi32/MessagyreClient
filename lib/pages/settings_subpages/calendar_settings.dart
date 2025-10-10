import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';

class CalendarSettingsPage extends StatefulWidget {
  const CalendarSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<CalendarSettingsPage> {
  final data = Data();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(previousPageTitle: "Réglages", middle: Text("Calendrier")),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(10),
          children: [
            Column(
              children: [
                CupertinoListSection.insetGrouped(
                  margin: EdgeInsets.zero,
                  children: [
                    CupertinoListTile(
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedCalendarFavorite01, color: CupertinoColors.label.resolveFrom(context)),
                      title: Text("Inclure les week-ends"),
                      trailing: CupertinoSwitch(
                        value: data.settings.includeWeekends,
                        onChanged: (newValue) {
                          setState(() {
                            data.settings.includeWeekends = newValue;
                          });
                          data.settings.save();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                CustomDatePicker(initialDate: DateTime.now(), onDateSelected: (_) {}, isPreviewMode: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
