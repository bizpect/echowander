import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';

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
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
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
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw NotificationPreferenceException(NotificationPreferenceError.unauthorized);
        }
        throw NotificationPreferenceException(NotificationPreferenceError.serverRejected);
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
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'get_my_profile',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'reason': 'notification_preference',
        },
        accessToken: accessToken,
      );
      throw NotificationPreferenceException(NotificationPreferenceError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'get_my_profile',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'reason': 'notification_preference',
        },
        accessToken: accessToken,
      );
      throw NotificationPreferenceException(NotificationPreferenceError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'get_my_profile',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'reason': 'notification_preference',
        },
        accessToken: accessToken,
      );
      throw NotificationPreferenceException(NotificationPreferenceError.invalidPayload);
    }
  }

  Future<void> updateEnabled({
    required String accessToken,
    required bool enabled,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw NotificationPreferenceException(NotificationPreferenceError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw NotificationPreferenceException(NotificationPreferenceError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/update_my_notification_setting');
    try {
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
        await _errorLogger.logHttpFailure(
          context: 'update_my_notification_setting',
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: {
            'enabled': enabled,
          },
          accessToken: accessToken,
        );
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw NotificationPreferenceException(NotificationPreferenceError.unauthorized);
        }
        throw NotificationPreferenceException(NotificationPreferenceError.serverRejected);
      }
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'update_my_notification_setting',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'enabled': enabled,
        },
        accessToken: accessToken,
      );
      throw NotificationPreferenceException(NotificationPreferenceError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'update_my_notification_setting',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'enabled': enabled,
        },
        accessToken: accessToken,
      );
      throw NotificationPreferenceException(NotificationPreferenceError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'update_my_notification_setting',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'enabled': enabled,
        },
        accessToken: accessToken,
      );
      throw NotificationPreferenceException(NotificationPreferenceError.invalidPayload);
    }
  }
}
