import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/field.dart';
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
                  padding: .symmetric(horizontal: 8),
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
                  padding: .symmetric(horizontal: 8),
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
                  padding: .symmetric(horizontal: 8),
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
            return Page.scrollable(
              context,
              topBar: TopBar.form(
                context,
                title: "Infos",
                trailing: Button.icon(
                  context,
                  icon: HugeIcons.strokeRoundedTick02,
                  enabled: displayNameController.text != originalDisplayName || bioController.text != originalBio,
                  onTap: () {
                    changesMade = true;
                    account.displayName = displayNameController.text;
                    profile["Bio"] = bioController.text;
                    Navigator.of(context).pop();
                  },
                ),
              ),
              children: [
                Field(placeholder: "Pseudo", controller: displayNameController, focusNode: displayNameFocusNode, onChanged: (_) => setSheetState(() {})),
                SizedBox(height: 12),
                Field(placeholder: "Bio", controller: bioController, focusNode: bioFocusNode, maxLines: 5, onChanged: (_) => setSheetState(() {})),

                SizedBox(height: 12),

                CustomText(
                  "Ces informations seront visibles par tous les utilisateurs de Messagyre.",
                  style: AppStyles.secondaryText(context).copyWith(fontSize: 17),
                  padding: .symmetric(horizontal: 20),
                ),
              ],
            );
          },
        );
      },
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

  Widget? buildTrailing() {
    return changesMade
        ? Button.icon(
            context,
            isLoading: isUploading,
            icon: HugeIcons.strokeRoundedTick02,
            color: AppColors.accent,
            onTap: () async {
              setState(() => isUploading = true);
              bool success = await network.uploadProfile(account.displayName, profile, imagePath: chosenPicturePath);
              setState(() => isUploading = false);

              if (!context.mounted) return;
              final mountedContext = context;

              showCupertinoDialog(
                context: mountedContext,
                builder: (_) => Dialog(
                  title: success ? "Profil actualisé!" : "Erreur",
                  content: success ? "Le profil a été mis a jour avec succès!" : "Une erreur s'est produite, veuillez reéssayer.\n\n(POST Multipart)",
                  options: success ? {"OK": () => Navigator.pop(context)} : null,
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

  @override
  Widget build(BuildContext context) {
    isBlocked = globals.blockedUsers.contains(account.username);

    return Page.scrollable(
      context,
      spacing: 16,
      topBar: editMode
          ? TopBar.form(context, title: "Votre profil", onCloseConfirmed: changesMade ? () => Navigator.pop(context) : null, trailing: buildTrailing())
          : TopBar.tab(context, title: account.username),

      children: [
        RoundContainer(
          child: Column(
            spacing: 10,
            children: [
              Row(
                spacing: 16,
                children: [
                  SizedBox(
                    height: 60,
                    child: ProfilePictureDisplay(
                      accountUsername: chosenPicturePath != null ? null : account.username,
                      picturePath: chosenPicturePath,
                      isBlocked: isBlocked,
                    ),
                  ),
                  Column(
                    spacing: 2,
                    crossAxisAlignment: .start,
                    children: [
                      Text(account.displayName ?? account.defaultDisplayName, style: TextStyle(fontSize: 24, fontWeight: .w600)),

                      Row(
                        spacing: 6,
                        children: [
                          CustomIcon(icon: HugeIcons.strokeRoundedUserAccount, size: 18, color: AppColors.secondaryText.adaptTo(context)),
                          CustomText("${account.username} - ${account.classOrRole ?? "*Nouveau compte*"}", style: AppStyles.secondaryText(context)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(),

              CustomText(
                profile["Bio"] ?? "Pas de biographie",
                style: TextStyle(fontSize: 16, color: profile["Bio"] == null ? AppColors.secondaryText.adaptTo(context) : null),
              ),
              Text(
                "Membre depuis :  ${formatDate(account.creationDate ?? DateTime.now())}.",
                style: TextStyle(fontSize: 16, color: AppColors.tertiaryText.adaptTo(context)),
              ),
            ],
          ),
        ),


        if (isBlocked)
          ListSection(
            children: [
              ListTile.simple(
                context,
                title: "Débloquer cet utilisateur",
                icon: HugeIcons.strokeRoundedUserUnlock01,
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

        if (account.username != globals.username && !widget.openedFromChat)
          ListSection(
            children: [
              ListTile.simple(
                context,
                title: "Envoyer un message",
                icon: HugeIcons.strokeRoundedSent,
                onTap: () => Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => ChatPage(username: account.username))),
              ),
            ],
          ),

        if (chat != null)
          ListSection(
            title: "Conversation",
            children: [
              ListTile.simple(
                context,
                title: chat!.isPinned ? "Désépingler" : "Épingler",
                icon: chat!.isPinned ? HugeIcons.strokeRoundedPinOff : HugeIcons.strokeRoundedPin,
                onTap: () {
                  if (chat == null) return;

                  chat!.isPinned = !chat!.isPinned;
                  database.chats.save(chat!);
                  setState(() {});
                },
              ),
              ListTile.simple(
                context,
                title: "Effacer les messages",
                icon: HugeIcons.strokeRoundedDelete01,
                isDestructive: true,
                buildChevron: false,
                onTap: () => deleteMessages(),
              ),
              ListTile.simple(
                context,
                title: "Supprimer la conversation",
                icon: HugeIcons.strokeRoundedDelete04,
                isDestructive: true,
                buildChevron: false,
                onTap: () => deleteChat(),
              ),
            ],
          ),

        if (account.username == globals.username) ...[
          ListSection(
            children: [
              ListTile.simple(context, title: "Modifier le profil", icon: HugeIcons.strokeRoundedPencilEdit02, onTap: () => changeProfile()),
              ListTile.simple(context, title: "Changer de photo de profil", icon: HugeIcons.strokeRoundedUserCircle, onTap: () => changeProfilePicture()),
            ],
          ),

          ListSection(
            children: [
              ListTile.simple(
                context,
                title: "Supprimer le compte",
                icon: HugeIcons.strokeRoundedUserRemove01,
                isDestructive: true,
                buildChevron: false,
                onTap: () => deleteAccount(),
              ),
            ],
          ),
        ],

        if (account.username != globals.username) ...[
          ListSection(
            title: "Utilisateur",
            children: [
              if (!isBlocked)
                ListTile.simple(
                  context,
                  title: "Bloquer",
                  icon: HugeIcons.strokeRoundedUserBlock01,
                  isDestructive: true,
                  buildChevron: false,
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

              ListTile.simple(
                context,
                title: "Signaler",
                icon: HugeIcons.strokeRoundedFlag02,
                isDestructive: true,
                buildChevron: false,
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
    );
  }
}
