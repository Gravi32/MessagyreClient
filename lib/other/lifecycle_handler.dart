import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';

class LifecycleHandler extends StatefulWidget {
  final Widget child;
  const LifecycleHandler({super.key, required this.child});

  @override
  State<LifecycleHandler> createState() => _LifecycleHandlerState();
}

class _LifecycleHandlerState extends State<LifecycleHandler> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final connection = ConnectionController();

    if (state == AppLifecycleState.resumed) {
      connection.connect();
      FocusManager.instance.primaryFocus?.unfocus();
    }

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      connection.disconnect();
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
