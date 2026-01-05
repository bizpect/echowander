import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';

class PushTokenRepository {
  PushTokenRepository({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config);

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;

  Future<void> upsertToken({
    required String accessToken,
    required String token,
    required String platform,
    required String deviceId,
  }) async {
    await _postRpc(
      rpc: 'upsert_device_token',
      accessToken: accessToken,
      payload: {
        '_token': token,
        '_platform': platform,
        '_device_id': deviceId,
      },
    );
  }

  Future<void> deactivateToken({
    required String accessToken,
    required String token,
  }) async {
    await _postRpc(
      rpc: 'deactivate_device_token',
      accessToken: accessToken,
      payload: {
        '_token': token,
      },
    );
  }

  Future<void> _postRpc({
    required String rpc,
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      // ignore: avoid_print
      print('푸시 RPC 중단: Supabase 설정 누락');
      return;
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/$rpc');
    try {
      final request = await HttpClient().postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set('apikey', _config.supabaseAnonKey);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400) {
        await _errorLogger.logHttpFailure(
          context: 'push_token_$rpc',
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: {
            'rpc': rpc,
          },
          accessToken: accessToken,
        );
        // ignore: avoid_print
        print('푸시 RPC 실패: $rpc ${response.statusCode} $body');
        return;
      }
      // ignore: avoid_print
      print('푸시 RPC 성공: $rpc ${response.statusCode}');
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'push_token_$rpc',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'rpc': rpc,
        },
        accessToken: accessToken,
      );
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'push_token_$rpc',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'rpc': rpc,
        },
        accessToken: accessToken,
      );
    }
  }
}
