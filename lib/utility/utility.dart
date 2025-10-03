import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/utility/classes.dart';

extension StringCasingExtension on String {
  String capitalize({bool everyWord = false}) {
    return everyWord ? split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '').join(' ') : this[0].toUpperCase() + substring(1);
  }
}

extension ColorExtension on Color {
  Color withBrightness(double brightness) {
    final hsl = HSLColor.fromColor(this);
    final adjustedHsl = hsl.withLightness((hsl.lightness + brightness).clamp(0.0, 1.0));
    return adjustedHsl.toColor();
  }
}

Color adaptiveColor(BuildContext context, Color light, Color dark) {
  return CupertinoTheme.of(context).brightness == Brightness.dark ? dark : light;
}

String formatDate(DateTime targetDate, {bool includeTime = false}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(targetDate.year, targetDate.month, targetDate.day);

  final difference = date.difference(today).inDays;
  final dayName = DateFormat.EEEE('fr_CH').format(targetDate);

  String result;

  if (difference == 0) {
    result = "aujourd'hui";
  } else if (difference == 1) {
    result = "demain";
  } else if (difference == -1) {
    result = "hier";
  } else if (difference > 1 && difference <= 6) {
    result = dayName;
  } else if (difference >= 7 && difference <= 13) {
    result = "$dayName prochain";
  } else if (difference < -1 && difference >= -13) {
    result = "$dayName passé";
  } else {
    result = DateFormat("d MMMM", 'fr_CH').format(targetDate);
  }

  if (includeTime) {
    final time = DateFormat.Hm('fr_CH').format(targetDate);
    result += " à $time";
  }

  return result;
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

double calculateAverage(List<Grade> grades) {
  if (grades.isEmpty) return 0.0;

  double total = 0.0;
  double totalWeight = 0.0;

  for (var gradeData in grades) {
    total += gradeData.grade * gradeData.weight;
    totalWeight += gradeData.weight;
  }

  return totalWeight > 0 ? (total / totalWeight).toDouble() : 0;
}

void initMessageNotifiers() {
  for (var chat in Hive.box<Chat>("Chats").values) {
    for (var message in chat.content) {
      message.initNotifier();
    }
  }
}

Map<double, String> fractions = {0.0: "0", 0.25: "¼", 0.33: "⅓", 0.5: "½", 0.66: "⅔", 0.75: "¾", 1.0: "1"};

String getFractionString(double value) {
  for (var fraction in fractions.keys) {
    if ((value - fraction).abs() < 0.01) {
      return fractions[fraction]!;
    }
  }
  return value.toStringAsFixed(2);
}

IconData getStatusIcon(int status) {
  if (status == 0) return Icons.close_rounded;
  if (status == 1) return Icons.done_rounded;
  return Icons.done_all_rounded;
}
