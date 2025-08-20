import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:settings_ui/settings_ui.dart';

class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  State<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  Future<void> confirmDeleteBox(
    String boxName,
    String title,
    String message,
  ) async {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text("Annuler"),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () async {
                      try {
                        if (boxName == "Chats") {
                          final box =
                              Hive.isBoxOpen("Chats")
                                  ? Hive.box<Chat>("Chats")
                                  : await Hive.openBox<Chat>("Chats");
                          await box.clear();
                        } else if (boxName == "Homework") {
                          final box =
                              Hive.isBoxOpen("Homework")
                                  ? Hive.box<Homework>("Homework")
                                  : await Hive.openBox<Homework>("Homework");
                          await box.clear();
                        } else if (boxName == "Grades") {
                          final box =
                              Hive.isBoxOpen("Grades")
                                  ? Hive.box<Grade>("Grades")
                                  : await Hive.openBox<Grade>("Grades");
                          await box.clear();
                        }
                      } catch (e, s) {
                        debugPrintStack(stackTrace: s, label: e.toString());
                      }
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    },
                    child: Text("Effacer"),
                  ),
                ],
              ),
    );
  }

  Future<void> confirmDeleteAll() async {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
                title: Text("Effacer toutes les données"),
                content: Text(
                  "Toutes les notes, tous les devoirs et toutes les conversations seront supprimés de manière irréversible.",
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
                        for (var boxName in ["Chats", "Grades", "Homework"]) {
                          if (boxName == "Chats") {
                            final box = Hive.isBoxOpen("Chats")
                                ? Hive.box<Chat>("Chats")
                                : await Hive.openBox<Chat>("Chats");
                            await box.clear();
                          } else if (boxName == "Grades") {
                            final box = Hive.isBoxOpen("Grades")
                                ? Hive.box<Grade>("Grades")
                                : await Hive.openBox<Grade>("Grades");
                            await box.clear();
                          } else if (boxName == "Homework") {
                            final box = Hive.isBoxOpen("Homework")
                                ? Hive.box<Homework>("Homework")
                                : await Hive.openBox<Homework>("Homework");
                            await box.clear();
                          }
                        }
                      } catch (e, s) {
                        debugPrintStack(stackTrace: s, label: e.toString());
                      }
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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
                  leading: Icon(CupertinoIcons.chat_bubble_2, color: CupertinoColors.destructiveRed),
                  title: Text(
                    "Effacer les conversations",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed:
                      (context) => confirmDeleteBox(
                        "Chats",
                        "Effacer les conversations",
                        "Toutes les conversations seront effacées, cette action est irréversible.",
                      ),
                ),
                SettingsTile(
                  leading: Icon(CupertinoIcons.table, color: CupertinoColors.destructiveRed),
                  title: Text(
                    "Effacer les notes",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed:
                      (context) => confirmDeleteBox(
                        "Grades",
                        "Effacer les notes",
                        "Toutes les notes seront effacées, cette action est irréversible.",
                      ),
                ),
                SettingsTile(
                  leading: Icon(CupertinoIcons.checkmark_square, color: CupertinoColors.destructiveRed),
                  title: Text(
                    "Effacer les devoirs",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed:
                      (context) => confirmDeleteBox(
                        "Homework",
                        "Effacer les devoirs",
                        "Tous les devoirs seront effacés, cette action est irréversible.",
                      ),
                ),
              ],
            ),
            SettingsSection(
              tiles: [
                SettingsTile(
                  leading: Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                  title: Text(
                    "Tout effacer",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed: (context) => confirmDeleteAll(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
