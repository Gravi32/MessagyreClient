import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/group_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:messagyre_client/utility/widgets/basics/action_sheet.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/chat_avatar.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

/// Someone who can be chosen for a group
@immutable
class _Person {
  final String username;
  final String? displayName;
  final String? pictureUrl;

  const _Person(this.username, this.displayName, this.pictureUrl);

  String get name => displayName?.trim().isNotEmpty == true ? displayName! : Account.getDefaultDisplayName(username);
}

/// Chooses people: my conversations first, anyone else by searching. The chosen ones show as chips above.
class _PeoplePicker extends StatefulWidget {
  final Set<String> excluded;
  final ValueChanged<List<_Person>> onChanged;

  const _PeoplePicker({required this.excluded, required this.onChanged});

  @override
  State<_PeoplePicker> createState() => _PeoplePickerState();
}

class _PeoplePickerState extends State<_PeoplePicker> {
  final network = NetworkService();
  final database = DatabaseService();
  final globals = GlobalsService();

  final chosen = <String, _Person>{};
  List<_Person> results = const [];
  String query = "";
  bool isSearching = false;
  String? searchError;
  int searchNumber = 0;
  Timer? debounce;

  /// The people I already talk to (not the shared chats)
  late final List<_Person> contacts = [
    for (final chat in database.chats.getAll())
      if (!chat.username.startsWith("#") && !chat.username.startsWith("@") && chat.username != globals.username && !widget.excluded.contains(chat.username))
        _Person(chat.username, chat.displayUsername, null),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  void onQueryChanged(String value) {
    setState(() => query = value.trim());
    debounce?.cancel();
    if (query.length < 2) {
      setState(() {
        results = const [];
        isSearching = false;
        searchError = null;
      });
      return;
    }
    debounce = Timer(const Duration(milliseconds: 300), search);
  }

  Future<void> search() async {
    final number = ++searchNumber;
    setState(() => isSearching = true);
    try {
      final response = await network.get("/accounts/search?query=${Uri.encodeQueryComponent(query)}");
      if (number != searchNumber || !mounted) return;
      if (response.statusCode != 200) {
        setState(() {
          isSearching = false;
          searchError = AppStrings.errorFor(response);
        });
        return;
      }
      final list = response.body.isEmpty ? const [] : jsonDecode(response.body) as List;
      setState(() {
        isSearching = false;
        searchError = null;
        results = [
          for (final item in list.whereType<Map>())
            if (item["Username"] != globals.username && !widget.excluded.contains(item["Username"]))
              _Person(item["Username"].toString(), item["DisplayName"]?.toString(), item["ProfilePictureURL"]?.toString()),
        ];
      });
    } catch (e) {
      if (number != searchNumber || !mounted) return;
      setState(() {
        isSearching = false;
        searchError = AppStrings.describe(e);
      });
    }
  }

  void toggle(_Person person) {
    HapticFeedback.selectionClick();
    setState(() => chosen.containsKey(person.username) ? chosen.remove(person.username) : chosen[person.username] = person);
    widget.onChanged(chosen.values.toList());
  }

  Widget buildPerson(_Person person) {
    final isChosen = chosen.containsKey(person.username);
    return CupertinoButton(
      padding: const .symmetric(vertical: AppSpacing.s),
      minimumSize: .zero,
      pressedOpacity: .6,
      onPressed: () => toggle(person),
      child: Row(
        spacing: AppSpacing.m,
        children: [
          SizedBox.square(dimension: AppSizes.avatarSmall, child: ProfilePictureDisplay(accountUsername: person.username, pictureURL: person.pictureUrl)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(person.name, maxLines: 1, overflow: .ellipsis, style: AppStyles.primaryText(context)),
                Text(person.username, maxLines: 1, overflow: .ellipsis, style: AppStyles.footnote(context)),
              ],
            ),
          ),
          AnimatedContainer(
            duration: AppDurations.fast,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isChosen ? AppColors.accent : AppColors.transparent,
              border: .all(color: isChosen ? AppColors.accent : AppColors.quaternaryText.adaptTo(context), width: 2),
            ),
            child: isChosen ? const Center(child: AppIcon(icon: AppIcons.done, size: 14, strokeWidth: 2.6, color: AppColors.white)) : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = query.length >= 2 ? results : contacts;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.m,
      children: [
        // The chosen people, removable
        AnimatedSize(
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: chosen.isEmpty
              ? const SizedBox(width: double.infinity)
              : Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    for (final person in chosen.values)
                      CupertinoButton(
                        padding: .zero,
                        minimumSize: .zero,
                        onPressed: () => toggle(person),
                        child: Container(
                          padding: const .fromLTRB(4, 4, 10, 4),
                          decoration: BoxDecoration(color: AppColors.accentSoft.adaptTo(context), borderRadius: .circular(20)),
                          child: Row(
                            mainAxisSize: .min,
                            spacing: 6,
                            children: [
                              SizedBox.square(dimension: 24, child: ProfilePictureDisplay(accountUsername: person.username, pictureURL: person.pictureUrl)),
                              Text(person.name, style: AppStyles.footnote(context).copyWith(color: AppColors.tint.adaptTo(context))),
                              AppIcon(icon: AppIcons.close, size: 12, color: AppColors.tint.adaptTo(context)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        Field(placeholder: "Rechercher quelqu'un", isSearch: true, onChanged: onQueryChanged, textInputAction: TextInputAction.search),
        Text(query.length >= 2 ? "Résultats" : "Vos conversations", style: AppStyles.section(context)),
        if (isSearching) const Center(child: GymnaseLoader(size: 22)),
        if (searchError != null) Text(searchError!, style: AppStyles.footnote(context).copyWith(color: AppColors.red)),
        if (!isSearching && list.isEmpty)
          Text(
            query.length >= 2 ? "Personne ne correspond à « $query »." : "Cherchez les personnes à ajouter par leur nom.",
            style: AppStyles.secondaryText(context),
          ),
        for (final person in list) buildPerson(person),
      ],
    );
  }
}

/// Says who couldn't be added: an app older than 4.109 doesn't know groups
void _explainTooOld(BuildContext context, List<String> tooOld) {
  if (tooOld.isEmpty) return;
  final names = tooOld.map(Account.getDefaultDisplayName).join(", ");
  showCupertinoDialog(
    context: context,
    builder: (_) => Dialog(
      title: tooOld.length == 1 ? "Pas encore ajouté·e" : "Pas encore ajoutés",
      content: "$names ${tooOld.length == 1 ? "doit" : "doivent"} d'abord mettre Messagyre à jour pour être dans un groupe. Ajoutez-${tooOld.length == 1 ? "la" : "les"} ensuite depuis la page du groupe.",
      options: {"Compris": () {}},
    ),
  );
}

/// Creates a group: a name, a picture if wanted, the people in it. Pops the new group's chat ID.
class NewGroupPage extends StatefulWidget {
  const NewGroupPage({super.key});

  @override
  State<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final groups = GroupService();
  final nameController = TextEditingController();
  List<_Person> members = const [];
  String? picturePath;
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void showError(String message) => showCupertinoDialog(context: context, builder: (_) => Dialog(title: AppStrings.errorTitle, content: message));

  Future<void> choosePicture() async {
    final choice = await ActionSheet.show<String>(
      context,
      title: "Photo du groupe",
      actions: [
        const SheetAction("Prendre une photo", icon: AppIcons.camera, value: "camera"),
        const SheetAction("Choisir dans la galerie", icon: HugeIcons.strokeRoundedAlbum02, value: "gallery"),
        if (picturePath != null) const SheetAction("Retirer la photo", icon: AppIcons.delete, value: "delete", isDestructive: true),
      ],
    );
    if (choice == null || !mounted) return;
    if (choice == "delete") return setState(() => picturePath = null);
    try {
      final picked = await ImagePicker().pickImage(source: choice == "camera" ? ImageSource.camera : ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (picked == null) return;
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [IOSUiSettings(title: "Retailler l'image", aspectRatioLockEnabled: true)],
      );
      if (cropped != null && mounted) setState(() => picturePath = cropped.path);
    } catch (e) {
      showError(AppStrings.describe(e));
    }
  }

  Future<void> create() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return showError("Donnez un nom au groupe.");
    if (members.isEmpty) return showError("Choisissez au moins une personne à mettre dans le groupe.");

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => isCreating = true);
    final result = await groups.create(name, members.map((person) => person.username).toList());
    if (!mounted) return;
    if (result.error != null || result.group == null) {
      setState(() => isCreating = false);
      return showError(result.error ?? "Le serveur n'a pas renvoyé le groupe créé : réessayez.");
    }
    if (picturePath != null) {
      final error = await groups.setPicture(result.group!.id, picturePath);
      if (error != null && mounted) showError("Le groupe a été créé, mais sa photo n'a pas pu être enregistrée : $error");
    }
    if (!mounted) return;
    final navigator = Navigator.of(context);
    _explainTooOld(navigator.context, result.tooOld);
    navigator.pop(result.group!.chatId);
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = nameController.text.trim().isNotEmpty && members.isNotEmpty;
    return Page.scrollable(
      context,
      topBar: TopBar.tab(
        context,
        title: "Nouveau groupe",
        trailing: Button.icon(context, icon: AppIcons.done, isLoading: isCreating, enabled: canCreate && !isCreating, onTap: create),
      ),
      spacing: AppSpacing.l,
      children: [
        Padding(
          padding: const .symmetric(horizontal: AppSpacing.page),
          child: Row(
            spacing: AppSpacing.m,
            children: [
              CupertinoButton(
                padding: .zero,
                minimumSize: .zero,
                onPressed: choosePicture,
                child: Stack(
                  clipBehavior: .none,
                  children: [
                    picturePath != null
                        ? GroupAvatar(groupId: "", size: 64, localPath: picturePath)
                        : Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tertiaryBackground.adaptTo(context)),
                            child: Center(child: AppIcon(icon: AppIcons.camera, size: 24, color: AppColors.tint.adaptTo(context))),
                          ),
                  ],
                ),
              ),
              Expanded(
                child: Field(placeholder: "Nom du groupe", controller: nameController, maxLines: 1, textCapitalization: TextCapitalization.sentences),
              ),
            ],
          ),
        ),
        Padding(
          padding: const .symmetric(horizontal: AppSpacing.page),
          child: Text(
            "Les messages du groupe sont chiffrés de bout en bout. Vous en serez administrateur·rice : vous pourrez ajouter et retirer des membres, et changer son nom et sa photo.",
            style: AppStyles.footnote(context),
          ),
        ),
        Padding(
          padding: const .symmetric(horizontal: AppSpacing.page),
          child: _PeoplePicker(excluded: const {}, onChanged: (chosen) => setState(() => members = chosen)),
        ),
      ],
    );
  }
}

/// Adds people to a group (admins). Pops true when people were added.
class AddGroupMembersPage extends StatefulWidget {
  final ChatGroup group;

  const AddGroupMembersPage({super.key, required this.group});

  @override
  State<AddGroupMembersPage> createState() => _AddGroupMembersPageState();
}

class _AddGroupMembersPageState extends State<AddGroupMembersPage> {
  List<_Person> chosen = const [];
  bool isAdding = false;

  Future<void> add() async {
    setState(() => isAdding = true);
    final result = await GroupService().addMembers(widget.group.id, chosen.map((person) => person.username).toList());
    if (!mounted) return;
    setState(() => isAdding = false);
    if (result.error != null) {
      showCupertinoDialog(context: context, builder: (_) => Dialog(title: AppStrings.errorTitle, content: result.error));
      return;
    }
    final navigator = Navigator.of(context);
    _explainTooOld(navigator.context, result.tooOld);
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Page.scrollable(
      context,
      topBar: TopBar.tab(
        context,
        title: "Ajouter des membres",
        trailing: Button.icon(context, icon: AppIcons.done, isLoading: isAdding, enabled: chosen.isNotEmpty && !isAdding, onTap: add),
      ),
      children: [
        Padding(
          padding: const .symmetric(horizontal: AppSpacing.page),
          child: _PeoplePicker(
            excluded: {for (final member in widget.group.members) member.username},
            onChanged: (people) => setState(() => chosen = people),
          ),
        ),
      ],
    );
  }
}
