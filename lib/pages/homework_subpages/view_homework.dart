import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';

class ViewHomework extends StatefulWidget {
  final Homework homework;

  const ViewHomework({super.key, required this.homework});

  @override
  State<StatefulWidget> createState() => _ViewHomeworkState();
}

class _ViewHomeworkState extends State<ViewHomework> {
  late final homework = widget.homework;

  void showDeletePopup() {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: Text("Supprimer le devoir ?"),
            content: Text(
              "Voulez-vous vraiment supprimer le devoir \"${widget.homework.title}\" ? Cette action est irréversible.",
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(0);
                },
                child: Text("Annuler"),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(2);
                },
                isDestructiveAction: true,
                child: Text("Supprimer"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(),

      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 60,
          ),
          child: Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  homework.title,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                ),

                SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      SubjectHelper.toFrench(homework.subject),
                      style: TextStyle(
                        color: CupertinoTheme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                    if (homework.isGraded) ...[
                      Spacer(),
                      Icon(CupertinoIcons.chart_bar),

                      SizedBox(width: 8),

                      Text(
                        "Noté",
                        style: TextStyle(
                          color: CupertinoTheme.of(context).primaryColor,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  "Description et liens:",
                  style: TextStyle(
                    color: CupertinoColors.inactiveGray.resolveFrom(context),
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  homework.description ?? "Pas de description.",
                  style: TextStyle(fontSize: 18),
                ),

                Divider(height: 40),
                Text(
                  "Créé le ${DateFormat("dd MMMM y", "fr_CH").format(homework.creationDate)}",
                  style: TextStyle(
                    color: CupertinoColors.inactiveGray.resolveFrom(context),
                  ),
                ),
                Spacer(),

                CupertinoButton.filled(
                  onPressed: () => Navigator.of(context).pop(1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 6,
                    children: [Icon(CupertinoIcons.pen), Text("Modifier")],
                  ),
                ),
                SizedBox(height: 6),
                CupertinoButton(
                  onPressed: showDeletePopup,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 6,
                    children: [Icon(CupertinoIcons.trash), Text("Supprimer")],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
