import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';

class ModalPopup extends StatelessWidget {
  final Widget child;
  final TopBar? topBar;
  final double? height;
  final List<Widget>? decorations;

  const ModalPopup({super.key, required this.child, this.topBar, this.height, this.decorations});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: RoundContainer(
        padding: .all(16).copyWith(top: topBar == null ? null : 0),
        margin: topBar == null ? .zero : .all(10),
        child: Column(
          mainAxisSize: .min,
          spacing: 8,
          children: [
            if (topBar != null) topBar!,

            SizedBox(height: height, child: child),

            ...decorations ?? [],
          ],
        ),
      ),
    );
  }
}
