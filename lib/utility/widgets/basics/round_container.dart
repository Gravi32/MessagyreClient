import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/graphics/blurred_container.dart';
import 'package:messagyre_client/utility/utility.dart';

class RoundContainer extends StatelessWidget {
  final bool transparent;
  final bool enabled;
  final bool blurOnly;
  final Color? color;
  final EdgeInsets? padding;
  final Widget? child;

  const RoundContainer({super.key, this.transparent = true, this.enabled = true, this.blurOnly = false, this.color, this.padding, this.child});

  static final borderRadius = BorderRadius.circular(24);

  @override
  Widget build(BuildContext context) {
    final finalButtonColor = enabled ? (color ?? AppColors.secondaryBackground.adaptTo(context)) : AppColors.inactive.adaptTo(context);

    return BlurredContainer(
      borderRadius: borderRadius,
      enabled: transparent,
      child: Opacity(
        opacity: enabled ? 1 : .5,
        child: Container(
          padding: padding ?? .all(16),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: blurOnly ? AppColors.transparent : (transparent && finalButtonColor.a > 0 ? finalButtonColor.withTransparency(.5) : finalButtonColor),
            border: .all(width: 2, color: finalButtonColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
