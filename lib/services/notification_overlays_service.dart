import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/notification_overlays.dart';

class NotificationOverlaysService {
  static final NotificationOverlaysService _instance = NotificationOverlaysService._internal();
  factory NotificationOverlaysService() => _instance;
  NotificationOverlaysService._internal();

  OverlayState? _overlayState;
  OverlayEntry? _currentOverlay;

  void init(BuildContext context) {
    _overlayState = Overlay.of(context);
  }

  void spawn(String title, String sender, String message) {
    if ((GlobalsService().openChatUsername ?? "") == sender) return;

    _currentOverlay?.remove();
    _currentOverlay = OverlayEntry(builder: (context) => NotificationOverlay(title: title, senderUsername: sender, messageContent: message));
    _overlayState?.insert(_currentOverlay!);
  }

  void remove() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
