import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/assignments/assignment_share.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/database/models/messages/message_reply.dart';
import 'package:messagyre_client/pages/chats/subpages/class_profile_page.dart';
import 'package:messagyre_client/pages/chats/widgets/attachment_actions.dart';
import 'package:messagyre_client/pages/chats/widgets/message_bubble.dart';
import 'package:messagyre_client/pages/settings/subpages/admin_page.dart' show adminUsernames;
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/services/chat_service.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/global_chat_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/action_sheet.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/modal_popup.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class ChatPage extends StatefulWidget {
  final String username;

  const ChatPage({super.key, required this.username});

  @override
  State<StatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final chats = ChatService();
  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  late final String username = widget.username;
  late String displayName = database.chats.getByUsername(username)?.displayUsername ?? Account.getDefaultDisplayName(username);
  late final currentWallpaper = globals.persistent.getString("CurrentWallpaper");

  final scrollController = ScrollController();
  final fieldController = TextEditingController();
  final fieldFocusNode = FocusNode();
  StreamSubscription<Message>? incomingSubscription;

  /// Messages that slide in when they appear (new ones only, not the history)
  final Set<String> animatedUuids = {};

  /// The message being answered (shown above the field), null when writing a normal message
  Message? replyingTo;

  /// The bubbles on screen, to scroll to the message an answer quotes
  final Map<String, GlobalKey> bubbleKeys = {};

  /// The message just scrolled to, lit up for a moment
  String? highlightedUuid;
  Timer? highlightTimer;

  /// The messages as last shown (newest first), to find the one a quote points to
  List<Message> shownMessages = const [];

  Account? account;
  bool isLoadingProfile = false;
  bool showScrollDownButton = false;
  bool isPickingAttachment = false;

  final classes = ClassService();

  /// A class chat ("#1M05"): no profile, a message's sender is shown above it
  late final String? className = ClassService.classOfChat(username);
  bool get isClassChat => className != null;

  /// The global chat ("@general"): everyone, not encrypted, moderated (see GlobalChatService)
  late final bool isGlobalChat = GlobalChatService.isGlobal(username);
  final global = GlobalChatService();
  StreamSubscription? rejectionSubscription;

  /// A chat of several people: who wrote each message is shown above it
  bool get isShared => isClassChat || isGlobalChat;

  /// The global chat's photos touched to be seen (blurred until then)
  final Set<String> revealedPhotos = {};

  /// Still in this class (a class of an earlier school year stays readable), not kept out of the global chat
  bool get canWrite => isGlobalChat ? global.status.value.cantWrite == null : (!isClassChat || classes.current.value?.name == className);

  bool get isSupport => username == "support.messagyre";
  bool get isBlocked => !isClassChat && globals.blockedUsers.contains(username);

  // #region -> Lifecycle

  @override
  void initState() {
    super.initState();

    globals.openChatUsername = username;
    chats.initialize();
    classes.current.addListener(onClassChanged);
    classes.members.addListener(onClassChanged);

    incomingSubscription = chats.incomingMessages.stream.where((m) => m.chatUsername == username).listen((message) {
      if (!mounted) return;
      setState(() => animatedUuids.add(message.uuid));
      if (!showScrollDownButton) scrollDown();
    });

    fieldController.addListener(onFieldChanged);
    scrollController.addListener(onScroll);
    globals.blockedUsersNotifier.addListener(onBlockedUsersChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => chats.markRead(username));

    if (isGlobalChat) {
      displayName = GlobalChatService.title;
      global.status.addListener(onClassChanged);
      unawaited(global.refreshStatus());
      // A message refused by the server (spam, sanction, a photo refused): says why
      rejectionSubscription = global.rejections.stream.listen((rejection) => showError(rejection.reason));
      return;
    }

    if (isClassChat) {
      displayName = ClassService.chatTitleOf(className!);
      if (canWrite) classes.loadMembers(force: true);
      return;
    }

    chats.publicKeyOf(username, refresh: true);
    network.getAccount(username).then((result) async {
      if (result == null || !mounted) return;
      account = result;
      final name = result.displayName ?? Account.getDefaultDisplayName(username);
      setState(() => displayName = name);

      // Only an existing conversation is updated: opening a profile doesn't create an empty one
      final chat = database.chats.getByUsername(username);
      if (chat != null && chat.displayUsername != result.displayName) {
        chat.displayUsername = result.displayName;
        await database.chats.save(chat);
      }
    });
  }

  @override
  void dispose() {
    if (globals.openChatUsername == username) globals.openChatUsername = null;
    incomingSubscription?.cancel();
    classes.current.removeListener(onClassChanged);
    classes.members.removeListener(onClassChanged);
    global.status.removeListener(onClassChanged);
    rejectionSubscription?.cancel();
    globals.blockedUsersNotifier.removeListener(onBlockedUsersChanged);
    fieldController.removeListener(onFieldChanged);
    scrollController.removeListener(onScroll);
    highlightTimer?.cancel();
    fieldController.dispose();
    fieldFocusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void onFieldChanged() => setState(() {});
  void onBlockedUsersChanged() => setState(() {});
  void onClassChanged() {
    if (mounted) setState(() {});
  }

  void onScroll() {
    // The list is reversed: offset 0 is the newest message
    final shouldShow = scrollController.offset > 400;
    if (shouldShow != showScrollDownButton) setState(() => showScrollDownButton = shouldShow);
  }

  void scrollDown() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(0, duration: AppDurations.normal, curve: Curves.easeOut);
  }

  // #endregion

  // #region -> Actions

  Future<void> openProfile() async {
    if (isGlobalChat) return showGlobalInfo();
    if (isClassChat) return showMembers();
    if (account == null) {
      setState(() => isLoadingProfile = true);
      account = await network.getAccount(username);
      if (!mounted) return;
      setState(() => isLoadingProfile = false);
    }
    if (account != null && mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfilePage(account!, openedFromChat: true)));
    }
  }

  /// The global chat's rules, and its notifications on or off
  Future<void> showGlobalInfo() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final muted = global.status.value.isMuted;
    final choice = await ActionSheet.show<String>(
      context,
      title: GlobalChatService.title,
      message: GlobalChatService.rules.replaceAll("*", ""),
      actions: [
        SheetAction(
          muted ? "Activer les notifications" : "Rendre silencieuse",
          icon: muted ? AppIcons.notificationsOn : AppIcons.muted,
          value: "mute",
        ),
      ],
    );
    if (choice != "mute" || !mounted) return;
    final error = await global.setMuted(!muted);
    if (error != null) showError(error);
  }

  /// The class chat's page: picture, description, delegates, media, members
  Future<void> showMembers() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Navigator.push(context, CupertinoPageRoute(builder: (context) => ClassProfilePage(className: className!)));
    if (mounted) setState(() {});
  }

  /// Sends one of my coming assignments: the others can add it to theirs
  Future<void> pickAssignment() async {
    final chosen = await showCupertinoModalPopup<Assignment>(context: context, builder: (context) => const _AssignmentPicker());
    if (chosen == null || !mounted) return;
    await chats.sendAssignment(username, AssignmentShare.of(chosen));
    scrollDown();
  }

  void sendText() {
    final text = fieldController.text;
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    fieldController.clear();
    final reply = replyOf(replyingTo);
    setState(() => replyingTo = null);
    chats.sendText(username, text, replyTo: reply);
    scrollDown();
  }

  /// Who wrote a message, as a username (mine for my messages)
  String authorOf(Message message) => message.isOwned ? (globals.username ?? "") : (message.senderUsername ?? username);

  /// The name shown above a quoted message
  String nameOf(String author) {
    if (author == globals.username) return "Vous";
    if (isGlobalChat) return global.displayNameOf(author);
    if (isClassChat) return classes.displayNameOf(author);
    return author == username ? displayName : Account.getDefaultDisplayName(author);
  }

  MessageReply? replyOf(Message? message) {
    if (message == null) return null;
    final text = message.displayText.trim().isNotEmpty ? message.displayText : message.content;
    return MessageReply.of(uuid: message.uuid, sender: authorOf(message), text: text);
  }

  /// Answers [message]: it shows above the field, and the keyboard opens
  void startReply(Message message) {
    if (!canWrite || message.isDeleted || message.uuid == _supportWelcomeUuid) return;
    HapticFeedback.selectionClick();
    setState(() => replyingTo = message);
    fieldFocusNode.requestFocus();
  }

  /// Scrolls to the message a quote points to and lights it up (when it is still in the conversation)
  Future<void> scrollToMessage(String uuid) async {
    final index = shownMessages.indexWhere((message) => message.uuid == uuid);
    if (index < 0) {
      showError("Ce message n'est plus dans la conversation : il a peut-être été supprimé.");
      return;
    }
    // Not built yet (too far up): jumps close to it first, then to it exactly
    for (var attempt = 0; attempt < 6 && bubbleKeys[uuid]?.currentContext == null; attempt++) {
      if (!scrollController.hasClients) return;
      final position = scrollController.position;
      final target = (position.pixels + position.viewportDimension * .8).clamp(0.0, position.maxScrollExtent);
      if (target == position.pixels) break;
      scrollController.jumpTo(target);
      await WidgetsBinding.instance.endOfFrame;
    }
    final context = bubbleKeys[uuid]?.currentContext;
    if (context == null || !context.mounted) return;
    await Scrollable.ensureVisible(context, alignment: .5, duration: AppDurations.normal, curve: Curves.easeOutCubic);
    if (!mounted) return;
    setState(() => highlightedUuid = uuid);
    highlightTimer?.cancel();
    highlightTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => highlightedUuid = null);
    });
  }

  void showError(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (_) => Dialog(title: AppStrings.errorTitle, content: message),
    );
  }

  Future<void> showAttachmentMenu() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!isShared && chats.encryptionStateOf(username).value == EncryptionState.unavailable) {
      showError(AppStrings.encryptionOff);
      return;
    }

    final choice = await ActionSheet.show<String>(
      context,
      message: isGlobalChat ? "Seules les photos sont acceptées ici : elles s'affichent floutées jusqu'à ce qu'on les touche." : null,
      actions: [
        const SheetAction(AppStrings.attachPhoto, icon: AppIcons.photo, value: "gallery"),
        const SheetAction(AppStrings.attachCamera, icon: AppIcons.camera, value: "camera"),
        if (!isGlobalChat) const SheetAction(AppStrings.attachFile, icon: AppIcons.file, value: "file"),
        if (!isGlobalChat) const SheetAction("Devoir", icon: AppIcons.assignments, value: "assignment"),
      ],
    );
    if (choice == null || !mounted) return;
    if (choice == "assignment") return pickAssignment();

    setState(() => isPickingAttachment = true);
    try {
      final picker = ImagePicker();
      final picked = <(String path, String name, AttachmentKind kind)>[];

      // Photos are resized and compressed by the system before being encrypted: light for the server and the network
      switch (choice) {
        case "gallery":
          final images = await picker.pickMultiImage(maxWidth: 2048, maxHeight: 2048, imageQuality: 80, limit: isGlobalChat ? 1 : 10);
          picked.addAll(images.map((image) => (image.path, image.name, AttachmentKind.image)));
        case "camera":
          final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 2048, maxHeight: 2048, imageQuality: 80);
          if (image != null) picked.add((image.path, image.name, AttachmentKind.image));
        case "file":
          final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: Attachment.allowedExtensions.toList());
          final file = result?.files.single;
          if (file?.path != null) picked.add((file!.path!, file.name, _isImageName(file.name) ? AttachmentKind.image : AttachmentKind.file));
      }

      // The text being typed goes with the first photo or file
      String? caption = fieldController.text.trim().isEmpty ? null : fieldController.text.trim();
      if (picked.isNotEmpty && caption != null) fieldController.clear();

      var reply = picked.isEmpty ? null : replyOf(replyingTo);
      if (reply != null) setState(() => replyingTo = null);
      for (final (path, name, kind) in picked) {
        await chats.sendAttachment(username, path: path, name: name, kind: kind, caption: caption, replyTo: reply);
        caption = null;
        reply = null;
      }
      if (picked.isNotEmpty) scrollDown();
    } on AttachmentException catch (e) {
      showError(e.message);
    } on PlatformException catch (e) {
      debugPrint("[Chat] Picking an attachment failed: $e");
      showError(AppStrings.describe(e));
    } catch (e) {
      debugPrint("[Chat] Sending an attachment failed: $e");
      showError(AppStrings.describe(e));
    } finally {
      if (mounted) setState(() => isPickingAttachment = false);
    }
  }

  static bool _isImageName(String name) => RegExp(r'\.(jpe?g|png|webp|gif)$', caseSensitive: false).hasMatch(name);

  Future<void> showMessageMenu(Message message) async {
    if (message.uuid == _supportWelcomeUuid) return;
    HapticFeedback.mediumImpact();
    FocusManager.instance.primaryFocus?.unfocus();

    final text = message.displayText.trim();
    final hasFile = message.hasAttachment && message.localPath != null && message.transfer == TransferState.ready;

    final choice = await ActionSheet.show<String>(
      context,
      message: message.isDeleted ? null : (text.isNotEmpty ? text : message.content),
      actions: [
        if (canWrite && !message.isDeleted) const SheetAction("Répondre", icon: AppIcons.reply, value: "reply"),
        if (message.isOwned && message.isFailed) const SheetAction(AppStrings.retry, icon: AppIcons.retry, value: "retry"),
        if (!message.isDeleted && text.isNotEmpty) const SheetAction(AppStrings.copy, icon: AppIcons.copy, value: "copy"),
        if (!message.isDeleted && hasFile) const SheetAction(AppStrings.saveToDevice, icon: AppIcons.save, value: "save"),
        const SheetAction(AppStrings.delete, icon: AppIcons.delete, value: "delete", isDestructive: true),
        if (isGlobalChat && !message.isOwned && !message.isDeleted && adminUsernames.contains(globals.username))
          const SheetAction("Supprimer pour tout le monde (admin)", icon: AppIcons.delete, value: "moderate", isDestructive: true),
        if (!message.isOwned && !message.isDeleted) const SheetAction(AppStrings.report, icon: AppIcons.report, value: "report", isDestructive: true),
      ],
    );
    if (!mounted) return;

    switch (choice) {
      case "reply":
        startReply(message);
      case "retry":
        chats.retry(message);
      case "copy":
        Clipboard.setData(ClipboardData(text: text));
      case "save":
        saveAttachment(context, message);
      case "delete":
        confirmDeletion(message);
      case "moderate":
        global.deleteForEveryone(message);
      case "report":
        showReportSheet(message);
    }
  }

  void confirmDeletion(Message message) {
    // Only my messages that the server accepted can be deleted for the other person too
    final canDeleteForEveryone = message.isOwned && !message.isDeleted && message.status != MessageStatus.Sending && message.status != MessageStatus.Failed;

    showCupertinoDialog(
      context: context,
      builder: (context) => Dialog(
        title: AppStrings.deleteMessageTitle,
        content: AppStrings.deleteMessageContent,
        isDestructive: true,
        options: {
          AppStrings.deleteForMe: () => chats.deleteForMe(message),
          if (canDeleteForEveryone) AppStrings.deleteForEveryone: () => chats.deleteForEveryone(message),
          AppStrings.cancel: () {},
        },
      ),
    );
  }

  Future<void> showReportSheet(Message message) async {
    if (isGlobalChat) return reportInGlobalChat(message);
    final choice = await ActionSheet.show<String>(
      context,
      title: AppStrings.reportTitle,
      message: AppStrings.reportContent,
      actions: [
        const SheetAction(AppStrings.report, icon: AppIcons.report, value: "report", isDestructive: true),
        SheetAction(AppStrings.reportAndBlock(message.senderUsername ?? username), icon: AppIcons.block, value: "block", isDestructive: true),
      ],
    );
    if (choice == null) return;

    final sent = await chats.report(message, reason: choice == "block" ? "Blocked" : null);
    if (choice == "block") await globals.blockUser(message.senderUsername ?? username);
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (_) => Dialog(title: sent ? AppStrings.thanks : AppStrings.errorTitle, content: sent ? AppStrings.reportSent : AppStrings.reportFailed),
    );
  }

  /// In the global chat: 3 people reporting someone stop them writing for 3 days, 5 ban them
  Future<void> reportInGlobalChat(Message message) async {
    final author = message.senderUsername ?? "";
    final choice = await ActionSheet.show<String>(
      context,
      title: AppStrings.reportTitle,
      message: "Signalez un message inapproprié (insultes, harcèlement, spam, photo choquante). Signalée par 3 personnes, une personne ne peut plus écrire ici pendant 3 jours ; par 5, elle est exclue. Un message signalé par 3 personnes disparaît.",
      actions: [
        const SheetAction(AppStrings.report, icon: AppIcons.report, value: "report", isDestructive: true),
        SheetAction(AppStrings.reportAndBlock(author), icon: AppIcons.block, value: "block", isDestructive: true),
      ],
    );
    if (choice == null) return;
    final result = await global.report(message, reason: choice == "block" ? "Blocked" : null);
    if (choice == "block" && result.sent && author.isNotEmpty) await globals.blockUser(author);
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (_) => Dialog(title: result.sent ? AppStrings.thanks : AppStrings.errorTitle, content: result.text),
    );
  }

  void onBubbleTap(Message message) {
    // The global chat's photos: the first touch shows it, the next ones open it
    if (isGlobalChat && message.attachment?.isImage == true && !message.isDeleted && !revealedPhotos.contains(message.uuid)) {
      setState(() => revealedPhotos.add(message.uuid));
      return;
    }
    if (message.hasAttachment && !message.isDeleted) {
      openAttachment(context, message);
    } else if (message.isOwned && message.isFailed) {
      showMessageMenu(message);
    }
  }

  // #endregion

  // #region -> Widgets

  static const _supportWelcomeUuid = "support-welcome";

  /// The support's first message is shown but never stored
  Message get _supportWelcome => Message.custom(
    uuid: _supportWelcomeUuid,
    chatUsername: username,
    content: AppStrings.supportWelcome,
    sentAt: DateTime.now(),
    isOwned: false,
    status: MessageStatus.Read,
  );

  Widget buildTopBar() {
    final topPadding = MediaQuery.paddingOf(context).top;

    // A solid bar (no blur, no fade): the messages scroll under it without ever showing through
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.page, topPadding + AppSpacing.xs, AppSpacing.page, AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground.adaptTo(context),
        border: Border(bottom: BorderSide(color: AppColors.separator.adaptTo(context), width: .5)),
      ),
      child: SizedBox(
        height: AppSizes.iconButton,
        child: Row(
          spacing: AppSpacing.m,
          children: [
            Button.icon(
              context,
              icon: AppIcons.back,
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).pop();
              },
            ),
            isGlobalChat
                ? const GlobalChatAvatar(size: AppSizes.avatarSmall)
                : isClassChat
                ? ClassAvatar(className: className!, size: AppSizes.avatarSmall)
                : ProfilePictureDisplay(accountUsername: username, isBlocked: isBlocked),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: openProfile,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: AppSpacing.xs + 2,
                      children: [
                        if (isBlocked) AppIcon(icon: AppIcons.blocked, size: 16, color: AppColors.secondaryText.adaptTo(context)),
                        Flexible(
                          child: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppStyles.strongText(context)),
                        ),
                      ],
                    ),
                    Text(
                      isGlobalChat ? (global.status.value.isMuted ? "Ouverte à tous · silencieuse" : "Ouverte à tous · non chiffrée") : (isClassChat ? classSubtitle : username),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.footnote(context),
                    ),
                  ],
                ),
              ),
            ),
            if (isLoadingProfile) GymnaseLoader(size: 18),
            Button.icon(context, icon: isGlobalChat ? (global.status.value.isMuted ? AppIcons.muted : AppIcons.info) : (isClassChat ? AppIcons.members : AppIcons.profile), onTap: openProfile),
          ],
        ),
      ),
    );
  }

  String get classSubtitle {
    if (!canWrite) return AppStrings.classChatLeft;
    final count = classes.members.value.length;
    return count == 0 ? AppStrings.classChatSubtitle : AppStrings.classMembersCount(count);
  }

  /// At the top of a class chat: what it is, who can read it
  Widget buildClassHeader() {
    final tertiary = AppColors.tertiaryText.adaptTo(context);
    return Column(
      children: [
        RoundContainer(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.m),
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              ClassAvatar(className: className!, size: AppSizes.avatarLarge),
              const SizedBox(height: AppSpacing.s),
              Text(displayName, textAlign: TextAlign.center, style: AppStyles.header(context)),
              Text(classSubtitle, style: AppStyles.secondaryText(context)),
              const SizedBox(height: AppSpacing.s),
              _Notice(icon: AppIcons.info, text: AppStrings.classChatHint, color: tertiary),
            ],
          ),
        ),
        RoundContainer(
          width: double.infinity,
          borderRadius: AppRadius.m,
          margin: const EdgeInsets.only(bottom: AppSpacing.l),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m - 2, horizontal: AppSpacing.l),
          child: _Notice(icon: AppIcons.encrypted, text: AppStrings.classEncryption, color: tertiary),
        ),
      ],
    );
  }

  /// At the top of the conversation: who it is with and whether it is encrypted
  /// At the top of the global chat: what it is and its rules
  Widget buildGlobalHeader() {
    final tertiary = AppColors.tertiaryText.adaptTo(context);
    return Column(
      children: [
        RoundContainer(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.m),
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              const GlobalChatAvatar(size: AppSizes.avatarLarge),
              const SizedBox(height: AppSpacing.s),
              Text(GlobalChatService.title, textAlign: TextAlign.center, style: AppStyles.header(context)),
              Text("Tous les utilisateurs de Messagyre", style: AppStyles.secondaryText(context)),
              const SizedBox(height: AppSpacing.s),
              _Notice(icon: AppIcons.info, text: GlobalChatService.rules, color: tertiary),
            ],
          ),
        ),
        RoundContainer(
          width: double.infinity,
          borderRadius: AppRadius.m,
          margin: const EdgeInsets.only(bottom: AppSpacing.l),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m - 2, horizontal: AppSpacing.l),
          child: _Notice(icon: AppIcons.notEncrypted, text: "Cette conversation n'est *pas chiffrée de bout en bout* : ne partagez rien de privé.", color: AppColors.orange),
        ),
      ],
    );
  }

  Widget buildHeader() {
    if (isGlobalChat) return buildGlobalHeader();
    if (isClassChat) return buildClassHeader();
    return Column(
      children: [
        RoundContainer(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.m),
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              SizedBox(
                height: AppSizes.avatarLarge,
                child: ProfilePictureDisplay(accountUsername: username),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(displayName, textAlign: TextAlign.center, style: AppStyles.header(context)),
              Text(username, style: AppStyles.secondaryText(context)),
              if (!isSupport) ...[
                const SizedBox(height: AppSpacing.s),
                _Notice(icon: AppIcons.info, text: AppStrings.blockHint, color: AppColors.tertiaryText.adaptTo(context)),
              ],
            ],
          ),
        ),
        ValueListenableBuilder(
          valueListenable: chats.encryptionStateOf(username),
          builder: (context, state, _) => RoundContainer(
            width: double.infinity,
            borderRadius: AppRadius.m,
            margin: const EdgeInsets.only(bottom: AppSpacing.l),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m - 2, horizontal: AppSpacing.l),
            child: switch (state) {
              EncryptionState.available => _Notice(
                icon: AppIcons.encrypted,
                text: AppStrings.encryptionOn(displayName),
                color: AppColors.tertiaryText.adaptTo(context),
              ),
              EncryptionState.unavailable => _Notice(icon: AppIcons.notEncrypted, text: AppStrings.encryptionOff, color: AppColors.orange),
              EncryptionState.unknown => _Notice(icon: AppIcons.encrypted, text: AppStrings.encryptionUnknown, color: AppColors.tertiaryText.adaptTo(context)),
            },
          ),
        ),
      ],
    );
  }

  Widget buildDateChip(DateTime date) {
    final now = DateTime.now();
    final text = date.isSameDayAs(now)
        ? AppStrings.today
        : date.isSameDayAs(now.subtract(const Duration(days: 1)))
        ? AppStrings.yesterday
        : formatDate(date).capitalize();

    return Center(
      child: RoundContainer(
        margin: const EdgeInsets.only(top: AppSpacing.l, bottom: AppSpacing.m),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1, horizontal: AppSpacing.m),
        borderRadius: AppRadius.s,
        child: Text(
          text,
          style: AppStyles.footnote(context).copyWith(fontWeight: FontWeight.w600, color: AppColors.secondaryText.adaptTo(context)),
        ),
      ),
    );
  }

  Widget buildMessages() {
    final padding = MediaQuery.paddingOf(context);

    return StreamBuilder<List<Message>>(
      stream: database.messages.watchChat(username),
      builder: (context, snapshot) {
        var messages = snapshot.data ?? database.messages.ofChat(username).reversed.toList();
        if (messages.isEmpty && isSupport) messages = [_supportWelcome];
        shownMessages = messages;

        return ListView.builder(
          controller: scrollController,
          reverse: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          // Room for the top bar above the oldest message; the input bar is outside of the list
          padding: EdgeInsets.fromLTRB(AppSpacing.page, padding.top + AppSizes.topBar + AppSpacing.s, AppSpacing.page, AppSpacing.s),
          itemCount: messages.length + 1,
          itemBuilder: (context, index) {
            if (index == messages.length) return buildHeader();

            // Newest first: "older" is index + 1
            final message = messages[index];
            final older = index + 1 < messages.length ? messages[index + 1] : null;
            final newer = index > 0 ? messages[index - 1] : null;

            final startsDay = older == null || !older.sentAt.isSameDayAs(message.sentAt);
            final joinsPrevious = older != null && !startsDay && older.isOwned == message.isOwned && older.senderUsername == message.senderUsername;
            final joinsNext =
                newer != null && newer.sentAt.isSameDayAs(message.sentAt) && newer.isOwned == message.isOwned && newer.senderUsername == message.senderUsername;
            final sender = message.senderUsername;

            Widget bubble = MessageBubble(
              key: ValueKey(message.uuid),
              bubbleKey: bubbleKeys.putIfAbsent(message.uuid, GlobalKey.new),
              message: message,
              joinsPrevious: joinsPrevious,
              joinsNext: joinsNext,
              onTap: onBubbleTap,
              onLongPress: showMessageMenu,
              senderName: sender == null ? null : (isGlobalChat ? global.displayNameOf(sender) : (isClassChat ? classes.displayNameOf(sender) : null)),
              blurPhoto: isGlobalChat && !revealedPhotos.contains(message.uuid),
              replyAuthorName: message.reply == null ? null : nameOf(message.reply!.sender),
              onReplyTap: scrollToMessage,
              isHighlighted: highlightedUuid == message.uuid,
            );

            if (canWrite && !message.isDeleted && message.uuid != _supportWelcomeUuid) {
              bubble = SwipeToReply(towardsLeft: message.isOwned, onReply: () => startReply(message), child: bubble);
            }

            if (animatedUuids.contains(message.uuid)) bubble = _SlideIn(key: ValueKey("in-${message.uuid}"), fromRight: message.isOwned, child: bubble);

            return startsDay ? Column(children: [buildDateChip(message.sentAt), bubble]) : bubble;
          },
        );
      },
    );
  }

  Widget buildInputBar() {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final surface = AppColors.secondaryBackground.adaptTo(context);
    final separator = BorderSide(color: AppColors.separator.adaptTo(context), width: .5);
    final canSend = fieldController.text.trim().isNotEmpty;

    if (!canWrite) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.l, AppSpacing.page, bottomPadding + AppSpacing.l),
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: separator),
        ),
        child: Text(
          isGlobalChat ? (global.status.value.cantWrite ?? "") : AppStrings.classChatReadOnly,
          textAlign: TextAlign.center,
          style: AppStyles.footnote(context),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, bottomPadding + AppSpacing.s),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: separator),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder(
            valueListenable: network.connectionState,
            builder: (context, state, _) => state == ConnectionState.Connected
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: AppSpacing.s,
                      children: [
                        Text(AppStrings.waitingForConnection, style: AppStyles.footnote(context)),
                        GymnaseLoader(size: 16),
                      ],
                    ),
                  ),
          ),
          if (replyingTo != null) buildReplyPreview(replyingTo!),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: AppSpacing.s,
            children: [
              SizedBox.square(
                dimension: AppSizes.compactControl,
                child: isPickingAttachment
                    ? const GymnaseLoader(size: 22)
                    : ValueListenableBuilder(
                        valueListenable: chats.encryptionStateOf(username),
                        builder: (context, state, _) => Button.icon(
                          context,
                          icon: AppIcons.attach,
                          iconColor: !isShared && state == EncryptionState.unavailable ? AppColors.inactive.adaptTo(context) : null,
                          onTap: showAttachmentMenu,
                        ),
                      ),
              ),
              Expanded(
                child: Field(
                  sunken: true,
                  placeholder: AppStrings.messagePlaceholder,
                  controller: fieldController,
                  focusNode: fieldFocusNode,
                  thin: true,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  scrollPhysics: const BouncingScrollPhysics(),
                ),
              ),
              SendButton(enabled: canSend, onTap: sendText),
            ],
          ),
        ],
      ),
    );
  }

  /// Above the field: the message being answered, with a cross to write a normal message instead
  Widget buildReplyPreview(Message message) {
    final reply = replyOf(message)!;
    final color = MessageBubble.colorOf(reply.sender);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        spacing: AppSpacing.s,
        children: [
          AppIcon(icon: AppIcons.reply, size: 20, color: AppColors.tint.adaptTo(context)),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => scrollToMessage(message.uuid),
              child: Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.xs + 2, AppSpacing.m, AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryBackground.adaptTo(context),
                  borderRadius: BorderRadius.circular(AppRadius.s),
                  border: Border(left: BorderSide(color: color, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Réponse à ${nameOf(reply.sender)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.footnote(context).copyWith(fontWeight: FontWeight.w700, color: color),
                    ),
                    Text(reply.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppStyles.subheadline(context)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox.square(
            dimension: AppSizes.compactControl,
            child: Button.icon(context, icon: AppIcons.close, onTap: () => setState(() => replyingTo = null)),
          ),
        ],
      ),
    );
  }

  Widget buildWallpaper() {
    final useDefault = (globals.persistent.getBool("useDefaultWallpaper") ?? true) || currentWallpaper == null;
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        image: useDefault
            ? DecorationImage(
                image: const AssetImage("assets/wallpaper.png"),
                repeat: ImageRepeat.repeat,
                fit: BoxFit.fitWidth,
                opacity: .12,
                colorFilter: isDark ? null : ColorFilter.mode(AppColors.black.withAlpha(200), BlendMode.srcIn),
              )
            : DecorationImage(image: FileImage(File(currentWallpaper!)), fit: BoxFit.cover),
      ),
    );
  }

  // #endregion

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background.adaptTo(context),
      child: Stack(
        children: [
          Positioned.fill(child: buildWallpaper()),
          Positioned.fill(
            child: Column(
              children: [
                Expanded(child: buildMessages()),
                buildInputBar(),
              ],
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: buildTopBar()),
          Positioned(
            right: AppSpacing.page,
            bottom: MediaQuery.paddingOf(context).bottom + AppSizes.compactControl + AppSpacing.xl + AppSpacing.l,
            // Hidden, it must not catch taps: it used to slide (invisible) over the send button and swallow them
            child: IgnorePointer(
              ignoring: !showScrollDownButton,
              child: AnimatedScale(
                scale: showScrollDownButton ? 1 : .6,
                duration: AppDurations.normal,
                child: AnimatedOpacity(
                  opacity: showScrollDownButton ? 1 : 0,
                  duration: AppDurations.normal,
                  child: SizedBox.square(
                    dimension: AppSizes.iconButton,
                    child: Button.icon(context, icon: AppIcons.scrollDown, onTap: scrollDown),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String text;
  final Color color;
  const _Notice({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final style = AppStyles.subheadline(context).copyWith(color: color);
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs + 2),
              child: AppIcon(icon: icon, size: 16, color: color),
            ),
          ),
          ...CustomText.parseSpans(text, style: style),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// A new message slides in from the bottom
class _SlideIn extends StatefulWidget {
  final Widget child;
  final bool fromRight;
  const _SlideIn({super.key, required this.child, required this.fromRight});

  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this, duration: AppDurations.normal)..forward();
  late final animation = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(offset: Offset(0, 30 * (1 - animation.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// My coming assignments, to send one in the chat
class _AssignmentPicker extends StatelessWidget {
  const _AssignmentPicker();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().dateOnly();
    final assignments = DatabaseService().assignments.getAll().where((a) => a.archivedYear == null && !a.dueDate.isBefore(today)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return ModalPopup(
      topBar: TopBar.form(context, title: "Envoyer un devoir"),
      height: assignments.isEmpty ? null : MediaQuery.sizeOf(context).height * .5,
      child: assignments.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
              child: Text(
                "Vous n'avez aucun devoir à venir. Ajoutez-en un dans l'onglet Devoirs, puis envoyez-le ici.",
                textAlign: TextAlign.center,
                style: AppStyles.secondaryText(context),
              ),
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s),
                  child: Text("Les autres pourront l'ajouter à leurs devoirs d'un geste.", style: AppStyles.footnote(context)),
                ),
                for (final assignment in assignments)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                    minimumSize: Size.zero,
                    onPressed: () => Navigator.pop(context, assignment),
                    child: Row(
                      spacing: AppSpacing.m,
                      children: [
                        assignment.subject.value != null
                            ? SubjectBadge(subject: assignment.subject.value, size: 32)
                            : ListTile.iconTile(context, icon: AppIcons.assignments),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AssignmentShare.of(assignment).headline,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppStyles.primaryText(context),
                              ),
                              Text(
                                [?assignment.subject.value?.name, formatDate(assignment.dueDate)].join(" · "),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppStyles.footnote(context),
                              ),
                            ],
                          ),
                        ),
                        AppIcon(icon: AppIcons.send, size: 18, color: AppColors.tint.adaptTo(context)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// The send button: purple when there is something to send, grey otherwise. The paper plane leans up and right:
/// it is drawn a little smaller than the other icons and moved down and left, so that it looks centered.
class SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const SendButton({super.key, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSizes.compactControl,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: enabled ? AppColors.accent : AppColors.tertiaryBackground.adaptTo(context),
            borderRadius: BorderRadius.circular(AppRadius.m),
            boxShadow: enabled ? [BoxShadow(color: Color.lerp(AppColors.accent, AppColors.black, .35)!, offset: const Offset(0, 3))] : null,
          ),
          child: Center(
            child: Transform.translate(
              offset: const Offset(-1.5, 1.5),
              child: AppIcon(icon: AppIcons.send, size: 21, color: enabled ? AppColors.white : AppColors.tertiaryText.adaptTo(context)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drag a message towards the middle of the screen to answer it (like WhatsApp): my messages to the left, the
/// others' to the right. An arrow appears behind it; past [threshold] it answers when let go.
class SwipeToReply extends StatefulWidget {
  final Widget child;
  final bool towardsLeft;
  final VoidCallback onReply;
  const SwipeToReply({super.key, required this.child, required this.towardsLeft, required this.onReply});

  static const threshold = 56.0;
  static const maxOffset = 80.0;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  // Made in initState, never lazily: a bubble never swiped would create it in dispose(), when its context is gone
  late final AnimationController controller;
  double offset = 0;

  /// Where the message was let go: it slides back from there
  double releasedAt = 0;
  bool passed = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: AppDurations.fast)
      ..addListener(() => setState(() => offset = releasedAt * (1 - Curves.easeOut.transform(controller.value))));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onUpdate(DragUpdateDetails details) {
    if (controller.isAnimating) controller.stop();
    final delta = widget.towardsLeft ? -details.delta.dx : details.delta.dx;
    setState(() {
      // Harder to pull past the threshold, like a rubber band
      final resistance = offset > SwipeToReply.threshold ? .35 : 1.0;
      offset = (offset + delta * resistance).clamp(0.0, SwipeToReply.maxOffset);
    });
    if (!passed && offset >= SwipeToReply.threshold) {
      passed = true;
      HapticFeedback.lightImpact();
    } else if (passed && offset < SwipeToReply.threshold) {
      passed = false;
    }
  }

  void onEnd([DragEndDetails? _]) {
    if (passed) widget.onReply();
    passed = false;
    releasedAt = offset;
    controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (offset / SwipeToReply.threshold).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: onUpdate,
      onHorizontalDragEnd: onEnd,
      onHorizontalDragCancel: onEnd,
      child: Stack(
        alignment: widget.towardsLeft ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          if (offset > 0)
            Positioned(
              left: widget.towardsLeft ? null : 4,
              right: widget.towardsLeft ? 4 : null,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: progress,
                  child: Transform.scale(
                    scale: .6 + .4 * progress,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: passed ? AppColors.accent : AppColors.tertiaryBackground.adaptTo(context), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: AppIcon(icon: AppIcons.reply, size: 18, color: passed ? AppColors.white : AppColors.secondaryText.adaptTo(context)),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(offset: Offset(widget.towardsLeft ? -offset : offset, 0), child: widget.child),
        ],
      ),
    );
  }
}
