import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
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
  final data = Data();
  final router = ConnectionController();

  late final account = widget.account;
  late final profile = widget.account.profile ?? {};

  late final editMode = account.username == data.username;

  bool changesMade = false;
  bool isUploading = false;
  String? chosenPicturePath;

  void copy(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: Text("Copié"),
            content: Text("Copié dans le presse-papiers."),
            actions: [
              CupertinoDialogAction(
                child: Text("OK"),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
    );
  }

  void changeProfilePicture() {
    void pickImage(ImageSource source) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return;

      setState(() {
        changesMade = true;
        chosenPicturePath = pickedFile.path;
      });
    }

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text("Changer de photo de profil"),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  pickImage(ImageSource.camera);
                },
                child: Text("Prendre une photo"),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  pickImage(ImageSource.gallery);
                },
                child: Text("Choisir une photo de la galérie"),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    chosenPicturePath = null;
                    changesMade = true;
                    //TODO: Remove pfp
                  });
                },
                child: Text("Supprimer la photo"),
              ),
            ],
          ),
    );
  }

  void changeBio() {
    final bioController = TextEditingController(text: profile["Bio"]);
    String originalBio = profile["Bio"] ?? "";

    showCupertinoSheet(
      context: context,
      pageBuilder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text("Votre Bio"),
                leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text("Annuler"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed:
                      (bioController.text != originalBio)
                          ? () {
                            changesMade = true;
                            profile["Bio"] = bioController.text;
                            Navigator.of(context).pop();
                          }
                          : null,
                  child: Text("Terminé"),
                ),
              ),
              child: SafeArea(
                child: SettingsList(
                  platform: DevicePlatform.iOS,
                  sections: [
                    SettingsSection(
                      tiles: [
                        SettingsTile(
                          title: CupertinoTextField(
                            controller: bioController,
                            decoration: BoxDecoration(),
                            padding: EdgeInsets.zero,
                            placeholder: "Bio",
                            minLines: 1,
                            maxLines: 3,
                            maxLength: 100,
                            onChanged: (_) => setSheetState(() {}),
                          ),
                          description: Text(
                            "Votre bio est visible par tout le monde (même les profs !).",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void changeContacts() {
    final phoneNumberController = TextEditingController(
      text: profile["PhoneNumber"],
    );
    final instagramUsernameController = TextEditingController(
      text: profile["InstagramUsername"],
    );
    final snapchatUsernameController = TextEditingController(
      text: profile["SnapchatUsername"],
    );
    final discordUsernameController = TextEditingController(
      text: profile["DiscordUsername"],
    );

    bool checkChanges() =>
        profile["PhoneNumber"] != phoneNumberController.text ||
        profile["InstagramUsername"] != instagramUsernameController.text ||
        profile["SnapchatUsername"] != snapchatUsernameController.text ||
        profile["DiscordUsername"] != discordUsernameController.text;

    showCupertinoSheet(
      context: context,
      pageBuilder:
          (context) => StatefulBuilder(
            builder:
                (context, setSheetState) => CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text("Vos contacts"),
                    leading: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text("Annuler"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed:
                          checkChanges()
                              ? () {
                                changesMade = true;
                                profile["PhoneNumber"] =
                                    phoneNumberController.text.isEmpty
                                        ? null
                                        : phoneNumberController.text;
                                profile["InstagramUsername"] =
                                    instagramUsernameController.text.isEmpty
                                        ? null
                                        : instagramUsernameController.text;
                                profile["SnapchatUsername"] =
                                    snapchatUsernameController.text.isEmpty
                                        ? null
                                        : snapchatUsernameController.text;
                                profile["DiscordUsername"] =
                                    discordUsernameController.text.isEmpty
                                        ? null
                                        : discordUsernameController.text;
                                Navigator.of(context).pop();
                              }
                              : null,
                      child: Text("Terminé"),
                    ),
                  ),
                  child: SafeArea(
                    child: SettingsList(
                      platform: DevicePlatform.iOS,
                      sections: [
                        SettingsSection(
                          tiles: [
                            contactTile(
                              "PhoneNumber",
                              CupertinoIcons.phone,
                              changeMode: true,
                              placeholder: "Numéro de téléphone",
                              controller: phoneNumberController,
                              onChanged: (value) {
                                final formatted = formatSwissPhoneNumber(value);

                                if (formatted != phoneNumberController.text) {
                                  final cursorPos = formatted.length;
                                  phoneNumberController
                                      .value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                      offset: cursorPos,
                                    ),
                                  );
                                }

                                setSheetState(() {});
                              },
                            ),

                            contactTile(
                              "InstagramUsername",
                              FontAwesomeIcons.instagram,
                              changeMode: true,
                              placeholder: "Nom d'utilisateur sur Instagram",
                              controller: instagramUsernameController,
                              onChanged: (_) => setSheetState(() {}),
                            ),

                            contactTile(
                              "SnapchatUsername",
                              FontAwesomeIcons.snapchat,
                              changeMode: true,
                              placeholder: "Nom d'utilisateur sur Snapchat",
                              controller: snapchatUsernameController,
                              onChanged: (_) => setSheetState(() {}),
                            ),

                            contactTile(
                              "DiscordUsername",
                              CupertinoIcons.game_controller,
                              changeMode: true,
                              placeholder: "Nom d'utilisateur sur Discord",
                              controller: discordUsernameController,
                              onChanged: (_) => setSheetState(() {}),
                              description: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  SettingsTile contactTile(
    String contact,
    IconData? icon, {
    bool description = false,
    bool changeMode = false,
    String? placeholder,
    TextEditingController? controller,
    void Function(String)? onChanged,
  }) {
    final value = profile[contact];

    if (changeMode) {
      return SettingsTile(
        leading: Icon(icon ?? CupertinoIcons.mail),
        title: CupertinoTextField(
          controller: controller,
          decoration: BoxDecoration(),
          padding: EdgeInsets.zero,
          placeholder: placeholder,
          onChanged: onChanged,
        ),
        description:
            description
                ? Text(
                  "Ces informations ne sont visibles que par les utilisateurs de Messagyre.",
                )
                : null,
      );
    }

    return SettingsTile(
      title: Text(
        value ?? "Ajouter",
        overflow: TextOverflow.fade,
        softWrap: false,
        style:
            value == null
                ? TextStyle(color: CupertinoColors.inactiveGray)
                : null,
      ),
      leading: Icon(icon),
      onPressed: (_) => editMode ? changeContacts() : copy(value),
      description:
          description
              ? Text(
                editMode
                    ? "Appuyez pour modifier."
                    : "Appuyez pour copier dans le presse-papiers.",
              )
              : null,
    );
  }

  @override
  Widget build(context) {

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: GestureDetector(
          onTap:
              isUploading
                  ? null
                  : () {
                    if (changesMade) {
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (dialogContext) => CupertinoAlertDialog(
                              title: Text("Annuler les changements ?"),
                              content: Text(
                                "Tout changement sera annulé. Cette action est irréversible !",
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed:
                                      () => Navigator.of(dialogContext).pop(),
                                  child: Text("Non"),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Oui"),
                                ),
                              ],
                            ),
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
          child: Icon(
            CupertinoIcons.back,
            color: isUploading ? CupertinoColors.inactiveGray : null,
          ),
        ),
        middle: Text(editMode ? "Mon profil" : account.username),
        trailing:
            changesMade
                ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  child:
                      isUploading
                          ? CupertinoActivityIndicator()
                          : Text(
                            "Appliquer",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  onPressed: () async {
                    setState(() => isUploading = true);
                    bool success = await router.uploadProfile(
                      profile,
                      imagePath: chosenPicturePath,
                    );
                    setState(() => isUploading = false);

                    if (context.mounted) {
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (dialogContext) => CupertinoAlertDialog(
                              title: Text(
                                success ? "Profil actualisé!" : "Erreur",
                              ),
                              content: Text(
                                success
                                    ? "Le profil a été mis a jour avec succès!"
                                    : "Une erreur s'est produite, veuillez reéssayer.",
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  child: Text("OK"),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    if (success) Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                      );
                    }
                  },
                )
                : null,
      ),
      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              tiles: [
                SettingsTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 3,
                        children: [
                          Text(
                            account.username.replaceAll(".", " ").capitalize(),
                            style: TextStyle(fontSize: 20),
                          ),
                          if (account.classOrRole != null)
                            Text(
                              account.classOrRole!,
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.inactiveGray,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: ProfilePictureDisplay(
                      accountUsername:
                          chosenPicturePath != null ? null : account.username,
                      picturePath: chosenPicturePath,
                      radius: 40,
                    ),
                  ),
                  description: Text(
                    "${editMode ? "Vous avez" : "A"} rejoint le ${DateFormat('dd.MM.yyyy').format(account.creationDate!)}",
                  ),
                  onPressed: editMode ? (_) => changeProfilePicture() : null,
                ),
              ],
            ),

            SettingsSection(
              title: Text(editMode ? "Votre bio" : "Bio"),
              tiles: [
                SettingsTile(
                  title: Text(profile["Bio"] ?? "-"),
                  onPressed: editMode ? (_) => changeBio() : null,
                ),
              ],
            ),

            SettingsSection(
              title: Text("Autres contacts"),
              tiles: [
                // Email address
                SettingsTile(
                  title: Text(
                    account.emailAddress,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                  leading: Icon(CupertinoIcons.mail),
                  onPressed:
                      editMode
                          ? null
                          : (context) =>
                              editMode
                                  ? changeContacts()
                                  : copy(account.emailAddress),
                ),

                if (profile["PhoneNumber"] != null || editMode)
                  contactTile("PhoneNumber", CupertinoIcons.phone),

                if (profile["InstagramUsername"] != null || editMode)
                  contactTile("InstagramUsername", FontAwesomeIcons.instagram),

                if (profile["SnapchatUsername"] != null || editMode)
                  contactTile("SnapchatUsername", FontAwesomeIcons.snapchat),

                if (profile["DiscordUsername"] != null || editMode)
                  contactTile(
                    "DiscordUsername",
                    CupertinoIcons.game_controller,
                    description: true,
                  ),
              ],
            ),

            if (!editMode)
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
//TODO: hide the Delete Chat button if the chat does not exist.
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
