import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/singletons/notifications_controller.dart';

class FirebaseApi {
  static final _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  final data = Data();
  final router = ConnectionController();
  final firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await firebaseMessaging.requestPermission();

    data.fcmToken = await firebaseMessaging.getToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("[Firebase] Message received: ${message.messageId}");
      if (message.notification != null) {
        NotificationController().spawn(
          message.notification?.title ?? "",
          message.notification?.body ?? "Une erreur est survenue.",
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification?.title == null) return;
      
      navigatorKey.currentState?.push(
        CupertinoPageRoute(
          builder:
              (_) => ChatOverlay(
                recipientUsername:
                    message.notification!.title!
              ),
        ),
      );
    });

    firebaseMessaging.onTokenRefresh.listen((newToken) {
      data.fcmToken = newToken;
      sendTokenToServer();
    });
  }

  void sendTokenToServer() {
    if (data.fcmToken == null) return;

    debugPrint("[Firebase] Sending FCM Token to the server...");

    router
        .post("/Accounts/Me/UploadFirebaseToken", {
          "FirebaseToken": data.fcmToken,
        })
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
