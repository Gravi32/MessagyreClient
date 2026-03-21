import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:messagyre_client/utility/widgets/text_chat_bubble.dart';
import 'package:pointycastle/export.dart' show RSAPublicKey;

class ChatPage extends StatefulWidget {
  final String username;

  const ChatPage({super.key, required this.username});

  @override
  State<StatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  late var chatData = database.chats.getByUsername(widget.username) ?? Chat.custom(username: widget.username);
  late var currentWallpaper = globals.persistent.getString("CurrentWallpaper");

  StreamSubscription? _keyboardVisibilitySub;
  StreamSubscription? _messageReceivedSub;
  StreamSubscription? _statusUpdateSub;
  StreamSubscription? _messageDeletionSub;

  final chatScrollController = ScrollController();
  final messageFieldController = TextEditingController();
  final messageFieldFocusNode = FocusNode();
  final Map<String, GlobalKey> bubbleKeys = {};

  double blurAmount = 6;
  // Color barLightColor = AppColors.grey5.withAlpha(150);
  // Color barDarkColor = AppColors.darkBackgroundGray.withAlpha(150);

  RSAPublicKey? recipientPublicKey;
  Account? lastAccountCache;
  bool showScrollDownButton = false;
  Set<String> messagesIdToAnimate = {};
  bool isLoading = false;
  bool isEncryptionAvailable = true;

  void messagesListener(String senderUsername, Message newMessage) {
    if (senderUsername != chatData.username) return;

    messagesIdToAnimate.add(newMessage.uuid);
    network.sendMessageStatusUpdate([newMessage.uuid], chatData.username, MessageStatus.Read);
    scrollDown();
  }

  void messageStatusUpdateListener(String senderUsername, Message messageData) {
    if (senderUsername != chatData.username) return;

    final targetMessage = chatData.messages.firstWhere((message) => message.isOwned && message.uuid == messageData.uuid, orElse: () => Message.empty());

    targetMessage.status = messageData.status;
  }

  void messageDeletionListener(String senderUsername, Message newMessage) {
    if (senderUsername != chatData.username) return;

    final targetMessages = chatData.messages.where((message) => message.uuid == newMessage.uuid);

    for (var message in targetMessages) {
      message.isDeleted = true;
    }
  }

  void scrollDown() {
    if (!mounted) return;
    setState(() => showScrollDownButton = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!chatScrollController.hasClients || chatScrollController.positions.isEmpty) return;

      final max = chatScrollController.position.maxScrollExtent;
      chatScrollController.animateTo(max, duration: Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  void sendMessage(String input) async {
    if (input.trim().isEmpty) return;

    HapticFeedback.mediumImpact();

    try {
      final message = Message.custom(
        content: input,
        sentAt: DateTime.now(),
        isOwned: true,
        status: network.isConnected ? MessageStatus.Sent : MessageStatus.Failed,
      );

      await database.chats.addMessage(chatData, message);

      messagesIdToAnimate.add(message.uuid);

      network.send(message.uuid, widget.username, recipientPublicKey, input);

      if (!mounted) return;

      setState(() {});

      messageFieldController.clear();
      messageFieldFocusNode.requestFocus();
      scrollDown();
    } catch (e, s) {
      debugPrint("[Chat] Message '$input' could not be sent: $e.\nStacktrace: $s");
    }
  }

  void updateAllMessagesToRead() async {
    if (chatData.unreadMessages <= 0) return;
    database.chats.resetUnread(chatData);

    List<String> justReadMessages = [];

    for (var message in chatData.messages) {
      if (!message.isOwned && message.status != MessageStatus.Read) {
        message.status = MessageStatus.Read;
        justReadMessages.add(message.uuid);
      }
    }

    network.sendMessageStatusUpdate(justReadMessages, chatData.username, MessageStatus.Read);
  }

  void showMessageContextMenu(BuildContext context, Message message) {
    HapticFeedback.heavyImpact();
    messageFieldFocusNode.unfocus();

    try {
      final overlay = Overlay.of(context, rootOverlay: true);
      final key = bubbleKeys["${message.id}-${message.isOwned}"];

      final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null) return;

      final bubblePosition = renderBox.localToGlobal(Offset.zero);
      final bubbleHeight = renderBox.size.height;

      late OverlayEntry entry;
      late AnimationController animationController;
      late Animation<double> animation;

      animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

      animation = CurvedAnimation(parent: animationController, curve: Curves.fastOutSlowIn);

      entry = OverlayEntry(
        builder: (context) {
          return GestureDetector(
            onTap: () {
              animationController.reverse().then((_) => entry.remove());
            },
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: animationController.value,
                        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), child: Container(color: Colors.white.withAlpha(5))),
                      ),
                    ),

                    Positioned(
                      top: min(bubblePosition.dy, MediaQuery.of(context).size.height - (160 + bubbleHeight) * animation.value),
                      left: message.isOwned ? null : 10,
                      right: message.isOwned ? 10 : null,
                      child: Column(
                        crossAxisAlignment: message.isOwned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          messageBubble(message, false, false, true),
                          Container(
                            width: 240,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground.adaptTo(context).withAlpha(.8.toByte()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!message.isDeleted) ...[
                                  CupertinoPressable(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: message.content));
                                      animationController.reverse().then((_) => entry.remove());
                                    },
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Copier"),
                                        HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 20, color: AppColors.text.adaptTo(context)),
                                      ],
                                    ),
                                  ),
                                  // Divider(height: 0, thickness: 1, color: AppColors.tertiaryBackground.adaptTo(context)),
                                  // CupertinoPressable(
                                  //   onTap: null,
                                  //   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  //   child: Row(
                                  //     mainAxisSize: MainAxisSize.max,
                                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //     children: [
                                  //       Text("Infos", style: TextStyle(color: AppColors.inactive.adaptTo(context))),
                                  //       HugeIcon(
                                  //         icon: HugeIcons.strokeRoundedInformationSquare,
                                  //         size: 20,
                                  //         color: AppColors.inactive.adaptTo(context),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                ],
                                if (message.isOwned) ...[
                                  Divider(height: 0, thickness: 1, color: AppColors.tertiaryBackground.adaptTo(context)),
                                  CupertinoPressable(
                                    onTap: () {
                                      animationController.reverse().then((_) => entry.remove());
                                      showCupertinoModalPopup(
                                        context: context,
                                        builder: (popupContext) {
                                          return CupertinoActionSheet(
                                            title: Text("Supprimer le message", style: TextStyle(fontSize: 14)),
                                            message: Text(
                                              "Choisissez comment supprimer le message. Ces actions sont irréversibles !",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            actions: [
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  setState(() {
                                                    chatData.messages.remove(message);
                                                  });

                                                  Navigator.pop(popupContext);
                                                },
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text("Supprimer pour vous", style: TextStyle(color: AppColors.red, fontSize: 18)),
                                                    HugeIcon(icon: HugeIcons.strokeRoundedDelete01, size: 20, color: AppColors.red),
                                                  ],
                                                ),
                                              ),

                                              if (!message.isDeleted)
                                                CupertinoActionSheetAction(
                                                  onPressed: () {
                                                    try {
                                                      final savedMessage = chatData.messages.firstWhere((element) => element.uuid == message.uuid);

                                                      database.messages.markAsDeleted(savedMessage);

                                                      network.sendMessageDelete([message.uuid], widget.username);

                                                      setState(() {});
                                                      debugPrint("[Chat] Deletion request sent for ${message.uuid}");
                                                    } catch (e) {
                                                      debugPrint("[Chat] Failed sending deletion request: $e");
                                                    }
                                                    Navigator.pop(popupContext);
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text("Supprimer pour tout le monde", style: TextStyle(color: AppColors.red, fontSize: 18)),
                                                      HugeIcon(icon: HugeIcons.strokeRoundedDelete04, size: 20, color: AppColors.red),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Supprimer", style: TextStyle(color: AppColors.red)),
                                        HugeIcon(icon: HugeIcons.strokeRoundedDelete04, size: 20, color: AppColors.red),
                                      ],
                                    ),
                                  ),
                                ],
                                if (!message.isOwned) ...[
                                  Divider(height: 0, thickness: 1, color: AppColors.tertiaryBackground.adaptTo(context)),

                                  CupertinoPressable(
                                    onTap: () {
                                      animationController.reverse().then((_) => entry.remove());

                                      showCupertinoModalPopup(
                                        context: context,
                                        builder: (popupContext) {
                                          return CupertinoActionSheet(
                                            title: Text("Signaler le message", style: TextStyle(fontSize: 14)),
                                            message: Text(
                                              "Si vous signalez ce message, il sera envoyé aux développeurs de Messagyre pour une évaluation. Si le message est considéré comme inapproprié, des mesures pourront être prises.",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            actions: [
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  Navigator.pop(popupContext);
                                                },
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text("Signaler", style: TextStyle(color: AppColors.red, fontSize: 18)),
                                                    HugeIcon(icon: HugeIcons.strokeRoundedFlag02, size: 20, color: AppColors.red),
                                                  ],
                                                ),
                                              ),

                                              if (!message.isDeleted)
                                                CupertinoActionSheetAction(
                                                  onPressed: () {
                                                    globals.blockUser(chatData.username);
                                                    Navigator.pop(popupContext);
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text("Signaler et bloquer ${chatData.username}", style: TextStyle(color: AppColors.red, fontSize: 18)),
                                                      HugeIcon(icon: HugeIcons.strokeRoundedUserBlock01, size: 20, color: AppColors.red),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Signaler", style: TextStyle(color: AppColors.red)),
                                        HugeIcon(icon: HugeIcons.strokeRoundedFlag02, size: 20, color: AppColors.red),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
      overlay.insert(entry);
      animationController.forward();
    } catch (e, s) {
      debugPrint("Message focus failed: $e. $s");
    }
  }

  void onBlockedUsersChanged() => setState(() {});

  @override
  void initState() {
    super.initState();

    globals.openChatUsername = widget.username;

    network
        .getPublicKey(widget.username)
        .then(
          (result) => setState(() {
            recipientPublicKey = result;
            if (result == null) isEncryptionAvailable = false;
          }),
        );

    if (widget.username == "support.messagyre" && chatData.messages.isEmpty) {
      chatData.messages.add(
        Message.custom(
          content:
              "Salut👋 !\n\nTu as une *question* sur *Messagyre* ou tu as rencontré un *problème* ? Je suis là pour t'aider!\n\nÉcris ici ce dont tu as besoin dans la conversation et je ferai de mon mieux pour te répondre le plus vite possible ! 😄\n\nLe support de Messagyre",
          sentAt: DateTime.now(),
          isOwned: false,
        ),
      );
    }

    network.messageStreamController.stream.listen((record) => messagesListener(record.$1, record.$2));
    network.messageStatusUpdateStreamController.stream.listen((record) => messagesListener(record.$1, record.$2));
    network.messageDeletionStreamController.stream.listen((record) => messagesListener(record.$1, record.$2));

    messageFieldController.addListener(() {
      setState(() {});
    });

    messageFieldFocusNode.addListener(
      () => Future.delayed(const Duration(milliseconds: 400), () {
        scrollDown();
      }),
    );

    _keyboardVisibilitySub = KeyboardVisibilityController().onChange.listen((bool visible) {
      if (visible) {
        scrollDown();
      } else {
        messageFieldFocusNode.unfocus();
      }
    });

    globals.blockedUsersNotifier.removeListener(onBlockedUsersChanged);
    globals.blockedUsersNotifier.addListener(onBlockedUsersChanged);

    chatScrollController.addListener(() {
      final offset = chatScrollController.offset;
      final maxOffset = chatScrollController.position.maxScrollExtent;

      if (offset > maxOffset - 20 && showScrollDownButton) {
        setState(() => showScrollDownButton = false);
      } else if (offset < maxOffset - 100 && !showScrollDownButton) {
        setState(() => showScrollDownButton = true);
      }
    });

    scrollDown();

    network.getAccount(widget.username).then((account) => setState(() => chatData.displayUsername = account?.displayName));
  }

  @override
  void dispose() {
    globals.openChatUsername = null;

    messageFieldController.removeListener(() {});
    messageFieldController.dispose();

    messageFieldFocusNode.removeListener(() {});
    messageFieldFocusNode.dispose();

    chatScrollController.removeListener(() {});
    chatScrollController.dispose();

    _keyboardVisibilitySub?.cancel();
    _messageReceivedSub?.cancel();
    _statusUpdateSub?.cancel();
    _messageDeletionSub?.cancel();

    super.dispose();
  }

  int getUnreadChats() {
    int count = 0;
    for (var chat in database.chats.getAll()) {
      count += chat.unreadMessages;
    }
    return count;
  }

  Widget topBar(BuildContext context) {
    final unreadChats = getUnreadChats();
    final isBlocked = globals.blockedUsers.contains(widget.username);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          //color: adaptiveColor(barLightColor, barDarkColor),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                CupertinoButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(context).pop();
                  },
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 30),
                      if (unreadChats > 0) Text(unreadChats.toString(), style: TextStyle(fontSize: 20, color: AppColors.accent)),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  foregroundDecoration: isBlocked ? BoxDecoration(color: Colors.grey, backgroundBlendMode: BlendMode.saturation) : null,
                  child: ProfilePictureDisplay(accountUsername: widget.username),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            if (isBlocked) HugeIcon(icon: HugeIcons.strokeRoundedUnavailable, size: 16, color: AppColors.secondaryText.adaptTo(context)),
                            Text(
                              chatData.displayUsername ?? Account.getDefaultDisplayName(widget.username),
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                            ),
                            if (isLoading) LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14),
                          ],
                        ),
                        Text(widget.username, style: TextStyle(color: AppColors.grey, fontSize: 14)),
                      ],
                    ),
                    onTap: () async {
                      isLoading = true;
                      var recipientAccount = widget.username == lastAccountCache?.username ? lastAccountCache : await network.getAccount(widget.username);
                      isLoading = false;
                      if (recipientAccount == null || !context.mounted) return;
                      lastAccountCache = recipientAccount;
                      Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfilePage(recipientAccount, openedFromChat: true)));
                    },
                  ),
                ),
                //HugeIcon(icon: HugeIcons.strokeRoundedCall02, size: 22, color: AppColors.grey.adaptTo(context)),
                SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget messageBubble(Message data, bool? isPreviousOwned, bool? isNextOwned, bool isPreview) {
    final shouldAnimate = messagesIdToAnimate.contains(data.uuid);
    var statusIconData = getStatusIcon(data.status);

    bubbleKeys.putIfAbsent("${data.id}-${data.isOwned}", () => GlobalKey());

    BorderRadius getBubbleShape(bool isOwned) {
      const double maxPx = 11;
      const Radius max = Radius.circular(maxPx);
      var isAlone = (isPreviousOwned ?? !isOwned) == !isOwned && (isNextOwned ?? !isOwned) == !isOwned;

      var owned = BorderRadius.only(
        topRight: Radius.circular(isPreviousOwned ?? false ? 4 : maxPx),
        bottomRight: Radius.circular(isAlone || (isNextOwned ?? false) ? 4 : maxPx),
        topLeft: max,
        bottomLeft: max,
      );

      var received = BorderRadius.only(
        topLeft: Radius.circular(isPreviousOwned ?? true ? maxPx : 4),
        bottomLeft: Radius.circular(isAlone || !(isNextOwned ?? false) ? 4 : maxPx),
        topRight: max,
        bottomRight: max,
      );

      return isOwned ? owned : received;
    }

    Color getBubbleColor(bool isOwned) {
      final color = isOwned ? AppColors.sentBubble.adaptTo(context) : AppColors.receivedBubble.adaptTo(context);

      return data.isDeleted ? color.withAlpha(200) : color;
    }

    Widget bubbleContent = Align(
      alignment: data.isOwned ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        key: isPreview ? null : bubbleKeys["${data.id}-${data.isOwned}"],
        onLongPressStart: isPreview || (!data.isOwned && data.isDeleted) ? null : (details) => showMessageContextMenu(context, data),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: EdgeInsets.only(bottom: (isNextOwned ?? !data.isOwned) != data.isOwned ? 8 : 2),
          padding: EdgeInsets.fromLTRB(9, 5, 8, 5),
          decoration: BoxDecoration(
            color: getBubbleColor(data.isOwned),
            borderRadius: getBubbleShape(data.isOwned),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), offset: Offset(3, 5), blurRadius: 10)],
          ),
          child: TextChatBubbleWithTimeStamp(
            content: Text.rich(
              TextSpan(
                children: [
                  ...CustomText.parseSpans(
                    data.isDeleted ? "Supprimé" : data.content.trim(),
                    style: TextStyle(
                      color: data.isDeleted ? AppColors.text.adaptTo(context).withAlpha(.5.toByte()) : AppColors.white,
                      fontSize: 17,
                      fontStyle: data.isDeleted ? FontStyle.italic : null,
                    ),
                  ),
                ],
              ),
            ),
            timestamp: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 6),
                Text(
                  DateFormat('HH:mm').format(data.sentAt),
                  style: TextStyle(color: data.isDeleted ? AppColors.white.withAlpha(150) : AppColors.white, fontSize: 12),
                ),
                if (data.isOwned && !data.isDeleted)
                  Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: HugeIcon(
                      icon: statusIconData.icon,
                      color: data.status == MessageStatus.Read ? statusIconData.color.withBrightness(-.15) : statusIconData.color,
                      size: 13,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!shouldAnimate) {
      return bubbleContent;
    } else {
      return AnimatedMessageBubble(key: ValueKey(data.id), isOwned: data.isOwned, child: bubbleContent);
    }
  }

  Widget messageList() {
    return StreamBuilder(
      stream: database.chats.watchAll(),
      builder: (context, snapshot) {
        // Loading the new chat data
        final latestChatData = database.chats.getByUsername(widget.username);
        if (latestChatData != null) chatData = latestChatData;

        // Clearing unread messages count if needed
        updateAllMessagesToRead();

        return ListView.builder(
          controller: chatScrollController,
          padding: EdgeInsets.symmetric(horizontal: 10),
          itemCount: chatData.messages.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                margin: EdgeInsets.only(bottom: 12, top: 30),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context).withAlpha(150), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ProfilePictureDisplay(accountUsername: widget.username, radius: 30),
                    SizedBox(height: 6),
                    Text(
                      chatData.displayUsername ?? Account.getDefaultDisplayName(widget.username),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    Text(widget.username, style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                    if (widget.username != "support.messagyre") ...[
                      SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: HugeIcon(icon: HugeIcons.strokeRoundedInformationSquare, size: 16, color: AppColors.tertiaryText.adaptTo(context)),
                              ),
                            ),
                            ...CustomText.parseSpans(
                              "Pour bloquer un utilisateur, allez sur son profil → Bloquer cet utilisateur.",
                              style: TextStyle(color: AppColors.tertiaryText.adaptTo(context), fontSize: 16),
                            ),
                          ],
                        ),
                        softWrap: true,
                      ),
                    ],
                  ],
                ),
              );
            }

            if (index == 1) {
              final color = isEncryptionAvailable ? AppColors.tertiaryText.adaptTo(context) : AppColors.yellow.withAlpha(.5.toByte());

              return Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context).withAlpha(150), borderRadius: BorderRadius.circular(12)),
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: HugeIcon(
                            icon: isEncryptionAvailable ? HugeIcons.strokeRoundedShieldKey : HugeIcons.strokeRoundedKnightShield,
                            size: 16,
                            color: color,
                          ),
                        ),
                      ),
                      ...CustomText.parseSpans(
                        isEncryptionAvailable
                            ? "Les messages dans cette conversation sont chiffrés de bout en bout : seuls toi et ${chatData.displayUsername ?? chatData.username} pouvez les lire."
                            : "Cet utilisateur a une ancienne version de Messagyre qui ne supporte pas le chiffrement de bout en bout.",
                        style: TextStyle(color: color, fontSize: 16),
                      ),
                    ],
                  ),
                  softWrap: true,
                ),
              );
            }

            final msgIndex = index - 2;

            var allMessagesList = chatData.messages.toList();

            var currentMessage = allMessagesList[msgIndex];
            var previousMessage = msgIndex > 0 ? allMessagesList[msgIndex - 1] : currentMessage;
            var nextMessage = msgIndex < allMessagesList.length - 1 ? allMessagesList[msgIndex + 1] : currentMessage;

            final bubble = messageBubble(currentMessage, previousMessage.isOwned, nextMessage.isOwned, false);

            return (currentMessage.sentAt.day != previousMessage.sentAt.day ||
                    currentMessage.sentAt.month != previousMessage.sentAt.month ||
                    currentMessage.sentAt.year != previousMessage.sentAt.year ||
                    msgIndex == 0)
                ? Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 12, top: 30),
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                      decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context).withAlpha(120), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedCalendar04, size: 14, color: AppColors.tertiaryText.adaptTo(context)),
                          Text(formatDate(currentMessage.sentAt), style: TextStyle(fontSize: 16, color: AppColors.tertiaryText.adaptTo(context))),
                        ],
                      ),
                    ),
                    bubble,
                  ],
                )
                : Container(margin: EdgeInsets.only(top: (msgIndex == 0) ? 12 : 0, bottom: (msgIndex == allMessagesList.length - 1) ? 12 : 0), child: bubble);
          },
        );
      },
    );
  }

  Widget bottomBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          //color: adaptiveColor(barLightColor, barDarkColor),
          padding: EdgeInsets.only(right: 12, left: 12, bottom: MediaQuery.of(context).padding.bottom),
          child: ValueListenableBuilder(
            valueListenable: network.connectionState,
            builder: (context, connectionState, _) {
              return connectionState == ConnectionState.Connected
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 8,
                    children: [
                      if (messageFieldFocusNode.hasFocus)
                        GestureDetector(onTap: () => messageFieldFocusNode.unfocus(), child: HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01)),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: CupertinoTextField(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minLines: 1,
                            maxLines: 3,
                            style: TextStyle(fontSize: 18),
                            controller: messageFieldController,
                            focusNode: messageFieldFocusNode,
                            scrollPhysics: BouncingScrollPhysics(),
                            decoration: BoxDecoration(color: Theme.of(context).hoverColor, borderRadius: BorderRadius.circular(20)),
                            onSubmitted: sendMessage,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => sendMessage(messageFieldController.text),
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                          child: Padding(padding: EdgeInsets.only(left: 2), child: Icon(Icons.send_rounded, size: 18, color: AppColors.white)),
                        ),
                      ),
                    ],
                  )
                  : SizedBox(
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Text("Connexion en cours", style: TextStyle(color: AppColors.secondaryText.adaptTo(context), fontSize: 16)),
                        LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14),
                      ],
                    ),
                  );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image:
                    (globals.persistent.getBool("useDefaultWallpaper") ?? true) || currentWallpaper == null
                        ? DecorationImage(
                          image: AssetImage("assets/wallpaper.png"),
                          repeat: ImageRepeat.repeat,
                          fit: BoxFit.fitWidth,
                          opacity: .12,
                          colorFilter: globals.appBrightness == Brightness.dark ? null : ColorFilter.mode(Colors.black.withAlpha(200), BlendMode.srcIn),
                        )
                        : DecorationImage(image: Image.file(File(currentWallpaper!)).image, fit: BoxFit.cover),
              ),
            ),
          ),
          Column(
            children: [
              topBar(context),
              Expanded(
                child: Stack(
                  children: [
                    messageList(),
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: AnimatedSlide(
                        offset: showScrollDownButton ? Offset(0, 0) : Offset(0, 1),
                        duration: Duration(milliseconds: 300),
                        child: AnimatedOpacity(
                          opacity: showScrollDownButton ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 300),
                          child: GestureDetector(
                            onTap: scrollDown,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context).withAlpha(200), shape: BoxShape.circle),
                              child: Icon(CupertinoIcons.down_arrow, color: AppColors.text.adaptTo(context)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottomBar(),
            ],
          ),
        ],
      ),
    );
  }
}

class AnimatedMessageBubble extends StatefulWidget {
  final Widget child;
  final bool isOwned;
  const AnimatedMessageBubble({required this.child, required this.isOwned, super.key});

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (context.mounted) {
          final parentState = context.findAncestorStateOfType<_ChatPageState>();
          parentState?.messagesIdToAnimate.add((widget.key as ValueKey).value);
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        final value = _animation.value;
        return Transform.translate(offset: Offset(widget.isOwned ? -1 : 1, 50 * (1 - value)), child: Opacity(opacity: value.clamp(0, 1), child: child));
      },
      child: widget.child,
    );
  }
}
