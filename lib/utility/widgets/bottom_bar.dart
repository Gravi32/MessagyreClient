import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';

/// The tabs, in a floating dock: a purple pill (the app icon's gradient, with its Gymnase in watermark) slides with a
/// little bounce under the selected tab, whose icon pops up. Opaque, so it needs no blur over the content under it.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  /// Height of the dock itself
  static const double dockHeight = 66;

  /// Room between the dock and the pill
  static const double _inset = 6;

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
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          borderRadius: .circular(AppRadius.xl),
          border: .all(color: AppColors.outline.adaptTo(context)),
          // The same solid lip as the cards, a little thicker: the dock sits on the page like a sticker
          boxShadow: [BoxShadow(color: AppColors.cardLip.adaptTo(context), offset: const Offset(0, 4))],
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: MainPage.pageIndex,
          builder: (context, currentIndex, _) => LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / App.pages.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    left: tabWidth * currentIndex + 3,
                    top: _inset,
                    bottom: _inset,
                    width: tabWidth - 6,
                    child: const _Pill(),
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
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The selected tab's background: the icon's gradient with its Gymnase, faint, in the corner
class _Pill extends StatelessWidget {
  const _Pill();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: .antiAlias,
      decoration: BoxDecoration(
        borderRadius: .circular(AppRadius.l),
        gradient: AppColors.accentGradient,
        boxShadow: const [BoxShadow(color: Color.fromRGBO(70, 8, 78, 1), offset: Offset(0, 3))],
      ),
      child: Stack(
        clipBehavior: .hardEdge,
        children: [
          Positioned(right: -10, bottom: -14, child: GymnaseMark(size: 46, color: AppColors.white.withValues(alpha: .16))),
        ],
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
    final color = isSelected ? AppColors.white : AppColors.secondaryText.adaptTo(context);

    return CupertinoButton(
      padding: .zero,
      minimumSize: .zero,
      pressedOpacity: .7,
      onPressed: onTap,
      child: Column(
        mainAxisAlignment: .center,
        spacing: 2,
        children: [
          Stack(
            clipBehavior: .none,
            children: [
              // The selected icon pops: a bigger, bolder icon, bounced in
              AnimatedScale(
                scale: isSelected ? 1.12 : 1,
                duration: const Duration(milliseconds: 380),
                curve: Curves.elasticOut,
                child: HugeIcon(icon: page.icon, size: 22, strokeWidth: isSelected ? 2.2 : 1.7, color: color),
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
                            color: isSelected ? AppColors.white : AppColors.accent,
                            border: .all(color: isSelected ? AppColors.accent : AppColors.secondaryBackground.adaptTo(context), width: 2),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          // Shrinks a long name ("Conversations") to fit a narrow phone rather than cutting it
          Padding(
            padding: const .symmetric(horizontal: 8),
            child: FittedBox(
              fit: .scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: AppDurations.fast,
                style: AppStyles.caption(context).copyWith(fontFamily: AppStyles.titleFontFamily, fontWeight: isSelected ? .w600 : .w500, color: color),
                child: Text(page.name, maxLines: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
