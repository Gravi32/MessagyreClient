import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/graphics/blurred_container.dart';

/// A rounded surface, the base of the cards, buttons and fields.
///
/// - a neutral [color] (the default: the cards' color) gives a solid card with a hairline outline;
/// - a vivid [color] with [transparent] gives a soft wash of that color (the "tonal" buttons: red to delete, accent);
/// - [transparent] false fills it with the color itself, [gradient] with a gradient (the main buttons);
/// - [blur] also blurs what is behind it, which is expensive (a BackdropFilter): only for surfaces that float over
///   scrolling content (popups, the + button).
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
    this.borderRadius = AppRadius.card,
  });

  /// Greys and the app's surfaces (barely tinted) are neutral; red, the accent, a subject's color are vivid
  /// (by chroma, not saturation: a very dark grey with a hint of purple has a high saturation but no visible color)
  static bool isNeutral(Color color) {
    final channels = [color.r, color.g, color.b];
    return channels.reduce((a, b) => a > b ? a : b) - channels.reduce((a, b) => a < b ? a : b) < .15;
  }

  /// What [RoundContainer] paints for [color]: also used by the widgets that draw the same surfaces themselves
  static Color fillFor(BuildContext context, Color color, {bool transparent = true, bool blur = false}) {
    if (!transparent || color.a < 1) return color;
    if (blur) return color.withValues(alpha: isNeutral(color) ? .78 : .3);
    if (isNeutral(color)) return color;
    return color.withValues(alpha: AppColors.isDark(context) ? .22 : .13);
  }

  @override
  Widget build(BuildContext context) {
    final base = enabled ? (color ?? AppColors.secondaryBackground.adaptTo(context)) : AppColors.tertiaryBackground.adaptTo(context);
    final hasGradient = gradient != null && enabled;
    final neutral = isNeutral(base);

    final Color fill;
    if (hasGradient || borderOnly) {
      fill = AppColors.transparent;
    } else if (blurOnly) {
      fill = AppColors.tertiaryBackground.adaptTo(context).withValues(alpha: .6);
    } else {
      fill = fillFor(context, base, transparent: transparent, blur: blur);
    }

    // Only the cards get the hairline: a filled or tonal surface stands out by itself
    final outlined = !hasGradient && !blurOnly && transparent && neutral && (base.a == 1 || borderOnly);

    final Widget surface = Container(
      height: height,
      width: width,
      constraints: constraints,
      padding: padding ?? const .all(16),
      // What is inside follows the rounded corners (the rows of a list, a picture, a decoration)
      clipBehavior: child != null ? .antiAlias : .none,
      decoration: BoxDecoration(borderRadius: .circular(borderRadius), color: fill, gradient: hasGradient ? gradient : null),
      // The hairline is painted over the content, with the same corners: the rows of a list fill the card up to its
      // edge and would otherwise cover it in the corners
      foregroundDecoration: outlined
          ? BoxDecoration(
              borderRadius: .circular(borderRadius),
              border: .all(width: 1, color: AppColors.outline.adaptTo(context)),
            )
          : null,
      child: child,
    );

    final content = opacity < 1 ? Opacity(opacity: opacity, child: surface) : surface;

    if (!(transparent && blur)) {
      return Padding(padding: margin ?? .zero, child: content);
    }

    return BlurredContainer(
      margin: margin,
      height: height,
      width: width,
      borderRadius: .circular(borderRadius),
      blur: blurAmount,
      constraints: constraints,
      child: content,
    );
  }
}
