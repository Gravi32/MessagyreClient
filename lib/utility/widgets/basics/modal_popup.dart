import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';

/// A small panel rising from the bottom (a date, a number to pick): the same card as the [ActionSheet]s
class ModalPopup extends StatelessWidget {
  final Widget child;
  final TopBar? topBar;
  final double? height;
  final List<Widget>? decorations;

  const ModalPopup({super.key, required this.child, this.topBar, this.height, this.decorations});

  @override
  Widget build(BuildContext context) {
    final floating = topBar != null;

    return SafeArea(
      top: false,
      bottom: floating,
      // Without a bar it is a preview laid in a page (the calendar settings)
      minimum: floating ? const .fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.l) : .zero,
      child: Container(
        clipBehavior: .antiAlias,
        padding: const .fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          borderRadius: .circular(AppRadius.card),
          border: .all(color: AppColors.outline.adaptTo(context)),
          boxShadow: !floating
              ? null
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: AppColors.isDark(context) ? .4 : .12),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: .min,
          spacing: AppSpacing.m,
          children: [
            ?topBar,
            SizedBox(height: height, child: child),
            ...?decorations,
          ],
        ),
      ),
    );
  }
}
