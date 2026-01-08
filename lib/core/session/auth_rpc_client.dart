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

  /// 세션 갱신 (인증 실패 확정 vs 일시 장애 구분)
  Future<RefreshResult> refreshSession(SessionTokens tokens);

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

/// refresh/validate 결과 타입: 인증 실패 확정 vs 일시 장애 구분
sealed class RefreshResult {
  const RefreshResult();

  /// 성공: 새 토큰 발급
  const factory RefreshResult.success(SessionTokens tokens) = RefreshSuccess;

  /// 인증 실패 확정: refresh 토큰 만료/무효 (401/403 확정)
  /// → 토큰 clear + unauthenticated (로그아웃)
  const factory RefreshResult.authFailed() = RefreshAuthFailed;

  /// 일시 장애: 네트워크/서버 문제 (timeout, 5xx, offline 등)
  /// → 토큰 유지 + authenticated 유지 (로그아웃 금지)
  const factory RefreshResult.transientError() = RefreshTransientError;
}

class RefreshSuccess extends RefreshResult {
  const RefreshSuccess(this.tokens);
  final SessionTokens tokens;
}

class RefreshAuthFailed extends RefreshResult {
  const RefreshAuthFailed();
}

class RefreshTransientError extends RefreshResult {
  const RefreshTransientError();
}

class DevAuthRpcClient implements AuthRpcClient {
  @override
  Future<bool> validateSession(SessionTokens tokens) async {
    return tokens.accessToken.isNotEmpty;
  }

  @override
  Future<RefreshResult> refreshSession(SessionTokens tokens) async {
    return RefreshResult.success(tokens);
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
      _config = config,
      _errorLogger = ServerErrorLogger(config: config),
      _networkGuard = NetworkGuard(
        errorLogger: ServerErrorLogger(config: config),
      ),
      _client = HttpClient();

  final Uri _baseUri;
  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  Uri _resolve(String path) => _baseUri.resolve(path);

  /// Supabase Auth REST refresh 요청 실제 실행 (NetworkGuard가 호출)
  Future<Map<String, dynamic>> _executeAuthRefresh({
    required Uri uri,
    required String refreshToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    // Supabase Auth REST 필수 헤더
    request.headers.set('apikey', _config.supabaseAnonKey);
    // Authorization: Bearer anonKey (권장 안전장치)
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${_config.supabaseAnonKey}',
    );
    request.add(utf8.encode(jsonEncode({'refresh_token': refreshToken})));

    final response = await request.close();
    final payloadText = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'auth_refresh_session',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: payloadText,
        meta: const {},
        accessToken: '', // 민감정보 제외
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: payloadText,
        context: 'auth_refresh_session',
      );
    }

    try {
      return jsonDecode(payloadText) as Map<String, dynamic>;
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'auth_refresh_session',
        uri: uri,
        method: 'POST',
        error: error,
        errorMessage: payloadText,
        meta: const {},
        accessToken: '',
      );
      throw const NetworkRequestException(
        type: NetworkErrorType.invalidPayload,
        message: 'Invalid JSON response',
      );
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
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    // Supabase Edge Functions 필수 헤더: apikey
    request.headers.set('apikey', _config.supabaseAnonKey);
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

    final uri = _resolve('validate_session');

    try {
      final result = await _networkGuard.execute<Map<String, dynamic>>(
        operation: () => _executePostJson(
          uri: uri,
          body: {'refreshToken': tokens.refreshToken},
          token: tokens.accessToken,
          context: 'auth_validate_session',
        ),
        retryPolicy: RetryPolicy.short,
        context: 'auth_validate_session',
        uri: uri,
        method: 'POST',
        meta: const {},
        accessToken: tokens.accessToken,
      );

      final isValid = result['valid'] == true;
      if (kDebugMode) {
        debugPrint('$_logPrefix validateSession 결과: valid=$isValid');
      }
      return isValid;
    } on NetworkRequestException catch (error) {
      // 에러 유형별 로깅 (401은 정상적인 "토큰 만료" 상황)
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix validateSession 실패: ${error.type} (statusCode=${error.statusCode})',
        );
      }
      // 401/403은 "토큰 만료/무효"로 간주 → false 반환 (refreshSession으로 진행)
      // 다른 에러도 false 반환 (refreshSession에서 다시 시도)
      return false;
    }
  }

  @override
  Future<RefreshResult> refreshSession(SessionTokens tokens) async {
    if (kDebugMode) {
      debugPrint('$_logPrefix refreshSession 시작 (Supabase Auth REST)');
    }

    // Supabase Auth REST endpoint 사용 (verify_jwt 설정과 무관)
    final supabaseUrl = _config.supabaseUrl;
    if (supabaseUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix refreshSession 실패: supabaseUrl 없음');
      }
      return const RefreshResult.transientError();
    }

    final uri = Uri.parse(
      supabaseUrl,
    ).resolve('/auth/v1/token?grant_type=refresh_token');

    try {
      // Supabase Auth REST: refresh_token 기반, 만료된 accessToken 불필요
      final result = await _networkGuard.execute<Map<String, dynamic>>(
        operation: () =>
            _executeAuthRefresh(uri: uri, refreshToken: tokens.refreshToken),
        retryPolicy: RetryPolicy.short,
        context: 'auth_refresh_session',
        uri: uri,
        method: 'POST',
        meta: const {},
        accessToken: '', // 로깅용도 빈 문자열
      );

      if (kDebugMode) {
        debugPrint('$_logPrefix refreshSession 성공');
      }

      // 응답 파싱: access_token, refresh_token (null-safe, rotation 대응)
      final accessToken = result['access_token'] as String?;
      final refreshToken = result['refresh_token'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        if (kDebugMode) {
          debugPrint('$_logPrefix refreshSession 응답에 access_token 없음');
        }
        return const RefreshResult.transientError();
      }

      // refresh_token이 없으면 기존 토큰 유지 (rotation 미적용 시)
      final newRefreshToken = refreshToken ?? tokens.refreshToken;

      return RefreshResult.success(
        SessionTokens(accessToken: accessToken, refreshToken: newRefreshToken),
      );
    } on NetworkRequestException catch (error) {
      // 에러 타입에 따라 "인증 실패 확정" vs "일시 장애" 분류
      // 응답 바디에서 에러 코드 추출 (민감정보 제외)
      final errorCode = _extractErrorCode(error.message ?? '');
      switch (error.type) {
        case NetworkErrorType.unauthorized:
          // 401/403: refresh 토큰 만료/무효 → 인증 실패 확정
          if (kDebugMode) {
            debugPrint(
              '$_logPrefix refreshSession 인증 실패 확정 '
              '(status=${error.statusCode}, error=$errorCode)',
            );
          }
          return const RefreshResult.authFailed();

        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
        case NetworkErrorType.serverUnavailable:
          // 네트워크/서버 일시 장애 → 토큰 유지
          if (kDebugMode) {
            debugPrint(
              '$_logPrefix refreshSession 일시 장애 '
              '(type=${error.type}, status=${error.statusCode}, error=$errorCode)',
            );
          }
          return const RefreshResult.transientError();

        case NetworkErrorType.invalidPayload:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          // 기타 오류: 일시 장애로 처리 (로그아웃 금지)
          if (kDebugMode) {
            debugPrint(
              '$_logPrefix refreshSession 기타 오류 '
              '(type=${error.type}, status=${error.statusCode}, error=$errorCode) → 일시 장애로 처리',
            );
          }
          return const RefreshResult.transientError();
      }
    }
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
          return const AuthRpcLoginResult.failure(
            AuthRpcLoginError.invalidToken,
          );
        case NetworkErrorType.invalidPayload:
          return const AuthRpcLoginResult.failure(
            AuthRpcLoginError.missingPayload,
          );
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
          // 서버 거부 메시지에서 상세 에러 코드 추출 시도
          final errorCode = _extractErrorCode(error.message ?? '');
          return AuthRpcLoginResult.failure(_mapLoginError(errorCode));
        case NetworkErrorType.missingConfig:
          return const AuthRpcLoginResult.failure(
            AuthRpcLoginError.serverMisconfigured,
          );
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
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    // Supabase Edge Functions 필수 헤더: apikey
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.add(
      utf8.encode(jsonEncode({'provider': provider, 'idToken': idToken})),
    );

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
