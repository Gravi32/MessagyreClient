import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class ConnectionController {
  // Configuration

  static const bool useLocalhost = true;
  static String localIP = "192.168.1.230:5066";

  static String serverWebSocketAddress =
      useLocalhost ? "ws://$localIP" : "wss://messagyre.up.railway.app";

  static String serverHTTPAddress =
      useLocalhost ? "http://$localIP" : "https://messagyre.up.railway.app";

  // Singletons

  static final _instance = ConnectionController._internal();
  factory ConnectionController() => _instance;
  ConnectionController._internal();

  late final data = Data();
  late final secureStorage = FlutterSecureStorage();

  WebSocketChannel? _channel;

  // Events

  final _messageDataController =
      StreamController<Map<String, Object>>.broadcast();
  final _connectionStatusController = StreamController<void>.broadcast();
  Stream<Map<String, Object>> get onMessageDataReceived =>
      _messageDataController.stream;
  Stream<void> get onConnected => _connectionStatusController.stream;
  void Function()? onUnauthorized;

  bool get isConnected => _channel != null;

  Future<void> start() async {
    debugPrint("[Router] Reading AccessToken...");
    data.token = await secureStorage.read(key: "token");

    debugPrint("[Router] Pinging server...");
    var response = await post("/Auth/Check", {});

    debugPrint("[Router] Server response code: ${response.statusCode}");

    if (response.statusCode == 200) connect();
  }

  // WebSocket Requests

  void connect() async {
    if (isConnected) return;

    try {
      final socket = await WebSocket.connect(
        serverWebSocketAddress,
        headers: {'Authorization': 'Bearer ${data.token}'},
      ).timeout(const Duration(seconds: 5));

      _channel = IOWebSocketChannel(socket);

      debugPrint("[WebSocket] Connected");

      _channel!.stream.listen(
        (stringMessage) {
          try {
            final rawMessageData = jsonDecode(stringMessage);

            final sender = rawMessageData["SenderUsername"]?.toString();
            final content = rawMessageData["Content"]?.toString();
            final rawSentAt = rawMessageData["SentAt"]?.toString();

            if (sender == null || content == null || rawSentAt == null) {
              throw FormatException("Missing fields");
            }

            final sentAt = DateTime.parse(rawSentAt);

            final messageData = {
              "SenderUsername": sender,
              "Content": content,
              "SentAt": sentAt,
            };

            _messageDataController.add(messageData);
          } catch (e) {
            debugPrint("[WebSocket] Received invalid message data: $e");
          }
        },
        onDone: () {
          debugPrint("[WebSocket] Connection closed by server");
          _channel = null;
          connect();
        },
        onError: (error) {
          debugPrint("[WebSocket] Error: $error");
          _channel = null;
          connect();
        },
      );

      _connectionStatusController.add(null);
    } catch (e) {
      if (e.toString().contains("401") && onUnauthorized != null) {
        onUnauthorized!();
        return;
      }
      debugPrint("[WebSocket] Could not connect ($e). Retrying...");
      _channel = null;
      connect();
    }
  }

  void send(String recipientUsername, String messageContent) {
    final message = jsonEncode({
      "RecipientUsername": recipientUsername,
      "Content": messageContent,
    });

    _channel?.sink.add(message);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    debugPrint("[WebSocket] Connection closed manually");
  }

  // HTTP Shorthands

  Future<http.Response> post(
    String route,
    Object body, {
    int timeout = 30,
    bool sendToken = true,
    bool handleUnauthorized = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(serverHTTPAddress + route),
            headers: {
              "Content-Type": "application/json",
              if (sendToken && data.token != null)
                "Authorization": "Bearer ${data.token!}",
            },
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: timeout));

      if (handleUnauthorized &&
          response.statusCode == 401 &&
          onUnauthorized != null) {
        onUnauthorized!();
      }

      return response;
    } on TimeoutException {
      debugPrint("[POST Request Timeout] $route");
      return http.Response("Timeout", 408);
    } catch (e) {
      debugPrint("[POST Request Error] $route: $e");
      return http.Response("Internal error", 500);
    }
  }

  Future<http.Response> get(
    String route, {
    bool sendToken = true,
    int timeout = 30,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(serverHTTPAddress + route),
            headers: {
              "Content-Type": "application/json",
              if (sendToken && data.token != null)
                "Authorization": "Bearer ${data.token!}",
            },
          )
          .timeout(Duration(seconds: timeout));

      if (response.statusCode == 401 && onUnauthorized != null) {
        onUnauthorized!();
      }

      return response;
    } on TimeoutException {
      debugPrint("[GET Request Timeout] $route");
      return http.Response("Timeout", 408);
    } catch (e) {
      debugPrint("[GET Request Error] $route: $e");
      return http.Response("Internal error", 500);
    }
  }

  // HTTP Requests

  Future<String?> uploadProfilePicture(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$serverHTTPAddress/Accounts/Me/UploadProfilePicture'),
    );

    debugPrint("Sending $filePath");

    request.headers["Authorization"] = "Bearer ${data.token}";
    request.files.add(await http.MultipartFile.fromPath('Image', filePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    debugPrint("${response.statusCode} $responseBody");

    if (response.statusCode != 200) {
      debugPrint("[PFP Upload Failed] (${response.statusCode}): $responseBody");
      return null;
    }

    final responseURL = jsonDecode(responseBody)["ProfilePictureURL"];
    debugPrint(responseURL);
    data.pfpNotifiersCache[data.username]?.value = responseURL;

    return responseURL;
  }

  Future<bool> uploadProfile(Map<String, dynamic> profileObject) async {
    final response = await post("/Accounts/Me/UploadProfile", {
      "Token": data.token ?? "",
      "Profile": profileObject,
    });

    if (response.statusCode != 200) {
      debugPrint(
        "[Profile Upload Failed] Error ${response.statusCode}: ${response.body}",
      );
      return false;
    }

    return true;
  }

  Future<String?> getProfilePicture(String accountUsername) async {
    final response = await get(
      "/Accounts/GetProfilePictureURL?Username=$accountUsername",
    );

    if (response.statusCode != 200) {
      debugPrint(
        "[PFP Get Failed] Error ${response.statusCode} (${response.body})",
      );
      return null;
    }

    final result = json.decode(response.body) as String?;
    data.pfpNotifiersCache[accountUsername]?.value = result;
    return result;
  }

  Future<Account?> getAccount(String accountUsername) async {
    final response = await get("/Accounts/Get?Username=$accountUsername");

    if (response.statusCode != 200) {
      debugPrint(
        "[Account Get Failed] Error ${response.statusCode}: ${response.body}",
      );
      return null;
    }

    final result = Account.fromJson(response.body);

    return result;
  }
}
