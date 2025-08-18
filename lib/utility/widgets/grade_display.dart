import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/utility/utility.dart';

class GradeDisplay extends StatefulWidget {
  final double grade;
  final double size;

  const GradeDisplay({super.key, required this.grade, this.size = 48});

  @override
  State<GradeDisplay> createState() => _GradeDisplayState();
}

class _GradeDisplayState extends State<GradeDisplay> {
  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final CupertinoDynamicColor color;

    if (widget.grade >= 4) {
      color = CupertinoColors.activeGreen;
    } else if (widget.grade > 3.75) {
      color = CupertinoColors.activeOrange;
    } else {
      color = CupertinoColors.systemRed;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: widget.grade / 6,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  color: color,
                ),
                Transform.flip(
                  flipX: true,
                  child: Transform.rotate(
                    angle: 3.14 * .1,
                    child: CircularProgressIndicator(
                      value: 1 - widget.grade / 6 - 0.1,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      color: adaptiveColor(
                        context,
                        CupertinoColors.black.withAlpha(30),
                        CupertinoColors.white.withAlpha(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            widget.grade.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
