import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';

/// Options side by side in a sunken track; the selected one is a raised card that slides to it
class SegmentedControl<T> extends StatefulWidget {
  final Map<String, T> options;
  final void Function(T) onTap;
  final int defaultIndex;
  final PageController? pageController;

  const SegmentedControl({super.key, required this.options, required this.onTap, this.defaultIndex = 0, this.pageController});

  @override
  State<SegmentedControl<T>> createState() => _SegmentedControlState();
}

class _SegmentedControlState<T> extends State<SegmentedControl<T>> {
  late int _selectedIndex = widget.defaultIndex;
  late bool pageChangedManually = false;

  @override
  void initState() {
    super.initState();
    widget.pageController?.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    if (pageChangedManually) {
      pageChangedManually = false;
      return;
    }
    setState(() => _selectedIndex = widget.pageController?.page?.round() ?? _selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.options.entries.toList();
    final totalOptions = entries.length;
    final isDark = AppColors.isDark(context);

    return Container(
      height: 46,
      padding: const .all(4),
      decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: .circular(AppRadius.m)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: AppDurations.normal,
            curve: Curves.easeOutCubic,
            alignment: Alignment(totalOptions <= 1 ? 0 : (_selectedIndex / (totalOptions - 1) * 2) - 1, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / totalOptions,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.secondaryButton.adaptTo(context) : AppColors.secondaryBackground.adaptTo(context),
                  borderRadius: .circular(AppRadius.m - 4),
                  boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: isDark ? .3 : .08), blurRadius: 6, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: .stretch,
            children: List.generate(totalOptions, (index) {
              final entry = entries[index];
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  behavior: .opaque,
                  onTap: () {
                    pageChangedManually = true;
                    setState(() => _selectedIndex = index);
                    widget.onTap(entry.value);
                  },
                  child: Padding(
                    padding: const .symmetric(horizontal: 8),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: AppDurations.fast,
                        style: AppStyles.callout(context).copyWith(
                          fontWeight: isSelected ? .w600 : .w500,
                          color: (isSelected ? AppColors.text : AppColors.secondaryText).adaptTo(context),
                        ),
                        child: Text(entry.key, maxLines: 1, overflow: .ellipsis),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
