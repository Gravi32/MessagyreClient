import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:messagyre_client/utility/classes.dart';

class Data {
  static final _instance = Data._singleton();

  // Singleton
  factory Data() {
    if (!Hive.isBoxOpen("Chats")) Hive.openBox("Chats");
    return _instance;
  }
  Data._singleton();

  // Settings
  Account? account;

  ValueNotifier<Brightness> appBrightnessNotifier = ValueNotifier(
    Brightness.light,
  );
  Brightness get appBrightness => appBrightnessNotifier.value;
  set appBrightness(Brightness value) => appBrightnessNotifier.value = value;

  // Chats
  bool isChatOpen = false;
}
