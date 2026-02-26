import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalsService {
  static final GlobalsService _instance = GlobalsService._internal();
  factory GlobalsService() => _instance;

  GlobalsService._internal() {
    SharedPreferences.getInstance().then((instance) => persistent = instance);
  }

  String? token;
  String? username;

  final secureStorage = FlutterSecureStorage();
  late final network = NetworkService();

  // #region -> Settings
  late final SharedPreferences persistent;

  // #endregion

  // #region -> App brightness

  ValueNotifier<Brightness> appBrightnessNotifier = ValueNotifier(Brightness.light);
  Brightness get appBrightness => appBrightnessNotifier.value;
  set appBrightness(Brightness value) => appBrightnessNotifier.value = value;

  // #endregion

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

  // #region -> Encryption

  AsymmetricKeyPair? _keyPairCache;

  Future<RSAPublicKey> get publicKey async {
    if (_keyPairCache?.publicKey != null) {
      return _keyPairCache!.publicKey as RSAPublicKey;
    }

    final storedPublic = await secureStorage.read(key: "RSAPublicKey");
    final storedPrivate = await secureStorage.read(key: "RSAPrivateKey");

    if (storedPublic != null && storedPublic.isNotEmpty && storedPrivate != null && storedPrivate.isNotEmpty) {
      final newPublicKey = CryptoUtils.rsaPublicKeyFromPem(storedPublic);
      final newPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(storedPrivate);
      _keyPairCache = AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(newPublicKey, newPrivateKey);
      return newPublicKey;
    }

    return _generateRSAKeyPair().publicKey as RSAPublicKey;
  }

  Future<RSAPrivateKey> get privateKey async {
    if (_keyPairCache?.privateKey != null) {
      return _keyPairCache!.privateKey as RSAPrivateKey;
    }

    final storedPublic = await secureStorage.read(key: "RSAPublicKey");
    final storedPrivate = await secureStorage.read(key: "RSAPrivateKey");

    if (storedPublic != null && storedPublic.isNotEmpty && storedPrivate != null && storedPrivate.isNotEmpty) {
      final newPublicKey = CryptoUtils.rsaPublicKeyFromPem(storedPublic);
      final newPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(storedPrivate);
      _keyPairCache = AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(newPublicKey, newPrivateKey);
      return newPrivateKey;
    }

    return _generateRSAKeyPair().privateKey as RSAPrivateKey;
  }

  AsymmetricKeyPair _generateRSAKeyPair({int bitLength = 2048}) {
    debugPrint("[RSA] Generating new RSA key pair...");

    final keyGenerator =
        RSAKeyGenerator()..init(
          ParametersWithRandom(
            RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
            SecureRandom("Fortuna")..seed(KeyParameter(Uint8List.fromList(List<int>.generate(32, (_) => Random.secure().nextInt(256))))),
          ),
        );

    final pair = keyGenerator.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;
    final result = AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);

    _keyPairCache = result;

    final publicPem = CryptoUtils.encodeRSAPublicKeyToPem(publicKey);
    final privatePem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);

    secureStorage.write(key: "RSAPublicKey", value: publicPem);
    secureStorage.write(key: "RSAPrivateKey", value: privatePem);

    debugPrint("[RSA] New key pair generated and saved");
    network.uploadPublicKey();

    return result;
  }

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
