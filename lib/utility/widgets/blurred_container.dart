import 'package:flutter/material.dart';
import 'dart:ui';

class BlurredContainer extends StatelessWidget {
  final Widget? child;
  final double blur;
  final double blurOpacity;

  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Decoration? decoration;
  final Decoration? foregroundDecoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Clip clipBehavior;

  const BlurredContainer({
    super.key,
    this.child,
    this.blur = 10.0,
    this.blurOpacity = 0.1,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.clipBehavior = Clip.none,
  });

  Decoration _buildDecoration() {
    if (decoration is BoxDecoration) {
      final boxDeco = decoration as BoxDecoration;
      return boxDeco.copyWith(color: (color ?? boxDeco.color ?? Colors.white).withValues(alpha: blurOpacity));
    }

    return BoxDecoration(color: (color ?? Colors.white).withValues(alpha: blurOpacity));
  }

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = BorderRadius.zero;
    if (decoration is BoxDecoration) {
      borderRadius = (decoration as BoxDecoration).borderRadius as BorderRadius? ?? BorderRadius.zero;
    }

    final Decoration finalDecoration = _buildDecoration();

    return Container(
      key: key,
      alignment: alignment,
      margin: margin,
      width: width,
      height: height,
      constraints: constraints,
      transform: transform,
      transformAlignment: transformAlignment,
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(padding: padding, decoration: finalDecoration, foregroundDecoration: foregroundDecoration, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
