import 'dart:io';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/pages/chats/subpages/new_group_page.dart';
import 'package:messagyre_client/pages/chats/widgets/attachment_actions.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/group_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:messagyre_client/utility/widgets/basics/action_sheet.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/modal_popup.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/segmented_control.dart';
import 'package:messagyre_client/utility/widgets/basics/tag.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/chat_avatar.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

enum _Tab { members, media, files }

/// A group chat's page: its picture, name and description (changed by its admins), its members, and the photos and
/// files sent in it.
class GroupProfilePage extends StatefulWidget {
  final String groupId;

  const GroupProfilePage({super.key, required this.groupId});

  @override
  State<GroupProfilePage> createState() => _GroupProfilePageState();
}

class _GroupProfilePageState extends State<GroupProfilePage> {
  final groups = GroupService();
  final globals = GlobalsService();
  final network = NetworkService();
  final database = DatabaseService();

  _Tab tab = _Tab.members;
  bool isSavingPicture = false;
  String? busyMember;

  String get chatId => GroupService.chatIdOf(widget.groupId);

  @override
  void initState() {
    super.initState();
    groups.refresh();
  }

  void showError(String message) {
    if (!mounted) return;
    showCupertinoDialog(context: context, builder: (_) => Dialog(title: AppStrings.errorTitle, content: message));
  }

  // #region -> Admin actions

  Future<void> changePicture(ChatGroup group) async {
    final choice = await ActionSheet.show<String>(
      context,
      title: "Photo du groupe",
      actions: [
        const SheetAction("Prendre une photo", icon: AppIcons.camera, value: "camera"),
        const SheetAction("Choisir dans la galerie", icon: HugeIcons.strokeRoundedAlbum02, value: "gallery"),
        if (group.pictureUrl != null) const SheetAction("Supprimer la photo", icon: AppIcons.delete, value: "delete", isDestructive: true),
      ],
    );
    if (choice == null || !mounted) return;

    String? path;
    if (choice != "delete") {
      try {
        final picked = await ImagePicker().pickImage(source: choice == "camera" ? ImageSource.camera : ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
        if (picked == null) return;
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [IOSUiSettings(title: "Retailler l'image", aspectRatioLockEnabled: true)],
        );
        if (cropped == null) return;
        path = cropped.path;
      } catch (e) {
        showError(AppStrings.describe(e));
        return;
      }
    }

    setState(() => isSavingPicture = true);
    final error = await groups.setPicture(group.id, path);
    if (!mounted) return;
    setState(() => isSavingPicture = false);
    if (error != null) showError(error);
  }

  /// Edits the name or the description in a small sheet; returns the text, null when closed
  Future<String?> editText({required String title, required String initial, required String placeholder, bool multiline = false}) {
    final controller = TextEditingController(text: initial);
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ModalPopup(
          topBar: TopBar.form(
            context,
            title: title,
            trailing: Button.icon(context, icon: AppIcons.done, onTap: () => Navigator.pop(context, controller.text.trim())),
          ),
          child: Field(controller: controller, placeholder: placeholder, minLines: multiline ? 3 : 1, maxLines: multiline ? 6 : 1, autofocus: true),
        ),
      ),
    );
  }

  Future<void> rename(ChatGroup group) async {
    final name = await editText(title: "Nom du groupe", initial: group.name, placeholder: "Nom du groupe");
    if (name == null || name == group.name || !mounted) return;
    final result = await groups.rename(group.id, name);
    if (result.error != null) showError(result.error!);
  }

  Future<void> editDescription(ChatGroup group) async {
    final text = await editText(
      title: "Description",
      initial: group.description ?? "",
      placeholder: "De quoi parle le groupe, ses règles…",
      multiline: true,
    );
    if (text == null || !mounted) return;
    final result = await groups.describe(group.id, text.isEmpty ? null : text);
    if (result.error != null) showError(result.error!);
  }

  Future<void> addMembers(ChatGroup group) async {
    await Navigator.push(context, CupertinoPageRoute(builder: (_) => AddGroupMembersPage(group: group)));
  }

  Future<void> openMember(GroupMember member, ChatGroup group) async {
    final iAmAdmin = group.isAdmin(globals.username);
    final isMe = member.username == globals.username;
    if (isMe) return;

    final choice = await ActionSheet.show<String>(
      context,
      title: member.name,
      actions: [
        const SheetAction("Voir le profil", icon: AppIcons.profile, value: "profile"),
        if (iAmAdmin && !member.isAdmin) const SheetAction("Nommer administrateur·rice", icon: HugeIcons.strokeRoundedCrown, value: "admin"),
        if (iAmAdmin && member.isAdmin) const SheetAction("Retirer le rôle d'admin", icon: HugeIcons.strokeRoundedCrown, value: "unadmin"),
        if (iAmAdmin) const SheetAction("Retirer du groupe", icon: AppIcons.delete, value: "remove", isDestructive: true),
      ],
    );
    if (choice == null || !mounted) return;

    if (choice == "profile") {
      setState(() => busyMember = member.username);
      final account = await network.getAccount(member.username);
      if (!mounted) return;
      setState(() => busyMember = null);
      if (account == null) return showError("Le profil de ${member.name} n'a pas pu être chargé. Vérifiez votre connexion internet.");
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfilePage(account)));
      return;
    }

    if (choice == "remove") {
      var confirmed = false;
      await showCupertinoDialog(
        context: context,
        builder: (context) => Dialog(
          content: "Retirer *${member.name}* du groupe ?",
          isDestructive: true,
          optionsDirection: .horizontal,
          options: {AppStrings.cancel: () {}, "Retirer": () => confirmed = true},
        ),
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => busyMember = member.username);
    final error = switch (choice) {
      "admin" => (await groups.setAdmin(group.id, member.username, true)).error,
      "unadmin" => (await groups.setAdmin(group.id, member.username, false)).error,
      _ => await groups.removeMember(group.id, member.username),
    };
    if (!mounted) return;
    setState(() => busyMember = null);
    if (error != null) showError(error);
  }

  Future<void> leave(ChatGroup group) async {
    final isLastAdmin = group.isAdmin(globals.username) && group.members.where((member) => member.isAdmin).length == 1 && group.members.length > 1;
    var confirmed = false;
    await showCupertinoDialog(
      context: context,
      builder: (context) => Dialog(
        title: "Quitter le groupe ?",
        isDestructive: true,
        optionsDirection: .horizontal,
        content: isLastAdmin
            ? "Vous êtes le seul administrateur : la personne arrivée la première dans le groupe le deviendra. Vous ne recevrez plus ses messages."
            : "Vous ne recevrez plus ses messages. La conversation reste sur votre téléphone.",
        options: {AppStrings.cancel: () {}, "Quitter": () => confirmed = true},
      ),
    );
    if (!confirmed || !mounted) return;
    final error = await groups.removeMember(group.id, globals.username!);
    if (error != null) return showError(error);
    if (mounted) Navigator.pop(context);
  }

  // #endregion

  // #region -> Widgets

  Widget buildHeader(ChatGroup group) {
    final canEdit = group.isAdmin(globals.username);
    return Column(
      spacing: AppSpacing.xs,
      children: [
        CupertinoButton(
          padding: .zero,
          minimumSize: .zero,
          onPressed: canEdit && !isSavingPicture ? () => changePicture(group) : null,
          child: Stack(
            clipBehavior: .none,
            children: [
              Opacity(opacity: isSavingPicture ? .5 : 1, child: GroupAvatar(groupId: group.id, size: 104)),
              if (isSavingPicture) const Positioned.fill(child: Center(child: GymnaseLoader(size: 26, color: AppColors.white))),
              if (canEdit)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: .center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondaryBackground.adaptTo(context),
                      border: .all(color: AppColors.background.adaptTo(context), width: 3),
                    ),
                    child: AppIcon(icon: AppIcons.camera, size: 16, color: AppColors.text.adaptTo(context)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        CupertinoButton(
          padding: .zero,
          minimumSize: .zero,
          pressedOpacity: .6,
          onPressed: canEdit ? () => rename(group) : null,
          child: Row(
            mainAxisSize: .min,
            spacing: AppSpacing.xs,
            children: [
              Flexible(child: Text(group.name, textAlign: .center, style: AppStyles.header(context))),
              if (canEdit) AppIcon(icon: AppIcons.edit, size: 16, color: AppColors.tertiaryText.adaptTo(context)),
            ],
          ),
        ),
        Text("Groupe · ${group.members.length} membre${group.members.length > 1 ? "s" : ""}", style: AppStyles.subheadline(context)),
        if (group.description != null || canEdit)
          Padding(
            padding: const .only(top: AppSpacing.m),
            child: CupertinoButton(
              padding: .zero,
              minimumSize: .zero,
              pressedOpacity: .6,
              onPressed: canEdit ? () => editDescription(group) : null,
              child: RoundContainer(
                width: double.infinity,
                padding: const .all(AppSpacing.card),
                watermark: true,
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: AppSpacing.s,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text("DESCRIPTION", style: AppStyles.overline(context))),
                        if (canEdit) AppIcon(icon: AppIcons.edit, size: 16, color: AppColors.tertiaryText.adaptTo(context)),
                      ],
                    ),
                    CustomText(
                      group.description ?? "Ajoutez quelques mots sur le groupe.",
                      style: AppStyles.primaryText(context).copyWith(color: group.description == null ? AppColors.tertiaryText.adaptTo(context) : null, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildMembers(ChatGroup group) {
    final iAmAdmin = group.isAdmin(globals.username);
    final sorted = [...group.members]
      ..sort((a, b) {
        if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.l,
      children: [
        ListSection(
          footer: iAmAdmin
              ? "Touchez un membre pour le nommer administrateur·rice ou le retirer du groupe."
              : "Les administrateurs ajoutent et retirent les membres et changent le nom et la photo du groupe.",
          children: [
            if (iAmAdmin)
              ListTile(
                onTap: () => addMembers(group),
                leading: ListTile.iconTile(context, icon: HugeIcons.strokeRoundedUserAdd01, color: AppColors.accent),
                child: Text("Ajouter des membres", style: AppStyles.primaryText(context).copyWith(color: AppColors.tint.adaptTo(context))),
              ),
            for (final member in sorted)
              ListTile(
                isLoading: busyMember == member.username,
                onTap: member.username == globals.username ? null : () => openMember(member, group),
                buildChevron: false,
                leading: SizedBox.square(
                  dimension: AppSizes.avatarSmall,
                  child: ProfilePictureDisplay(accountUsername: member.username, pictureURL: member.pictureUrl),
                ),
                trailing: member.isAdmin ? const Tag(text: "ADMIN", color: AppColors.accent) : null,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(member.username == globals.username ? "${member.name} (vous)" : member.name, maxLines: 1, overflow: .ellipsis, style: AppStyles.primaryText(context)),
                    Text(member.username, maxLines: 1, overflow: .ellipsis, style: AppStyles.footnote(context)),
                  ],
                ),
              ),
          ],
        ),
        ListSection(
          children: [ListTile.simple(context, icon: HugeIcons.strokeRoundedLogout03, title: "Quitter le groupe", isDestructive: true, buildChevron: false, onTap: () => leave(group))],
        ),
      ],
    );
  }

  Widget buildMedia(List<Message> messages) {
    final photos = messages.where((m) => !m.isDeleted && m.attachment?.isImage == true && m.localPath != null && m.transfer.name == "ready").toList();
    if (photos.isEmpty) return _Empty(icon: HugeIcons.strokeRoundedImage02, text: "Les photos envoyées dans le groupe apparaîtront ici.");
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: .zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final message = photos[index];
        return _Appear(
          delay: index * 25,
          child: GestureDetector(
            onTap: () => openAttachment(context, message),
            child: ClipRRect(
              borderRadius: .circular(AppRadius.s),
              child: Image.file(
                File(message.localPath!),
                fit: BoxFit.cover,
                cacheWidth: 300,
                errorBuilder: (_, _, _) => Container(color: AppColors.tertiaryBackground.adaptTo(context)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildFiles(List<Message> messages) {
    final files = messages.where((m) => !m.isDeleted && m.attachment != null && m.attachment!.isImage == false).toList();
    if (files.isEmpty) return _Empty(icon: HugeIcons.strokeRoundedFile02, text: "Les fichiers envoyés dans le groupe apparaîtront ici.");
    return ListSection(
      children: [
        for (final message in files.take(100))
          ListTile(
            onTap: () => openAttachment(context, message),
            leading: ListTile.iconTile(context, icon: message.attachment!.icon),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(message.attachment!.name, maxLines: 1, overflow: .ellipsis, style: AppStyles.primaryText(context)),
                Text([AppStrings.fileSize(message.attachment!.size), formatDate(message.sentAt)].join(" · "), style: AppStyles.footnote(context)),
              ],
            ),
          ),
      ],
    );
  }

  // #endregion

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, ChatGroup>>(
      valueListenable: groups.groups,
      builder: (context, all, _) {
        final group = all[widget.groupId];
        if (group == null) {
          return Page.scrollable(
            context,
            topBar: TopBar.tab(context, title: "Groupe"),
            children: [
              Padding(
                padding: const .all(AppSpacing.page),
                child: Text("Vous ne faites plus partie de ce groupe. Ses anciens messages restent sur votre téléphone.", textAlign: .center, style: AppStyles.secondaryText(context)),
              ),
            ],
          );
        }

        final messages = database.messages.ofChat(chatId);
        return Page.scrollable(
          context,
          spacing: AppSpacing.xl,
          topBar: TopBar.tab(context, title: group.name),
          children: [
            Padding(padding: const .symmetric(horizontal: AppSpacing.page), child: buildHeader(group)),
            Padding(
              padding: const .symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: .stretch,
                spacing: AppSpacing.l,
                children: [
                  SegmentedControl<_Tab>(
                    options: const {"Membres": _Tab.members, "Médias": _Tab.media, "Fichiers": _Tab.files},
                    onTap: (value) => setState(() => tab = value),
                  ),
                  AnimatedSwitcher(
                    duration: AppDurations.normal,
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(animation), child: child),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(tab),
                      child: switch (tab) {
                        _Tab.members => buildMembers(group),
                        _Tab.media => buildMedia(messages),
                        _Tab.files => buildFiles(messages),
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String text;

  const _Empty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(vertical: AppSpacing.xl),
      child: Column(
        spacing: AppSpacing.s,
        children: [
          AppIcon(icon: icon, size: 32, color: AppColors.quaternaryText.adaptTo(context)),
          Text(text, textAlign: .center, style: AppStyles.secondaryText(context)),
        ],
      ),
    );
  }
}

/// Fades and rises in, after [delay] milliseconds (the photos of the grid one after the other)
class _Appear extends StatelessWidget {
  final int delay;
  final Widget child;

  const _Appear({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + delay.clamp(0, 400)),
      curve: Interval((delay.clamp(0, 400) / (300 + delay.clamp(0, 400))), 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) => Opacity(opacity: value, child: Transform.scale(scale: .92 + .08 * value, child: child)),
      child: child,
    );
  }
}
