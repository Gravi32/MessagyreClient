import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/utility/classes.dart';

class Data {
  static final Data _instance = Data._internal();
  factory Data() => _instance;

  Data._internal() {
    loadSettings();
  }

  late final ConnectionController router = ConnectionController();
  Settings settings = Settings();

  // Settings
  void loadSettings() async {
    final box = Hive.box<Settings>("Settings");

    settings = box.get("Settings", defaultValue: settings) ?? settings;

    if (settings.isInBox == false) {
      box.put("Settings", settings);
    }
  }

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

  // Calendar
  Future<Calendar?> getTargetCalendar() async {
    final calendarsResult = await DeviceCalendarPlugin().retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) return null;

    return calendarsResult.data!.firstWhere((c) => c.isDefault ?? false, orElse: () => calendarsResult.data!.first);
  }

  // Chats
  String? openChatUsername;
  String? fcmToken;

  // Accounts
  Map<String, ValueNotifier<String?>> pfpNotifiersCache = {};

  // Debug
  List<String> appLogs = [];

  void log(String? message) {
    try {
      final timestamp = DateTime.now();
      final logEntry = "[${timestamp.hour}:${timestamp.minute}:${timestamp.millisecond.toString().padLeft(3, '0')}] $message";
      appLogs.add(logEntry);
      if (appLogs.length > 1000) appLogs.removeAt(0);
    } catch (_) {}
  }

  ValueNotifier<String?> getPfpNotifier(String accountUsername) {
    var cachedURL = pfpNotifiersCache[accountUsername];
    if (cachedURL != null) return cachedURL;
    pfpNotifiersCache[accountUsername] = ValueNotifier<String?>(null);
    router.getProfilePicture(accountUsername);
    return pfpNotifiersCache[accountUsername]!;
  }

  // Blocked users
  List<String>? _blockedUsers;
  final ValueNotifier<List<String>> blockedUsersNotifier = ValueNotifier([]);

  List<String> get blockedUsers {
    if (_blockedUsers == null) {
      _blockedUsers = List<String>.from(Hive.box("Misc").get("BlockedUsers", defaultValue: <String>[]));
      blockedUsersNotifier.value = List<String>.from(_blockedUsers!);
    }
    return blockedUsersNotifier.value;
  }

  Future<void> _saveBlockedUsers() async {
    await Hive.box("Misc").put("BlockedUsers", blockedUsersNotifier.value);
  }

  Future<void> blockUser(String id) async {
    if (blockedUsers.contains(id)) return;
    blockedUsersNotifier.value = [...blockedUsers, id];
    await _saveBlockedUsers();
  }

  Future<void> unblockUser(String id) async {
    if (!blockedUsers.contains(id)) return;
    blockedUsersNotifier.value = blockedUsers.where((u) => u != id).toList();
    await _saveBlockedUsers();
  }
}
