import 'dart:convert';
import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:messagyre_client/services/network_service.dart';
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

  final secureStorage = FlutterSecureStorage();
  final network = NetworkService();

  AsymmetricKeyPair? _keyPairCache;

  Future<RSAPublicKey> get publicKey async {
    if (_keyPairCache?.publicKey != null) {
      return _keyPairCache!.publicKey as RSAPublicKey;
    }

    final storedPublic = await secureStorage.read(key: "RSAPublicKey");
    final storedPrivate = await secureStorage.read(key: "RSAPrivateKey");

    if (storedPublic != null && storedPublic.isNotEmpty && storedPrivate != null && storedPrivate.isNotEmpty) {
      final newPublicKey = CryptoUtils.rsaPublicKeyFromPem(storedPublic);
      final newPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(storedPrivate);
      _keyPairCache = AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(newPublicKey, newPrivateKey);
      return newPublicKey;
    }

    return _generateRSAKeyPair().publicKey as RSAPublicKey;
  }

  Future<RSAPrivateKey> get privateKey async {
    if (_keyPairCache?.privateKey != null) {
      return _keyPairCache!.privateKey as RSAPrivateKey;
    }

    final storedPublic = await secureStorage.read(key: "RSAPublicKey");
    final storedPrivate = await secureStorage.read(key: "RSAPrivateKey");

    if (storedPublic != null && storedPublic.isNotEmpty && storedPrivate != null && storedPrivate.isNotEmpty) {
      final newPublicKey = CryptoUtils.rsaPublicKeyFromPem(storedPublic);
      final newPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(storedPrivate);
      _keyPairCache = AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(newPublicKey, newPrivateKey);
      return newPrivateKey;
    }

    return _generateRSAKeyPair().privateKey as RSAPrivateKey;
  }

  AsymmetricKeyPair _generateRSAKeyPair({int bitLength = 2048}) {
    debugPrint("[RSA] Generating new RSA key pair...");

    final keyGenerator =
        RSAKeyGenerator()..init(
          ParametersWithRandom(
            RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
            SecureRandom("Fortuna")..seed(KeyParameter(Uint8List.fromList(List<int>.generate(32, (_) => Random.secure().nextInt(256))))),
          ),
        );

    final pair = keyGenerator.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;
    final result = AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);

    _keyPairCache = result;

    final publicPem = CryptoUtils.encodeRSAPublicKeyToPem(publicKey);
    final privatePem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);

    secureStorage.write(key: "RSAPublicKey", value: publicPem);
    secureStorage.write(key: "RSAPrivateKey", value: privatePem);

    debugPrint("[RSA] New key pair generated and saved");
    network.uploadPublicKey();

    return result;
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
