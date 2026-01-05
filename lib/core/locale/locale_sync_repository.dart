import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';

class LocaleSyncRepository {
  LocaleSyncRepository({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config),
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final HttpClient _client;

  Future<void> updateLocale({
    required String localeTag,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return;
    }
    if (accessToken.isEmpty) {
      return;
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/update_my_locale');
    try {
      final request = await _client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set('apikey', _config.supabaseAnonKey);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.add(
        utf8.encode(
          jsonEncode({
            '_locale_tag': localeTag,
          }),
        ),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        await _errorLogger.logHttpFailure(
          context: 'update_my_locale',
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: {
            'locale_tag': localeTag,
          },
          accessToken: accessToken,
        );
      }
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'update_my_locale',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'locale_tag': localeTag,
        },
        accessToken: accessToken,
      );
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'update_my_locale',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'locale_tag': localeTag,
        },
        accessToken: accessToken,
      );
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'update_my_locale',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'locale_tag': localeTag,
        },
        accessToken: accessToken,
      );
    }
  }
}
