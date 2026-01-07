import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session_tokens.dart';

const _logPrefix = '[TokenStore]';

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
    try {
      final access = await _storage.read(key: _accessKey);
      final refresh = await _storage.read(key: _refreshKey);
      if (access == null || refresh == null) {
        // 토큰이 없는 것은 로그인 전 정상 상태이므로 로그 출력 불필요
        return null;
      }
      return SessionTokens(accessToken: access, refreshToken: refresh);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 읽기 예외: $error');
      }
      return null;
    }
  }

  @override
  Future<void> save(SessionTokens tokens) async {
    try {
      await _storage.write(key: _accessKey, value: tokens.accessToken);
      await _storage.write(key: _refreshKey, value: tokens.refreshToken);
      if (kDebugMode) {
        debugPrint('$_logPrefix 저장 완료');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 저장 예외: $error');
      }
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 삭제 예외: $error');
      }
    }
  }
}
