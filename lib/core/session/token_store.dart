import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session_tokens.dart';

abstract class TokenStore {
  Future<SessionTokens?> read();
  Future<void> save(SessionTokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'session_access_token';
  static const _refreshKey = 'session_refresh_token';

  @override
  Future<SessionTokens?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) {
      return null;
    }
    return SessionTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> save(SessionTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
