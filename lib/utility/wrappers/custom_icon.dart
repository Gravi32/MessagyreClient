import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

class CustomIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color? color;
  final double? size;
  final double? strokeWidth;

  const CustomIcon({super.key, required this.icon, this.color = AppColors.accent, this.size = 24.0, this.strokeWidth = 1});

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: color?.a ?? 1, child: HugeIcon(key: super.key, icon: icon, color: color?.withAlpha(255), size: size, strokeWidth: strokeWidth));
  }
}
