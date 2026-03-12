import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class ReportCardPage extends StatefulWidget {
  const ReportCardPage({super.key});

  @override
  State<ReportCardPage> createState() => _ReportCardPageState();
}

class _ReportCardPageState extends State<ReportCardPage> {
  final database = DatabaseService();

  late final grades = database.grades.getAll();
  late final subjects = database.subjects.getAll();

  final Map<String, List<Grade>> gradesPerSubject = {};
  final Map<String, double> averagePerSubject = {};

  Widget buildSubjectRow(Subject subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        spacing: 10,
        children: [
          SubjectBadge(subject: subject, size: 24),
          Expanded(child: Text(subject.name, style: TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis)),
          Text((averagePerSubject[subject.code] ?? "-").toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    for (final grade in grades) {
      final subject = grade.subject.value;
      if (subject == null) continue;
      gradesPerSubject.putIfAbsent(subject.code, () => []).add(grade);
    }

    for (final subject in gradesPerSubject.keys) {
      averagePerSubject[subject] = gradesPerSubject[subject] != null ? calculateAverage(gradesPerSubject[subject]!, round: true) : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [CupertinoSliverNavigationBar(largeTitle: Text("Votre bulletin"), previousPageTitle: "Toutes les notes")];
        },
        body: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              spacing: 10,
              children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Column(
                    children: [
                      for (int i = 0; i < subjects.length; i++) ...[
                        buildSubjectRow(subjects[i]),
                        if (i != subjects.length - 1) Divider(color: AppColors.tertiaryBackground.adaptTo(context), height: 0),
                      ],
                    ],
                  ),
                ),
                CupertinoListSection.insetGrouped(
                  margin: EdgeInsets.zero,
                  backgroundColor: AppColors.transparent,
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                      title: Text("Double compensation"),
                      trailing: CupertinoSwitch(value: false, onChanged: (_) {}),
                    ),
                    CupertinoListTile(
                      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                      title: Text("Groupe restreint"),
                      trailing: CupertinoSwitch(value: false, onChanged: (_) {}),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
