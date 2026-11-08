import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/main.dart';

/// The tabs, in a floating dock stuck on the page like a sticker (solid lip, no blur). Each tab is an icon over its
/// name; the selected one gets a purple capsule behind its icon that grows in with a bounce, and its name turns
/// purple and bold. A name too long for a narrow phone ends with "…" (never shrunk, never cut mid-letter).
class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  /// Height of the dock itself
  static const double dockHeight = 64;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final background = AppColors.background.adaptTo(context);

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
        padding: const .symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          borderRadius: .circular(AppRadius.xl),
          border: .all(color: AppColors.outline.adaptTo(context)),
          boxShadow: [BoxShadow(color: AppColors.cardLip.adaptTo(context), offset: const Offset(0, 4))],
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: MainPage.pageIndex,
          builder: (context, currentIndex, _) => Row(
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

  static const double _capsuleWidth = 52, _capsuleHeight = 30;

  @override
  Widget build(BuildContext context) {
    final idle = AppColors.secondaryText.adaptTo(context);
    final selectedText = AppColors.isDark(context) ? const Color.fromRGBO(214, 120, 226, 1) : AppColors.accent;

    return GestureDetector(
      behavior: .opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: .center,
        spacing: 3,
        children: [
          SizedBox(
            width: _capsuleWidth,
            height: _capsuleHeight + 3,
            child: Stack(
              clipBehavior: .none,
              alignment: .topCenter,
              children: [
                // The capsule: grows from the icon with a bounce, on a darker lip like the buttons
                AnimatedScale(
                  scale: isSelected ? 1 : .4,
                  duration: const Duration(milliseconds: 420),
                  curve: isSelected ? Curves.elasticOut : Curves.easeIn,
                  child: AnimatedOpacity(
                    opacity: isSelected ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      width: _capsuleWidth,
                      height: _capsuleHeight,
                      decoration: BoxDecoration(
                        borderRadius: .circular(_capsuleHeight / 2),
                        gradient: AppColors.accentGradient,
                        boxShadow: const [BoxShadow(color: Color.fromRGBO(70, 8, 78, 1), offset: Offset(0, 3))],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: _capsuleHeight,
                  child: Center(
                    child: Stack(
                      clipBehavior: .none,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.08 : 1,
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.elasticOut,
                          child: HugeIcon(
                            icon: page.icon,
                            size: 22,
                            strokeWidth: isSelected ? 2.2 : 1.7,
                            color: isSelected ? AppColors.white : idle,
                          ),
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
                                      color: isSelected ? AppColors.white : AppColors.red,
                                      border: .all(color: isSelected ? AppColors.accent : AppColors.secondaryBackground.adaptTo(context), width: 2),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // On a narrow phone (or with large text) a long name ends with "…" instead of shrinking
          Padding(
            padding: const .symmetric(horizontal: 2),
            child: AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: AppStyles.caption(context).copyWith(
                fontFamily: AppStyles.titleFontFamily,
                fontWeight: isSelected ? .w700 : .w500,
                color: isSelected ? selectedText : idle,
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
