import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/progress_bar.dart';

class NumberedProgressBar extends StatelessWidget {
  final String lowerBound;
  final String upperBound;
  final double progress;
  final String value;
  final Color color;
  final bool centered;
  final double fontSize;
  final double? barHeight;

  const NumberedProgressBar({
    super.key,
    required this.lowerBound,
    required this.upperBound,
    required this.progress,
    required this.value,
    this.color = AppColors.accent,
    this.centered = false,
    this.fontSize = 32,
    this.barHeight
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, backgroundColor: color);

    final textSize = measureTextSize(value, textStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: (barHeight ?? 2) / 2,
      children: [
        SizedBox(height: max(textSize.height - 22, 0)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(lowerBound), Text(upperBound)]),

        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            double position;

            if (!centered) {
              final p = progress.clamp(0.0, 1.0);
              position = width * p;
            } else {
              final p = progress.clamp(-1.0, 1.0);
              final center = width / 2;
              position = center + (p * width / 2);
            }

            final left = (position - textSize.width / 2).clamp(0.0, width - textSize.width);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                ProgressBar(
                  progress: progress,
                  centered: centered,
                  gradient: LinearGradient(
                    colors: [color, color.withBrightness(.15)],
                    stops: [.5, 1],
                    transform: GradientRotation(centered && progress < 0 ? pi : 0),
                  ),
                  height: barHeight,
                ),

                Positioned(
                  left: left - 8,
                  bottom: barHeight ?? 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [AppColors.secondaryBackground.adaptTo(context), AppColors.secondaryBackground.adaptTo(context).withAlpha(0)],
                        stops: [.5, .95],
                        radius: 1,
                      ),
                    ),
                    child: Text(value, style: textStyle.copyWith(backgroundColor: AppColors.transparent)),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
