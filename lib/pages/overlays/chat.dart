import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/pages/overlays/profile.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:uuid/uuid.dart';

class ChatOverlay extends StatefulWidget {
  final String recipientUsername;

  const ChatOverlay({super.key, required this.recipientUsername});

  @override
  State<StatefulWidget> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> with TickerProviderStateMixin {
  final router = ConnectionController();
  final data = Data();
  final chats = Hive.box<Chat>("Chats");
  final misc = Hive.box("Misc");

  late var chatData = chats.get(widget.recipientUsername);
  late var currentWallpaper = misc.get("CurrentWallpaper");

  StreamSubscription? _keyboardVisibilitySub;
  StreamSubscription? _messageReceivedSub;
  StreamSubscription? _statusUpdateSub;
  StreamSubscription? _messageDeletionSub;

  final chatScrollController = ScrollController();
  final messageFieldController = TextEditingController();
  final messageFieldFocusNode = FocusNode();
  final Map<String, GlobalKey> bubbleKeys = {};

  Set<Message> animatedMessages = {};
  bool isLoading = false;

  int visibleMessageCount = 150;
  double blurAmount = 6;
  Color barLightColor = CupertinoColors.systemGrey5.withAlpha(150);
  Color barDarkColor = CupertinoColors.darkBackgroundGray.withAlpha(150);

  Account? lastAccountCache;
  bool showScrollDownButton = false;

  void messagesListener(Map<String, Object> messageData) {
    if (chatData == null || messageData["SenderUsername"] != chatData?.recipientUsername) return;

    final newMessage = Message.fromMessageData(messageData);

    setState(() {
      chatData!.content.add(newMessage);
    });

    router.sendMessageStatusUpdate([newMessage.id], chatData!.recipientUsername, MessageStatus.Read);

    saveChatData();
    scrollDown();
  }

  void messageStatusUpdateListener(Map<String, Object> messageStatusUpdate) {
    if (chatData == null || messageStatusUpdate["SenderUsername"] != chatData?.recipientUsername) return;

    final targetMessage = chatData!.content.firstWhere((message) => message.isOwned && message.id == messageStatusUpdate["ID"], orElse: () => Message.empty());

    targetMessage.status = (messageStatusUpdate["Status"] as MessageStatus?) ?? MessageStatus.Failed;

    //setState(() {});
  }

  void messageDeletionListener(Map<String, Object> messageDeletion) {
    if (chatData == null || messageDeletion["SenderUsername"] != chatData?.recipientUsername) return;

    final targetMessages = chatData!.content.where((message) => message.id == messageDeletion["ID"]);

    setState(() {
      for (var message in targetMessages) {
        message.isDeleted = true;
      }
    });
  }

  void scrollDown() {
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() => showScrollDownButton = false);
      if (chatScrollController.hasClients) {
        chatScrollController.animateTo(chatScrollController.position.maxScrollExtent, duration: Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void sendMessage(String input) async {
    if (input.trim().isEmpty) return;

    HapticFeedback.mediumImpact();

    try {
      if (chatData == null) {
        chatData = Chat(recipientUsername: widget.recipientUsername);
        saveChatData();
      }

      final message = Message(id: Uuid().v4(), content: input, sentAt: DateTime.now(), isOwned: true);

      setState(() {
        chatData!.content.add(message);
      });

      if (router.isConnected) {
        router.send(message.id, widget.recipientUsername, input);
        message.statusNotifier.value = MessageStatus.Sending;
      } else {
        message.statusNotifier.value = MessageStatus.Failed;
      }

      saveChatData();
      messageFieldController.clear();
      messageFieldFocusNode.requestFocus();
      scrollDown();
    } catch (e) {
      debugPrint("[Chat] Message '$input' could not be sent: $e");
    }
  }

  void saveChatData() async {
    if (chatData == null) return;
    chats.put(widget.recipientUsername, chatData!);
  }

  void updateAllMessagesToRead() async {
    if ((chatData?.unreadMessages ?? 0) <= 0) return;
    chatData!.unreadMessages = 0;

    List<String> justReadMessages = [];

    for (var message in chatData!.content) {
      if (!message.isOwned && message.status != MessageStatus.Read) {
        message.status = MessageStatus.Read;
        justReadMessages.add(message.id);
      }
    }

    router.sendMessageStatusUpdate(justReadMessages, chatData!.recipientUsername, MessageStatus.Read);
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
                              color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withOpacity(.8),
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
                                        HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 20, color: CupertinoColors.label.resolveFrom(context)),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 0, thickness: 1, color: CupertinoColors.tertiarySystemBackground.resolveFrom(context)),
                                  CupertinoPressable(
                                    onTap: null,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Infos", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                                        HugeIcon(
                                          icon: HugeIcons.strokeRoundedInformationSquare,
                                          size: 20,
                                          color: CupertinoColors.inactiveGray.resolveFrom(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 0, thickness: 1, color: CupertinoColors.tertiarySystemBackground.resolveFrom(context)),
                                ],
                                if (message.isOwned)
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
                                                    chatData?.content.remove(message);
                                                    saveChatData();
                                                  });

                                                  Navigator.pop(popupContext);
                                                },
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text("Supprimer pour vous", style: TextStyle(color: CupertinoColors.systemRed, fontSize: 18)),
                                                    HugeIcon(icon: HugeIcons.strokeRoundedDelete01, size: 20, color: CupertinoColors.systemRed),
                                                  ],
                                                ),
                                              ),

                                              if (!message.isDeleted)
                                                CupertinoActionSheetAction(
                                                  onPressed: () {
                                                    try {
                                                      final savedMessage = chatData?.content.firstWhere((element) => element.id == message.id);
                                                      if (savedMessage == null) return;

                                                      setState(() {
                                                        savedMessage.isDeleted = true;
                                                        saveChatData();
                                                      });

                                                      router.sendMessageDelete([message.id], widget.recipientUsername);
                                                      debugPrint("[Chat] Deletion request sent for ${message.id}");
                                                    } catch (e) {
                                                      debugPrint("[Chat] Failed sending deletion request: $e");
                                                    }
                                                    Navigator.pop(popupContext);
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text("Supprimer pour tout le monde", style: TextStyle(color: CupertinoColors.systemRed, fontSize: 18)),
                                                      HugeIcon(icon: HugeIcons.strokeRoundedDelete04, size: 20, color: CupertinoColors.systemRed),
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
                                        Text("Supprimer", style: TextStyle(color: CupertinoColors.systemRed)),
                                        HugeIcon(icon: HugeIcons.strokeRoundedDelete04, size: 20, color: CupertinoColors.systemRed),
                                      ],
                                    ),
                                  ),
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

  @override
  void initState() {
    super.initState();

    data.openChatUsername = widget.recipientUsername;

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

    _messageReceivedSub = router.onMessageReceived.listen(messagesListener);
    _statusUpdateSub = router.onMessageStatusUpdateReceived.listen(messageStatusUpdateListener);
    _messageDeletionSub = router.onMessageDeletionReceived.listen(messageDeletionListener);

    chatScrollController.addListener(() {
      final offset = chatScrollController.offset;
      final maxOffset = chatScrollController.position.maxScrollExtent;

      if (offset > maxOffset - 20 && showScrollDownButton) {
        setState(() => showScrollDownButton = false);
      } else if (offset < maxOffset - 100 && !showScrollDownButton) {
        setState(() => showScrollDownButton = true);
      }

      if (offset < maxOffset - 300 && messageFieldFocusNode.hasFocus) {
        messageFieldFocusNode.unfocus();
      }
    });

    scrollDown();

    router.getAccount(widget.recipientUsername).then((account) => setState(() => chatData?.recipientDisplayUsername = account?.displayName));
  }

  @override
  void dispose() {
    data.openChatUsername = null;

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
    for (var chat in chats.values) {
      count += chat.unreadMessages;
    }
    return count;
  }

  Widget topBar(BuildContext context) {
    final unreadChats = getUnreadChats();
    final isBlocked = data.blockedUsers.contains(widget.recipientUsername);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          color: adaptiveColor(barLightColor, barDarkColor),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 30),
                      if (unreadChats > 0) Text(unreadChats.toString(), style: TextStyle(fontSize: 20, color: CupertinoTheme.of(context).primaryColor)),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  foregroundDecoration: isBlocked ? BoxDecoration(color: Colors.grey, backgroundBlendMode: BlendMode.saturation) : null,
                  child: ProfilePictureDisplay(accountUsername: widget.recipientUsername),
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
                            if (isBlocked)
                              Opacity(
                                opacity: .5,
                                child: HugeIcon(icon: HugeIcons.strokeRoundedUnavailable, size: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                              ),
                            Text(
                              chatData?.recipientDisplayUsername ?? Account.getDefaultDisplayName(widget.recipientUsername),
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                            ),
                            if (isLoading) LoadingAnimationWidget.waveDots(color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 14),
                          ],
                        ),
                        Text(widget.recipientUsername, style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
                      ],
                    ),
                    onTap: () async {
                      isLoading = true;
                      var recipientAccount =
                          widget.recipientUsername == lastAccountCache?.username ? lastAccountCache : await router.getAccount(widget.recipientUsername);
                      isLoading = false;
                      if (recipientAccount == null || !context.mounted) return;
                      lastAccountCache = recipientAccount;
                      Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfileOverlay(recipientAccount, openedFromChat: true)));
                    },
                  ),
                ),
                HugeIcon(icon: HugeIcons.strokeRoundedCall02, size: 22, color: CupertinoColors.systemGrey.resolveFrom(context)),
                SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget messageBubble(Message data, bool? isPreviousOwned, bool? isNextOwned, bool isPreview) {
    final alreadyAnimated = animatedMessages.contains(data);
    if (!alreadyAnimated) animatedMessages.add(data);

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
      final isDarkMode = CupertinoTheme.brightnessOf(context) == Brightness.dark;
      final color = isOwned ? (isDarkMode ? Color(0xFF56009C) : Color(0xFFE0AAFF)) : (isDarkMode ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey3);
      return data.isDeleted ? color.withAlpha(200) : color;
    }

    Widget bubbleContent = Align(
      alignment: data.isOwned ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        key: isPreview ? null : bubbleKeys["${data.id}-${data.isOwned}"],
        onLongPressStart: isPreview ? null : (details) => showMessageContextMenu(context, data),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: EdgeInsets.only(bottom: (isNextOwned ?? !data.isOwned) != data.isOwned ? 8 : 2),
          padding: EdgeInsets.only(left: 9, right: 8, bottom: 2, top: 5),
          decoration: BoxDecoration(
            color: getBubbleColor(data.isOwned),
            borderRadius: getBubbleShape(data.isOwned),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), offset: Offset(3, 5), blurRadius: 10)],
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 9,
            runSpacing: 4,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 3.5),
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (data.isDeleted)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Opacity(
                              opacity: .6,
                              child: HugeIcon(icon: HugeIcons.strokeRoundedUnavailable, size: 16, color: CupertinoColors.white.withAlpha(150)),
                            ),
                          ),
                        ),
                      ...CustomText.parseSpans(
                        data.isDeleted ? "Supprimé" : data.content.trim(),
                        style: TextStyle(
                          color: data.isDeleted ? CupertinoColors.white.withAlpha(150) : CupertinoColors.white,
                          fontSize: 17,
                          fontStyle: data.isDeleted ? FontStyle.italic : null,
                        ),
                      ),
                    ],
                  ),
                  softWrap: true,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 1,
                children: [
                  Text(
                    DateFormat('HH:mm').format(data.sentAt),
                    style: TextStyle(color: data.isDeleted ? CupertinoColors.white.withAlpha(150) : CupertinoColors.white, fontSize: 12),
                  ),
                  if (data.isOwned && !data.isDeleted)
                    ValueListenableBuilder(
                      valueListenable: data.statusNotifier,
                      builder: (context, status, _) {
                        final statusIconData = getStatusIcon(status);
                        return HugeIcon(icon: statusIconData.icon, color: statusIconData.color, size: 13);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (alreadyAnimated) {
      return bubbleContent;
    } else {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.translate(offset: Offset((data.isOwned ? -1 : 1) * -200 * (1 - value), 0), child: Transform.scale(scale: value, child: child));
        },
        child: bubbleContent,
      );
    }
  }

  Widget messageList() {
    return ListView.builder(
      controller: chatScrollController,
      padding: EdgeInsets.symmetric(horizontal: 10),
      itemCount: chatData == null ? 0 : (chatData!.content.length < visibleMessageCount ? chatData!.content.length : visibleMessageCount),
      itemBuilder: (context, index) {
        if (chatData == null) return SizedBox.shrink();

        var allMessagesList = chatData!.content;
        var visibleMessagesList = allMessagesList.sublist((allMessagesList.length - visibleMessageCount).clamp(0, allMessagesList.length));

        var currentMessage = visibleMessagesList[index];
        var previousMessage = visibleMessagesList[max(index - 1, 0)];
        var nextMessage = visibleMessagesList[min(index + 1, visibleMessagesList.length - 1)];

        final bubble = messageBubble(currentMessage, previousMessage.isOwned, nextMessage.isOwned, false);

        return currentMessage.sentAt.difference(previousMessage.sentAt).inDays > 0 || index == 0
            ? Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 12, top: 30),
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Opacity(
                        opacity: .25,
                        child: HugeIcon(icon: HugeIcons.strokeRoundedCalendar04, size: 14, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                      ),
                      Text(formatDate(currentMessage.sentAt), style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context))),
                    ],
                  ),
                ),
                bubble,
              ],
            )
            : Container(margin: EdgeInsets.only(top: (index == 0) ? 12 : 0, bottom: (index == visibleMessagesList.length - 1) ? 12 : 0), child: bubble);
      },
    );
  }

  Widget bottomBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          color: adaptiveColor(barLightColor, barDarkColor),
          padding: EdgeInsets.only(right: 12, left: 12, bottom: MediaQuery.of(context).padding.bottom),
          child: ValueListenableBuilder(
            valueListenable: router.connectionState,
            builder: (context, connectionState, _) {
              return connectionState == ConnectionState.Connected
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 8,
                    children: [
                      GestureDetector(child: HugeIcon(icon: HugeIcons.strokeRoundedAddSquare, color: CupertinoColors.systemGrey.resolveFrom(context))),
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
                          decoration: BoxDecoration(shape: BoxShape.circle, color: CupertinoTheme.of(context).primaryColor),
                          child: Padding(padding: EdgeInsets.only(left: 2), child: Icon(Icons.send_rounded, size: 18, color: CupertinoColors.white)),
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
                        Text("Connexion en cours", style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 16)),
                        LoadingAnimationWidget.waveDots(color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 14),
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
    updateAllMessagesToRead();
    saveChatData();

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image:
                    data.settings.useDefaultWallpaper
                        ? DecorationImage(
                          image: AssetImage("assets/wallpaper.png"),
                          repeat: ImageRepeat.repeat,
                          fit: BoxFit.fitWidth,
                          opacity: .12,
                          colorFilter: data.appBrightness == Brightness.dark ? null : ColorFilter.mode(Colors.black.withAlpha(200), BlendMode.srcIn),
                        )
                        : DecorationImage(image: Image.file(File(currentWallpaper)).image, fit: BoxFit.cover),
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
                              decoration: BoxDecoration(
                                color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context).withAlpha(200),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(CupertinoIcons.down_arrow, color: CupertinoColors.label.resolveFrom(context)),
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
