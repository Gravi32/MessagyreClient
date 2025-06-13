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

  List<Account?> searchResults = [];

  Widget buildSearchBar() {
    return CupertinoSearchTextField(
      placeholder: "Réchercher un.e gymnasien.ne",
      padding: EdgeInsets.symmetric(vertical: 4),
      controller: searchBarController,
      onChanged: (query) {
        router.send(
          Signal(type: SignalType.Search, data: {"Query": query}).pack(),
        );
      },
    );
  }

  Widget buildResult(Account account) {
    return CupertinoListTile(
      padding: EdgeInsets.symmetric(vertical: 12),
      title: Text(
        account.getDisplayableUsername(),
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
      ),
      leading: ProfilePictureDisplay(account.username, radius: 50),
      leadingSize: 50,
      subtitle:
          account.profile?.isNotEmpty ?? false
              ? Text(account.profile?["Class"] ?? "-")
              : null,
      additionalInfo: Icon(
        CupertinoIcons.chevron_forward,
        color: CupertinoColors.systemGrey,
      ),
      onTap: () {
        debugPrint("[search.dart] $account");
        Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(builder: (context) => ProfileOverlay(account)),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    router.onSignalReceived.listen((signal) {
      if (signal.type != SignalType.Search) return;

      var resultsJson = signal.data["Result"];
      if (resultsJson == null) return;

      try {
        List<dynamic> resultsList = jsonDecode(resultsJson);
        searchResults.clear();

        for (int i = 0; i < resultsList.length; i++) {
          var account = Account.fromMap(resultsList[i]);

          searchResults.add(account);
        }
        setState(() {});
      } catch (e, s) {
        debugPrintStack(stackTrace: s, label: e.toString());
      }

      // setState(() {
      //   searchResults =
      //       resultsList.map((jsonAccount) => Account.fromJson(jsonAccount)).toList();
      // });
    });
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
                if (searchResults[index] == null) return null;
                return buildResult(searchResults[index]!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
