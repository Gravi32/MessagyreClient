import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:flutter/material.dart' show Theme;
import 'package:in_app_review/in_app_review.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/empty_state.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/search/subpages/ideas_page.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';
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

  bool isSearching = false;
  String? usernameBeingLoaded;
  int searchCounter = 0;
  int latestSearch = 0;

  final newsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);

  List<SearchResult> searchResults = [];

  Future<void> fetchNews() async {
    final apiResponse = await network.get("/news/get");
    if (apiResponse.body.isEmpty) return;
    newsNotifier.value = List<Map<String, dynamic>>.from(tryJsonDecode(apiResponse.body) ?? []);

    App.pages[3].showBadge.value = globals.persistent.getInt("SeenNewsCount") != newsNotifier.value.length;
    globals.persistent.setInt("SeenNewsCount", newsNotifier.value.length);
  }

  void search(String query) async {
    final int thisSearch = ++searchCounter;

    setState(() {
      isSearching = true;
    });

    if (query.trim().length < 2) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
      return;
    }

    final response = await network.get("/accounts/search?query=${Uri.encodeQueryComponent(query.trim())}");

    if (thisSearch < latestSearch) return;
    setState(() {
      isSearching = false;
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
              GymnaseLoader(size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildDecoration() {
    final bool isShortQuery = searchBarController.text.trim().length < 2;

    if (!isShortQuery) {
      return isSearching
          ? Center(child: GymnaseLoader(size: 18))
          : const EmptyState(icon: AppIcons.noResults, title: AppStrings.searchNoResults, padding: EdgeInsets.only(top: AppSpacing.xl));
    }

    return const EmptyState(icon: AppIcons.search, title: AppStrings.searchEmptyTitle, subtitle: AppStrings.searchEmptySubtitle, padding: EdgeInsets.only(top: AppSpacing.xl));
  }

  Widget buildNews() {
    return ValueListenableBuilder(
      valueListenable: newsNotifier,
      builder: (context, newsContent, _) => ListView(
        padding: .only(top: 8),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: .symmetric(horizontal: 10, vertical: 8),
            child: Text(AppStrings.shortcuts, style: AppStyles.section(context)),
          ),
          Row(
            spacing: 8,
            children: [
              ...[
                (name: "Hermes II", iconPath: "assets/icons/hermesII.webp", url: "https://hermes.edu-vaud.ch/absences/synoptiques/eleve/"),
                (name: "Teams", iconPath: "assets/icons/teams.webp", url: "https://teams.microsoft.com/v2/"),
                (name: "Moodle", iconPath: "assets/icons/moodle.webp", url: "https://moodle.eduvaud.ch/my/"),
              ].map(
                (shortcut) => Expanded(
                  child: Button(
                    transparent: true,
                    color: AppColors.secondaryBackground.adaptTo(context),
                    onTap: () => openUrl(shortcut.url, tryApp: true),
                    rawChild: Column(
                      children: [
                        RoundContainer(
                          height: 52,
                          color: AppColors.tertiaryBackground.adaptTo(context),
                          borderRadius: 14,
                          padding: .all(2),
                          child: Image.asset(shortcut.iconPath),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: .center,
                          spacing: 2,
                          children: [
                            Expanded(
                              child: Text(shortcut.name, maxLines: 1, softWrap: false, overflow: .fade, style: AppStyles.strongText(context)),
                            ),
                            HugeIcon(icon: AppIcons.chevronRight, size: AppStyles.tertiaryText(context).fontSize, color: AppColors.tertiaryText.adaptTo(context)),
                          ],
                        ),
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
            child: Text(AppStrings.announcements, style: AppStyles.section(context)),
          ),
          ...newsContent.map((newsBox) {
            final Map<String, dynamic>? metadata = tryJsonDecode(newsBox["Metadata"] ?? "{}");
            final Map<String, dynamic>? coverWidget = tryJsonDecode(newsBox["CoverWidget"] ?? "{}");
            final Map<String, dynamic>? pageWidget = tryJsonDecode(newsBox["PageWidget"] ?? "{}");
            final hasBackgroundImage = metadata?["BackgroundImageUrl"] != null;
            final hasAuthor = (newsBox["AuthorUsername"] ?? "") != "";
            final backgroundColor = AppColors.fromName(metadata?["BackgroundColor"]);
            final foregroundColor = AppColors.fromName(metadata?["ForegroundColor"]);
            final onTapUrl = metadata?["OnTapUrl"];

            if (coverWidget == null || pageWidget == null) return const SizedBox();
            final isTappable = onTapUrl != null || pageWidget.isNotEmpty;
            const double authorPictureHeight = 30;
            const double trailingButtonHeight = 40;
            final double bottomPadding = max((hasAuthor ? authorPictureHeight + 8 : 0), (isTappable ? trailingButtonHeight + 8 : 0));

            return Button(
              margin: .only(bottom: 16),
              transparent: true,
              padding: .zero,
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
                    padding: .all(14),
                    margin: .only(bottom: bottomPadding),
                    child: Stac.fromJson(coverWidget, context) ?? const SizedBox(),
                  ),
                  if (hasAuthor)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: SizedBox.square(
                        dimension: authorPictureHeight,
                        child: ProfilePictureDisplay(accountUsername: newsBox["AuthorUsername"], includeBadge: false),
                      ),
                    ),
                  if (isTappable)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Button.icon(
                        context,
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: trailingButtonHeight,
                        color: backgroundColor,
                        iconColor: foregroundColor,
                      ),
                    ),
                ],
              ),
              onTap: isTappable
                  ? () => onTapUrl != null
                        ? openUrl(onTapUrl, tryApp: true)
                        : showCupertinoSheet(
                            context: context,
                            builder: (context) => Page(
                              topBar: TopBar.tab(context),
                              child: Stac.fromJson(pageWidget, context) ?? Center(child: Text(AppStrings.pageError, style: AppStyles.error(context))),
                            ),
                          )
                  : null,
            );
          }),

          Button(
            margin: .only(bottom: 16),
            padding: .all(16),
            color: AppColors.secondaryBackground.adaptTo(context),
            transparent: true,
            rawChild: Row(
              spacing: AppSpacing.m + 2,
              children: [
                ListTile.iconTile(context, icon: HugeIcons.strokeRoundedStar, color: AppColors.orange),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .stretch,
                    spacing: 2,
                    children: [
                      Text(AppStrings.leaveReview, style: AppStyles.strongText(context).copyWith(fontSize: 18)),
                      Text(AppStrings.leaveReviewContent(Theme.of(context).platform == .android), style: AppStyles.subheadline(context)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () async {
              if (await InAppReview.instance.isAvailable()) {
                await InAppReview.instance.requestReview();
              } else {
                await InAppReview.instance.openStoreListing(appStoreId: "6752887226");
              }
              if (context.mounted) {
                showCupertinoDialog(
                  context: context,
                  builder: (_) => Dialog(title: AppStrings.thanks, options: {AppStrings.close: () {}}),
                );
              }
            },
          ),

          Button(
            margin: .only(bottom: 16),
            padding: .all(16),
            color: AppColors.secondaryBackground.adaptTo(context),
            transparent: true,
            rawChild: Row(
              spacing: AppSpacing.m + 2,
              children: [
                ListTile.iconTile(context, icon: HugeIcons.strokeRoundedIdea01),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .stretch,
                    spacing: 2,
                    children: [
                      Text(AppStrings.ideasBox, style: AppStyles.strongText(context).copyWith(fontSize: 18)),
                      Text(AppStrings.ideasBoxContent, style: AppStyles.subheadline(context)),
                    ],
                  ),
                ),
                HugeIcon(icon: AppIcons.chevronRight, size: 18, color: AppColors.tertiaryText.adaptTo(context)),
              ],
            ),
            onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => IdeasPage())),
          ),

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
      topBar: TopBar.sliver(title: AppStrings.tabSearch),
      onRefresh: () async => await fetchNews(),
      field: Field.search(
        placeholder: AppStrings.searchPlaceholder,
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
