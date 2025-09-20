import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:messagyre_client/api/firebase_api.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class ConnectionController {
  // Configuration
  static const String localIP = "192.168.1.230:5066";

  static final bool useLocalhost = false;

  static final String serverWebSocketAddress = useLocalhost ? "ws://$localIP" : "wss://messagyre.fly.dev";

  static final String serverHTTPAddress = useLocalhost ? "http://$localIP" : "https://messagyre.fly.dev";

  // Declaring this singleton
  static final _instance = ConnectionController._internal();
  factory ConnectionController() => _instance;
  ConnectionController._internal();

  // Singletons
  late final data = Data();
  late final secureStorage = FlutterSecureStorage();
  late final firebaseApi = FirebaseApi();

  final connectionState = ValueNotifier(ConnectionState.NotConnected);
  int connectionAttempts = 0;
  WebSocketChannel? _channel;

  // Events

  /* Stream for the received WebSocket messages */
  final _messagesController = StreamController<Map<String, Object>>.broadcast();
  Stream<Map<String, Object>> get onMessageReceived => _messagesController.stream;

  /* Stream for the received WebSocket read receipts */
  final _readReceiptsController = StreamController<Map<String, Object>>.broadcast();
  Stream<Map<String, Object>> get onReadReceiptReceived => _readReceiptsController.stream;

  final _connectionStatusController = StreamController<void>.broadcast();
  Stream<void> get onConnected => _connectionStatusController.stream;
  void Function()? onUnauthorized;

  bool get isConnected => _channel != null;

  Future<void> start() async {
    data.token = await secureStorage.read(key: "AccessToken");

    if ((data.token == null || data.username == null) && onUnauthorized != null) {
      debugPrint("[ConnectionController] No token or username found in storage. Switching to AccessOverlay.");
      onUnauthorized!();
      return;
    }

    connect();
  }

  Future<http.Response> refreshAccessToken() async {
    final refreshToken = await secureStorage.read(key: "RefreshToken");
    if (refreshToken == null) {
      return http.Response("No refresh token found in SecureStorage.", 401);
    }

    final response = await post("/Auth/Refresh", {"RefreshToken": refreshToken});

    if (response.statusCode == 200) {
      final results = jsonDecode(response.body);
      data.token = results["AccessToken"];

      await secureStorage.write(key: "AccessToken", value: data.token);
      await secureStorage.write(key: "RefreshToken", value: results["RefreshToken"]);

      return http.Response("OK", 200);
    }

    return response;
  }

  // WebSocket Requests
  void _scheduleReconnect() {
    if (isConnected) return;

    connectionState.value = ConnectionState.WaitingToReconnect;

    connectionAttempts++;
    final delay = min(15 * connectionAttempts, 300);
    debugPrint("[WebSocket] Reconnecting in $delay seconds...");

    Future.delayed(Duration(seconds: delay), () {
      if (!isConnected) connect();
    });
  }

  void connect() async {
    if (isConnected) return;

    // Asking the server to refresh the token
    try {
      connectionState.value = ConnectionState.WaitingForAuthorization;
      debugPrint("[WebSocket 1/2] Attempting to refresh the access tokens...");

      if (onUnauthorized == null) {
        throw Exception("onUnauthorized was not declared.");
      }

      // No token stored, either the first time on the app or logged out
      if (data.token == null) {
        debugPrint("[WebSocket 1/2][!] No token found in local storage.");
        onUnauthorized!();
        return;
      }

      final response = await refreshAccessToken();

      // The server refused to refresh access, user was kicked out or banned
      if (response.statusCode == 401) {
        debugPrint("[WebSocket 1/2][!] Could not refresh the access token. ${response.body}");
        onUnauthorized!();
        return;
      } else if (response.statusCode != 200) {
        throw Exception(response);
      }

      debugPrint("[WebSocket 1/2] Tokens successfully refreshed.");
    } catch (e, s) {
      debugPrint("[WebSocket 1/2][!] Token refresh failed: $e, StackTrace:\n$s");
      connectionState.value = ConnectionState.NotConnected;
      _scheduleReconnect();
      return;
    }

    // Attemping a connection
    try {
      connectionState.value = ConnectionState.Connecting;

      debugPrint("[WebSocket 2/2] Connecting...");

      final socket = await WebSocket.connect(serverWebSocketAddress, headers: {'Authorization': 'Bearer ${data.token}'}).timeout(const Duration(seconds: 40));
      print("[WebSocket 2/2] await WebSocket.connect() finished");

      socket.done.catchError((e) {
        debugPrint("[WebSocket] Socket done with error: $e");
      });

      _channel = IOWebSocketChannel(socket);
      print("[WebSocket] Channel created.");

      connectionAttempts = 0;

      print("[WebSocket] Adding listeners");
      _channel!.stream.listen(
        (message) {
          try {
            final receivedData = jsonDecode(message);

            if (receivedData is List) {
              print("$receivedData ${receivedData.runtimeType} ${receivedData[0]} ${receivedData[0].runtimeType}");
              for (var element in receivedData) {
                _handleMessage(element);
              }
            } else {
              _handleMessage(receivedData);
            }
          } catch (e) {
            debugPrint("[WebSocket] Message received by server could not be decoded: $e. Message content: $message");
          }
        },

        onDone: () {
          debugPrint("[WebSocket] Closed by server");
          _channel = null;
          connectionState.value = ConnectionState.NotConnected;
          _scheduleReconnect();
        },
        onError: (err) {
          debugPrint("[WebSocket] Error: $err");
          _channel = null;
          connectionState.value = ConnectionState.NotConnected;
          _scheduleReconnect();
        },
      );

      debugPrint("[WebSocket 2/2] Connected!");
      connectionState.value = ConnectionState.Connected;
    } catch (e) {
      debugPrint("[WebSocket 2/2][!] Connection failed: $e");

      connectionState.value = ConnectionState.NotConnected;
      _channel = null;
      _scheduleReconnect();
    }
  }

  void _handleMessage(Map<String, dynamic> rawMessageData) {
    try {
      final sender = rawMessageData["SenderUsername"]?.toString();
      final isReadReceipt = rawMessageData.containsKey("ReadAt");

      if (sender == null) throw FormatException("Missing SenderUsername");

      if (isReadReceipt) {
        final readAt = DateTime.parse(rawMessageData["ReadAt"].toString()).toLocal();
        final readReceipt = {"SenderUsername": sender, "ReadAt": readAt};
        _readReceiptsController.add(readReceipt);
      } else {
        final content = rawMessageData["Content"]?.toString();
        final rawSentAt = rawMessageData["SentAt"]?.toString();

        if (content == null || rawSentAt == null) {
          throw FormatException("Missing Content or SentAt");
        }
        final sentAt = DateTime.parse(rawSentAt).toLocal();
        final messageData = {"SenderUsername": sender, "Content": content, "SentAt": sentAt};

        _messagesController.add(messageData);
      }
    } catch (e) {
      debugPrint("[WebSocket] Invalid message format: $e");
    }
  }

  void send(String recipientUsername, String messageContent) {
    final message = jsonEncode({"RecipientUsername": recipientUsername, "Content": messageContent});

    _channel?.sink.add(message);
  }

  void sendReadReceipt(String forUsername) {
    _channel?.sink.add(jsonEncode({"RecipientUsername": forUsername, "IsReadReceipt": true}));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    connectionState.value = ConnectionState.NotConnected;
    debugPrint("[WebSocket] Connection closed manually");
  }

  // HTTP Shorthands

  Future<http.Response> post(String route, Object body, {int timeout = 30}) async {
    try {
      final response = await http
          .post(
            Uri.parse(serverHTTPAddress + route),
            headers: {"Content-Type": "application/json", if (data.token != null) "Authorization": "Bearer ${data.token!}"},
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: timeout));

      return response;
    } on TimeoutException {
      debugPrint("[POST Request Timeout] $route");
      return http.Response("Timeout", 408);
    } catch (e) {
      debugPrint("[POST Request Error] $route: $e");
      return http.Response("Internal error", 500);
    }
  }

  Future<http.Response> get(String route, {int timeout = 30}) async {
    try {
      final response = await http
          .get(
            Uri.parse(serverHTTPAddress + route),
            headers: {"Content-Type": "application/json", if (data.token != null) "Authorization": "Bearer ${data.token!}"},
          )
          .timeout(Duration(seconds: timeout));

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

  Future<bool> uploadProfile(Map<String, dynamic> profileObject, {String? imagePath, bool removeProfilePicture = false}) async {
    final uri = Uri.parse('$serverHTTPAddress/Accounts/Me/UploadProfile');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${data.token}';
    request.fields['Profile'] = jsonEncode(profileObject);

    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('Image', imagePath));
    } else if (removeProfilePicture) {
      request.fields['RemoveProfilePicture'] = 'true';
    }

    try {
      final response = await request.send().timeout(Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();

      debugPrint("[ProfileUpload] ${response.statusCode} $responseBody");

      if (response.statusCode != 200) {
        debugPrint("[ProfileUpload Failed] (${response.statusCode})");
        return false;
      }

      final responseJson = jsonDecode(responseBody);
      final updatedPfpUrl = responseJson["ProfilePictureURL"];

      if (updatedPfpUrl != null && updatedPfpUrl is String) {
        data.pfpNotifiersCache[data.username]?.value = updatedPfpUrl;
      }

      return true;
    } catch (e) {
      debugPrint("[ProfileUpload Failed] $e");
      return false;
    }
  }

  Future<String?> getProfilePicture(String accountUsername) async {
    final response = await get("/Accounts/GetProfilePictureURL?Username=$accountUsername");

    if (response.statusCode != 200) {
      if (response.statusCode != 404) {
        debugPrint("[PFP Get Failed] Error ${response.statusCode} (${response.body})");
      }
      return null;
    }

    final result = json.decode(response.body) as String?;
    data.pfpNotifiersCache[accountUsername]?.value = result;
    return result;
  }

  Future<Account?> getAccount(String accountUsername) async {
    final response = await get("/Accounts/Get?Username=$accountUsername");

    if (response.statusCode != 200) {
      debugPrint("[Account Get Failed] Error ${response.statusCode}: ${response.body}");
      return null;
    }

    final result = Account.fromJson(response.body);

    return result;
  }
}

enum ConnectionState { NotConnected, WaitingForAuthorization, Connecting, WaitingToReconnect, Connected }
