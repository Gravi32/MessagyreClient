import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/settings/subpages/calendar_settings_page.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/segmented_control.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';

class PreferencesSettingsPage extends StatelessWidget {
  PreferencesSettingsPage({super.key});

  final globals = GlobalsService();

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.tab(context, title: "Préférences"),
      child: ListView(
        children: [
          ListSection(
            children: [
              ListTile(
                buildChevron: false,
                padding: .all(14),
                child: Column(
                  spacing: 12,
                  crossAxisAlignment: .stretch,
                  children: [
                    Padding(
                      padding: .symmetric(horizontal: 10),
                      child: Row(
                        spacing: 12,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedPhoneDeveloperMode, color: AppColors.accent),
                          Text("Page initiale", style: AppStyles.primaryText(context)),
                        ],
                      ),
                    ),
                    SegmentedControl(
                      defaultIndex: globals.persistent.getInt("DefaultPage") ?? 2,
                      options: App.pages.asMap().map((index, page) => .new(page.name, index)),
                      onTap: (chosenIndex) {
                        globals.persistent.setInt("DefaultPage", chosenIndex);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          ListSection(
            margin: .only(top: 16),
            children: [
              ListTile.simple(
                context,
                title: "Calendrier",
                icon: HugeIcons.strokeRoundedCalendar04,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => CalendarSettingsPage())),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
