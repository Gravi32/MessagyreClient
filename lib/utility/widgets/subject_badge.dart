import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';

class SubjectBadge extends StatelessWidget {
  final Subject subject;
  final double size;

  const SubjectBadge({super.key, required this.subject, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Container(
        decoration: BoxDecoration(
          color: subject.color,
          border: Border.all(color: subject.color.withAlpha(100), strokeAlign: BorderSide.strokeAlignOutside, width: 1.5),
          borderRadius: BorderRadius.circular(size / 3.6),
        ),
        child: Center(child: Icon(subject.icon, color: AppColors.white, size: size * (1 - size / 70))),
      ),
    );
  }
}
