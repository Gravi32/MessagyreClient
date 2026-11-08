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
          borderRadius: .circular(size * .3),
        ),
        child: Center(
          child: Icon(icon, color: AppColors.white, size: size * (1 - size / 70)),
        ),
      ),
    );
  }
}

/// The leading of a "Branche" row: the generic icon ([child]) until a subject is chosen, then that subject's badge.
/// Typing something else in the field ([controller]) brings the icon back.
class SubjectLeading extends StatelessWidget {
  final Subject? subject;
  final TextEditingController controller;
  final Widget child;
  final double size;

  const SubjectLeading({super.key, required this.subject, required this.controller, required this.child, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final chosen = subject != null && value.text.trim() == subject!.name.trim();
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
          child: chosen ? SubjectBadge(key: ValueKey(subject!.code), subject: subject, size: size) : KeyedSubtree(key: const ValueKey("none"), child: child),
        );
      },
    );
  }
}
