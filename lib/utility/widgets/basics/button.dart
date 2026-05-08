import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/extensions/widget_extensions.dart';
import 'package:messagyre_client/utility/graphics/blurred_container.dart';
import 'package:messagyre_client/utility/utility.dart';

class Button extends StatelessWidget {
  final Axis direction;
  final bool transparent;
  final bool enabled;
  final bool isLoading;
  final List<List>? icon;
  final IconData? legacyIcon;
  final double spacing;
  final FontWeight textWeight;
  final Color? color;
  final Color? textColor;
  final Color? iconColor;
  final Function()? onTap;
  final String? text;
  final EdgeInsets? padding;

  static final borderRadius = BorderRadius.circular(34);

  const Button({
    super.key,
    this.text,
    this.direction = .horizontal,
    this.transparent = false,
    this.enabled = true,
    this.isLoading = false,
    this.icon,
    this.legacyIcon,
    this.spacing = 4,
    this.textWeight = .w600,
    this.color,
    this.textColor,
    this.iconColor,
    this.onTap,
    this.padding,
  });

  factory Button.icon(
    BuildContext context, {
    List<List>? icon,
    IconData? legacyIcon,
    Function()? onTap,
    Color? color,
    Color? iconColor,
    bool transparent = true,
    bool enabled = true,
  }) {
    return Button(
      icon: icon,
      legacyIcon: legacyIcon,
      onTap: onTap,
      transparent: transparent,
      enabled: enabled,
      color: color ?? AppColors.secondaryBackground.adaptTo(context),
      iconColor: iconColor ?? AppColors.text.adaptTo(context),
      padding: .all(8),
    );
  }

  factory Button.destructive(BuildContext context, {required String text, Function()? onTap}) {
    return Button(
      text: text,
      textColor: AppColors.red,
      color: AppColors.secondaryBackground.adaptTo(context),
      transparent: true,
      icon: HugeIcons.strokeRoundedDelete01,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final finalIcon = icon ?? legacyIcon;
    final finalIconColor = iconColor ?? (transparent ? (textColor ?? color ?? AppColors.accent) : AppColors.white);
    final usingLegacyIcon = icon == null && legacyIcon != null;
    final isIconOnly = text == null && finalIcon != null;
    final finalButtonColor = enabled ? (color ?? AppColors.accent) : AppColors.inactive.adaptTo(context);
    final finalTextColor = textColor ?? (transparent ? AppColors.text.adaptTo(context) : AppColors.white);

    return CupertinoButton(
      padding: .zero,
      minimumSize: .zero,
      onPressed: enabled ? onTap : null,
      child: BlurredContainer(
        borderRadius: borderRadius,
        enabled: transparent,
        child: Opacity(
          opacity: enabled ? 1 : .5,
          child: Container(
            padding: padding ?? .all(16),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: transparent && finalButtonColor.a > 0 ? finalButtonColor.withTransparency(.5) : finalButtonColor,
              border: .all(width: 2, color: finalButtonColor),
            ),
            child: Flex(
              direction: direction,
              crossAxisAlignment: .center,
              mainAxisAlignment: .center,
              spacing: spacing,
              children: [
                if (finalIcon != null)
                  AspectRatio(
                    aspectRatio: 1,
                    child: usingLegacyIcon ? Icon(legacyIcon, color: finalIconColor) : HugeIcon(icon: icon!, color: finalIconColor),
                  ),

                if (!isIconOnly)
                  isLoading
                      ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)
                      : Expanded(
                          child: Text(
                            text ?? "Tap",
                            textAlign: .center,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: textWeight,
                              color: enabled ? finalTextColor : AppColors.inactive.adaptTo(context).withBrightness(.2),
                            ),
                          ),
                        ),

                if (finalIcon != null && text != null) const AspectRatio(aspectRatio: 1),
              ],
            ),
          ).withAspectRatio(1, enabled: isIconOnly),
        ),
      ),
    );
  }
}
