import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session_tokens.dart';

const _logPrefix = '[TokenStore]';

/// 토큰 fingerprint 생성 (SHA256 prefix 12자, 민감정보 제외 로깅용)
String _tokenFingerprint(String token) {
  final bytes = utf8.encode(token);
  final digest = sha256.convert(bytes);
  return digest.toString().substring(0, 12);
}

abstract class TokenStore {
  Future<SessionTokens?> read();
  Future<void> save(SessionTokens tokens);
  Future<void> clear();
  Future<String?> readLoginProvider();
  Future<void> saveLoginProvider(String? provider);
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'session_access_token';
  static const _refreshKey = 'session_refresh_token';
  static const _providerKey = 'session_login_provider';

  @override
  Future<SessionTokens?> read() async {
    try {
      final access = await _storage.read(key: _accessKey);
      final refresh = await _storage.read(key: _refreshKey);
      if (access == null || refresh == null) {
        // 토큰이 없는 것은 로그인 전 정상 상태이므로 로그 출력 불필요
        return null;
      }

      // ✅ SSOT 검증: 로드 직후 토큰 형태 검증 로그
      if (kDebugMode) {
        final accessLen = access.length;
        final accessJwt = access.split('.').length == 3;
        final accessFp = _tokenFingerprint(access);
        final refreshLen = refresh.length;
        final refreshJwt = refresh.split('.').length == 3;
        final refreshFp = _tokenFingerprint(refresh);
        debugPrint(
          '$_logPrefix loaded: '
          'accessLen=$accessLen, accessJwt=$accessJwt, accessFp=$accessFp, '
          'refreshLen=$refreshLen, refreshJwt=$refreshJwt, refreshFp=$refreshFp',
        );
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
      // ✅ SSOT 검증: 저장 직전 토큰 형태 검증 로그
      if (kDebugMode) {
        final accessLen = tokens.accessToken.length;
        final accessJwt = tokens.accessToken.split('.').length == 3;
        final accessFp = _tokenFingerprint(tokens.accessToken);
        final refreshLen = tokens.refreshToken.length;
        final refreshJwt = tokens.refreshToken.split('.').length == 3;
        final refreshFp = _tokenFingerprint(tokens.refreshToken);
        debugPrint(
          '$_logPrefix saving: '
          'accessLen=$accessLen, accessJwt=$accessJwt, accessFp=$accessFp, '
          'refreshLen=$refreshLen, refreshJwt=$refreshJwt, refreshFp=$refreshFp',
        );
      }

      await _storage.write(key: _accessKey, value: tokens.accessToken);
      await _storage.write(key: _refreshKey, value: tokens.refreshToken);

      if (kDebugMode) {
        debugPrint('$_logPrefix saved');
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
      await _storage.delete(key: _providerKey);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 삭제 예외: $error');
      }
    }
  }

  @override
  Future<String?> readLoginProvider() async {
    try {
      final provider = await _storage.read(key: _providerKey);
      if (provider == null || provider.isEmpty) {
        return null;
      }
      return provider;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 로그인 제공자 읽기 예외: $error');
      }
      return null;
    }
  }

  @override
  Future<void> saveLoginProvider(String? provider) async {
    try {
      if (provider == null || provider.isEmpty) {
        await _storage.delete(key: _providerKey);
        return;
      }
      await _storage.write(key: _providerKey, value: provider);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 로그인 제공자 저장 예외: $error');
      }
    }
  }
}
