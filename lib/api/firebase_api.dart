import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';

class FirebaseApi {
  static final _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  final router = ConnectionController();
  final firebaseMessaging = FirebaseMessaging.instance;

  String? token;

  Future<void> initialize() async {
    await firebaseMessaging.requestPermission();

    token = await firebaseMessaging.getToken();

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

    firebaseMessaging.onTokenRefresh.listen((newToken) {
      token = newToken;
      sendTokenToServer();
    });
  }

  void sendTokenToServer() {
    if (token == null) return;

    debugPrint("[Firebase] Sending FCM Token to the server...");

    router
        .post("/Accounts/Me/UploadFirebaseToken", {"FirebaseToken": token})
        .then((response) {
          if (response.statusCode == 200) {
            debugPrint("[Firebase] Token sent to server successfully.");
          } else {
            debugPrint(
              "[Firebase] Failed to send token to server. Status code: ${response.statusCode}, body: ${response.body}",
            );
          }
        })
        .catchError((error) {
          debugPrint("[Firebase] Error sending token to server: $error");
        });
  }
}
