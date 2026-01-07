import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/server_error_logger.dart';
import '../../../core/network/network_error.dart';
import '../../../core/network/network_guard.dart';
import '../domain/notification_item.dart';
import '../domain/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(config: AppConfigStore.current);
});

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config),
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final HttpClient _client;

  @override
  Future<List<NotificationItem>> fetchNotifications({
    required String accessToken,
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    _validateConfig(accessToken);
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/list_my_notifications');

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await NetworkGuard(errorLogger: _errorLogger).execute<List<NotificationItem>>(
        operation: () => _executeFetchNotifications(
          uri: uri,
          limit: limit,
          offset: offset,
          unreadOnly: unreadOnly,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_my_notifications',
        uri: uri,
        method: 'POST',
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw NotificationInboxException(NotificationInboxError.network);
        case NetworkErrorType.unauthorized:
          throw NotificationInboxException(NotificationInboxError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw NotificationInboxException(NotificationInboxError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw NotificationInboxException(NotificationInboxError.serverRejected);
      }
    }
  }

  /// fetchNotifications RPC 실제 실행 (NetworkGuard가 호출)
  Future<List<NotificationItem>> _executeFetchNotifications({
    required Uri uri,
    required int limit,
    required int offset,
    required bool unreadOnly,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(
      utf8.encode(
        jsonEncode({
          'page_size': limit,
          'page_offset': offset,
          'unread_only': unreadOnly,
        }),
      ),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'list_my_notifications',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );

      throw NetworkGuard(errorLogger: _errorLogger).statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'list_my_notifications',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      throw const FormatException('Invalid payload format');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
  }

  @override
  Future<int> fetchUnreadCount({
    required String accessToken,
  }) async {
    _validateConfig(accessToken);
    final uri =
        Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/count_my_unread_notifications');

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await NetworkGuard(errorLogger: _errorLogger).execute<int>(
        operation: () => _executeFetchUnreadCount(
          uri: uri,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'count_my_unread_notifications',
        uri: uri,
        method: 'POST',
        meta: const {},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw NotificationInboxException(NotificationInboxError.network);
        case NetworkErrorType.unauthorized:
          throw NotificationInboxException(NotificationInboxError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw NotificationInboxException(NotificationInboxError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw NotificationInboxException(NotificationInboxError.serverRejected);
      }
    }
  }

  /// fetchUnreadCount RPC 실제 실행 (NetworkGuard가 호출)
  Future<int> _executeFetchUnreadCount({
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
      await _errorLogger.logHttpFailure(
        context: 'count_my_unread_notifications',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: const {},
        accessToken: accessToken,
      );

      throw NetworkGuard(errorLogger: _errorLogger).statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'count_my_unread_notifications',
      );
    }

    final payload = jsonDecode(body);
    if (payload is num) {
      return payload.toInt();
    }
    if (payload is List && payload.isNotEmpty && payload.first is num) {
      return (payload.first as num).toInt();
    }
    return 0;
  }

  @override
  Future<void> markRead({
    required int notificationId,
    required String accessToken,
  }) async {
    // 사전 검증
    _validateConfig(accessToken);

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/mark_notification_read');

    try {
      // NetworkGuard를 통한 요청 실행 (재시도 없음: 커밋 액션)
      await NetworkGuard(errorLogger: _errorLogger).execute<void>(
        operation: () => _executeRpcPost(
          uri: uri,
          rpc: 'mark_notification_read',
          payload: {'target_id': notificationId},
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'mark_notification_read',
        uri: uri,
        method: 'POST',
        meta: {'notification_id': notificationId},
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (error) {
      // NetworkRequestException을 NotificationInboxException으로 변환
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw NotificationInboxException(NotificationInboxError.network);
        case NetworkErrorType.unauthorized:
          throw NotificationInboxException(NotificationInboxError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw NotificationInboxException(NotificationInboxError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw NotificationInboxException(NotificationInboxError.serverRejected);
      }
    }
  }

  @override
  Future<void> deleteNotification({
    required int notificationId,
    required String accessToken,
  }) async {
    // 사전 검증
    _validateConfig(accessToken);

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/delete_notification_log');

    try {
      // NetworkGuard를 통한 요청 실행 (재시도 없음: 커밋 액션)
      await NetworkGuard(errorLogger: _errorLogger).execute<void>(
        operation: () => _executeRpcPost(
          uri: uri,
          rpc: 'delete_notification_log',
          payload: {'target_id': notificationId},
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'delete_notification_log',
        uri: uri,
        method: 'POST',
        meta: {'notification_id': notificationId},
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (error) {
      // NetworkRequestException을 NotificationInboxException으로 변환
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw NotificationInboxException(NotificationInboxError.network);
        case NetworkErrorType.unauthorized:
          throw NotificationInboxException(NotificationInboxError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw NotificationInboxException(NotificationInboxError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw NotificationInboxException(NotificationInboxError.serverRejected);
      }
    }
  }

  void _validateConfig(String accessToken) {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw NotificationInboxException(NotificationInboxError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw NotificationInboxException(NotificationInboxError.unauthorized);
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
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode(payload)));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: rpc,
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: payload,
        accessToken: accessToken,
      );

      final networkGuard = NetworkGuard(errorLogger: _errorLogger);
      throw networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: rpc,
      );
    }
  }
}
