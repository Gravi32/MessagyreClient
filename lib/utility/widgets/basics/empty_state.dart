import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';

/// What a page or a list shows when it has nothing to show: an icon, a title, a sentence and an optional action.
class EmptyState extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final List<List<dynamic>>? actionIcon;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.actionIcon,
    this.onAction,
    this.padding = const .only(top: 60, left: AppSpacing.xl, right: AppSpacing.xl),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: .min,
        mainAxisAlignment: .center,
        children: [
          // The icon in a soft grey circle
          Container(
            width: 84,
            height: 84,
            alignment: .center,
            decoration: BoxDecoration(shape: .circle, color: AppColors.tertiaryBackground.adaptTo(context)),
            child: HugeIcon(icon: icon, strokeWidth: 1.5, size: 36, color: AppColors.secondaryText.adaptTo(context)),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(title, textAlign: .center, style: AppStyles.secondaryHeader(context)),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.s),
            Text(subtitle!, textAlign: .center, style: AppStyles.subheadline(context).copyWith(height: 1.4)),
          ],
          if (actionText != null && onAction != null)
            CupertinoButton(
              onPressed: onAction,
              padding: const .only(top: AppSpacing.xl),
              child: Row(
                mainAxisSize: .min,
                spacing: AppSpacing.s - 2,
                children: [
                  Text(actionText!, style: AppStyles.strongText(context).copyWith(color: AppColors.tint.adaptTo(context))),
                  if (actionIcon != null) HugeIcon(icon: actionIcon!, size: AppSizes.smallIcon, color: AppColors.tint.adaptTo(context)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
