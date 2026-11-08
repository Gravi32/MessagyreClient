import 'dart:ui';

import 'package:flutter/cupertino.dart';

class BlurredContainer extends StatelessWidget {
  final double blur;
  final bool enabled;
  final BorderRadius? borderRadius;
  final Widget? child;
  final Widget? blurredChild;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxConstraints? constraints;
  final Border? border;
  final double? height;
  final double? width;

  const BlurredContainer({
    super.key,
    this.child,
    this.blurredChild,
    this.blur = 15,
    this.borderRadius,
    this.enabled = true,
    this.padding,
    this.margin,
    this.constraints,
    this.border,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    // A BackdropFilter costs a full read of the screen behind it even with a zero blur: without blur, none at all
    if (!enabled || blur <= 0) {
      return Padding(
        padding: margin ?? .zero,
        child: ClipRRect(
          borderRadius: borderRadius ?? .circular(24),
          child: Stack(
            children: [
              if (blurredChild != null) Positioned.fill(child: blurredChild!),
              Container(
                padding: padding,
                height: height,
                width: width,
                constraints: constraints,
                decoration: BoxDecoration(borderRadius: borderRadius, border: border),
                child: child ?? SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: margin ?? .zero,
      child: ClipRRect(
        borderRadius: borderRadius ?? .circular(24),
        child: Stack(
          children: [
            if (blurredChild != null) Positioned.fill(child: blurredChild!),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                padding: padding,
                height: height,
                width: width,
                constraints: constraints,
                decoration: BoxDecoration(borderRadius: borderRadius, border: border),
                child: child ?? SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
