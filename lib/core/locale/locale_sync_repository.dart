import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';
import '../network/network_error.dart';
import '../network/network_guard.dart';

class LocaleSyncRepository {
  LocaleSyncRepository({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config),
        _networkGuard = NetworkGuard(errorLogger: ServerErrorLogger(config: config)),
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  Future<void> updateLocale({
    required String localeTag,
    required String accessToken,
  }) async {
    // 백그라운드 작업: 설정 누락 시 조용히 실패
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return;
    }
    if (accessToken.isEmpty) {
      return;
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/update_my_locale');

    try {
      // NetworkGuard를 통한 요청 실행 (백그라운드: 짧은 재시도)
      await _networkGuard.execute<void>(
        operation: () => _executeUpdateLocale(
          uri: uri,
          localeTag: localeTag,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'update_my_locale',
        uri: uri,
        method: 'POST',
        meta: {'locale_tag': localeTag},
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (_) {
      // 백그라운드 로케일 동기화 실패는 조용히 무시 (이미 로깅됨, UX 방해 금지)
      return;
    }
  }

  /// updateLocale RPC 실제 실행 (NetworkGuard가 호출)
  Future<void> _executeUpdateLocale({
    required Uri uri,
    required String localeTag,
    required String accessToken,
  }) async {
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
        meta: {'locale_tag': localeTag},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'update_my_locale',
      );
    }
  }
}
