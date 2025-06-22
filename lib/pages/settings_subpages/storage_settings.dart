import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:settings_ui/settings_ui.dart';

class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {

  void confirmDeleteChats() {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: Text("Effacer les conversations"),
            content: Text(
              "Toutes les conversations seront effacées, cette action est irréversible.",
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text("Annuler"),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () async {
                  try {
                    if (Hive.isBoxOpen("Chats")) {
                      await Hive.box<Chat>("Chats").clear();
                    } else if (await Hive.boxExists("Chats")) {
                      var box = await Hive.openBox<Chat>("Chats");
                      await box.clear();
                    }
                  } catch (e, s) {
                    debugPrintStack(stackTrace: s, label: e.toString());
                  }

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text("Effacer"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: "Réglages",
        middle: Text("Effacer les données"),
      ),
      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              tiles: [
                SettingsTile(
                  title: Text(
                    "Effacer les conversations",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed: (context) {
                    confirmDeleteChats();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
