import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdStore {
  DeviceIdStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _deviceIdKey = 'push_device_id';
  final FlutterSecureStorage _storage;

  Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = _generateId();
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}
