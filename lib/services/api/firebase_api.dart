import 'dart:io';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:messagyre_client/services/encryption_service.dart';
import 'package:messagyre_client/services/notification_overlays_service.dart';
import 'package:path_provider/path_provider.dart';

import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';

class FirebaseApi {
  static final _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  final firebaseMessaging = FirebaseMessaging.instance;
  final localNotifications = FlutterLocalNotificationsPlugin();
  final notificationOverlays = NotificationOverlaysService();
  final globals = GlobalsService();
  final network = NetworkService();
  final encryption = EncryptionService();

  bool waitingForConnection = false;
  int badgeCount = 0;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final username = response.payload;
        if (username != null && username.isNotEmpty) {
          navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => ChatPage(username: username)));
        }
        resetBadge();
      },
    );

    final settings = await firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return;
    }

    if (Platform.isIOS) {
      String? apnsToken;
      while (apnsToken == null) {
        apnsToken = await firebaseMessaging.getAPNSToken();
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    globals.fcmToken = await firebaseMessaging.getToken();
    sendTokenToServer();

    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  void _onMessage(RemoteMessage message) async {
    final state = WidgetsBinding.instance.lifecycleState;
    final data = message.data;

    final title = data['Title'] ?? message.notification?.title ?? 'Notification';
    final body = data['Body'] ?? message.notification?.body ?? '';
    final imageUrl = data['ProfilePictureURL'];
    final sender = data['SenderUsername'];
    final cipherText = data['CipherText'];
    final iv = data['IV'];
    final encryptedKey = data['EncryptedKey'];

    final usingEncryption = cipherText != null && iv != null && encryptedKey != null;
    final messageBody = usingEncryption ? encryption.decryptMessage(cipherText, iv, encryptedKey) : body;

    if (state == AppLifecycleState.resumed) {
      if (usingEncryption) notificationOverlays.spawn(title, messageBody, sender);
      resetBadge();
    } else {
      await _showSystemNotification(title, messageBody, imageUrl, sender);
      incrementBadge();
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    final username = message.data['SenderUsername'];
    if (username == null) return;

    navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => ChatPage(username: username)));
    resetBadge();
  }

  void _onTokenRefresh(String token) {
    globals.fcmToken = token;
    sendTokenToServer();
  }

  Future<void> _showSystemNotification(String title, String body, String? imageUrl, String? payload) async {
    NotificationDetails details;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final imagePath = await _downloadAndSaveFile(imageUrl, 'notif_icon');
      final sender = Person(name: title, icon: BitmapFilePathAndroidIcon(imagePath));

      details = NotificationDetails(
        android: AndroidNotificationDetails(
          'messagyre_channel',
          'Messagyre',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: MessagingStyleInformation(sender, messages: [Message(body, DateTime.now(), sender)]),
          largeIcon: FilePathAndroidBitmap(imagePath),
        ),
      );
    } else {
      details = const NotificationDetails(
        android: AndroidNotificationDetails('messagyre_channel', 'Messagyre', importance: Importance.max, priority: Priority.high),
      );
    }

    await localNotifications.show(0, title, body, details, payload: payload);
  }

  Future<String> _downloadAndSaveFile(String url, String name) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$name';
    final bytes = (await http.get(Uri.parse(url))).bodyBytes;
    await File(path).writeAsBytes(bytes);
    return path;
  }

  void sendTokenToServer() async {
    if (waitingForConnection) return;
    waitingForConnection = true;

    while (!network.isConnected) {
      await Future.delayed(const Duration(seconds: 1));
    }

    waitingForConnection = false;

    final token = globals.fcmToken;
    if (token == null) return;

    await network.post("/accounts/me/upload-firebase-token", {"FirebaseToken": token});
  }

  void incrementBadge() {
    badgeCount++;
    AppBadgePlus.updateBadge(badgeCount);
  }

  void resetBadge() {
    badgeCount = 0;
    AppBadgePlus.updateBadge(0);
  }
}
