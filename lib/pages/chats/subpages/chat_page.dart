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
import 'package:messagyre_client/pages/chats/subpages/class_profile_page.dart';
import 'package:messagyre_client/pages/chats/widgets/attachment_actions.dart';
import 'package:messagyre_client/pages/chats/widgets/message_bubble.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/services/chat_service.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/services/database_service.dart';
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

  Account? account;
  bool isLoadingProfile = false;
  bool showScrollDownButton = false;
  bool isPickingAttachment = false;

  final classes = ClassService();

  /// A class chat ("#1M05"): no profile, a message's sender is shown above it
  late final String? className = ClassService.classOfChat(username);
  bool get isClassChat => className != null;

  /// Still in this class (a class of an earlier school year stays readable)
  bool get canWrite => !isClassChat || classes.current.value?.name == className;

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
    globals.blockedUsersNotifier.removeListener(onBlockedUsersChanged);
    fieldController.removeListener(onFieldChanged);
    scrollController.removeListener(onScroll);
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
    chats.sendText(username, text);
    scrollDown();
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

    if (!isClassChat && chats.encryptionStateOf(username).value == EncryptionState.unavailable) {
      showError(AppStrings.encryptionOff);
      return;
    }

    final choice = await ActionSheet.show<String>(
      context,
      actions: const [
        SheetAction(AppStrings.attachPhoto, icon: AppIcons.photo, value: "gallery"),
        SheetAction(AppStrings.attachCamera, icon: AppIcons.camera, value: "camera"),
        SheetAction(AppStrings.attachFile, icon: AppIcons.file, value: "file"),
        SheetAction("Devoir", icon: AppIcons.assignments, value: "assignment"),
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
          final images = await picker.pickMultiImage(maxWidth: 2048, maxHeight: 2048, imageQuality: 80, limit: 10);
          picked.addAll(images.map((image) => (image.path, image.name, AttachmentKind.image)));
        case "camera":
          final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 2048, maxHeight: 2048, imageQuality: 80);
          if (image != null) picked.add((image.path, image.name, AttachmentKind.image));
        case "file":
          final result = await FilePicker.platform.pickFiles();
          final file = result?.files.single;
          if (file?.path != null) picked.add((file!.path!, file.name, _isImageName(file.name) ? AttachmentKind.image : AttachmentKind.file));
      }

      // The text being typed goes with the first photo or file
      String? caption = fieldController.text.trim().isEmpty ? null : fieldController.text.trim();
      if (picked.isNotEmpty && caption != null) fieldController.clear();

      for (final (path, name, kind) in picked) {
        await chats.sendAttachment(username, path: path, name: name, kind: kind, caption: caption);
        caption = null;
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
        if (message.isOwned && message.isFailed) const SheetAction(AppStrings.retry, icon: AppIcons.retry, value: "retry"),
        if (!message.isDeleted && text.isNotEmpty) const SheetAction(AppStrings.copy, icon: AppIcons.copy, value: "copy"),
        if (!message.isDeleted && hasFile) const SheetAction(AppStrings.saveToDevice, icon: AppIcons.save, value: "save"),
        const SheetAction(AppStrings.delete, icon: AppIcons.delete, value: "delete", isDestructive: true),
        if (!message.isOwned && !message.isDeleted) const SheetAction(AppStrings.report, icon: AppIcons.report, value: "report", isDestructive: true),
      ],
    );
    if (!mounted) return;

    switch (choice) {
      case "retry":
        chats.retry(message);
      case "copy":
        Clipboard.setData(ClipboardData(text: text));
      case "save":
        saveAttachment(context, message);
      case "delete":
        confirmDeletion(message);
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

  void onBubbleTap(Message message) {
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
            isClassChat ? ClassAvatar(className: className!, size: AppSizes.avatarSmall) : ProfilePictureDisplay(accountUsername: username, isBlocked: isBlocked),
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
                    Text(isClassChat ? classSubtitle : username, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppStyles.footnote(context)),
                  ],
                ),
              ),
            ),
            if (isLoadingProfile) GymnaseLoader(size: 18),
            Button.icon(context, icon: isClassChat ? AppIcons.members : AppIcons.profile, onTap: openProfile),
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
  Widget buildHeader() {
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
              message: message,
              joinsPrevious: joinsPrevious,
              joinsNext: joinsNext,
              onTap: onBubbleTap,
              onLongPress: showMessageMenu,
              senderName: isClassChat && sender != null ? classes.displayNameOf(sender) : null,
            );

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
        child: Text(AppStrings.classChatReadOnly, textAlign: TextAlign.center, style: AppStyles.footnote(context)),
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
                          iconColor: !isClassChat && state == EncryptionState.unavailable ? AppColors.inactive.adaptTo(context) : null,
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
              SizedBox.square(
                dimension: AppSizes.compactControl,
                child: Button.icon(
                  context,
                  icon: AppIcons.send,
                  transparent: !canSend,
                  color: canSend ? null : AppColors.tertiaryBackground.adaptTo(context),
                  iconColor: canSend ? AppColors.white : AppColors.tertiaryText.adaptTo(context),
                  onTap: canSend ? sendText : null,
                ),
              ),
            ],
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
