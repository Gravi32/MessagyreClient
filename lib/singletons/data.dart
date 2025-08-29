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

  // Connection
  ValueNotifier<bool> isConnecting = ValueNotifier(false);
  ValueNotifier<bool> isConnected = ValueNotifier(false);
  ValueNotifier<DateTime?> lastRequestTimestamp = ValueNotifier(null);

  // Settings
  ValueNotifier<Brightness> appBrightnessNotifier = ValueNotifier(
    Brightness.light,
  );
  Brightness get appBrightness => appBrightnessNotifier.value;
  set appBrightness(Brightness value) => appBrightnessNotifier.value = value;

  // Chats
  bool isChatOpen = false;

  // Accounts
  Map<String, ValueNotifier<String?>> pfpNotifiersCache = {};

  // Debug
  List<String> appLogs = [];

  void log(String? message) {
    final timestamp = DateTime.now();
    final logEntry =
        "[${timestamp.hour}:${timestamp.minute}:${timestamp.millisecond.toString().substring(0, 3)}] $message";

    appLogs.add(logEntry);

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
