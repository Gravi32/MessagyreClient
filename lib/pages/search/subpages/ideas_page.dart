import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/tag.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

class IdeasPage extends StatefulWidget {
  const IdeasPage({super.key});

  @override
  State<IdeasPage> createState() => _IdeasPageState();
}

class _IdeasPageState extends State<IdeasPage> {
  final network = NetworkService();

  final ideasNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  String? activeTypeFilter, activeStatusFilter;

  Future<void> fetchIdeas() async {
    final apiResponse = await network.get("/ideas/get");
    if (apiResponse.body.isEmpty) return;
    ideasNotifier.value = List<Map<String, dynamic>>.from(tryJsonDecode(apiResponse.body) ?? []);
  }

  Future<void> voteIdea(int id, int direction) async {
    final apiResponse = await network.post("/ideas/vote", {"Id": id, "Direction": direction});
    if (apiResponse.statusCode != 200 && mounted) showCupertinoDialog(context: context, builder: (_) => Dialog.networkError(apiResponse));
    await fetchIdeas();
  }

  (String, Color)? getTypeTag(String? type) => switch (type) {
    "Feature" => ("Fonctionnalité", AppColors.green),
    "Bug" => ("Bug", AppColors.red),
    "Other" => ("Autre", AppColors.grey),
    _ => null,
  };

  (String, Color)? getStatusTag(String? status) => switch (status) {
    "Done" => ("Terminé", AppColors.green),
    "InProgress" => ("En cours", AppColors.orange),
    "Planned" => ("Planifié", AppColors.cyan),
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    fetchIdeas();
  }

  @override
  Widget build(BuildContext context) {
    return Page.sliver(
      topBar: TopBar.sliverWithChevron(context, title: "Boîte à idées"),
      onRefresh: () => fetchIdeas(),
      body: ValueListenableBuilder(
        valueListenable: ideasNotifier,
        builder: (context, ideas, _) => ListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: .only(top: 8),
          children: [
            Container(
              height: 60,
              padding: .symmetric(horizontal: 8),
              margin: .only(bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: .horizontal,
                child: Row(
                  spacing: 8,
                  children: [
                    Text("Filtres", style: AppStyles.secondaryHeader(context)),
                    ...() {
                      const types = ["Feature", "Bug", "Other", null];
                      const statuses = ["Done", "InProgress", "Planned", null];
                      final typeTag = getTypeTag(activeTypeFilter) ?? ("Tous", AppColors.secondaryButton.adaptTo(context));
                      final statusTag = getStatusTag(activeStatusFilter) ?? ("Tous", AppColors.secondaryButton.adaptTo(context));

                      return [
                            (label: "Type", options: types, tag: typeTag, update: (val) => activeTypeFilter = val),
                            (label: "État", options: statuses, tag: statusTag, update: (val) => activeStatusFilter = val),
                          ]
                          .map(
                            (button) => GestureDetector(
                              child: RoundContainer(
                                padding: .symmetric(vertical: 8, horizontal: 16),
                                child: Row(
                                  spacing: 8,
                                  children: [
                                    Text(button.label, style: AppStyles.primaryText(context)), // Molto più leggibile!
                                    Tag(text: button.tag.$1, color: button.tag.$2),
                                  ],
                                ),
                              ),
                              onTap: () => setState(() {
                                final nextIndex = (button.options.indexOf(activeTypeFilter) + 1) % button.options.length;
                                button.update(button.options[nextIndex]);
                              }),
                            ),
                          )
                          .toList();
                    }(),
                  ],
                ),
              ),
            ),

            ...ideas.map((idea) {
              int id = idea["ID"] ?? -1;
              int myVote = idea["MyVote"] ?? 0;
              final typeTag = getTypeTag(idea["Type"]);
              final statusTag = getStatusTag(idea["Status"]);

              if (idea["Type"] != (activeTypeFilter ?? idea["Type"])) return SizedBox();
              if (idea["Status"] != (activeStatusFilter ?? idea["Status"])) return SizedBox();
              if (id < 0) return SizedBox();

              return RoundContainer(
                margin: .only(bottom: 16),
                width: .infinity,
                child: Column(
                  crossAxisAlignment: .stretch,
                  spacing: 8,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        if (idea["AuthorUsername"] != null)
                          GestureDetector(
                            onTap: () async {
                              final account = await network.getAccount(idea["AuthorUsername"]);
                              if (!context.mounted) return;
                              if (account == null) {
                                showCupertinoDialog(
                                  context: context,
                                  builder: (_) => Dialog(title: "Compte introuvable"),
                                );
                                return;
                              }
                              showCupertinoSheet(context: context, builder: (_) => ProfilePage(account));
                            },
                            child: Container(
                              width: 24,
                              margin: .only(right: 6),
                              child: ProfilePictureDisplay(accountUsername: idea["AuthorUsername"], includeBadge: false),
                            ),
                          ),
                        if (typeTag != null) Tag(text: typeTag.$1, color: typeTag.$2),
                        if (statusTag != null) Tag(text: statusTag.$1, color: statusTag.$2),
                      ],
                    ),
                    SizedBox(),

                    Text(idea["Title"] ?? "Sans titre", style: AppStyles.header(context), textAlign: .left),

                    Text(idea["Description"] ?? "Sans description", style: AppStyles.primaryText(context), textAlign: .left),

                    SizedBox(),

                    SizedBox(
                      height: 40,
                      child: Row(
                        spacing: 16,
                        children: [
                          Spacer(),
                          Button.icon(
                            context,
                            icon: HugeIcons.strokeRoundedThumbsUp,
                            color: myVote == 1 ? AppColors.accent : null,
                            iconColor: myVote == 1 ? AppColors.white : null,
                            onTap: () => voteIdea(id, 1),
                          ),
                          Text((idea["LikesCount"] ?? 0).toString(), style: AppStyles.header(context)),
                          Button.icon(
                            context,
                            icon: HugeIcons.strokeRoundedThumbsDown,
                            color: myVote == -1 ? AppColors.accent : null,
                            iconColor: myVote == -1 ? AppColors.white : null,
                            onTap: () => voteIdea(id, -1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            CustomText(
              "Proposez d'autres idées de fonctionnalités que vous voudriez ajouter à Messagyre en envoyant un message au compte Instagram *messagyre.ch*",
              style: AppStyles.footer(context),
            ),

            BottomSpacing(),
          ],
        ),
      ),
    );
  }
}
