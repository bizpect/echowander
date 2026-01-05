import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/server_error_logger.dart';
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
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw NotificationInboxException(NotificationInboxError.unauthorized);
        }
        throw NotificationInboxException(NotificationInboxError.serverRejected);
      }
      final payload = jsonDecode(body);
      if (payload is! List) {
        throw NotificationInboxException(NotificationInboxError.invalidPayload);
      }
      return payload
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList();
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'list_my_notifications',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw NotificationInboxException(NotificationInboxError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'list_my_notifications',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw NotificationInboxException(NotificationInboxError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'list_my_notifications',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw NotificationInboxException(NotificationInboxError.invalidPayload);
    }
  }

  @override
  Future<int> fetchUnreadCount({
    required String accessToken,
  }) async {
    _validateConfig(accessToken);
    final uri =
        Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/count_my_unread_notifications');
    try {
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
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw NotificationInboxException(NotificationInboxError.unauthorized);
        }
        throw NotificationInboxException(NotificationInboxError.serverRejected);
      }
      final payload = jsonDecode(body);
      if (payload is num) {
        return payload.toInt();
      }
      if (payload is List && payload.isNotEmpty && payload.first is num) {
        return (payload.first as num).toInt();
      }
      return 0;
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'count_my_unread_notifications',
        uri: uri,
        method: 'POST',
        error: error,
        meta: const {},
        accessToken: accessToken,
      );
      throw NotificationInboxException(NotificationInboxError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'count_my_unread_notifications',
        uri: uri,
        method: 'POST',
        error: error,
        meta: const {},
        accessToken: accessToken,
      );
      throw NotificationInboxException(NotificationInboxError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'count_my_unread_notifications',
        uri: uri,
        method: 'POST',
        error: error,
        meta: const {},
        accessToken: accessToken,
      );
      throw NotificationInboxException(NotificationInboxError.invalidPayload);
    }
  }

  @override
  Future<void> markRead({
    required int notificationId,
    required String accessToken,
  }) async {
    await _postRpc(
      rpc: 'mark_notification_read',
      payload: {
        'target_id': notificationId,
      },
      accessToken: accessToken,
      meta: {
        'notification_id': notificationId,
      },
    );
  }

  @override
  Future<void> deleteNotification({
    required int notificationId,
    required String accessToken,
  }) async {
    await _postRpc(
      rpc: 'delete_notification_log',
      payload: {
        'target_id': notificationId,
      },
      accessToken: accessToken,
      meta: {
        'notification_id': notificationId,
      },
    );
  }

  void _validateConfig(String accessToken) {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw NotificationInboxException(NotificationInboxError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw NotificationInboxException(NotificationInboxError.unauthorized);
    }
  }

  Future<void> _postRpc({
    required String rpc,
    required Map<String, dynamic> payload,
    required String accessToken,
    Map<String, dynamic>? meta,
  }) async {
    _validateConfig(accessToken);
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/$rpc');
    try {
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
          meta: meta ?? const {},
          accessToken: accessToken,
        );
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw NotificationInboxException(NotificationInboxError.unauthorized);
        }
        throw NotificationInboxException(NotificationInboxError.serverRejected);
      }
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: rpc,
        uri: uri,
        method: 'POST',
        error: error,
        meta: meta ?? const {},
        accessToken: accessToken,
      );
      throw NotificationInboxException(NotificationInboxError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: rpc,
        uri: uri,
        method: 'POST',
        error: error,
        meta: meta ?? const {},
        accessToken: accessToken,
      );
      throw NotificationInboxException(NotificationInboxError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: rpc,
        uri: uri,
        method: 'POST',
        error: error,
        meta: meta ?? const {},
        accessToken: accessToken,
      );
      throw NotificationInboxException(NotificationInboxError.invalidPayload);
    }
  }
}
