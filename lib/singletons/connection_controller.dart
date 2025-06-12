import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ConnectionController {
  static final ConnectionController _instance =
      ConnectionController._internal();
  factory ConnectionController() => _instance;
  ConnectionController._internal();

  late final Data data = Data();

  WebSocketChannel? _channel;

  final _signalController = StreamController<Signal>.broadcast();
  final _connectionStatusController = StreamController<void>.broadcast();
  Stream<Signal> get onSignalReceived => _signalController.stream;
  Stream<void> get onConnected => _connectionStatusController.stream;
  bool get isConnected => _channel != null;

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

  Future<String?> uploadProfilePicture(String filePath) async {
    if (data.account == null) return null;

    // Creating the request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${App.serverHTTPAddress}/upload-pfp'),
    );
    request.fields["Username"] = data.account!.username;
    request.files.add(await http.MultipartFile.fromPath('Image', filePath));

    // Sending the request and waiting for the result
    _print("Image uploaded. Waiting for response...");

    final response = await request.send();

    if (response.statusCode != 200) {
      _print(
        "Error uploading image (${response.statusCode}): ${await response.stream.bytesToString()}",
      );
    }

    final responseBody = await response.stream.bytesToString();
    final responseURL = jsonDecode(responseBody)["url"];

    _print("Uploaded image for ${data.account!.username}: $responseURL");
    data.pfpNotifiersCache[data.account!.username]?.value = responseURL;
    return responseURL;
  }

  Future<String?> getProfilePicture(String accountUsername) async {
    final response = await http.get(
      Uri.parse(
        "${App.serverHTTPAddress}/get-pfp-url?username=$accountUsername",
      ),
    );

    if (response.statusCode != 200) {
      _print("[PFP] Failed fetching picture URL (${response.statusCode})");
      return null;
    }

    final result = json.decode(response.body)["url"] as String?;
    data.pfpNotifiersCache[accountUsername]?.value = result;
    return result;
  }

  Future<Account?> getAccount(String accountUsername) async {
    final response = await http.get(
      Uri.parse(
        "${App.serverHTTPAddress}/get-account?username=$accountUsername",
      ),
    );

    if (response.statusCode != 200) {
      _print("[Account] Failed fetching account (${response.statusCode})");
      return null;
    }

    final jsonResult = json.decode(response.body)["account"] as String?;

    return Account.fromJson(jsonResult);
  }

  // Local methods
  void _print(String content) {
    debugPrint("[ConnectionController] $content");
  }

  // Local event handling
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
