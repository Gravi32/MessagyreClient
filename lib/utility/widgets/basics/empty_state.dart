import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';

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
          // The icon on a soft purple disc, over the app's Gymnase drawn large and faint
          SizedBox(
            width: 150,
            height: 110,
            child: Stack(
              alignment: .center,
              children: [
                GymnaseMark(size: 130, color: MarkWatermark.faint(context, surface: AppColors.background.adaptTo(context))),
                Container(
                  width: 80,
                  height: 80,
                  alignment: .center,
                  decoration: BoxDecoration(
                    shape: .circle,
                    color: AppColors.secondaryBackground.adaptTo(context),
                    border: .all(color: AppColors.outline.adaptTo(context)),
                    boxShadow: [BoxShadow(color: AppColors.cardLip.adaptTo(context), offset: const Offset(0, 3))],
                  ),
                  child: _Float(child: AppIcon(icon: icon, strokeWidth: 1.8, size: 36, color: AppColors.tint.adaptTo(context))),
                ),
              ],
            ),
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
                  if (actionIcon != null) AppIcon(icon: actionIcon!, size: AppSizes.smallIcon, color: AppColors.tint.adaptTo(context)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pops in once with a little bounce (an endless movement would keep the phone drawing for nothing)
class _Float extends StatelessWidget {
  final Widget child;
  const _Float({required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutBack,
    child: child,
    builder: (context, value, child) => Transform.translate(
      offset: Offset(0, 8 * (1 - value)),
      child: Transform.scale(scale: .8 + .2 * value, child: child),
    ),
  );
}
