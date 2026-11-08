import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/utility.dart';

class CustomIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color? color;
  final double? size;
  final double? strokeWidth;

  const CustomIcon({super.key, required this.icon, this.color, this.size = 24.0, this.strokeWidth = 1});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: color?.a ?? 1,
      child: AppIcon(key: super.key, icon: icon, color: color?.withTransparency(1) ?? AppColors.text.adaptTo(context), size: size, strokeWidth: strokeWidth),
    );
  }
}
