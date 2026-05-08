import 'package:flutter/material.dart';

class ConstrainedAspectRatio extends StatelessWidget {
  final Widget child;
  final double? maxAspectRatio;
  final Axis mainAxis;

  const ConstrainedAspectRatio({super.key, required this.child, this.maxAspectRatio, this.mainAxis = .horizontal});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size limit = Size(constraints.maxHeight, constraints.maxWidth) * (maxAspectRatio ?? 1);
        return Container(
          constraints: BoxConstraints(
            maxHeight: mainAxis == .horizontal ? limit.height : double.infinity,
            maxWidth: mainAxis == .vertical ? limit.width : double.infinity,
          ),
          child: child,
        );
      },
    );
  }
}
