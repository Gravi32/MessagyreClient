import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/pages/overlays/profile.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

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

  late var chatData = chats.get(widget.recipientUsername);

  final chatScrollController = ScrollController();
  final messageFieldController = TextEditingController();
  final messageFieldFocusNode = FocusNode();

  int visibleMessageCount = 50;

  Account? lastAccountCache = null;

  void scrollDown() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (chatScrollController.hasClients) {
        chatScrollController.animateTo(
          chatScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage(String input) async {
    if (input.isEmpty) return;

    if (chatData == null) {
      chatData = Chat(recipientUsername: widget.recipientUsername);
      chats.put(widget.recipientUsername, chatData!);
    }

    setState(() {
      chatData!.content.add(
        Message(content: input, sentAt: DateTime.now(), isOwned: true),
      );
    });

    router.send(
      Signal(
        type: SignalType.Message,
        data: {"RecipientUsername": widget.recipientUsername, "Content": input},
      ).pack(),
    );

    chats.put(widget.recipientUsername, chatData!);

    messageFieldController.clear();
    messageFieldFocusNode.requestFocus();
    scrollDown();
  }

  @override
  void initState() {
    super.initState();

    data.isChatOpen = true;

    messageFieldController.addListener(() {
      setState(() {});
    });

    Future.delayed(Duration(milliseconds: 300), () {
      if (chatScrollController.hasClients) {
        chatScrollController.jumpTo(
          chatScrollController.position.maxScrollExtent + 1000,
        );
      }
    });

    chatScrollController.addListener(() {
      if (chatScrollController.offset <= 100 && chatData != null) {
        if (visibleMessageCount < chatData!.content.length) {
          setState(() {
            visibleMessageCount += 20;
          });
        }
      }
    });

    router.onSignalReceived.listen((signal) {
      if (!mounted || signal.type != SignalType.Message) return;

      var receivedMessage = Message.fromSignal(signal);
      if (receivedMessage == null) return;

      setState(() {
        chatData?.content.add(receivedMessage);
      });

      chats.put(widget.recipientUsername, chatData!);
      scrollDown();
    });
  }

  @override
  void dispose() {
    data.isChatOpen = false;
    messageFieldController.dispose();
    chatScrollController.dispose();
    super.dispose();
  }

  ObstructingPreferredSizeWidget topBar() {
    return CupertinoNavigationBar(
      border: Border(),
      middle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              ProfilePictureDisplay(widget.recipientUsername),
              SizedBox(width: 12),

              GestureDetector(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.recipientUsername
                          .replaceAll('.', ' ')
                          .capitalize(),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      widget.recipientUsername,
                      style: TextStyle(
                        color: adaptiveColor(context, CupertinoColors.systemGrey, CupertinoColors.systemGrey),
                        fontWeight: FontWeight.w400,
                        fontSize: 14
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  debugPrint("Tap detected");

                  final recipientAccount =
                      widget.recipientUsername == lastAccountCache?.username
                          ? lastAccountCache
                          : await router.getAccount(widget.recipientUsername);

                  if (recipientAccount == null || !mounted) return;

                  lastAccountCache = recipientAccount;

                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => ProfileOverlay(recipientAccount),
                    ),
                  );
                },
              ),

              Spacer(),
              Icon(CupertinoIcons.phone, size: 22),
            ],
          ),
        ],
      ),
    );
  }

  Widget messageBubble(Message data, bool? isPreviousOwned, bool? isNextOwned) {
    BorderRadius getBubbleShape(bool isOwned) {
      const Radius max = Radius.circular(14);
      var isAlone =
          (isPreviousOwned ?? !isOwned) == !isOwned &&
          (isNextOwned ?? !isOwned) == !isOwned;

      var owned = BorderRadius.only(
        topRight: Radius.circular(isPreviousOwned ?? false ? 4 : 14),
        bottomRight: Radius.circular(
          isAlone || (isNextOwned ?? false) ? 4 : 14,
        ),
        topLeft: max,
        bottomLeft: max,
      );

      var received = BorderRadius.only(
        topLeft: Radius.circular(isPreviousOwned ?? true ? 14 : 4),
        bottomLeft: Radius.circular(
          isAlone || !(isNextOwned ?? false) ? 4 : 14,
        ),
        topRight: max,
        bottomRight: max,
      );

      return isOwned ? owned : received;
    }

    Color getBubbleColor(bool isOwned) {
      final isDarkMode =
          CupertinoTheme.brightnessOf(context) == Brightness.dark;

      return isOwned
          ? (isDarkMode ? Color(0xFF56009C) : Color(0xFFE0AAFF))
          : (isDarkMode
              ? const Color(0xFF3D3D3D)
              : CupertinoColors.systemGrey3);
    }

    return Align(
      alignment: data.isOwned ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          bottom: (isNextOwned ?? !data.isOwned) != data.isOwned ? 8 : 2,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: getBubbleColor(data.isOwned),
          borderRadius: getBubbleShape(data.isOwned),
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text(data.content, style: TextStyle(color: CupertinoColors.white)),
            Text(
              DateFormat('HH:mm').format(data.sentAt),
              style: TextStyle(color: CupertinoColors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomBar() {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(
          right: 12,
          left: 12,
          bottom: MediaQuery.of(context).padding.bottom + 10,
          top: 6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(child: Icon(CupertinoIcons.paperclip)),
            SizedBox(width: 16),
            Expanded(
              child: CupertinoTextField(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                minLines: 1,
                maxLines: 3,
                controller: messageFieldController,
                focusNode: messageFieldFocusNode,
                scrollPhysics: BouncingScrollPhysics(),
                decoration: BoxDecoration(
                  color: Theme.of(context).hoverColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                onSubmitted: sendMessage,
              ),
            ),
            SizedBox(width: 16),
            GestureDetector(
              onTap: () => sendMessage(messageFieldController.text),
              child: Icon(CupertinoIcons.paperplane),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    chatData?.unreadMessages = 0;

    return CupertinoPageScaffold(
      navigationBar: topBar(),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: chatScrollController,
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount:
                    chatData == null
                        ? 0
                        : (chatData!.content.length < visibleMessageCount
                            ? chatData!.content.length
                            : visibleMessageCount),
                itemBuilder: (context, index) {
                  if (chatData == null) return SizedBox.shrink();

                  var list = chatData!.content;
                  int start = (list.length - visibleMessageCount).clamp(
                    0,
                    list.length,
                  );
                  var sliced = list.sublist(start);

                  var data = sliced[index];
                  var previous = (index > 0) ? sliced[index - 1].isOwned : null;
                  var next =
                      (index < sliced.length - 1)
                          ? sliced[index + 1].isOwned
                          : null;

                  return messageBubble(data, previous, next);
                },
              ),
            ),
            bottomBar(),
          ],
        ),
      ),
    );
  }
}
