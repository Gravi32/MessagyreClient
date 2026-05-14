import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/material.dart' hide ConnectionState, Dialog;
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
import 'package:messagyre_client/utility/graphics/blurred_container.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:messagyre_client/utility/widgets/text_chat_bubble.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';
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
    //TODO network.sendMessageAcknowledgement([newMessage.uuid], chatData.username, MessageStatus.Read);
    scrollDown();
  }

  void messageAcknowledgementListener(String senderUsername, Message messageData) {
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

  void pushProfilePage() async {
    setState(() => isLoading = true);
    var recipientAccount = widget.username == lastAccountCache?.username ? lastAccountCache : await network.getAccount(widget.username);
    setState(() => isLoading = false);

    if (recipientAccount == null) return;
    lastAccountCache = recipientAccount;
    if (mounted) Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfilePage(recipientAccount, openedFromChat: true)));
  }

  void sendMessage(String input) async {
    if (input.trim().isEmpty) return;

    HapticFeedback.mediumImpact();

    try {
      final message = Message.custom(
        content: input,
        sentAt: DateTime.now(),
        isOwned: true,
        status: network.isConnected ? MessageStatus.Sending : MessageStatus.Failed,
      );

      await database.chats.addMessage(chatData, message);

      messagesIdToAnimate.add(message.uuid);

      final sentSuccessfully = await network.send(message.uuid, widget.username, recipientPublicKey, input);
      final messageInDatabase = database.messages.getByUuid(message.uuid);
      if (messageInDatabase != null) {
        messageInDatabase.status = sentSuccessfully ? MessageStatus.Sent : MessageStatus.Failed;
        database.messages.save(messageInDatabase);
      }

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

    //TODO network.sendMessageAcknowledgement(justReadMessages, chatData.username, MessageStatus.Read);
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
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(color: Colors.white.withAlpha(5)),
                        ),
                      ),
                    ),

                    Positioned(
                      top: min(bubblePosition.dy, MediaQuery.of(context).size.height - (160 + bubbleHeight) * animation.value),
                      left: message.isOwned ? null : 10,
                      right: message.isOwned ? 10 : null,
                      child: Column(
                        crossAxisAlignment: message.isOwned ? .end : .start,
                        children: [
                          messageBubble(message, false, false, true),
                          RoundContainer(
                            width: 240,
                            color: AppColors.tertiaryBackground.adaptTo(context),
                            padding: .zero,
                            child: Column(
                              crossAxisAlignment: .stretch,
                              children: [
                                if (!message.isDeleted) ...[
                                  CupertinoPressable(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: message.content));
                                      animationController.reverse().then((_) => entry.remove());
                                    },
                                    padding: .symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      mainAxisSize: .max,
                                      mainAxisAlignment: .spaceBetween,
                                      children: [
                                        Text("Copier"),
                                        CustomIcon(icon: HugeIcons.strokeRoundedCopy01, size: 20, color: AppColors.text.adaptTo(context)),
                                      ],
                                    ),
                                  ),
                                ],
                                if (message.isOwned) ...[
                                  Divider(height: 0, thickness: 1, color: AppColors.tertiaryBackground.adaptTo(context)),
                                  CupertinoPressable(
                                    onTap: () {
                                      animationController.reverse().then((_) => entry.remove());
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          title: "Supprimer le message",
                                          content: "Choisissez *comment supprimer ce message*. Ces actions sont irréversibles !",
                                          options: {
                                            "Supprimer pour vous": () => setState(() => chatData.messages.remove(message)),
                                            "Supprimer pour tout le monde": () {
                                              try {
                                                final savedMessage = chatData.messages.firstWhere((element) => element.uuid == message.uuid);
                                                database.messages.markAsDeleted(savedMessage);
                                                network.sendMessageDelete([message.uuid], widget.username);
                                                setState(() {});
                                                debugPrint("[Chat] Deletion request sent for ${message.uuid}");
                                              } catch (e) {
                                                debugPrint("[Chat] Failed sending deletion request: $e");
                                              }
                                            },
                                          },
                                        ),
                                      );
                                    },

                                    padding: .symmetric(horizontal: 18, vertical: 10),
                                    child: Row(
                                      mainAxisSize: .max,
                                      mainAxisAlignment: .spaceBetween,
                                      children: [
                                        Text("Supprimer", style: TextStyle(color: AppColors.red)),
                                        CustomIcon(icon: HugeIcons.strokeRoundedDelete04, size: 20, color: AppColors.red),
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
                                                  mainAxisAlignment: .spaceBetween,
                                                  children: [
                                                    Text("Signaler", style: TextStyle(color: AppColors.red, fontSize: 18)),
                                                    CustomIcon(icon: HugeIcons.strokeRoundedFlag02, size: 20, color: AppColors.red),
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
                                                    mainAxisAlignment: .spaceBetween,
                                                    children: [
                                                      Text("Signaler et bloquer ${chatData.username}", style: TextStyle(color: AppColors.red, fontSize: 18)),
                                                      CustomIcon(icon: HugeIcons.strokeRoundedUserBlock01, size: 20, color: AppColors.red),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    padding: .symmetric(horizontal: 18, vertical: 10),
                                    child: Row(
                                      mainAxisSize: .max,
                                      mainAxisAlignment: .spaceBetween,
                                      children: [
                                        Text("Signaler", style: TextStyle(color: AppColors.red)),
                                        CustomIcon(icon: HugeIcons.strokeRoundedFlag02, size: 20, color: AppColors.red),
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
            print(result);
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
    //TODO network.messageAcknowledgementStreamController.stream.listen((record) => messagesListener(record.$1, record.$2));
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateAllMessagesToRead();
    });

    scrollDown();

    network.getAccount(widget.username).then((account) {
      setState(() => chatData.displayUsername = account?.displayName);
      database.chats.save(chatData);
    });
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

    super.dispose();
  }

  Widget topBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isBlocked = globals.blockedUsers.contains(widget.username);

    return Container(
      height: topPadding + 60,
      padding: .symmetric(horizontal: 10, vertical: 8).add(.only(top: topPadding)),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: .bottomCenter,
          end: .topCenter,
          colors: [AppColors.background.adaptTo(context).withTransparency(0), AppColors.background.adaptTo(context)],
          stops: [0, .4],
        ),
      ),

      child: Row(
        mainAxisSize: .max,
        spacing: 12,
        children: [
          Button.icon(
            context,
            icon: HugeIcons.strokeRoundedArrowLeft01,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).pop();
            },
          ),

          const SizedBox(),

          ProfilePictureDisplay(accountUsername: widget.username, isBlocked: isBlocked),

          Expanded(
            child: GestureDetector(
              child: Column(
                mainAxisAlignment: .center,
                crossAxisAlignment: .start,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      if (isBlocked) CustomIcon(icon: HugeIcons.strokeRoundedUnavailable, size: 16, color: AppColors.secondaryText.adaptTo(context)),
                      Text(chatData.displayUsername ?? Account.getDefaultDisplayName(widget.username), style: TextStyle(fontWeight: .w500, fontSize: 20)),
                    ],
                  ),
                  Text(widget.username, style: TextStyle(color: AppColors.grey, fontSize: 14)),
                ],
              ),
              onTap: () => pushProfilePage(),
            ),
          ),

          if (isLoading) LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14),

          const SizedBox(),

          Button.icon(context, icon: HugeIcons.strokeRoundedUser, onTap: () => pushProfilePage()),
        ],
      ),
    );
  }

  Widget messageBubble(Message data, bool? isPreviousOwned, bool? isNextOwned, bool isPreview) {
    final shouldAnimate = messagesIdToAnimate.contains(data.uuid);
    var statusIconData = getStatusIcon(data.status);

    bubbleKeys.putIfAbsent("${data.id}-${data.isOwned}", () => GlobalKey());

    BorderRadius getBubbleShape(bool isOwned) {
      const Radius max = .circular(24);
      const Radius min = .circular(8);
      var isAlone = (isPreviousOwned ?? !isOwned) == !isOwned && (isNextOwned ?? !isOwned) == !isOwned;

      BorderRadius owned = .only(topRight: isPreviousOwned == true ? min : max, bottomRight: isNextOwned == true ? min : max, topLeft: max, bottomLeft: max);

      BorderRadius received = .only(
        topLeft: isPreviousOwned ?? true ? max : min,
        bottomLeft: isAlone || !(isNextOwned ?? false) ? min : max,
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
      alignment: data.isOwned ? .centerRight : .centerLeft,
      child: GestureDetector(
        key: isPreview ? null : bubbleKeys["${data.id}-${data.isOwned}"],
        onLongPressStart: isPreview || (!data.isOwned && data.isDeleted) ? null : (details) => showMessageContextMenu(context, data),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: .only(bottom: (isNextOwned ?? !data.isOwned) != data.isOwned ? 8 : 2),
          padding: .fromLTRB(9, 5, 8, 5),
          decoration: BoxDecoration(
            color: getBubbleColor(data.isOwned),
            borderRadius: getBubbleShape(data.isOwned),
            border: .all(color: getBubbleColor(data.isOwned).withBrightness(MediaQuery.maybePlatformBrightnessOf(context) == .light ? .1 : -.1), width: .5),
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
                      fontStyle: data.isDeleted ? .italic : null,
                    ),
                  ),
                ],
              ),
            ),
            timestamp: Row(
              mainAxisSize: .min,
              children: [
                const SizedBox(width: 12),
                Text(DateFormat('HH:mm').format(data.sentAt), style: TextStyle(color: AppColors.white.withAlpha(data.isDeleted ? 100 : 150), fontSize: 12)),
                if (data.isOwned && !data.isDeleted)
                  Padding(
                    padding: .only(left: 2),
                    child: CustomIcon(
                      icon: statusIconData.icon,
                      color: data.status == .Read ? statusIconData.color.withBrightness(-.15) : statusIconData.color,
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
    final padding = MediaQuery.viewPaddingOf(context);

    return StreamBuilder(
      stream: database.chats.watchChat(widget.username),
      builder: (context, snapshot) {
        // Loading the new chat data
        final latestChatData = snapshot.data;
        if (latestChatData != null) chatData = latestChatData;

        return ListView.builder(
          controller: chatScrollController,
          padding: .symmetric(horizontal: 10),
          itemCount: chatData.messages.length + 4,
          itemBuilder: (context, index) {
            if (index == 0) return SizedBox(height: padding.top + 60);

            if (index == 1) {
              return BlurredContainer(
                width: .infinity,
                blur: blurAmount,
                margin: .only(bottom: 12, top: 30),
                padding: .all(16),

                child: Column(
                  crossAxisAlignment: .center,
                  children: [
                    SizedBox(height: 100, child: ProfilePictureDisplay(accountUsername: widget.username)),
                    SizedBox(height: 6),
                    Text(chatData.displayUsername ?? Account.getDefaultDisplayName(widget.username), style: TextStyle(fontSize: 22, fontWeight: .w600)),
                    Text(widget.username, style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                    if (widget.username != "support.messagyre") ...[
                      SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: .middle,
                              child: Padding(
                                padding: const .only(right: 4),
                                child: Icon(CupertinoIcons.info_circle, size: 16, color: AppColors.tertiaryText.adaptTo(context)),
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

            if (index == 2) {
              final color = isEncryptionAvailable ? AppColors.tertiaryText.adaptTo(context) : AppColors.yellow.withAlpha(.5.toByte());

              return BlurredContainer(
                blur: blurAmount,
                padding: .symmetric(vertical: 10, horizontal: 16),

                child: Text.rich(
                  textAlign: .center,
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: .middle,
                        child: Padding(
                          padding: const .only(right: 4),
                          child: Icon(isEncryptionAvailable ? CupertinoIcons.lock_fill : CupertinoIcons.lock_slash_fill, size: 16, color: color),
                        ),
                      ),
                      ...CustomText.parseSpans(
                        isEncryptionAvailable
                            ? "Les messages dans cette conversation sont chiffrés de bout en bout : seuls vous et ${chatData.displayUsername ?? chatData.username} pouvez les lire."
                            : "Cet utilisateur a une ancienne version de Messagyre qui ne supporte pas le chiffrement de bout en bout.",
                        style: TextStyle(color: color, fontSize: 16),
                      ),
                    ],
                  ),
                  softWrap: true,
                ),
              );
            }

            final messageIndex = index - 3;

            if (messageIndex == chatData.messages.length) return SizedBox(height: padding.bottom + 60);

            var allMessagesList = chatData.messages.toList();

            var currentMessage = allMessagesList[messageIndex];
            var previousMessage = messageIndex > 0 ? allMessagesList[messageIndex - 1] : currentMessage;
            var nextMessage = messageIndex < allMessagesList.length - 1 ? allMessagesList[messageIndex + 1] : currentMessage;

            final bubble = messageBubble(
              currentMessage,
              previousMessage != currentMessage && previousMessage.sentAt.isSameDayAs(currentMessage.sentAt) ? previousMessage.isOwned : null,
              nextMessage != currentMessage && nextMessage.sentAt.isSameDayAs(currentMessage.sentAt) ? nextMessage.isOwned : null,
              false,
            );

            return (currentMessage.sentAt.day != previousMessage.sentAt.day ||
                    currentMessage.sentAt.month != previousMessage.sentAt.month ||
                    currentMessage.sentAt.year != previousMessage.sentAt.year ||
                    messageIndex == 0)
                ? Column(
                    children: [
                      BlurredContainer(
                        blur: blurAmount,
                        margin: .only(bottom: 12, top: 30),
                        padding: .symmetric(vertical: 5, horizontal: 16),

                        child: Container(
                          decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context).withAlpha(120), borderRadius: .circular(10)),
                          child: Row(
                            mainAxisSize: .min,
                            spacing: 8,
                            children: [
                              CustomIcon(icon: HugeIcons.strokeRoundedCalendar04, size: 14, color: AppColors.tertiaryText.adaptTo(context)),
                              Text(formatDate(currentMessage.sentAt), style: TextStyle(fontSize: 16, color: AppColors.tertiaryText.adaptTo(context))),
                            ],
                          ),
                        ),
                      ),
                      bubble,
                    ],
                  )
                : Container(
                    margin: .only(top: (messageIndex == 0) ? 12 : 0, bottom: (messageIndex == allMessagesList.length - 1) ? 12 : 0),
                    child: bubble,
                  );
          },
        );
      },
    );
  }

  Widget bottomBar() {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      height: bottomPadding + 60,
      padding: .symmetric(horizontal: 10, vertical: 8).add(.only(bottom: bottomPadding)),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: .topCenter,
          end: .bottomCenter,
          colors: [AppColors.background.adaptTo(context).withTransparency(0), AppColors.background.adaptTo(context)],
          stops: [0, .4],
        ),
      ),

      child: ValueListenableBuilder(
        valueListenable: network.connectionState,
        builder: (context, connectionState, _) {
          return connectionState == .Connected
              ? Row(
                  crossAxisAlignment: .center,
                  spacing: 10,
                  children: [
                    if (messageFieldFocusNode.hasFocus)
                      Button.icon(context, icon: HugeIcons.strokeRoundedArrowDown01, onTap: () => messageFieldFocusNode.unfocus()),

                    // Message field
                    Expanded(
                      child: Field(
                        placeholder: "",
                        maxLines: 5,
                        controller: messageFieldController,
                        focusNode: messageFieldFocusNode,
                        thin: true,
                        scrollPhysics: BouncingScrollPhysics(),
                        onSubmitted: (message) => sendMessage(message),
                      ),
                    ),

                    // Send button
                    Button.icon(
                      context,
                      legacyIcon: Icons.send_rounded,
                      color: messageFieldController.text.isNotEmpty ? AppColors.accent : null,
                      onTap: () => sendMessage(messageFieldController.text),
                    ),
                  ],
                )
              : SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: .center,
                    spacing: 8,
                    children: [
                      Text("Connexion en cours", style: TextStyle(color: AppColors.secondaryText.adaptTo(context), fontSize: 16)),
                      LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14),
                    ],
                  ),
                );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Wallpaper
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: (globals.persistent.getBool("useDefaultWallpaper") ?? true) || currentWallpaper == null
                    ? DecorationImage(
                        image: AssetImage("assets/wallpaper.png"),
                        repeat: ImageRepeat.repeat,
                        fit: .fitWidth,
                        opacity: .12,
                        colorFilter: MediaQuery.maybePlatformBrightnessOf(context) == .dark
                            ? null
                            : ColorFilter.mode(Colors.black.withAlpha(200), BlendMode.srcIn),
                      )
                    : DecorationImage(image: Image.file(File(currentWallpaper!)).image, fit: .cover),
              ),
            ),
          ),

          Positioned.fill(child: messageList()),

          // Top bar
          Positioned(top: 0, right: 0, left: 0, child: topBar(context)),

          // Scroll down button
          Positioned(
            bottom: bottomPadding + 60,
            right: 10,
            child: AnimatedSlide(
              offset: showScrollDownButton ? Offset(0, 0) : Offset(0, 1),
              duration: Duration(milliseconds: 300),
              child: AnimatedOpacity(
                opacity: showScrollDownButton ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: SizedBox(
                  height: 44,
                  child: Button.icon(context, legacyIcon: CupertinoIcons.down_arrow, onTap: () => scrollDown()),
                ),
              ),
            ),
          ),

          // Bottom bar
          Positioned(bottom: 0, right: 0, left: 0, child: bottomBar()),
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
        return Transform.translate(
          offset: Offset(widget.isOwned ? -1 : 1, 50 * (1 - value)),
          child: Opacity(opacity: value.clamp(0, 1), child: child),
        );
      },
      child: widget.child,
    );
  }
}
