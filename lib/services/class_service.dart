import 'dart:async';
import 'dart:convert';

import 'package:basic_utils/basic_utils.dart' show CryptoUtils;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/services/chat_service.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:pointycastle/export.dart' show RSAPublicKey;

/// A class of the Gymnase de Renens, written like the school writes it (gyre.ch, "Maîtrises de classe"): the year,
/// the school (M = maturité, EC = école de commerce, C = école de culture générale) and the class: "1M05", "3Mb11"
/// (bilingual), "2EC1", "1C3", "2Cci1" (ECG: the professional domain from the 2nd year), "2Cadts" (two domains).
/// The classes that can be chosen come from the server ([ClassCatalog]); any value of that shape is a class.
@immutable
class SchoolClass {
  final String name;

  const SchoolClass._(this.name);

  static final _pattern = RegExp(r'^([1-4])(EC|M|C)([A-Za-z0-9]{1,8})$');

  /// What someone who isn't at the Gymnase de Renens chooses (the value the accounts already had)
  static const outside = "Externe";

  /// A class of the catalog whatever the case ("2cci1" → "2Cci1"), or any value shaped like a class. Null for
  /// anything else ("Externe", "Enseignant"...)
  static SchoolClass? tryParse(String? value, {ClassCatalog? catalog}) {
    final cleaned = value?.trim() ?? "";
    if (cleaned.isEmpty) return null;
    final known = (catalog ?? ClassCatalog.current).find(cleaned);
    if (known != null) return SchoolClass._(known);
    return _pattern.hasMatch(cleaned) ? SchoolClass._(cleaned) : null;
  }

  int get year => int.parse(name[0]);
  String get school => _pattern.firstMatch(name)!.group(2)!;

  /// What comes after the school: "05", "b11", "1", "ci1", "adts"
  String get section => _pattern.firstMatch(name)!.group(3)!;

  String get yearName => year == 1 ? "1re année" : "${year}e année";

  /// "École de maturité, bilingue", "Communication et information", "Arts et design et Travail social"...
  String describe([ClassCatalog? catalog]) {
    final source = catalog ?? ClassCatalog.current;
    final schoolName = source.schoolNamed(school)?.name ?? school;
    if (school == "M" && section.startsWith("b")) return "$schoolName, bilingue";
    if (school == "C" && year > 1) {
      final letters = section.replaceAll(RegExp(r'\d'), "").toLowerCase();
      final names = [for (var index = 0; index + 1 < letters.length; index += 2) source.domains[letters.substring(index, index + 2)]];
      if (letters.length.isEven && names.isNotEmpty && names.every((name) => name != null)) return names.join(" et ");
    }
    return schoolName;
  }

  /// The school year of a date ("2026-2027"). It changes in the middle of August, when the classes are known
  /// (the server uses the same rule: ClassesService.YearLabel).
  static String yearLabel(DateTime date) {
    final start = date.month > 8 || (date.month == 8 && date.day >= 15) ? date.year : date.year - 1;
    return "$start-${start + 1}";
  }

  @override
  bool operator ==(Object other) => other is SchoolClass && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// A school of the Gymnase in the [ClassCatalog]: its classes per year, in the picker's order
@immutable
class CatalogSchool {
  final String code;
  final String name;
  final String shortName;
  final Map<int, List<String>> classes;

  const CatalogSchool(this.code, this.name, this.shortName, this.classes);

  List<int> get years => classes.keys.toList()..sort();
}

/// The classes that can be chosen this school year: `GET /classes/catalog` (Assets/Classes.json on the server,
/// updated every August from gyre.ch without an app release). The last one received is kept on the phone, and the
/// app has its own copy (assets/classes.json) for a first start without connection.
@immutable
class ClassCatalog {
  final String? year;
  final List<CatalogSchool> schools;
  final Map<String, String> domains;

  const ClassCatalog({this.year, required this.schools, this.domains = const {}});

  static const empty = ClassCatalog(schools: []);

  /// The catalog in use (the server's, the last one received or the app's copy)
  static ClassCatalog current = empty;

  static ClassCatalog? tryParse(String? json) {
    if (json == null) return null;
    try {
      final data = jsonDecode(json);
      if (data is! Map || data["Schools"] is! List) return null;
      final schools = [
        for (final school in (data["Schools"] as List).whereType<Map>())
          CatalogSchool(
            school["Code"].toString(),
            school["Name"]?.toString() ?? school["Code"].toString(),
            school["Short"]?.toString() ?? school["Name"]?.toString() ?? school["Code"].toString(),
            {
              for (final MapEntry(:key, :value) in (school["Classes"] as Map).entries)
                if (int.tryParse(key.toString()) != null && value is List && value.isNotEmpty)
                  int.parse(key.toString()): [for (final name in value) name.toString()],
            },
          ),
      ].where((school) => school.classes.isNotEmpty).toList();
      if (schools.isEmpty) return null;
      final domains = data["Domains"];
      return ClassCatalog(
        year: data["Year"]?.toString(),
        schools: schools,
        domains: domains is Map ? {for (final MapEntry(:key, :value) in domains.entries) key.toString(): value.toString()} : const {},
      );
    } catch (e) {
      debugPrint("[Class] The catalog couldn't be read: $e");
      return null;
    }
  }

  CatalogSchool? schoolNamed(String code) {
    for (final school in schools) {
      if (school.code == code) return school;
    }
    return null;
  }

  /// The class of the catalog written like [value] whatever the case
  String? find(String value) {
    final lower = value.toLowerCase();
    for (final school in schools) {
      for (final names in school.classes.values) {
        for (final name in names) {
          if (name.toLowerCase() == lower) return name;
        }
      }
    }
    return null;
  }
}

/// A member of my class: what is needed to write to them (their public key) and to show who wrote what
class ClassMember {
  final String username;
  final String? displayName;
  final String? pictureUrl;
  final RSAPublicKey? publicKey;

  const ClassMember({required this.username, this.displayName, this.pictureUrl, this.publicKey});
}

/// The class chat's details shared by its members (GET /classes/mine): its picture and description, chosen by the
/// delegates, and the delegates themselves, elected by the class (each member votes for one delegate and one vice)
@immutable
class ClassGroup {
  final String className;
  final String? pictureUrl;
  final String? description;
  final String? delegate;
  final String? viceDelegate;

  /// Votes per role ([ClassService.delegateRole], [ClassService.viceRole]) and candidate
  final Map<String, Map<String, int>> votes;

  /// My vote per role
  final Map<String, String> myVotes;

  const ClassGroup({
    required this.className,
    this.pictureUrl,
    this.description,
    this.delegate,
    this.viceDelegate,
    this.votes = const {},
    this.myVotes = const {},
  });

  bool isDelegate(String? username) => username != null && (username == delegate || username == viceDelegate);

  int votesFor(String role, String username) => votes[role]?[username] ?? 0;

  static ClassGroup fromJson(String className, Map data) {
    Map<String, int> counts(Object? raw) =>
        raw is Map ? {for (final MapEntry(:key, :value) in raw.entries) key.toString(): (value is num ? value.toInt() : 0)} : const {};
    final votes = data["Votes"];
    final myVotes = data["MyVotes"];
    String? text(Object? value) => value is String && value.trim().isNotEmpty ? value : null;
    return ClassGroup(
      className: className,
      pictureUrl: text(data["PictureURL"]),
      description: text(data["Description"]),
      delegate: text(data["Delegate"]),
      viceDelegate: text(data["ViceDelegate"]),
      votes: votes is Map ? {for (final MapEntry(:key, :value) in votes.entries) key.toString(): counts(value)} : const {},
      myVotes: myVotes is Map ? {for (final MapEntry(:key, :value) in myVotes.entries) key.toString(): value.toString()} : const {},
    );
  }
}

/// The user's class and its chat. The class is chosen for a school year: when a new one starts the app asks again
/// (a class of last year is not the class of this year). The account keeps it on the server ("ClassOrRole", also
/// used by the shared assignments, and "ClassYear"); this device keeps a copy to know whether to ask.
class ClassService {
  static final ClassService _instance = ClassService._internal();
  factory ClassService() => _instance;
  ClassService._internal();

  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  static const _classKey = "MyClass";
  static const _yearKey = "MyClassYear";
  static const _postponedKey = "ClassPromptPostponedUntil";
  static const postponement = Duration(days: 1);

  /// The class whose chat I am in (null: none this school year)
  final current = ValueNotifier<SchoolClass?>(null);

  /// The members of my class (refreshed at every connection and before writing)
  final members = ValueNotifier<List<ClassMember>>(const []);
  DateTime? _membersLoadedAt;

  /// My class chat's picture, description and delegates (null until the server answered)
  final group = ValueNotifier<ClassGroup?>(null);

  static const delegateRole = "Delegate";
  static const viceRole = "Vice";

  /// Whether I can change my class's picture and description and every shared assignment
  bool get amDelegate => group.value?.isDelegate(globals.username) ?? false;

  // #region -> Chat identifiers

  /// A class chat is a Chat whose "username" is "#" and the class
  static String chatIdOf(String className) => "#$className";
  static bool isClassChat(String? chatId) => chatId != null && chatId.startsWith("#");
  static String? classOfChat(String chatId) => isClassChat(chatId) ? chatId.substring(1) : null;
  static String chatTitleOf(String className) => "Classe $className";

  // #endregion

  // #region -> Choosing

  /// What the account has (class or role) and the school year it was chosen for, as this device last saw them
  String? get savedValue => globals.persistent.getString(_classKey);
  String? get savedYear => globals.persistent.getString(_yearKey);

  /// Whether to ask the user for their class: they never chose, or chose a class for an earlier school year.
  /// A role ("Enseignant", "Externe"...) is never asked again.
  static bool needsAnswer(String? value, String? year, DateTime now) {
    final cleaned = value?.trim() ?? "";
    if (cleaned.isEmpty || cleaned == "-") return true;
    if (SchoolClass.tryParse(cleaned) != null || _isLegacyClass(cleaned)) return year != SchoolClass.yearLabel(now);
    return false;
  }

  /// Classes written before the picker existed ("2Cci1", "3Cts"...): still classes, so asked again every year
  static bool _isLegacyClass(String value) => RegExp(r'^[1-4](M|EC|C)[A-Za-z0-9]{1,8}$', caseSensitive: false).hasMatch(value);

  bool shouldAsk(DateTime now) {
    if (!needsAnswer(savedValue, savedYear, now)) return false;
    final postponedUntil = DateTime.tryParse(globals.persistent.getString(_postponedKey) ?? "");
    return postponedUntil == null || now.isAfter(postponedUntil);
  }

  static const _catalogKey = "ClassCatalog";

  /// The catalog to show in the picker: the server's (kept for next time), otherwise the last one received,
  /// otherwise the app's copy. Never fails: the app's copy is always there.
  Future<ClassCatalog> loadCatalog() async {
    try {
      final response = await network.get("/classes/catalog", timeout: 6);
      final received = response.statusCode == 200 ? ClassCatalog.tryParse(response.body) : null;
      if (received != null) {
        await globals.persistent.setString(_catalogKey, response.body);
        return ClassCatalog.current = received;
      }
      debugPrint("[Class] The server didn't send the catalog: ${response.statusCode}");
    } catch (e) {
      debugPrint("[Class] Reading the catalog failed: $e");
    }
    return ClassCatalog.current = ClassCatalog.tryParse(globals.persistent.getString(_catalogKey)) ?? await _bundledCatalog();
  }

  static Future<ClassCatalog> _bundledCatalog() async => ClassCatalog.tryParse(await rootBundle.loadString("assets/classes.json")) ?? ClassCatalog.empty;

  Future<void> postpone() => globals.persistent.setString(_postponedKey, DateTime.now().add(postponement).toIso8601String());

  /// Reads the account's class from the server (at the start: another device may have chosen it)
  Future<void> refresh() async {
    final username = globals.username;
    if (username == null) return;
    try {
      final response = await network.get("/accounts/get?username=${Uri.encodeQueryComponent(username)}", timeout: 8);
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data is! Map) return;
      await _save(data["ClassOrRole"]?.toString(), data["ClassYear"]?.toString());
    } catch (e) {
      debugPrint("[Class] Reading the class failed: $e");
    }
  }

  /// Chooses a class ([SchoolClass.name]) or [SchoolClass.outside]. Returns false when the server refused or
  /// couldn't be reached.
  /// Returns why it failed, in words (null when it worked)
  Future<String?> choose(String value) async {
    try {
      final response = await network.post("/classes/choose", {"Class": value, "Year": SchoolClass.yearLabel(DateTime.now())});
      if (response.statusCode != 200) return AppStrings.errorFor(response);
      final data = jsonDecode(response.body);
      await _save(value, data is Map ? data["Year"]?.toString() : SchoolClass.yearLabel(DateTime.now()));
      await globals.persistent.remove(_postponedKey);
      if (current.value != null) unawaited(loadMembers(force: true));
      return null;
    } catch (e) {
      debugPrint("[Class] Choosing the class failed: $e");
      return AppStrings.describe(e);
    }
  }

  Future<void> _save(String? value, String? year) async {
    value == null ? await globals.persistent.remove(_classKey) : await globals.persistent.setString(_classKey, value);
    year == null ? await globals.persistent.remove(_yearKey) : await globals.persistent.setString(_yearKey, year);
    _updateCurrent();
  }

  /// At the start, from this device's copy (before the server answers)
  void load() {
    ClassCatalog.current = ClassCatalog.tryParse(globals.persistent.getString(_catalogKey)) ?? ClassCatalog.current;
    _updateCurrent();
  }

  void _updateCurrent() {
    final schoolClass = SchoolClass.tryParse(savedValue);
    final isThisYear = savedYear == SchoolClass.yearLabel(DateTime.now());
    final next = schoolClass != null && isThisYear ? schoolClass : null;
    if (current.value != next) {
      current.value = next;
      members.value = const [];
      group.value = null;
      _membersLoadedAt = null;
    }
    if (next != null) unawaited(_ensureChat(next.name));
    unawaited(_removePastClassChats());
  }

  /// On 15 August the classes move up (last year's 1M05 is somebody else this year): the class chats of an earlier
  /// school year are removed from this phone, with their messages and files. The server removes its side too.
  Future<void> _removePastClassChats() async {
    const key = "ClassChatsYear";
    final year = SchoolClass.yearLabel(DateTime.now());
    final previous = globals.persistent.getString(key);
    if (previous == year) return;
    try {
      if (previous != null) {
        final now = DateTime.now();
        final yearStart = DateTime(now.month > 8 || (now.month == 8 && now.day >= 15) ? now.year : now.year - 1, 8, 15);
        final currentChat = current.value == null ? null : chatIdOf(current.value!.name);
        for (final chat in database.chats.getAll().where((chat) => isClassChat(chat.username)).toList()) {
          // The chat of this year's class may have the same name as last year's (a repeated year): only its old
          // messages go
          chat.username == currentChat ? await ChatService().deleteMessagesBefore(chat.username, yearStart) : await ChatService().deleteChat(chat);
        }
        debugPrint("[Class] New school year: last year's class chats were removed");
      }
      await globals.persistent.setString(key, year);
    } catch (e) {
      debugPrint("[Class] Removing last year's class chats failed: $e");
    }
  }

  /// The class chat is in the list as soon as the class is chosen, even before its first message
  Future<void> _ensureChat(String className) async {
    final id = chatIdOf(className);
    if (database.chats.getByUsername(id) != null) return;
    await database.chats.save(Chat.custom(username: id, displayUsername: chatTitleOf(className)));
  }

  /// Signing out: the next account chooses its own class
  Future<void> forget() async {
    await globals.persistent.remove(_classKey);
    await globals.persistent.remove(_yearKey);
    await globals.persistent.remove(_postponedKey);
    current.value = null;
    members.value = const [];
    group.value = null;
    _membersLoadedAt = null;
  }

  /// How many people chose each class this school year (null when the server can't be reached)
  Future<Map<String, int>?> counts() async {
    try {
      final response = await network.get("/classes/counts", timeout: 8);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final counts = data is Map ? data["Counts"] : null;
      if (counts is! Map) return null;
      return {for (final MapEntry(:key, :value) in counts.entries) key.toString(): (value as num).toInt()};
    } catch (e) {
      debugPrint("[Class] Reading the counts failed: $e");
      return null;
    }
  }

  // #endregion

  // #region -> Members

  /// The members of my class with their public keys. Kept a few minutes: a new member gets the messages written
  /// after the next refresh.
  Future<List<ClassMember>> loadMembers({bool force = false}) async {
    final loadedAt = _membersLoadedAt;
    if (!force && loadedAt != null && DateTime.now().difference(loadedAt) < const Duration(minutes: 5)) return members.value;
    if (current.value == null) return const [];

    try {
      final response = await network.get("/classes/mine", timeout: 15);
      if (response.statusCode == 204) {
        // The server says I have no class this year (chosen on another device, or a new school year)
        await refresh();
        return const [];
      }
      if (response.statusCode != 200) return members.value;

      final data = jsonDecode(response.body);
      final list = data is Map ? data["Members"] : null;
      if (list is! List) return members.value;

      members.value = [
        for (final item in list.whereType<Map>())
          ClassMember(
            username: item["Username"].toString(),
            displayName: item["DisplayName"]?.toString(),
            pictureUrl: item["ProfilePictureURL"]?.toString(),
            publicKey: _parseKey(item["PublicKey"]),
          ),
      ];
      group.value = ClassGroup.fromJson(data["Class"]?.toString() ?? current.value?.name ?? "", data as Map);
      _membersLoadedAt = DateTime.now();
    } catch (e) {
      debugPrint("[Class] Reading the members failed: $e");
    }
    return members.value;
  }

  static RSAPublicKey? _parseKey(Object? pem) {
    if (pem is! String || pem.trim().isEmpty) return null;
    try {
      return CryptoUtils.rsaPublicKeyFromPem(pem);
    } catch (_) {
      return null;
    }
  }

  // #region -> Group

  /// My vote for [role] ([delegateRole] or [viceRole]); a null [candidate] takes it back. Returns why it failed
  Future<String?> vote(String role, String? candidate) async {
    final response = await network.post("/classes/vote", {"Role": role, "Candidate": candidate});
    if (response.statusCode != 200) return AppStrings.errorFor(response);
    await loadMembers(force: true);
    return null;
  }

  /// The class chat's picture ([path] of a JPEG or PNG), or none. Only the delegates can. Returns why it failed
  Future<String?> setPicture(String? path) async {
    try {
      final request = http.MultipartRequest("POST", network.getBackendUri(route: "/classes/picture"))..headers["Authorization"] = globals.token ?? "";
      if (path == null) {
        request.fields["Remove"] = "true";
      } else {
        request.files.add(await http.MultipartFile.fromPath("Picture", path));
      }
      var response = await http.Response.fromStream(await request.send().timeout(const Duration(seconds: 60)));
      if (response.statusCode == 401 && (await network.refreshAccessToken()).statusCode == 200) return setPicture(path);
      if (response.statusCode == 403) return "Seuls le délégué et le vice-délégué de la classe peuvent changer sa photo.";
      if (response.statusCode != 200) return AppStrings.errorFor(response);
      await loadMembers(force: true);
      return null;
    } catch (e) {
      debugPrint("[Class] Changing the picture failed: $e");
      return AppStrings.describe(e);
    }
  }

  /// The few words under the class's name. Only the delegates can. Returns why it failed
  Future<String?> setDescription(String? description) async {
    final response = await network.post("/classes/description", {"Description": description});
    if (response.statusCode == 403) return "Seuls le délégué et le vice-délégué de la classe peuvent changer sa description.";
    if (response.statusCode != 200) return AppStrings.errorFor(response);
    await loadMembers(force: true);
    return null;
  }

  // #endregion

  /// The name to show for someone of the class
  String displayNameOf(String username) {
    for (final member in members.value) {
      if (member.username == username) return member.displayName?.trim().isNotEmpty == true ? member.displayName! : Account.getDefaultDisplayName(username);
    }
    return Account.getDefaultDisplayName(username);
  }

  // #endregion
}
