import 'package:flutter/material.dart';

class ConstrainedAspectRatio extends StatelessWidget {
  final Widget child;
  final double maxAspectRatio;

  const ConstrainedAspectRatio({super.key, required this.child, this.maxAspectRatio = 1.5});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeightLimit = maxWidth * maxAspectRatio;

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeightLimit),
          child: child,
        );
      },
    );
  }
}
