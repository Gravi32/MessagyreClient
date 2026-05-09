import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/numbered_progress_bar.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final database = DatabaseService();
  final globals = GlobalsService();

  List<Grade> get allGrades => database.grades.getAll();

  List<Subject> get allSubjects {
    final compositeCodes = allCompositeSubjects.expand((c) => [c.firstSubject.value?.code, c.secondSubject.value?.code]).whereType<String>().toSet();

    return database.subjects.getAll().where((s) => !compositeCodes.contains(s.code)).sorted((a, b) {
      if (a.isLocked != b.isLocked) return a.isLocked ? 1 : -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  List<CompositeSubject> get allCompositeSubjects => database.compositeSubjects.getAll().sortedBy((s) => s.name.toLowerCase());

  int get maxFailingGrades => globals.persistent.getInt("MaxFailingSubjects") ?? 4;
  bool get usingDoubleCompensation => globals.persistent.getBool("UseDoubleCompensation") ?? false;
  bool get usingRestrictedGroup => globals.persistent.getBool("UseRestrictedGroup") ?? false;

  List<String> get restrictedGroupCodes => globals.persistent.getStringList("RestrictedGroupSubjects") ?? [];
  List<Subject> get restrictedGroupSubjects => allSubjects.where((s) => restrictedGroupCodes.contains(s.code)).toList();
  List<CompositeSubject> get restrictedGroupCompositeSubjects => allCompositeSubjects.where((c) => restrictedGroupCodes.contains(c.code)).toList();

  double get totalPoints => allAverages.values.sum;

  /// A list of the average of all subjects and composite subjects.
  Map<String, double> get allAverages {
    final averages = <String, double>{};
    final grades = allGrades;

    for (final subject in allSubjects) {
      if (subject.isLocked && subject.lockedGrade != null) {
        averages[subject.code] = subject.lockedGrade!;
      } else {
        final subjectGrades = grades.where((g) => g.subject.value?.code == subject.code).toList();
        if (subjectGrades.isNotEmpty) {
          averages[subject.code] = calculateAverage(subjectGrades, round: true);
        }
      }
    }

    for (final composite in allCompositeSubjects) {
      final avg = calculateCompositeSubjectAverage(composite, round: true);
      if (avg != null) averages[composite.code] = avg;
    }
    return averages;
  }

  /// A list of the unrounded average of all subjects and composite subjects.
  Map<String, double> get allAveragesRaw {
    final averages = <String, double>{};
    final grades = allGrades;

    for (final subject in allSubjects) {
      final subjectGrades = grades.where((g) => g.subject.value?.code == subject.code).toList();
      if (subjectGrades.isNotEmpty) {
        averages[subject.code] = calculateAverage(subjectGrades, round: false);
      }
    }

    for (final composite in allCompositeSubjects) {
      final avg = calculateCompositeSubjectAverage(composite, round: false);
      if (avg != null) averages[composite.code] = avg;
    }
    return averages;
  }

  // #region -> UI
  TextStyle getIndicatorTitleStyle(bool minimized) =>
      minimized ? const TextStyle(fontSize: 14, fontWeight: .w600) : const TextStyle(fontSize: 19, fontWeight: .w600);

  Widget maybeExpanded({required bool condition, required Widget child, int flex = 1}) => condition ? Expanded(flex: flex, child: child) : child;

  Widget buildTotalPointsIndicator({bool minimized = false}) {
    final minPoints = allAverages.length * 4;
    final maxPoints = allAverages.length * 6;

    final isLowerThanMinimum = totalPoints < minPoints;

    final progress = max(0, isLowerThanMinimum ? totalPoints / minPoints : (totalPoints - minPoints) / (maxPoints - minPoints)).toDouble();
    final difference = (minPoints - totalPoints).abs().removeTrailingZero();

    return Flex(
      direction: minimized ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: minimized ? .start : .stretch,
      children: [
        maybeExpanded(
          condition: minimized,
          child: Text("Total des points", style: getIndicatorTitleStyle(minimized), maxLines: 2, overflow: TextOverflow.ellipsis), flex: 2,
        ),
        if (!minimized)
          Text(
            isLowerThanMinimum
                ? "Encore $difference point${difference == "1" ? "" : "s"}, courage !"
                : "$difference point${difference == "1" ? "" : "s"} au-dessus du minimum !",
            style: TextStyle(fontSize: 14, color: isLowerThanMinimum ? AppColors.red : AppColors.green),
          ),

        const SizedBox.square(dimension: 6),
        maybeExpanded(
          condition: minimized,
          child: NumberedProgressBar(
            lowerBound: isLowerThanMinimum ? "0" : minPoints.toString(),
            upperBound: (isLowerThanMinimum ? minPoints : maxPoints).toString(),
            progress: progress,
            value: totalPoints.removeTrailingZero(),
            color: isLowerThanMinimum ? AppColors.red : AppColors.green,
            fontSize: minimized ? 23 : 32,
            barHeight: minimized ? 6 : null,
          ),
          flex: 3,
        ),
      ],
    );
  }

  Widget buildMaxFailingSubjectsIndicator({bool minimized = false}) {
    final numberOfFailingGrades = allAverages.values.where((grade) => grade < 3.75).length;

    final progress = (numberOfFailingGrades / maxFailingGrades).clamp(0, 1).toDouble();

    return Flex(
      direction: minimized ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: minimized ? .center : .stretch,
      children: [
        maybeExpanded(
          condition: minimized,
          child: Text("Moyennes insuffisantes", style: getIndicatorTitleStyle(minimized), maxLines: 2, overflow: TextOverflow.ellipsis), flex: 2,
        ),

        const SizedBox.square(dimension: 6),
        maybeExpanded(
          condition: minimized,
          child: NumberedProgressBar(
            lowerBound: "0",
            upperBound: maxFailingGrades.toString(),
            progress: progress,
            value: numberOfFailingGrades.toString(),
            color: getProgressColor(numberOfFailingGrades / maxFailingGrades),
            fontSize: minimized ? 23 : 32,
            barHeight: minimized ? 6 : null,
          ),
          flex: 3,
        ),
      ],
    );
  }

  Widget buildRestrictedGroupPointsIndicator({bool minimized = false}) {
    final restrictedGroupAverages = <double>[];
    for (final subjectCode in restrictedGroupCodes) {
      if (allAverages.containsKey(subjectCode) && allAverages[subjectCode] != null) restrictedGroupAverages.add(allAverages[subjectCode]!);
    }

    final totalPoints = restrictedGroupAverages.sum;
    final minPoints = restrictedGroupAverages.length * 4;
    final maxPoints = restrictedGroupAverages.length * 6;

    final isLowerThanMinimum = totalPoints < minPoints;

    final progress = max(0, isLowerThanMinimum ? totalPoints / minPoints : (totalPoints - minPoints) / (maxPoints - minPoints)).toDouble();
    final difference = (minPoints - totalPoints).abs().removeTrailingZero();

    return Flex(
      direction: minimized ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: minimized ? .center : .stretch,
      children: [
        maybeExpanded(
          condition: minimized,
          child: Text("Points du groupe restreint", style: getIndicatorTitleStyle(minimized), maxLines: 2, overflow: TextOverflow.ellipsis), flex: 2,
        ),
        if (!minimized)
          Text(
            isLowerThanMinimum
                ? "Encore $difference point${difference == "1" ? "" : "s"}, courage !"
                : "$difference point${difference == "1" ? "" : "s"} au-dessus du minimum !",
            style: TextStyle(fontSize: 14, color: isLowerThanMinimum ? AppColors.red : AppColors.green),
          ),

        const SizedBox.square(dimension: 6),
        maybeExpanded(
          condition: minimized,
          child: NumberedProgressBar(
            lowerBound: isLowerThanMinimum ? "0" : minPoints.toString(),
            upperBound: (isLowerThanMinimum ? minPoints : maxPoints).toString(),
            progress: progress,
            value: totalPoints.removeTrailingZero(),
            color: isLowerThanMinimum ? AppColors.red : AppColors.green,
            fontSize: minimized ? 23 : 32,
            barHeight: minimized ? 6 : null,
          ),
          flex: 3,
        ),
      ],
    );
  }

  Widget buildDoubleCompensationIndicator({bool minimized = false}) {
    var deficit = .0;
    for (final average in allAverages.values) {
      if (average < 4) deficit += average - 4;
    }
    var surplus = .0;
    for (final average in allAverages.values) {
      if (average > 4) surplus += average - 4;
    }
    final result = surplus + deficit * 2;

    final isFailing = result < 0;

    final progress = result / (deficit.abs() + surplus);
    final difference = result.abs() * 2.0;

    return Flex(
      direction: minimized ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: minimized ? .center : .stretch,
      children: [
        maybeExpanded(
          condition: minimized,
          child: Text("Double compensation", style: getIndicatorTitleStyle(minimized), maxLines: 2, overflow: TextOverflow.ellipsis), flex: 2,
        ),
        if (!minimized && isFailing)
          Text(
            "+${difference.removeTrailingZero()} point${difference == 1.0 ? "" : "s"} pour compenser, courage !",
            style: TextStyle(fontSize: 14, color: AppColors.red),
          ),

        const SizedBox.square(dimension: 6),
        maybeExpanded(
          condition: minimized,
          child: NumberedProgressBar(
            lowerBound: deficit.toDouble().removeTrailingZero(),
            upperBound: "+${surplus.toDouble().removeTrailingZero()}",
            progress: progress,
            value: result.toDouble().removeTrailingZero(),
            color: isFailing ? AppColors.red : AppColors.green,
            centered: true,
            fontSize: minimized ? 23 : 32,
            barHeight: minimized ? 6 : null,
          ),
          flex: 3,
        ),
      ],
    );
  }

  // #endregion
}
