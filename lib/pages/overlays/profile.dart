import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/dismissable_text_field.dart';
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
            actions: [CupertinoDialogAction(child: Text("OK"), onPressed: () => Navigator.of(dialogContext).pop())],
          ),
    );
  }

  void changeProfilePicture() {
    void pickImage(ImageSource source) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [IOSUiSettings(title: "Retailler l'image", aspectRatioLockEnabled: true)],
      );

      if (croppedFile != null) {
        setState(() {
          changesMade = true;
          chosenPicturePath = croppedFile.path;
        });
      }
    }

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  pickImage(ImageSource.camera);
                },
                child: Row(
                  spacing: 8,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: CupertinoColors.label.resolveFrom(context)),
                    ),
                    Text("Prendre une photo", style: TextStyle(fontSize: 20, color: CupertinoColors.label.resolveFrom(context))),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  pickImage(ImageSource.gallery);
                },
                child: Row(
                  spacing: 8,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedAlbum02, color: CupertinoColors.label.resolveFrom(context)),
                    ),
                    Text("Choisir une photo de la galérie", style: TextStyle(fontSize: 20, color: CupertinoColors.label.resolveFrom(context))),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    chosenPicturePath = null;
                    changesMade = true;
                    data.pfpNotifiersCache[account.username]?.value = null;
                  });
                },
                child: Row(
                  spacing: 8,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedDelete04, color: CupertinoColors.destructiveRed.resolveFrom(context)),
                    ),
                    Text("Supprimer la photo", style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  void changeProfile() {
    String originalDisplayName = account.displayName ?? account.defaultDisplayName;
    String originalBio = profile["Bio"] ?? "";
    final displayNameController = TextEditingController(text: originalDisplayName);
    final bioController = TextEditingController(text: originalBio);
    final displayNameFocusNode = FocusNode();
    final bioFocusNode = FocusNode();

    showCupertinoSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text("Modifier le profil"),
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
                      (displayNameController.text != originalDisplayName || bioController.text != originalBio)
                          ? () {
                            changesMade = true;
                            account.displayName = displayNameController.text;
                            profile["Bio"] = bioController.text;
                            Navigator.of(context).pop();
                          }
                          : null,
                  child: Text("Terminé"),
                ),
              ),
              child: SafeArea(
                child: ListView(
                  padding: EdgeInsets.all(10),
                  children: [
                    Column(
                      children: [
                        CupertinoListSection.insetGrouped(
                          header: Text("Pseudo"),
                          margin: EdgeInsets.zero,
                          children: [
                            CupertinoListTile(
                              title: DismissableTextField(
                                controller: displayNameController,
                                focusNode: displayNameFocusNode,
                                decoration: BoxDecoration(),
                                padding: EdgeInsets.zero,
                                placeholder: "Entrez votre pseudo",
                                minLines: 1,
                                maxLines: 1,
                                maxLength: 100,
                                onChanged: (_) => setSheetState(() {}),
                              ),
                              onTap: () => displayNameFocusNode.requestFocus(),
                            ),
                          ],
                        ),

                        CupertinoListSection.insetGrouped(
                          header: Text("Entrez votre biographie"),
                          margin: EdgeInsets.zero,
                          children: [
                            CupertinoListTile(
                              title: DismissableTextField(
                                controller: bioController,
                                focusNode: bioFocusNode,
                                decoration: BoxDecoration(),
                                padding: EdgeInsets.symmetric(vertical: 8),
                                placeholder: "Bio",
                                minLines: 3,
                                maxLines: 5,
                                maxLength: 100,
                                onChanged: (_) => setSheetState(() {}),
                                onTap: () => bioFocusNode.requestFocus(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedAlert02, color: CupertinoColors.inactiveGray.resolveFrom(context), size: 16),
                            Expanded(
                              child: Text(
                                "Votre bio sera visible par tout les utilisateurs de Messagyre.",
                                style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context)),
                                softWrap: true,
                              ),
                            ),
                          ],
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
    final phoneNumberController = TextEditingController(text: profile["PhoneNumber"]);
    final instagramUsernameController = TextEditingController(text: profile["InstagramUsername"]);
    final snapchatUsernameController = TextEditingController(text: profile["SnapchatUsername"]);
    final discordUsernameController = TextEditingController(text: profile["DiscordUsername"]);

    bool checkChanges() =>
        profile["PhoneNumber"] != phoneNumberController.text ||
        profile["InstagramUsername"] != instagramUsernameController.text ||
        profile["SnapchatUsername"] != snapchatUsernameController.text ||
        profile["DiscordUsername"] != discordUsernameController.text;

    showCupertinoSheet(
      context: context,
      builder:
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
                                profile["PhoneNumber"] = phoneNumberController.text.isEmpty ? null : phoneNumberController.text;
                                profile["InstagramUsername"] = instagramUsernameController.text.isEmpty ? null : instagramUsernameController.text;
                                profile["SnapchatUsername"] = snapchatUsernameController.text.isEmpty ? null : snapchatUsernameController.text;
                                profile["DiscordUsername"] = discordUsernameController.text.isEmpty ? null : discordUsernameController.text;
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
                              HugeIcons.strokeRoundedCall02,
                              placeholder: "Numéro de téléphone",
                              controller: phoneNumberController,
                              onChanged: (value) {
                                final formatted = formatSwissPhoneNumber(value);

                                if (formatted != phoneNumberController.text) {
                                  final cursorPos = formatted.length;
                                  phoneNumberController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: cursorPos));
                                }

                                setSheetState(() {});
                              },
                            ),

                            contactTile(
                              "InstagramUsername",
                              HugeIcons.strokeRoundedInstagram,
                              placeholder: "Nom d'utilisateur sur Instagram",
                              controller: instagramUsernameController,
                              onChanged: (_) => setSheetState(() {}),
                            ),

                            contactTile(
                              "SnapchatUsername",
                              HugeIcons.strokeRoundedSnapchat,
                              placeholder: "Nom d'utilisateur sur Snapchat",
                              controller: snapchatUsernameController,
                              onChanged: (_) => setSheetState(() {}),
                            ),

                            contactTile(
                              "DiscordUsername",
                              HugeIcons.strokeRoundedDiscord,
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

  void deleteChat() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text("Supprimer la conversation"),
          content: Text("Voulez-vous vraiment supprimer la conversation avec ${account.username} ? Cette action est irréversible."),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                if (Hive.isBoxOpen("Chats")) {
                  await Hive.box<Chat>("Chats").delete(account.username);
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).push(
                    CupertinoDialogRoute(
                      builder:
                          (_) => CupertinoAlertDialog(
                            title: Text("Supprimée"),
                            content: Text("La conversation avec ${account.username} a été supprimée du téléphone."),
                            actions: [CupertinoDialogAction(child: Text("OK"), onPressed: () => Navigator.pop(context))],
                          ),
                      context: dialogContext,
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
    );
  }

  SettingsTile contactTile(
    String contact,
    List<List>? icon, {
    bool description = false,
    String? placeholder,
    TextEditingController? controller,
    void Function(String)? onChanged,
  }) {
    final value = profile[contact];

    if (editMode) {
      controller ??= TextEditingController(text: value);
      return SettingsTile(
        leading: HugeIcon(icon: icon ?? HugeIcons.strokeRoundedMailAccount01),
        title: CupertinoTextField(
          controller: controller,
          decoration: BoxDecoration(),
          padding: EdgeInsets.zero,
          placeholder: placeholder ?? "Ajouter",
          onChanged: onChanged,
        ),
        description: description ? Text("Ces informations ne sont visibles que par les utilisateurs de Messagyre.") : null,
      );
    } else {
      return SettingsTile(
        leading: HugeIcon(icon: icon ?? HugeIcons.strokeRoundedMailAccount01),
        title: Text(
          value ?? "Ajouter",
          overflow: TextOverflow.fade,
          softWrap: false,
          style: value == null ? TextStyle(color: CupertinoColors.inactiveGray) : null,
        ),
        description: description ? Text("Appuyez pour copier dans le presse-papiers.") : null,
        onPressed: value != null ? (_) => copy(value) : null,
      );
    }
  }

  Widget buildLeading() {
    return GestureDetector(
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
                          content: Text("Tout changement sera annulé. Cette action est irréversible !"),
                          actions: [
                            CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(dialogContext).pop(), child: Text("Non")),
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
      child: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isUploading ? CupertinoColors.inactiveGray : null, size: 30),
    );
  }

  Widget? buildTrailing() {
    return changesMade
        ? CupertinoButton(
          padding: EdgeInsets.zero,
          child: isUploading ? CupertinoActivityIndicator() : Text("Appliquer", style: TextStyle(fontWeight: FontWeight.w600)),
          onPressed: () async {
            setState(() => isUploading = true);
            bool success = await router.uploadProfile(account.displayName, profile, imagePath: chosenPicturePath);
            setState(() => isUploading = false);

            if (!context.mounted) return;
            final mountedContext = context;

            showCupertinoDialog(
              context: mountedContext,
              builder:
                  (dialogContext) => CupertinoAlertDialog(
                    title: Text(success ? "Profil actualisé!" : "Erreur"),
                    content: Text(success ? "Le profil a été mis a jour avec succès!" : "Une erreur s'est produite, veuillez reéssayer."),
                    actions: [
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          if (success) Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  ),
            );
          },
        )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(leading: buildLeading(), middle: Text(editMode ? "Mon profil" : account.username), trailing: buildTrailing()),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(10),
          children: [
            Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 10,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfilePictureDisplay(accountUsername: chosenPicturePath != null ? null : account.username, picturePath: chosenPicturePath, radius: 40),
                    Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedUserAccount, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                            Text(account.displayName ?? account.defaultDisplayName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                          ],
                        ),

                        if (account.classOrRole != null)
                          Text(account.classOrRole!, style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),

                        Text(account.emailAddress, style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 6),
                if (profile["Bio"] != null) Text(profile["Bio"], style: TextStyle(fontSize: 18)),
                Text(
                  "Compte créé ${formatDate(account.creationDate ?? DateTime.now(), includeArticle: true)}.",
                  style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                ),

                SizedBox(height: 6),

                if (account.username != data.username) ...[
                  CupertinoListSection.insetGrouped(
                    margin: EdgeInsets.zero,
                    children: [
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedSent, color: CupertinoColors.label.resolveFrom(context)),
                        title: Text("Envoyer un message"),
                        onTap:
                            () =>
                                Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => ChatOverlay(recipientUsername: account.username))),
                      ),
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                        title: Text("Ajouter à un groupe", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                      ),
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedLinkForward, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                        title: Text("Transférer ce profil", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                      ),
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedShare08, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                        title: Text("Partager ce profil", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                      ),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    margin: EdgeInsets.zero,
                    children: [
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedFlag02, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                        title: Text("Signaler", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                      ),
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedUserBlock01, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                        title: Text("Bloquer", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                      ),
                    ],
                  ),
                ],

                if (Hive.box<Chat>("Chats").containsKey(account.username))
                  CupertinoListSection.insetGrouped(
                    margin: EdgeInsets.zero,
                    children: [
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedPin, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                        title: Text("Épingler", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                      ),
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedDelete01, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                        title: Text("Effacer les messages", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                      ),
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedDelete04, color: CupertinoColors.destructiveRed),
                        title: Text("Supprimer la conversation", style: TextStyle(color: CupertinoColors.destructiveRed)),
                        onTap: deleteChat,
                      ),
                    ],
                  ),

                if (account.username == data.username)
                  CupertinoListSection.insetGrouped(
                    margin: EdgeInsets.zero,
                    children: [
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: CupertinoColors.label.resolveFrom(context)),
                        title: Text("Modifier le profil"),
                        onTap: () => changeProfile(),
                      ),
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, color: CupertinoColors.label.resolveFrom(context)),
                        title: Text("Changer de photo de profil"),
                        onTap: () => changeProfilePicture(),
                      ),
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedSquareLock02, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                        title: Text("Parametres de visibilité", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
