import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';

/// The title above a group of cards, with an optional link on the right ("Tout voir ›")
class SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  const SectionHeader(this.title, {super.key, this.onAction, this.actionText = "Tout voir", this.padding = const .only(left: 4, bottom: AppSpacing.s)});

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.tint.adaptTo(context);
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Expanded(
              child: Text(title, maxLines: 1, overflow: .ellipsis, style: AppStyles.section(context)),
            ),
            if (onAction != null)
              CupertinoButton(
                padding: const .symmetric(horizontal: AppSpacing.s),
                minimumSize: .zero,
                onPressed: onAction,
                child: Row(
                  mainAxisSize: .min,
                  spacing: 2,
                  children: [
                    Text(
                      actionText,
                      style: AppStyles.subheadline(context).copyWith(color: tint, fontWeight: .w500),
                    ),
                    HugeIcon(icon: AppIcons.chevronRight, size: 16, color: tint, strokeWidth: 2),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
