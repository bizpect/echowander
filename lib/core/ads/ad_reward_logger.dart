import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';
import '../network/network_error.dart';
import '../network/network_guard.dart';
import 'ad_reward_constants.dart';

class AdRewardLogger {
  AdRewardLogger({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config),
        _networkGuard = NetworkGuard(errorLogger: ServerErrorLogger(config: config)),
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  Future<void> logEvent({
    required String? journeyId,
    required String placementCode,
    required String envCode,
    required String adUnitId,
    required String eventCode,
    required String accessToken,
    String? reqId,
    Map<String, dynamic>? metadata,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return;
    }
    if (accessToken.isEmpty) {
      return;
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/log_ad_reward_event');

    try {
      await _networkGuard.execute<void>(
        operation: () => _executeLogEvent(
          uri: uri,
          journeyId: journeyId,
          placementCode: placementCode,
          envCode: envCode,
          adUnitId: adUnitId,
          eventCode: eventCode,
          accessToken: accessToken,
          reqId: reqId,
          metadata: metadata,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'log_ad_reward_event',
        uri: uri,
        method: 'POST',
        meta: {
          'journey_id': journeyId,
          'placement_code': placementCode,
          'env_code': envCode,
          'ad_network_code': AdNetworkCodes.admob,
          'event_code': eventCode,
          if (reqId != null) 'req_id': reqId,
        },
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('[AdRewardLog] 실패: ${error.type}');
      }
    }
  }

  Future<void> _executeLogEvent({
    required Uri uri,
    required String? journeyId,
    required String placementCode,
    required String envCode,
    required String adUnitId,
    required String eventCode,
    required String accessToken,
    String? reqId,
    Map<String, dynamic>? metadata,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(
      utf8.encode(
        jsonEncode({
          'p_journey_id': journeyId,
          'p_placement_code': placementCode,
          'p_env_code': envCode,
          'p_ad_unit_id': adUnitId,
          'p_event_code': eventCode,
          'p_req_id': reqId,
          'p_metadata': metadata,
        }),
      ),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'log_ad_reward_event',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {
          'journey_id': journeyId,
          'placement_code': placementCode,
          'env_code': envCode,
          'event_code': eventCode,
        },
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'log_ad_reward_event',
      );
    }
  }
}
