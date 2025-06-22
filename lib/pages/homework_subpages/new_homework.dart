import 'package:flutter/cupertino.dart';
import 'package:settings_ui/settings_ui.dart';

class NewHomework extends StatefulWidget {
  const NewHomework({super.key});

  @override
  State<StatefulWidget> createState() => _NewHomeworkState();
}

class _NewHomeworkState extends State<NewHomework> {
  final titleController = TextEditingController();

  bool isEvaluated = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Annuler"),
        ),
        middle: Text("Nouveau devoir"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Ajouter", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: Text("Informations principales"),
              tiles: [
                SettingsTile(
                  leading: Icon(CupertinoIcons.textformat),
                  title: CupertinoTextField(
                    controller: titleController,
                    decoration: BoxDecoration(),
                    padding: EdgeInsets.zero,
                    placeholder: "Titre",
                  ),
                ),
                SettingsTile(
                  leading: Icon(CupertinoIcons.book),
                  title: Text("Branche"),
                ),
                SettingsTile(
                  leading: Icon(CupertinoIcons.calendar),
                  title: Text("Date de remise"),
                ),
              ],
            ),
            SettingsSection(
              title: Text("Autres informations"),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icon(CupertinoIcons.chart_bar),
                  title: Text("Évalué"),
                  initialValue: isEvaluated,
                  onToggle: (newValue) {
                    setState(() => isEvaluated = newValue);
                  },
                ),
                if (isEvaluated) ...[
                  SettingsTile(title: Text("Type d'évaluation")),
                  SettingsTile(title: Text("Valeur")),
                ],
                SettingsTile(
                  leading: Icon(CupertinoIcons.doc_text),
                  title: CupertinoTextField(
                    controller: titleController,
                    decoration: BoxDecoration(),
                    padding: EdgeInsets.zero,
                    textAlignVertical: TextAlignVertical.top,
                    maxLines: 5,
                    placeholder: "Description et liens",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
