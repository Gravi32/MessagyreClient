import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/main.dart';

/// The tabs, in a floating dock that looks like the app's cards (the same color, hairline and solid lip): the only
/// raised thing. The selected tab is marked flat, inside it: a faint purple pill slides under it (like a selected
/// item anywhere else in the app) and its icon and name turn purple. A name too long for a narrow phone ends with
/// "…" (never shrunk, never cut mid-letter).
class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  /// Height of the dock itself
  static const double dockHeight = 64;

  static const double _inset = 6;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final background = AppColors.background.adaptTo(context);
    final count = App.pages.length;

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
        padding: const .all(_inset),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          borderRadius: .circular(AppRadius.xl),
          border: .all(color: AppColors.outline.adaptTo(context)),
          boxShadow: [BoxShadow(color: AppColors.cardLip.adaptTo(context), offset: const Offset(0, 3))],
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: MainPage.pageIndex,
          builder: (context, currentIndex, _) => Stack(
            children: [
              // The selection: flat, it slides from tab to tab with a small overshoot
              AnimatedAlign(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                alignment: Alignment(count <= 1 ? 0 : currentIndex / (count - 1) * 2 - 1, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: Container(
                    margin: const .symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: AppColors.accentSoft.adaptTo(context), borderRadius: .circular(AppRadius.xl - _inset)),
                  ),
                ),
              ),
              Row(
                children: App.pages
                    .mapIndexed(
                      (index, page) => Expanded(
                        child: _Tab(
                          page: page,
                          isSelected: index == currentIndex,
                          onTap: () {
                            if (MainPage.pageIndex.value != index) HapticFeedback.selectionClick();
                            MainPage.pageIndex.value = index;
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
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
    final idle = AppColors.secondaryText.adaptTo(context);
    final selected = AppColors.tint.adaptTo(context);

    return GestureDetector(
      behavior: .opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: .center,
        spacing: 2,
        children: [
          Stack(
            clipBehavior: .none,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1,
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                child: AppIcon(icon: page.icon, size: 22, strokeWidth: isSelected ? 2.1 : 1.7, color: isSelected ? selected : idle),
              ),
              // A dot for something new in that tab
              ValueListenableBuilder(
                valueListenable: page.showBadge,
                builder: (context, showBadge, _) => !showBadge
                    ? const SizedBox.shrink()
                    : Positioned(
                        top: -3,
                        right: -5,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: .circle,
                            color: AppColors.red,
                            border: .all(color: AppColors.secondaryBackground.adaptTo(context), width: 2),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          // On a narrow phone (or with large text) a long name ends with "…" instead of shrinking
          Padding(
            padding: const .symmetric(horizontal: 3),
            child: AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: AppStyles.caption(context).copyWith(
                fontFamily: AppStyles.titleFontFamily,
                fontWeight: isSelected ? .w700 : .w500,
                color: isSelected ? selected : idle,
                height: 1.1,
              ),
              child: Text(
                page.name,
                maxLines: 1,
                overflow: .ellipsis,
                softWrap: false,
                textAlign: .center,
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
