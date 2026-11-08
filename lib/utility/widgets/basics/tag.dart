import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';

class Tag extends StatelessWidget {
  final String text;
  final Color color;

  const Tag({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return RoundContainer(
      color: color,
      transparent: false,
      borderRadius: 10,
      padding: .symmetric(horizontal: 8, vertical: 3),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: .fade,
        style: TextStyle(fontSize: 13, letterSpacing: .4, fontWeight: .w800, color: AppColors.white),
      ),
    );
  }
}
