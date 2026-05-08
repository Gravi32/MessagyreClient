import 'package:flutter/cupertino.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/graphics/blurred_container.dart';
import 'package:messagyre_client/utility/utility.dart';

class Button extends StatelessWidget {
  final Axis direction;
  final Color? color;
  final bool transparent;
  final bool enabled;
  final bool isLoading;
  final IconData? icon;
  final String? emojiIcon;
  final double spacing;
  final FontWeight textWeight;
  final Color? textColor;
  final Function()? onTap;
  final String text;
  final EdgeInsets? padding;

  static final borderRadius = BorderRadius.circular(34);

  const Button({
    super.key,
    this.direction = .horizontal,
    this.color,
    this.transparent = false,
    this.enabled = true,
    this.isLoading = false,
    this.icon,
    this.emojiIcon,
    this.spacing = 4,
    this.textWeight = .w600,
    this.textColor,
    this.onTap,
    this.padding,
    required this.text,
  });

  factory Button.destructive(BuildContext context, {required String text, Function()? onTap}) {
    return Button(
      text: text,
      textColor: AppColors.red,
      color: AppColors.secondaryBackground.adaptTo(context),
      transparent: true,
      icon: CupertinoIcons.delete,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasIcons = (icon ?? emojiIcon) != null;
    final finalButtonColor = enabled ? (color ?? AppColors.accent) : AppColors.inactive.adaptTo(context);
    final finalTextColor = textColor ?? (transparent ? AppColors.text.adaptTo(context) : AppColors.white);

    return CupertinoButton(
      padding: .zero,
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
              color: transparent ? finalButtonColor.withTransparency(.5) : finalButtonColor,
              border: transparent ? .all(width: 2, color: finalButtonColor) : null,
            ),
            child: Flex(
              direction: direction,
              crossAxisAlignment: .center,
              mainAxisAlignment: .center,
              spacing: spacing,
              children: [
                if (hasIcons)
                  SizedBox(
                    width: 30,
                    child: Center(
                      child: Stack(
                        children: [
                          if (icon != null) Icon(icon, color: transparent ? (textColor ?? color ?? AppColors.accent) : AppColors.white),
                          if (emojiIcon != null)
                            Text(
                              "$emojiIcon ",
                              style: TextStyle(fontSize: 28, color: AppColors.black, height: 0.01, leadingDistribution: TextLeadingDistribution.even),
                            ),
                        ],
                      ),
                    ),
                  ),

                isLoading
                    ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)
                    : Expanded(
                        child: Text(
                          text,
                          textAlign: .center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: textWeight,
                            color: enabled ? finalTextColor : AppColors.inactive.adaptTo(context).withBrightness(.2),
                          ),
                        ),
                      ),

                if (hasIcons) const SizedBox(width: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
