import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';

/// "#8B3FD9" (without alpha)
String colorToHex(Color color) => "#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, "0").toUpperCase()}";

/// "#8B3FD9" or "8b3fd9" → the colour, null when it isn't one
Color? colorFromHex(String? hex) {
  final digits = hex?.trim().replaceFirst("#", "");
  if (digits == null || !RegExp(r"^[0-9a-fA-F]{6}$").hasMatch(digits)) return null;
  return Color(0xFF000000 | int.parse(digits, radix: 16));
}

/// Any colour: a square for the saturation and the brightness, a strip for the hue, and its code (#RRGGBB)
class ColorPicker extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onChanged;

  const ColorPicker({super.key, required this.color, required this.onChanged});

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSVColor hsv = HSVColor.fromColor(widget.color);
  late final hexController = TextEditingController(text: colorToHex(widget.color));
  final hexFocus = FocusNode();

  @override
  void didUpdateWidget(covariant ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chosen elsewhere (a preset): follow it, keeping the hue of a grey
    if (widget.color.toARGB32() != hsv.toColor().toARGB32()) {
      final next = HSVColor.fromColor(widget.color);
      hsv = next.saturation == 0 ? next.withHue(hsv.hue) : next;
      if (!hexFocus.hasFocus) hexController.text = colorToHex(widget.color);
    }
  }

  @override
  void dispose() {
    hexController.dispose();
    hexFocus.dispose();
    super.dispose();
  }

  void change(HSVColor next) {
    setState(() => hsv = next);
    final color = next.toColor();
    if (!hexFocus.hasFocus) hexController.text = colorToHex(color);
    widget.onChanged(color);
  }

  void onSquare(Offset position, Size size) {
    change(hsv.withSaturation((position.dx / size.width).clamp(0.0, 1.0)).withValue(1 - (position.dy / size.height).clamp(0.0, 1.0)));
  }

  void onHue(Offset position, Size size) {
    change(hsv.withHue((position.dx / size.width).clamp(0.0, 1.0) * 360));
  }

  @override
  Widget build(BuildContext context) {
    final outline = AppColors.outline.adaptTo(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.m,
      children: [
        // Saturation (left to right) and brightness (top to bottom) of the hue
        AspectRatio(
          aspectRatio: 1.7,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return GestureDetector(
                onPanDown: (details) => onSquare(details.localPosition, size),
                onPanUpdate: (details) => onSquare(details.localPosition, size),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.s),
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor())),
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)])),
                        ),
                      ),
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xFF000000)]),
                          ),
                        ),
                      ),
                      Positioned(
                        left: hsv.saturation * size.width - 12,
                        top: (1 - hsv.value) * size.height - 12,
                        child: _Knob(color: hsv.toColor()),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // The hue
        SizedBox(
          height: 28,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return GestureDetector(
                onPanDown: (details) => onHue(details.localPosition, size),
                onPanUpdate: (details) => onHue(details.localPosition, size),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: 6,
                      bottom: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: outline, width: .5),
                          gradient: LinearGradient(colors: [for (var hue = 0; hue <= 360; hue += 60) HSVColor.fromAHSV(1, hue.toDouble(), 1, 1).toColor()]),
                        ),
                      ),
                    ),
                    Positioned(
                      left: hsv.hue / 360 * size.width - 12,
                      top: 2,
                      child: _Knob(color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor()),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        Row(
          spacing: AppSpacing.m,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: hsv.toColor(), shape: BoxShape.circle, border: Border.all(color: outline)),
            ),
            Expanded(
              child: Field(
                controller: hexController,
                focusNode: hexFocus,
                placeholder: "#RRGGBB",
                maxLines: 1,
                textCapitalization: TextCapitalization.characters,
                onChanged: (text) {
                  final color = colorFromHex(text);
                  if (color == null) return;
                  setState(() => hsv = HSVColor.fromColor(color));
                  widget.onChanged(color);
                },
              ),
            ),
          ],
        ),
        Text("Glissez dans le carré et sur l'arc-en-ciel, ou écrivez le code de la couleur.", style: AppStyles.footnote(context)),
      ],
    );
  }
}

class _Knob extends StatelessWidget {
  final Color color;
  const _Knob({required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
      ),
    );
  }
}
