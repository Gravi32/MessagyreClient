import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/cupertino.dart' hide ConnectionState, Key;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/pages/bootstrap/login_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class NetworkService {
  // Configuration
  bool isLocalhost = false;

  // Declaring this singleton
  static final _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  // Singletons
  final globals = GlobalsService();
  final database = DatabaseService();
  final secureStorage = FlutterSecureStorage();

  // Streams
  final messageStreamController = StreamController<(String sender, Message message)>.broadcast();
  final messageStatusUpdateStreamController = StreamController<(String sender, Message message)>.broadcast();
  final messageDeletionStreamController = StreamController<(String sender, Message message)>.broadcast();

  final connectionState = ValueNotifier(ConnectionState.NotConnected);
  int connectionAttempts = 0;
  WebSocketChannel? _channel;

  bool isLoginPageOpen = false;

  // #region -> Initialization

  dynamic getBackendUri({String? route, bool useWebsocket = false, bool forceLocalhost = false}) {
    final useLocalhost = isLocalhost || forceLocalhost;

    if (useWebsocket) {
      return useLocalhost ? "ws://192.168.1.230:5067" : "wss://api.gravi.dev/messagyre/";
    }

    final url = useLocalhost ? "http://192.168.1.230:5067${route ?? ""}" : "https://api.gravi.dev/messagyre${route ?? ""}";
    return Uri.parse(url);
  }

  Future<void> checkLocalhostAvailability() async {
    debugPrint("[Boot] Checking for a localhost backend...");
    final response = await get("/ping", forceLocalhost: true, timeout: 1);

    if (response.statusCode == 200) isLocalhost = true;

    return;
  }

  Future<void> start() async {
    globals.token = await secureStorage.read(key: "AccessToken");

    if (globals.token == null || globals.username == null) {
      debugPrint("[NetworkService] No token or username found in storage. Switching to LoginPage.");
      onUnauthorized();
      return;
    }

    await uploadPublicKey();

    await connect();
  }
  // #endregion

  // #region -> WebSocket handling

  bool get isConnected => _channel != null;
  bool _manuallyDisconnected = false;
  bool _isConnecting = false;

  void onUnauthorized() {
    if (isLoginPageOpen || navigatorKey.currentState?.widget is LoginPage) return;
    isLoginPageOpen = true;
    navigatorKey.currentState?.push(
      PageRouteBuilder(transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero, pageBuilder: (_, _, _) => const LoginPage()),
    );
  }

  void _scheduleReconnect() {
    if (isConnected || _isConnecting) return;

    connectionState.value = ConnectionState.WaitingToReconnect;

    final delay = connectionAttempts == 0 ? 1 : min(5 * connectionAttempts, 30);
    connectionAttempts++;

    debugPrint("[WebSocket] Reconnecting in $delay seconds... (attempt #$connectionAttempts)");

    Future.delayed(Duration(seconds: delay), () {
      if (!isConnected && !_isConnecting) connect();
    });
  }

  Future<void> connect() async {
    if (isLoginPageOpen) {
      debugPrint("[WebSocket] Tried to connect while on LoginPage.");
      return;
    }

    if (isConnected) {
      debugPrint("[WebSocket] Already connected, ignoring connect() call");
      return;
    }
    if (_isConnecting) {
      debugPrint("[WebSocket] Connection already in progress, ignoring connect() call");
      return;
    }

    if (!(connectionState.value == ConnectionState.NotConnected || connectionState.value == ConnectionState.WaitingToReconnect)) {
      debugPrint("[WebSocket] Invalid state for connection: ${connectionState.value}");
      return;
    }

    _isConnecting = true;
    bool shouldScheduleReconnect = false;

    // Asking the server to refresh the token
    try {
      connectionState.value = ConnectionState.WaitingForAuthorization;

      // No token stored, either the first time on the app or logged out
      if (globals.token == null) {
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
        throw Exception("Token refresh failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("[WebSocket] Token refresh failed: $e");
      connectionState.value = ConnectionState.NotConnected;
      _isConnecting = false;
      if (shouldScheduleReconnect) _scheduleReconnect();
      return;
    }

    // Attemping a connection
    try {
      connectionState.value = ConnectionState.Connecting;
      debugPrint("[WebSocket] Connecting to ${getBackendUri(useWebsocket: true).toString()}...");

      final socket = await WebSocket.connect(
        getBackendUri(useWebsocket: true),
        headers: {'Authorization': 'Bearer ${globals.token}'},
      ).timeout(const Duration(seconds: 40));

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
          debugPrint("[WebSocket] Disconnected by the server: ${_channel?.closeCode} ${_channel?.closeReason}");
          _channel = null;
          connectionState.value = ConnectionState.NotConnected;
          _isConnecting = false;

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
          _isConnecting = false;
          _scheduleReconnect();
        },
      );

      connectionState.value = ConnectionState.Connected;
      connectionAttempts = 0;
      _isConnecting = false;
      debugPrint("[WebSocket] Connected successfully!");

      uploadAppVersion();
    } catch (e) {
      debugPrint("[WebSocket] Connection FAILED: $e");

      connectionState.value = ConnectionState.NotConnected;
      _channel = null;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void send(String id, String recipientUsername, RSAPublicKey? recipientPublicKeyPem, String messageContent) {
    if (!isConnected) return;

    Map<String, dynamic> payload = {"RequestType": "Message", "ID": id, "RecipientUsername": recipientUsername};

    if (recipientPublicKeyPem != null) {
      final aesKey = Key.fromSecureRandom(32); // 32 bytes = 256 bit
      final iv = IV.fromSecureRandom(12); // 12 bytes for GCM

      final encrypter = Encrypter(AES(aesKey, mode: AESMode.gcm));
      final encryptedMessage = encrypter.encrypt(messageContent, iv: iv);

      final rsaEncryptor = OAEPEncoding(RSAEngine())..init(true, PublicKeyParameter<RSAPublicKey>(recipientPublicKeyPem));

      final encryptedKeyBytes = rsaEncryptor.process(aesKey.bytes);

      final base64CipherText = encryptedMessage.base64;
      final base64IV = base64.encode(iv.bytes);
      final base64EncryptedKey = base64.encode(encryptedKeyBytes);

      payload.addAll({"CipherText": base64CipherText, "IV": base64IV, "EncryptedKey": base64EncryptedKey});
    } else {
      payload["Content"] = messageContent;
    }

    _channel?.sink.add(jsonEncode(payload));
  }

  void _handleMessage(Map<String, dynamic> rawMessageData) async {
    // On message received
    void onMessageReceived(String senderUsername, Map<String, dynamic> messageData) {
      var receivedMessage = Message.fromMessageData(messageData);
      var targetChat = database.chats.getByUsername(senderUsername);

      if (targetChat == null) {
        targetChat = Chat.custom(username: senderUsername);
        targetChat.unreadMessages = 1;
      } else {
        targetChat.unreadMessages += 1;
      }

      database.chats.addMessage(targetChat, receivedMessage);

      messageStreamController.add((senderUsername, receivedMessage));
    }

    // On message status update received
    void onMessageStatusUpdateReceived(String senderUsername, String uuid, MessageStatus status) {
      final targetChat = database.chats.getByUsername(senderUsername);
      if (targetChat == null) return;

      final targetMessage = database.messages.getByUuid(uuid);
      if (targetMessage == null) return;

      targetMessage.status = status;

      database.messages.save(targetMessage);

      messageStatusUpdateStreamController.add((senderUsername, targetMessage));
    }

    // On message deletion received
    void onMessageDeletionReceived(String senderUsername, String uuid) {
      final targetChat = database.chats.getByUsername(senderUsername);
      if (targetChat == null) return;

      final targetMessage = database.messages.getByUuid(uuid);
      if (targetMessage == null) return;

      targetMessage.isDeleted = true;

      database.messages.save(targetMessage);

      messageDeletionStreamController.add((senderUsername, targetMessage));
    }

    try {
      final sender = rawMessageData["SenderUsername"]?.toString();
      final isMessageStatusUpdate = rawMessageData.containsKey("Status") && rawMessageData["Status"] != null;
      final isMessageDeletion = rawMessageData.containsKey("Deletion") && rawMessageData["Deletion"] == true;

      if (sender == null) throw FormatException("Missing SenderUsername");
      if (globals.blockedUsers.contains(sender)) return;

      final messageId = rawMessageData["ID"]?.toString();

      if (isMessageStatusUpdate) {
        final status = MessageStatus.values.firstWhere((status) => status.name == rawMessageData["Status"]?.toString(), orElse: () => MessageStatus.Failed);

        if (messageId == null) throw FormatException("Missing Message ID");

        onMessageStatusUpdateReceived(sender, messageId, status);
      } else if (isMessageDeletion) {
        if (messageId == null) throw FormatException("Missing Message ID");

        onMessageDeletionReceived(sender, messageId);
      } else {
        final rawSentAt = rawMessageData["SentAt"]?.toString();
        if (rawSentAt == null) throw FormatException("Missing SentAt");

        String content;

        final hasCipherText = rawMessageData.containsKey("CipherText") && rawMessageData["CipherText"] != null;
        final hasIV = rawMessageData.containsKey("IV") && rawMessageData["IV"] != null;
        final hasEncryptedKey = rawMessageData.containsKey("EncryptedKey") && rawMessageData["EncryptedKey"] != null;

        if (hasCipherText && hasIV && hasEncryptedKey) {
          try {
            final cipherText = base64.decode(rawMessageData["CipherText"]);
            final iv = base64.decode(rawMessageData["IV"]);
            final encryptedKeyString = rawMessageData["EncryptedKey"] as String;

            final encryptedKeyBytes = base64.decode(encryptedKeyString);

            final privateKey = await globals.privateKey;

            if (privateKey.modulus == null || privateKey.privateExponent == null) {
              throw Exception("Invalid private key: missing modulus or exponent");
            }

            final rsaDecryptor = OAEPEncoding(RSAEngine())..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

            final aesKeyBytes = rsaDecryptor.process(encryptedKeyBytes);

            final cipher = GCMBlockCipher(AESEngine())..init(
              false,
              AEADParameters(
                KeyParameter(aesKeyBytes),
                128, // tag length in bits
                iv,
                Uint8List(0), // additional data
              ),
            );

            final decryptedBytes = cipher.process(cipherText);
            content = utf8.decode(decryptedBytes);
          } catch (e) {
            throw FormatException("Decryption failed: $e");
          }
        } else {
          final plain = rawMessageData["Content"]?.toString();
          if (plain == null) throw FormatException("Missing Content");
          content = plain;
        }

        final sentAt = DateTime.parse(rawSentAt).toLocal();

        onMessageReceived(sender, {"ID": messageId ?? Uuid().v4(), "SenderUsername": sender, "Content": content, "SentAt": sentAt});

        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint("[WebSocket] Invalid message format: $e");
    }
  }

  void sendMessageStatusUpdate(List<String> forMessageIds, String forUsername, MessageStatus status) {
    if (!isConnected) return;

    _channel?.sink.add(jsonEncode({"RequestType": "StatusUpdate", "RecipientUsername": forUsername, "IDs": forMessageIds, "Status": status.name}));
  }

  void sendMessageDelete(List<String> forMessageIds, String forUsername) {
    if (!isConnected) return;

    _channel?.sink.add(jsonEncode({"RequestType": "Deletion", "RecipientUsername": forUsername, "IDs": forMessageIds}));
  }

  void disconnect() {
    _manuallyDisconnected = true;
    _isConnecting = false;

    _channel?.sink.close();
    _channel = null;
    connectionState.value = ConnectionState.NotConnected;
    debugPrint("[WebSocket] Connection closed manually");
  }

  // #endregion

  // #region -> HTTP handling

  // HTTP Shorthands

  Future<http.Response> post(String route, Object body, {int timeout = 30}) async {
    try {
      final response = await http
          .post(
            getBackendUri(route: route),
            headers: {"Content-Type": "application/json", if (globals.token != null) "Authorization": "Bearer ${globals.token!}"},
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

  Future<http.Response> get(String route, {int timeout = 30, bool forceLocalhost = false}) async {
    try {
      final response = await http
          .get(
            getBackendUri(route: route, forceLocalhost: forceLocalhost),
            headers: {"Content-Type": "application/json", if (globals.token != null) "Authorization": "Bearer ${globals.token!}"},
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
    final uri = getBackendUri(route: "messagyre/Accounts/Me/UploadProfile");
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${globals.token}';
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
        globals.pfpNotifiersCache[globals.username]?.value = updatedPfpUrl;
      }

      return true;
    } catch (e) {
      debugPrint("[ProfileUpload Failed] $e");
      return false;
    }
  }

  Future<String?> getProfilePicture(String accountUsername) async {
    final response = await get("/accounts/get-profile-picture-url?Username=$accountUsername");

    if (response.statusCode != 200) {
      if (response.statusCode != 404) {
        debugPrint("[PFP Get Failed] Error ${response.statusCode} (${response.body})");
      }
      return null;
    }

    final result = json.decode(response.body) as String?;
    globals.pfpNotifiersCache[accountUsername]?.value = result;
    return result;
  }

  Future<Account?> getAccount(String accountUsername) async {
    final response = await get("/accounts/get?Username=$accountUsername");

    if (response.statusCode != 200) {
      debugPrint("[Account Get Failed] Error ${response.statusCode}: ${response.body}");
      return null;
    }

    final result = Account.fromJson(response.body);

    return result;
  }

  Future<http.Response> refreshAccessToken() async {
    final refreshToken = await secureStorage.read(key: "RefreshToken");

    if (refreshToken == null) {
      debugPrint("[RefreshToken] No refresh token found in SecureStorage.");
      return http.Response("No refresh token found in SecureStorage.", 401);
    }

    final response = await post("/auth/refresh", {"RefreshToken": refreshToken}).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint("[RefreshToken] Request timed out");
        throw Exception("Refresh token request timed out");
      },
    );

    if (response.statusCode == 200) {
      try {
        final results = jsonDecode(response.body);
        globals.token = results["AccessToken"];

        await secureStorage.write(key: "AccessToken", value: globals.token);
        await secureStorage.write(key: "RefreshToken", value: results["RefreshToken"]);
      } catch (e) {
        debugPrint("[RefreshToken] Failed decoding server response: ${response.body} -> $e");
      }

      return http.Response("OK", 200);
    }

    debugPrint("[RefreshToken] Refresh failed with status ${response.statusCode}: ${response.body}");
    return response;
  }

  Future<void> uploadAppVersion() async {
    final response = await post("/accounts/me/upload-app-version", {"AppVersion": globals.appVersion});

    if (response.statusCode != 200) {
      debugPrint("[Network] Uploading the app version failed. Server response: ${response.statusCode} ${response.body}");
    }

    return;
  }

  Future<void> uploadPublicKey() async {
    final stringPublicKey = CryptoUtils.encodeRSAPublicKeyToPem(await globals.publicKey);
    final response = await post("/accounts/me/upload-public-key", {"PublicKey": stringPublicKey});

    if (response.statusCode != 200) {
      debugPrint("[RSA] Uploading the public key failed. Server response: ${response.statusCode} ${response.body}");
    }

    return;
  }

  Future<RSAPublicKey?> getPublicKey(String username) async {
    final response = await get("/accounts/get-public-key?of=$username");

    if (response.statusCode != 200 || response.body.isEmpty) return null;

    try {
      String pemKey = jsonDecode(response.body);
      return CryptoUtils.rsaPublicKeyFromPem(pemKey);
    } catch (e) {
      return null;
    }
  }

  void logout() async {
    get("/auth/logout"); // Notifies the server

    disconnect();

    globals.username = null;
    globals.token = null;

    await secureStorage.delete(key: "AccessToken");
    await secureStorage.delete(key: "RefreshToken");
    await secureStorage.delete(key: "PublicKey");
    await secureStorage.delete(key: "PrivateKey");
    globals.persistent.remove("Username");

    onUnauthorized();

    MainPage.pageIndex.value = 2;
  }

  // #endregion
}

enum ConnectionState { NotConnected, WaitingForAuthorization, Connecting, WaitingToReconnect, Connected }
