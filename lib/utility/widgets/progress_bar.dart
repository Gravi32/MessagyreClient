import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color? color;
  final Gradient? gradient;

  const ProgressBar({super.key, required this.progress, this.height = 8, this.color = AppColors.accent, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  gradient: gradient,
                  border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
