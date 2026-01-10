import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';
import '../network/network_error.dart';
import '../network/network_guard.dart';

const _logPrefix = '[PushToken]';

class PushTokenRepository {
  PushTokenRepository({required AppConfig config})
    : _config = config,
      _errorLogger = ServerErrorLogger(config: config),
      _networkGuard = NetworkGuard(
        errorLogger: ServerErrorLogger(config: config),
      ),
      _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  Future<void> upsertToken({
    required String accessToken,
    required String token,
    required String platform,
    required String deviceId,
  }) async {
    await _postRpc(
      rpc: 'upsert_device_token',
      accessToken: accessToken,
      payload: {'_token': token, '_platform': platform, '_device_id': deviceId},
    );
  }

  Future<void> deactivateToken({
    required String accessToken,
    required String token,
  }) async {
    await _postRpc(
      rpc: 'deactivate_device_token',
      accessToken: accessToken,
      payload: {'_token': token},
    );
  }

  Future<void> _postRpc({
    required String rpc,
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    // 백그라운드 작업: 설정 누락 시 조용히 실패
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix RPC 중단: Supabase 설정 누락');
      }
      return;
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/$rpc');

    try {
      // NetworkGuard를 통한 요청 실행 (백그라운드: 짧은 재시도)
      await _networkGuard.execute<void>(
        operation: () => _executeRpcPost(
          uri: uri,
          rpc: rpc,
          payload: payload,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'push_token_$rpc',
        uri: uri,
        method: 'POST',
        meta: {'rpc': rpc},
        accessToken: accessToken,
      );

      if (kDebugMode) {
        debugPrint('$_logPrefix RPC 성공: $rpc');
      }
    } on NetworkRequestException catch (_) {
      // 백그라운드 푸시 토큰 동기화 실패는 조용히 무시 (이미 로깅됨, UX 방해 금지)
      if (kDebugMode) {
        debugPrint('$_logPrefix RPC 실패: $rpc - 무시됨');
      }
      return;
    }
  }

  /// RPC POST 요청 실제 실행 (NetworkGuard가 호출)
  Future<void> _executeRpcPost({
    required Uri uri,
    required String rpc,
    required Map<String, dynamic> payload,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode(payload)));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode >= HttpStatus.badRequest) {
      await _errorLogger.logHttpFailure(
        context: 'push_token_$rpc',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'rpc': rpc},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'push_token_$rpc',
      );
    }
  }
}
