import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:messagyre_client/services/encryption_service.dart';
import 'package:messagyre_client/services/notification_overlays_service.dart';
import 'package:messagyre_client/services/notifications_service.dart';

import 'package:messagyre_client/services/globals_service.dart';

class FirebaseApi {
  static final _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  final firebaseMessaging = FirebaseMessaging.instance;
  final notifications = NotificationsService();
  final notificationOverlays = NotificationOverlaysService();
  final globals = GlobalsService();
  final encryption = EncryptionService();

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listening first: nothing is missed while the permission and the token are awaited
    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

    // The app was started by tapping a notification
    final initialMessage = await firebaseMessaging.getInitialMessage();
    if (initialMessage != null) _onMessageOpened(initialMessage);

    final settings = await firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus != AuthorizationStatus.authorized && settings.authorizationStatus != AuthorizationStatus.provisional) return;

    // iOS gives the Firebase token only once Apple's (APNs) is there: a few seconds at most
    if (Platform.isIOS) {
      for (var attempt = 0; attempt < 20 && await firebaseMessaging.getAPNSToken() == null; attempt++) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    try {
      globals.fcmToken = await firebaseMessaging.getToken();
    } catch (e) {
      debugPrint("[Firebase] No push token: $e");
    }
  }

  /// A push received while the app is open: a banner inside the app (unless that conversation is open)
  Future<void> _onMessage(RemoteMessage message) async {
    try {
      final content = await NotificationContent.fromData(message.data, fallbackTitle: message.notification?.title, fallbackBody: message.notification?.body);
      final chatId = content.chatId;
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        if (chatId != null) notificationOverlays.spawn(content.title, content.isShared ? "${content.senderName} : ${content.body}" : content.body, chatId);
        notifications.resetBadge();
      }
    } catch (e) {
      debugPrint("[Firebase] A push couldn't be shown: $e");
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    final group = message.data['Group'], username = message.data['SenderUsername'], chat = message.data['Chat'];
    if (chat is String && chat.isNotEmpty) {
      NotificationsService.openChat(chat);
    } else if (group is String && group.isNotEmpty) {
      NotificationsService.openChat("#$group");
    } else if (username is String) {
      NotificationsService.openChat(username);
    }
    notifications.resetBadge();
  }

  void _onTokenRefresh(String token) {
    globals.fcmToken = token;
    notifications.sendTokenToServer();
  }
}

/// What a message notification shows, from the push's data (see the server's FirebaseService)
class NotificationContent {
  final String senderName;
  final String? senderUsername;
  final String body;
  final String? pictureUrl;

  /// The class, for a message of a class chat (apps from 4.94)
  final String? group;

  /// Another shared conversation (the global chat, "@general") and its name
  final String? chat;
  final String? chatName;

  NotificationContent(this.senderName, this.senderUsername, this.body, this.pictureUrl, {this.group, this.chat, this.chatName});

  /// A conversation of several people: the notification says who wrote
  bool get isShared => group != null || chat != null;

  /// The conversation it belongs to: the sender, the class chat ("#1M05") or the global chat ("@general")
  String? get chatId => chat ?? (group != null ? "#$group" : senderUsername);

  /// The conversation's name: the sender, the class or the shared conversation
  String get title => chatName ?? (group != null ? "Classe $group" : senderName);

  static Future<NotificationContent> fromData(Map<String, dynamic> data, {String? fallbackTitle, String? fallbackBody}) async {
    final title = (data['Title'] ?? fallbackTitle ?? 'Messagyre').toString();
    final cipherText = data['CipherText'], iv = data['IV'] ?? data['Iv'], encryptedKey = data['EncryptedKey'];

    // The server only knows that a message arrived: the text is decrypted here
    String body = (data['Body'] ?? fallbackBody ?? '').toString();
    if (cipherText is String && iv is String && encryptedKey is String) {
      try {
        body = (await EncryptionService().decryptPayload(cipherText, iv, encryptedKey)).$1;
      } catch (e) {
        debugPrint("[Notifications] A message couldn't be decrypted: $e");
      }
    }

    final picture = data['ProfilePictureURL'];
    return NotificationContent(
      title.replaceFirst(RegExp(r'^💬\s*'), ''), // the server adds it for the apps that show the title as it is
      data['SenderUsername']?.toString(),
      body,
      picture is String && picture.isNotEmpty ? picture : null,
      group: data['Group'] is String && (data['Group'] as String).isNotEmpty ? data['Group'] as String : null,
      chat: data['Chat'] is String && (data['Chat'] as String).isNotEmpty ? data['Chat'] as String : null,
      chatName: data['ChatName'] is String && (data['ChatName'] as String).isNotEmpty ? data['ChatName'] as String : null,
    );
  }
}

/// Android: pushes arriving while the app is in the background or closed (they only carry data: the
/// notification is built here, with the decrypted text). iOS shows them itself (NotificationService.swift).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!Platform.isAndroid) return;
  try {
    await Firebase.initializeApp();
    await showMessageNotification(message.data, initializePlugin: true);
  } catch (e, s) {
    debugPrint("[Notifications] A push couldn't be shown: $e\n$s");
  }
}

const _channelId = 'messagyre_channel';
const _maxMessagesPerNotification = 6;

/// One notification per conversation: the sender's photo (with Messagyre's icon at the bottom right) and
/// their latest messages
///
/// [initializePlugin] in the background isolate only: in the app, initializing again would replace the
/// handler of the taps (NotificationsService.initialize)
Future<void> showMessageNotification(Map<String, dynamic> data, {bool initializePlugin = false}) async {
  final content = await NotificationContent.fromData(data);
  final sender = content.senderUsername ?? content.senderName;
  final conversation = content.chatId ?? sender;

  final plugin = FlutterLocalNotificationsPlugin();
  if (initializePlugin) await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('ic_notification')));
  final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  final id = notificationIdFor(conversation);
  final avatar = await _avatarWithBadge(content.pictureUrl, content.senderName);
  final person = Person(key: sender, name: content.senderName, icon: avatar != null ? ByteArrayAndroidIcon(avatar) : null, important: true);

  // The messages already in this conversation's notification stay under the new one
  List<Message> previous = const [];
  try {
    previous = (await android?.getActiveNotificationMessagingStyle(id))?.messages ?? const [];
  } catch (_) {}
  final messages = [...previous, Message(content.body, DateTime.now(), person)];

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Messagyre',
      channelDescription: 'Messages reçus',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      icon: 'ic_notification',
      color: const Color.fromRGBO(171, 12, 179, 1),
      largeIcon: avatar != null ? ByteArrayAndroidBitmap(avatar) : null,
      styleInformation: MessagingStyleInformation(
        person,
        conversationTitle: content.title,
        groupConversation: content.isShared,
        messages: messages.length > _maxMessagesPerNotification ? messages.sublist(messages.length - _maxMessagesPerNotification) : messages,
      ),
    ),
  );

  await plugin.show(id, content.title, content.body, details, payload: jsonEncode({"Username": conversation}));
}

/// The same number for the same conversation, in any isolate (String.hashCode isn't guaranteed to be)
int notificationIdFor(String username) {
  var hash = 17;
  for (final unit in username.codeUnits) {
    hash = (hash * 31 + unit) & 0x3fffffff;
  }
  return hash + 1000; // below are the assignments' notifications
}

/// The sender's photo (or their initial) in a circle, with Messagyre's icon at the bottom right
Future<Uint8List?> _avatarWithBadge(String? pictureUrl, String name) async {
  try {
    const size = 192;
    final canvas = img.Image(width: size, height: size, numChannels: 4);

    img.Image? photo;
    if (pictureUrl != null) {
      try {
        final response = await http.get(Uri.parse(pictureUrl)).timeout(const Duration(seconds: 6));
        // With an alpha channel (a JPEG has none): the rounded corners must be transparent, not black
        if (response.statusCode == 200) photo = img.decodeImage(response.bodyBytes)?.convert(numChannels: 4);
      } catch (_) {}
    }

    if (photo != null) {
      img.compositeImage(canvas, img.copyResizeCropSquare(photo, size: size, radius: size / 2, antialias: true, interpolation: img.Interpolation.average));
    } else {
      img.fillCircle(canvas, x: size ~/ 2, y: size ~/ 2, radius: size ~/ 2, color: img.ColorRgba8(171, 12, 179, 255), antialias: true);
      final initial = name.trim().isEmpty ? "?" : name.trim().characters.first.toUpperCase();
      img.drawString(canvas, initial, font: img.arial48, x: size ~/ 2 - 14, y: size ~/ 2 - 26, color: img.ColorRgba8(255, 255, 255, 255));
    }

    // The badge, on a white ring so it stands apart from the photo
    img.Image? badge;
    try {
      final badgeData = await rootBundle.load('assets/icons/notification_badge.png');
      badge = img.decodePng(badgeData.buffer.asUint8List(badgeData.offsetInBytes, badgeData.lengthInBytes));
    } catch (e) {
      debugPrint("[Notifications] No badge: $e");
    }
    if (badge != null) {
      const badgeSize = 72, ring = 6;
      const centre = size - badgeSize ~/ 2 - 2;
      img.fillCircle(canvas, x: centre, y: centre, radius: badgeSize ~/ 2 + ring, color: img.ColorRgba8(255, 255, 255, 255), antialias: true);
      img.compositeImage(
        canvas,
        img.copyResize(badge, width: badgeSize, height: badgeSize, interpolation: img.Interpolation.cubic),
        dstX: centre - badgeSize ~/ 2,
        dstY: centre - badgeSize ~/ 2,
      );
    }

    return img.encodePng(canvas);
  } catch (e) {
    debugPrint("[Notifications] The avatar couldn't be drawn: $e");
    return null;
  }
}
