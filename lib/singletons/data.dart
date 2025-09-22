import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';

class Data {
  static final Data _instance = Data._internal();
  factory Data() => _instance;
  Data._internal();

  late final ConnectionController router = ConnectionController();

  // Main
  String? token;
  String? username;

  // Settings
  ValueNotifier<Brightness> appBrightnessNotifier = ValueNotifier(
    Brightness.light,
  );
  Brightness get appBrightness => appBrightnessNotifier.value;
  set appBrightness(Brightness value) => appBrightnessNotifier.value = value;

  // Chats
  bool isChatOpen = false;
  String? openChatUsername;
  String? fcmToken;

  // Accounts
  Map<String, ValueNotifier<String?>> pfpNotifiersCache = {};

  // Debug
  List<String> appLogs = [];

  void log(String? message) {
    final timestamp = DateTime.now();
    String? logEntry;

    try {
      logEntry =
          "[${timestamp.hour}:${timestamp.minute}:${timestamp.millisecond.toString().substring(0, 3)}] $message";
    } catch (_) {}

    appLogs.add(logEntry ?? message ?? "null");

    if (appLogs.length > 1000) {
      appLogs.removeAt(0);
    }
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
}
