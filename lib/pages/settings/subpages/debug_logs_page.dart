import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

class DebugLogsPage extends StatefulWidget {
  const DebugLogsPage({super.key});

  @override
  State<DebugLogsPage> createState() => _DebugLogsPageState();
}

class _DebugLogsPageState extends State<DebugLogsPage> {
  final globals = GlobalsService();

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.tab(context, title: "Logs"),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ...globals.appLogs.map((log) {
                  final content = log.split(" ");

                  return Padding(
                    padding: .only(top: 8),
                    child: Row(
                      crossAxisAlignment: .start,
                      children: [
                        Expanded(child: Text(content.sublist(1).join(" "), style: AppStyles.secondaryText(context), softWrap: true)),
                        Text(content[0].replaceAll(RegExp(r'[\[\]]'), ''), textAlign: .end, style: AppStyles.tertiaryText(context)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Button(
            text: "Tout copier",
            transparent: true,
            color: AppColors.secondaryButton.adaptTo(context),
            onTap: () => copy(context, globals.appLogs.join("\n")),
          ),
          BottomSpacing(),
        ],
      ),
    );
  }
}
