import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/pages/chats/widgets/attachment_actions.dart';
import 'package:messagyre_client/pages/chats/widgets/message_bubble.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/services/chat_service.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/graphics/blurred_container.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

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

  /// The members of the class chat
  Future<void> showMembers() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => _ClassMembersSheet(className: className!, isMember: canWrite),
    );
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
    showCupertinoDialog(context: context, builder: (_) => Dialog(title: AppStrings.errorTitle, content: message));
  }

  Future<void> showAttachmentMenu() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!isClassChat && chats.encryptionStateOf(username).value == EncryptionState.unavailable) {
      showError(AppStrings.encryptionOff);
      return;
    }

    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          _sheetAction(context, AppStrings.attachPhoto, AppIcons.photo, "gallery"),
          _sheetAction(context, AppStrings.attachCamera, AppIcons.camera, "camera"),
          _sheetAction(context, AppStrings.attachFile, AppIcons.file, "file"),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
      ),
    );
    if (choice == null || !mounted) return;

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
      showError(e.code.contains("denied") || e.code.contains("access") ? AppStrings.permissionDenied : AppStrings.genericError);
    } catch (e) {
      debugPrint("[Chat] Sending an attachment failed: $e");
      showError(AppStrings.genericError);
    } finally {
      if (mounted) setState(() => isPickingAttachment = false);
    }
  }

  static bool _isImageName(String name) => RegExp(r'\.(jpe?g|png|webp|gif)$', caseSensitive: false).hasMatch(name);

  Widget _sheetAction(BuildContext context, String text, List<List<dynamic>> icon, String value, {bool isDestructive = false}) {
    final color = isDestructive ? AppColors.red : AppColors.accent;
    return CupertinoActionSheetAction(
      isDestructiveAction: isDestructive,
      onPressed: () => Navigator.pop(context, value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: TextStyle(color: color)),
          HugeIcon(icon: icon, size: 22, color: color),
        ],
      ),
    );
  }

  Future<void> showMessageMenu(Message message) async {
    if (message.uuid == _supportWelcomeUuid) return;
    HapticFeedback.mediumImpact();
    FocusManager.instance.primaryFocus?.unfocus();

    final text = message.displayText.trim();
    final hasFile = message.hasAttachment && message.localPath != null && message.transfer == TransferState.ready;

    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        message: message.isDeleted
            ? null
            : Text(text.isNotEmpty ? text : message.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
        actions: [
          if (message.isOwned && message.isFailed) _sheetAction(context, AppStrings.retry, AppIcons.retry, "retry"),
          if (!message.isDeleted && text.isNotEmpty) _sheetAction(context, AppStrings.copy, AppIcons.copy, "copy"),
          if (!message.isDeleted && hasFile) _sheetAction(context, AppStrings.saveToDevice, AppIcons.save, "save"),
          _sheetAction(context, AppStrings.delete, AppIcons.delete, "delete", isDestructive: true),
          if (!message.isOwned && !message.isDeleted) _sheetAction(context, AppStrings.report, AppIcons.report, "report", isDestructive: true),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
      ),
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
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(AppStrings.reportTitle, style: TextStyle(fontSize: 14)),
        message: const Text(AppStrings.reportContent, style: TextStyle(fontSize: 14)),
        actions: [
          _sheetAction(context, AppStrings.report, AppIcons.report, "report", isDestructive: true),
          _sheetAction(context, AppStrings.reportAndBlock(message.senderUsername ?? username), AppIcons.block, "block", isDestructive: true),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
      ),
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
    final background = AppColors.background.adaptTo(context);

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.page, topPadding + AppSpacing.xs, AppSpacing.page, AppSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [background.withTransparency(0), background.withTransparency(.92), background], stops: const [0, .35, .6]),
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
            isClassChat ? const ClassAvatar(size: AppSizes.avatarSmall) : ProfilePictureDisplay(accountUsername: username, isBlocked: isBlocked),
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
                        if (isBlocked) HugeIcon(icon: AppIcons.blocked, size: 16, color: AppColors.secondaryText.adaptTo(context)),
                        Flexible(child: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppStyles.strongText(context).copyWith(fontSize: 18))),
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
        BlurredContainer(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.m),
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              const ClassAvatar(size: AppSizes.avatarLarge),
              const SizedBox(height: AppSpacing.s),
              Text(displayName, textAlign: TextAlign.center, style: AppStyles.header(context)),
              Text(classSubtitle, style: AppStyles.secondaryText(context)),
              const SizedBox(height: AppSpacing.s),
              _Notice(icon: AppIcons.info, text: AppStrings.classChatHint, color: tertiary),
            ],
          ),
        ),
        BlurredContainer(
          width: double.infinity,
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
        BlurredContainer(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.m),
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              SizedBox(height: AppSizes.avatarLarge, child: ProfilePictureDisplay(accountUsername: username)),
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
          builder: (context, state, _) => BlurredContainer(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.l),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m - 2, horizontal: AppSpacing.l),
            child: switch (state) {
              EncryptionState.available => _Notice(icon: AppIcons.encrypted, text: AppStrings.encryptionOn(displayName), color: AppColors.tertiaryText.adaptTo(context)),
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
      child: BlurredContainer(
        margin: const EdgeInsets.only(top: AppSpacing.l, bottom: AppSpacing.m),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1, horizontal: AppSpacing.m),
        borderRadius: BorderRadius.circular(AppRadius.s),
        child: Text(text, style: AppStyles.footnote(context).copyWith(fontWeight: FontWeight.w600, color: AppColors.secondaryText.adaptTo(context))),
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
            final joinsNext = newer != null && newer.sentAt.isSameDayAs(message.sentAt) && newer.isOwned == message.isOwned && newer.senderUsername == message.senderUsername;
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
    final background = AppColors.background.adaptTo(context);
    final canSend = fieldController.text.trim().isNotEmpty;

    if (!canWrite) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.l, AppSpacing.page, bottomPadding + AppSpacing.l),
        color: background,
        child: Text(AppStrings.classChatReadOnly, textAlign: TextAlign.center, style: AppStyles.footnote(context)),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xl, AppSpacing.page, bottomPadding + AppSpacing.s),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [background.withTransparency(0), background], stops: const [0, .35]),
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
                    ? const CupertinoActivityIndicator()
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
                  color: canSend ? AppColors.accent : null,
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
                  child: SizedBox.square(dimension: AppSizes.iconButton, child: Button.icon(context, icon: AppIcons.scrollDown, onTap: scrollDown)),
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
            child: Padding(padding: const EdgeInsets.only(right: AppSpacing.xs + 2), child: HugeIcon(icon: icon, size: 16, color: color)),
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

/// Who is in a class chat (everybody who chose this class for this school year)
class _ClassMembersSheet extends StatelessWidget {
  final String className;
  final bool isMember;
  const _ClassMembersSheet({required this.className, required this.isMember});

  @override
  Widget build(BuildContext context) {
    final classes = ClassService();
    final globals = GlobalsService();

    return CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7),
          child: ValueListenableBuilder(
            valueListenable: classes.members,
            builder: (context, members, _) => ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.l),
              children: [
                Row(
                  spacing: AppSpacing.m,
                  children: [
                    const ClassAvatar(size: AppSizes.avatarSmall),
                    Expanded(child: Text(ClassService.chatTitleOf(className), style: AppStyles.header(context))),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                CustomText(isMember ? AppStrings.classMembersHint : AppStrings.classChatReadOnly, style: AppStyles.secondaryText(context)),
                const SizedBox(height: AppSpacing.m),
                if (isMember && members.isEmpty) const Padding(padding: EdgeInsets.all(AppSpacing.l), child: CupertinoActivityIndicator()),
                if (isMember)
                  for (final member in members)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        spacing: AppSpacing.m,
                        children: [
                          SizedBox.square(dimension: AppSizes.avatarSmall, child: ProfilePictureDisplay(accountUsername: member.username, pictureURL: member.pictureUrl)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.username == globals.username ? "${classes.displayNameOf(member.username)} (vous)" : classes.displayNameOf(member.username),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppStyles.primaryText(context),
                                ),
                                Text(member.username, style: AppStyles.footnote(context)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
