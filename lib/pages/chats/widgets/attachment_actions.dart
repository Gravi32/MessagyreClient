import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/services/chat_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:open_filex/open_filex.dart';

/// What tapping an attachment does: view or open it when it's here, download it (or send it again) otherwise
Future<void> openAttachment(BuildContext context, Message message) async {
  final attachment = message.attachment;
  if (attachment == null || message.isDeleted) return;
  if (attachment.isBlocked) return _showBlocked(context);

  final chats = ChatService();

  switch (message.transfer) {
    case TransferState.uploading || TransferState.downloading:
      return;
    case TransferState.expired:
      showCupertinoDialog(context: context, builder: (_) => const Dialog(title: AppStrings.fileExpired, content: AppStrings.fileExpiredContent));
      return;
    case TransferState.failed when message.isOwned:
      await chats.retry(message);
      return;
    case TransferState.pending || TransferState.failed:
      await chats.download(message);
      return;
    default:
      break;
  }

  final path = message.localPath;
  if (path == null || !await File(path).exists()) {
    if (!message.isOwned) await chats.download(message);
    return;
  }
  if (!context.mounted) return;

  if (attachment.isImage) {
    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(fullscreenDialog: true, builder: (_) => ImageViewerPage(message: message)));
    return;
  }

  final result = await OpenFilex.open(path, type: attachment.mimeType);
  if (result.type != ResultType.done && context.mounted) {
    showCupertinoDialog(context: context, builder: (_) => const Dialog(title: AppStrings.errorTitle, content: AppStrings.fileOpenFailed));
  }
}

/// Lets the user choose where to keep a copy of the attachment
Future<void> saveAttachment(BuildContext context, Message message) async {
  final path = message.localPath;
  final attachment = message.attachment;
  if (path == null || attachment == null || !await File(path).exists()) return;
  if (attachment.isBlocked) {
    if (context.mounted) _showBlocked(context);
    return;
  }

  try {
    final saved = await FilePicker.platform.saveFile(dialogTitle: AppStrings.saveToDevice, fileName: attachment.name, bytes: await File(path).readAsBytes());
    if (saved != null && context.mounted) {
      showCupertinoDialog(context: context, builder: (_) => const Dialog(title: AppStrings.saved));
    }
  } catch (e) {
    if (context.mounted) showCupertinoDialog(context: context, builder: (_) => Dialog.error(e));
  }
}

/// A photo in full screen, zoomable
class ImageViewerPage extends StatelessWidget {
  final Message message;
  const ImageViewerPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final caption = message.attachment?.caption;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(child: Image.file(File(message.localPath!), fit: BoxFit.contain)),
            ),
          ),
          Positioned(
            top: padding.top + AppSpacing.s,
            left: AppSpacing.page,
            right: AppSpacing.page,
            // The round buttons are square (AspectRatio): without a height they couldn't be laid out, and the X
            // to close the photo wasn't there
            height: AppSizes.iconButton,
            child: Row(
              children: [
                Button.icon(context, icon: AppIcons.close, color: AppColors.black.withTransparency(.5), iconColor: AppColors.white, onTap: () => Navigator.pop(context)),
                Expanded(
                  child: Text(
                    "${formatDate(message.sentAt)} · ${DateFormat('HH:mm').format(message.sentAt)}",
                    textAlign: TextAlign.center,
                    style: AppStyles.subheadline(context).copyWith(color: AppColors.white),
                  ),
                ),
                Button.icon(context, icon: AppIcons.save, color: AppColors.black.withTransparency(.5), iconColor: AppColors.white, onTap: () => saveAttachment(context, message)),
              ],
            ),
          ),
          if (caption != null)
            Positioned(
              left: AppSpacing.l,
              right: AppSpacing.l,
              bottom: padding.bottom + AppSpacing.l,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(color: AppColors.black.withTransparency(.55), borderRadius: BorderRadius.circular(AppRadius.m)),
                child: Text(caption, style: AppStyles.primaryText(context).copyWith(color: AppColors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A program, a script or an archive sent by an app before 4.108: never opened nor saved
void _showBlocked(BuildContext context) {
  showCupertinoDialog(
    context: context,
    builder: (_) => Dialog(title: "Fichier bloqué", content: AppStrings.fileBlocked),
  );
}
