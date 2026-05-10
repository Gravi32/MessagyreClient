import 'dart:convert';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/settings/subpages/profile_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/field.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

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
  bool showDecoration = true;

  double backgroundFigureAnimation = 0;

  List<SearchResult> searchResults = [];

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
    return CupertinoListTile.notched(
      padding: .symmetric(vertical: 6, horizontal: 10),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: .start,
            children: [
              Text(result.displayName ?? Account.getDefaultDisplayName(result.username), style: TextStyle(fontWeight: .w500, fontSize: 20)),
              Row(
                spacing: 6,
                crossAxisAlignment: .baseline,
                textBaseline: .alphabetic,
                children: [
                  Text.rich(
                    TextSpan(
                      children: highlightSearchMatch(result.username, searchBarController.text),
                      style: TextStyle(fontWeight: .w400, fontSize: 16),
                    ),
                  ),
                  if (result.classOrRole != null)
                    Text.rich(
                      TextSpan(
                        children: highlightSearchMatch(result.classOrRole ?? "", searchBarController.text),
                        style: TextStyle(color: AppColors.grey, fontSize: 14, fontWeight: .w400),
                      ),
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
      leading: ProfilePictureDisplay(accountUsername: result.username, pictureURL: result.profilePictureURL, radius: 26),
      leadingSize: 50,
      additionalInfo: CupertinoListTileChevron(),
      onTap: () async {
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
    );
  }

  Widget buildDecoration() {
    final bool isShortQuery = searchBarController.text.length < 2;

    if (!isShortQuery) {
      return Center(
        child: isSearcing
            ? LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14)
            : Column(
                mainAxisAlignment: .center,
                children: [
                  CustomIcon(icon: HugeIcons.strokeRoundedUserQuestion01, color: AppColors.secondaryText.adaptTo(context), size: 40),
                  const SizedBox(height: 10),
                  Text("Aucun utilisateur trouvé.", style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                ],
              ),
      );
    }

    return Center(
      child: SizedBox.expand(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: backgroundFigureAnimation),
          curve: Curves.easeOutCubic,
          duration: Duration(seconds: backgroundFigureAnimation > 0 ? 2 : 1),
          builder: (context, alpha, child) {
            return Stack(
              alignment: .center,
              children: [
                _buildBackgroundImage(alpha),
                _buildCenterContent(context),
                _buildForegroundCharacter(context, alpha, -80 + (MediaQuery.viewPaddingOf(context).bottom + 80) * Curves.easeOutCubic.transform(alpha)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackgroundImage(double alpha) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: showDecoration ? 1 : 0,
        duration: Duration(milliseconds: showDecoration ? 200 : 100),
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: const Alignment(0, 1.2),
            end: Alignment(0, 1 - alpha),
            colors: [AppColors.white.withAlpha(30), AppColors.white.withAlpha(40), AppColors.transparent],
            stops: const [.1, 0.3, 1],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: Image.asset("assets/wallpaper.png", fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildCenterContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 2,
      children: [
        CustomIcon(icon: HugeIcons.strokeRoundedSearch01, strokeWidth: 1.5, size: 48, color: AppColors.tertiaryText.adaptTo(context)),
        const SizedBox(height: 8),
        Text(
          "Recherchez un utilisateur",
          style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.secondaryText.adaptTo(context), fontSize: 22),
        ),
        Text(
          "Et appuyez sur son profil\npour entamer une conversation !",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.tertiaryText.adaptTo(context)),
        ),
        SizedBox(height: showDecoration ? 100 : 0),
      ],
    );
  }

  Widget _buildForegroundCharacter(BuildContext context, double alpha, double yPosition) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: yPosition,
      child: AnimatedOpacity(
        opacity: showDecoration ? 1 : 0,
        duration: Duration(milliseconds: showDecoration ? 200 : 100),
        child: Image.asset("assets/messagyreGuy.png", fit: .fitWidth),
      ),
    );
  }

  void triggerAnimation() {
    setState(() => backgroundFigureAnimation = MainPage.pageIndex.value == 3 ? 1 : 0);
  }

  @override
  void initState() {
    super.initState();
    MainPage.pageIndex.addListener(triggerAnimation);
    searchBarFocusNode.addListener(() {
      if (searchBarFocusNode.hasFocus) {
        setState(() => showDecoration = false);
      } else {
        Future.delayed(Duration(milliseconds: 200)).then((_) => setState(() => showDecoration = true));
      }
    });
  }

  @override
  void dispose() {
    MainPage.pageIndex.removeListener(triggerAnimation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.tab(context, title: "Recherche", buildChevron: false),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 8,
        children: [
          const SizedBox.shrink(),

          Field(
            placeholder: "Rechercher un.e gymnasien.ne",
            controller: searchBarController,
            focusNode: searchBarFocusNode,
            onChanged: search,
            onTap: () => setState(() => showDecoration = false),
          ),

          Expanded(
            child: AnimatedOpacity(
              opacity: backgroundFigureAnimation,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOutSine,
              child: searchResults.isNotEmpty
                  ? ListView.builder(itemCount: searchResults.length, itemBuilder: (context, index) => buildResult(searchResults[index]))
                  : buildDecoration(),
            ),
          ),
        ],
      ),
    );
  }
}
