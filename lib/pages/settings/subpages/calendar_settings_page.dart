import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';

class CalendarSettingsPage extends StatefulWidget {
  const CalendarSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<CalendarSettingsPage> {
  final globals = GlobalsService();

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
                  backgroundColor: CupertinoColors.transparent,
                  margin: EdgeInsets.zero,
                  children: [
                    CupertinoListTile(
                      backgroundColor: cupertinoListTileColor,
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedCalendarFavorite01, color: CupertinoColors.label.resolveFrom(context)),
                      title: Text("Inclure les week-ends"),
                      trailing: CupertinoSwitch(
                        value: globals.settings.includeWeekends,
                        onChanged: (newValue) {
                          setState(() {
                            globals.settings.includeWeekends = newValue;
                          });
                          globals.settings.save();
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
