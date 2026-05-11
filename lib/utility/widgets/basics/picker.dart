import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';

class Picker extends StatelessWidget {
  final FixedExtentScrollController? controller;
  final void Function(int)? onChanged;
  final List<Widget> children;

  const Picker({super.key, this.controller, this.onChanged, required this.children});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: .center,
      children: [
        RoundContainer(height: 32, margin: .symmetric(horizontal: 4), color: AppColors.tertiaryBackground.adaptTo(context)),

        CupertinoPicker(
          scrollController: controller,
          itemExtent: 32,
          selectionOverlay: null,
          onSelectedItemChanged: onChanged,
          squeeze: .9,
          diameterRatio: 10,
          children: children,
        ),
      ],
    );
  }
}
