import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:messagyre_client/access.dart';
import 'package:messagyre_client/other/firebase_api.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class ConnectionController {
  // Configuration
  static const String localhostAddress = "192.168.1.230:5066";
  static const String linuxServerAddress = "152.228.173.250:5066";

  static final bool useLocalhost = false;
  static final bool useLinuxServer = true;

  static final String serverWebSocketAddress =
      useLocalhost
          ? "ws://$localhostAddress"
          : useLinuxServer
          ? "ws://$linuxServerAddress"
          : "wss://messagyre.fly.dev";

  static final String serverHTTPAddress =
      useLocalhost
          ? "http://$localhostAddress"
          : useLinuxServer
          ? "http://$linuxServerAddress"
          : "https://messagyre.fly.dev";

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

  /* Stream for the received WebSocket messages status updates */
  final _messageStatusUpdatesController = StreamController<Map<String, Object>>.broadcast();
  Stream<Map<String, Object>> get onMessageStatusUpdateReceived => _messageStatusUpdatesController.stream;

  /* Stream for the received WebSocket messages deletion */
  final _messageDeletionController = StreamController<Map<String, Object>>.broadcast();
  Stream<Map<String, Object>> get onMessageDeletionReceived => _messageDeletionController.stream;

  void onUnauthorized() {
    if (navigatorKey.currentState?.widget is AccessOverlay) return;
    navigatorKey.currentState?.push(CupertinoPageRoute(builder: (_) => const AccessOverlay()));
  }

  bool get isConnected => _channel != null;
  bool _manuallyDisconnected = false;

  Future<void> start() async {
    data.token = await secureStorage.read(key: "AccessToken");

    if (data.token == null || data.username == null) {
      debugPrint("[ConnectionController] No token or username found in storage. Switching to AccessOverlay.");
      onUnauthorized();
      return;
    }

    connect();
  }

  Future<http.Response> refreshAccessToken() async {
    final refreshToken = await secureStorage.read(key: "RefreshToken");

    if (refreshToken == null) {
      return http.Response("No refresh token found in SecureStorage.", 401);
    }

    final response = await post("/Auth/Refresh", {"RefreshToken": refreshToken}).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception("Refresh token request timed out");
      },
    );

    if (response.statusCode == 200) {
      try {
        final results = jsonDecode(response.body);
        data.token = results["AccessToken"];

        await secureStorage.write(key: "AccessToken", value: data.token);
        await secureStorage.write(key: "RefreshToken", value: results["RefreshToken"]);
      } catch (e) {
        debugPrint("[WebSocket] Failed decoding server response: ${response.body} -> $e");
      }

      return http.Response("OK", 200);
    }

    return response;
  }

  // WebSocket Requests
  void _scheduleReconnect() {
    if (isConnected) return;

    connectionState.value = ConnectionState.WaitingToReconnect;

    final delay = connectionAttempts == 0 ? 1 : min(5 * connectionAttempts, 30);
    connectionAttempts++;

    debugPrint("[WebSocket] Reconnecting in $delay seconds...");

    Future.delayed(Duration(seconds: delay), () {
      if (!isConnected) connect();
    });
  }

  void connect() async {
    if (isConnected) return;

    bool shouldScheduleReconnect = false;

    // Asking the server to refresh the token
    try {
      connectionState.value = ConnectionState.WaitingForAuthorization;

      // No token stored, either the first time on the app or logged out
      if (data.token == null) {
        onUnauthorized();
        throw Exception("[WebSocket] Connection aborted: No token found in Data.");
      }

      final response = await refreshAccessToken();

      // The server refused to refresh access, user was kicked out or banned
      if (response.statusCode == 401) {
        onUnauthorized();
        throw Exception("[WebSocket] Could not refresh the access token. ${response.body}");
      } else if (response.statusCode != 200) {
        shouldScheduleReconnect = true;
        throw Exception(response);
      }
    } catch (e) {
      debugPrint("[WebSocket] Token refresh failed: $e");
      connectionState.value = ConnectionState.NotConnected;
      if (shouldScheduleReconnect) _scheduleReconnect();
      return;
    }

    // Attemping a connection
    try {
      connectionState.value = ConnectionState.Connecting;

      final socket = await WebSocket.connect(serverWebSocketAddress, headers: {'Authorization': 'Bearer ${data.token}'}).timeout(const Duration(seconds: 40));

      socket.done.catchError((e) {
        debugPrint("[WebSocket] Socket done with error: $e");
      });

      _channel = IOWebSocketChannel(socket);

      _channel!.stream.listen(
        (message) {
          try {
            final receivedData = jsonDecode(message);

            if (receivedData is List) {
              for (var element in receivedData) {
                _handleMessage(element);
              }
            } else {
              _handleMessage(receivedData);
            }
          } catch (e) {
            debugPrint("[WebSocket] An error occurred while decoding a message: $e. Message content: $message");
          }
        },

        onDone: () {
          debugPrint("[WebSocket] Closed by server");
          _channel = null;
          connectionState.value = ConnectionState.NotConnected;

          if (_manuallyDisconnected) {
            // Avoiding reconnection attempts after manual disconnection
            _manuallyDisconnected = false;
            return;
          }

          _scheduleReconnect();
        },
        onError: (err) {
          debugPrint("[WebSocket] Error: $err");
          _channel = null;
          connectionState.value = ConnectionState.NotConnected;
          _scheduleReconnect();
        },
      );

      connectionState.value = ConnectionState.Connected;
      connectionAttempts = 0;
    } catch (e) {
      debugPrint("[WebSocket] Connection FAILED: $e");

      connectionState.value = ConnectionState.NotConnected;
      _channel = null;
      _scheduleReconnect();
    }
  }

  void _handleMessage(Map<String, dynamic> rawMessageData) {
    debugPrint("[Router] WebSocket message received. Raw data: $rawMessageData");
    try {
      final sender = rawMessageData["SenderUsername"]?.toString();
      final isMessageStatusUpdate = rawMessageData.containsKey("Status") && rawMessageData["Status"] != null;
      final isMessageDeletion = rawMessageData.containsKey("Deletion") && rawMessageData["Deletion"] == true;

      if (sender == null) throw FormatException("Missing SenderUsername");
      if (data.blockedUsers.contains(sender)) return;

      final messageId = rawMessageData["ID"]?.toString();

      if (isMessageStatusUpdate) {
        // If the received WebSocket message is a Status Update
        final status = MessageStatus.values.firstWhere((status) => status.name == rawMessageData["Status"]?.toString(), orElse: () => MessageStatus.Failed);

        if (messageId == null) throw FormatException("Missing Message ID");

        _messageStatusUpdatesController.add({"SenderUsername": sender, "ID": messageId, "Status": status});
      } else if (isMessageDeletion) {
        // If the received WebSocket message is for a Message Deletion
        if (messageId == null) throw FormatException("Missing Message ID");
        _messageDeletionController.add({"SenderUsername": sender, "ID": messageId});
      } else {
        // If the received WebSocket message is a simple Message
        final content = rawMessageData["Content"]?.toString();
        final rawSentAt = rawMessageData["SentAt"]?.toString();

        if (content == null || rawSentAt == null) {
          throw FormatException("Missing Content or SentAt");
        }
        final sentAt = DateTime.parse(rawSentAt).toLocal();
        final messageData = {"ID": messageId ?? Uuid().v4(), "SenderUsername": sender, "Content": content, "SentAt": sentAt};

        _messagesController.add(messageData);

        if (messageId != null) sendMessageStatusUpdate([messageId], sender, MessageStatus.Delivered);

        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint("[WebSocket] Invalid message format: $e");
    }
  }

  void send(String id, String recipientUsername, String messageContent) {
    final message = jsonEncode({"RequestType": "Message", "ID": id, "RecipientUsername": recipientUsername, "Content": messageContent});

    _channel?.sink.add(message);
  }

  void sendMessageStatusUpdate(List<String> forMessageIds, String forUsername, MessageStatus status) {
    _channel?.sink.add(jsonEncode({"RequestType": "StatusUpdate", "RecipientUsername": forUsername, "IDs": forMessageIds, "Status": status.name}));
  }

  void sendMessageDelete(List<String> forMessageIds, String forUsername) {
    _channel?.sink.add(jsonEncode({"RequestType": "Deletion", "RecipientUsername": forUsername, "IDs": forMessageIds}));
  }

  void disconnect() {
    _manuallyDisconnected = true;

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

  Future<bool> uploadProfile(String? displayName, Map<String, dynamic> profileObject, {String? imagePath, bool removeProfilePicture = false}) async {
    final uri = Uri.parse('$serverHTTPAddress/Accounts/Me/UploadProfile');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${data.token}';
    request.fields['DisplayName'] = displayName ?? '';
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

  void logout() async {
    get("/Auth/Logout"); // Notifies the server

    disconnect();

    data.username = null;
    data.token = null;

    await secureStorage.delete(key: "AccessToken");
    await secureStorage.delete(key: "RefreshToken");
    await Hive.box("Misc").delete("Username");

    onUnauthorized();

    MainPage.pageIndex.value = 2;
  }
}

enum ConnectionState { NotConnected, WaitingForAuthorization, Connecting, WaitingToReconnect, Connected }
