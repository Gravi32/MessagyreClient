import 'package:flutter/cupertino.dart';

extension AspectRatioExtension on Widget {
  Widget withAspectRatio(double ratio, {bool enabled = true}) {
    if (!enabled) return this;
    return AspectRatio(aspectRatio: ratio, child: this);
  }
}
