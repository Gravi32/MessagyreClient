import 'dart:math';

import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({super.key});

  @override
  State<StatefulWidget> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  final pageScrollController = ScrollController();

  bool showThumbnailChats = false;

  final Map<String, String?> _mockPhotos = {
    'lucas_v7': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=150', // Gatto
    'enzo_drk': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=150', // Macchina
    'mathis_99': 'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=150', // Gatto
    'nathan_off': null,
    'hugo_m': 'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=150', // Macchina
    'leo_paris': 'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=150', // Cane/Gatto
    'theo_j': 'https://images.unsplash.com/photo-1543906965-f9520aa2ed8b?w=150', // Gatto
    'gabriel_l': null,
    'maxime_r': 'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=150', // Macchina
    'yanis_b': 'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?w=150', // Gatto
  };

  final Map<String, Message> _mockLastMessages = {};

  List<Chat> get _mockedFrenchChats {
    final now = DateTime.now();
    final mocks = [
      {'user': 'lucas_v7', 'display': 'Lucas 🇫🇷', 'msg': 'On se voit à quelle heure ?', 'own': true, 'status': MessageStatus.Read},
      {'user': 'enzo_drk', 'display': 'Enzo', 'msg': 'T\'as fait l\'exo de maths ? 💀', 'own': false, 'status': MessageStatus.Delivered},
      {'user': 'mathis_99', 'display': 'Mathis B.', 'msg': 'Je t\'envoie le lien tout de suite', 'own': true, 'status': MessageStatus.Read},
      {'user': 'nathan_off', 'display': 'Nathan', 'msg': 'Vas-y chaud pour la console!', 'own': true, 'status': MessageStatus.Delivered},
      {'user': 'hugo_m', 'display': 'Hugo', 'msg': 'Mdr t\'es sérieux ??', 'own': false, 'status': MessageStatus.Delivered},
      {'user': 'leo_paris', 'display': 'Léo', 'msg': 'Je t\'ai laissé les clés.', 'own': true, 'status': MessageStatus.Read},
      {'user': 'theo_j', 'display': 'Théo', 'msg': 'Je t\'attends au skatepark.', 'own': false, 'status': MessageStatus.Delivered},
      {'user': 'gabriel_l', 'display': 'Gabriel', 'msg': 'Ok ça marche.', 'own': true, 'status': MessageStatus.Read},
      {'user': 'maxime_r', 'display': 'Maxime', 'msg': 'C\'est incroyable mec!', 'own': true, 'status': MessageStatus.Read},
      {'user': 'yanis_b', 'display': 'Yanis', 'msg': 'Je arrive dans 5 minutes.', 'own': false, 'status': MessageStatus.Delivered},
    ];

    return mocks.map((m) {
      final username = m['user'] as String;
      final chat = Chat.custom(
        username: username,
        displayUsername: m['display'] as String,
        unreadMessages: (m['own'] as bool) == false ? Random().nextInt(3) : 0,
      );

      _mockLastMessages[username] = Message.custom(
        content: m['msg'] as String,
        sentAt: now.subtract(Duration(minutes: (mocks.indexOf(m) + 1) * 12)),
        isOwned: m['own'] as bool,
      )..status = m['status'] as MessageStatus;

      return chat;
    }).toList();
  }

  List<Chat> get allChats {
    if (showThumbnailChats) {
      return _mockedFrenchChats;
    }

    return database.chats.getAll()..sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      final aDate = a.messages.isNotEmpty ? a.messages.last.sentAt : DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.messages.isNotEmpty ? b.messages.last.sentAt : DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

  // Widgets

  Widget buildChatBar(Chat chatData) {
    final isBlocked = globals.blockedUsers.contains(chatData.username);
    var hasUnreadMessages = chatData.unreadMessages > 0;

    final lastMessage = showThumbnailChats ? _mockLastMessages[chatData.username] : (chatData.messages.isNotEmpty ? chatData.messages.last : null);

    final statusIconData = lastMessage != null ? getStatusIcon(lastMessage.status) : null;

    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  foregroundDecoration: isBlocked ? BoxDecoration(color: Colors.grey, backgroundBlendMode: BlendMode.saturation) : null,
                  child: ProfilePictureDisplay(
                    accountUsername: (showThumbnailChats && _mockPhotos[chatData.username] != null) ? null : chatData.username,
                    pictureURL: showThumbnailChats ? _mockPhotos[chatData.username] : null,
                    radius: 25,
                  ),
                ),

                SizedBox(width: 12),
                Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          if (isBlocked) HugeIcon(icon: HugeIcons.strokeRoundedUnavailable, size: 16, color: AppColors.secondaryText.adaptTo(context)),

                          Text(
                            chatData.displayUsername ?? Account.getDefaultDisplayName(chatData.username),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: adaptiveColor(AppColors.black, AppColors.white)),
                          ),
                        ],
                      ),

                      Expanded(
                        child:
                            lastMessage != null
                                ? Text.rich(
                                  TextSpan(
                                    children: [
                                      if (lastMessage.isOwned && statusIconData != null)
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 2),
                                            child: HugeIcon(
                                              icon: statusIconData.icon,
                                              size: 20,
                                              color:
                                                  statusIconData.color == AppColors.white && Theme.of(context).brightness == Brightness.light
                                                      ? AppColors.grey
                                                      : statusIconData.color.withAlpha(.6.toByte()),
                                            ),
                                          ),
                                        ),
                                      if (lastMessage.isDeleted)
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 3),
                                            child: HugeIcon(
                                              icon: HugeIcons.strokeRoundedUnavailable,
                                              size: 14,
                                              strokeWidth: hasUnreadMessages ? 3 : 2,
                                              color: AppColors.secondaryText.adaptTo(context),
                                            ),
                                          ),
                                        ),
                                      ...CustomText.parseSpans(
                                        lastMessage.isDeleted ? "Message supprimé" : lastMessage.content.trim(),
                                        style: TextStyle(
                                          fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.w400,
                                          color: AppColors.secondaryText.adaptTo(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                )
                                : Text("Envoyez un message...", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.tertiaryText.adaptTo(context))),
                      ),
                    ],
                  ),
                ),
                if (lastMessage != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        lastMessage.sentAt.isSameDayAs(DateTime.now()) ? DateFormat('HH:mm').format(lastMessage.sentAt) : formatDate(lastMessage.sentAt),
                        style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: hasUnreadMessages ? FontWeight.w600 : FontWeight.w400),
                      ),

                      Row(
                        spacing: 4,
                        children: [
                          if (chatData.isPinned) HugeIcon(icon: HugeIcons.strokeRoundedPin, size: 16, color: AppColors.secondaryText.adaptTo(context)),

                          if (hasUnreadMessages)
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                chatData.unreadMessages.toString(),
                                style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          onPressed: () {
            Navigator.of(
              context,
              rootNavigator: true,
            ).push(CupertinoPageRoute(builder: (builder) => ChatPage(username: chatData.username))).then((_) => setState(() {}));
          },
        ),

        Divider(indent: 60, color: Theme.of(context).dividerColor.withAlpha(30)),
      ],
    );
  }

  // Overrides

  @override
  void initState() {
    super.initState();

    globals.blockedUsersNotifier.addListener(() => setState(() {}));

    // On connection to WebSocket
    network.connectionState.addListener(() async {
      // FOR THE REVIEW TEAMS
      if (globals.username == "apple.verification" || globals.username == "google.verification") {
        final now = DateTime.now();

        final abusiveChat = Chat.custom(username: "test.1");
        final abusiveMessages = [
          Message.custom(content: "Bonjour. Ceci est une conversation de démonstration.", sentAt: now.subtract(const Duration(minutes: 5)), isOwned: false),
          Message.custom(content: "Salut, comment ça va ?", sentAt: now.subtract(const Duration(minutes: 4)), isOwned: true),
          Message.custom(content: "Tu es vraiment nul, personne veut parler avec toi.", sentAt: now.subtract(const Duration(minutes: 3)), isOwned: false),
          Message.custom(content: "Ce message est un exemple de contenu à signaler.", sentAt: now.subtract(const Duration(minutes: 2)), isOwned: false),
        ];

        final normalChat = Chat.custom(username: "test.2");
        final normalMessages = [
          Message.custom(content: "Bonjour, ceci est un exemple de chat normal.", sentAt: now.subtract(const Duration(minutes: 6)), isOwned: false),
          Message.custom(content: "Merci, c'est parfait pour la vérification.", sentAt: now.subtract(const Duration(minutes: 5)), isOwned: true),
          Message.custom(content: "N'hésitez pas à signaler ou bloquer un utilisateur.", sentAt: now.subtract(const Duration(minutes: 4)), isOwned: false),
        ];

        for (var msg in abusiveMessages) {
          await database.messages.save(msg);
          abusiveChat.messages.add(msg);
        }

        for (var msg in normalMessages) {
          await database.messages.save(msg);
          normalChat.messages.add(msg);
        }

        await database.chats.save(abusiveChat);
        await database.chats.save(normalChat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Forces rebuild to draw the page title when starting the app
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await pageScrollController.animateTo(15, duration: Duration(milliseconds: 10), curve: Curves.linear);
      if (mounted) await pageScrollController.animateTo(0, duration: Duration(milliseconds: 10), curve: Curves.linear);
    });

    return CupertinoPageScaffold(
      child: NestedScrollView(
        controller: pageScrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            ValueListenableBuilder(
              valueListenable: network.connectionState,
              builder:
                  (context, connectionState, _) => CupertinoSliverNavigationBar(
                    leading:
                        (connectionState != ConnectionState.Connected || network.isLocalhost)
                            ? Row(
                              spacing: 8,
                              children: [
                                Text(
                                  network.isLocalhost ? "Connecté au Localhost" : "Connexion en cours",
                                  style: TextStyle(color: network.isLocalhost ? AppColors.red : AppColors.secondaryText.adaptTo(context)),
                                ),
                                network.isLocalhost
                                    ? HugeIcon(icon: HugeIcons.strokeRoundedAlert02, color: AppColors.red, size: 20, strokeWidth: 1.5)
                                    : LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14),
                              ],
                            )
                            : null,
                    largeTitle: Text("Conversations"),
                    trailing: GestureDetector(child: HugeIcon(icon: HugeIcons.strokeRoundedBubbleChatAdd), onTap: () => MainPage.pageIndex.value = 3),
                  ),
            ),
          ];
        },
        body: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder(
              stream: database.chats.watchAll(),
              builder: (context, _) {
                final list = allChats;

                return list.isEmpty
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 2,
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedSleeping, strokeWidth: 1.5, size: 48, color: AppColors.tertiaryText.adaptTo(context)),

                        const SizedBox(height: 8),
                        Text("Silence total...", style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.secondaryText.adaptTo(context), fontSize: 22)),
                        Text(
                          "Messagyre est faite aussi pour discuter !",
                          style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.tertiaryText.adaptTo(context)),
                        ),
                        CupertinoButton(
                          onPressed: () => MainPage.pageIndex.value = 3,
                          padding: EdgeInsets.only(top: 40),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 6,
                            children: [
                              Text("Briser la glace", style: TextStyle(fontWeight: FontWeight.w400)),
                              HugeIcon(icon: HugeIcons.strokeRoundedBubbleChatAdd, size: 18),
                            ],
                          ),
                        ),
                      ],
                    )
                    : ListView.builder(
                      padding: EdgeInsets.only(top: 8),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return buildChatBar(list[index]);
                      },
                    );
              },
            ),
          ),
        ),
      ),
    );
  }
}
