import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';

/// Chooses a grade from 1 to 6 by half points: a ruler with the six whole grades written under it, a round handle
/// carrying the grade, to drag or to tap anywhere on the ruler, and − / + for half a point. The part of the ruler
/// up to the grade is filled (red under 4, orange just under it).
///
/// [onAccent]: drawn in white, for a card on the icon's gradient.
class GradePicker extends StatelessWidget {
  final double grade;
  final Function(double) onGradeChanged;
  final bool onAccent;

  const GradePicker({super.key, required this.grade, required this.onGradeChanged, this.onAccent = false});

  static const double min = 1, max = 6, step = .5;
  static const double _thumb = 38, _track = 10;

  void _set(double value) {
    final snapped = ((value / step).round() * step).clamp(min, max);
    if (snapped == grade) return;
    HapticFeedback.selectionClick();
    onGradeChanged(snapped);
  }

  Color _fill(BuildContext context) {
    if (grade < 3.75) return onAccent ? const Color.fromRGBO(255, 130, 120, 1) : AppColors.red;
    if (grade < 4) return onAccent ? const Color.fromRGBO(255, 190, 90, 1) : AppColors.orange;
    return onAccent ? AppColors.white : AppColors.accent;
  }

  Widget _stepButton(BuildContext context, List<List<dynamic>> icon, double delta) {
    final enabled = (grade + delta) >= min && (grade + delta) <= max;
    final background = onAccent ? AppColors.white.withValues(alpha: .18) : AppColors.tertiaryBackground.adaptTo(context);
    final foreground = onAccent ? AppColors.white : AppColors.text.adaptTo(context);

    return CupertinoButton(
      padding: .zero,
      minimumSize: .zero,
      pressedOpacity: .5,
      onPressed: enabled ? () => _set(grade + delta) : null,
      child: Container(
        width: 40,
        height: 40,
        alignment: .center,
        decoration: BoxDecoration(shape: .circle, color: background),
        child: AppIcon(icon: icon, size: 20, strokeWidth: 2.4, color: foreground.withValues(alpha: enabled ? 1 : .3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fill = _fill(context);
    final track = onAccent ? AppColors.white.withValues(alpha: .22) : AppColors.tertiaryBackground.adaptTo(context);
    final labels = onAccent ? AppColors.white.withValues(alpha: .75) : AppColors.tertiaryText.adaptTo(context);

    return Row(
      spacing: 10,
      children: [
        _stepButton(context, HugeIcons.strokeRoundedMinusSign, -step),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth - _thumb;
              double xOf(double value) => _thumb / 2 + (value - min) / (max - min) * width;
              double valueAt(double x) => min + ((x - _thumb / 2) / width).clamp(0, 1) * (max - min);
              final x = xOf(grade);

              return GestureDetector(
                behavior: .opaque,
                onTapDown: (details) => _set(valueAt(details.localPosition.dx)),
                onHorizontalDragUpdate: (details) => _set(valueAt(details.localPosition.dx)),
                child: SizedBox(
                  height: 64,
                  child: Stack(
                    clipBehavior: .none,
                    children: [
                      // The ruler
                      Positioned(
                        left: _thumb / 2 - _track / 2,
                        right: _thumb / 2 - _track / 2,
                        top: _thumb / 2 - _track / 2,
                        height: _track,
                        child: Container(decoration: BoxDecoration(color: track, borderRadius: .circular(_track))),
                      ),
                      // Filled up to the grade
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 120),
                        left: _thumb / 2 - _track / 2,
                        width: x - _thumb / 2 + _track,
                        top: _thumb / 2 - _track / 2,
                        height: _track,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(color: fill, borderRadius: .circular(_track)),
                        ),
                      ),
                      // A notch at each half point
                      for (var value = min; value <= max; value += step)
                        if (value != grade)
                          Positioned(
                            left: xOf(value) - 2,
                            top: _thumb / 2 - 2,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: .circle,
                                color: value < grade
                                    ? (onAccent ? AppColors.accent : AppColors.white).withValues(alpha: .5)
                                    : labels.withValues(alpha: .5),
                              ),
                            ),
                          ),
                      // The whole grades under the ruler
                      for (var value = min; value <= max; value++)
                        Positioned(
                          left: xOf(value) - 12,
                          width: 24,
                          top: _thumb + 4,
                          child: Text(
                            value.toInt().toString(),
                            textAlign: .center,
                            style: AppStyles.caption(context).copyWith(
                              fontFamily: AppStyles.titleFontFamily,
                              fontWeight: .w600,
                              color: grade.floor() == value ? (onAccent ? AppColors.white : AppColors.text.adaptTo(context)) : labels,
                            ),
                          ),
                        ),
                      // The handle, with the grade on it
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 120),
                        left: x - _thumb / 2,
                        top: 0,
                        width: _thumb,
                        height: _thumb,
                        child: Container(
                          alignment: .center,
                          decoration: BoxDecoration(
                            shape: .circle,
                            color: onAccent ? AppColors.white : AppColors.secondaryBackground.adaptTo(context),
                            border: .all(color: fill, width: 3),
                            boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: .22), offset: const Offset(0, 3))],
                          ),
                          child: Text(
                            GradeDisplay.format(grade),
                            textScaler: .noScaling,
                            style: AppStyles.strongText(context).copyWith(
                              fontFamily: AppStyles.titleFontFamily,
                              fontWeight: .w700,
                              fontSize: AppStyles.sizeSubheadline,
                              color: onAccent ? AppColors.accent : AppColors.text.adaptTo(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _stepButton(context, HugeIcons.strokeRoundedPlusSign, step),
      ],
    );
  }
}
