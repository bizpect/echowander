import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';
import '../network/network_error.dart';
import '../network/network_guard.dart';

class RewardUnlockRepository {
  RewardUnlockRepository({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config),
        _networkGuard = NetworkGuard(errorLogger: ServerErrorLogger(config: config)),
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  Future<bool> upsertRewardUnlock({
    required String journeyId,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return false;
    }
    if (accessToken.isEmpty) {
      return false;
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/upsert_reward_unlock');

    try {
      final result = await _networkGuard.execute<bool>(
        operation: () => _executeUpsert(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'upsert_reward_unlock',
        uri: uri,
        method: 'POST',
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('[RewardUnlock] 실패: ${error.type}');
      }
      return false;
    }
  }

  Future<bool> _executeUpsert({
    required Uri uri,
    required String journeyId,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(
      utf8.encode(
        jsonEncode({'p_journey_id': journeyId}),
      ),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'upsert_reward_unlock',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'upsert_reward_unlock',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List || payload.isEmpty) {
      throw const FormatException('Invalid payload format');
    }

    final row = payload.first;
    if (row is! Map<String, dynamic>) {
      throw const FormatException('Invalid payload row');
    }

    return row['unlocked'] == true;
  }
}
