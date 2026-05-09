import 'package:flutter/material.dart';

class BottomSpacing extends StatelessWidget {
  final double height;
  final bool includeBottomBar;

  const BottomSpacing({super.key, this.height = 16, this.includeBottomBar = false});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final bottomBarHeight = includeBottomBar ? 80 : 0;
    return SizedBox(height: bottomPadding + bottomBarHeight + height);
  }
}
