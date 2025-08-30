
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();

    final token = await getDeviceToken();
    debugPrint("[Firebase] Device token: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("[Firebase] Message received: ${message.messageId}");
      if (message.notification != null) {
        debugPrint(
          "[Firebase] Notification: ${message.notification!.title} - ${message.notification!.body}",
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("[Firebase] Message opened: ${message.messageId}");
    });
  }

  Future<String?> getDeviceToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint("Erreur lors de la récupération du token FCM : $e");
      return null;
    }
  }
}