import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/utility.dart';

class CupertinoPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Duration duration;
  final BoxConstraints? constraints;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const CupertinoPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 120),
    this.constraints,
    this.decoration,
    this.padding,
    this.height
  });

  @override
  State<CupertinoPressable> createState() => _CupertinoPressableState();
}

class _CupertinoPressableState extends State<CupertinoPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      onTap:
          widget.onTap == null
              ? null
              : () {
                widget.onTap!();

                setState(() => _pressed = true);
                Future.delayed(widget.duration, () => setState(() => _pressed = false));
              },

      child: AnimatedContainer(
        duration: _pressed ? Duration.zero : widget.duration,
        constraints: widget.constraints,
        padding: widget.padding,
        decoration: widget.decoration,
        height: widget.height,

        foregroundDecoration: BoxDecoration(
          color: _pressed ? (AppColors.background.adaptTo(context).withTransparency(.25)) : null,
          borderRadius: widget.borderRadius ?? widget.decoration?.borderRadius,
        ),
        child: widget.child,
      ),
    );
  }
}
