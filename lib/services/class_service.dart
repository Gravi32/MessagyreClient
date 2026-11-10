import 'dart:async';
import 'dart:convert';

import 'package:basic_utils/basic_utils.dart' show CryptoUtils;
import 'package:flutter/foundation.dart';
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
/// the school ([schools]) and the [section]:
/// - École de maturité (3 years): "1M05", "3M10"; the bilingual classes (from the 2nd year) have a "b": "3Mb11".
/// - École de commerce (4 years, the 4th is the stage): "1EC1", "4EC1".
/// - École de culture générale (3 years): "1C3" in the 1st year; from the 2nd, the professional domain ([domains])
///   and a number when there are several classes: "2Cci1", "3Csa". Two small domains can share a class: "2Cadts"
///   (the domains in alphabetical order; the school also writes "2CTsAd").
///
/// The server checks the same rules (ClassesService.Normalize).
@immutable
class SchoolClass {
  final int year;
  final String school;

  /// What comes after the school: "05", "b11", "1", "ci1", "adts"
  final String section;

  const SchoolClass(this.year, this.school, this.section);

  static const schools = {"M": "École de maturité", "EC": "École de commerce", "C": "École de culture générale"};
  static const shortSchools = {"M": "Maturité", "EC": "Commerce", "C": "Culture g."};

  /// The professional domains of the école de culture générale, chosen at the end of the 1st year
  static const domains = {
    "ad": "Arts et design",
    "ci": "Communication et information",
    "mu": "Musique",
    "pe": "Pédagogie",
    "sa": "Santé",
    "ts": "Travail social",
  };

  static List<int> yearsOf(String school) => school == "EC" ? const [1, 2, 3, 4] : const [1, 2, 3];

  /// Every class of a year of a school, in the order of the picker's wheel
  static List<String> sectionsOf(int year, String school) {
    String twoDigits(int number) => number.toString().padLeft(2, "0");
    switch (school) {
      case "M":
        return [for (var number = 1; number <= 20; number++) twoDigits(number), if (year > 1) for (var number = 1; number <= 20; number++) "b${twoDigits(number)}"];
      case "EC":
        return [for (var number = 1; number <= 6; number++) "$number"];
      default:
        if (year == 1) return [for (var number = 1; number <= 8; number++) "$number"];
        final codes = domains.keys.toList();
        return [
          for (final domain in codes) ...[domain, for (var number = 1; number <= 3; number++) "$domain$number"],
          for (var first = 0; first < codes.length; first++)
            for (var second = first + 1; second < codes.length; second++) "${codes[first]}${codes[second]}",
        ];
    }
  }

  /// What someone who isn't at the Gymnase de Renens chooses (the value the accounts already had)
  static const outside = "Externe";

  static final _pattern = RegExp(r'^([1-4])(EC|M|C)([A-Za-z]*)(\d{0,2})$', caseSensitive: false);

  /// "1M05", "1m5", "3MB11", "2EC1", "2cci1", "2CTsAd" (→ "2Cadts")... Null for anything else ("Externe",
  /// "Enseignant", "4M01"...)
  static SchoolClass? tryParse(String? value) {
    final match = _pattern.firstMatch(value?.trim() ?? "");
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final school = match.group(2)!.toUpperCase();
    final letters = match.group(3)!.toLowerCase();
    final digits = match.group(4)!;
    final number = digits.isEmpty ? null : int.parse(digits);
    if (!yearsOf(school).contains(year)) return null;

    String? section;
    switch (school) {
      case "M":
        if ((letters == "" || (letters == "b" && year > 1)) && number != null) section = "$letters${number.toString().padLeft(2, "0")}";
      case "EC":
        if (letters == "" && number != null) section = "$number";
      default:
        if (year == 1) {
          if (letters == "" && number != null) section = "$number";
        } else if (letters.length == 2 || letters.length == 4) {
          final parts = [for (var index = 0; index < letters.length; index += 2) letters.substring(index, index + 2)]..sort();
          final isValid = parts.every(domains.containsKey) && parts.toSet().length == parts.length && (parts.length == 1 || number == null);
          if (isValid) section = "${parts.join()}${number ?? ""}";
        }
    }
    if (section == null || !sectionsOf(year, school).contains(section)) return null;
    return SchoolClass(year, school, section);
  }

  /// The class as the school (and the server) writes it
  String get name => "$year$school$section";

  String get yearName => year == 1 ? "1re année" : "${year}e année";

  /// "École de maturité, bilingue", "Communication et information", "Arts et design et Travail social"...
  String get description {
    if (school == "M" && section.startsWith("b")) return "École de maturité, bilingue";
    if (school == "C" && year > 1) {
      final letters = section.replaceAll(RegExp(r'\d'), "");
      return [for (var index = 0; index < letters.length; index += 2) domains[letters.substring(index, index + 2)]].join(" et ");
    }
    return schools[school]!;
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
  static bool _isLegacyClass(String value) => RegExp(r'^[1-4](M|EC|C)[A-Za-z0-9]{1,4}$').hasMatch(value);

  bool shouldAsk(DateTime now) {
    if (!needsAnswer(savedValue, savedYear, now)) return false;
    final postponedUntil = DateTime.tryParse(globals.persistent.getString(_postponedKey) ?? "");
    return postponedUntil == null || now.isAfter(postponedUntil);
  }

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
  void load() => _updateCurrent();

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
