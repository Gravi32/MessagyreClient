import 'dart:convert';
import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/secure_storage_service.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final secureStorage = SecureStorageService();
  // Do not instantiate NetworkService here: Stack overflow

  AsymmetricKeyPair? _keyPairCache;
  Future<AsymmetricKeyPair>? _loading;

  Future<RSAPublicKey> get publicKey async => (await _keyPair()).publicKey as RSAPublicKey;

  Future<RSAPrivateKey> get privateKey async => (await _keyPair()).privateKey as RSAPrivateKey;

  /// The stored key pair, or a new one. Calls made at the same time share the same work.
  Future<AsymmetricKeyPair> _keyPair() {
    final cached = _keyPairCache;
    if (cached != null) return Future.value(cached);
    return _loading ??= _loadOrGenerate().whenComplete(() => _loading = null);
  }

  Future<AsymmetricKeyPair> _loadOrGenerate() async {
    final storedPublic = await secureStorage.read(key: "RSAPublicKey");
    final storedPrivate = await secureStorage.read(key: "RSAPrivateKey");

    if (storedPublic != null && storedPublic.isNotEmpty && storedPrivate != null && storedPrivate.isNotEmpty) {
      final pair = AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
        CryptoUtils.rsaPublicKeyFromPem(storedPublic),
        CryptoUtils.rsaPrivateKeyFromPem(storedPrivate),
      );
      return _keyPairCache = pair;
    }

    debugPrint("[RSA] Generating new RSA key pair...");

    // A 2048-bit key takes seconds: in a background isolate, the app stays responsive
    final (publicPem, privatePem) = await compute(_generatePems, 2048);

    await secureStorage.write(key: "RSAPublicKey", value: publicPem);
    await secureStorage.write(key: "RSAPrivateKey", value: privatePem);

    final pair = AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(CryptoUtils.rsaPublicKeyFromPem(publicPem), CryptoUtils.rsaPrivateKeyFromPem(privatePem));
    _keyPairCache = pair;

    debugPrint("[RSA] New key pair generated and saved");
    NetworkService().uploadPublicKey();

    return pair;
  }

  static (String, String) _generatePems(int bitLength) {
    final keyGenerator = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
          SecureRandom("Fortuna")..seed(KeyParameter(Uint8List.fromList(List<int>.generate(32, (_) => Random.secure().nextInt(256))))),
        ),
      );

    final pair = keyGenerator.generateKeyPair();
    return (CryptoUtils.encodeRSAPublicKeyToPem(pair.publicKey as RSAPublicKey), CryptoUtils.encodeRSAPrivateKeyToPem(pair.privateKey as RSAPrivateKey));
  }

  // #region -> Messages

  /// Encrypts a message for its recipient: a new AES-256-GCM key per message, itself encrypted with the
  /// recipient's RSA key. The attachment's description (if any) uses the same key with its own nonce, sent as
  /// `nonce:cipherText` in base64.
  Map<String, String> encryptMessage(String content, RSAPublicKey recipientKey, {String? attachmentJson}) {
    final aesKey = _randomBytes(32);
    return {..._encryptWith(aesKey, content, attachmentJson), "EncryptedKey": _encryptKey(aesKey, recipientKey)};
  }

  /// The same for a class chat: the message is encrypted once, its key once per member ("EncryptedKeys":
  /// username → key). Each member's app reads it like a message sent to them alone.
  Map<String, Object> encryptForMany(String content, Map<String, RSAPublicKey> recipientKeys, {String? attachmentJson}) {
    final aesKey = _randomBytes(32);
    return {
      ..._encryptWith(aesKey, content, attachmentJson),
      "EncryptedKeys": {for (final MapEntry(key: username, value: key) in recipientKeys.entries) username: _encryptKey(aesKey, key)},
    };
  }

  static String _encryptKey(Uint8List aesKey, RSAPublicKey recipientKey) {
    final rsaEncryptor = OAEPEncoding(RSAEngine())..init(true, PublicKeyParameter<RSAPublicKey>(recipientKey));
    return base64.encode(rsaEncryptor.process(aesKey));
  }

  static Map<String, String> _encryptWith(Uint8List aesKey, String content, String? attachmentJson) {
    final iv = _randomBytes(12);

    final result = {
      "CipherText": base64.encode(_gcm(true, aesKey, iv, Uint8List.fromList(utf8.encode(content)))),
      "Iv": base64.encode(iv),
    };

    if (attachmentJson != null) {
      final attachmentIv = _randomBytes(12);
      final cipher = _gcm(true, aesKey, attachmentIv, Uint8List.fromList(utf8.encode(attachmentJson)));
      result["Attachment"] = "${base64.encode(attachmentIv)}:${base64.encode(cipher)}";
    }

    return result;
  }

  /// The text of a received message and the description of its attachment (null without one, or when it
  /// can't be read: the text is still shown)
  Future<(String content, String? attachmentJson)> decryptPayload(String rawCipherText, String rawIv, String rawEncryptedKey, {String? rawAttachment}) async {
    final aesKey = await _decryptKey(rawEncryptedKey);
    final content = utf8.decode(_gcm(false, aesKey, base64.decode(rawIv), base64.decode(rawCipherText)));

    String? attachmentJson;
    if (rawAttachment != null && rawAttachment.contains(':')) {
      try {
        final parts = rawAttachment.split(':');
        attachmentJson = utf8.decode(_gcm(false, aesKey, base64.decode(parts[0]), base64.decode(parts[1])));
      } catch (e) {
        debugPrint("[Encryption] An attachment couldn't be decrypted: $e");
      }
    }

    return (content, attachmentJson);
  }

  Future<Uint8List> _decryptKey(String rawEncryptedKey) async {
    final key = await privateKey;
    final rsaDecryptor = OAEPEncoding(RSAEngine())..init(false, PrivateKeyParameter<RSAPrivateKey>(key));
    return rsaDecryptor.process(base64.decode(rawEncryptedKey));
  }

  // #endregion

  // #region -> Files

  /// Encrypts a file's bytes with a new key (in a background isolate: a photo can weigh several MB)
  /// With [key] and [iv] (base64) the same file is encrypted again identically, to upload it a second time.
  static Future<({Uint8List bytes, String key, String iv})> encryptFile(Uint8List plain, {String? key, String? iv}) async {
    final keyBytes = key != null ? base64.decode(key) : _randomBytes(32);
    final ivBytes = iv != null ? base64.decode(iv) : _randomBytes(12);
    final encrypted = await compute(_gcmIsolate, (true, keyBytes, ivBytes, plain));
    return (bytes: encrypted, key: base64.encode(keyBytes), iv: base64.encode(ivBytes));
  }

  static Future<Uint8List> decryptFile(Uint8List encrypted, String key, String iv) =>
      compute(_gcmIsolate, (false, base64.decode(key), base64.decode(iv), encrypted));

  static Uint8List _gcmIsolate((bool, Uint8List, Uint8List, Uint8List) arguments) => _gcm(arguments.$1, arguments.$2, arguments.$3, arguments.$4);

  // #endregion

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  /// AES-GCM with a 128-bit tag (the format the app has always used, see decryptMessage)
  static Uint8List _gcm(bool encrypt, Uint8List key, Uint8List iv, Uint8List data) {
    final cipher = GCMBlockCipher(AESEngine())..init(encrypt, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    return cipher.process(data);
  }

  Future<String> decryptMessage(String rawCipherText, String rawIv, String rawEncryptedKey) async {
    try {
      final cipherText = base64.decode(rawCipherText);
      final iv = base64.decode(rawIv);
      final encryptedKeyBytes = base64.decode(rawEncryptedKey);

      final key = await privateKey;

      if (key.modulus == null || key.privateExponent == null) {
        throw Exception("Invalid private key: missing modulus or exponent");
      }

      final rsaDecryptor = OAEPEncoding(RSAEngine())..init(false, PrivateKeyParameter<RSAPrivateKey>(key));

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
      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw FormatException("Decryption failed: $e");
    }
  }
}
