import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:settings_ui/settings_ui.dart';

class ProfileOverlay extends StatefulWidget {
  final Account account;

  const ProfileOverlay(this.account, {super.key});

  @override
  State<StatefulWidget> createState() => _ProfileOverlayState();
}

class _ProfileOverlayState extends State<ProfileOverlay> {
  late final account = widget.account;
  late final profile = widget.account.profile ?? {};

  void showConfirmation(String frenchName) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: Text("Copié"),
            content: Text("$frenchName a été copié dans le presse-papiers."),
            actions: [
              CupertinoDialogAction(
                child: Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void copyPhoneNumber() async {
    await Clipboard.setData(ClipboardData(text: profile["PhoneNumber"]));
    showConfirmation("Le numéro");
  }

  void copyEmailAddress() async {
    await Clipboard.setData(ClipboardData(text: account.emailAddress));
    showConfirmation("L'adresse email");
  }

  void copyDiscordUsername() async {
    await Clipboard.setData(ClipboardData(text: profile["DiscordID"]));
    showConfirmation("Le nom d'utilisateur de Discord");
  }

  @override
  Widget build(context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: "Retour",
        middle: Text(account.username),
      ),
      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: Text("Profil"),
              tiles: [
                SettingsTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.username.replaceAll(".", " ").capitalize(),
                          ),
                          Text(
                            profile["Class"] ?? "-",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: ProfilePictureDisplay(account.username, radius: 40),
                  ),
                  description: Text(
                    "A rejoint le ${DateFormat('dd.MM.yyyy').format(account.creationDate!)}",
                  ),
                ),
              ],
            ),

            SettingsSection(
              title: Text("Bio"),
              tiles: [SettingsTile(title: Text(profile["Bio"] ?? "-"))],
            ),

            SettingsSection(
              title: Text("Autres contacts"),
              tiles: [
                SettingsTile(
                  title: Text("Numéro"),
                  leading: Icon(CupertinoIcons.phone),
                  value: Text(profile["PhoneNumber"] ?? "-"),
                  onPressed:
                      profile["PhoneNumber"] == null
                          ? null
                          : (context) => copyPhoneNumber(),
                ),
                SettingsTile(
                  title: Text("Email"),
                  leading: Icon(CupertinoIcons.mail),
                  value: Text(account.emailAddress),
                  onPressed: (context) => copyEmailAddress(),
                ),
                SettingsTile(
                  title: Text("Discord"),
                  leading: Icon(CupertinoIcons.game_controller),
                  value: Text(profile["DiscordUsername"] ?? "-"),
                  onPressed:
                      profile["DiscordUsername"] == null
                          ? null
                          : (context) => copyDiscordUsername(),
                  description: Text(
                    "Appuyez pour copier dans le presse-papiers.",
                  ),
                ),
              ],
            ),

            SettingsSection(
              tiles: [
                SettingsTile.navigation(
                  leading: Icon(CupertinoIcons.bubble_left),
                  title: Text("Envoyer un message"),
                  onPressed:
                      (context) => Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(
                          builder:
                              (context) => ChatOverlay(
                                recipientUsername: account.username,
                              ),
                        ),
                      ),
                ),

                SettingsTile.navigation(
                  leading: Icon(CupertinoIcons.phone),
                  title: Text("Appeler"),
                ),

                SettingsTile(
                  leading: Icon(
                    CupertinoIcons.trash,
                    color: CupertinoColors.destructiveRed,
                  ),
                  title: Text(
                    "Supprimer la conversation",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed:
                      (context) => showCupertinoDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return CupertinoAlertDialog(
                            title: Text("Supprimer la conversation"),
                            content: Text(
                              "Voulez-vous vraiment supprimer cette conversation ? Cette action est irréversible.",
                            ),
                            actions: [
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                onPressed: () async {
                                  Navigator.of(dialogContext).pop();

                                  if (Hive.isBoxOpen("Chats")) {
                                    await Hive.box<Chat>(
                                      "Chats",
                                    ).delete(account.username);
                                  }

                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).push(
                                      CupertinoDialogRoute(
                                        builder:
                                            (_) => CupertinoAlertDialog(
                                              title: Text("Supprimée"),
                                              content: Text(
                                                "La conversation avec ${account.username} a été supprimée du téléphone.",
                                              ),
                                              actions: [
                                                CupertinoDialogAction(
                                                  child: Text("OK"),
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                ),
                                              ],
                                            ),
                                        context: context,
                                      ),
                                    );
                                  }
                                },
                                child: Text("Supprimer"),
                              ),
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: Text("Annuler"),
                              ),
                            ],
                          );
                        },
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
