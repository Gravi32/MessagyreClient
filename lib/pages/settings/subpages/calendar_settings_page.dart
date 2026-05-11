import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
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
    return Page.scrollable(
      context,
      topBar: TopBar.tab(context, title: "Calendrier"),
      children: [
        CustomDatePicker(initialDate: DateTime.now(), onDateSelected: (_) {}, isPreviewMode: true),

        const SizedBox(height: 20),

        ListSection(
          children: [
            ListTile.simple(
              context,
              title: "Inclure les week-ends",
              icon: HugeIcons.strokeRoundedCalendarFavorite01,
              trailing: CupertinoSwitch(
                value: globals.persistent.getBool("includeWeekends") ?? false,
                onChanged: (newValue) {
                  globals.persistent.setBool("includeWeekends", newValue);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
