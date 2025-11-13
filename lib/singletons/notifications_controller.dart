import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

class NotificationController {
  static final NotificationController _instance = NotificationController._internal();
  factory NotificationController() => _instance;
  NotificationController._internal();

  OverlayState? _overlayState;
  OverlayEntry? _currentOverlay;

  void init(BuildContext context) {
    _overlayState = Overlay.of(context);
  }

  void spawn(String sender, String message) {
    print("CALLED $sender $message");
    if ((Data().openChatUsername ?? "") == sender) return;

    _currentOverlay?.remove();
    _currentOverlay = OverlayEntry(
        builder: (context) => NotificationPopup(senderUsername: sender, messageContent: message));
    _overlayState?.insert(_currentOverlay!);
  }

  void remove() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class NotificationPopup extends StatefulWidget {
  final String senderUsername;
  final String messageContent;
  final double outScreenOffset = -150;

  const NotificationPopup({super.key, required this.senderUsername, required this.messageContent});

  @override
  State<NotificationPopup> createState() => _NotificationPopupsState();
}

class _NotificationPopupsState extends State<NotificationPopup> {
  late double _top = widget.outScreenOffset;
  double _dragOffset = 0;
  Timer? _timer;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _top = 8));
    _startAutoDismissTimer();
  }

  void _startAutoDismissTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 3), () {
      if (!_isDragging) _dismiss();
    });
  }

  void _dismiss() {
    _timer?.cancel();
    setState(() => _top = widget.outScreenOffset);
    Future.delayed(Duration(milliseconds: 400), () => NotificationController().remove());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 600),
      curve: _top == 8 ? Curves.easeOutQuart : Curves.easeInCubic,
      top: _top + _dragOffset,
      left: 10,
      right: 10,
      child: GestureDetector(
        onTap: () {
          _dismiss();
          Navigator.of(context, rootNavigator: true)
              .push(CupertinoPageRoute(builder: (_) => ChatOverlay(recipientUsername: widget.senderUsername)));
        },
        onVerticalDragStart: (_) {
          _isDragging = true;
          _timer?.cancel();
        },
        onVerticalDragUpdate: (details) => setState(() => _dragOffset += details.delta.dy),
        onVerticalDragEnd: (details) {
          _isDragging = false;
          if (_dragOffset < -30)
            _dismiss();
          else {
            setState(() => _dragOffset = 0);
            _startAutoDismissTimer();
          }
        },
        child: SafeArea(
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withOpacity(0.75),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    Row(
                      children: [
                        ProfilePictureDisplay(accountUsername: widget.senderUsername, radius: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.senderUsername.replaceAll(".", " ").capitalize(everyWord: true),
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                                    fontSize: 14),
                              ),
                              Text(
                                widget.messageContent.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.fade,
                                softWrap: true,
                                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 100,
                      height: 4,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: CupertinoColors.quaternaryLabel.resolveFrom(context)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
