import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show BytesBuilder, Uint8List;

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/cupertino.dart' hide ConnectionState, Key;
import 'package:http/http.dart' as http;
import 'package:messagyre_client/pages/bootstrap/login_page.dart';
import 'package:messagyre_client/services/backup_service.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/services/chat_service.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/services/encryption_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/secure_storage_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
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
  final encryption = EncryptionService();
  final secureStorage = SecureStorageService();

  // Streams
  final _acknowledgementStreamController = StreamController<String>.broadcast();

  final connectionState = ValueNotifier(ConnectionState.NotConnected);
  int connectionAttempts = 0;
  WebSocketChannel? _channel;

  bool isLoginPageOpen = false;

  /// True once an account is signed in (stored token found at the start, or the login page succeeded)
  final isSignedIn = ValueNotifier(false);

  /// Waits for an account to be signed in
  Future<void> waitForSignIn() async {
    if (isSignedIn.value) return;
    final completer = Completer<void>();
    void listener() {
      if (isSignedIn.value && !completer.isCompleted) completer.complete();
    }

    isSignedIn.addListener(listener);
    await completer.future;
    isSignedIn.removeListener(listener);
  }

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
    try {
      globals.token = await secureStorage.read(key: "AccessToken");
    } catch (e) {
      debugPrint("[NetworkService] The access token couldn't be read: $e");
    }

    if (globals.token == null || globals.username == null) {
      debugPrint("[NetworkService] No token or username found in storage. Switching to LoginPage.");
      onUnauthorized();
      return;
    }

    isSignedIn.value = true;

    // Not awaited: the connection doesn't need it (and a new key pair takes a few seconds to make)
    uploadPublicKey();

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
    if (globals.token == null || isLoginPageOpen || isConnected || _isConnecting) return;

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
        headers: {'Authorization': globals.token!},
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
                _handleCommunication(element);
              }
            } else {
              _handleCommunication(receivedData);
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
      BackupService().sync(); // reads the saved copy if the start had no connection
    } catch (e, s) {
      debugPrint("[WebSocket] Connection FAILED: $e, $s");

      connectionState.value = ConnectionState.NotConnected;
      _channel = null;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  /// Sends a communication; false when there is no connection
  bool sendRaw(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) return false;
    try {
      channel.sink.add(jsonEncode(payload));
      return true;
    } catch (e) {
      debugPrint("[WebSocket] Sending failed: $e");
      return false;
    }
  }

  /// Sends a message and waits for the server to confirm it stored it (false after 10 seconds without answer)
  Future<bool> sendAndWaitForAcknowledgement(String uuid, Map<String, dynamic> payload) async {
    // Listening before sending: the acknowledgement can't be missed
    final acknowledgement = _acknowledgementStreamController.stream.firstWhere((acknowledged) => acknowledged == uuid).timeout(const Duration(seconds: 10));

    if (!sendRaw(payload)) {
      acknowledgement.ignore(); // nobody waits for it any more: its timeout must not become an uncaught error
      return false;
    }

    try {
      await acknowledgement;
      return true;
    } catch (_) {
      debugPrint("[WebSocket] Never received the server's acknowledgement for $uuid");
      return false;
    }
  }

  void _handleCommunication(Map<String, dynamic> communicationData) {
    if (communicationData["CommunicationType"] == "Acknowledgement") {
      final uuid = communicationData["Uuid"]?.toString();
      if (uuid != null) _acknowledgementStreamController.add(uuid);
      return;
    }

    ChatService().handleCommunication(communicationData);
  }

  void sendMessageDelete(List<String> forMessageUuids, String forUsername) {
    sendRaw({"CommunicationType": "Deletion", "RecipientUsername": forUsername, "Uuids": forMessageUuids});
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
            headers: {"Content-Type": "application/json", if (globals.token != null) "Authorization": globals.token!},
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
            headers: {"Content-Type": "application/json", if (globals.token != null) "Authorization": globals.token!},
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
    final uri = getBackendUri(route: "/accounts/me/upload-profile");
    final request = http.MultipartRequest("POST", uri);

    request.headers["Authorization"] = globals.token!;
    request.fields["DisplayName"] = displayName ?? "";
    request.fields["Profile"] = tryJsonEncode(profileObject);

    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath("Picture", imagePath));
    } else if (removeProfilePicture) {
      request.fields["RemoveProfilePicture"] = "true";
    }

    try {
      final response = await request.send().timeout(Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();

      debugPrint("[ProfileUpload] ${response.statusCode} $responseBody");

      if (response.statusCode != 200) {
        debugPrint("[ProfileUpload Failed] (${response.statusCode})");
        return false;
      }

      final responseJson = tryJsonDecode(responseBody) ?? [];
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

    final decoded = tryJsonDecode(response.body);
    final result = decoded is String ? decoded : null;
    globals.pfpNotifiersCache[accountUsername]?.value = result;
    return result;
  }

  Future<Account?> getAccount(String accountUsername) async {
    final response = await get("/accounts/get?Username=$accountUsername");

    if (response.statusCode != 200) {
      debugPrint("[Account Get Failed] Error ${response.statusCode}: ${response.body}");
      return null;
    }

    try {
      return Account.fromJson(response.body);
    } catch (e) {
      debugPrint("[Account Get Failed] Unreadable answer: $e");
      return null;
    }
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
    final response = await post("/analytics/upload-app-version", {"AppVersion": globals.appVersion});

    if (response.statusCode != 200) {
      debugPrint("[Network] Uploading the app version failed. Server response: ${response.statusCode} ${response.body}");
    }

    return;
  }

  Future<void> uploadPublicKey() async {
    final String stringPublicKey;
    try {
      stringPublicKey = CryptoUtils.encodeRSAPublicKeyToPem(await encryption.publicKey);
    } catch (e) {
      debugPrint("[RSA] The public key couldn't be read: $e");
      return;
    }
    final response = await post("/accounts/me/upload-public-key", {"PublicKey": stringPublicKey});

    if (response.statusCode != 200) {
      debugPrint("[RSA] Uploading the public key failed. Server response: ${response.statusCode} ${response.body}");
    }

    return;
  }

  /// The public key of a user: found, missing (an app too old to have one) or unknown (the request failed)
  Future<PublicKeyLookup> fetchPublicKey(String username) async {
    final response = await get("/accounts/get-public-key?username=${Uri.encodeQueryComponent(username)}");
    if (response.statusCode != 200) return const PublicKeyError();

    final pem = tryJsonDecode(response.body);
    if (pem is! String || pem.trim().isEmpty) return const PublicKeyMissing();

    try {
      return PublicKeyFound(CryptoUtils.rsaPublicKeyFromPem(pem));
    } catch (e) {
      debugPrint("[RSA] The public key of $username is invalid: $e");
      return const PublicKeyMissing();
    }
  }

  // Files

  /// Uploads an (already encrypted) attachment. Returns its ID, or the reason of the refusal.
  /// The access token lasts an hour: an upload or download refused with 401 is tried again once with a new one
  Future<({String? id, String? error})> uploadFile(Uint8List bytes, {required String recipientUsername, void Function(double progress)? onProgress}) async {
    final result = await _uploadFile(bytes, recipientUsername: recipientUsername, onProgress: onProgress);
    if (result.error != "Unauthorized" || (await refreshAccessToken()).statusCode != 200) return result;
    return _uploadFile(bytes, recipientUsername: recipientUsername, onProgress: onProgress);
  }

  Future<({String? id, String? error})> _uploadFile(Uint8List bytes, {required String recipientUsername, void Function(double progress)? onProgress}) async {
    final multipart = http.MultipartRequest("POST", getBackendUri(route: "/files/upload"))
      ..fields["RecipientUsername"] = recipientUsername
      ..files.add(http.MultipartFile.fromBytes("File", bytes, filename: "file.bin"));

    // A streamed copy of the request, to follow how much was sent
    final body = multipart.finalize();
    final total = multipart.contentLength;
    var sent = 0;

    final request = http.StreamedRequest("POST", multipart.url)
      ..headers.addAll(multipart.headers)
      ..headers["Authorization"] = globals.token ?? ""
      ..contentLength = total;

    body.listen(
      (chunk) {
        sent += chunk.length;
        onProgress?.call(total > 0 ? sent / total : 0);
        request.sink.add(chunk);
      },
      onDone: request.sink.close,
      onError: request.sink.addError,
      cancelOnError: true,
    );

    try {
      final response = await http.Response.fromStream(await request.send().timeout(const Duration(minutes: 5)));
      if (response.statusCode == 200) return (id: tryJsonDecode(response.body)?["ID"] as String?, error: null);
      return (
        id: null,
        error: switch (response.statusCode) {
          401 => "Unauthorized",
          507 => "StorageFull",
          _ => response.body,
        },
      );
    } catch (e) {
      debugPrint("[Files] Upload failed: $e");
      return (id: null, error: "Network");
    }
  }

  /// Downloads an attachment (still encrypted)
  Future<({int statusCode, Uint8List? bytes})> downloadFile(String fileId, {void Function(double progress)? onProgress}) async {
    final result = await _downloadFile(fileId, onProgress: onProgress);
    if (result.statusCode != 401 || (await refreshAccessToken()).statusCode != 200) return result;
    return _downloadFile(fileId, onProgress: onProgress);
  }

  Future<({int statusCode, Uint8List? bytes})> _downloadFile(String fileId, {void Function(double progress)? onProgress}) async {
    final client = http.Client();
    try {
      final request = http.Request("GET", getBackendUri(route: "/files/get?ID=$fileId"));
      if (globals.token != null) request.headers["Authorization"] = globals.token!;

      final response = await client.send(request).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return (statusCode: response.statusCode, bytes: null);

      final total = response.contentLength ?? 0;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.stream.timeout(const Duration(seconds: 60))) {
        builder.add(chunk);
        if (total > 0) onProgress?.call(builder.length / total);
      }
      return (statusCode: 200, bytes: builder.takeBytes());
    } catch (e) {
      debugPrint("[Files] Download failed: $e");
      return (statusCode: 0, bytes: null);
    } finally {
      client.close();
    }
  }

  void logout() async {
    isSignedIn.value = false;
    await BackupService().stop(); // the last changes go first, while the token is still valid
    await ClassService().forget();

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

sealed class PublicKeyLookup {
  const PublicKeyLookup();
}

class PublicKeyFound extends PublicKeyLookup {
  final RSAPublicKey key;
  const PublicKeyFound(this.key);
}

class PublicKeyMissing extends PublicKeyLookup {
  const PublicKeyMissing();
}

class PublicKeyError extends PublicKeyLookup {
  const PublicKeyError();
}
