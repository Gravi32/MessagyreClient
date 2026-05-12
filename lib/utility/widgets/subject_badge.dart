import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';

class SubjectBadge extends StatelessWidget {
  final Subject? subject;
  final double size;

  const SubjectBadge({super.key, required this.subject, this.size = 36});

  final defaultColor = AppColors.grey;
  final defaultIcon = Icons.question_mark_rounded;

  @override
  Widget build(BuildContext context) {
    final color = subject?.color ?? defaultColor;
    final icon = subject?.icon ?? defaultIcon;

    return SizedBox.square(
      dimension: size,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: .all(color: color.withAlpha(100), strokeAlign: BorderSide.strokeAlignInside, width: 1.5),
          borderRadius: .circular(12),
        ),
        child: Center(
          child: Icon(icon, color: AppColors.white, size: size * (1 - size / 70)),
        ),
      ),
    );
  }
}
