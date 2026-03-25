import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:messagyre_client/services/encryption_service.dart';
import 'package:messagyre_client/services/notification_overlays_service.dart';
import 'package:messagyre_client/services/notifications_service.dart';
import 'package:path_provider/path_provider.dart';

import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/globals_service.dart';

class FirebaseApi {
  static final _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  final firebaseMessaging = FirebaseMessaging.instance;
  final notifications = NotificationsService();
  final notificationOverlays = NotificationOverlaysService();
  final globals = GlobalsService();
  final encryption = EncryptionService();

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

    return;
  }

  void _onMessage(RemoteMessage message) async {
    final state = WidgetsBinding.instance.lifecycleState;
    final data = message.data;

    final title = data['Title'] ?? message.notification?.title ?? 'Notification';
    final body = data['Body'] ?? message.notification?.body ?? '';
    final sender = data['SenderUsername'];
    final cipherText = data['CipherText'];
    final iv = data['IV'];
    final encryptedKey = data['EncryptedKey'];

    final usingEncryption = cipherText != null && iv != null && encryptedKey != null;
    final messageBody = usingEncryption ? await encryption.decryptMessage(cipherText, iv, encryptedKey) : body;

    if (state == AppLifecycleState.resumed) {
      if (usingEncryption) notificationOverlays.spawn(title, messageBody, sender);
      notifications.resetBadge();
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    final username = message.data['SenderUsername'];
    if (username == null) return;

    navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => ChatPage(username: username)));
    notifications.resetBadge();
  }

  void _onTokenRefresh(String token) {
    globals.fcmToken = token;
    notifications.sendTokenToServer();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final data = message.data;
  final title = data['Title'] ?? message.notification?.title ?? 'Messagyre';
  final body = data['Body'] ?? message.notification?.body ?? '';
  final sender = data['SenderUsername'];
  final cipherText = data['CipherText'];
  final iv = data['IV'];
  final encryptedKey = data['EncryptedKey'];
  final imageUrl = data['ProfilePictureURL'];

  String finalBody = body;

  if (cipherText != null && iv != null && encryptedKey != null) {
    final encryption = EncryptionService();
    finalBody = await encryption.decryptMessage(cipherText, iv, encryptedKey);
  }

  final localNotifications = FlutterLocalNotificationsPlugin();

  NotificationDetails details;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    final response = await http.get(Uri.parse(imageUrl));
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/bg_notif_icon';
    await File(path).writeAsBytes(response.bodyBytes);

    final person = Person(name: title, icon: BitmapFilePathAndroidIcon(path));

    details = NotificationDetails(
      android: AndroidNotificationDetails(
        'messagyre_channel',
        'Messagyre',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: MessagingStyleInformation(person, messages: [Message(finalBody, DateTime.now(), person)]),
        largeIcon: FilePathAndroidBitmap(path),
      ),
    );
  } else {
    details = const NotificationDetails(
      android: AndroidNotificationDetails('messagyre_channel', 'Messagyre', importance: Importance.max, priority: Priority.high),
    );
  }

  await localNotifications.show(0, title, finalBody, details, payload: sender);
}
