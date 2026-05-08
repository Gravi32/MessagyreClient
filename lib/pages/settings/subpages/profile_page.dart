import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart' hide Dialog;
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/dismissable_text_field.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

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
  final database = DatabaseService();

  late final account = widget.account;
  late final profile = widget.account.profile ?? {};

  late var chat = database.chats.getByUsername(account.username);

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
      builder: (context) => CupertinoActionSheet(
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
                  child: CustomIcon(icon: HugeIcons.strokeRoundedCamera01, color: AppColors.text.adaptTo(context)),
                ),
                Text("Prendre une photo", style: TextStyle(fontSize: 20, color: AppColors.text.adaptTo(context))),
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
                  child: CustomIcon(icon: HugeIcons.strokeRoundedAlbum02, color: AppColors.text.adaptTo(context)),
                ),
                Text("Choisir une photo de la galérie", style: TextStyle(fontSize: 20, color: AppColors.text.adaptTo(context))),
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
                  child: CustomIcon(icon: HugeIcons.strokeRoundedDelete04, color: AppColors.red),
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
                middle: Text("Infos"),
                leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text("Annuler"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: (displayNameController.text != originalDisplayName || bioController.text != originalBio)
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
                          backgroundColor: AppColors.transparent,
                          header: Text("Pseudo"),
                          margin: EdgeInsets.zero,
                          children: [
                            CupertinoListTile(
                              backgroundColor: AppColors.secondaryBackground.adaptTo(context),
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
                          backgroundColor: AppColors.transparent,
                          header: Text("Entrez votre biographie"),
                          margin: EdgeInsets.zero,
                          children: [
                            CupertinoListTile(
                              backgroundColor: AppColors.secondaryBackground.adaptTo(context),
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
                            CustomIcon(icon: HugeIcons.strokeRoundedAlert02, color: AppColors.secondaryText.adaptTo(context), size: 16),
                            Expanded(
                              child: Text(
                                "Votre bio sera visible par tout les utilisateurs de Messagyre.",
                                style: TextStyle(color: AppColors.secondaryText.adaptTo(context)),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => CupertinoPageScaffold(
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
              onPressed: checkChanges()
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
            child: ListView(
              physics: const ClampingScrollPhysics(),
              children: [
                CupertinoListSection.insetGrouped(
                  children: [
                    contactTile(
                      "PhoneNumber",
                      HugeIcons.strokeRoundedCall02,
                      placeholder: "Numéro de téléphone",
                      controller: phoneNumberController,
                      onChanged: (value) {
                        final formatted = formatSwissPhoneNumber(value);

                        if (formatted != phoneNumberController.text) {
                          final cursorPos = formatted.length;
                          phoneNumberController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: cursorPos),
                          );
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
      builder: (_) {
        return Dialog.confirm(
          content:
              "Voulez-vous vraiment *effacer tous les messages* dans la conversation avec *${account.displayName ?? Account.getDefaultDisplayName(account.username)}* ? Cette action est irréversible.",
          onConfirm: () async {
            for (final message in chat!.messages) {
              database.messages.delete(message);
            }
            chat?.messages.clear();
            database.chats.save(chat!);

            showCupertinoDialog(
              context: context,
              builder: (_) => Dialog(title: "Messages effacés.", content: "Tous les messages de cette conversation ont été effacés du téléphone."),
            );
          },
          isDestructive: true,
        );
      },
    );
  }

  void deleteChat() {
    showCupertinoDialog(
      context: context,
      builder: (_) => Dialog.confirm(
        content:
            "Voulez-vous vraiment *supprimer la conversation* avec *${account.displayName ?? Account.getDefaultDisplayName(account.username)}* ? Cette action est irréversible.",
        onConfirm: () async {
          database.chats.deleteChat(chat);

          showCupertinoDialog(
            context: context,
            builder: (_) => Dialog(
              title: "Conversation supprimée",
              content: "La conversation avec ${account.displayName ?? Account.getDefaultDisplayName(account.username)} a été supprimée du téléphone.",
            ),
          );
        },
        isDestructive: true,
      ),
    );
  }

  CupertinoListTile contactTile(
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
      return CupertinoListTile(
        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
        leading: CustomIcon(icon: icon ?? HugeIcons.strokeRoundedMailAccount01),
        title: CupertinoTextField(
          controller: controller,
          decoration: BoxDecoration(),
          padding: EdgeInsets.zero,
          placeholder: placeholder ?? "Ajouter",
          onChanged: onChanged,
        ),
        subtitle: description ? Text("Ces informations ne sont visibles que par les utilisateurs de Messagyre.") : null,
      );
    } else {
      return CupertinoListTile(
        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
        leading: CustomIcon(icon: icon ?? HugeIcons.strokeRoundedMailAccount01),
        title: Text(
          value ?? "Ajouter",
          overflow: TextOverflow.fade,
          softWrap: false,
          style: value == null ? TextStyle(color: AppColors.inactive.adaptTo(context)) : null,
        ),
        subtitle: description ? Text("Appuyez pour copier dans le presse-papiers.") : null,
        onTap: value != null ? () => copy(context, value) : null,
      );
    }
  }

  Widget buildLeading() {
    return GestureDetector(
      onTap: isUploading
          ? null
          : () {
              if (changesMade) {
                showCupertinoDialog(
                  context: context,
                  builder: (_) => Dialog.confirm(
                    content: "Tout changement sera annulé. Cette action est irréversible !",
                    onConfirm: () => Navigator.of(context).pop(),
                    isDestructive: true,
                  ),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
      child: CustomIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isUploading ? AppColors.inactive.adaptTo(context) : null, size: 30),
    );
  }

  Widget? buildTrailing() {
    return changesMade
        ? CupertinoButton(
            padding: EdgeInsets.zero,
            child: isUploading
                ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)
                : Text("Appliquer", style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: () async {
              setState(() => isUploading = true);
              bool success = await network.uploadProfile(account.displayName, profile, imagePath: chosenPicturePath);
              setState(() => isUploading = false);

              if (!context.mounted) return;
              final mountedContext = context;

              showCupertinoDialog(
                context: mountedContext,
                builder: (_) => Dialog(
                  title: success ? "Profil actualisé!" : "Erreur",
                  content: success ? "Le profil a été mis a jour avec succès!" : "Une erreur s'est produite, veuillez reéssayer.",
                  options: {"OK": () => Navigator.pop(context)},
                ),
              );
            },
          )
        : null;
  }

  void deleteAccount() async {
    showCupertinoDialog(
      context: context,
      builder: (_) => Dialog.confirm(
        content: "Voulez-vous vraiment *supprimer votre compte* ? Cette action est irréversible et toutes vos données seront perdues.",
        isDestructive: true,
        onConfirm: () {
          showCupertinoDialog(
            context: context,
            builder: (_) {
              final controller = TextEditingController();
              return Dialog.entry(
                title: "Mot de passe requis",
                controller: controller,
                isDestructive: true,
                obscureText: true,
                placeholder: "Votre mot de passe",
                onConfirm: () async {
                  final password = controller.text.trim();
                  if (password.isEmpty) return;

                  final apiResponse = await network.post("/accounts/me/delete", {"Password": password});
                  if (!mounted) return;

                  if (apiResponse.statusCode == 400) {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => Dialog(
                        title: "Mot de passe erroné",
                        content: "Si vous avez oublié votre mot de passe, contactez le support depuis les réglages. \n\nInstagram : @messagyre.ch",
                      ),
                    );
                    return;
                  }

                  if (apiResponse.statusCode != 200) {
                    showCupertinoDialog(context: context, builder: (_) => Dialog.networkError(apiResponse));
                    return;
                  }

                  showCupertinoDialog(
                    context: context,
                    builder: (_) => Dialog(
                      title: "Compte supprimé",
                      content:
                          "Votre compte a été supprimé avec succès. Nous sommes désolés de vous voir partir. Vous serez redirigé vers l'écran de connexion.",
                      options: {
                        "OK": () {
                          network.logout();
                          restartApp(context);
                          Navigator.pop(context);
                        },
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget buildListTile(List<List<dynamic>> icon, String title, {VoidCallback? onTap, bool isDestructive = false}) {
    final enabled = onTap != null;
    final color = enabled
        ? isDestructive
              ? AppColors.red
              : AppColors.text.adaptTo(context)
        : AppColors.inactive.adaptTo(context);

    return CupertinoListTile(
      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
      leading: CustomIcon(icon: icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            if (isBlocked) CustomIcon(icon: HugeIcons.strokeRoundedUnavailable, size: 16, color: AppColors.secondaryText.adaptTo(context)),
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
                        Text(account.displayName ?? account.defaultDisplayName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),

                        Row(
                          spacing: 6,
                          children: [
                            CustomIcon(icon: HugeIcons.strokeRoundedUserAccount, size: 18, color: AppColors.secondaryText.adaptTo(context)),
                            Text(account.username, style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                          ],
                        ),

                        SizedBox(height: 0),

                        if ((account.classOrRole ?? "-") != "-") Text(account.classOrRole!, style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                CustomText(
                  profile["Bio"] ?? "Pas de biographie",
                  style: TextStyle(fontSize: 16, color: profile["Bio"] == null ? AppColors.secondaryText.adaptTo(context) : null),
                ),
                Text(
                  "Membre depuis ${formatDate(account.creationDate ?? DateTime.now(), includeArticle: true)}.",
                  style: TextStyle(fontSize: 16, color: AppColors.tertiaryText.adaptTo(context)),
                ),

                SizedBox(height: 6),

                if (isBlocked)
                  CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.transparent,
                    margin: EdgeInsets.zero,
                    children: [
                      buildListTile(
                        HugeIcons.strokeRoundedUserUnlock01,
                        "Débloquer cet utilisateur",
                        onTap: () => showCupertinoDialog(
                          context: context,
                          builder: (dialogContext) => Dialog.confirm(
                            content:
                                "Débloquer *${account.displayName ?? Account.getDefaultDisplayName(account.username)}* ?\nVous pourrez à nouveau recevoir de messages de sa part. Cet utilisateur ne sera pas notifié de votre action.",
                            onConfirm: () {
                              globals.unblockUser(account.username);
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                if (account.username != globals.username) ...[
                  if (!widget.openedFromChat)
                    CupertinoListSection.insetGrouped(
                      backgroundColor: AppColors.transparent,
                      margin: EdgeInsets.zero,

                      children: [
                        if (!widget.openedFromChat)
                          buildListTile(
                            HugeIcons.strokeRoundedSent,
                            "Envoyer un message",
                            onTap: isBlocked
                                ? null
                                : () => Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => ChatPage(username: account.username))),
                          ),

                        // TODO
                        // buildListTile(HugeIcons.strokeRoundedUserGroup, "Ajouter à un groupe"),
                        // buildListTile(HugeIcons.strokeRoundedLinkForward, "Transférer ce profil"),
                        // buildListTile(HugeIcons.strokeRoundedShare08, "Partager ce profil"),
                      ],
                    ),
                ],

                if (chat != null)
                  CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.transparent,
                    margin: EdgeInsets.zero,

                    header: Text("Conversation"),

                    children: [
                      buildListTile(
                        chat!.isPinned ? HugeIcons.strokeRoundedPinOff : HugeIcons.strokeRoundedPin,
                        chat!.isPinned ? "Désépingler" : "Épingler",
                        onTap: () {
                          if (chat == null) return;

                          chat!.isPinned = !chat!.isPinned;
                          database.chats.save(chat!);
                          setState(() {});
                        },
                      ),
                      buildListTile(HugeIcons.strokeRoundedDelete01, "Effacer les messages", onTap: deleteMessages),
                      buildListTile(HugeIcons.strokeRoundedDelete04, "Supprimer la conversation", isDestructive: true, onTap: deleteChat),
                    ],
                  ),

                if (account.username == globals.username) ...[
                  CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.transparent,
                    margin: EdgeInsets.zero,

                    children: [
                      buildListTile(HugeIcons.strokeRoundedPencilEdit02, "Modifier le profil", onTap: () => changeProfile()),
                      buildListTile(HugeIcons.strokeRoundedUserCircle, "Changer de photo de profil", onTap: () => changeProfilePicture()),
                      //TODO
                      //buildListTile(HugeIcons.strokeRoundedSquareLock02, "Parametres de visibilité"),
                    ],
                  ),
                  CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.transparent,
                    margin: EdgeInsets.zero,
                    children: [buildListTile(HugeIcons.strokeRoundedUserRemove01, "Supprimer le compte", isDestructive: true, onTap: () => deleteAccount())],
                  ),
                ],

                if (account.username != globals.username) ...[
                  CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.transparent,
                    margin: EdgeInsets.zero,

                    header: Text("Utilisateur"),

                    children: [
                      if (!isBlocked)
                        buildListTile(
                          HugeIcons.strokeRoundedUserBlock01,
                          "Bloquer",
                          isDestructive: true,
                          onTap: () => showCupertinoDialog(
                            context: context,
                            builder: (_) => Dialog.confirm(
                              content:
                                  "Bloquer *${account.displayName ?? Account.getDefaultDisplayName(account.username)}* ?\nVous ne receverez plus de messages de sa part. Cet utilisateur ne sera pas notifié de votre action.",
                              onConfirm: () {
                                globals.blockUser(account.username);
                                setState(() {});
                              },
                              isDestructive: true,
                            ),
                          ),
                        ),
                      buildListTile(
                        HugeIcons.strokeRoundedFlag02,
                        "Signaler",
                        isDestructive: true,
                        onTap: () => showCupertinoDialog(
                          context: context,
                          builder: (dialogContext) => Dialog.confirm(
                            content:
                                "Signaler *${account.displayName ?? Account.getDefaultDisplayName(account.username)}* ?\nCe profil sera envoyé aux développeurs de Messagyre. Si le profil est jugé inapproprié, des mesures pourront être prises.",
                            onConfirm: () => setState(() {}),
                            isDestructive: true,
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
