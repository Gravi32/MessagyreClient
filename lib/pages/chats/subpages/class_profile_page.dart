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
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/pages/chats/widgets/attachment_actions.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
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
import 'package:messagyre_client/utility/widgets/basics/tag.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

/// A class chat's page, like a group's info: its picture and description (chosen by its delegates), its delegates
/// (elected by the class), the photos, files and assignments sent in it, and its members.
class ClassProfilePage extends StatefulWidget {
  final String className;
  const ClassProfilePage({super.key, required this.className});

  @override
  State<ClassProfilePage> createState() => _ClassProfilePageState();
}

class _ClassProfilePageState extends State<ClassProfilePage> {
  final classes = ClassService();
  final globals = GlobalsService();
  final network = NetworkService();
  final database = DatabaseService();

  String get className => widget.className;
  String get chatId => ClassService.chatIdOf(className);

  /// Still in this class this school year (an old class chat stays readable, without its members)
  bool get isMember => classes.current.value?.name == className;

  bool isSavingPicture = false;
  String? openingProfileOf;

  @override
  void initState() {
    super.initState();
    if (isMember) classes.loadMembers(force: true);
  }

  void showError(String message) {
    if (!mounted) return;
    showCupertinoDialog(context: context, builder: (_) => Dialog(title: AppStrings.errorTitle, content: message));
  }

  // #region -> Picture and description (delegates)

  Future<void> changePicture() async {
    final hasPicture = classes.group.value?.pictureUrl != null;
    final choice = await ActionSheet.show<String>(
      context,
      title: "Photo de la classe",
      actions: [
        const SheetAction("Prendre une photo", icon: AppIcons.camera, value: "camera"),
        const SheetAction("Choisir dans la galerie", icon: HugeIcons.strokeRoundedAlbum02, value: "gallery"),
        if (hasPicture) const SheetAction("Supprimer la photo", icon: AppIcons.delete, value: "delete", isDestructive: true),
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
    final error = await classes.setPicture(path);
    if (!mounted) return;
    setState(() => isSavingPicture = false);
    if (error != null) showError(error);
  }

  Future<void> editDescription() async {
    final controller = TextEditingController(text: classes.group.value?.description ?? "");
    final saved = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ModalPopup(
          topBar: TopBar.form(
            context,
            title: "Description",
            trailing: Button.icon(context, icon: AppIcons.done, onTap: () => Navigator.pop(context, true)),
          ),
          child: Field(
            controller: controller,
            placeholder: "Quelques mots sur la classe, une règle de la conversation…",
            minLines: 3,
            maxLines: 6,
            autofocus: true,
          ),
        ),
      ),
    );
    if (saved != true || !mounted) return;
    if (controller.text.trim().length > 300) {
      showError("La description est trop longue : ${controller.text.trim().length} caractères sur 300 au plus.");
      return;
    }
    final error = await classes.setDescription(controller.text.trim().isEmpty ? null : controller.text.trim());
    if (error != null) showError(error);
  }

  // #endregion

  // #region -> Votes

  String roleName(String role) => role == ClassService.delegateRole ? "Délégué·e" : "Vice-délégué·e";

  Future<void> vote(String role) async {
    final group = classes.group.value;
    final members = classes.members.value;
    if (members.isEmpty) return;

    final chosen = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => _MemberPicker(
        title: "Votre vote : ${roleName(role).toLowerCase()}",
        hint: "Votez pour la personne que la classe a choisie (ou que vous voulez). Vous pouvez changer votre vote quand vous voulez.",
        members: members,
        selected: group?.myVotes[role],
        votesOf: (username) => group?.votesFor(role, username) ?? 0,
        allowNone: group?.myVotes[role] != null,
      ),
    );
    if (chosen == null || !mounted) return;

    final error = await classes.vote(role, chosen.isEmpty ? null : chosen);
    if (error != null) showError(error);
  }

  // #endregion

  Future<void> openMember(String username) async {
    if (openingProfileOf != null) return;
    setState(() => openingProfileOf = username);
    final account = await network.getAccount(username);
    if (!mounted) return;
    setState(() => openingProfileOf = null);
    if (account == null) {
      showError("Le profil de $username n'a pas pu être chargé. Vérifiez votre connexion internet.");
      return;
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfilePage(account)));
  }

  // #region -> Widgets

  Widget buildHeader(ClassGroup? group, int memberCount) {
    final canEdit = isMember && classes.amDelegate;
    final description = group?.description;

    return Column(
      spacing: AppSpacing.xs,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: canEdit && !isSavingPicture ? changePicture : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(opacity: isSavingPicture ? .5 : 1, child: ClassAvatar(className: className, size: 104)),
              if (isSavingPicture) const Positioned.fill(child: Center(child: GymnaseLoader(size: 26, color: AppColors.white))),
              if (canEdit)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondaryBackground.adaptTo(context),
                      border: Border.all(color: AppColors.background.adaptTo(context), width: 3),
                    ),
                    child: AppIcon(icon: AppIcons.camera, size: 16, color: AppColors.text.adaptTo(context)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(ClassService.chatTitleOf(className), textAlign: TextAlign.center, style: AppStyles.header(context)),
        Text(
          isMember ? "${AppStrings.classMembersCount(memberCount)} · ${SchoolClass.yearLabel(DateTime.now())}" : AppStrings.classChatLeft,
          textAlign: TextAlign.center,
          style: AppStyles.subheadline(context),
        ),
        if (isMember && (description != null || canEdit))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.m),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              pressedOpacity: .6,
              onPressed: canEdit ? editDescription : null,
              child: RoundContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.card),
                watermark: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.s,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text("DESCRIPTION", style: AppStyles.overline(context))),
                        if (canEdit) AppIcon(icon: AppIcons.edit, size: 16, color: AppColors.tertiaryText.adaptTo(context)),
                      ],
                    ),
                    CustomText(
                      description ?? "Ajoutez quelques mots pour la classe : vous êtes délégué·e, vous seul·e et le vice pouvez la changer.",
                      style: AppStyles.primaryText(context).copyWith(color: description == null ? AppColors.tertiaryText.adaptTo(context) : null, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  ListTile buildRoleTile(ClassGroup? group, String role) {
    final holder = role == ClassService.delegateRole ? group?.delegate : group?.viceDelegate;
    final myVote = group?.myVotes[role];

    return ListTile(
      onTap: classes.members.value.isEmpty ? null : () => vote(role),
      leading: SizedBox.square(
        dimension: 36,
        child: holder != null
            ? ProfilePictureDisplay(accountUsername: holder)
            : Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tertiaryBackground.adaptTo(context)),
                alignment: Alignment.center,
                child: AppIcon(icon: HugeIcons.strokeRoundedCrown, size: 18, color: AppColors.tertiaryText.adaptTo(context)),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 1,
        children: [
          Text(roleName(role).toUpperCase(), style: AppStyles.overline(context)),
          Text(
            holder != null ? classes.displayNameOf(holder) : "Pas encore élu·e",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.primaryText(context).copyWith(color: holder == null ? AppColors.tertiaryText.adaptTo(context) : null),
          ),
          Text(
            myVote == null ? "Touchez pour voter" : "Votre vote : ${myVote == globals.username ? "vous" : classes.displayNameOf(myVote)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.footnote(context).copyWith(color: myVote == null ? AppColors.tint.adaptTo(context) : null),
          ),
        ],
      ),
    );
  }

  /// The photos and files sent in the class chat that are on this phone
  Widget? buildMedia(List<Message> messages) {
    final photos = messages.where((m) => !m.isDeleted && m.attachment?.isImage == true && m.localPath != null && m.transfer.name == "ready").toList();
    final files = messages.where((m) => !m.isDeleted && m.attachment != null && m.attachment!.isImage == false).toList();
    if (photos.isEmpty && files.isEmpty) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s + 2,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text("Médias, fichiers", style: AppStyles.section(context)),
        ),
        if (photos.isNotEmpty)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s),
              itemBuilder: (context, index) {
                final message = photos[index];
                return GestureDetector(
                  onTap: () => openAttachment(context, message),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.s),
                    child: Image.file(
                      File(message.localPath!),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      cacheWidth: 288,
                      errorBuilder: (_, _, _) => Container(width: 96, height: 96, color: AppColors.tertiaryBackground.adaptTo(context)),
                    ),
                  ),
                );
              },
            ),
          ),
        if (files.isNotEmpty)
          ListSection(
            children: [
              for (final message in files.take(20))
                ListTile(
                  onTap: () => openAttachment(context, message),
                  leading: ListTile.iconTile(context, icon: message.attachment!.icon),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.attachment!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppStyles.primaryText(context)),
                      Text(
                        [AppStrings.fileSize(message.attachment!.size), formatDate(message.sentAt)].join(" · "),
                        style: AppStyles.footnote(context),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// The assignments sent in the class chat, the coming ones first
  Widget? buildAssignments(List<Message> messages) {
    final today = DateTime.now().dateOnly();
    final sent = messages.where((m) => !m.isDeleted && m.sharedAssignment != null && !m.sharedAssignment!.dueDate.isBefore(today)).toList()
      ..sort((a, b) => a.sharedAssignment!.dueDate.compareTo(b.sharedAssignment!.dueDate));
    if (sent.isEmpty) return null;

    final mine = database.assignments.getAll();
    return ListSection(
      title: "Devoirs envoyés",
      footer: "Touchez un devoir pour l'ajouter aux vôtres.",
      children: [
        for (final message in sent.take(20))
          ListTile(
            onTap: () async {
              await showCupertinoSheet(
                context: context,
                builder: (context) => NewAssignmentPage(prefill: message.sharedAssignment),
                enableDrag: false,
              );
              if (mounted) setState(() {});
            },
            leading: ListTile.iconTile(context, icon: AppIcons.assignments),
            trailing: mine.any(message.sharedAssignment!.isSameAs) ? AppIcon(icon: AppIcons.done, size: 18, color: AppColors.tertiaryText.adaptTo(context)) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.sharedAssignment!.headline, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppStyles.primaryText(context)),
                Text(
                  [?message.sharedAssignment!.subjectName, formatDate(message.sharedAssignment!.dueDate)].join(" · "),
                  style: AppStyles.footnote(context),
                ),
              ],
            ),
          ),
      ],
    );
  }

  ListSection buildMembers(ClassGroup? group, List<ClassMember> members) {
    // The delegates first, then by name
    int rank(ClassMember member) => member.username == group?.delegate ? 0 : (member.username == group?.viceDelegate ? 1 : 2);
    final sorted = [...members]
      ..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : classes.displayNameOf(a.username).toLowerCase().compareTo(classes.displayNameOf(b.username).toLowerCase());
      });

    return ListSection(
      title: AppStrings.classMembersCount(members.length).capitalize(),
      footer: AppStrings.classMembersHint.replaceAll("*", ""),
      children: [
        for (final member in sorted)
          ListTile(
            isLoading: openingProfileOf == member.username,
            onTap: member.username == globals.username ? null : () => openMember(member.username),
            buildChevron: member.username != globals.username,
            leading: SizedBox.square(
              dimension: AppSizes.avatarSmall,
              child: ProfilePictureDisplay(accountUsername: member.username, pictureURL: member.pictureUrl),
            ),
            trailing: member.username == group?.delegate
                ? const Tag(text: "DÉLÉGUÉ·E", color: AppColors.accent)
                : member.username == group?.viceDelegate
                ? const Tag(text: "VICE", color: AppColors.indigo)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.username == globals.username ? "${classes.displayNameOf(member.username)} (vous)" : classes.displayNameOf(member.username),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.primaryText(context),
                ),
                Text(member.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppStyles.footnote(context)),
              ],
            ),
          ),
      ],
    );
  }

  // #endregion

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ClassMember>>(
      valueListenable: classes.members,
      builder: (context, members, _) => ValueListenableBuilder<ClassGroup?>(
        valueListenable: classes.group,
        builder: (context, group, _) {
          final messages = database.messages.ofChat(chatId);
          final media = buildMedia(messages);
          final assignments = buildAssignments(messages);

          return Page.scrollable(
            context,
            spacing: AppSpacing.xl,
            topBar: TopBar.tab(context, title: ClassService.chatTitleOf(className)),
            children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page), child: buildHeader(group, members.length)),
              if (isMember)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                  child: ListSection(
                    title: "Délégués",
                    footer:
                        "Élus par la classe : chacun vote pour un·e délégué·e et un·e vice, et peut changer son vote. Ils peuvent changer la photo et la description de la classe, et modifier ou supprimer les devoirs partagés.",
                    children: [buildRoleTile(group, ClassService.delegateRole), buildRoleTile(group, ClassService.viceRole)],
                  ),
                ),
              if (media != null) Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page), child: media),
              if (assignments != null) Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page), child: assignments),
              if (isMember && members.isEmpty) const Center(child: GymnaseLoader(size: 22)),
              if (isMember && members.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page), child: buildMembers(group, members)),
              if (!isMember)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                  child: CustomText(AppStrings.classChatReadOnly, textAlign: TextAlign.center, style: AppStyles.secondaryText(context)),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

/// A list of the class's members to choose one (a vote). Pops the chosen username, "" for "no vote", null if closed.
class _MemberPicker extends StatelessWidget {
  final String title;
  final String hint;
  final List<ClassMember> members;
  final String? selected;
  final int Function(String username) votesOf;
  final bool allowNone;

  const _MemberPicker({required this.title, required this.hint, required this.members, required this.selected, required this.votesOf, required this.allowNone});

  @override
  Widget build(BuildContext context) {
    final classes = ClassService();
    final globals = GlobalsService();
    final sorted = [...members]..sort((a, b) => classes.displayNameOf(a.username).toLowerCase().compareTo(classes.displayNameOf(b.username).toLowerCase()));

    return ModalPopup(
      topBar: TopBar.form(context, title: title),
      height: MediaQuery.sizeOf(context).height * .55,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: Text(hint, style: AppStyles.footnote(context)),
          ),
          if (allowNone)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              minimumSize: Size.zero,
              onPressed: () => Navigator.pop(context, ""),
              child: Row(
                spacing: AppSpacing.m,
                children: [
                  SizedBox.square(
                    dimension: AppSizes.avatarSmall,
                    child: Center(child: AppIcon(icon: AppIcons.close, size: 18, color: AppColors.red)),
                  ),
                  Text("Retirer mon vote", style: AppStyles.primaryText(context).copyWith(color: AppColors.red)),
                ],
              ),
            ),
          for (final member in sorted)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
              minimumSize: Size.zero,
              onPressed: () => Navigator.pop(context, member.username),
              child: Row(
                spacing: AppSpacing.m,
                children: [
                  SizedBox.square(
                    dimension: AppSizes.avatarSmall,
                    child: ProfilePictureDisplay(accountUsername: member.username, pictureURL: member.pictureUrl),
                  ),
                  Expanded(
                    child: Text(
                      member.username == globals.username ? "${classes.displayNameOf(member.username)} (vous)" : classes.displayNameOf(member.username),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.primaryText(context).copyWith(fontWeight: member.username == selected ? FontWeight.w700 : null),
                    ),
                  ),
                  if (votesOf(member.username) > 0)
                    Text("${votesOf(member.username)} vote${votesOf(member.username) > 1 ? "s" : ""}", style: AppStyles.footnote(context)),
                  if (member.username == selected) AppIcon(icon: AppIcons.done, size: 18, strokeWidth: 2.2, color: AppColors.tint.adaptTo(context)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
