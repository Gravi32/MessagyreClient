import 'package:flutter/cupertino.dart' hide ConnectionState, Page;
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/chat_service.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/empty_state.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/connection_status.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({super.key});

  @override
  State<StatefulWidget> createState() => _ChatsListPageState();
}

/// A conversation with its last message, for the list
typedef _ChatEntry = ({Chat chat, Message? lastMessage});

class _ChatsListPageState extends State<ChatsListPage> {
  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();
  final chats = ChatService();

  int lastSentChatsCount = -1;

  void onBlockedUsersChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    chats.initialize();
    globals.blockedUsersNotifier.addListener(onBlockedUsersChanged);
  }

  @override
  void dispose() {
    globals.blockedUsersNotifier.removeListener(onBlockedUsersChanged);
    super.dispose();
  }

  /// Pinned first, then the most recent activity first
  List<_ChatEntry> loadEntries() {
    final entries = database.chats.getAll().map((chat) => (chat: chat, lastMessage: database.messages.lastOfChat(chat.username))).toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    entries.sort((a, b) {
      if (a.chat.isPinned != b.chat.isPinned) return a.chat.isPinned ? -1 : 1;
      return (b.lastMessage?.sentAt ?? epoch).compareTo(a.lastMessage?.sentAt ?? epoch);
    });
    return entries;
  }

  void openChat(String username) {
    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (_) => ChatPage(username: username)));
  }

  Future<void> showChatMenu(Chat chat) async {
    HapticFeedback.mediumImpact();
    final name = chat.displayUsername ?? Account.getDefaultDisplayName(chat.username);

    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, "pin"),
            child: _ActionRow(text: chat.isPinned ? AppStrings.unpinChat : AppStrings.pinChat, icon: chat.isPinned ? AppIcons.unpin : AppIcons.pin),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, "delete"),
            child: const _ActionRow(text: AppStrings.deleteChat, icon: AppIcons.delete, color: AppColors.red),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
      ),
    );
    if (!mounted) return;

    if (choice == "pin") {
      await database.chats.setPinned(chat, !chat.isPinned);
    } else if (choice == "delete") {
      showCupertinoDialog(
        context: context,
        builder: (_) => Dialog.confirm(content: AppStrings.deleteChatConfirm(name), isDestructive: true, onConfirm: () => chats.deleteChat(chat)),
      );
    }
  }

  String previewOf(Message message) {
    if (message.isDeleted) return AppStrings.deletedMessage;
    final attachment = message.attachment;
    if (attachment == null) return message.content.trim();
    final caption = attachment.caption?.trim();
    return caption?.isNotEmpty == true ? caption! : (attachment.isImage ? AppStrings.photo : attachment.name);
  }

  Widget buildChatTile(_ChatEntry entry) {
    final chat = entry.chat;
    final lastMessage = entry.lastMessage;
    final isBlocked = globals.blockedUsers.contains(chat.username);
    final hasUnread = chat.unreadMessages > 0;
    final secondary = AppColors.secondaryText.adaptTo(context);

    final previewIcon = lastMessage == null
        ? null
        : lastMessage.isDeleted
        ? AppIcons.deleted
        : lastMessage.attachment?.icon;

    return GestureDetector(
      onLongPress: () => showChatMenu(chat),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s - 2, vertical: AppSpacing.s),
        minimumSize: Size.zero,
        onPressed: () => openChat(chat.username),
        child: Row(
          spacing: AppSpacing.l - 2,
          children: [
            SizedBox.square(dimension: AppSizes.avatar, child: ProfilePictureDisplay(accountUsername: chat.username, isBlocked: isBlocked)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xxs,
                children: [
                  Row(
                    spacing: AppSpacing.xs + 2,
                    children: [
                      if (isBlocked) HugeIcon(icon: AppIcons.blocked, size: 16, color: secondary),
                      Expanded(
                        child: Text(
                          chat.displayUsername ?? Account.getDefaultDisplayName(chat.username),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.strongText(context).copyWith(fontSize: 18),
                        ),
                      ),
                      if (lastMessage != null)
                        Text(
                          lastMessage.sentAt.isSameDayAs(DateTime.now()) ? DateFormat('HH:mm').format(lastMessage.sentAt) : formatDate(lastMessage.sentAt),
                          style: AppStyles.subheadline(context).copyWith(
                            color: hasUnread ? AppColors.accent : AppColors.tertiaryText.adaptTo(context),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.s,
                    children: [
                      Expanded(
                        child: lastMessage == null
                            ? Text(AppStrings.chatsNoMessage, style: AppStyles.callout(context).copyWith(fontStyle: FontStyle.italic, color: AppColors.tertiaryText.adaptTo(context)))
                            : Text.rich(
                                TextSpan(
                                  children: [
                                    if (lastMessage.isOwned && !lastMessage.isDeleted)
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                                          child: HugeIcon(icon: getStatusIcon(lastMessage.status).icon, size: 16, color: getStatusIcon(lastMessage.status).color),
                                        ),
                                      ),
                                    if (previewIcon != null)
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Padding(padding: const EdgeInsets.only(right: AppSpacing.xs), child: HugeIcon(icon: previewIcon, size: 16, color: secondary)),
                                      ),
                                    ...CustomText.parseSpans(
                                      previewOf(lastMessage),
                                      style: AppStyles.callout(context).copyWith(
                                        color: hasUnread ? AppColors.text.adaptTo(context) : secondary,
                                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                                        fontStyle: lastMessage.isDeleted ? FontStyle.italic : null,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (chat.isPinned) Padding(padding: const EdgeInsets.only(top: 2), child: HugeIcon(icon: AppIcons.pin, size: 16, color: secondary)),
                      if (hasUnread)
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s - 2, vertical: AppSpacing.xxs),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.s)),
                          child: Text(chat.unreadMessages > 99 ? "99+" : chat.unreadMessages.toString(), textAlign: TextAlign.center, style: AppStyles.badge(context)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Page.sliver(
      topBar: TopBar.sliver(
        title: AppStrings.tabChats,
        leading: const ConnectionStatus(),
        trailing: Button.icon(context, icon: AppIcons.newChat, onTap: () => MainPage.pageIndex.value = 3),
      ),
      // Any change of a chat or a message refreshes the list
      body: StreamBuilder(
        stream: database.messages.watchAll(),
        builder: (context, _) => StreamBuilder(
          stream: database.chats.watchAllLazy(),
          builder: (context, _) {
            final entries = loadEntries();
            final hasUnread = entries.any((entry) => entry.chat.unreadMessages > 0);

            if (lastSentChatsCount != entries.length) {
              lastSentChatsCount = entries.length;
              network.post("/analytics/upload-chats-count", {"Chats": entries.length});
            }

            if (App.pages[2].showBadge.value != hasUnread) {
              WidgetsBinding.instance.addPostFrameCallback((_) => App.pages[2].showBadge.value = hasUnread);
            }

            if (entries.isEmpty) {
              return EmptyState(
                icon: AppIcons.emptyChats,
                title: AppStrings.chatsEmptyTitle,
                subtitle: AppStrings.chatsEmptySubtitle,
                actionText: AppStrings.chatsEmptyAction,
                actionIcon: AppIcons.newChat,
                onAction: () => MainPage.pageIndex.value = 3,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              itemCount: entries.length + 1,
              itemBuilder: (context, index) => index == entries.length ? const BottomSpacing(includeBottomBar: true) : buildChatTile(entries[index]),
              separatorBuilder: (context, index) =>
                  index == entries.length - 1 ? const SizedBox.shrink() : Container(height: .5, margin: const EdgeInsets.only(left: AppSizes.avatar + AppSpacing.xl), color: AppColors.separator.adaptTo(context)),
            );
          },
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String text;
  final List<List<dynamic>> icon;
  final Color color;
  const _ActionRow({required this.text, required this.icon, this.color = AppColors.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: TextStyle(color: color)),
        HugeIcon(icon: icon, size: 22, color: color),
      ],
    );
  }
}
