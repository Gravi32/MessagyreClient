import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  String lastSentUsername = "", lastSentPassword = "";

  void connect(String url) async {
    if (isConnected) return;

    _channel = WebSocketChannel.connect(Uri.parse(url));
    _print("Connecting...");

    _channel!.stream.listen(
      (message) {
        _print("Received: $message");

        final signal = Signal.unpack(message);
        if (signal == null) return;

        _signalController.add(signal);
        _onSignalReceived(signal);
      },
      onDone: () {
        _print("Connection closed by server");
        _channel = null;
        connect(url);
      },
      onError: (error) {
        _print("Error: $error");
        _channel = null;
        connect(url);
      },
    );

    _channel!.ready
        .then((_) {
          _print("Connected");

          _connectionStatusController.add(null);
        })
        .catchError((error) {
          _print("Could not connect: $error");
        });
  }

  void send(String message) {
    _channel?.sink.add(message);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _print("Connection closed manually");
  }

  void login(String username, String password) {
    send(
      Signal(
        type: SignalType.Login,
        data: {"Username": username, "Password": password},
      ).pack(),
    );
    
    lastSentUsername = username;
    lastSentPassword = password;

    _print("Logging in as $username... ($password)");
  }

  void _print(String content) {
    debugPrint("[ConnectionController] $content");
  }

  void _onSignalReceived(Signal signal) {
    // On successful login
    if (signal.type == SignalType.Login) {
      var account = signal.data["Account"];

      if (account == null) return;
      data.account = Account.fromJson(account);

      var box = Hive.box("AccessInfo");
      box.put("Username", lastSentUsername);
      box.put("Password", lastSentPassword);
    }
  }
}
