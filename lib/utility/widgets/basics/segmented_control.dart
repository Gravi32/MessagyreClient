import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';

class SegmentedControl<T> extends StatefulWidget {
  final Map<String, T> options;
  final void Function(T) onTap;
  final int defaultIndex;

  const SegmentedControl({super.key, required this.options, required this.onTap, this.defaultIndex = 0});

  @override
  State<SegmentedControl<T>> createState() => _SegmentedControlState();
}

class _SegmentedControlState<T> extends State<SegmentedControl<T>> {
  late int _selectedIndex = widget.defaultIndex;

  @override
  Widget build(BuildContext context) {
    final entries = widget.options.entries.toList();
    final totalOptions = entries.length;

    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          RoundContainer(),

          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment(totalOptions <= 1 ? 0 : (_selectedIndex / (totalOptions - 1) * 2) - 1, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / totalOptions,
              child: RoundContainer(color: AppColors.tertiaryBackground.adaptTo(context)),
            ),
          ),

          Row(
            mainAxisAlignment: .spaceAround,
            crossAxisAlignment: .stretch,
            children: List.generate(totalOptions, (index) {
              final entry = entries[index];
              return Expanded(
                child: GestureDetector(
                  behavior: .opaque,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    widget.onTap(entry.value);
                  },
                  child: Center(
                    child: Text(entry.key, style: TextStyle(fontWeight: _selectedIndex == index ? .bold : .normal)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
