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

  /// Supabase Auth REST refresh 요청 실제 실행 (NetworkGuard가 호출)
  Future<Map<String, dynamic>> _executeAuthRefresh({
    required Uri uri,
    required String refreshToken,
  }) async {
    // URL 검증: supabaseUrl이 올바른 형태인지 확인
    final supabaseUrl = _config.supabaseUrl;
    if (!supabaseUrl.startsWith('https://') || !supabaseUrl.contains('.supabase.co')) {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix refreshSession URL 검증 실패: supabaseUrl=$supabaseUrl '
          '(예상: https://xxxx.supabase.co)',
        );
      }
      throw NetworkRequestException(
        type: NetworkErrorType.missingConfig,
        message: 'Invalid supabaseUrl format: $supabaseUrl',
      );
    }

    // 엔드포인트 검증: /auth/v1/token이어야 함
    if (!uri.path.endsWith('/auth/v1/token') || !uri.queryParameters.containsKey('grant_type')) {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix refreshSession 엔드포인트 검증 실패: uri=$uri '
          '(예상: /auth/v1/token?grant_type=refresh_token)',
        );
      }
      throw NetworkRequestException(
        type: NetworkErrorType.missingConfig,
        message: 'Invalid refresh endpoint: $uri',
      );
    }

    // 헤더/바디 검증 로깅 (민감정보 제외)
    if (kDebugMode) {
      debugPrint(
        '$_logPrefix refreshSession 요청 상세: '
        'scheme=${uri.scheme}, '
        'host=${uri.host}, '
        'path=${uri.path}, '
        'query=${uri.query}, '
        'supabaseUrlSource=${_config.supabaseUrl}, '
        'refreshTokenLength=${refreshToken.length}, '
        'apikeyLength=${_config.supabaseAnonKey.length}, '
        'hasAuthHeader=true',
      );
    }

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
    // Accept: application/json (권장)
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final bodyJson = jsonEncode({'refresh_token': refreshToken});
    request.add(utf8.encode(bodyJson));

    final response = await request.close();
    final rawPayloadText = await response.transform(utf8.decoder).join();
    // 빈 문자열이면 "<empty>"로 대체하여 파싱 시도
    final payloadText = rawPayloadText.isEmpty ? '<empty>' : rawPayloadText;

    // 응답 상세 로깅 (민감정보 제외)
    final contentType = response.headers.value(HttpHeaders.contentTypeHeader) ?? 'unknown';
    final payloadLength = payloadText.length;
    final payloadSample = _maskTokens(_truncate(payloadText, 200));

    if (kDebugMode) {
      debugPrint(
        '$_logPrefix refreshSession 응답: '
        'status=${response.statusCode}, '
        'contentType=$contentType, '
        'payloadLength=$payloadLength, '
        'payloadSample=$payloadSample',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // 비-2xx 응답의 error/error_description 파싱 (토큰 값 제외)
      final parsedErrorCode = _extractErrorCode(payloadText);
      final parsedErrorDescription = _extractErrorMessage(payloadText);

      // HTML 응답 또는 빈 응답은 "요청 자체가 잘못" 가능성이 높음
      final isHtml = payloadText.trim().toLowerCase().startsWith('<!doctype') ||
          payloadText.trim().toLowerCase().startsWith('<html');
      final isEmpty = payloadText == '<empty>' || payloadText.trim().isEmpty;

      // 정규화된 메시지 생성 (로깅용, 민감정보 제외)
      final normalizedMessage = parsedErrorCode != null
          ? 'error=$parsedErrorCode${parsedErrorDescription != null ? ", description=$parsedErrorDescription" : ""}'
          : (isEmpty
              ? 'empty_response'
              : (isHtml
                  ? 'html_response'
                  : payloadSample));

      await _errorLogger.logHttpFailure(
        context: 'auth_refresh_session',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: normalizedMessage, // 로깅용 정규화된 메시지
        meta: {
          'contentType': contentType,
          'payloadLength': payloadLength,
          'isHtml': isHtml,
          'isEmpty': isEmpty,
          'parsedErrorCode': parsedErrorCode,
          'parsedErrorDescription': parsedErrorDescription,
        },
        accessToken: '', // 민감정보 제외
      );

      // 400 + HTML/empty 응답은 fatal_misconfig로 분기
      if (response.statusCode == 400 && (isHtml || isEmpty)) {
        throw NetworkRequestException(
          type: NetworkErrorType.missingConfig,
          statusCode: response.statusCode,
          message: 'fatal_misconfig: 400 with HTML/empty response',
          rawBody: payloadText,
          parsedErrorCode: parsedErrorCode,
          parsedErrorDescription: parsedErrorDescription,
          contentType: contentType,
          isHtml: isHtml,
          isEmpty: isEmpty,
          endpoint: uri.toString(),
        );
      }

      // ⚠️ 중요: 파싱 결과를 exception 필드에 포함 (SSOT)
      // message는 정규화된 safe 문자열만 사용
      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: normalizedMessage, // 정규화된 메시지
        context: 'auth_refresh_session',
        rawBody: payloadText, // 원문 (파싱용)
        parsedErrorCode: parsedErrorCode,
        parsedErrorDescription: parsedErrorDescription,
        contentType: contentType,
        isHtml: isHtml,
        isEmpty: isEmpty,
        endpoint: uri.toString(),
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
      // refresh는 비멱등(rotation 가능) → 자동 재시도 금지 (invalid_grant 방지)
      final result = await _networkGuard.execute<Map<String, dynamic>>(
        operation: () =>
            _executeAuthRefresh(uri: uri, refreshToken: tokens.refreshToken),
        retryPolicy: RetryPolicy.none, // 재시도 0 (rotation 안전)
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

  /// Supabase Auth REST 응답에서 error_description 추출 (토큰 값 제외)
  String? _extractErrorMessage(String payloadText) {
    try {
      final payload = jsonDecode(payloadText) as Map<String, dynamic>;
      final errorDescription = payload['error_description'];
      if (errorDescription is String) {
        return errorDescription;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  /// 문자열을 지정된 길이로 자르기 (로깅용)
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// 토큰 문자열 패턴 마스킹 (로깅용)
  String _maskTokens(String text) {
    // JWT 패턴 (3개 부분으로 구성) 마스킹
    final jwtPattern = RegExp(r'[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}');
    return text.replaceAll(jwtPattern, '<token_masked>');
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
