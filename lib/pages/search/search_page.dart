import 'dart:convert';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';
import 'package:stac/stac.dart';

class SearchResult {
  final String username;
  final String? displayName;
  final String? classOrRole;
  final String? profilePictureURL;

  SearchResult({required this.username, this.displayName, this.classOrRole, this.profilePictureURL});

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      username: json["Username"],
      displayName: json["DisplayName"],
      classOrRole: json["ClassOrRole"],
      profilePictureURL: json["ProfilePictureURL"],
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final network = NetworkService();
  final globals = GlobalsService();
  final searchBarController = TextEditingController();
  final searchBarFocusNode = FocusNode();

  bool isSearcing = false;
  String? usernameBeingLoaded;
  int searchCounter = 0;
  int latestSearch = 0;

  final news = ValueNotifier<List<Map<String, dynamic>>>([]);

  List<SearchResult> searchResults = [];

  Future<void> fetchNews() async {
    final apiResponse = await network.get("/news/get");
    if (apiResponse.body.isEmpty) return;
    news.value = List<Map<String, dynamic>>.from(tryJsonDecode(apiResponse.body) ?? []);
    
    App.pages[3].showBadge.value = globals.persistent.getInt("SeenNewsCount") != news.value.length;
    globals.persistent.setInt("SeenNewsCount", news.value.length);
  }

  void search(String query) async {
    final int thisSearch = ++searchCounter;

    setState(() {
      isSearcing = true;
    });

    final response = await network.get("/accounts/search?query=$query");

    if (thisSearch < latestSearch) return;
    setState(() {
      isSearcing = false;
    });

    latestSearch = thisSearch;

    List<SearchResult> results;

    if (response.body.isEmpty) {
      results = [];
    } else {
      try {
        final list = jsonDecode(response.body) as List;
        results = list.map((jsonResult) => SearchResult.fromJson(jsonResult)).toList();
      } catch (e) {
        debugPrint("[Search Failed] Invalid JSON: $e");
        return;
      }
    }

    setState(() {
      searchResults = results;
    });
  }

  Widget buildResult(SearchResult result) {
    return SizedBox(
      width: .infinity,
      height: 60,
      child: CupertinoButton(
        minimumSize: .zero,
        padding: .symmetric(vertical: 6, horizontal: 10),
        onPressed: () async {
          setState(() {
            usernameBeingLoaded = result.username;
          });

          final account = await network.getAccount(result.username);

          setState(() {
            usernameBeingLoaded = null;
          });

          if (account != null && mounted) {
            Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (context) => ProfilePage(account)));
          }
        },
        child: Row(
          children: [
            ProfilePictureDisplay(accountUsername: result.username, pictureURL: result.profilePictureURL, radius: 26),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: .start,
              children: [
                Text(result.displayName ?? Account.getDefaultDisplayName(result.username), style: AppStyles.secondaryHeader(context)),
                Row(
                  spacing: 6,
                  crossAxisAlignment: .baseline,
                  textBaseline: .alphabetic,
                  children: [
                    Text.rich(TextSpan(children: highlightSearchMatch(result.username, searchBarController.text), style: AppStyles.primaryText(context))),
                    if (result.classOrRole != null)
                      Text.rich(
                        TextSpan(children: highlightSearchMatch(result.classOrRole ?? "", searchBarController.text), style: AppStyles.secondaryText(context)),
                      ),
                  ],
                ),
              ],
            ),
            if (usernameBeingLoaded == result.username) ...[
              SizedBox(width: 10),
              LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildDecoration() {
    final bool isShortQuery = searchBarController.text.length < 2;

    if (!isShortQuery) {
      return isSearcing
          ? Center(child: LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14))
          : Column(
              mainAxisAlignment: .center,
              children: [
                CustomIcon(icon: HugeIcons.strokeRoundedUserQuestion01, color: AppColors.secondaryText.adaptTo(context), size: 40),
                const SizedBox(height: 10),
                Text("Aucun utilisateur trouvé.", style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
              ],
            );
    }

    return Column(
      mainAxisAlignment: .center,
      spacing: 2,
      children: [
        CustomIcon(icon: HugeIcons.strokeRoundedSearch01, strokeWidth: 1.5, size: 48, color: AppColors.tertiaryText.adaptTo(context)),
        const SizedBox(height: 8),
        Text(
          "Recherchez un utilisateur",
          style: TextStyle(fontWeight: .w500, color: AppColors.secondaryText.adaptTo(context), fontSize: 22),
        ),
        Text(
          "Et appuyez sur son profil\npour entamer une conversation !",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: .w400, color: AppColors.tertiaryText.adaptTo(context)),
        ),
      ],
    );
  }

  Widget buildNews() {
    return ValueListenableBuilder(
      valueListenable: news,
      builder: (context, newsContent, _) => ListView(
        padding: .only(top: 8),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: .symmetric(horizontal: 10, vertical: 8),
            child: Text("Raccourcis", style: AppStyles.header(context)),
          ),
          Row(
            spacing: 8,
            children: [
              ...[
                (name: "Hermes II", iconPath: "assets/icons/hermesII.png", url: "https://hermes.edu-vaud.ch/absences/synoptiques/eleve/"),
                (name: "Teams", iconPath: "assets/icons/teams.png", url: "https://teams.microsoft.com/v2/"),
              ].map(
                (shortcut) => Expanded(
                  child: Button(
                    transparent: true,
                    color: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () => openUrl(shortcut.url),
                    rawChild: Column(
                      children: [
                        SizedBox.square(dimension: 40, child: Image.asset(shortcut.iconPath)),
                        SizedBox(height: 16),
                        Text(shortcut.name, style: AppStyles.secondaryHeader(context)),
                        Text("Ouvrir", style: AppStyles.tertiaryText(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Padding(
            padding: .symmetric(horizontal: 10, vertical: 8),
            child: Text("Annonces", style: AppStyles.header(context)),
          ),
          ...newsContent.map((box) {
            final Map<String, dynamic>? metadata = tryJsonDecode(box["Metadata"] ?? "{}");
            final Map<String, dynamic>? coverWidget = tryJsonDecode(box["CoverWidget"] ?? "{}");
            final Map<String, dynamic>? pageWidget = tryJsonDecode(box["PageWidget"] ?? "{}");
            final hasBackgroundImage = metadata?["BackgroundImageUrl"] != null;
            final hasAuthor = box["AuthorUsername"] != null;
            final backgroundColor = AppColors.fromName(metadata?["Color"]);
            final onTapUrl = metadata?["OnTapUrl"];

            if (coverWidget == null || pageWidget == null) return const SizedBox();
            final isTappable = onTapUrl != null || pageWidget.isNotEmpty;

            return Button(
              margin: .only(bottom: 16),
              padding: hasBackgroundImage ? .zero : null,
              color: backgroundColor ?? AppColors.secondaryBackground.adaptTo(context),
              rawChild: Stack(
                children: [
                  if (hasBackgroundImage)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: .circular(22.5),
                        child: Image.network(metadata?["BackgroundImageUrl"], fit: .cover),
                      ),
                    ),
                  Container(
                    padding: hasBackgroundImage ? .all(14) : .zero,
                    margin: .only(bottom: 48),
                    child: Stac.fromJson(coverWidget, context) ?? const SizedBox(),
                  ),
                  if (hasAuthor)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: SizedBox.square(dimension: 30, child: ProfilePictureDisplay(accountUsername: box["AuthorUsername"], includeBadge: false)),
                    ),
                  if (isTappable)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Button.icon(context, icon: HugeIcons.strokeRoundedArrowRight01, size: 40, color: backgroundColor),
                    ),
                ],
              ),
              onTap: isTappable
                  ? () => onTapUrl != null
                        ? openUrl(onTapUrl)
                        : showCupertinoSheet(
                            context: context,
                            builder: (context) => Page(
                              topBar: TopBar.tab(context),
                              child: Stac.fromJson(pageWidget, context) ?? Center(child: Text("Une erreur s'est produite.", style: AppStyles.error(context))),
                            ),
                          )
                  : null,
            );
          }),
          BottomSpacing(includeBottomBar: true),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    searchBarFocusNode.addListener(() => setState(() {}));
    fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Page.sliver(
      topBar: TopBar.sliver(title: "Recherche"),
      onRefresh: () async => await fetchNews(),
      field: Field.search(
        placeholder: "Rechercher un.e gymnasien.ne",
        controller: searchBarController,
        focusNode: searchBarFocusNode,
        onChanged: search,
        onClear: () => setState(() => searchResults.clear()),
      ),
      body: searchBarFocusNode.hasFocus || searchResults.isNotEmpty && searchBarController.text.isNotEmpty
          ? searchResults.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: .only(top: 16),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) => buildResult(searchResults[index]),
                  )
                : Padding(padding: .only(top: 24), child: buildDecoration())
          : buildNews(),
    );
  }
}
