import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingLocalStore {
  static const _completedKey = 'onboarding_completed';
  final FlutterSecureStorage _storage;

  OnboardingLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> readCompleted() async {
    final value = await _storage.read(key: _completedKey);
    return value == 'true';
  }

  Future<void> saveCompleted() async {
    await _storage.write(key: _completedKey, value: 'true');
  }
}
