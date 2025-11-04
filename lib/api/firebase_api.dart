import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/singletons/notifications_controller.dart';
import 'dart:io' show Platform;

class FirebaseApi {
  static final _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  final data = Data();
  final router = ConnectionController();
  final firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 2));

    final settings = await firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (Platform.isIOS) {
        final apnsToken = await firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint("[Firebase] ⚠️ Nessun APNs token disponibile. Le notifiche non funzioneranno su iOS.");
        } else {
          debugPrint("[Firebase] APNs token: $apnsToken");
        }
      }

      data.fcmToken = await firebaseMessaging.getToken();
      debugPrint("[Firebase] FCM token: ${data.fcmToken}");
      sendTokenToServer();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("[Firebase] Messaggio ricevuto: ${message.messageId}");
        if (message.notification != null) {
          NotificationController().spawn(
            message.notification?.title ?? "",
            message.notification?.body ?? "Une erreur est survenue.",
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final title = message.notification?.title;
        if (title == null) return;
        navigatorKey.currentState?.push(
          CupertinoPageRoute(builder: (_) => ChatOverlay(recipientUsername: title)),
        );
      });

      firebaseMessaging.onTokenRefresh.listen((newToken) {
        data.fcmToken = newToken;
        sendTokenToServer();
      });
    } else {
      debugPrint("[Firebase] Notifiche non autorizzate dall’utente.");
    }
  }

  void sendTokenToServer() {
    final token = data.fcmToken;
    if (token == null) return;

    debugPrint("[Firebase] Invio FCM token al server...");

    router
        .post("/Accounts/Me/UploadFirebaseToken", {"FirebaseToken": token})
        .then((response) {
      if (response.statusCode == 200) {
        debugPrint("[Firebase] Token inviato con successo.");
      } else {
        debugPrint("[Firebase] Errore nell’invio del token. Codice: ${response.statusCode}, body: ${response.body}");
      }
    }).catchError((error) {
      debugPrint("[Firebase] Errore durante l’invio del token: $error");
    });
  }
}
