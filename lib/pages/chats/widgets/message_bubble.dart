import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/utility/widgets/app_icon.dart';
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
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/assignments/assignment_share.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/services/database_service.dart';
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

  /// In a class chat: who wrote it, above the first bubble of their messages
  final String? senderName;

  const MessageBubble({
    super.key,
    required this.message,
    this.joinsPrevious = false,
    this.joinsNext = false,
    this.onLongPress,
    this.onTap,
    this.bubbleKey,
    this.senderName,
  });

  /// The same color for the same person in every class chat
  static Color colorOf(String username) {
    const palette = [AppColors.accent, AppColors.blue, AppColors.orange, AppColors.green, AppColors.pink, AppColors.indigo, AppColors.teal, AppColors.brown];
    var hash = 0;
    for (final unit in username.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }

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

    final sharedAssignment = message.isDeleted ? null : message.sharedAssignment;

    final Widget content = sharedAssignment != null
        ? _AssignmentContent(message: message, assignment: sharedAssignment, colors: colors)
        : attachment == null
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
                  child: AppIcon(icon: AppIcons.statusFailed, color: AppColors.red, size: 22),
                ),
              Builder(
                builder: (context) {
                  final bubble = Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    decoration: BoxDecoration(
                      color: colors.background.withTransparency(message.isDeleted ? .6 : 1),
                      gradient: message.isOwned && !message.isDeleted ? AppColors.sentGradient : null,
                      borderRadius: _shape,
                      // The received bubbles are cards: a hairline keeps them apart from a light wallpaper
                      border: message.isOwned ? null : Border.all(color: AppColors.outline.adaptTo(context), width: .5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: content,
                  );
                  final sender = message.senderUsername;
                  if (senderName == null || sender == null || message.isOwned || joinsPrevious) return bubble;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.m, bottom: AppSpacing.xxs),
                        child: Text(
                          senderName!,
                          style: AppStyles.footnote(context).copyWith(fontWeight: FontWeight.w600, color: colorOf(sender)),
                        ),
                      ),
                      bubble,
                    ],
                  );
                },
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
          AppIcon(icon: status.icon, size: 14, color: message.status == MessageStatus.Read ? AppColors.mint : (message.isFailed ? AppColors.red : color)),
      ],
    );
  }
}

/// An assignment sent in the chat: what, for when, and (received) a button to add it to my assignments
class _AssignmentContent extends StatefulWidget {
  final Message message;
  final AssignmentShare assignment;
  final BubbleColors colors;
  const _AssignmentContent({required this.message, required this.assignment, required this.colors});

  @override
  State<_AssignmentContent> createState() => _AssignmentContentState();
}

class _AssignmentContentState extends State<_AssignmentContent> {
  /// Already in my assignments (false when the database can't be read, as in the widget tests)
  bool get isAdded {
    try {
      return DatabaseService().assignments.getAll().any(widget.assignment.isSameAs);
    } catch (_) {
      return false;
    }
  }

  Future<void> add() async {
    await showCupertinoSheet(
      context: context,
      builder: (context) => NewAssignmentPage(prefill: widget.assignment),
      enableDrag: false,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final colors = widget.colors;
    final owned = widget.message.isOwned;
    final inner = owned ? AppColors.white.withValues(alpha: .14) : AppColors.tertiaryBackground.adaptTo(context);

    final (label, icon) = switch (assignment.type) {
      AssignmentType.test => (AppStrings.tagTest, HugeIcons.strokeRoundedAlert02),
      AssignmentType.leave => (AppStrings.tagLeave, HugeIcons.strokeRoundedSun03),
      AssignmentType.assignment => ("Devoir", AppIcons.assignments),
    };
    final subject = assignment.subjectName;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 260,
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(color: inner, borderRadius: BorderRadius.circular(AppRadius.l - AppSpacing.s)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                Row(
                  spacing: AppSpacing.s - 2,
                  children: [
                    AppIcon(icon: icon, size: 16, strokeWidth: 2, color: colors.secondary),
                    Expanded(
                      child: Text(
                        [label.toUpperCase(), if (subject != null) subject].join(" · "),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.caption(context).copyWith(color: colors.secondary, fontWeight: FontWeight.w700, letterSpacing: .4),
                      ),
                    ),
                  ],
                ),
                Text(assignment.headline, maxLines: 4, overflow: TextOverflow.ellipsis, style: AppStyles.strongText(context).copyWith(color: colors.text)),
                if (assignment.type == AssignmentType.test && assignment.content.trim().isNotEmpty)
                  Text(assignment.content.trim(), maxLines: 4, overflow: TextOverflow.ellipsis, style: AppStyles.subheadline(context).copyWith(color: colors.secondary)),
                Text(
                  "Pour ${formatDate(assignment.dueDate, includeArticle: true)}",
                  style: AppStyles.footnote(context).copyWith(color: colors.secondary),
                ),
              ],
            ),
          ),
          if (!owned) ...[
            const SizedBox(height: AppSpacing.s),
            SizedBox(
              width: 260,
              child: isAdded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: AppSpacing.xs,
                        children: [
                          AppIcon(icon: AppIcons.done, size: 16, color: colors.secondary),
                          Flexible(
                            child: Text(
                              "Dans vos devoirs",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.subheadline(context).copyWith(color: colors.secondary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                      minimumSize: Size.zero,
                      color: AppColors.accentSoft.adaptTo(context),
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      onPressed: add,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: AppSpacing.xs,
                        children: [
                          AppIcon(icon: AppIcons.add, size: 16, strokeWidth: 2, color: AppColors.tint.adaptTo(context)),
                          Flexible(
                            child: Text(
                              "Ajouter à mes devoirs",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.subheadline(context).copyWith(color: AppColors.tint.adaptTo(context), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, right: AppSpacing.xxs),
            child: Align(alignment: Alignment.centerRight, widthFactor: 1, child: MessageFooter(message: widget.message, color: colors.secondary)),
          ),
        ],
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  final Message message;
  final BubbleColors colors;
  const _TextContent({required this.message, required this.colors});

  @override
  Widget build(BuildContext context) {
    final style = AppStyles.primaryText(
      context,
    ).copyWith(color: message.isDeleted ? colors.secondary : colors.text, fontStyle: message.isDeleted ? FontStyle.italic : null);

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
                    ? GymnaseLoader(color: color, size: size / 2)
                    : CustomPaint(
                        painter: _RingPainter(progress: progress, color: color),
                      ),
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
    return AppIcon(icon: icon, color: color, size: size * .6);
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
                content: Text.rich(
                  TextSpan(
                    children: CustomText.parseSpans(caption, style: AppStyles.primaryText(context).copyWith(color: colors.text)),
                  ),
                ),
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
                child: showsState
                    ? _TransferIndicator(message: message, color: colors.text, size: 32)
                    : AppIcon(icon: attachment.icon, color: colors.text, size: AppSizes.icon),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attachment.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.strongText(context).copyWith(color: colors.text, fontSize: AppStyles.sizeSubheadline),
                    ),
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
                child: Text.rich(
                  TextSpan(
                    children: CustomText.parseSpans(caption, style: AppStyles.primaryText(context).copyWith(color: colors.text)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xxs),
          MessageFooter(message: message, color: colors.secondary),
        ],
      ),
    );
  }
}
