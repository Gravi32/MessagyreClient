import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/secure_storage_service.dart';
import 'package:messagyre_client/utility/school_calendar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalsService {
  static final GlobalsService _instance = GlobalsService._internal();
  factory GlobalsService() => _instance;

  GlobalsService._internal();

  String? token;
  // Kept in memory too: the session never depends on reading the keychain back (it can be slow or refuse on iOS)
  String? refreshToken;
  String? username;

  final secureStorage = SecureStorageService();
  late final network = NetworkService();

  late final SharedPreferences persistent;

  Future<void> initialize() async {
    persistent = await SharedPreferences.getInstance();
    // Loaded here, not on first read: reading it while a page builds must not notify the listeners
    blockedUsersNotifier.value = List<String>.from(persistent.getStringList("BlockedUsers") ?? []);
    appVersion = (await PackageInfo.fromPlatform()).version;
    return;
  }

  // #region -> Calendars

  /// First day of the current school year (Vaud calendar)
  DateTime get schoolStart => SchoolCalendar.yearStart(SchoolCalendar.startYearOf(DateTime.now()));

  /// Last day of the current school year (used to be a fixed 6 June: later dates couldn't be picked)
  DateTime get schoolEnd => SchoolCalendar.yearEnd(SchoolCalendar.startYearOf(DateTime.now()) + 1);

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

  final ValueNotifier<List<String>> blockedUsersNotifier = ValueNotifier([]);

  List<String> get blockedUsers => blockedUsersNotifier.value;

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
