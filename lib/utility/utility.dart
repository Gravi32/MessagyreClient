import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:url_launcher/url_launcher.dart';

// #region -> Strings
extension StringExtension on String {
  String capitalize({bool everyWord = false}) {
    if (everyWord) {
      return split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '').join(' ');
    } else {
      return isEmpty ? "" : (this[0].toUpperCase() + substring(1));
    }
  }

  String normalize() {
    return toLowerCase()
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[ïî]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  String withPreposition({bool lowercase = false}) {
    var word = this;
    if (lowercase) word = word.toLowerCase();

    final firstChar = word[0].toLowerCase();
    if ('aeiouàâäéèêëïîôöùûü'.contains(firstChar)) {
      return "d'$word";
    } else {
      return "de $word";
    }
  }
}

void copy(BuildContext context, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  if (!context.mounted) return;
  showCupertinoDialog(
    context: context,
    builder: (_) => Dialog(title: "Copié", content: "Copié dans le presse-papiers."),
  );
}

String formatSwissPhoneNumber(String input) {
  String digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = '41${digits.substring(1)}';
  if (!digits.startsWith('41')) digits = '41$digits';
  if (digits.length > 11) digits = digits.substring(0, 11);

  final buffer = StringBuffer('+${digits.substring(0, 2)}');
  if (digits.length > 2) buffer.write(' ${digits.substring(2, 4)}');
  if (digits.length > 4) buffer.write(' ${digits.substring(4, 7)}');
  if (digits.length > 7) buffer.write(' ${digits.substring(7, 9)}');
  if (digits.length > 9) buffer.write(' ${digits.substring(9)}');

  return buffer.toString();
}

final Map<String, List<TextSpan>> _highlightSearchCache = {};

List<TextSpan> highlightSearchMatch(String fullText, String query, {bool useCache = false}) {
  final key = '$fullText::$query';
  if (useCache && _highlightSearchCache.containsKey(key)) return _highlightSearchCache[key]!;

  if (query.isEmpty) {
    final span = [TextSpan(text: fullText)];
    if (useCache) _highlightSearchCache[key] = span;
    return span;
  }

  final normalizedText = fullText.toLowerCase();
  final normalizedQuery = query.toLowerCase();

  if (!normalizedText.contains(normalizedQuery)) {
    final span = [TextSpan(text: fullText)];
    if (useCache) _highlightSearchCache[key] = span;
    return span;
  }

  final spans = <TextSpan>[];
  int lastIndex = 0;
  final matches = RegExp(RegExp.escape(normalizedQuery)).allMatches(normalizedText);

  for (final m in matches) {
    if (m.start > lastIndex) {
      spans.add(TextSpan(text: fullText.substring(lastIndex, m.start)));
    }
    spans.add(
      TextSpan(
        text: fullText.substring(m.start, m.end),
        style: const TextStyle(fontWeight: .w900),
      ),
    );
    lastIndex = m.end;
  }

  if (lastIndex < fullText.length) {
    spans.add(TextSpan(text: fullText.substring(lastIndex)));
  }

  if (useCache) _highlightSearchCache[key] = spans;
  return spans;
}

// #endregion

// #region -> Numbers

extension DoubleExtension on double {
  int toByte() => (this * 255).round().clamp(0, 255);

  String removeTrailingZero() {
    if (this == truncateToDouble()) {
      return toInt().toString();
    }
    return toString();
  }

  double roundToHalves() => (this * 2).roundToDouble() / 2;
}

// #endregion

// #region -> Colors
extension ColorExtension on Color {
  Color withBrightness(double brightness) {
    final hsl = HSLColor.fromColor(this);
    final adjustedHsl = hsl.withLightness((hsl.lightness + brightness).clamp(0.0, 1.0));
    return adjustedHsl.toColor();
  }

  /// Returns the given color with the alpha channel set as [transparency]. (double)
  Color withTransparency(double transparency) {
    return withValues(alpha: transparency);
  }

  int toInt() {
    final alpha = (a * 255).toInt();
    final red = (r * 255).toInt();
    final green = (g * 255).toInt();
    final blue = (b * 255).toInt();

    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }
}

Color getGradeColor(double grade, {Color? defaultColor, BuildContext? context}) {
  Color result = AppColors.red;

  if (grade >= 4) {
    result = defaultColor ?? (context != null ? AppColors.text.adaptTo(context) : AppColors.accent);
  } else if (grade > 3.75) {
    result = AppColors.orange;
  }

  return result;
}

Color getProgressColor(double ratio) {
  final double t = ratio.clamp(0.0, 1.0);

  const colors = [AppColors.green, AppColors.yellow, AppColors.orange, AppColors.red];

  if (t <= 0) return colors.first;
  if (t >= 1) return colors.last;

  final double segment = t * (colors.length - 1);
  final int index = segment.floor();
  final double delta = segment - index;

  return Color.lerp(colors[index], colors[index + 1], delta)!;
}

// #endregion

// #region -> Dates

extension DateTimeExtension on DateTime {
  bool isSameDayAs(DateTime other) => year == other.year && month == other.month && day == other.day;

  /// Returns the DateTime with just the day, month and year values.
  DateTime dateOnly() => DateTime(year, month, day);

  /// Returns a new DateTime with [amount] more days
  DateTime addDays(int amount) => copyWith().dateOnly().add(Duration(days: amount)).copyWith(hour: hour, minute: minute, second: second);

  DateTime withTheTimeOf(DateTime source) => copyWith(hour: source.hour, minute: source.minute, second: source.second);
}

String formatDate(DateTime targetDate, {bool includeTime = false, bool includeArticle = false}) {
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
    result = (includeArticle ? "le " : "") + DateFormat("d MMMM", 'fr_CH').format(targetDate);
  }

  if (date.year != today.year) result += " ${date.year}";

  if (includeTime) {
    final time = DateFormat.Hm('fr_CH').format(targetDate);
    result += " à $time";
  }

  return result;
}

// #endregion

// #region -> Grades
double calculateAverage(List<Grade> grades, {bool round = false}) {
  if (grades.isEmpty) return 0.0;

  double total = 0.0;
  double totalWeight = 0.0;

  for (var gradeData in grades) {
    total += gradeData.grade * gradeData.weight;
    totalWeight += gradeData.weight;
  }

  final double result = totalWeight > 0 ? (total / totalWeight).toDouble() : 0;

  return round ? result.roundToHalves() : result;
}

(double toPass, double toMaintain, double toBoost) calculateGoalGrades(List<Grade> grades, double nextExamWeight) {
  if (grades.isEmpty) return (3.75, 4.0, 4.5);

  double currentTotalWeight = 0.0;
  double currentWeightedSum = 0.0;

  for (var g in grades) {
    currentWeightedSum += g.grade * g.weight;
    currentTotalWeight += g.weight;
  }

  double currentAverage = currentWeightedSum / currentTotalWeight;
  double newTotalWeight = currentTotalWeight + nextExamWeight;

  double solve(double target) {
    double needed = (target * newTotalWeight - currentWeightedSum) / nextExamWeight;
    return needed.roundToHalves();
  }

  return (
    solve(3.75), // toPass
    solve(currentAverage.roundToHalves() - .25), // toMaintain
    solve(currentAverage.roundToHalves() + .25), // toBoost
  );
}

double? calculateCompositeSubjectAverage(CompositeSubject compositeSubject, {bool round = false}) {
  final database = DatabaseService();
  final allGrades = database.grades.getAll();

  final firstSubjectGrades = allGrades.where((g) => g.subject.value?.code == compositeSubject.firstSubject.value?.code).toList();
  final secondSubjectGrades = allGrades.where((g) => g.subject.value?.code == compositeSubject.secondSubject.value?.code).toList();

  if (firstSubjectGrades.isEmpty || secondSubjectGrades.isEmpty) return null;

  final firstAverage = calculateAverage(firstSubjectGrades);
  final secondAverage = calculateAverage(secondSubjectGrades);

  final result =
      (firstAverage * compositeSubject.firstSubjectPeriodsPerWeek + secondAverage * compositeSubject.secondSubjectPeriodsPerWeek) /
      compositeSubject.totalPeriodsPerWeek;

  return round ? result.roundToHalves() : result;
}

Map<double, String> fractions = {
  0.0: "0",
  0.125: "⅛",
  0.166: "⅙",
  0.2: "⅕",
  0.25: "¼",
  0.33: "⅓",
  0.375: "⅜",
  0.4: "⅖",
  0.5: "½",
  0.6: "⅗",
  0.625: "⅝",
  0.66: "⅔",
  0.75: "¾",
  0.8: "⅘",
  0.875: "⅞",
  1.0: "1",
};

String? getFractionString(double value) {
  for (var fraction in fractions.keys) {
    if ((value - fraction).abs() < 0.01) {
      return fractions[fraction]!;
    }
  }
  return null;
}
// #endregion

// #region -> Messages

({List<List<dynamic>> icon, Color color}) getStatusIcon(MessageStatus status) {
  switch (status) {
    case MessageStatus.Failed:
      return (icon: HugeIcons.strokeRoundedCancel01, color: AppColors.red);
    case MessageStatus.Sending:
      return (icon: HugeIcons.strokeRoundedMoreHorizontal, color: AppColors.white);
    case MessageStatus.Sent:
      return (icon: HugeIcons.strokeRoundedTick02, color: AppColors.white);
    case MessageStatus.Delivered:
      return (icon: HugeIcons.strokeRoundedTickDouble02, color: AppColors.white);
    case MessageStatus.Read:
      return (icon: HugeIcons.strokeRoundedTickDouble02, color: AppColors.accent);
  }
}
// #endregion

// #region -> Text

Size measureTextSize(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: ui.TextDirection.ltr,
    maxLines: 1,
  )..layout();

  return painter.size;
}

// #endregion

// #region -> Json

dynamic tryJsonDecode(String source) {
  try {
    return jsonDecode(source);
  } catch (_) {
    return null;
  }
}

// #endregion

// #region -> Map

extension MapExtension on Map<String, dynamic> {
  dynamic tryGetValue(String key) {
    try {
      return this[key];
    } catch (_) {
      return null;
    }
  }
}

// #endregion

// #region -> Miscellaneous

void restartApp(BuildContext context) {
  if (!context.mounted) return;
  final mountedContext = context;
  Phoenix.rebirth(mountedContext);
}

Future<void> openUrl(String url, {bool tryApp = false}) async {
  Uri uri = Uri.parse(url);

  if (tryApp) if (await launchUrl(uri, mode: .externalNonBrowserApplication)) return;

  await launchUrl(uri, mode: .inAppBrowserView, webViewConfiguration: const WebViewConfiguration(enableJavaScript: true, enableDomStorage: true));
}

// #endregion
