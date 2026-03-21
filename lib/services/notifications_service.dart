import 'dart:async';
import 'dart:io';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

class NotificationsService {
  static final _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final plugin = FlutterLocalNotificationsPlugin();

  Future<List<PendingNotificationRequest>> get getScheduledNotifications async => await plugin.pendingNotificationRequests();
  Future<bool> isNotificationScheduled(int id) async => (await getScheduledNotifications).any((n) => n.id == id);

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await plugin.initialize(const InitializationSettings(android: android, iOS: ios));
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
            importance: Importance.high,
            priority: Priority.high,
            largeIcon: const DrawableResourceAndroidBitmap('broadcast'), // Android reads from the native drawables (android/app/src/main/res/drawable)
          ),
          iOS: DarwinNotificationDetails(attachments: [DarwinNotificationAttachment(imagePath)]), // iOS reads the extracted file's path
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
}
