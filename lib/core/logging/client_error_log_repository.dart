import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../push/device_id_store.dart';

class ClientErrorLogRepository {
  ClientErrorLogRepository({required AppConfig config})
      : _config = config,
        _client = HttpClient();

  final AppConfig _config;
  final HttpClient _client;

  Future<void> logError({
    required String context,
    required int? statusCode,
    required String? errorMessage,
    required Map<String, dynamic>? meta,
    required String? accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return;
    }
    if (context.trim().isEmpty) {
      return;
    }
    final deviceId = await DeviceIdStore().getOrCreate();
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/log_client_error');
    final payload = jsonEncode({
      'error_context': context,
      'status_code': statusCode,
      'error_message': _truncate(errorMessage, 2000),
      'meta': meta,
      'device_id': deviceId,
    });
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        final success = await _postLog(
          uri: uri,
          payload: payload,
          accessToken: accessToken,
        );
        if (success) {
          return;
        }
      }
      await _postLog(
        uri: uri,
        payload: payload,
        accessToken: null,
      );
    } on SocketException {
      return;
    } on HttpException {
      return;
    } on FormatException {
      return;
    } on ArgumentError {
      return;
    }
  }

  Future<bool> _postLog({
    required Uri uri,
    required String payload,
    required String? accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    }
    request.add(utf8.encode(payload));
    final response = await request.close();
    await response.transform(utf8.decoder).drain();
    return response.statusCode == HttpStatus.ok;
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
