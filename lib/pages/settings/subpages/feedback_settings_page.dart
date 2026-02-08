import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:settings_ui/settings_ui.dart';

class FeedbackSettingsPage extends StatefulWidget {
  const FeedbackSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _FeedbackSettingsPageState();
}

class _FeedbackSettingsPageState extends State<FeedbackSettingsPage> {
  final feedbackController = TextEditingController();

  void confirmDeleteChats() {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: Text("Envoyez un commentaire"),
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
        middle: Text("Envoyer un commentaire"),
      ),
      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: Text("Contenu du commentaire"),
              tiles: [
                SettingsTile(
                  title: CupertinoTextField(
                    controller: feedbackController,
                    decoration: BoxDecoration(),
                    padding: EdgeInsets.zero,
                    textAlignVertical: TextAlignVertical.top,
                    minLines: 1,
                    maxLines: 15,
                    placeholder: "J'ai remarqué que...",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
