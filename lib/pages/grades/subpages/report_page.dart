import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/report_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/composite_subject_badge.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class ReportCardPage extends StatefulWidget {
  const ReportCardPage({super.key});

  @override
  State<ReportCardPage> createState() => _ReportCardPageState();
}

class _ReportCardPageState extends State<ReportCardPage> {
  final globals = GlobalsService();
  final report = ReportService();

  Widget buildRow(String subjectName, double? average, double? rawAverage, bool isLocked, {Subject? subject, CompositeSubject? compositeSubject}) {
    return Padding(
      padding: const .symmetric(vertical: 5),
      child: Row(
        spacing: 4,
        children: [
          if (subject != null) SubjectBadge(subject: subject, size: 24),
          if (compositeSubject != null) CompositeSubjectBadge(compositeSubject: compositeSubject, size: 24),

          const SizedBox(width: 8),
          Expanded(child: Text(subjectName, style: const TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis)),

          if (isLocked) Icon(CupertinoIcons.lock_fill, size: 14, color: AppColors.text.adaptTo(context)),

          Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .end,
            children: [
              Padding(
                padding: .symmetric(vertical: rawAverage == null ? 6 : 0),
                child: Text(
                  (average?.removeTrailingZero() ?? "-").toString(),
                  style: TextStyle(fontSize: 18, color: (average ?? 4) < 4 ? AppColors.red : null, fontWeight: .w800),
                ),
              ),

              if (rawAverage != null)
                Text(
                  rawAverage.toStringAsFixed(2),
                  style: TextStyle(fontSize: 10, color: AppColors.text.adaptTo(context).withAlpha(.5.toByte()), fontWeight: .w400),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSubjectRow(Subject subject) {
    double? average = subject.lockedGrade ?? report.allAverages[subject.code];
    double? rawAverage = report.allAveragesRaw[subject.code];

    if (average != null && average < 1) average = null;

    return buildRow(subject.name, average, rawAverage, subject.isLocked, subject: subject);
  }

  Widget buildCompositeSubjectRow(CompositeSubject compositeSubject) {
    double? average = calculateCompositeSubjectAverage(compositeSubject, round: true);
    double? rawAverage = report.allAveragesRaw[compositeSubject.code];

    if (average != null && average < 1) average = null;

    return buildRow(compositeSubject.name, average, rawAverage, false, compositeSubject: compositeSubject);
  }

  void onSubjectSelected(String selectedSubjectCode) {
    final newList = report.restrictedGroupCodes.toList();
    newList.add(selectedSubjectCode);
    globals.persistent.setStringList("RestrictedGroupSubjects", newList);
    setState(() {});
  }

  void onSubjectRemoved(String subjectCode) {
    final newList = report.restrictedGroupCodes.toList();
    newList.remove(subjectCode);
    globals.persistent.setStringList("RestrictedGroupSubjects", newList);
    setState(() {});
  }

  void chooseMaxFailingSubjects() {
    int maxFailingSubjects = report.maxFailingGrades;
    final pickerController = FixedExtentScrollController(initialItem: maxFailingSubjects);

    showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder: (context, setPopupState) {
              return Container(
                height: 250,
                decoration: BoxDecoration(color: AppColors.background.adaptTo(context), borderRadius: const .vertical(top: .circular(16))),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      Container(
                        color: AppColors.background.adaptTo(context),
                        child: Row(
                          children: [
                            CupertinoButton(child: const Text("Annuler"), onPressed: () => Navigator.pop(context)),
                            const Expanded(
                              child: Text(
                                "Max. branches insuffisantes",
                                style: TextStyle(fontSize: 18, fontWeight: .w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            CupertinoButton(
                              child: const Text("Terminé"),
                              onPressed: () {
                                setState(() {
                                  globals.persistent.setInt("MaxFailingSubjects", maxFailingSubjects);
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: .symmetric(horizontal: 10, vertical: 10),
                          child: CupertinoPicker(
                            scrollController: pickerController,
                            itemExtent: 32,
                            onSelectedItemChanged: (index) {
                              setPopupState(() {
                                maxFailingSubjects = index;
                              });
                            },
                            squeeze: .9,
                            diameterRatio: 10,
                            children: [for (int index = 0; index <= 10; index++) Center(child: Text(index.toString(), style: TextStyle()))],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSubjects = report.allSubjects;
    final allCompositeSubjects = report.allCompositeSubjects;
    final usingRestrictedGroup = report.usingRestrictedGroup;
    final restrictedGroupCodes = report.restrictedGroupCodes;
    final restrictedGroupCompositeSubjects = report.restrictedGroupCompositeSubjects;
    final restrictedGroupSubjects = report.restrictedGroupSubjects;

    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [const CupertinoSliverNavigationBar(largeTitle: Text("Votre bulletin"), previousPageTitle: "Toutes les notes")];
        },
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const .symmetric(horizontal: 12, vertical: 10),
            children: [
              // All subjects list
              Container(
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: .circular(12)),
                padding: const .symmetric(horizontal: 12, vertical: 2),
                child: Column(
                  children: [
                    // All subjects
                    ...() {
                      final filteredList =
                          [...allCompositeSubjects, ...allSubjects].where((subject) {
                            final String code = (subject as dynamic).code;
                            return !(usingRestrictedGroup && restrictedGroupCodes.contains(code));
                          }).toList();

                      return filteredList.indexed.map(
                        (subject) => Column(
                          children: [
                            if (subject.$2 is CompositeSubject)
                              buildCompositeSubjectRow(subject.$2 as CompositeSubject)
                            else
                              buildSubjectRow(subject.$2 as Subject),
                            if (subject.$1 != filteredList.length - 1) Divider(color: AppColors.tertiaryBackground.adaptTo(context), height: 0),
                          ],
                        ),
                      );
                    }(),

                    // Restricted group subjects
                    if (usingRestrictedGroup && (restrictedGroupSubjects.isNotEmpty || restrictedGroupCompositeSubjects.isNotEmpty)) ...[
                      const Padding(
                        padding: .only(top: 10, bottom: 2),
                        child: Text("Groupe restreint", style: TextStyle(fontWeight: .w600)),
                      ),
                      ...() {
                        final restrictedList = [...restrictedGroupCompositeSubjects, ...restrictedGroupSubjects];

                        return restrictedList.indexed.map(
                          (subject) => Column(
                            children: [
                              if (subject.$2 is CompositeSubject)
                                buildCompositeSubjectRow(subject.$2 as CompositeSubject)
                              else
                                buildSubjectRow(subject.$2 as Subject),
                              if (subject.$1 != restrictedList.length - 1) Divider(color: AppColors.tertiaryBackground.adaptTo(context), height: 0),
                            ],
                          ),
                        );
                      }(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Points part
              Container(
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: .circular(12)),
                padding: const .symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  spacing: 6,
                  children: [
                    report.buildTotalPointsIndicator(),

                    if (report.maxFailingGrades > 0) ...[
                      Divider(color: AppColors.tertiaryBackground.adaptTo(context)),
                      report.buildMaxFailingSubjectsIndicator(),
                    ],

                    if (report.usingDoubleCompensation) ...[
                      Divider(color: AppColors.tertiaryBackground.adaptTo(context)),
                      report.buildDoubleCompensationIndicator(),
                    ],

                    if (usingRestrictedGroup && restrictedGroupCodes.isNotEmpty) ...[
                      Divider(color: AppColors.tertiaryBackground.adaptTo(context)),
                      report.buildRestrictedGroupPointsIndicator(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              CupertinoListSection.insetGrouped(
                margin: .zero,
                backgroundColor: AppColors.transparent,
                header: const Text("Options de calcul"),
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    title: const Text("Max. de notes insuffisantes"),
                    trailing: Row(
                      mainAxisSize: .min,
                      children: [
                        Text(report.maxFailingGrades.toString(), style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                        CupertinoListTileChevron(),
                      ],
                    ),
                    onTap: () => chooseMaxFailingSubjects(),
                  ),
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    title: const Text("Double compensation"),
                    trailing: CupertinoSwitch(
                      value: report.usingDoubleCompensation,
                      onChanged: (newValue) {
                        globals.persistent.setBool("UseDoubleCompensation", newValue);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),

              if (allSubjects.length > 3) ...[
                const SizedBox(height: 10),
                CupertinoListSection.insetGrouped(
                  margin: .zero,
                  backgroundColor: AppColors.transparent,
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                      title: const Text("Groupe restreint"),
                      trailing: CupertinoSwitch(
                        value: usingRestrictedGroup,
                        onChanged: (newValue) {
                          globals.persistent.setBool("UseRestrictedGroup", newValue);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),

                if (usingRestrictedGroup) ...[
                  const SizedBox(height: 10),
                  CupertinoListSection.insetGrouped(
                    margin: .zero,
                    backgroundColor: AppColors.transparent,
                    children: [
                      for (final compositeSubject in restrictedGroupCompositeSubjects)
                        CupertinoListTile(
                          backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                          leading: GestureDetector(
                            onTap: () => onSubjectRemoved(compositeSubject.code),
                            child: CustomIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.red),
                          ),
                          title: Row(spacing: 10, children: [CompositeSubjectBadge(compositeSubject: compositeSubject, size: 20), Text(compositeSubject.name)]),
                        ),

                      for (final subject in restrictedGroupSubjects)
                        CupertinoListTile(
                          backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                          leading: GestureDetector(
                            onTap: () => onSubjectRemoved(subject.code),
                            child: CustomIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.red),
                          ),
                          title: Row(spacing: 10, children: [SubjectBadge(subject: subject, size: 20), Text(subject.name)]),
                        ),

                      if (allSubjects.length - restrictedGroupSubjects.length - restrictedGroupCompositeSubjects.length > 1)
                        CupertinoListTile(
                          backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                          leading: CustomIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.placeholderText.adaptTo(context)),
                          title: SubjectAutocomplete(
                            placeholder: "Entrez une branche du groupe restreint",
                            onSubjectSelected: (subject) => onSubjectSelected(subject.code),
                            onCompositeSubjectSelected: (compositeSubject) => onSubjectSelected(compositeSubject.code),
                            useCompositeSubjects: true,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
