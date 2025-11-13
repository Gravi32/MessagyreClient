import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:messagyre_client/singletons/notifications_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';

class FirebaseApi {
  static final _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  final data = Data();
  final router = ConnectionController();
  final firebaseMessaging = FirebaseMessaging.instance;
  final localNotifications = FlutterLocalNotificationsPlugin();
  bool waitingForConnection = false;

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
          navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => ChatOverlay(recipientUsername: username)));
        }
      },
    );

    final settings = await firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await firebaseMessaging.setAutoInitEnabled(true);

      if (Platform.isIOS) {
        final apnsToken = await firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint("[Firebase] No APNs token retrieved.");
        } else {
          debugPrint("[Firebase] APNs token: $apnsToken");
        }
      }

      data.fcmToken = await firebaseMessaging.getToken();
      debugPrint("[Firebase] FCM token: ${data.fcmToken}");
      sendTokenToServer();

      // Gestione notifiche in foreground
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
            NotificationController().spawn(senderUsername, body);
          } else {
            await _showNotification(title, body, imageUrl, senderUsername);
          }
        } catch (e) {
          debugPrint("[Firebase] Error parsing notification data: $e");
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final username = message.data['SenderUsername'];
        if (username == null) return;
        navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => ChatOverlay(recipientUsername: username)));
      });

      firebaseMessaging.onTokenRefresh.listen((newToken) {
        data.fcmToken = newToken;
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
    while (router.isConnected == false) {
      await Future.delayed(const Duration(seconds: 1));
    }
    waitingForConnection = false;

    final token = data.fcmToken;
    if (token == null) return;

    debugPrint("[Firebase] Uploading the FCM token...");

    final response = await router.post("/Accounts/Me/UploadFirebaseToken", {"FirebaseToken": token});

    if (response.statusCode == 200) {
      debugPrint("[Firebase] Token sent successfully.");
    } else {
      debugPrint("[Firebase] Token upload failed. Code: ${response.statusCode}, body: ${response.body}. Username: ${data.username}, token: ${data.token}");
    }
  }
}
