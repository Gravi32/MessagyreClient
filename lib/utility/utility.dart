import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

extension StringCasingExtension on String {
  String capitalize() {
    return split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : '',
        )
        .join(' ');
  }
}

Color adaptiveColor(BuildContext context, Color light, Color dark) {
  return CupertinoTheme.of(context).brightness == Brightness.dark
      ? dark
      : light;
}

String formatSwissPhoneNumber(String input) {
  // Removing everything but digits
  String digits = input.replaceAll(RegExp(r'\D'), '');

  // Replacing initial "0" with prefix
  if (digits.startsWith('0')) {
    digits = '41${digits.substring(1)}';
  }

  // Adding prefix if missing
  if (!digits.startsWith('41')) {
    digits = '41$digits';
  }

  // Limiting to 11 digits
  if (digits.length > 11) {
    digits = digits.substring(0, 11);
  }

  // Adding whitespaces
  final buffer = StringBuffer('+${digits.substring(0, 2)}');
  if (digits.length > 2) buffer.write(' ${digits.substring(2, 4)}');
  if (digits.length > 4) buffer.write(' ${digits.substring(4, 7)}');
  if (digits.length > 7) buffer.write(' ${digits.substring(7, 9)}');
  if (digits.length > 9) buffer.write(' ${digits.substring(9)}');

  return buffer.toString();
}