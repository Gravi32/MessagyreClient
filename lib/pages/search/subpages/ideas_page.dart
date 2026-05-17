import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

class IdeasPage extends StatefulWidget {
  const IdeasPage({super.key});

  @override
  State<IdeasPage> createState() => _IdeasPageState();
}

class _IdeasPageState extends State<IdeasPage> {
  final network = NetworkService();

  final ideasNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);

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
          padding: .only(top: 16),
          children: [
            ...ideas.map((idea) {
              int id = idea["ID"] ?? -1;
              int myVote = idea["MyVote"] ?? 0;

              if (id < 0) return SizedBox();

              return RoundContainer(
                margin: .only(bottom: 16),
                width: .infinity,
                child: Column(
                  crossAxisAlignment: .stretch,
                  spacing: 8,
                  children: [
                    Text(idea["Title"] ?? "Sans titre", style: AppStyles.header(context), textAlign: .left),
                    Text(idea["Description"] ?? "Sans description", style: AppStyles.primaryText(context), textAlign: .left),
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
                            onTap: () => voteIdea(id, 1),
                          ),
                          Text((idea["LikesCount"] ?? 0).toString(), style: AppStyles.header(context)),
                          Button.icon(
                            context,
                            icon: HugeIcons.strokeRoundedThumbsDown,
                            color: myVote == -1 ? AppColors.accent : null,
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
