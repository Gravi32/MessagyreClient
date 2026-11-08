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
    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await plugin.initialize(initSettings, onDidReceiveNotificationResponse: (response) => _onTapped(response.payload));

    // The app was started by tapping one of our notifications (Android's message notifications, assignments)
    try {
      final launch = await plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) _onTapped(launch!.notificationResponse?.payload);
    } catch (e) {
      debugPrint("[Notifications] Launch details unavailable: $e");
    }

    await FirebaseApi().initialize();

    sendTokenToServer();
  }

  void _onTapped(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      final data = tryJsonDecode(payload);
      // Older notifications had the username alone as payload
      final username = data is Map ? data["Username"] : (data == null ? payload : null);
      final url = data is Map ? data["Url"] : null;

      if (username is String && username.isNotEmpty) openChat(username);
      if (url is String) openUrl(url);
    }

    resetBadge();
  }

  /// Opens a conversation (from a notification): once the app's first page is there
  static void openChat(String username) {
    void push() => navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => ChatPage(username: username)));
    if (navigatorKey.currentState != null) return push();
    WidgetsBinding.instance.addPostFrameCallback((_) => push());
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
    try {
      if (await AppBadgePlus.isSupported()) await AppBadgePlus.updateBadge(0);
    } catch (e) {
      debugPrint("[Notifications] The badge couldn't be reset: $e");
    }
  }

  void sendTokenToServer() async {
    if (waitingForConnection) return;
    waitingForConnection = true;

    while (!network.isConnected) {
      await Future.delayed(const Duration(seconds: 1));
    }

    waitingForConnection = false;

    // Firebase may still be waiting for the token (iOS)
    for (var attempt = 0; attempt < 30 && globals.fcmToken == null; attempt++) {
      await Future.delayed(const Duration(seconds: 1));
    }

    final token = globals.fcmToken;
    if (token == null) return;

    await network.post("/accounts/me/upload-firebase-token", {"FirebaseToken": token});
  }
}
