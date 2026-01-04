import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';

class PushTokenRepository {
  PushTokenRepository({required AppConfig config}) : _config = config;

  final AppConfig _config;

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
      return;
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/$rpc');
    final request = await HttpClient().postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.write(jsonEncode(payload));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 400) {
      return;
    }
  }
}
