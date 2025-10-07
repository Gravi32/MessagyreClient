import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/singletons/data.dart';

class SubjectsSettingsPage extends StatefulWidget {
  const SubjectsSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SubjectsSettingsPageState();
}

class _SubjectsSettingsPageState extends State<SubjectsSettingsPage> {
  final data = Data();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(previousPageTitle: "Réglages", middle: Text("Branches")),
      child: SafeArea(
        child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedCrane)),
      ),
    );
  }
}
