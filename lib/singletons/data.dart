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

  // Accounts
  Map<String, ValueNotifier<String?>> pfpNotifiersCache = {};

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
