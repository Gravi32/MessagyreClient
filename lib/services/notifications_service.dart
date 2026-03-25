import 'dart:async';
import 'dart:io';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/api/firebase_api.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:path_provider/path_provider.dart';

class NotificationsService {
  static final _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final plugin = FlutterLocalNotificationsPlugin();
  final network = NetworkService();
  final globals = GlobalsService();

  bool waitingForConnection = false;

  Future<List<PendingNotificationRequest>> get getScheduledNotifications async => await plugin.pendingNotificationRequests();
  Future<bool> isNotificationScheduled(int id) async => (await getScheduledNotifications).any((n) => n.id == id);

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final String? payload = response.payload;

        if (payload != null && payload.isNotEmpty) {
          final Map<String, dynamic>? data = tryJsonDecode(payload);

          final username = data?["Username"];
          final url = data?["Url"];

          if (username != null) navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => ChatPage(username: username)));
          if (url != null) openUrl(url);
        }

        resetBadge();
      },
    );

    await FirebaseApi().initialize();

    sendTokenToServer();
  }

  Future<String> getImageFilePath(String assetName) async {
    final byteData = await rootBundle.load('assets/$assetName');
    final file = File('${(await getTemporaryDirectory()).path}/$assetName');

    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file.path;
  }

  Future<void> scheduleAssignmentNotification({
    required int notificationId,
    required String title,
    required String subtitle,
    required String body,
    required DateTime dueDate,
  }) async {
    try {
      final imagePath = await getImageFilePath('broadcast.png');
      final scheduled = TZDateTime.from(dueDate, local);

      if (await isNotificationScheduled(notificationId)) await cancel(notificationId); // Cancel existing notification if already scheduled

      await plugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'homework_channel',
            'Devoirs',
            subText: subtitle,
            importance: Importance.high,
            priority: Priority.high,
            largeIcon: const DrawableResourceAndroidBitmap('broadcast'), // Android reads from the native drawables (android/app/src/main/res/drawable)
          ),
          iOS: DarwinNotificationDetails(subtitle: subtitle, attachments: [DarwinNotificationAttachment(imagePath)]), // iOS reads the extracted file's path
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, s) {
      debugPrint("An error occurred while scheduling a notification: $e | $s");
    }
  }

  Future<void> cancel(int id) async {
    await plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }

  Future<void> resetBadge() async {
    if (await AppBadgePlus.isSupported()) AppBadgePlus.updateBadge(0);
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
}
