import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/dismissable_text_field.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:settings_ui/settings_ui.dart';

class ProfilePage extends StatefulWidget {
  final Account account;
  final bool openedFromChat;

  const ProfilePage(this.account, {super.key, this.openedFromChat = false});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final globals = GlobalsService();
  final network = NetworkService();

  late final account = widget.account;
  late final profile = widget.account.profile ?? {};

  late final box = Hive.box<Chat>("Chats");
  late final chat = box.get(account.username);

  late final editMode = account.username == globals.username;

  bool isBlocked = false;
  bool changesMade = false;
  bool isUploading = false;
  String? chosenPicturePath;

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
                    globals.pfpNotifiersCache[account.username]?.value = null;
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
                          backgroundColor: CupertinoColors.transparent,
                          header: Text("Pseudo"),
                          margin: EdgeInsets.zero,
                          children: [
                            CupertinoListTile(
                              backgroundColor: cupertinoListTileColor,
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
                          backgroundColor: CupertinoColors.transparent,
                          header: Text("Entrez votre biographie"),
                          margin: EdgeInsets.zero,
                          children: [
                            CupertinoListTile(
                              backgroundColor: cupertinoListTileColor,
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
                            HugeIcon(icon: HugeIcons.strokeRoundedAlert02, color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 16),
                            Expanded(
                              child: Text(
                                "Votre bio sera visible par tout les utilisateurs de Messagyre.",
                                style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
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

  void deleteMessages() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text("Effacer les messages"),
          content: Text(
            "Voulez-vous vraiment effacer tous les messages dans la conversation avec ${account.displayName ?? Account.getDefaultDisplayName(account.username)} ? Cette action est irréversible.",
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                if (Hive.isBoxOpen("Chats")) {
                  chat?.content.clear();
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).push(
                    CupertinoDialogRoute(
                      builder:
                          (_) => CupertinoAlertDialog(
                            title: Text("Messages effacés."),
                            content: Text("Tous les messages de cette conversation ont été effacés du téléphone."),
                            actions: [CupertinoDialogAction(child: Text("OK"), onPressed: () => Navigator.pop(context))],
                          ),
                      context: dialogContext,
                    ),
                  );
                }
              },
              child: Text("Effacer"),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text("Annuler", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.25))),
            ),
          ],
        );
      },
    );
  }

  void deleteChat() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text("Supprimer la conversation"),
          content: Text(
            "Voulez-vous vraiment supprimer la conversation avec ${account.displayName ?? Account.getDefaultDisplayName(account.username)} ? Cette action est irréversible.",
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                if (Hive.isBoxOpen("Chats")) {
                  await box.delete(account.username);
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).push(
                    CupertinoDialogRoute(
                      builder:
                          (_) => CupertinoAlertDialog(
                            title: Text("Supprimée"),
                            content: Text(
                              "La conversation avec ${account.displayName ?? Account.getDefaultDisplayName(account.username)} a été supprimée du téléphone.",
                            ),
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
              child: Text("Annuler", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.25))),
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
        onPressed: value != null ? (_) => copy(context, value) : null,
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
          child:
              isUploading
                  ? LoadingAnimationWidget.waveDots(color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 14)
                  : Text("Appliquer", style: TextStyle(fontWeight: FontWeight.w600)),
          onPressed: () async {
            setState(() => isUploading = true);
            bool success = await network.uploadProfile(account.displayName, profile, imagePath: chosenPicturePath);
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

  void deleteAccount() async {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: Text("Supprimer le compte"),
            content: Text("Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible et toutes vos données seront perdues."),
            actions: [
              CupertinoDialogAction(
                child: Text("Annuler", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.25))),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text("Supprimer"),
                onPressed: () {
                  Navigator.pop(dialogContext);

                  showCupertinoDialog(
                    context: context,
                    builder: (dialogContext) {
                      final controller = TextEditingController();
                      return CupertinoAlertDialog(
                        title: Row(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedLockPassword, color: CupertinoTheme.of(context).primaryColor.withBrightness(.25)),
                            Text("Mot de passe requis"),
                          ],
                        ),
                        content: Column(
                          children: [
                            SizedBox(height: 10),
                            SizedBox(
                              height: 40,
                              child: DismissableTextField(
                                keyboardType: TextInputType.visiblePassword,
                                obscureText: true,
                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(color: CupertinoColors.systemGrey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                controller: controller,
                                placeholder: "Votre mot de passe",
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: Text("Annuler", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.25))),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: Text("Supprimer"),
                            onPressed: () async {
                              final password = controller.text.trim();
                              if (password.isEmpty) return;

                              final success = await network.post("/accounts/me/delete", {"Password": password});
                              if (!dialogContext.mounted) return;

                              if (success.statusCode != 200) {
                                showCupertinoDialog(
                                  context: dialogContext,
                                  builder:
                                      (errorDialogContext) => CupertinoAlertDialog(
                                        title: Text("Erreur"),
                                        content: Text("Le mot de passe est incorrect ou une erreur est survenue. Veuillez réessayer."),
                                        actions: [
                                          CupertinoDialogAction(isDefaultAction: true, child: Text("OK"), onPressed: () => Navigator.pop(errorDialogContext)),
                                        ],
                                      ),
                                );
                                return;
                              }

                              showCupertinoDialog(
                                context: dialogContext,
                                builder:
                                    (errorDialogContext) => CupertinoAlertDialog(
                                      title: Text("Compte supprimé"),
                                      content: Text(
                                        "Votre compte a été supprimé avec succès. Nous sommes désolés de vous voir partir. Vous serez redirigé vers l'écran de connexion.",
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          isDefaultAction: true,
                                          child: Text("OK"),
                                          onPressed: () {
                                            Navigator.pop(errorDialogContext);
                                            network.logout();

                                            if (!dialogContext.mounted) return;
                                            restartApp(dialogContext);
                                            Navigator.pop(dialogContext);
                                          },
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
    );
  }

  Widget buildListTile(List<List<dynamic>> icon, String title, {VoidCallback? onTap, bool isDestructive = false}) {
    final enabled = onTap != null;
    final color =
        enabled
            ? isDestructive
                ? CupertinoColors.destructiveRed.resolveFrom(context)
                : CupertinoColors.label.resolveFrom(context)
            : CupertinoColors.inactiveGray.resolveFrom(context);

    return CupertinoListTile(
      backgroundColor: cupertinoListTileColor,
      leading: HugeIcon(icon: icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPinned = chat?.isPinned ?? false;

    isBlocked = globals.blockedUsers.contains(account.username);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: buildLeading(),
        middle: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Text(editMode ? "Mon profil" : account.username),
            if (isBlocked) HugeIcon(icon: HugeIcons.strokeRoundedUnavailable, size: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
          ],
        ),
        trailing: buildTrailing(),
      ),
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
                    Container(
                      foregroundDecoration: isBlocked ? BoxDecoration(color: Colors.grey, backgroundBlendMode: BlendMode.saturation) : null,
                      child: ProfilePictureDisplay(
                        accountUsername: chosenPicturePath != null ? null : account.username,
                        picturePath: chosenPicturePath,
                        radius: 40,
                      ),
                    ),
                    Column(
                      spacing: 2,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedUserAccount, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                            Text(account.displayName ?? account.defaultDisplayName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(account.username, style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        SizedBox(height: 0),

                        if (account.classOrRole != null)
                          Text(account.classOrRole!, style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                      ],
                    ),
                  ],
                ),

                if (profile["Bio"] != null) CustomText(profile["Bio"], style: TextStyle(fontSize: 16)),
                Text(
                  "Membre depuis ${formatDate(account.creationDate ?? DateTime.now(), includeArticle: true)}.",
                  style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                ),

                SizedBox(height: 6),

                if (isBlocked)
                  CupertinoListSection.insetGrouped(
                    backgroundColor: CupertinoColors.transparent,
                    margin: EdgeInsets.zero,
                    children: [
                      buildListTile(
                        HugeIcons.strokeRoundedUserUnlock01,
                        "Débloquer cet utilisateur",
                        onTap:
                            () => showCupertinoDialog(
                              context: context,
                              builder:
                                  (dialogContext) => CupertinoAlertDialog(
                                    title: Text("Débloquer ${account.displayName ?? Account.getDefaultDisplayName(account.username)} ?"),
                                    content: Text(
                                      "Vous pourrez à nouveau recevoir de messages de sa part. Cet utilisateur ne sera pas notifié de votre action.",
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: Text("Annuler", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.25))),
                                        onPressed: () => Navigator.pop(dialogContext),
                                      ),
                                      CupertinoDialogAction(
                                        isDefaultAction: true,
                                        child: Text("Débloquer", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.25))),
                                        onPressed: () {
                                          globals.unblockUser(account.username);
                                          setState(() {});
                                          Navigator.pop(dialogContext);
                                        },
                                      ),
                                    ],
                                  ),
                            ),
                      ),
                    ],
                  ),

                if (account.username != globals.username) ...[
                  if (!widget.openedFromChat) // Temporary
                    CupertinoListSection.insetGrouped(
                      backgroundColor: CupertinoColors.transparent,
                      margin: EdgeInsets.zero,
                      children: [
                        if (!widget.openedFromChat)
                          buildListTile(
                            HugeIcons.strokeRoundedSent,
                            "Envoyer un message",
                            onTap:
                                isBlocked
                                    ? null
                                    : () => Navigator.pushReplacement(
                                      context,
                                      CupertinoPageRoute(builder: (context) => ChatPage(recipientUsername: account.username)),
                                    ),
                          ),

                        // TODO
                        // buildListTile(HugeIcons.strokeRoundedUserGroup, "Ajouter à un groupe"),
                        // buildListTile(HugeIcons.strokeRoundedLinkForward, "Transférer ce profil"),
                        // buildListTile(HugeIcons.strokeRoundedShare08, "Partager ce profil"),
                      ],
                    ),
                ],

                if (box.containsKey(account.username))
                  CupertinoListSection.insetGrouped(
                    backgroundColor: CupertinoColors.transparent,
                    margin: EdgeInsets.zero,
                    children: [
                      buildListTile(
                        isPinned ? HugeIcons.strokeRoundedPinOff : HugeIcons.strokeRoundedPin,
                        isPinned ? "Désépingler" : "Épingler",
                        onTap: () {
                          if (chat == null) return;
                          chat!.isPinned = !isPinned;
                          chat!.save();
                          setState(() {});
                        },
                      ),
                      buildListTile(HugeIcons.strokeRoundedDelete01, "Effacer les messages", onTap: deleteMessages),
                      buildListTile(HugeIcons.strokeRoundedDelete04, "Supprimer la conversation", isDestructive: true, onTap: deleteChat),
                    ],
                  ),

                if (account.username == globals.username) ...[
                  CupertinoListSection.insetGrouped(
                    backgroundColor: CupertinoColors.transparent,
                    margin: EdgeInsets.zero,
                    children: [
                      buildListTile(HugeIcons.strokeRoundedPencilEdit02, "Modifier le profil", onTap: () => changeProfile()),
                      buildListTile(HugeIcons.strokeRoundedUserCircle, "Changer de photo de profil", onTap: () => changeProfilePicture()),
                      //TODO
                      //buildListTile(HugeIcons.strokeRoundedSquareLock02, "Parametres de visibilité"),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    backgroundColor: CupertinoColors.transparent,
                    margin: EdgeInsets.zero,
                    children: [buildListTile(HugeIcons.strokeRoundedUserRemove01, "Supprimer le compte", isDestructive: true, onTap: () => deleteAccount())],
                  ),
                ],

                if (account.username != globals.username) ...[
                  CupertinoListSection.insetGrouped(
                    backgroundColor: CupertinoColors.transparent,
                    margin: EdgeInsets.zero,
                    children: [
                      if (!isBlocked)
                        buildListTile(
                          HugeIcons.strokeRoundedUserBlock01,
                          "Bloquer",
                          isDestructive: true,
                          onTap:
                              () => showCupertinoDialog(
                                context: context,
                                builder:
                                    (dialogContext) => CupertinoAlertDialog(
                                      title: Text("Bloquer ${account.displayName ?? Account.getDefaultDisplayName(account.username)} ?"),
                                      content: Text("Vous ne receverez plus de messages de sa part. Cet utilisateur ne sera pas notifié de votre action."),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: Text("Annuler", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.25))),
                                          onPressed: () => Navigator.pop(dialogContext),
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          child: Text("Bloquer"),
                                          onPressed: () {
                                            globals.blockUser(account.username);
                                            setState(() {});
                                            Navigator.pop(dialogContext);
                                          },
                                        ),
                                      ],
                                    ),
                              ),
                        ),
                      buildListTile(
                        HugeIcons.strokeRoundedFlag02,
                        "Signaler",
                        isDestructive: true,
                        onTap:
                            () => showCupertinoDialog(
                              context: context,
                              builder:
                                  (dialogContext) => CupertinoAlertDialog(
                                    title: Text("Signaler ${account.displayName ?? Account.getDefaultDisplayName(account.username)} ?"),
                                    content: Text(
                                      "Ce profil sera envoyé aux développeurs de Messagyre pour évaluation. Si le profil est jugé inapproprié, des mesures pourront être prises.",
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: Text("Annuler", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(0.25))),
                                        onPressed: () => Navigator.pop(dialogContext),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        child: Text("Signaler"),
                                        onPressed: () {
                                          setState(() {});
                                          Navigator.pop(dialogContext);
                                        },
                                      ),
                                    ],
                                  ),
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
