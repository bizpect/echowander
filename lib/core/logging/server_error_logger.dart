import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../network/network_error.dart';
import '../network/network_guard.dart';
import '../push/device_id_store.dart';

/// 서버 에러 로거 - 에러 발생 시 서버로 로그 전송
///
/// 중요: 이 클래스는 순환 의존성 방지를 위해 NetworkGuard(errorLogger: null)을 사용합니다.
/// - errorLogger: null → 로깅 실패를 다시 로깅하지 않음 (재귀 원천 차단)
/// - 로깅 실패 시 조용히 swallow 처리 (앱 UX/플로우 영향 0)
class ServerErrorLogger {
  ServerErrorLogger({required AppConfig config})
      : _config = config,
        // 순환 의존성 방지: errorLogger를 null로 전달
        // 로깅 실패를 다시 로깅하지 않아 재귀/무한루프 원천 차단
        _networkGuard = NetworkGuard(),
        _client = HttpClient();

  final AppConfig _config;
  /// NetworkGuard (errorLogger: null) - 로깅 실패 시 재귀 방지
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  Future<void> logHttpFailure({
    required String context,
    required Uri uri,
    required String method,
    required int? statusCode,
    String? errorMessage,
    Map<String, dynamic>? meta,
    String? accessToken,
  }) async {
    await _logToServer(
      context: context,
      statusCode: statusCode,
      errorMessage: errorMessage,
      meta: _mergeMeta(
        meta: meta,
        uri: uri,
        method: method,
      ),
      accessToken: accessToken,
    );
  }

  Future<void> logException({
    required String context,
    required Uri uri,
    required String method,
    required Object error,
    String? errorMessage,
    Map<String, dynamic>? meta,
    String? accessToken,
  }) async {
    await _logToServer(
      context: context,
      statusCode: null,
      errorMessage: errorMessage ?? error.toString(),
      meta: _mergeMeta(
        meta: meta,
        uri: uri,
        method: method,
        extra: {
          'exception': error.runtimeType.toString(),
        },
      ),
      accessToken: accessToken,
    );
  }

  /// 서버로 에러 로그 전송 (NetworkGuard 경유)
  ///
  /// - NetworkGuard(errorLogger: null)을 사용하여 재귀 로깅 방지
  /// - 실패 시 조용히 swallow - 앱 UX/플로우 영향 0
  Future<void> _logToServer({
    required String context,
    required int? statusCode,
    required String? errorMessage,
    required Map<String, dynamic>? meta,
    required String? accessToken,
  }) async {
    // 설정 누락 시 조용히 실패 (백그라운드 작업)
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return;
    }
    if (context.trim().isEmpty) {
      return;
    }

    try {
      final deviceId = await DeviceIdStore().getOrCreate();
      final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/log_client_error');
      final payload = {
        'error_context': context,
        'status_code': statusCode,
        'error_message': _truncate(errorMessage, 2000),
        'meta': meta,
        'device_id': deviceId,
      };

      // 인증된 토큰이 있으면 먼저 시도
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          await _networkGuard.execute<void>(
            operation: () => _executePost(
              uri: uri,
              payload: payload,
              accessToken: accessToken,
            ),
            retryPolicy: RetryPolicy.none,
            context: 'server_error_log',
            uri: uri,
            method: 'POST',
            meta: {'log_context': context},
            accessToken: accessToken,
          );
          return;
        } on NetworkRequestException catch (_) {
          // 인증 실패 시 익명 시도로 폴백
        }
      }

      // 익명 시도
      await _networkGuard.execute<void>(
        operation: () => _executePost(
          uri: uri,
          payload: payload,
          accessToken: null,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'server_error_log',
        uri: uri,
        method: 'POST',
        meta: {'log_context': context},
        accessToken: null,
      );
    } on NetworkRequestException catch (_) {
      // 로깅 실패는 조용히 swallow - 재귀 로깅/무한 루프/앱 크래시 방지
      // NetworkGuard(errorLogger: null)이므로 여기서 다시 로깅되지 않음
    } catch (_) {
      // 기타 예외도 조용히 swallow
    }
  }

  /// HTTP POST 실행 (NetworkGuard.execute 내부에서 호출)
  Future<void> _executePost({
    required Uri uri,
    required Map<String, dynamic> payload,
    required String? accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    }
    request.add(utf8.encode(jsonEncode(payload)));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'server_error_log',
      );
    }
  }

  Map<String, dynamic> _mergeMeta({
    required Uri uri,
    required String method,
    Map<String, dynamic>? meta,
    Map<String, dynamic>? extra,
  }) {
    return {
      'url': uri.toString(),
      'method': method,
      if (meta != null) ...meta,
      if (extra != null) ...extra,
    };
  }

  String? _truncate(String? value, int limit) {
    if (value == null) return null;
    if (value.length <= limit) return value;
    return value.substring(0, limit);
  }
}
