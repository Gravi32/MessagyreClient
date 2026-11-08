import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/graphics/blurred_container.dart';
import 'package:messagyre_client/utility/utility.dart';

/// A rounded surface. [transparent] gives it a see-through fill; [blur] also blurs what is behind it, which is
/// expensive (a BackdropFilter): only for surfaces that float over scrolling content.
class RoundContainer extends StatelessWidget {
  final bool transparent;
  final bool blur;
  final bool enabled;
  final bool borderOnly;
  final bool blurOnly;
  final Color? color;

  /// Fills it instead of [color] (the main buttons: the app icon's gradient)
  final Gradient? gradient;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxConstraints? constraints;
  final Widget? child;
  final double? height;
  final double? width;
  final double opacity;
  final double blurAmount;
  final double borderRadius;

  const RoundContainer({
    super.key,
    this.transparent = true,
    this.blur = false,
    this.enabled = true,
    this.borderOnly = false,
    this.blurOnly = false,
    this.color,
    this.gradient,
    this.padding,
    this.margin,
    this.constraints,
    this.child,
    this.height,
    this.width,
    this.opacity = 1,
    this.blurAmount = 15,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final finalButtonColor = enabled ? (color ?? AppColors.secondaryBackground.adaptTo(context)) : AppColors.inactive.adaptTo(context);

    return BlurredContainer(
      margin: margin,
      height: height,
      width: width,
      borderRadius: .circular(borderRadius),
      enabled: transparent && blur,
      blur: blurAmount,
      constraints: constraints,
      child: Opacity(
        opacity: enabled ? opacity : .5,
        child: Container(
          height: height,
          width: width,
          constraints: constraints,
          padding: padding ?? .all(16),
          decoration: BoxDecoration(
            borderRadius: .circular(borderRadius),
            color: gradient != null && enabled
                ? null
                : (borderOnly ? AppColors.transparent : (transparent && finalButtonColor.a > 0 ? finalButtonColor.withTransparency(.5) : finalButtonColor)),
            gradient: enabled ? gradient : null,
            border: .all(width: 2, color: blurOnly || (gradient != null && enabled) ? AppColors.transparent : finalButtonColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
