import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final bool centered;
  final Color? color;
  final Gradient? gradient;

  const ProgressBar({super.key, required this.progress, this.height = 8, this.centered = false, this.color = AppColors.accent, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!centered) {
            return Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: progress.clamp(0.0, 1.0), child: buildBar(context)));
          }

          final width = constraints.maxWidth;
          final clampedProgress = progress.clamp(-1.0, 1.0);

          final barWidth = width * clampedProgress.abs() / 2;
          final center = width / 2;

          final left = clampedProgress >= 0 ? center : center - barWidth;

          return Stack(children: [Positioned(left: left, width: barWidth, top: 0, bottom: 0, child: buildBar(context))]);
        },
      ),
    );
  }

  Widget buildBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
