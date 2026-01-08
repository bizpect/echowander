import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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

  /// 치명적 설정 오류: 요청 자체가 잘못됨 (URL/엔드포인트/헤더 오류)
  /// → 원인 노출 우선 (로그인 튕김보다 개발자 알림 우선)
  const factory RefreshResult.fatalMisconfig(String reason) = RefreshFatalMisconfig;
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

class RefreshFatalMisconfig extends RefreshResult {
  const RefreshFatalMisconfig(this.reason);
  final String reason;
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

  /// POST JSON 요청 실제 실행 (NetworkGuard가 호출)
  Future<Map<String, dynamic>> _executePostJson({
    required Uri uri,
    required Map<String, dynamic> body,
    String? token, // ✅ nullable로 변경: null이면 Authorization 헤더 추가 안 함
    required String context,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    // Supabase Edge Functions 필수 헤더: apikey
    request.headers.set('apikey', _config.supabaseAnonKey);
    // ✅ Authorization 헤더는 옵션: token이 null이 아니고 비어있지 않을 때만 추가
    // 빈 문자열 토큰을 Authorization에 넣는 것은 금지
    if (token != null && token.isNotEmpty) {
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
      debugPrint(
        '$_logPrefix validateSession 시작: '
        '${_logTokenValidation(tokenType: 'access', token: tokens.accessToken)}, '
        '${_logTokenValidation(tokenType: 'refresh', token: tokens.refreshToken)}',
      );
    }

    final uri = _resolve('validate_session');

    try {
      // ✅ validateSession은 accessToken을 Authorization Bearer로 보냄
      // body에는 refreshToken을 포함 (서버에서 검증용)
      final result = await _networkGuard.execute<Map<String, dynamic>>(
        operation: () => _executePostJson(
          uri: uri,
          body: {'refreshToken': tokens.refreshToken},
          token: tokens.accessToken, // Authorization Bearer로 전송됨
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
      debugPrint('$_logPrefix refreshSession 시작 (Edge Function)');
    }

    // ✅ Edge Function endpoint 사용: /functions/v1/refresh_session
    // HMAC refresh_token은 Edge Function으로만 refresh 수행 (GoTrue 호환 불가)
    final supabaseUrl = _config.supabaseUrl;
    if (supabaseUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix refreshSession 실패: supabaseUrl 없음');
      }
      return const RefreshResult.transientError();
    }

    // ✅ URL 생성: Uri.replace로 고정 생성 (조건문 지옥 금지)
    // base: https://<project>.supabase.co
    // path: /functions/v1/refresh_session (고정)
    final base = Uri.parse(supabaseUrl);
    final uri = base.replace(path: '/functions/v1/refresh_session');

    // ✅ URL 검증: 반드시 /functions/v1/refresh_session이어야 함
    if (uri.path != '/functions/v1/refresh_session') {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix ⚠️ URL 검증 실패: path=${uri.path} '
          '(예상: /functions/v1/refresh_session)',
        );
      }
      return RefreshResult.fatalMisconfig(
        'Invalid refresh endpoint: ${uri.path} (expected: /functions/v1/refresh_session)',
      );
    }

    // ✅ SSOT 검증: refresh 직전 토큰 형태 검증 로그
    // refresh_token이 JWT 형태면 치명적 매핑 오류로 차단
    if (_isJwtFormat(tokens.refreshToken)) {
      final fingerprint = _tokenFingerprint(tokens.refreshToken);
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix ⚠️ 치명적 토큰 매핑 오류: refresh_token이 JWT 형태입니다 '
          '(fp=$fingerprint, len=${tokens.refreshToken.length})',
        );
      }
      return RefreshResult.fatalMisconfig(
        'refresh_token 매핑 오류: JWT 형태로 변질됨 (fp=$fingerprint)',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '$_logPrefix refreshSession using: '
        '${_logTokenValidation(tokenType: 'refresh', token: tokens.refreshToken)}',
      );
      // ✅ 최종 URL 출력 (검증 포인트)
      debugPrint(
        '$_logPrefix refreshSession 요청 상세: '
        'path=${uri.path}, '
        'fullUrl=${uri.toString()}',
      );
    }

    try {
      // ✅ Edge Function: refresh_token 기반, 만료된 accessToken 불필요
      // verify_jwt=true 환경에서도 게이트 통과를 위해 Bearer anonKey 사용
      // refresh는 비멱등(rotation 가능) → 자동 재시도 금지 (invalid_grant 방지)
      // ✅ SSOT: 요청 body 키를 refresh_token으로 통일 (서버와 동일)
      final result = await _networkGuard.execute<Map<String, dynamic>>(
        operation: () => _executePostJson(
          uri: uri,
          body: {'refresh_token': tokens.refreshToken}, // ✅ SSOT: refresh_token으로 통일
          token: _config.supabaseAnonKey, // ✅ Bearer anonKey로 게이트 401 차단 제거
          context: 'auth_refresh_session',
        ),
        retryPolicy: RetryPolicy.none, // 재시도 0 (rotation 안전)
        context: 'auth_refresh_session',
        uri: uri,
        method: 'POST',
        meta: const {},
        accessToken: '', // 로깅용도 빈 문자열
      );

      if (kDebugMode) {
        debugPrint('$_logPrefix refreshSession 응답: status=200');
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

      // ✅ SSOT 검증: refresh 응답 직후 토큰 형태 검증
      // access_token은 JWT여야 함 (점 2개)
      final accessJwt = _isJwtFormat(accessToken);
      if (!accessJwt) {
        final fingerprint = _tokenFingerprint(accessToken);
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix ⚠️ 치명적 토큰 매핑 오류: refreshSession 응답의 access_token이 JWT 형태가 아닙니다 '
            '(fp=$fingerprint, len=${accessToken.length})',
          );
        }
        return RefreshResult.fatalMisconfig(
          'access_token 매핑 오류: JWT 형태가 아님 (fp=$fingerprint)',
        );
      }

      // refresh_token은 JWT가 아니어야 함 (점 2개면 안 됨)
      final refreshJwt = _isJwtFormat(newRefreshToken);
      if (refreshJwt) {
        final fingerprint = _tokenFingerprint(newRefreshToken);
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix ⚠️ 치명적 토큰 매핑 오류: refreshSession 응답의 refresh_token이 JWT 형태입니다 '
            '(fp=$fingerprint, len=${newRefreshToken.length}) - access_token을 잘못 매핑한 것',
          );
        }
        return RefreshResult.fatalMisconfig(
          'refresh_token 매핑 오류: JWT 형태로 변질됨 (fp=$fingerprint)',
        );
      }

      if (kDebugMode) {
        debugPrint(
          '$_logPrefix [Token] refresh issued: '
          '${_logTokenValidation(tokenType: 'access', token: accessToken)}, '
          '${_logTokenValidation(tokenType: 'refresh', token: newRefreshToken)}',
        );
        // ✅ 완료 조건 검증: accessJwt=true, refreshJwt=false
        debugPrint(
          '$_logPrefix ✅ 토큰 형태 검증 통과: accessJwt=$accessJwt, refreshJwt=$refreshJwt',
        );
      }

      return RefreshResult.success(
        SessionTokens(accessToken: accessToken, refreshToken: newRefreshToken),
      );
    } on NetworkRequestException catch (error) {
      // 에러 타입에 따라 "인증 실패 확정" vs "일시 장애" vs "치명적 설정 오류" 분류
      // SSOT: exception 필드에서 파싱 결과 사용 (message가 아닌 parsedErrorCode 사용)

      // missingConfig는 fatal_misconfig로 분기
      if (error.type == NetworkErrorType.missingConfig) {
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix refreshSession 치명적 설정 오류: '
            'endpoint=${error.endpoint}, '
            'contentType=${error.contentType}, '
            'isHtml=${error.isHtml}, '
            'isEmpty=${error.isEmpty}',
          );
        }
        return RefreshResult.fatalMisconfig(
          error.message ?? 'Unknown configuration error',
        );
      }

      switch (error.type) {
        case NetworkErrorType.unauthorized:
          // 401/403: refresh 토큰 만료/무효 → 인증 실패 확정
          if (kDebugMode) {
            debugPrint(
              '$_logPrefix refreshSession 인증 실패 확정 '
              '(status=${error.statusCode}, error=${error.parsedErrorCode})',
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
              '(type=${error.type}, status=${error.statusCode})',
            );
          }
          return const RefreshResult.transientError();

        case NetworkErrorType.serverRejected:
          // 400 응답: exception 필드 기반 분기 (SSOT)
          if (error.statusCode == 400) {
            // HTML/empty 응답은 fatal_misconfig 또는 authFailed (설정/게이트웨이 가능성)
            if (error.isHtml == true || error.isEmpty == true) {
              if (kDebugMode) {
                debugPrint(
                  '$_logPrefix refreshSession 인증 실패 확정 '
                  '(status=400, isHtml=${error.isHtml}, isEmpty=${error.isEmpty}, '
                  'contentType=${error.contentType}, endpoint=${error.endpoint})',
                );
              }
              // 설정 오류 가능성이 높지만, 루프 방지를 위해 authFailed로 처리
              return const RefreshResult.authFailed();
            }

            // parsedErrorCode 기반 분기 (SSOT)
            final parsedErrorCode = error.parsedErrorCode;
            if (parsedErrorCode == 'invalid_grant' || parsedErrorCode == 'invalid_request') {
              if (kDebugMode) {
                debugPrint(
                  '$_logPrefix refreshSession 인증 실패 확정 '
                  '(status=400, error=$parsedErrorCode, desc=${error.parsedErrorDescription})',
                );
              }
              return const RefreshResult.authFailed();
            }

            if (parsedErrorCode != null) {
              // 그 외 errorCode도 authFailed로 처리 (루프 방지 우선)
              if (kDebugMode) {
                debugPrint(
                  '$_logPrefix refreshSession 인증 실패 확정 '
                  '(status=400, error=$parsedErrorCode, 루프 방지)',
                );
              }
              return const RefreshResult.authFailed();
            }

            // parsedErrorCode가 null이면 unparsed 400 → authFailed (루프 방지)
            if (kDebugMode) {
              debugPrint(
                '$_logPrefix refreshSession 인증 실패 확정 '
                '(status=400, error=unparsed, contentType=${error.contentType}, '
                'payloadLength=${error.rawBody?.length ?? 0}, 루프 방지)',
              );
            }
            return const RefreshResult.authFailed();
          }
          // 그 외 serverRejected는 일시 장애로 처리
          if (kDebugMode) {
            debugPrint(
              '$_logPrefix refreshSession 일시 장애 '
              '(type=${error.type}, status=${error.statusCode})',
            );
          }
          return const RefreshResult.transientError();

        case NetworkErrorType.invalidPayload:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          // 기타 오류: 일시 장애로 처리 (로그아웃 금지)
          // missingConfig는 이미 위에서 fatalMisconfig로 처리되므로 여기 도달하지 않음
          if (kDebugMode) {
            debugPrint(
              '$_logPrefix refreshSession 기타 오류 '
              '(type=${error.type}, status=${error.statusCode}) → 일시 장애로 처리',
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
      // ✅ SSOT: 서버 응답 키를 access_token/refresh_token으로 통일
      final accessToken = payload['access_token'] as String?;
      final refreshToken = payload['refresh_token'] as String?;
      
      if (accessToken == null || accessToken.isEmpty || refreshToken == null || refreshToken.isEmpty) {
        await _errorLogger.logException(
          context: 'auth_login_social',
          uri: uri,
          method: 'POST',
          error: const FormatException('Missing access_token or refresh_token in response'),
          errorMessage: payloadText,
          meta: {'provider': provider},
          accessToken: '',
        );
        return const AuthRpcLoginResult.failure(
          AuthRpcLoginError.missingPayload,
        );
      }
      
      // ✅ SSOT 검증: 발급 직후 토큰 형태 검증
      // access_token은 JWT여야 함 (점 2개)
      final accessJwt = _isJwtFormat(accessToken);
      if (!accessJwt) {
        final fingerprint = _tokenFingerprint(accessToken);
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix ⚠️ 치명적 토큰 매핑 오류: exchangeSocialToken 응답의 access_token이 JWT 형태가 아닙니다 '
            '(fp=$fingerprint, len=${accessToken.length})',
          );
        }
        return const AuthRpcLoginResult.failure(
          AuthRpcLoginError.serverMisconfigured,
        );
      }

      // refresh_token은 JWT가 아니어야 함 (점 2개면 안 됨)
      final refreshJwt = _isJwtFormat(refreshToken);
      if (refreshJwt) {
        final fingerprint = _tokenFingerprint(refreshToken);
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix ⚠️ 치명적 토큰 매핑 오류: exchangeSocialToken 응답의 refresh_token이 JWT 형태입니다 '
            '(fp=$fingerprint, len=${refreshToken.length}) - access_token을 잘못 매핑한 것',
          );
        }
        return const AuthRpcLoginResult.failure(
          AuthRpcLoginError.serverMisconfigured,
        );
      }

      if (kDebugMode) {
        debugPrint(
          '$_logPrefix [Token] issued: '
          '${_logTokenValidation(tokenType: 'access', token: accessToken)}, '
          '${_logTokenValidation(tokenType: 'refresh', token: refreshToken)}',
        );
        // ✅ 완료 조건 검증: accessJwt=true, refreshJwt=false
        debugPrint(
          '$_logPrefix ✅ 토큰 형태 검증 통과: accessJwt=$accessJwt, refreshJwt=$refreshJwt',
        );
      }
      
      return AuthRpcLoginResult.success(
        SessionTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
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

  /// 토큰 검증 헬퍼: JWT dots 여부 및 길이 검증 (민감정보 제외 로깅용)
  static bool _isJwtFormat(String token) {
    return token.split('.').length == 3;
  }

  /// 토큰 fingerprint 생성 (SHA256 prefix 12자, 민감정보 제외 로깅용)
  static String _tokenFingerprint(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 12);
  }

  /// 토큰 검증 로그 생성 (민감정보 제외)
  static String _logTokenValidation({
    required String tokenType,
    required String token,
  }) {
    final len = token.length;
    final hasJwtDots = _isJwtFormat(token);
    final fingerprint = _tokenFingerprint(token);
    return '$tokenType: len=$len, jwtDots=$hasJwtDots, fp=$fingerprint';
  }

  String? _extractErrorCode(String payloadText) {
    try {
      final payload = jsonDecode(payloadText) as Map<String, dynamic>;
      // Supabase 응답 형식: error_code 우선
      final errorCode = payload['error_code'];
      if (errorCode is String) {
        return errorCode;
      }
      // 표준 OAuth2 형식: error
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
