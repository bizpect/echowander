import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';
import '../network/network_error.dart';
import '../network/network_guard.dart';
import 'common_code.dart';
import 'common_code_repository.dart';

const _logPrefix = '[CommonCodeRepo]';

class SupabaseCommonCodeRepository implements CommonCodeRepository {
  SupabaseCommonCodeRepository({required AppConfig config})
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

  @override
  Future<List<CommonCode>> listCommonCodes({
    required String codeType,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix listCommonCodes: 설정 누락');
      }
      return [];
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix listCommonCodes: accessToken 없음');
      }
      return [];
    }

    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/list_common_codes',
    );

    try {
      final result = await _networkGuard.execute<List<CommonCode>>(
        operation: () => _executeListCommonCodes(
          uri: uri,
          codeType: codeType,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_common_codes',
        uri: uri,
        method: 'POST',
        meta: {'code_type': codeType},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix listCommonCodes 실패: $error');
      }
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
        case NetworkErrorType.unauthorized:
        case NetworkErrorType.forbidden:
        case NetworkErrorType.invalidPayload:
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          return [];
      }
    }
  }

  Future<List<CommonCode>> _executeListCommonCodes({
    required Uri uri,
    required String codeType,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode({'p_code_type': codeType})));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'list_common_codes',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'code_type': codeType},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'list_common_codes',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      throw const FormatException('Invalid payload format');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(CommonCode.fromJson)
        .toList();
  }
}
