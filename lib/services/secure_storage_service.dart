import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final storage = const FlutterSecureStorage(iOptions: IOSOptions(groupId: 'group.com.graviware.messagyre', accessibility: KeychainAccessibility.first_unlock));

  Future<String?> read({required String key}) => storage.read(key: key);
  Future<void> write({required String key, required String? value}) => storage.write(key: key, value: value);
  Future<void> delete({required String key}) => storage.delete(key: key);
}
