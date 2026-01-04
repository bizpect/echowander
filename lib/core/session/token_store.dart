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
    try {
      final access = await _storage.read(key: _accessKey);
      final refresh = await _storage.read(key: _refreshKey);
      if (access == null || refresh == null) {
        // ignore: avoid_print
        print('토큰 저장소 읽기 실패: access 또는 refresh 없음');
        return null;
      }
      return SessionTokens(accessToken: access, refreshToken: refresh);
    } catch (error) {
      // ignore: avoid_print
      print('토큰 저장소 읽기 예외: $error');
      return null;
    }
  }

  @override
  Future<void> save(SessionTokens tokens) async {
    try {
      await _storage.write(key: _accessKey, value: tokens.accessToken);
      await _storage.write(key: _refreshKey, value: tokens.refreshToken);
      // ignore: avoid_print
      print('토큰 저장소 저장 완료');
    } catch (error) {
      // ignore: avoid_print
      print('토큰 저장소 저장 예외: $error');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (error) {
      // ignore: avoid_print
      print('토큰 저장소 삭제 예외: $error');
    }
  }
}
