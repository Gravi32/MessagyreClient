import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/main.dart';

/// The tabs, in a floating dock: the selected one sits on a soft grey pill.
/// Opaque, so it needs no blur over the content scrolling under it.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  /// Height of the dock itself
  static const double dockHeight = 66;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final background = AppColors.background.adaptTo(context);
    final isDark = AppColors.isDark(context);

    return Container(
      height: bottomPadding + AppSizes.bottomBar,
      alignment: .bottomCenter,
      padding: .only(bottom: bottomPadding > 0 ? bottomPadding : AppSpacing.m, left: AppSpacing.m, right: AppSpacing.m),
      // The content fades out under the dock
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: .topCenter,
          end: .bottomCenter,
          colors: [background.withValues(alpha: 0), background.withValues(alpha: .92)],
          stops: const [0, .55],
        ),
      ),
      child: Container(
        height: dockHeight,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          borderRadius: .circular(AppRadius.l),
          border: .all(color: AppColors.outline.adaptTo(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: isDark ? .35 : .06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: MainPage.pageIndex,
          builder: (context, currentIndex, _) => Row(
            children: App.pages
                .mapIndexed(
                  (index, page) => Expanded(
                    child: _Tab(page: page, isSelected: index == currentIndex, onTap: () => MainPage.pageIndex.value = index),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final AppPage page;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({required this.page, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final idle = AppColors.tertiaryText.adaptTo(context);
    final active = AppColors.text.adaptTo(context);

    return CupertinoButton(
      padding: .zero,
      minimumSize: .zero,
      pressedOpacity: .6,
      onPressed: onTap,
      child: Column(
        mainAxisAlignment: .center,
        spacing: 3,
        children: [
          Stack(
            clipBehavior: .none,
            children: [
              AnimatedContainer(
                duration: AppDurations.normal,
                curve: Curves.easeOutCubic,
                width: 48,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: .circular(15),
                  color: isSelected ? AppColors.tertiaryBackground.adaptTo(context) : AppColors.tertiaryBackground.adaptTo(context).withValues(alpha: 0),
                ),
                alignment: .center,
                child: HugeIcon(icon: page.icon, size: 21, color: isSelected ? active : idle),
              ),
              // A dot for something new in that tab
              ValueListenableBuilder(
                valueListenable: page.showBadge,
                builder: (context, showBadge, _) => !showBadge
                    ? const SizedBox.shrink()
                    : Positioned(
                        top: -2,
                        right: 2,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: .circle,
                            color: AppColors.accent,
                            border: .all(color: AppColors.secondaryBackground.adaptTo(context), width: 2),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          // Shrinks a long name ("Conversations") to fit a narrow phone rather than cutting it
          Padding(
            padding: const .symmetric(horizontal: 2),
            child: FittedBox(
              fit: .scaleDown,
              child: Text(
                page.name,
                maxLines: 1,
                style: AppStyles.caption(context).copyWith(fontWeight: isSelected ? .w600 : .w500, color: isSelected ? active : idle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
