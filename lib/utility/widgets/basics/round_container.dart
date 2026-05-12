import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/graphics/blurred_container.dart';
import 'package:messagyre_client/utility/utility.dart';

class RoundContainer extends StatelessWidget {
  final bool transparent;
  final bool enabled;
  final bool borderOnly;
  final bool blurOnly;
  final Color? color;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Widget? child;
  final double? height;
  final double? width;
  final double opacity;
  final double blurAmount;
  final double borderRadius;

  const RoundContainer({
    super.key,
    this.transparent = true,
    this.enabled = true,
    this.borderOnly = false,
    this.blurOnly = false,
    this.color,
    this.padding,
    this.margin,
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
      enabled: transparent,
      blur: blurAmount,
      child: Opacity(
        opacity: enabled ? opacity : .5,
        child: Container(
          height: height,
          width: width,
          padding: padding ?? .all(16),
          decoration: BoxDecoration(
            borderRadius: .circular(borderRadius),
            color: borderOnly ? AppColors.transparent : (transparent && finalButtonColor.a > 0 ? finalButtonColor.withTransparency(.5) : finalButtonColor),
            border: .all(width: 2, color: blurOnly ? AppColors.transparent : finalButtonColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
