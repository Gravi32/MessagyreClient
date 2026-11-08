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
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/card_group.dart';
import 'package:messagyre_client/utility/widgets/basics/section_header.dart';
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
    return CupertinoButton(
      minimumSize: .zero,
      pressedOpacity: .55,
      padding: const .symmetric(vertical: AppSpacing.m - 2, horizontal: AppSpacing.l),
      onPressed: () async {
        setState(() => usernameBeingLoaded = result.username);
        final account = await network.getAccount(result.username);
        setState(() => usernameBeingLoaded = null);

        if (account != null && mounted) {
          Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (context) => ProfilePage(account)));
        }
      },
      child: Row(
        spacing: AppSpacing.m + 2,
        children: [
          SizedBox.square(
            dimension: 44,
            child: ProfilePictureDisplay(accountUsername: result.username, pictureURL: result.profilePictureURL, radius: 22),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: 2,
              children: [
                Text(
                  result.displayName ?? Account.getDefaultDisplayName(result.username),
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: AppStyles.strongText(context),
                ),
                Text.rich(
                  TextSpan(
                    style: AppStyles.subheadline(context),
                    children: [
                      ...highlightSearchMatch(result.username, searchBarController.text),
                      if (result.classOrRole != null) ...[
                        const TextSpan(text: " · "),
                        ...highlightSearchMatch(result.classOrRole ?? "", searchBarController.text),
                      ],
                    ],
                  ),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
          if (usernameBeingLoaded == result.username) const GymnaseLoader(size: 18),
        ],
      ),
    );
  }

  Widget buildDecoration() {
    final bool isShortQuery = searchBarController.text.trim().length < 2;

    if (!isShortQuery) {
      return isSearching
          ? Center(child: GymnaseLoader(size: 18))
          : const EmptyState(
              icon: AppIcons.noResults,
              title: AppStrings.searchNoResults,
              padding: EdgeInsets.only(top: AppSpacing.xl),
            );
    }

    return const EmptyState(
      icon: AppIcons.search,
      title: AppStrings.searchEmptyTitle,
      subtitle: AppStrings.searchEmptySubtitle,
      padding: EdgeInsets.only(top: AppSpacing.xl),
    );
  }

  Widget buildNews() {
    return ValueListenableBuilder(
      valueListenable: newsNotifier,
      builder: (context, newsContent, _) => ListView(
        padding: .zero,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.s),
          SectionHeader(AppStrings.shortcuts),
          // The school's apps, like on a home screen
          RoundContainer(
            padding: const .symmetric(vertical: AppSpacing.l, horizontal: AppSpacing.s),
            child: Row(
              children: [
                for (final shortcut in [
                  (name: "Hermes II", iconPath: "assets/icons/hermesII.webp", url: "https://hermes.edu-vaud.ch/absences/synoptiques/eleve/"),
                  (name: "Teams", iconPath: "assets/icons/teams.webp", url: "https://teams.microsoft.com/v2/"),
                  (name: "Moodle", iconPath: "assets/icons/moodle.webp", url: "https://moodle.eduvaud.ch/my/"),
                ])
                  Expanded(
                    child: CupertinoButton(
                      padding: .zero,
                      minimumSize: .zero,
                      pressedOpacity: .55,
                      onPressed: () => openUrl(shortcut.url, tryApp: true),
                      child: Column(
                        spacing: AppSpacing.s,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            clipBehavior: .antiAlias,
                            padding: const .all(4),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: .circular(15),
                              border: .all(color: AppColors.separator.adaptTo(context)),
                            ),
                            child: Image.asset(shortcut.iconPath),
                          ),
                          Text(
                            shortcut.name,
                            maxLines: 1,
                            style: AppStyles.footnote(context).copyWith(color: AppColors.text.adaptTo(context), fontWeight: .w500),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (newsContent.isNotEmpty) ...[const SizedBox(height: AppSpacing.section), SectionHeader(AppStrings.announcements)],
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
              margin: .only(bottom: AppSpacing.m),
              transparent: true,
              padding: .zero,
              color: backgroundColor ?? AppColors.secondaryBackground.adaptTo(context),
              rawChild: Stack(
                children: [
                  if (hasBackgroundImage)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: .circular(AppRadius.card),
                        child: Image.network(metadata?["BackgroundImageUrl"], fit: .cover),
                      ),
                    ),
                  Container(
                    padding: .all(AppSpacing.card),
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

          const SizedBox(height: AppSpacing.section),
          ListSection(
            title: "Messagyre",
            children: [
              ListTile(
                leading: ListTile.iconTile(context, icon: HugeIcons.strokeRoundedIdea01),
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const IdeasPage())),
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 2,
                  children: [
                    Text(AppStrings.ideasBox, style: AppStyles.primaryText(context)),
                    Text(AppStrings.ideasBoxContent, style: AppStyles.footnote(context)),
                  ],
                ),
              ),
              ListTile(
                leading: ListTile.iconTile(context, icon: HugeIcons.strokeRoundedStar, color: AppColors.orange),
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
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 2,
                  children: [
                    Text(AppStrings.leaveReview, style: AppStyles.primaryText(context)),
                    Text(AppStrings.leaveReviewContent(Theme.of(context).platform == .android), style: AppStyles.footnote(context)),
                  ],
                ),
              ),
            ],
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
                ? Padding(
                    padding: const .only(top: AppSpacing.s),
                    child: CardGroup(separatorInset: AppSpacing.l + 44 + AppSpacing.m + 2, children: [for (final result in searchResults) buildResult(result)]),
                  )
                : Padding(padding: .only(top: 24), child: buildDecoration())
          : buildNews(),
    );
  }
}
