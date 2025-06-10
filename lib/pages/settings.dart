import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/extensions.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final data = Data();

  late bool isDarkMode;

  Widget profilePage() {
    var profile = data.account!.profile!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: "Réglages",
        middle: Text("Profil publique"),
      ),
      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              tiles: [
                SettingsTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        child: Text(data.account!.username[0].toUpperCase()),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data.account!.username.split('.')[0].capitalize(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(profile["Class"] ?? ""),
                        ],
                      ),
                      Text(
                        data.account!.username,
                        style: TextStyle(
                          color: Theme.of(context).dividerColor,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(profile["Bio"] ?? "Pas de biographie"),
                      SizedBox(height: 15),
                    ],
                  ),
                ),
                SettingsTile.navigation(
                  leading: Icon(CupertinoIcons.person_alt_circle_fill),
                  title: Text("Photo de profil"),
                ),
                SettingsTile.navigation(
                  leading: Icon(CupertinoIcons.bookmark),
                  title: Text("Classe"),
                  value: SizedBox(
                    width: 80,
                    child: Text(
                      profile["Class"] ?? "Ajouter",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                SettingsTile.navigation(
                  leading: Icon(CupertinoIcons.text_aligncenter),
                  title: Text("Biographie"),
                  value: SizedBox(
                    width: 80,
                    child: Text(
                      profile["Bio"] ?? "Ajouter",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

                    debugPrint("Donee");
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

  @override
  void initState() {
    isDarkMode = data.appBrightness == Brightness.dark;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
            if (data.account != null)
              SettingsSection(
                title: Text("Votre compte"),
                tiles: <SettingsTile>[
                  SettingsTile.navigation(
                    leading: CircleAvatar(
                      child: Text(data.account!.username[0].toUpperCase()),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          data.account!.username.split('.')[0].capitalize(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          data.account!.username,
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
                            builder: (context) => profilePage(),
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
                    debugPrint("$value");
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
          ],
        ),
      ),
    );
  }
}
