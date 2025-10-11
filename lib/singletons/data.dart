import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/utility/classes.dart';

class Data {
  static final Data _instance = Data._internal();
  factory Data() => _instance;
  Data._internal();

  late final ConnectionController router = ConnectionController();
  late final Settings settings = Settings();

  // General app appearance
  ValueNotifier<Brightness> appBrightnessNotifier = ValueNotifier(Brightness.light);
  Brightness get appBrightness => appBrightnessNotifier.value;
  set appBrightness(Brightness value) => appBrightnessNotifier.value = value;

  // Main
  String? token;
  String? username;

  // School year
  final _now = DateTime.now();
  DateTime get schoolStart => DateTime(_now.year, 8, 18);
  DateTime get schoolEnd => _now.isBefore(schoolStart) ? DateTime(_now.year, 6, 6) : DateTime(_now.year + 1, 6, 6);

  // Chats
  bool isChatOpen = false;
  String? openChatUsername;
  String? fcmToken;

  // Accounts
  Map<String, ValueNotifier<String?>> pfpNotifiersCache = {};

  // Debug
  List<String> appLogs = [];

  void log(String? message) {
    try {
      final timestamp = DateTime.now();
      final logEntry = "[${timestamp.hour}:${timestamp.minute}:${timestamp.millisecond.toString().substring(0, 3)}] $message";

      appLogs.add(logEntry);

      if (appLogs.length > 1000) {
        appLogs.removeAt(0);
      }
    } catch (_) {}
  }

  ValueNotifier<String?> getPfpNotifier(String accountUsername) {
    // Getting the cached URL notifier
    var cachedURL = pfpNotifiersCache[accountUsername];
    if (cachedURL != null) {
      return cachedURL;
    }

    // Otherwise returns an empty one and asks the server to fill it
    pfpNotifiersCache[accountUsername] = ValueNotifier<String?>(null);
    router.getProfilePicture(accountUsername);
    return pfpNotifiersCache[accountUsername]!;
  }

  // Blocked users

  List<String>? _blockedUsers;

  List<String> get blockedUsers {
    if (_blockedUsers != null) return _blockedUsers!;
    return _blockedUsers = List<String>.from(Hive.box("Misc").get("BlockedUsers", defaultValue: <String>[]));
  }

  Future<void> _saveBlockedUsers() async => Hive.box("Misc").put("BlockedUsers", _blockedUsers);

  Future<void> blockUser(String id) async {
    if (blockedUsers.contains(id)) return;
    blockedUsers.add(id);
    await _saveBlockedUsers();
  }

  Future<void> unblockUser(String id) async {
    if (!blockedUsers.contains(id)) return;
    blockedUsers.remove(id);
    await _saveBlockedUsers();
  }
}
