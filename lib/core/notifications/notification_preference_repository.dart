import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';
import '../network/network_error.dart';
import '../network/network_guard.dart';

enum NotificationPreferenceError {
  missingConfig,
  unauthorized,
  invalidPayload,
  serverRejected,
  network,
  unknown,
}

class NotificationPreferenceException implements Exception {
  NotificationPreferenceException(this.error);

  final NotificationPreferenceError error;
}

final notificationPreferenceRepositoryProvider =
    Provider<NotificationPreferenceRepository>((ref) {
  return NotificationPreferenceRepository(config: AppConfigStore.current);
});

class NotificationPreferenceRepository {
  NotificationPreferenceRepository({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config),
        _networkGuard = NetworkGuard(errorLogger: ServerErrorLogger(config: config)),
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  Future<bool> fetchEnabled({
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw NotificationPreferenceException(NotificationPreferenceError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw NotificationPreferenceException(NotificationPreferenceError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/get_my_profile');

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<bool>(
        operation: () => _executeFetchEnabled(
          uri: uri,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'get_my_profile',
        uri: uri,
        method: 'POST',
        meta: {'reason': 'notification_preference'},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('notifications: get_my_profile NetworkRequestException: $error');
      }

      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw NotificationPreferenceException(NotificationPreferenceError.network);
        case NetworkErrorType.unauthorized:
          throw NotificationPreferenceException(NotificationPreferenceError.unauthorized);
        case NetworkErrorType.forbidden:
          throw NotificationPreferenceException(NotificationPreferenceError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw NotificationPreferenceException(NotificationPreferenceError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw NotificationPreferenceException(NotificationPreferenceError.serverRejected);
      }
    }
  }

  /// fetchEnabled RPC 실제 실행 (NetworkGuard가 호출)
  Future<bool> _executeFetchEnabled({
    required Uri uri,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode({})));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      if (kDebugMode) {
        debugPrint('notifications: get_my_profile 실패 ${response.statusCode} $body');
      }
      await _errorLogger.logHttpFailure(
        context: 'get_my_profile',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {
          'reason': 'notification_preference',
        },
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'get_my_profile',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List || payload.isEmpty) {
      return true;
    }
    final row = payload.first;
    if (row is Map<String, dynamic>) {
      return row['notifications_enabled'] as bool? ?? true;
    }
    return true;
  }

  Future<void> updateEnabled({
    required String accessToken,
    required bool enabled,
  }) async {
    // 사전 검증
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw NotificationPreferenceException(NotificationPreferenceError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw NotificationPreferenceException(NotificationPreferenceError.unauthorized);
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/update_my_notification_setting');

    try {
      // NetworkGuard를 통한 요청 실행 (재시도 없음: 커밋 액션)
      await _networkGuard.execute<void>(
        operation: () => _executeUpdateEnabled(
          uri: uri,
          enabled: enabled,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'update_my_notification_setting',
        uri: uri,
        method: 'POST',
        meta: {'enabled': enabled},
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (error) {
      // NetworkRequestException을 NotificationPreferenceException으로 변환
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw NotificationPreferenceException(NotificationPreferenceError.network);
        case NetworkErrorType.unauthorized:
          throw NotificationPreferenceException(NotificationPreferenceError.unauthorized);
        case NetworkErrorType.forbidden:
          throw NotificationPreferenceException(NotificationPreferenceError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw NotificationPreferenceException(NotificationPreferenceError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw NotificationPreferenceException(NotificationPreferenceError.serverRejected);
      }
    }
  }

  /// update_my_notification_setting RPC 실제 실행 (NetworkGuard가 호출)
  Future<void> _executeUpdateEnabled({
    required Uri uri,
    required bool enabled,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(
      utf8.encode(
        jsonEncode({
          '_enabled': enabled,
        }),
      ),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      if (kDebugMode) {
        debugPrint('notifications: update 실패 ${response.statusCode} $body');
      }

      // NetworkGuard가 처리할 수 있도록 NetworkRequestException 발생
      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
      );
    }
  }
}
