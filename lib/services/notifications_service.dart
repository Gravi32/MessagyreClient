import 'dart:async';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:messagyre_client/services/notification_overlays_service.dart';

class NotificationsService {
  static final _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  void showInAppOverlay(String title, String sender, String body) {
    NotificationOverlaysService().spawn(title, sender, body);
  }

  Future<void> scheduleHomeworkNotification({required int id, required String title, required String body, required DateTime dueDate}) async {
    final scheduled = TZDateTime.from(dueDate.subtract(const Duration(days: 1)), local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails('homework_channel', 'Compiti', importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
