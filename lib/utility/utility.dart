import 'dart:ui';

import 'package:flutter/cupertino.dart';

extension StringCasingExtension on String {
  String capitalize() {
    return split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }
}

Color adaptiveColor(BuildContext context, Color light, Color dark) {
  return CupertinoTheme.of(context).brightness == Brightness.dark ? dark : light;
}