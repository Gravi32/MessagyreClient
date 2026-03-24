import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  State<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  int chatsSize = 0, assignmentSize = 0, gradesSize = 0;

  @override
  void initState() {
    super.initState();
    _loadBoxSizes();
  }

  Future<void> _loadBoxSizes() async {
    final chats = await getBoxSize<Chat>("Chats");
    final assignment = await getBoxSize<Assignment>("Assignment");
    final grades = await getBoxSize<Grade>("Grades");

    if (mounted) {
      setState(() {
        chatsSize = chats;
        assignmentSize = assignment;
        gradesSize = grades;
      });
    }
  }

  Future<int> getBoxSize<T>(String boxName) async {
    // try {
    //   final box = Hive.box<T>(boxName);
    //   if (box.path == null) return 0;
    //   final file = File(box.path!);
    //   return await file.length();
    // } catch (_) {
    //   return 0;
    // }

    return 0;
  }

  Future<void> deleteBox(String name) async {
    // try {
    //   Box<HiveObject>? box;
    //   bool isOpen = Hive.isBoxOpen(name);

    //   if (name == "Chats") {
    //     box = isOpen ? Hive.box<Chat>(name) : await Hive.openBox<Chat>(name);
    //   } else if (name == "Assignment") {
    //     box = isOpen ? Hive.box<Assignment>(name) : await Hive.openBox<Assignment>(name);
    //   } else if (name == "Grades") {
    //     box = isOpen ? Hive.box<Grade>(name) : await Hive.openBox<Grade>(name);
    //   }

    //   await box?.clear();
    // } catch (e, s) {
    //   debugPrintStack(stackTrace: s, label: e.toString());
    // }
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
                  for (var boxName in ["Chats", "Grades", "Assignment"]) {
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
        child: ListView(
          physics: const ClampingScrollPhysics(),
          children: [
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leading: CustomIcon(icon: HugeIcons.strokeRoundedMessageMultiple02, color: AppColors.red),
                  title: Text("Effacer les conversations", style: TextStyle(color: AppColors.red)),
                  trailing: Text(formatBytes(chatsSize)),
                  onTap:
                      () => confirmDeleteBox("Chats", "Effacer les conversations", "Toutes les conversations seront effacées, cette action est irréversible."),
                ),
                CupertinoListTile(
                  leading: CustomIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge04, color: AppColors.red),
                  title: Text("Effacer les notes", style: TextStyle(color: AppColors.red)),
                  trailing: Text(formatBytes(gradesSize)),
                  onTap: () => confirmDeleteBox("Grades", "Effacer les notes", "Toutes les notes seront effacées, cette action est irréversible."),
                ),
                CupertinoListTile(
                  leading: CustomIcon(icon: HugeIcons.strokeRoundedWork, color: AppColors.red),
                  title: Text("Effacer les devoirs", style: TextStyle(color: AppColors.red)),
                  trailing: Text(formatBytes(assignmentSize)),
                  onTap: () => confirmDeleteBox("Assignment", "Effacer les devoirs", "Tous les devoirs seront effacés, cette action est irréversible."),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leading: CustomIcon(icon: HugeIcons.strokeRoundedDelete04, color: AppColors.red),
                  title: Text("Tout effacer", style: TextStyle(color: AppColors.red)),
                  trailing: Text(formatBytes(chatsSize + assignmentSize + gradesSize)),
                  onTap: () => confirmDeleteAll(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
