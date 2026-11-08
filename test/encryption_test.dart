import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:encrypt/encrypt.dart' as legacy;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/services/api/firebase_api.dart';
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

  group("Push notifications", () {
    test("show the decrypted text and the sender's name without the server's emoji", () async {
      final encrypted = EncryptionService().encryptMessage("Tu viens samedi ?", keys.publicKey);
      final content = await NotificationContent.fromData({
        "Title": "💬 Léa Martin",
        "Body": "Nouveau message !",
        "SenderUsername": "lea.martin",
        "CipherText": encrypted["CipherText"],
        "IV": encrypted["Iv"],
        "EncryptedKey": encrypted["EncryptedKey"],
      });
      expect(content.body, "Tu viens samedi ?");
      expect(content.senderName, "Léa Martin");
      expect(content.senderUsername, "lea.martin");
      expect(content.pictureUrl, isNull);
    });

    test("fall back on the server's text when the message can't be decrypted", () async {
      final content = await NotificationContent.fromData({
        "Title": "💬 Noah",
        "Body": "Nouveau message !",
        "CipherText": "AAAA",
        "IV": "AAAA",
        "EncryptedKey": "AAAA",
      });
      expect(content.body, "Nouveau message !");
    });

    test("of one conversation share the same id, different from the assignments' ones", () {
      expect(notificationIdFor("lea.martin"), notificationIdFor("lea.martin"));
      expect(notificationIdFor("lea.martin"), isNot(notificationIdFor("noah.dubois")));
      expect(notificationIdFor("a"), greaterThanOrEqualTo(1000));
    });

    // The iOS extension (NotificationService.swift) reads this PEM from the keychain: iOS only accepts the PKCS#1
    // key, which the extension takes out of the PKCS#8 envelope exactly like this
    test("the stored private key is a PKCS#8 PEM whose PKCS#1 key the iOS extension can take out", () {
      final pem = CryptoUtils.encodeRSAPrivateKeyToPem(keys.privateKey);
      final lines = const LineSplitter().convert(pem);
      expect(lines.first, "-----BEGIN PRIVATE KEY-----");
      final der = base64.decode(lines.where((line) => !line.startsWith("-----")).join().trim());

      var index = 0;
      int? readLength() {
        var length = der[index++];
        if (length & 0x80 != 0) {
          final count = length & 0x7f;
          length = 0;
          for (var i = 0; i < count; i++) {
            length = (length << 8) | der[index++];
          }
        }
        return length;
      }

      int? expectTag(int tag) => der[index] == tag ? (index++, readLength()).$2 : null;

      expect(expectTag(0x30), isNotNull);
      final versionLength = expectTag(0x02)!; // (not "index += expectTag(...)": index would be read before the call)
      index += versionLength;
      final algorithmLength = expectTag(0x30)!;
      index += algorithmLength;
      final keyLength = expectTag(0x04)!;
      final pkcs1 = der.sublist(index, index + keyLength);

      // What iOS gets (SecKeyCreateWithData): the same key, in PKCS#1
      expect(CryptoUtils.rsaPrivateKeyFromDERBytesPkcs1(Uint8List.fromList(pkcs1)).modulus, keys.privateKey.modulus);
    });
  });
}
