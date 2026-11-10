import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/services/global_chat_service.dart';
import 'package:messagyre_client/services/group_service.dart';
import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

/// The picture of any conversation: a person, a class, a group or the global chat
class ChatAvatar extends StatelessWidget {
  final String chatId;
  final double size;
  final bool isBlocked;

  const ChatAvatar({super.key, required this.chatId, required this.size, this.isBlocked = false});

  @override
  Widget build(BuildContext context) {
    if (GlobalChatService.isGlobal(chatId)) return GlobalChatAvatar(size: size);
    if (GroupService.isGroupChat(chatId)) return GroupAvatar(groupId: GroupService.groupOfChat(chatId)!, size: size);
    if (ClassService.isClassChat(chatId)) return ClassAvatar(className: ClassService.classOfChat(chatId)!, size: size);
    return SizedBox.square(dimension: size, child: ProfilePictureDisplay(accountUsername: chatId, isBlocked: isBlocked));
  }
}

/// A group's picture, or its initials on a color of its own (the same on every phone)
class GroupAvatar extends StatelessWidget {
  final String groupId;
  final double size;

  /// A picture being chosen (a local file), shown before it is uploaded
  final String? localPath;

  const GroupAvatar({super.key, required this.groupId, required this.size, this.localPath});

  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r"\s+")).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return "";
    final letters = words.length == 1 ? words.first.characters.take(2).toString() : words.take(2).map((word) => word.characters.first).join();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, ChatGroup>>(
      valueListenable: GroupService().groups,
      builder: (context, groups, _) {
        final group = groups[groupId];
        final fallback = _InitialsAvatar(seed: groupId, initials: initialsOf(group?.name ?? ""), size: size);
        if (localPath != null) return ClipOval(child: Image.file(File(localPath!), width: size, height: size, fit: BoxFit.cover));
        final url = group?.pictureUrl;
        if (url == null) return fallback;
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          ),
        );
      },
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String seed;
  final String initials;
  final double size;

  const _InitialsAvatar({required this.seed, required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = ClassAvatar.colorOf(seed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, AppColors.white, .12)!, Color.lerp(color, AppColors.black, .18)!],
        ),
      ),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? AppIcon(icon: HugeIcons.strokeRoundedUserGroup, size: size * .45, color: AppColors.white)
          : Text(
              initials,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(fontFamily: AppStyles.titleFontFamily, fontWeight: FontWeight.w700, fontSize: size * .36, height: 1, color: AppColors.white),
            ),
    );
  }
}
