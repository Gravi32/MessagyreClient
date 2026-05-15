import 'dart:math';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:flutter/material.dart' show Divider;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/report_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/modal_popup.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/picker.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/segmented_control.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/composite_subject_badge.dart';
import 'package:messagyre_client/utility/widgets/numbered_progress_bar.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class ReportCardPage extends StatefulWidget {
  const ReportCardPage({super.key});

  @override
  State<ReportCardPage> createState() => _ReportCardPageState();
}

class _ReportCardPageState extends State<ReportCardPage> {
  final globals = GlobalsService();
  final report = ReportService();

  final pageController = PageController();

  Widget buildRow(String subjectName, double? average, double? rawAverage, bool isLocked, {Subject? subject, CompositeSubject? compositeSubject}) {
    return Padding(
      padding: const .symmetric(vertical: 5),
      child: Row(
        spacing: 4,
        children: [
          if (subject != null) SubjectBadge(subject: subject, size: 24),
          if (compositeSubject != null) CompositeSubjectBadge(compositeSubject: compositeSubject, size: 24),

          const SizedBox(width: 8),
          Expanded(
            child: Text(subjectName, style: AppStyles.primaryText(context), overflow: .ellipsis),
          ),

          if (isLocked) Icon(CupertinoIcons.lock_fill, size: 14, color: AppColors.text.adaptTo(context)),

          Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .end,
            children: [
              Padding(
                padding: .symmetric(vertical: rawAverage == null ? 6 : 0),
                child: Text(
                  (average?.removeTrailingZero() ?? "-").toString(),
                  style: AppStyles.secondaryHeader(context).copyWith(color: getGradeColor(average ?? 4, context: context)),
                ),
              ),

              if (rawAverage != null) Text(rawAverage.toStringAsFixed(2), style: AppStyles.footer(context).copyWith()),
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
      builder: (context) => ModalPopup(
        topBar: TopBar.form(
          context,
          title: "Max. branches insuffisantes",
          trailing: Button.icon(
            context,
            icon: HugeIcons.strokeRoundedTick02,
            onTap: () async {
              globals.persistent.setInt("MaxFailingSubjects", maxFailingSubjects);
              setState(() {});
              Navigator.pop(context);
            },
          ),
        ),
        height: 180,
        child: StatefulBuilder(
          builder: (context, setPopupState) {
            return Picker(
              controller: pickerController,
              onChanged: (index) {
                setPopupState(() {
                  maxFailingSubjects = index;
                });
              },
              children: [for (int index = 0; index <= 10; index++) Center(child: Text(index.toString(), style: TextStyle()))],
            );
          },
        ),
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

    return Page(
      topBar: TopBar.tab(context, title: "Votre bulletin"),
      ignorePadding: true,
      child: Column(
        spacing: 16,
        children: [
          Padding(
            padding: .symmetric(horizontal: 10),
            child: SegmentedControl(
              pageController: pageController,
              options: {"Bulletin": 0, "Critères": 1, "Options": 2},
              onTap: (index) => pageController.animateToPage(index, duration: Duration(milliseconds: 120), curve: Curves.easeInOutQuart),
            ),
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              children: [
                // All subjects list
                ListView(
                  padding: .symmetric(horizontal: 10),
                  children: [
                    RoundContainer(
                      padding: .symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        crossAxisAlignment: .stretch,
                        spacing: 6,
                        children: [
                          // All subjects
                          () {
                            final filteredList = [
                              ...allCompositeSubjects,
                              ...allSubjects,
                            ].where((subject) => !(usingRestrictedGroup && restrictedGroupCodes.contains((subject as dynamic).code))).toList();

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final subject = filteredList[index];
                                return subject is CompositeSubject ? buildCompositeSubjectRow(subject) : buildSubjectRow(subject as Subject);
                              },
                              separatorBuilder: (context, _) => Divider(color: AppColors.secondaryBackground.adaptTo(context), height: 4),
                              itemCount: filteredList.length,
                            );
                          }(),

                          // Restricted group subjects
                          if (usingRestrictedGroup && (restrictedGroupSubjects.isNotEmpty || restrictedGroupCompositeSubjects.isNotEmpty)) ...[
                            Padding(
                              padding: .only(top: 18),
                              child: Text("Groupe restreint", style: AppStyles.header(context)),
                            ),

                            () {
                              final restrictedList = [...restrictedGroupCompositeSubjects, ...restrictedGroupSubjects];

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final subject = restrictedList[index];
                                  return subject is CompositeSubject ? buildCompositeSubjectRow(subject) : buildSubjectRow(subject as Subject);
                                },
                                separatorBuilder: (context, _) => Divider(color: AppColors.secondaryBackground.adaptTo(context), height: 4),
                                itemCount: restrictedList.length,
                              );
                            }(),
                          ],
                        ],
                      ),
                    ),

                    BottomSpacing(),
                  ],
                ),

                // Criteria Stats
                ListView(
                  padding: .symmetric(horizontal: 10),
                  children: [
                    ListSection(
                      children: [
                        ListTile(
                          buildChevron: false,
                          child: Builder(
                            builder: (context) {
                              final isLowerThanMinimum = report.totalPoints < report.minTotalPoints;
                              final difference = (report.minTotalPoints - report.totalPoints).abs().removeTrailingZero();

                              return Column(
                                crossAxisAlignment: .stretch,
                                children: [
                                  Text("Total des points", style: AppStyles.secondaryHeader(context), maxLines: 2, overflow: .ellipsis),
                                  Text(
                                    "$difference point${difference == "1" ? "" : "s"} ${isLowerThanMinimum ? "nécessaires" : "au-dessus du minimum"}",
                                    style: AppStyles.primaryText(context).copyWith(color: isLowerThanMinimum ? AppColors.red : AppColors.green),
                                  ),

                                  const SizedBox.square(dimension: 6),
                                  NumberedProgressBar(
                                    lowerBound: isLowerThanMinimum ? "0" : report.minTotalPoints.toString(),
                                    upperBound: (isLowerThanMinimum ? report.minTotalPoints : report.maxTotalPoints).toString(),
                                    progress: max(
                                      0,
                                      isLowerThanMinimum
                                          ? report.totalPoints / report.minTotalPoints
                                          : (report.totalPoints - report.minTotalPoints) / (report.maxTotalPoints - report.minTotalPoints),
                                    ),
                                    value: report.totalPoints.removeTrailingZero(),
                                    color: isLowerThanMinimum ? AppColors.red : AppColors.green,
                                    fontSize: 32,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    if (report.maxFailingGrades > 0)
                      ListSection(
                        margin: .only(top: 16),
                        children: [
                          ListTile(
                            buildChevron: false,
                            child: Column(
                              crossAxisAlignment: .stretch,
                              children: [
                                Text("Moyennes insuffisantes", style: AppStyles.secondaryHeader(context), maxLines: 2, overflow: .ellipsis),
                                const SizedBox.square(dimension: 6),
                                NumberedProgressBar(
                                  lowerBound: "0",
                                  upperBound: report.maxFailingGrades.toString(),
                                  progress: (report.failingGrades / report.maxFailingGrades).clamp(0, 1),
                                  value: report.failingGrades.toString(),
                                  color: getProgressColor(report.failingGrades / report.maxFailingGrades),
                                  fontSize: 32,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    if (report.usingDoubleCompensation)
                      ListSection(
                        margin: .only(top: 16),
                        children: [
                          ListTile(
                            buildChevron: false,
                            child: Builder(
                              builder: (context) {
                                final isFailing = report.doubleCompensation < 0;
                                final progress = report.doubleCompensation / (report.deficit.abs() + report.surplus);
                                final difference = report.doubleCompensation.abs() * 2.0;

                                return Column(
                                  crossAxisAlignment: .stretch,
                                  children: [
                                    Text("Double compensation", style: AppStyles.secondaryHeader(context), maxLines: 2, overflow: .ellipsis),

                                    if (isFailing)
                                      Text(
                                        "+${difference.removeTrailingZero()} point${difference == 1.0 ? "" : "s"} nécessaires",
                                        style: TextStyle(fontSize: 14, color: AppColors.red),
                                      ),

                                    const SizedBox.square(dimension: 6),
                                    NumberedProgressBar(
                                      lowerBound: report.deficit.toDouble().removeTrailingZero(),
                                      upperBound: "+${report.surplus.toDouble().removeTrailingZero()}",
                                      progress: progress,
                                      value: report.doubleCompensation.toDouble().removeTrailingZero(),
                                      color: isFailing ? AppColors.red : AppColors.green,
                                      centered: true,
                                      fontSize: 32,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                    if (usingRestrictedGroup && restrictedGroupCodes.isNotEmpty)
                      ListSection(
                        margin: .only(top: 16),
                        children: [
                          ListTile(
                            buildChevron: false,
                            child: Builder(
                              builder: (context) {
                                final isLowerThanMinimum = report.restrictedGroupPoints < report.minRestrictedGroupPoints;

                                final progress = max(
                                  0,
                                  isLowerThanMinimum
                                      ? report.restrictedGroupPoints / report.minRestrictedGroupPoints
                                      : (report.restrictedGroupPoints - report.minRestrictedGroupPoints) /
                                            (report.maxRestrictedGroupPoints - report.minRestrictedGroupPoints),
                                ).toDouble();
                                final difference = (report.minRestrictedGroupPoints - report.restrictedGroupPoints).abs().removeTrailingZero();

                                return Column(
                                  crossAxisAlignment: .stretch,
                                  children: [
                                    Text("Points du groupe restreint", style: AppStyles.secondaryHeader(context), maxLines: 2, overflow: .ellipsis),

                                    Text(
                                      isLowerThanMinimum
                                          ? "Encore $difference point${difference == "1" ? "" : "s"}, courage !"
                                          : "$difference point${difference == "1" ? "" : "s"} au-dessus du minimum !",
                                      style: TextStyle(fontSize: 14, color: isLowerThanMinimum ? AppColors.red : AppColors.green),
                                    ),

                                    const SizedBox.square(dimension: 6),
                                    NumberedProgressBar(
                                      lowerBound: isLowerThanMinimum ? "0" : report.minRestrictedGroupPoints.toString(),
                                      upperBound: (isLowerThanMinimum ? report.minRestrictedGroupPoints : report.maxRestrictedGroupPoints).toString(),
                                      progress: progress,
                                      value: report.totalPoints.removeTrailingZero(),
                                      color: isLowerThanMinimum ? AppColors.red : AppColors.green,
                                      fontSize: 32,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                    BottomSpacing(),
                  ],
                ),

                // Criteria Options
                ListView(
                  padding: .symmetric(horizontal: 10),
                  children: [
                    ListSection(
                      children: [
                        ListTile.simple(
                          context,
                          title: "Max. de notes insuffisantes",
                          trailing: Row(
                            mainAxisSize: .min,
                            spacing: 6,
                            children: [
                              Text(report.maxFailingGrades.toString(), style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                              CupertinoListTileChevron(),
                            ],
                          ),
                          onTap: () => chooseMaxFailingSubjects(),
                        ),
                        ListTile.simple(
                          context,
                          title: "Double compensation",
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

                    if (allSubjects.length > 3)
                      ListSection(
                        margin: .only(top: 16),
                        children: [
                          ListTile.simple(
                            context,
                            title: "Groupe restreint",
                            trailing: CupertinoSwitch(
                              value: usingRestrictedGroup,
                              onChanged: (newValue) {
                                globals.persistent.setBool("UseRestrictedGroup", newValue);
                                setState(() {});
                              },
                            ),
                          ),

                          for (final compositeSubject in restrictedGroupCompositeSubjects)
                            ListTile(
                              leading: Button.icon(
                                context,
                                onTap: () => onSubjectRemoved(compositeSubject.code),
                                icon: HugeIcons.strokeRoundedCancel01,
                                isDestructive: true,
                              ),
                              child: Row(
                                spacing: 10,
                                children: [
                                  CompositeSubjectBadge(compositeSubject: compositeSubject, size: 20),
                                  Text(compositeSubject.name),
                                ],
                              ),
                            ),

                          for (final subject in restrictedGroupSubjects)
                            ListTile(
                              leading: SubjectBadge(subject: subject, size: 20),
                              trailing: CustomIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: AppColors.secondaryText.adaptTo(context)),
                              child: Text(subject.name, style: AppStyles.primaryText(context)),
                              onTap: () => showCupertinoDialog(
                                context: context,
                                builder: (_) => Dialog.confirm(
                                  content: "Supprimer '*${subject.name}*' du groupe restreint ?",
                                  onConfirm: () => onSubjectRemoved(subject.code),
                                ),
                              ),
                            ),

                          if (allSubjects.length - restrictedGroupSubjects.length - restrictedGroupCompositeSubjects.length > 1)
                            ListTile(
                              leading: CustomIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.placeholderText.adaptTo(context)),
                              buildChevron: false,
                              child: SubjectAutocomplete(
                                placeholder: "Ajouter une branche",
                                onSubjectSelected: (subject) => onSubjectSelected(subject.code),
                                onCompositeSubjectSelected: (compositeSubject) => onSubjectSelected(compositeSubject.code),
                                useCompositeSubjects: true,
                              ),
                            ),
                        ],
                      ),

                    BottomSpacing(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
