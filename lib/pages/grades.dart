import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<StatefulWidget> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  final router = ConnectionController();
  final data = Data();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                CupertinoSliverNavigationBar(largeTitle: Text("Notes")),
              ];
            },
            body: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Icon(
                      CupertinoIcons.sparkles,
                      size: 40,
                      color: CupertinoColors.separator.resolveFrom(context),
                    ),
                    Text(
                      "Ajoutez une note...",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
