import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';
import '../network/network_error.dart';
import '../network/network_guard.dart';
import 'session_tokens.dart';

const _logPrefix = '[AuthRpcClient]';

abstract class AuthRpcClient {
  Future<bool> validateSession(SessionTokens tokens);
  Future<SessionTokens?> refreshSession(SessionTokens tokens);
  Future<AuthRpcLoginResult> exchangeSocialToken({
    required String provider,
    required String idToken,
  });
}

enum AuthRpcLoginError {
  missingPayload,
  unsupportedProvider,
  invalidToken,
  userSyncFailed,
  serverMisconfigured,
  network,
  unknown,
}

class AuthRpcLoginResult {
  const AuthRpcLoginResult._({this.tokens, this.error});

  final SessionTokens? tokens;
  final AuthRpcLoginError? error;

  const AuthRpcLoginResult.success(SessionTokens tokens)
      : this._(tokens: tokens, error: null);
  const AuthRpcLoginResult.failure(AuthRpcLoginError error)
      : this._(tokens: null, error: error);
}

class DevAuthRpcClient implements AuthRpcClient {
  @override
  Future<bool> validateSession(SessionTokens tokens) async {
    return tokens.accessToken.isNotEmpty;
  }

  @override
  Future<SessionTokens?> refreshSession(SessionTokens tokens) async {
    return tokens;
  }

  @override
  Future<AuthRpcLoginResult> exchangeSocialToken({
    required String provider,
    required String idToken,
  }) async {
    return const AuthRpcLoginResult.success(
      SessionTokens(accessToken: 'dev', refreshToken: 'dev'),
    );
  }
}

class HttpAuthRpcClient implements AuthRpcClient {
  HttpAuthRpcClient({required String baseUrl, required AppConfig config})
      : _baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
        _errorLogger = ServerErrorLogger(config: config),
        _networkGuard = NetworkGuard(errorLogger: ServerErrorLogger(config: config)),
        _client = HttpClient();

  final Uri _baseUri;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  Uri _resolve(String path) => _baseUri.resolve(path);

  /// 공통 POST JSON 요청 (NetworkGuard 경유)
  Future<Map<String, dynamic>?> _postJson({
    required String context,
    required Uri uri,
    required Map<String, dynamic> body,
    required String token,
    RetryPolicy retryPolicy = RetryPolicy.short,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final result = await _networkGuard.execute<Map<String, dynamic>>(
        operation: () => _executePostJson(
          uri: uri,
          body: body,
          token: token,
          context: context,
        ),
        retryPolicy: retryPolicy,
        context: context,
        uri: uri,
        method: 'POST',
        meta: meta ?? const {},
        accessToken: token,
      );
      return result;
    } on NetworkRequestException catch (_) {
      // 인증 API 실패는 null 반환 (기존 시그니처 유지)
      return null;
    }
  }

  /// POST JSON 요청 실제 실행 (NetworkGuard가 호출)
  Future<Map<String, dynamic>> _executePostJson({
    required Uri uri,
    required Map<String, dynamic> body,
    required String token,
    required String context,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    if (token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    request.add(utf8.encode(jsonEncode(body)));

    final response = await request.close();
    final payloadText = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: context,
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: payloadText,
        meta: const {},
        accessToken: token,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: payloadText,
        context: context,
      );
    }

    try {
      return jsonDecode(payloadText) as Map<String, dynamic>;
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: context,
        uri: uri,
        method: 'POST',
        error: error,
        errorMessage: payloadText,
        meta: const {},
        accessToken: token,
      );
      throw const NetworkRequestException(
        type: NetworkErrorType.invalidPayload,
        message: 'Invalid JSON response',
      );
    }
  }

  @override
  Future<bool> validateSession(SessionTokens tokens) async {
    if (kDebugMode) {
      debugPrint('$_logPrefix validateSession 시작');
    }
    final payload = await _postJson(
      context: 'auth_validate_session',
      uri: _resolve('validate_session'),
      body: {'refreshToken': tokens.refreshToken},
      token: tokens.accessToken,
    );
    final isValid = payload?['valid'] == true;
    if (kDebugMode) {
      if (payload == null) {
        debugPrint('$_logPrefix validateSession 실패: 네트워크/서버 오류 (payload=null)');
      } else {
        debugPrint('$_logPrefix validateSession 결과: valid=$isValid');
      }
    }
    return isValid;
  }

  @override
  Future<SessionTokens?> refreshSession(SessionTokens tokens) async {
    if (kDebugMode) {
      debugPrint('$_logPrefix refreshSession 시작');
    }
    final payload = await _postJson(
      context: 'auth_refresh_session',
      uri: _resolve('refresh_session'),
      body: {'refreshToken': tokens.refreshToken},
      token: tokens.accessToken,
    );
    if (payload == null) {
      if (kDebugMode) {
        debugPrint('$_logPrefix refreshSession 실패: 네트워크/서버 오류 또는 인증 실패');
      }
      return null;
    }
    if (kDebugMode) {
      debugPrint('$_logPrefix refreshSession 성공');
    }
    return SessionTokens(
      accessToken: payload['accessToken'] as String,
      refreshToken: payload['refreshToken'] as String,
    );
  }

  @override
  Future<AuthRpcLoginResult> exchangeSocialToken({
    required String provider,
    required String idToken,
  }) async {
    final uri = _resolve('login_social');

    try {
      // NetworkGuard를 통한 요청 실행 (인증: 재시도 없음)
      final result = await _networkGuard.execute<AuthRpcLoginResult>(
        operation: () => _executeExchangeSocialToken(
          uri: uri,
          provider: provider,
          idToken: idToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'auth_login_social',
        uri: uri,
        method: 'POST',
        meta: {'provider': provider},
        accessToken: '',
      );
      return result;
    } on NetworkRequestException catch (error) {
      // NetworkRequestException을 AuthRpcLoginError로 변환
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          return const AuthRpcLoginResult.failure(AuthRpcLoginError.network);
        case NetworkErrorType.unauthorized:
          return const AuthRpcLoginResult.failure(AuthRpcLoginError.invalidToken);
        case NetworkErrorType.invalidPayload:
          return const AuthRpcLoginResult.failure(AuthRpcLoginError.missingPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
          // 서버 거부 메시지에서 상세 에러 코드 추출 시도
          final errorCode = _extractErrorCode(error.message ?? '');
          return AuthRpcLoginResult.failure(_mapLoginError(errorCode));
        case NetworkErrorType.missingConfig:
          return const AuthRpcLoginResult.failure(AuthRpcLoginError.serverMisconfigured);
        case NetworkErrorType.unknown:
          return const AuthRpcLoginResult.failure(AuthRpcLoginError.unknown);
      }
    }
  }

  /// exchangeSocialToken 실제 실행 (NetworkGuard가 호출)
  Future<AuthRpcLoginResult> _executeExchangeSocialToken({
    required Uri uri,
    required String provider,
    required String idToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.add(utf8.encode(jsonEncode({'provider': provider, 'idToken': idToken})));

    final response = await request.close();
    final payloadText = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'auth_login_social',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: payloadText,
        meta: {'provider': provider},
        accessToken: '',
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: payloadText,
        context: 'auth_login_social',
      );
    }

    try {
      final payload = jsonDecode(payloadText) as Map<String, dynamic>;
      return AuthRpcLoginResult.success(
        SessionTokens(
          accessToken: payload['accessToken'] as String,
          refreshToken: payload['refreshToken'] as String,
        ),
      );
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'auth_login_social',
        uri: uri,
        method: 'POST',
        error: error,
        errorMessage: payloadText,
        meta: {'provider': provider},
        accessToken: '',
      );
      throw const NetworkRequestException(
        type: NetworkErrorType.invalidPayload,
        message: 'Invalid JSON response',
      );
    }
  }

  String? _extractErrorCode(String payloadText) {
    try {
      final payload = jsonDecode(payloadText) as Map<String, dynamic>;
      final error = payload['error'];
      if (error is String) {
        return error;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  AuthRpcLoginError _mapLoginError(String? errorCode) {
    switch (errorCode) {
      case 'missing_payload':
        return AuthRpcLoginError.missingPayload;
      case 'unsupported_provider':
        return AuthRpcLoginError.unsupportedProvider;
      case 'invalid_token':
        return AuthRpcLoginError.invalidToken;
      case 'user_sync_failed':
        return AuthRpcLoginError.userSyncFailed;
      case 'missing_secret':
        return AuthRpcLoginError.serverMisconfigured;
      default:
        return AuthRpcLoginError.unknown;
    }
  }
}
