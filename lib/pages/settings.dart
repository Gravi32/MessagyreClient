import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
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

  Widget profilePage() {
    var profile = data.account!.profile!;

    void pickImage(ImageSource source) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return;

      await router.uploadProfilePicture(pickedFile.path);

    }

    void changeProfilePicture() {
      showCupertinoSheet(
        context: context,
        pageBuilder:
            (context) => CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text("Photo de profil"),
                previousPageTitle: "Retour",
              ),
              child: SafeArea(
                child: SettingsList(
                  platform: DevicePlatform.iOS,
                  sections: [
                    SettingsSection(
                      title: Text("Photo actuelle"),
                      tiles: [
                        SettingsTile(
                          title: ProfilePictureDisplay(
                            data.account!.username,
                            radius: 80,
                          ),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: Text("Changer de photo"),
                      tiles: [
                        SettingsTile(
                          title: Text("Prendre une photo"),
                          leading: Icon(CupertinoIcons.camera),
                          onPressed: (_) => pickImage(ImageSource.camera),
                        ),
                        SettingsTile(
                          title: Text("Choisir une photo de la galérie"),
                          leading: Icon(CupertinoIcons.photo_on_rectangle),
                          onPressed: (_) => pickImage(ImageSource.gallery),
                        ),
                        SettingsTile(
                          title: Text(
                            "Supprimer la photo",
                            style: TextStyle(
                              color: CupertinoColors.destructiveRed,
                            ),
                          ),
                          leading: Icon(
                            CupertinoIcons.trash,
                            color: CupertinoColors.destructiveRed,
                          ),
                          onPressed: (_) => pickImage(ImageSource.camera),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      );
    }

    void changeClass() {
      int selectedClassIndex = 0;

      //var classList = ["-", "2M01", "2M02"];

      showCupertinoModalPopup(
        context: context,
        builder:
            (BuildContext context) => Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  // This sets the initial item.
                  scrollController: FixedExtentScrollController(
                    initialItem: selectedClassIndex,
                  ),
                  // This is called when selected item is changed.
                  onSelectedItemChanged: (int selectedItem) {
                    setState(() {
                      selectedClassIndex = selectedItem;
                    });
                  },
                  children: List<Widget>.generate(10, (int index) {
                    return Center(child: Text("a"));
                  }),
                ),
              ),
            ),
      );
    }

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
                      ProfilePictureDisplay(
                        data
                            .account!
                            .username, // TODO: Handle account being null
                        radius: 60,
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
                  onPressed: (context) => changeProfilePicture(),
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
                  onPressed: (context) => changeClass(),
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
                    leading: ProfilePictureDisplay(data.account!.username),
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
                            builder: (context) => ProfileOverlay(data.account!),
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
