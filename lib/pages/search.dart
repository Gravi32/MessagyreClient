import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/pages/overlays/profile.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

class SearchResult {
  final String username;
  final String? classOrRole;
  final String? profilePictureURL;

  SearchResult({
    required this.username,
    this.classOrRole,
    this.profilePictureURL,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      username: json["Username"],
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

class SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin {
  final router = ConnectionController();
  final data = Data();
  final searchBarController = TextEditingController();

  bool isSearcing = false;
  String? usernameBeingLoaded;
  int searchCounter = 0;
  int latestSearch = 0;

  double backgroundFigureAnimation = 0;

  List<SearchResult> searchResults = [];

  void search(String query) async {
    final int thisSearch = ++searchCounter;

    setState(() {
      isSearcing = true;
    });

    final response = await router.get("/Accounts/Search?Query=$query");

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
        results =
            list
                .map((jsonResult) => SearchResult.fromJson(jsonResult))
                .toList();
      } catch (e) {
        debugPrint("[Search Failed] Invalid JSON: $e");
        return;
      }
    }

    setState(() {
      searchResults = results;
    });
  }

  Widget buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: CupertinoSearchTextField(
        placeholder: "Réchercher un.e gymnasien.ne",
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        controller: searchBarController,
        onChanged: search,
      ),
    );
  }

  Widget buildResult(SearchResult result) {
    return CupertinoListTile.notched(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: highlightSearchMatch(
                    Account.getDisplayableUsername(result.username),
                    searchBarController.text,
                  ),
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
                ),
              ),

              if (result.classOrRole != null) ...[
                SizedBox(width: 2),

                Text(
                  result.classOrRole ?? "",
                  style: TextStyle(
                    color: CupertinoColors.systemGrey2,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),

          if (usernameBeingLoaded == result.username) ...[
            SizedBox(width: 10),
            CupertinoActivityIndicator(),
          ],
        ],
      ),
      leading: ProfilePictureDisplay(
        accountUsername: result.username,
        pictureURL: result.profilePictureURL,
        radius: 40,
      ),
      leadingSize: 50,
      additionalInfo: HugeIcon(icon: 
        HugeIcons.strokeRoundedArrowRight01,
        color: CupertinoColors.systemGrey,
      ),
      onTap: () async {
        setState(() {
          usernameBeingLoaded = result.username;
        });

        final account = await router.getAccount(result.username);

        setState(() {
          usernameBeingLoaded = null;
        });

        if (account != null && mounted) {
          Navigator.of(context, rootNavigator: true).push(
            CupertinoPageRoute(builder: (context) => ProfileOverlay(account)),
          );
        }
      },
          
    );
  }

  Widget buildDecoration() {
    Decoration? getDecoration() {
      return data.appBrightness == Brightness.dark
          ? BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withAlpha(75),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          )
          : null;
    }

    return Center(
      child:
          searchBarController.text.length < 2
              ? Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 0.6),
                    curve: Curves.easeOutCubic,
                    duration: Duration(seconds: 2),
                    builder: (context, radius, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return RadialGradient(
                            center: Alignment.center,
                            radius: radius,
                            colors: [
                              CupertinoColors.white.withAlpha(200),
                              CupertinoColors.transparent,
                            ],
                            stops: [0.7, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("assets/BackgroundTile.png"),
                              repeat: ImageRepeat.repeat,
                              scale: 3,
                              opacity: 0.15,
                              colorFilter:
                                  data.appBrightness == Brightness.dark
                                      ? null
                                      : ColorFilter.mode(
                                        CupertinoColors.black.withAlpha(100),
                                        BlendMode.srcIn,
                                      ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: getDecoration(),
                        child: Text(
                          "Récherchez vos amis !",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 15),
                      Container(
                        width: 200,
                        decoration: getDecoration(),
                        child: Image.asset("assets/MessagyreGuy.png"),
                      ),
                    ],
                  ),
                ],
              )
              : isSearcing
              ? CupertinoActivityIndicator()
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(icon: 
                    HugeIcons.strokeRoundedUserQuestion01,
                    color: CupertinoColors.systemGrey,
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Aucun utilisateur trouvé.",
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
    );
  }

  @override bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          backgroundFigureAnimation = 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Nouvelle conversation",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8),
            buildSearchBar(),
            SizedBox(height: 8),
            Expanded(
              child: AnimatedOpacity(
                opacity: backgroundFigureAnimation,
                duration: Duration(milliseconds: 200),
                curve: Curves.easeOutSine,
                child:
                    searchResults.isNotEmpty
                        ? ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder:
                              (context, index) =>
                                  buildResult(searchResults[index]),
                        )
                        : buildDecoration(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
