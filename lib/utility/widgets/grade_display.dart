import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/utility/utility.dart';

class GradeDisplay extends StatefulWidget {
  final double grade;
  final double size;
  final double weight;

  const GradeDisplay({super.key, required this.grade, this.size = 48, this.weight = 1.0});

  @override
  State<GradeDisplay> createState() => _GradeDisplayState();
}

class _GradeDisplayState extends State<GradeDisplay> {
  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final CupertinoDynamicColor color;
    final int alpha = ((.25 + widget.weight * .75) * 255).toInt();

    if (widget.grade >= 4) {
      color = CupertinoColors.activeGreen;
    } else if (widget.grade > 3.75) {
      color = CupertinoColors.activeOrange;
    } else {
      color = CupertinoColors.systemRed;
    }

    return SizedBox(
      width: size,
      height: size + 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(value: widget.grade / 6, strokeWidth: 4, strokeCap: StrokeCap.round, color: color.withAlpha(alpha)),
                Transform.flip(
                  flipX: true,
                  child: Transform.rotate(
                    angle: 3.14 * .1,
                    child: CircularProgressIndicator(
                      value: 1 - widget.grade / 6 - 0.1,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      color: adaptiveColor(CupertinoColors.black, CupertinoColors.white).withAlpha(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            widget.grade % 1 == 0 ? widget.grade.toInt().toString() : widget.grade.toStringAsFixed(1),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CupertinoColors.label.resolveFrom(context)),
          ),
          if (widget.weight != 1)
            Positioned(
              bottom: 0,
              child: Transform.translate(
                offset: const Offset(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(color: CupertinoColors.systemBackground.resolveFrom(context).withAlpha(200), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    getFractionString(widget.weight),

                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: CupertinoColors.label.resolveFrom(context)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
