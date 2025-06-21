import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/pages/overlays/profile.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final data = Data();
  final router = ConnectionController();

  late bool isDarkMode;

  Account? account;

  void getAccount() {
    if (data.username == null) return;

    router
        .getAccount(data.username!)
        .then(
          (receivedAccount) => setState(() {
            account = receivedAccount;
          }),
        );
  }

  Widget storagePage() {
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

  Widget debugPage() {
    void confirm(Function() onConfirmed) {
      showCupertinoDialog(
        context: context,
        builder:
            (dialogContext) => CupertinoAlertDialog(
              title: Text("Confirmer l'action"),
              content: Text(
                "Veuillez-vous vraiment procéder ? Cette action est irréversible.",
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text("Annuler"),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    onConfirmed();
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text("Confirmer"),
                ),
              ],
            ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: "Réglages",
        middle: Text("Débogage"),
      ),
      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: Text("Token d'accès"),
              tiles: [
                SettingsTile(title: Text(data.token ?? "-")),
                SettingsTile(
                  title: Text(
                    "Supprimer",
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onPressed:
                      (context) => confirm(() {
                        setState(() => data.token = null);
                        FlutterSecureStorage().delete(key: "AccessToken");
                      }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    isDarkMode = data.appBrightness == Brightness.dark;

    super.initState();

    getAccount();
  }

  @override
  Widget build(BuildContext context) {
    if (account == null) getAccount();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CupertinoSliverNavigationBar(
              largeTitle: Text("Réglages"),
              stretch: true,
            ),
          ];
        },
        body: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: Text("Votre compte"),
              tiles: <SettingsTile>[
                account == null
                    ? SettingsTile(
                      title: SizedBox(
                        height: 39,
                        child: CupertinoActivityIndicator(),
                      ),
                    )
                    : SettingsTile.navigation(
                      leading: ProfilePictureDisplay(
                        accountUsername: data.username!,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            data.username!.split('.')[0].capitalize(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            data.username!,
                            style: TextStyle(
                              color: Theme.of(context).dividerColor,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      onPressed:
                          (context) => Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => ProfileOverlay(account!),
                            ),
                          ),
                    ),
              ],
            ),

            SettingsSection(
              title: Text("Apparence"),
              tiles: [
                SettingsTile.switchTile(
                  onToggle: (value) {
                    setState(() {
                      isDarkMode = value;
                      data.appBrightness =
                          value ? Brightness.dark : Brightness.light;
                    });
                  },
                  initialValue: isDarkMode,
                  leading: Icon(CupertinoIcons.moon),
                  title: Text('Mode sombre'),
                ),
              ],
            ),

            SettingsSection(
              title: Text("Stockage"),
              tiles: [
                SettingsTile.navigation(
                  onPressed:
                      (context) => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (context) => storagePage()),
                      ),
                  leading: Icon(CupertinoIcons.delete),
                  title: Text("Effacer les données"),
                ),
              ],
            ),

            SettingsSection(
              title: Text("Autres"),
              tiles: [
                SettingsTile.navigation(
                  onPressed:
                      (context) => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (context) => debugPage()),
                      ),
                  leading: Icon(CupertinoIcons.ant),
                  title: Text("Débogage"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
