import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:encrypt/encrypt.dart' as legacy;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/services/encryption_service.dart';
import 'package:pointycastle/export.dart';

/// The key pair of "this phone", stored where EncryptionService looks for it
AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> installKeyPair() {
  final generator = RSAKeyGenerator()
    ..init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        FortunaRandom()..seed(KeyParameter(Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256))))),
      ),
    );
  final pair = generator.generateKeyPair();
  final publicKey = pair.publicKey as RSAPublicKey, privateKey = pair.privateKey as RSAPrivateKey;
  FlutterSecureStorage.setMockInitialValues({
    "RSAPublicKey": CryptoUtils.encodeRSAPublicKeyToPem(publicKey),
    "RSAPrivateKey": CryptoUtils.encodeRSAPrivateKeyToPem(privateKey),
  });
  return AsymmetricKeyPair(publicKey, privateKey);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keys;

  setUpAll(() => keys = installKeyPair());

  test("a message from an app before 4.0 (encrypt package) is still decrypted", () async {
    // Exactly what network_service.dart did up to 3.83
    final aesKey = legacy.Key.fromSecureRandom(32);
    final iv = legacy.IV.fromSecureRandom(12);
    final encrypted = legacy.Encrypter(legacy.AES(aesKey, mode: legacy.AESMode.gcm)).encrypt("Salut 👋, ça va ?", iv: iv);
    final encryptedKey = (OAEPEncoding(RSAEngine())..init(true, PublicKeyParameter<RSAPublicKey>(keys.publicKey))).process(aesKey.bytes);

    final (content, attachment) = await EncryptionService().decryptPayload(encrypted.base64, base64.encode(iv.bytes), base64.encode(encryptedKey));
    expect(content, "Salut 👋, ça va ?");
    expect(attachment, isNull);
  });

  test("a message from 4.0 is readable by the decryption of older apps, and carries its attachment", () async {
    final service = EncryptionService();
    final payload = service.encryptMessage("📷 Photo", keys.publicKey, attachmentJson: '{"Name":"photo.jpg"}');

    // Older apps only use these three fields (and ignore "Attachment")
    expect(await service.decryptMessage(payload["CipherText"]!, payload["Iv"]!, payload["EncryptedKey"]!), "📷 Photo");

    final (content, attachment) = await service.decryptPayload(payload["CipherText"]!, payload["Iv"]!, payload["EncryptedKey"]!, rawAttachment: payload["Attachment"]);
    expect(content, "📷 Photo");
    expect(attachment, '{"Name":"photo.jpg"}');
  });

  test("files are encrypted and decrypted, and encrypting again with the same key gives the same bytes", () async {
    final plain = Uint8List.fromList(List.generate(300 * 1024, (i) => i % 251));
    final encrypted = await EncryptionService.encryptFile(plain);
    expect(encrypted.bytes.length, plain.length + 16); // GCM tag
    expect(encrypted.bytes.sublist(0, 64), isNot(plain.sublist(0, 64)));

    expect(await EncryptionService.decryptFile(encrypted.bytes, encrypted.key, encrypted.iv), plain);

    final again = await EncryptionService.encryptFile(plain, key: encrypted.key, iv: encrypted.iv);
    expect(again.bytes, encrypted.bytes);
  });

  test("a tampered file is refused", () async {
    final encrypted = await EncryptionService.encryptFile(Uint8List.fromList(utf8.encode("devoir de maths")));
    encrypted.bytes[3] ^= 0xFF;
    expect(() => EncryptionService.decryptFile(encrypted.bytes, encrypted.key, encrypted.iv), throwsA(anything));
  });
}
