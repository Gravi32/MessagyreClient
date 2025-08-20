import 'dart:io';
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
  int chatsSize = 0, homeworkSize = 0, gradesSize = 0;

  @override
  void initState() {
    super.initState();
    _loadBoxSizes();
  }

  Future<void> _loadBoxSizes() async {
    final chats = await getBoxSize<Chat>("Chats");
    final homework = await getBoxSize<Homework>("Homework");
    final grades = await getBoxSize<Grade>("Grades");

    if (mounted) {
      setState(() {
        chatsSize = chats;
        homeworkSize = homework;
        gradesSize = grades;
      });
    }
  }

  Future<int> getBoxSize<T>(String boxName) async {
    try {
      final box = Hive.box<T>(boxName);
      if (box.path == null) return 0;
      final file = File(box.path!);
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  String formatBytes(int bytes) => "${(bytes / 1024).toStringAsFixed(1)} Ko";

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

                  await _loadBoxSizes();
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
                  for (var boxName in ["Chats", "Grades", "Homework"]) {
                    try {
                      if (Hive.isBoxOpen(boxName)) {
                        await Hive.box(boxName).clear();
                      } else if (await Hive.boxExists(boxName)) {
                        final box = await Hive.openBox(boxName);
                        await box.clear();
                      }
                    } catch (e, s) {
                      debugPrintStack(stackTrace: s, label: e.toString());
                    }
                  }
                  await _loadBoxSizes(); // aggiorna dimensioni
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
                  leading: Icon(
                    CupertinoIcons.chat_bubble_2,
                    color: CupertinoColors.destructiveRed,
                  ),
                  title: Text(
                    "Effacer les conversations (${formatBytes(chatsSize)})",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed:
                      (_) => confirmDeleteBox(
                        "Chats",
                        "Effacer les conversations",
                        "Toutes les conversations seront effacées, cette action est irréversible.",
                      ),
                ),
                SettingsTile(
                  leading: Icon(
                    CupertinoIcons.table,
                    color: CupertinoColors.destructiveRed,
                  ),
                  title: Text(
                    "Effacer les notes (${formatBytes(gradesSize)})",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed:
                      (_) => confirmDeleteBox(
                        "Grades",
                        "Effacer les notes",
                        "Toutes les notes seront effacées, cette action est irréversible.",
                      ),
                ),
                SettingsTile(
                  leading: Icon(
                    CupertinoIcons.checkmark_square,
                    color: CupertinoColors.destructiveRed,
                  ),
                  title: Text(
                    "Effacer les devoirs (${formatBytes(homeworkSize)})",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed:
                      (_) => confirmDeleteBox(
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
                  leading: Icon(
                    CupertinoIcons.trash,
                    color: CupertinoColors.destructiveRed,
                  ),
                  title: Text(
                    "Tout effacer (${formatBytes(chatsSize + homeworkSize + gradesSize)})",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed: (_) => confirmDeleteAll(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
