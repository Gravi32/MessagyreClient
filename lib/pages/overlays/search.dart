import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/utility/classes.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final router = ConnectionController();
  final searchBarController = TextEditingController();

  List<String> searchResults = [];

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

  Widget buildResult(String username) {
    return CupertinoListTile(
      title: Text(username),
      leading: CircleAvatar(child: Text(username[0].toUpperCase())),
      subtitle: Text("2CCi1"),
      additionalInfo: Icon(
        CupertinoIcons.bubble_right,
        color: CupertinoColors.systemGrey,
      ),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (context) => ChatOverlay(recipientUsername: username,),));
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

      setState(() {
        searchResults = List<String>.from(jsonDecode(resultsJson));
      });
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
                return buildResult(searchResults[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
