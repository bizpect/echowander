import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../network/network_error.dart';
import '../network/network_guard.dart';
import '../push/device_id_store.dart';

/// 클라이언트 에러 로그 저장소
///
/// 중요: 순환 의존성 방지를 위해 NetworkGuard에 errorLogger를 null로 전달합니다.
/// 에러 로깅 자체가 실패하면 조용히 swallow 처리합니다 (재귀 로깅/무한 루프 방지).
class ClientErrorLogRepository {
  ClientErrorLogRepository({required AppConfig config})
      : _config = config,
        // 순환 의존성 방지: errorLogger를 null로 전달
        // 에러 로깅 실패는 재귀적으로 로깅하지 않음
        _networkGuard = NetworkGuard(),
        _client = HttpClient();

  final AppConfig _config;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  Future<void> logError({
    required String context,
    required int? statusCode,
    required String? errorMessage,
    required Map<String, dynamic>? meta,
    required String? accessToken,
  }) async {
    // 백그라운드 작업: 설정 누락 시 조용히 실패
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return;
    }
    if (context.trim().isEmpty) {
      return;
    }

    final deviceId = await DeviceIdStore().getOrCreate();
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/log_client_error');
    final payload = {
      'error_context': context,
      'status_code': statusCode,
      'error_message': _truncate(errorMessage, 2000),
      'meta': meta,
      'device_id': deviceId,
    };

    try {
      // 인증된 토큰이 있으면 먼저 시도
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          await _networkGuard.execute<void>(
            operation: () => _executePostLog(
              uri: uri,
              payload: payload,
              accessToken: accessToken,
            ),
            retryPolicy: RetryPolicy.none,
            context: 'log_client_error',
            uri: uri,
            method: 'POST',
            meta: {'context': context},
            accessToken: accessToken,
          );
          return;
        } on NetworkRequestException catch (_) {
          // 인증 실패 시 익명 시도로 폴백
        }
      }

      // 익명 시도
      await _networkGuard.execute<void>(
        operation: () => _executePostLog(
          uri: uri,
          payload: payload,
          accessToken: null,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'log_client_error',
        uri: uri,
        method: 'POST',
        meta: {'context': context},
        accessToken: null,
      );
    } on NetworkRequestException catch (_) {
      // 백그라운드 에러 로깅 실패는 조용히 무시 (무한 재귀 방지, UX 방해 금지)
      return;
    }
  }

  /// log_client_error RPC 실제 실행 (NetworkGuard가 호출)
  Future<void> _executePostLog({
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
      // 에러 로그 실패는 ServerErrorLogger 호출 금지 (무한 재귀 방지)
      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'log_client_error',
      );
    }
  }

  String? _truncate(String? value, int limit) {
    if (value == null) {
      return null;
    }
    if (value.length <= limit) {
      return value;
    }
    return value.substring(0, limit);
  }
}
