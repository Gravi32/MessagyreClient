import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
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

  Future<void> deleteBox(String name) async {
    try {
      Box<HiveObject>? box;
      bool isOpen = Hive.isBoxOpen(name);

      if (name == "Chats") {
        box = isOpen ? Hive.box<Chat>(name) : await Hive.openBox<Chat>(name);
      } else if (name == "Homework") {
        box = isOpen ? Hive.box<Homework>(name) : await Hive.openBox<Homework>(name);
      } else if (name == "Grades") {
        box = isOpen ? Hive.box<Grade>(name) : await Hive.openBox<Grade>(name);
      }

      await box?.clear();
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    }
  }

  String formatBytes(int bytes) => "${(bytes / 1024).toStringAsFixed(1)} Ko";

  Future<void> confirmDeleteBox(String boxName, String title, String message) async {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: Text("Annuler")),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () async {
                  await deleteBox(boxName);

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
            content: Text("Toutes les notes, tous les devoirs et toutes les conversations seront supprimés de manière irréversible."),
            actions: [
              CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: Text("Annuler")),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () async {
                  for (var boxName in ["Chats", "Grades", "Homework"]) {
                    deleteBox(boxName);
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(previousPageTitle: "Réglages", middle: Text("Effacer les données")),
      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              tiles: [
                SettingsTile(
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedMessageMultiple02, color: CupertinoColors.destructiveRed),
                  title: Text("Effacer les conversations", style: TextStyle(color: CupertinoColors.destructiveRed)),
                  trailing: Text(formatBytes(chatsSize)),
                  onPressed:
                      (_) => confirmDeleteBox("Chats", "Effacer les conversations", "Toutes les conversations seront effacées, cette action est irréversible."),
                ),
                SettingsTile(
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge04, color: CupertinoColors.destructiveRed),
                  title: Text("Effacer les notes", style: TextStyle(color: CupertinoColors.destructiveRed)),
                  trailing: Text(formatBytes(gradesSize)),
                  onPressed: (_) => confirmDeleteBox("Grades", "Effacer les notes", "Toutes les notes seront effacées, cette action est irréversible."),
                ),
                SettingsTile(
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedWork, color: CupertinoColors.destructiveRed),
                  title: Text("Effacer les devoirs", style: TextStyle(color: CupertinoColors.destructiveRed)),
                  trailing: Text(formatBytes(homeworkSize)),
                  onPressed: (_) => confirmDeleteBox("Homework", "Effacer les devoirs", "Tous les devoirs seront effacés, cette action est irréversible."),
                ),
              ],
            ),
            SettingsSection(
              tiles: [
                SettingsTile(
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedDelete04, color: CupertinoColors.destructiveRed),
                  title: Text("Tout effacer", style: TextStyle(color: CupertinoColors.destructiveRed)),
                  trailing: Text(formatBytes(chatsSize + homeworkSize + gradesSize)),
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
