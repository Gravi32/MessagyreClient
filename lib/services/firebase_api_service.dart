import 'dart:io';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:messagyre_client/services/notifications_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';

class FirebaseApi {
  static final _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  final globals = GlobalsService();
  final network = NetworkService();
  final firebaseMessaging = FirebaseMessaging.instance;
  final localNotifications = FlutterLocalNotificationsPlugin();
  bool waitingForConnection = false;
  int badgeCount = 0;

  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 2));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final username = response.payload;
        if (username != null && username.isNotEmpty) {
          navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => ChatPage(recipientUsername: username)));
        }
        resetBadge();
      },
    );

    final settings = await firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await firebaseMessaging.setAutoInitEnabled(true);

      if (Platform.isIOS) {
        String? apnsToken;
        while (apnsToken == null) {
          apnsToken = await firebaseMessaging.getAPNSToken();

          if (apnsToken == null) {
            debugPrint("[Firebase] No APNs token retrieved. Retrying in 3 seconds...");
          }

          await Future.delayed(Duration(seconds: 3));
        }
      }

      globals.fcmToken = await firebaseMessaging.getToken();
      sendTokenToServer();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final state = WidgetsBinding.instance.lifecycleState;

        debugPrint("[Firebase] Notification received: ${message.data}");

        try {
          final dataMap = message.data;
          final title = dataMap['Title'] ?? message.notification?.title ?? 'Notification';
          final body = dataMap['Body'] ?? message.notification?.body ?? '';
          final imageUrl = dataMap['ProfilePictureURL'] as String?;
          final senderUsername = dataMap['SenderUsername'] ?? title;
          if (state == AppLifecycleState.resumed) {
            NotificationsService().spawn(title, senderUsername, body);
            resetBadge();
          } else {
            await _showNotification(title, body, imageUrl, senderUsername);
            incrementBadge();
          }
        } catch (e) {
          debugPrint("[Firebase] Error parsing notification data: $e");
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final username = message.data['SenderUsername'];
        if (username == null) return;
        navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => ChatPage(recipientUsername: username)));
        resetBadge();
      });

      firebaseMessaging.onTokenRefresh.listen((newToken) {
        globals.fcmToken = newToken;
        sendTokenToServer();
      });
    } else {
      debugPrint("[Firebase] Notification permission denied.");
    }
  }

  Future<void> _showNotification(String title, String body, String? imageUrl, String? payload) async {
    NotificationDetails notificationDetails;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final imagePath = await _downloadAndSaveFile(imageUrl, 'notif_icon');
      final largeIcon = FilePathAndroidBitmap(imagePath);

      final sender = Person(name: title, icon: BitmapFilePathAndroidIcon(imagePath));
      final messageStyle = MessagingStyleInformation(sender, messages: [Message(body, DateTime.now(), sender)]);

      final androidDetails = AndroidNotificationDetails(
        'messagyre_channel',
        'Messagyre',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: messageStyle,
        largeIcon: largeIcon,
      );

      notificationDetails = NotificationDetails(android: androidDetails);
    } else {
      final androidDetails = AndroidNotificationDetails('messagyre_channel', 'Messagyre', importance: Importance.max, priority: Priority.high);

      notificationDetails = NotificationDetails(android: androidDetails);
    }

    await localNotifications.show(0, title, body, notificationDetails, payload: payload);
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';
    final bytes = (await http.get(Uri.parse(url))).bodyBytes;
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  void sendTokenToServer() async {
    if (waitingForConnection) return;

    waitingForConnection = true;
    while (network.isConnected == false) {
      await Future.delayed(const Duration(seconds: 1));
    }
    waitingForConnection = false;

    final token = globals.fcmToken;
    if (token == null) return;

    final response = await network.post("/accounts/me/upload-firebase-token", {"FirebaseToken": token});

    if (response.statusCode == 200) {
      debugPrint("[Firebase] FCM token successfully uploaded.");
    } else {
      debugPrint(
        "[Firebase] Token upload failed. Code: ${response.statusCode}, body: ${response.body}. Username: ${globals.username}, token: ${globals.token}",
      );
    }
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
