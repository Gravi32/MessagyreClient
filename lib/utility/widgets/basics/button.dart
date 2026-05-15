import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/extensions/widget_extensions.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';

class Button extends StatefulWidget {
  final bool transparent;
  final bool enabled;
  final bool isLoading;

  final double? height;
  final double? width;

  final List<List>? icon;
  final IconData? legacyIcon;
  final double? pressedOpacity;

  final Color? color;
  final Color? textColor;
  final Color? iconColor;

  final Function()? onTap;
  final String? text;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Widget? rawChild;

  const Button({
    super.key,
    this.text,
    this.transparent = false,
    this.enabled = true,
    this.isLoading = false,

    this.height,
    this.width,

    this.icon,
    this.legacyIcon,
    this.pressedOpacity,

    this.color,
    this.textColor,
    this.iconColor,

    this.onTap,
    this.padding,
    this.margin,
    this.rawChild,
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
    bool isLoading = false,
    bool isDestructive = false,
    double? size,
    EdgeInsets? margin,
  }) {
    return Button(
      icon: icon,
      legacyIcon: legacyIcon,
      onTap: onTap,
      transparent: transparent,
      enabled: enabled,
      isLoading: isLoading,
      margin: margin,
      color: color ?? (isDestructive ? AppColors.red : AppColors.secondaryBackground.adaptTo(context)),
      iconColor: iconColor,
      padding: .all(8),
      width: size,
      height: size,
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
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  @override
  Widget build(BuildContext context) {
    final finalIcon = widget.icon ?? widget.legacyIcon;
    final finalIconColor = widget.iconColor ?? (widget.transparent ? (widget.textColor ?? AppColors.text.adaptTo(context)) : AppColors.white);

    final usingLegacyIcon = widget.icon == null && widget.legacyIcon != null;
    final isIconOnly = widget.text == null && finalIcon != null;
    final finalTextColor = widget.textColor ?? (widget.transparent ? AppColors.text.adaptTo(context) : AppColors.white);

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: CupertinoButton(
        padding: .zero,
        minimumSize: .zero,
        onPressed: widget.enabled ? widget.onTap : null,
        pressedOpacity: widget.pressedOpacity ?? .4,
        child: RoundContainer(
          transparent: widget.transparent,
          enabled: widget.enabled,
          padding: widget.padding ?? const .all(12),
          margin: widget.margin,
          color: widget.enabled ? (widget.color ?? AppColors.accent) : AppColors.inactive.adaptTo(context),
          child: Row(
            crossAxisAlignment: .center,
            mainAxisAlignment: .center,
            mainAxisSize: .min,
            children: [
              if (!isIconOnly && finalIcon != null) const AspectRatio(aspectRatio: 1, child: SizedBox()),

              if (!isIconOnly)
                widget.isLoading
                    ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)
                    : Expanded(
                        child: widget.rawChild != null
                            ? widget.rawChild!
                            : Text(
                                widget.text ?? "Tap",
                                textAlign: .center,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: .w600,
                                  color: widget.enabled ? finalTextColor : AppColors.inactive.adaptTo(context).withBrightness(.2),
                                ),
                              ),
                      ),

              if (finalIcon != null)
                AspectRatio(
                  aspectRatio: 1,
                  child: usingLegacyIcon ? Icon(widget.legacyIcon, color: finalIconColor) : HugeIcon(icon: widget.icon!, color: finalIconColor),
                ),
            ],
          ),
        ).withAspectRatio(1, enabled: isIconOnly),
      ),
    );
  }
}
