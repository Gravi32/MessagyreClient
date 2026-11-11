import 'dart:convert';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/pages/search/widgets/news_card.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/empty_state.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/tag.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';

/// What the server answered when it refused: its own sentence ({"Error"}), or the reason behind the status code
String _errorOf(http.Response response) {
  try {
    final data = jsonDecode(response.body);
    if (data is Map && data["Error"] is String) return data["Error"];
  } catch (_) {}
  return AppStrings.errorFor(response);
}

String _day(DateTime date) => DateFormat("d MMMM yyyy", "fr_CH").format(date);

/// Every announcement of the search tab, also the hidden and the expired ones: to add, edit and delete them.
/// For the admin accounts only (the server checks it: GET /admin/news).
class NewsAdminPage extends StatefulWidget {
  const NewsAdminPage({super.key});

  @override
  State<NewsAdminPage> createState() => _NewsAdminPageState();
}

class _NewsAdminPageState extends State<NewsAdminPage> {
  final network = NetworkService();
  List<Map<String, dynamic>>? news;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await network.get("/admin/news");
      if (!mounted) return;
      final data = response.statusCode == 200 ? tryJsonDecode(response.body) : null;
      setState(() {
        if (data is List) news = [for (final row in data.whereType<Map>()) Map<String, dynamic>.from(row)];
        error = data is List ? null : _errorOf(response);
      });
    } catch (e) {
      if (mounted) setState(() => error = AppStrings.describe(e));
    }
  }

  Future<void> edit(Map<String, dynamic>? row) async {
    final saved = await Navigator.of(context).push<bool>(CupertinoPageRoute(fullscreenDialog: true, builder: (_) => NewsEditorPage(toEdit: row)));
    if (saved == true) await load();
  }

  /// Who sees it now, in a few tags above the card
  List<Widget> tagsOf(Map<String, dynamic> row) {
    final expired = row["Expired"] == 1 || row["Expired"] == true;
    final target = row["TargetType"]?.toString();
    final expiration = DateTime.tryParse(row["ExpirationDate"]?.toString() ?? "");
    final created = DateTime.tryParse(row["CreationDate"]?.toString() ?? "");
    return [
      if (expired)
        Tag(text: "Expirée", color: AppColors.grey)
      else if (target == "None")
        Tag(text: "Masquée", color: AppColors.grey)
      else if (target == "Version")
        Tag(text: "Avant la ${row["Target"]}", color: AppColors.cyan)
      else if (target == "User")
        Tag(text: "Pour ${row["Target"]}", color: AppColors.cyan)
      else
        Tag(text: "Visible", color: AppColors.green),
      if (((row["Priority"] as num?) ?? 0) >= 10) Tag(text: "Épinglée", color: AppColors.accent),
      if (expiration != null && !expired) Tag(text: "Jusqu'au ${_day(expiration)}", color: AppColors.orange),
      if (created != null)
        Padding(
          padding: const .only(left: 2),
          child: Text(_day(created), style: AppStyles.footnote(context)),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final list = news;
    return Page(
      topBar: TopBar.tab(
        context,
        title: AppStrings.announcements,
        trailing: Button.icon(context, icon: AppIcons.add, onTap: () => edit(null)),
      ),
      child: ListView(
        padding: const .only(top: AppSpacing.s, bottom: AppSpacing.xxl),
        children: [
          if (error != null)
            Padding(
              padding: const .only(bottom: AppSpacing.m),
              child: Text(error!, textAlign: .center, style: AppStyles.error(context)),
            ),
          if (list == null && error == null)
            const Padding(
              padding: .all(AppSpacing.xl),
              child: Center(child: GymnaseLoader(size: 22)),
            ),
          if (list != null && list.isEmpty)
            EmptyState(
              icon: AppIcons.add,
              title: "Aucune annonce",
              subtitle: "Écrivez la première : tout le monde la verra dans l'onglet Recherche.",
              actionText: "Nouvelle annonce",
              onAction: () => edit(null),
            ),
          for (final row in list ?? const <Map<String, dynamic>>[]) ...[
            Padding(
              padding: const .only(left: 2, bottom: AppSpacing.s),
              child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: .center, children: tagsOf(row)),
            ),
            NewsCard(
              news: row,
              onTap: () => edit(row),
              margin: const .only(bottom: AppSpacing.xl),
            ),
          ],
          if (list != null && list.isNotEmpty)
            Text("Touchez une annonce pour la modifier ou la supprimer.", textAlign: .center, style: AppStyles.footnote(context)),
        ],
      ),
    );
  }
}

/// Writes a new announcement or changes one: a title, a text, a colour, a link, who sees it and until when.
/// The card above the fields is the one people will see. Pops true once saved or deleted.
class NewsEditorPage extends StatefulWidget {
  final Map<String, dynamic>? toEdit;
  const NewsEditorPage({super.key, this.toEdit});

  @override
  State<NewsEditorPage> createState() => _NewsEditorPageState();
}

class _NewsEditorPageState extends State<NewsEditorPage> {
  /// The colours the server accepts (Admin.newsColors); "" is a plain card
  static const colors = ["accent", "cyan", "blue", "green", "orange", "red", "pink", "indigo", "teal", ""];

  final network = NetworkService();
  final globals = GlobalsService();
  final titleController = TextEditingController();
  final textController = TextEditingController();
  final urlController = TextEditingController();

  late final content = widget.toEdit == null ? null : NewsContent(widget.toEdit!);
  late final String? target = widget.toEdit?["TargetType"]?.toString();
  late final bool hasOwnTarget = target == "Version" || target == "User";

  /// An announcement laid out by hand in the database (a picture beside the text…): saving it here redraws it
  late final bool isHandMade =
      content != null && content!.metadata["Title"] == null && (content!.texts.length > 2 || content!.coverWidget?["type"] != "column");

  String color = "accent";
  bool pinned = false;
  bool signed = true;
  bool visible = true;
  DateTime? expiration;
  bool isSaving = false;
  String? titleError;
  String? urlError;

  @override
  void initState() {
    super.initState();
    final existing = content;
    if (existing != null) {
      titleController.text = existing.title;
      textController.text = existing.text;
      urlController.text = existing.url ?? "";
      color = colors.contains(existing.colorName?.toLowerCase()) ? existing.colorName!.toLowerCase() : (existing.colorName == null ? "" : "accent");
      pinned = ((existing.row["Priority"] as num?) ?? 0) >= 10;
      signed = existing.author != "";
      visible = target != "None";
      expiration = DateTime.tryParse(existing.row["ExpirationDate"]?.toString() ?? "")?.dateOnly();
    }
    for (final controller in [titleController, textController, urlController]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    textController.dispose();
    urlController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get preview {
    final built = NewsContent.build(
      title: titleController.text.trim().isEmpty ? "Titre de l'annonce" : titleController.text.trim(),
      text: textController.text.trim(),
      colorName: color,
      url: urlController.text.trim(),
      author: signed ? (content?.author.isNotEmpty == true ? content!.author : globals.username ?? "") : "",
    );
    // The picture behind an existing announcement stays on a coloured card
    final picture = content?.metadata["BackgroundImageUrl"];
    if (picture != null && color.isNotEmpty) (built["Metadata"] as Map)["BackgroundImageUrl"] = picture;
    return built;
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    final url = urlController.text.trim();
    final link = Uri.tryParse(url);
    setState(() {
      titleError = title.isEmpty ? "Entrez un titre" : null;
      urlError = url.isNotEmpty && !(link != null && link.hasAuthority && (link.scheme == "https" || link.scheme == "http"))
          ? "Le lien doit commencer par https://"
          : null;
    });
    if (titleError != null || urlError != null || isSaving) return;

    setState(() => isSaving = true);
    try {
      final response = await network.post("/admin/news/save", {
        if (widget.toEdit != null) "ID": widget.toEdit!["ID"],
        "Title": title,
        "Text": textController.text.trim(),
        "Color": color,
        "Url": url,
        "Signed": signed,
        "Pinned": pinned,
        "Visible": visible,
        "ExpirationDate": expiration == null ? "" : DateFormat("yyyy-MM-dd").format(expiration!),
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => isSaving = false);
      showCupertinoDialog(
        context: context,
        builder: (_) => Dialog(title: "L'annonce n'a pas été enregistrée", content: _errorOf(response), options: {AppStrings.close: () {}}),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      showCupertinoDialog(context: context, builder: (_) => Dialog.error(e));
    }
  }

  Future<void> delete() async {
    setState(() => isSaving = true);
    try {
      final response = await network.post("/admin/news/delete", {"ID": widget.toEdit!["ID"]});
      if (!mounted) return;
      // Already deleted from another phone: gone all the same
      if (response.statusCode == 200 || response.statusCode == 404) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => isSaving = false);
      showCupertinoDialog(
        context: context,
        builder: (_) => Dialog(title: "L'annonce n'a pas été supprimée", content: _errorOf(response), options: {AppStrings.close: () {}}),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      showCupertinoDialog(context: context, builder: (_) => Dialog.error(e));
    }
  }

  Widget sectionTitle(String title) => Padding(
    padding: const .only(left: 4, top: AppSpacing.xl, bottom: AppSpacing.s),
    child: Text(title, style: AppStyles.section(context)),
  );

  Widget buildColors() {
    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.m,
      children: [
        for (final name in colors)
          CupertinoButton(
            padding: .zero,
            minimumSize: .zero,
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => color = name);
            },
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: .circle,
                color: name.isEmpty ? AppColors.secondaryBackground.adaptTo(context) : AppColors.fromName(name),
                border: .all(color: color == name ? AppColors.text.adaptTo(context) : AppColors.quaternaryText.adaptTo(context), width: color == name ? 3 : 1),
              ),
              child: color == name
                  ? Center(
                      child: AppIcon(icon: AppIcons.done, size: 16, strokeWidth: 2.6, color: name.isEmpty ? AppColors.text.adaptTo(context) : AppColors.white),
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.toEdit != null;
    return Page(
      topBar: TopBar.form(
        context,
        title: editing ? "Modifier l'annonce" : "Nouvelle annonce",
        trailing: Button.icon(context, icon: AppIcons.done, isLoading: isSaving, onTap: save),
      ),
      child: ListView(
        padding: const .only(top: AppSpacing.s, bottom: AppSpacing.xxl),
        children: [
          // What people will see; it does nothing here
          IgnorePointer(
            child: NewsCard(news: preview, margin: .zero),
          ),
          if (isHandMade)
            Padding(
              padding: const .only(top: AppSpacing.s, left: 4, right: 4),
              child: Text(
                "Cette annonce avait une mise en page faite à la main. En l'enregistrant ici, elle devient un titre et un texte, comme l'aperçu ci-dessus.",
                style: AppStyles.footnote(context),
              ),
            ),

          sectionTitle("Annonce"),
          Field(
            margin: const .only(bottom: AppSpacing.m),
            controller: titleController,
            placeholder: "Titre",
            maxLines: 2,
            error: titleError,
            onTap: () => setState(() => titleError = null),
          ),
          Field(controller: textController, placeholder: "Texte (facultatif)", minLines: 3, maxLines: 12),

          sectionTitle("Couleur"),
          buildColors(),

          sectionTitle("Lien"),
          Field(
            controller: urlController,
            placeholder: "https://… (facultatif)",
            keyboardType: .url,
            textCapitalization: .none,
            error: urlError,
            onTap: () => setState(() => urlError = null),
          ),
          Padding(
            padding: const .only(top: AppSpacing.s, left: 4),
            child: Text("Toucher l'annonce ouvre ce lien.", style: AppStyles.footnote(context)),
          ),

          sectionTitle("Options"),
          ListSection(
            footer: hasOwnTarget
                ? (target == "Version"
                      ? "Montrée seulement à ceux qui ont une version de l'app plus ancienne que la ${widget.toEdit?["Target"]}."
                      : "Montrée seulement à ${widget.toEdit?["Target"]}.")
                : null,
            children: [
              if (!hasOwnTarget)
                ListTile.simple(
                  context,
                  icon: AppIcons.search,
                  title: "Visible par tout le monde",
                  buildChevron: false,
                  onTap: () => setState(() => visible = !visible),
                  trailing: CupertinoSwitch(activeTrackColor: AppColors.accent, value: visible, onChanged: (value) => setState(() => visible = value)),
                ),
              ListTile.simple(
                context,
                icon: AppIcons.pin,
                title: "Épingler en haut",
                buildChevron: false,
                onTap: () => setState(() => pinned = !pinned),
                trailing: CupertinoSwitch(activeTrackColor: AppColors.accent, value: pinned, onChanged: (value) => setState(() => pinned = value)),
              ),
              ListTile.simple(
                context,
                icon: AppIcons.edit,
                title: "Signer avec ma photo",
                buildChevron: false,
                onTap: () => setState(() => signed = !signed),
                trailing: CupertinoSwitch(activeTrackColor: AppColors.accent, value: signed, onChanged: (value) => setState(() => signed = value)),
              ),
              ListTile.simple(
                context,
                icon: AppIcons.date,
                title: "Afficher jusqu'au",
                onTap: () => showCupertinoModalPopup(
                  context: context,
                  builder: (_) => CustomDatePicker(
                    initialDate: expiration ?? DateTime.now().addDays(7),
                    allowPast: false,
                    onDateSelected: (date) => setState(() => expiration = date.dateOnly()),
                  ),
                ),
                trailing: Text(expiration == null ? "Sans limite" : _day(expiration!), style: AppStyles.secondaryText(context)),
              ),
              if (expiration != null)
                ListTile.simple(
                  context,
                  icon: AppIcons.close,
                  title: "Enlever la date de fin",
                  buildChevron: false,
                  onTap: () => setState(() => expiration = null),
                ),
            ],
          ),

          if (editing) ...[
            const SizedBox(height: AppSpacing.section),
            ListSection(
              children: [
                ListTile.simple(
                  context,
                  icon: AppIcons.delete,
                  title: "Supprimer cette annonce",
                  isDestructive: true,
                  buildChevron: false,
                  onTap: () => showCupertinoDialog(
                    context: context,
                    builder: (_) => Dialog.confirm(
                      content: "Supprimer cette annonce pour tout le monde ? Elle ne pourra pas être récupérée.",
                      onConfirm: delete,
                      isDestructive: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
