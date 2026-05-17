import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/utility.dart';

class Tag extends StatelessWidget {
  final String text;
  final Color color;

  const Tag({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withBrightness(-.25),
        border: .all(color: color),
        borderRadius: .circular(24),
      ),
      padding: .symmetric(horizontal: 8, vertical: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, letterSpacing: .3, fontWeight: .w900, color: AppColors.white),
      ),
    );
  }
}
