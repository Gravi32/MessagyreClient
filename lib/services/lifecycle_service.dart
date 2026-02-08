import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/services/network_service.dart';

class LifecycleService extends StatefulWidget {
  final Widget child;
  const LifecycleService({super.key, required this.child});

  @override
  State<LifecycleService> createState() => _LifecycleHandlerState();
}

class _LifecycleHandlerState extends State<LifecycleService> with WidgetsBindingObserver {
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
    final connection = NetworkService();

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
