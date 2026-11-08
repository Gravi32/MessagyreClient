import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/services/chat_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/text_chat_bubble.dart';

/// Colors of a bubble, depending on who sent it
class BubbleColors {
  final Color background, text, secondary;
  const BubbleColors(this.background, this.text, this.secondary);

  factory BubbleColors.of(BuildContext context, {required bool isOwned}) => isOwned
      ? BubbleColors(AppColors.sentBubble.adaptTo(context), AppColors.white, AppColors.white.withTransparency(.7))
      : BubbleColors(AppColors.receivedBubble.adaptTo(context), AppColors.text.adaptTo(context), AppColors.secondaryText.adaptTo(context));
}

/// One message of a conversation. [joinsPrevious] and [joinsNext] tell whether the neighbouring messages are from
/// the same person (same day): the corners between them are then smaller, like a single block.
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool joinsPrevious;
  final bool joinsNext;
  final void Function(Message message)? onLongPress;
  final void Function(Message message)? onTap;
  final GlobalKey? bubbleKey;

  const MessageBubble({super.key, required this.message, this.joinsPrevious = false, this.joinsNext = false, this.onLongPress, this.onTap, this.bubbleKey});

  BorderRadius get _shape {
    const big = Radius.circular(AppRadius.bubble);
    const small = Radius.circular(AppRadius.bubbleTail);
    return message.isOwned
        ? BorderRadius.only(topLeft: big, bottomLeft: big, topRight: joinsPrevious ? small : big, bottomRight: joinsNext ? small : big)
        : BorderRadius.only(topRight: big, bottomRight: big, topLeft: joinsPrevious ? small : big, bottomLeft: joinsNext ? small : big);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BubbleColors.of(context, isOwned: message.isOwned);
    final maxWidth = MediaQuery.sizeOf(context).width * .75;
    final attachment = message.isDeleted ? null : message.attachment;

    final Widget content = attachment == null
        ? _TextContent(message: message, colors: colors)
        : attachment.isImage
        ? _ImageContent(message: message, attachment: attachment, colors: colors, shape: _shape, maxWidth: maxWidth)
        : _FileContent(message: message, attachment: attachment, colors: colors);

    return Align(
      alignment: message.isOwned ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        key: bubbleKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap!(message),
        onLongPress: onLongPress == null ? null : () => onLongPress!(message),
        child: Padding(
          padding: EdgeInsets.only(bottom: joinsNext ? AppSpacing.xxs : AppSpacing.s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (message.isOwned && message.isFailed && !message.isDeleted)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.s),
                  child: HugeIcon(icon: AppIcons.statusFailed, color: AppColors.red, size: 22),
                ),
              Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(color: colors.background.withTransparency(message.isDeleted ? .6 : 1), borderRadius: _shape),
                clipBehavior: Clip.antiAlias,
                child: content,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Time and (for my messages) status, at the bottom right of a bubble
class MessageFooter extends StatelessWidget {
  final Message message;
  final Color color;
  const MessageFooter({super.key, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    final status = getStatusIcon(message.status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xxs,
      children: [
        Text(DateFormat('HH:mm').format(message.sentAt), style: AppStyles.caption(context).copyWith(color: color)),
        if (message.isOwned && !message.isDeleted)
          HugeIcon(icon: status.icon, size: 14, color: message.status == MessageStatus.Read ? AppColors.mint : (message.isFailed ? AppColors.red : color)),
      ],
    );
  }
}

class _TextContent extends StatelessWidget {
  final Message message;
  final BubbleColors colors;
  const _TextContent({required this.message, required this.colors});

  @override
  Widget build(BuildContext context) {
    final style = AppStyles.primaryText(context).copyWith(color: message.isDeleted ? colors.secondary : colors.text, fontStyle: message.isDeleted ? FontStyle.italic : null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.s - 1, AppSpacing.s + 2, AppSpacing.s - 2),
      child: TextChatBubbleWithTimeStamp(
        content: Text.rich(TextSpan(children: CustomText.parseSpans(message.isDeleted ? AppStrings.deleted : message.content.trim(), style: style))),
        timestamp: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.m),
          child: MessageFooter(message: message, color: colors.secondary),
        ),
      ),
    );
  }
}

/// Upload/download state over an attachment
class _TransferIndicator extends StatelessWidget {
  final Message message;
  final Color color;
  final double size;
  const _TransferIndicator({required this.message, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final transfer = message.transfer;
    final isMoving = transfer == TransferState.uploading || transfer == TransferState.downloading;

    if (isMoving) {
      return ValueListenableBuilder(
        valueListenable: ChatService().progressOf(message.uuid),
        builder: (context, progress, _) => SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: size - 6,
                child: progress == null || progress <= 0
                    ? CupertinoActivityIndicator(color: color, radius: size / 4)
                    : CustomPaint(painter: _RingPainter(progress: progress, color: color)),
              ),
            ],
          ),
        ),
      );
    }

    final icon = switch (transfer) {
      TransferState.pending => AppIcons.download,
      TransferState.failed => AppIcons.retry,
      TransferState.expired => message.attachment?.isImage == true ? AppIcons.imageMissing : AppIcons.fileMissing,
      _ => null,
    };
    if (icon == null) return const SizedBox.shrink();
    return HugeIcon(icon: icon, color: color, size: size * .6);
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width / 10;
    final rect = Offset.zero & size;
    final track = Paint()
      ..color = color.withTransparency(.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(rect.deflate(stroke / 2), 0, 6.2832, false, track);
    canvas.drawArc(rect.deflate(stroke / 2), -1.5708, 6.2832 * progress.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

class _ImageContent extends StatelessWidget {
  final Message message;
  final Attachment attachment;
  final BubbleColors colors;
  final BorderRadius shape;
  final double maxWidth;
  const _ImageContent({required this.message, required this.attachment, required this.colors, required this.shape, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final ratio = (attachment.aspectRatio ?? 4 / 3).clamp(.6, 1.8);
    final width = maxWidth;
    final localPath = message.localPath;
    final isReady = localPath != null && message.transfer != TransferState.downloading && File(localPath).existsSync();
    final caption = attachment.caption;
    final pixelWidth = (width * MediaQuery.devicePixelRatioOf(context)).round();

    Widget picture;
    if (isReady) {
      picture = Image.file(File(localPath), fit: BoxFit.cover, cacheWidth: pixelWidth, gaplessPlayback: true);
    } else if (attachment.thumbnail != null) {
      picture = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Image.memory(base64.decode(attachment.thumbnail!), fit: BoxFit.cover, gaplessPlayback: true),
      );
    } else {
      picture = Container(color: AppColors.tertiaryBackground.adaptTo(context));
    }

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: ratio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                picture,
                if (!isReady || message.transfer == TransferState.uploading)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.s),
                      decoration: BoxDecoration(color: AppColors.black.withTransparency(.45), shape: BoxShape.circle),
                      child: _TransferIndicator(message: message, color: AppColors.white),
                    ),
                  ),
                if (message.transfer == TransferState.expired)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: caption == null ? 34 : AppSpacing.s,
                    child: Text(
                      AppStrings.fileExpired,
                      textAlign: TextAlign.center,
                      style: AppStyles.footnote(context).copyWith(color: AppColors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (caption == null)
                  Positioned(
                    right: AppSpacing.s,
                    bottom: AppSpacing.s,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(color: AppColors.black.withTransparency(.4), borderRadius: BorderRadius.circular(AppRadius.s)),
                      child: MessageFooter(message: message, color: AppColors.white),
                    ),
                  ),
              ],
            ),
          ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.s - 2, AppSpacing.s + 2, AppSpacing.s - 2),
              child: TextChatBubbleWithTimeStamp(
                content: Text.rich(TextSpan(children: CustomText.parseSpans(caption, style: AppStyles.primaryText(context).copyWith(color: colors.text)))),
                timestamp: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.m),
                  child: MessageFooter(message: message, color: colors.secondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FileContent extends StatelessWidget {
  final Message message;
  final Attachment attachment;
  final BubbleColors colors;
  const _FileContent({required this.message, required this.attachment, required this.colors});

  String _stateText() => switch (message.transfer) {
    TransferState.uploading => AppStrings.uploading,
    TransferState.downloading => AppStrings.downloading,
    TransferState.pending => "${AppStrings.fileSize(attachment.size)} · ${AppStrings.tapToDownload}",
    TransferState.failed => "${AppStrings.fileSize(attachment.size)} · ${AppStrings.retry}",
    TransferState.expired => AppStrings.fileExpired,
    _ => AppStrings.fileSize(attachment.size),
  };

  @override
  Widget build(BuildContext context) {
    final isMoving = message.transfer == TransferState.uploading || message.transfer == TransferState.downloading;
    final showsState = isMoving || message.transfer == TransferState.pending || message.transfer == TransferState.failed;
    final caption = attachment.caption;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.s, AppSpacing.s + 2, AppSpacing.s - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.m - 2,
            children: [
              Container(
                width: AppSizes.compactControl,
                height: AppSizes.compactControl,
                decoration: BoxDecoration(color: colors.text.withTransparency(.12), borderRadius: BorderRadius.circular(AppRadius.s)),
                alignment: Alignment.center,
                child: showsState ? _TransferIndicator(message: message, color: colors.text, size: 32) : HugeIcon(icon: attachment.icon, color: colors.text, size: AppSizes.icon),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(attachment.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppStyles.strongText(context).copyWith(color: colors.text, fontSize: 16)),
                    Text(_stateText(), style: AppStyles.footnote(context).copyWith(color: colors.secondary)),
                  ],
                ),
              ),
            ],
          ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s, left: AppSpacing.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(TextSpan(children: CustomText.parseSpans(caption, style: AppStyles.primaryText(context).copyWith(color: colors.text)))),
              ),
            ),
          const SizedBox(height: AppSpacing.xxs),
          MessageFooter(message: message, color: colors.secondary),
        ],
      ),
    );
  }
}
