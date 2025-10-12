import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/pages/overlays/profile.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class ChatOverlay extends StatefulWidget {
  final String recipientUsername;

  const ChatOverlay({super.key, required this.recipientUsername});

  @override
  State<StatefulWidget> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  final router = ConnectionController();
  final data = Data();
  final chats = Hive.box<Chat>("Chats");
  final misc = Hive.box("Misc");

  late var chatData = chats.get(widget.recipientUsername);
  late var currentWallpaper = misc.get("CurrentWallpaper");

  final chatScrollController = ScrollController();
  final messageFieldController = TextEditingController();
  final messageFieldFocusNode = FocusNode();

  Set<Message> animatedMessages = {};
  bool isLoading = false;

  void messagesListener(Map<String, Object> messageData) {
    if (chatData == null || messageData["SenderUsername"] != chatData?.recipientUsername) return;

    final newMessage = Message.fromMessageData(messageData);

    setState(() {
      chatData!.content.add(newMessage);
    });

    router.sendReadReceipt(chatData!.recipientUsername);

    saveChatData();
    scrollDown();
  }

  void readReceiptListener(Map<String, Object> readReceipt) {
    if (chatData == null || readReceipt["SenderUsername"] != chatData?.recipientUsername) return;
    DateTime readAt = readReceipt["ReadAt"] as DateTime;

    for (var readMessage in chatData!.content.where((storedMessage) => storedMessage.sentAt.isBefore(readAt))) {
      if (readMessage.status == 1) readMessage.status = 2;
    }

    setState(() {});
  }

  int visibleMessageCount = 150;
  double blurAmount = 6;
  Color barLightColor = CupertinoColors.systemGrey5.withAlpha(150);
  Color barDarkColor = CupertinoColors.darkBackgroundGray.withAlpha(150);

  Account? lastAccountCache;
  bool showScrollDownButton = false;

  void scrollDown() {
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() => showScrollDownButton = false);
      if (chatScrollController.hasClients) {
        chatScrollController.animateTo(chatScrollController.position.maxScrollExtent, duration: Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void sendMessage(String input) async {
    if (input.isEmpty) return;

    try {
      if (chatData == null) {
        chatData = Chat(recipientUsername: widget.recipientUsername);
        saveChatData();
      }

      final message = Message(content: input, sentAt: DateTime.now(), isOwned: true);

      setState(() {
        chatData!.content.add(message);
      });

      if (router.isConnected) {
        router.send(widget.recipientUsername, input);
        message.statusNotifier.value = 1;
      }
      saveChatData();
      messageFieldController.clear();
      messageFieldFocusNode.requestFocus();
      scrollDown();
    } catch (e) {
      debugPrint("[Chat] Message '$input' could not be sent: $e");
    }
  }

  void saveChatData() {
    if (chatData == null) return;
    chats.put(widget.recipientUsername, chatData!);
  }

  @override
  void initState() {
    super.initState();

    data.isChatOpen = true;
    data.openChatUsername = widget.recipientUsername;

    messageFieldController.addListener(() {
      setState(() {});
    });

    messageFieldFocusNode.addListener(
      () => Future.delayed(Duration(milliseconds: 400), () {
        scrollDown();
      }),
    );

    KeyboardVisibilityController().onChange.listen((bool visible) {
      if (visible) {
        scrollDown();
      } else {
        messageFieldFocusNode.unfocus();
      }
    });

    router.onMessageReceived.listen(messagesListener);

    router.onReadReceiptReceived.listen(readReceiptListener);

    chatScrollController.addListener(() {
      if (showScrollDownButton) {
        if (chatScrollController.offset > chatScrollController.position.maxScrollExtent - 20) {
          setState(() => showScrollDownButton = false);
        }
      } else {
        if (chatScrollController.offset < chatScrollController.position.maxScrollExtent - 100) {
          setState(() => showScrollDownButton = true);
        }
      }
    });

    scrollDown();

    router.getAccount(widget.recipientUsername).then((account) => setState(() => chatData?.recipientDisplayUsername = account?.displayName));
  }

  @override
  void dispose() {
    data.isChatOpen = false;
    data.openChatUsername = null;
    messageFieldController.dispose();
    chatScrollController.dispose();
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

  Widget messageBubble(Message data, bool? isPreviousOwned, bool? isNextOwned) {
    final alreadyAnimated = animatedMessages.contains(data);
    if (!alreadyAnimated) animatedMessages.add(data);

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
      return isOwned ? (isDarkMode ? Color(0xFF56009C) : Color(0xFFE0AAFF)) : (isDarkMode ? const Color(0xFF3D3D3D) : CupertinoColors.systemGrey3);
    }

    Widget bubbleContent = Align(
      alignment: data.isOwned ? Alignment.centerRight : Alignment.centerLeft,
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
            Padding(padding: EdgeInsets.only(bottom: 3.5), child: CustomText(data.content, style: TextStyle(color: CupertinoColors.white, fontSize: 15))),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 1,
              children: [
                Text(DateFormat('HH:mm').format(data.sentAt), style: TextStyle(color: CupertinoColors.white, fontSize: 12)),
                if (data.isOwned)
                  ValueListenableBuilder(
                    valueListenable: data.statusNotifier,
                    builder: (context, status, _) => HugeIcon(icon: getStatusIcon(status), color: CupertinoColors.white, size: 13),
                  ),
              ],
            ),
          ],
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

        final bubble = messageBubble(currentMessage, previousMessage.isOwned, nextMessage.isOwned);

        return currentMessage.sentAt.difference(previousMessage.sentAt).inDays > 0 || index == 0
            ? Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 12, top: 30),
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withAlpha(200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedCalendar04, size: 14, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
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
                      children: [CupertinoActivityIndicator(), Text("Connexion en cours...")],
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
    if ((chatData?.unreadMessages ?? 0) > 0) {
      chatData!.unreadMessages = 0;
      router.sendReadReceipt(chatData!.recipientUsername);
    }
    saveChatData();

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          image:
              data.settings.useDefaultWallpaper
                  ? DecorationImage(
                    image: AssetImage("assets/BackgroundTile.png"),
                    repeat: ImageRepeat.repeat,
                    scale: 3,
                    opacity: .1,
                    colorFilter: data.appBrightness == Brightness.dark ? null : ColorFilter.mode(Colors.black.withAlpha(100), BlendMode.srcIn),
                  )
                  : DecorationImage(image: Image.file(File(currentWallpaper)).image),
        ),
        child: Column(
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
      ),
    );
  }
}
