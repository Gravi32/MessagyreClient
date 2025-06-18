import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/pages/overlays/profile.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final router = ConnectionController();
  final searchBarController = TextEditingController();

  String? usernameBeingLoaded;
  int searchCounter = 0;
  int latestSearch = 0;

  Map<String, String?> searchResults = {};

  void search(String query) async {
    final int thisSearch = ++searchCounter;

    final response = await router.get("/Accounts/Search?Query=$query");

    // Se questa ricerca non è più l’ultima → ignora
    if (thisSearch < latestSearch) return;

    latestSearch = thisSearch;

    if (response.body.isEmpty) return;

    Map<String, String?> rawResults;
    try {
      rawResults = Map<String, String?>.from(jsonDecode(response.body));
    } catch (e) {
      debugPrint("[Search Failed] Received invalid results: $e");
      return;
    }

    if (rawResults.isEmpty) return;

    setState(() {
      searchResults = rawResults;
    });
  }

  Widget buildSearchBar() {
    return CupertinoSearchTextField(
      placeholder: "Réchercher un.e gymnasien.ne",
      padding: EdgeInsets.symmetric(vertical: 4),
      controller: searchBarController,
      onChanged: search,
    );
  }

  Widget buildResult(String username, String? profilePictureURL) {
    return CupertinoListTile(
      padding: EdgeInsets.symmetric(vertical: 12),
      title: Text(
        Account.getDisplayableUsername(username),
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
      ),
      leading: ProfilePictureDisplay(username, radius: 50),
      leadingSize: 50,
      subtitle: Text("Class", style: TextStyle(fontSize: 14)),

      additionalInfo: Icon(
        CupertinoIcons.chevron_forward,
        color: CupertinoColors.systemGrey,
      ),
      onTap: () async {
        usernameBeingLoaded = username;

        final account = await router.getAccount(username);

        usernameBeingLoaded = null;

        if (account != null && mounted) {
          Navigator.of(context, rootNavigator: true).push(
            CupertinoPageRoute(builder: (context) => ProfileOverlay(account)),
          );
        }
      },
      trailing:
          usernameBeingLoaded == username ? CupertinoActivityIndicator() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Nouvelle conversation",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),
      child: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8),
            buildSearchBar(),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                if (searchResults.entries.elementAtOrNull(index) == null) {
                  return null;
                }
                return buildResult(
                  searchResults.keys.elementAt(index),
                  searchResults.values.elementAt(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
