import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ConnectionController {
  static final _instance = ConnectionController._singleton();

  factory ConnectionController() => _instance;
  ConnectionController._singleton();

  WebSocketChannel? _channel;

  final _signalController = StreamController<Signal>.broadcast();
  final _connectionStatusController = StreamController<void>.broadcast();

  Stream<Signal> get onSignalReceived => _signalController.stream;
  Stream<void> get onConnected => _connectionStatusController.stream;

  bool get isConnected => _channel != null;

  final data = Data();

  void connect(String url) async {
    if (isConnected) return;

    _channel = WebSocketChannel.connect(Uri.parse(url));
    debugPrint("Connecting...");

    _channel!.stream.listen(
      (message) {
        debugPrint("Received: $message");

        final signal = Signal.unpack(message);
        if (signal == null) return;

        _signalController.add(signal);
        _onSignalReceived(signal);
      },
      onDone: () {
        debugPrint("Connection closed by server");
        _channel = null;
        connect(url);
      },
      onError: (error) {
        debugPrint("Error: $error");
        _channel = null;
        connect(url);
      },
    );

    _channel!.ready
        .then((_) {
          debugPrint("Connected");

          _connectionStatusController.add(null);
        })
        .catchError((error) {
          debugPrint("Could not connect: $error");
        });
  }

  void send(String message) {
    _channel?.sink.add(message);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    debugPrint("Connection closed manually");
  }

  void login(String username, String password) {
    send(
      Signal(
        type: SignalType.Login,
        data: {"Username": username, "Password": password},
      ).pack(),
    );
  }

  void _onSignalReceived(Signal signal) {
    if (signal.type != SignalType.Login) return;
    var account = signal.data["Account"];

    if (account == null) return;
    data.account = Account.fromJson(account);
  }
}
