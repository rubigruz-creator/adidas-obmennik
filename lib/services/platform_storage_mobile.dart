import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_service.dart';

class MobileStorageService implements StorageService {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> getString(String key) => _storage.read(key: key);

  @override
  Future<void> setString(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> remove(String key) => _storage.delete(key: key);
}
