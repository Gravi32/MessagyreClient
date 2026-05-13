import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/secure_storage_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalsService {
  static final GlobalsService _instance = GlobalsService._internal();
  factory GlobalsService() => _instance;

  GlobalsService._internal();

  String? token;
  String? username;

  final secureStorage = SecureStorageService();
  late final network = NetworkService();

  late final SharedPreferences persistent;

  Future<void> initialize() async {
    persistent = await SharedPreferences.getInstance();
    appVersion = (await PackageInfo.fromPlatform()).version;
    return;
  }

  // #region -> Calendars

  final _now = DateTime.now();

  DateTime get schoolStart {
    // August 18th of the current or previous year
    final startYear = _now.month >= 8 ? _now.year : _now.year - 1;
    final result = DateTime(startYear, 8, 18);

    return result;
  }

  DateTime get schoolEnd {
    final start = schoolStart;
    return DateTime(start.year + 1, 6, 6);
  }

  Future<Calendar?> getTargetCalendar() async {
    final calendarsResult = await DeviceCalendarPlugin().retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null || calendarsResult.data!.isEmpty) return null;

    return calendarsResult.data!.firstWhere((c) => c.isDefault ?? false, orElse: () => calendarsResult.data!.first);
  }

  // #endregion

  // #region -> Chats

  String? openChatUsername;
  String? fcmToken;

  // #endregion

  // #region -> Profile pictures

  Map<String, ValueNotifier<String?>> pfpNotifiersCache = {};

  ValueNotifier<String?> getPfpNotifier(String accountUsername) {
    var cachedURL = pfpNotifiersCache[accountUsername];
    if (cachedURL != null) return cachedURL;
    pfpNotifiersCache[accountUsername] = ValueNotifier<String?>(null);
    network.getProfilePicture(accountUsername);
    return pfpNotifiersCache[accountUsername]!;
  }

  // #endregion

  // #region -> Debugging

  String appVersion = "Loading";
  List<String> appLogs = [];

  void log(String? message) {
    try {
      final timestamp = DateTime.now();
      final logEntry = "[${timestamp.hour}:${timestamp.minute}:${timestamp.millisecond.toString().padLeft(3, '0')}] $message";
      appLogs.add(logEntry);
      if (appLogs.length > 1000) appLogs.removeAt(0);
    } catch (_) {}
  }

  // #endregion

  // #region -> Blocked users

  List<String>? _blockedUsers;
  final ValueNotifier<List<String>> blockedUsersNotifier = ValueNotifier([]);

  List<String> get blockedUsers {
    if (_blockedUsers == null) {
      _blockedUsers = List<String>.from(persistent.getStringList("BlockedUsers") ?? []);
      blockedUsersNotifier.value = List<String>.from(_blockedUsers!);
    }
    return blockedUsersNotifier.value;
  }

  Future<void> _saveBlockedUsers() async {
    await persistent.setStringList("BlockedUsers", blockedUsersNotifier.value);
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

  // #endregion
}
