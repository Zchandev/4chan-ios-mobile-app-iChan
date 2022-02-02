import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Secstore {
  Secstore(this.storage);

  final FlutterSecureStorage storage;
  final Map<String, String> _cache = {};

  String getCached(String field) => _cache[field] ?? '';

  Future<String> get(String field, {String defaultValue}) async {
    final result = await storage.read(key: field);
    if (_cache[field] == null) {
      _cache[field] = result;
    }
    return result ?? defaultValue;
  }

  Future<int> getInt(String field, {int defaultValue = 0}) async {
    final result = await storage.read(key: field);

    if (result != null) {
      if (_cache[field] == null) {
        _cache[field] = result;
      }
      return int.tryParse(result) ?? defaultValue;
    } else {
      return defaultValue;
    }
  }

  Future<void> put(String field, String value) async {
    _cache[field] = value;
    return await storage.write(key: field, value: value);
  }

  Future<void> delete(String field) async {
    _cache.remove(field);
    return await storage.delete(key: field);
  }
}
