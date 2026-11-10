import 'dart:async';
import 'dart:convert';

import 'package:basic_utils/basic_utils.dart' show CryptoUtils;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:pointycastle/export.dart' show RSAPublicKey;

/// A member of a group chat
@immutable
class GroupMember {
  final String username;
  final String? displayName;
  final String? pictureUrl;
  final String? publicKeyPem;
  final bool isAdmin;

  const GroupMember({required this.username, this.displayName, this.pictureUrl, this.publicKeyPem, this.isAdmin = false});

  String get name => displayName?.trim().isNotEmpty == true ? displayName! : Account.getDefaultDisplayName(username);

  static GroupMember fromJson(Map data) => GroupMember(
    username: data["Username"].toString(),
    displayName: data["DisplayName"]?.toString(),
    pictureUrl: data["ProfilePictureURL"]?.toString(),
    publicKeyPem: data["PublicKey"]?.toString(),
    isAdmin: data["IsAdmin"] == true,
  );

  Map<String, dynamic> toJson() => {
    "Username": username,
    "DisplayName": displayName,
    "ProfilePictureURL": pictureUrl,
    "PublicKey": publicKeyPem,
    "IsAdmin": isAdmin,
  };
}

/// A group chat chosen by its members (apps from 4.109): a name, a picture, a description, admins. Its messages
/// travel like a class chat's (encrypted once, the key encrypted for each member).
@immutable
class ChatGroup {
  final String id;
  final String name;
  final String? pictureUrl;
  final String? description;
  final String? createdBy;
  final List<GroupMember> members;

  const ChatGroup({required this.id, required this.name, this.pictureUrl, this.description, this.createdBy, this.members = const []});

  String get chatId => GroupService.chatIdOf(id);

  GroupMember? memberNamed(String? username) {
    for (final member in members) {
      if (member.username == username) return member;
    }
    return null;
  }

  bool isAdmin(String? username) => memberNamed(username)?.isAdmin ?? false;

  static ChatGroup? fromJson(Object? data) {
    if (data is! Map || data["ID"] == null) return null;
    String? text(Object? value) => value is String && value.trim().isNotEmpty ? value : null;
    return ChatGroup(
      id: data["ID"].toString(),
      name: data["Name"]?.toString() ?? "Groupe",
      pictureUrl: text(data["PictureURL"]),
      description: text(data["Description"]),
      createdBy: text(data["CreatedBy"]),
      members: [for (final member in (data["Members"] as List? ?? const []).whereType<Map>()) GroupMember.fromJson(member)],
    );
  }

  Map<String, dynamic> toJson() => {
    "ID": id,
    "Name": name,
    "PictureURL": pictureUrl,
    "Description": description,
    "CreatedBy": createdBy,
    "Members": [for (final member in members) member.toJson()],
  };
}

/// The answer to creating a group or adding members: who couldn't be added (their app is too old to know groups)
typedef GroupChangeResult = ({ChatGroup? group, String? error, List<String> tooOld});

/// My group chats: read from the server at every connection and when a member changes them ("GroupChanged"), kept on
/// the phone to show them without connection. A chat whose group I left stays readable but can't be written in.
class GroupService {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  static const _storageKey = "ChatGroups";

  /// My groups by ID
  final groups = ValueNotifier<Map<String, ChatGroup>>(const {});

  // #region -> Identifiers

  /// A group's chat is "#" and its ID ("#g-k3h9x2m1qa"), like a class chat ("#1M05")
  static String chatIdOf(String groupId) => "#$groupId";
  static bool isGroupChat(String? chatId) => chatId != null && chatId.startsWith("#g-");
  static String? groupOfChat(String? chatId) => isGroupChat(chatId) ? chatId!.substring(1) : null;

  ChatGroup? groupOfChatId(String? chatId) => groups.value[groupOfChat(chatId)];

  // #endregion

  /// At the start, from the phone's copy
  void load() {
    try {
      final data = jsonDecode(globals.persistent.getString(_storageKey) ?? "[]");
      groups.value = {for (final group in (data as List).map(ChatGroup.fromJson).whereType<ChatGroup>()) group.id: group};
    } catch (e) {
      debugPrint("[Groups] The saved groups couldn't be read: $e");
    }
  }

  Future<void> _store(Map<String, ChatGroup> next) async {
    groups.value = next;
    await globals.persistent.setString(_storageKey, jsonEncode([for (final group in next.values) group.toJson()]));
    // Every group has its conversation in the list, with its name
    for (final group in next.values) {
      final chat = database.chats.getByUsername(group.chatId);
      if (chat == null) {
        await database.chats.save(Chat.custom(username: group.chatId, displayUsername: group.name));
      } else if (chat.displayUsername != group.name) {
        chat.displayUsername = group.name;
        await database.chats.save(chat);
      }
    }
  }

  /// Reads my groups from the server
  Future<void> refresh() async {
    if (globals.username == null) return;
    try {
      final response = await network.get("/groups/mine", timeout: 15);
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      final list = data is Map ? data["Groups"] : null;
      if (list is! List) return;
      await _store({for (final group in list.map(ChatGroup.fromJson).whereType<ChatGroup>()) group.id: group});
    } catch (e) {
      debugPrint("[Groups] Reading the groups failed: $e");
    }
  }

  /// The server says a group changed (members, name, picture): read again
  Future<void> handleCommunication(Map<String, dynamic> data) => refresh();

  void _replace(ChatGroup group) => unawaited(_store({...groups.value, group.id: group}));

  /// The members to encrypt a message for (from the last reading: refreshed at every connection and change)
  Map<String, RSAPublicKey> keysOf(String groupId) {
    final keys = <String, RSAPublicKey>{};
    for (final member in groups.value[groupId]?.members ?? const <GroupMember>[]) {
      if (member.username == globals.username || member.publicKeyPem == null) continue;
      try {
        keys[member.username] = CryptoUtils.rsaPublicKeyFromPem(member.publicKeyPem!);
      } catch (_) {}
    }
    return keys;
  }

  String displayNameOf(String chatId, String username) =>
      groupOfChatId(chatId)?.memberNamed(username)?.name ?? Account.getDefaultDisplayName(username);

  // #region -> Changes

  static String _errorOf(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data["Error"] is String) return data["Error"];
    } catch (_) {}
    return AppStrings.errorFor(response);
  }

  Future<GroupChangeResult> _change(String route, Map<String, dynamic> body) async {
    try {
      final response = await network.post(route, body);
      if (response.statusCode != 200) return (group: null, error: _errorOf(response), tooOld: const <String>[]);
      final data = jsonDecode(response.body);
      final group = ChatGroup.fromJson(data is Map ? data["Group"] : null);
      if (group != null) _replace(group);
      final tooOld = data is Map && data["TooOld"] is List ? [for (final name in data["TooOld"]) name.toString()] : const <String>[];
      return (group: group, error: null, tooOld: tooOld);
    } catch (e) {
      return (group: null, error: AppStrings.describe(e), tooOld: const <String>[]);
    }
  }

  Future<GroupChangeResult> create(String name, List<String> members) => _change("/groups/create", {"Name": name, "Members": members});

  Future<GroupChangeResult> addMembers(String groupId, List<String> members) => _change("/groups/members/add", {"Group": groupId, "Members": members});

  Future<GroupChangeResult> setAdmin(String groupId, String username, bool isAdmin) =>
      _change("/groups/admin", {"Group": groupId, "Username": username, "IsAdmin": isAdmin});

  Future<GroupChangeResult> rename(String groupId, String name) => _change("/groups/edit", {"Group": groupId, "Name": name});

  Future<GroupChangeResult> describe(String groupId, String? description) => _change("/groups/edit", {"Group": groupId, "Description": description ?? ""});

  /// Removes [username] (an admin), or leaves the group (my own username). Returns why it failed
  Future<String?> removeMember(String groupId, String username) async {
    try {
      final response = await network.post("/groups/members/remove", {"Group": groupId, "Username": username});
      if (response.statusCode != 200) return _errorOf(response);
      await refresh();
      return null;
    } catch (e) {
      return AppStrings.describe(e);
    }
  }

  /// The group's picture ([path] of a JPEG or PNG), or none. Only admins. Returns why it failed
  Future<String?> setPicture(String groupId, String? path) async {
    try {
      final request = http.MultipartRequest("POST", network.getBackendUri(route: "/groups/picture"))
        ..headers["Authorization"] = globals.token ?? ""
        ..fields["Group"] = groupId;
      if (path == null) {
        request.fields["Remove"] = "true";
      } else {
        request.files.add(await http.MultipartFile.fromPath("Picture", path));
      }
      final response = await http.Response.fromStream(await request.send().timeout(const Duration(seconds: 60)));
      if (response.statusCode == 401 && (await network.refreshAccessToken()).statusCode == 200) return setPicture(groupId, path);
      if (response.statusCode != 200) return _errorOf(response);
      final data = jsonDecode(response.body);
      final group = ChatGroup.fromJson(data is Map ? data["Group"] : null);
      if (group != null) _replace(group);
      return null;
    } catch (e) {
      debugPrint("[Groups] Changing the picture failed: $e");
      return AppStrings.describe(e);
    }
  }

  // #endregion

  /// Signing out: the next account has its own groups
  Future<void> forget() async {
    groups.value = const {};
    await globals.persistent.remove(_storageKey);
  }
}
