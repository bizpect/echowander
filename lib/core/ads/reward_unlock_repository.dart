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
      _networkGuard = NetworkGuard(
        errorLogger: ServerErrorLogger(config: config),
      ),
      _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  Future<bool> upsertRewardUnlock({
    required String journeyId,
    required String accessToken,
    required String reqId,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return false;
    }
    if (accessToken.isEmpty) {
      return false;
    }

    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/upsert_reward_unlock',
    );
    if (kDebugMode) {
      debugPrint(
        '[Unlock] reqId=$reqId call upsert_reward_unlock params={journeyId=$journeyId, '
        'unlockedByGroup=reward_unlock_type, unlockedByCode=ADMOB_REWARDED}',
      );
    }

    try {
      final result = await _networkGuard.execute<bool>(
        operation: () => _executeUpsert(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
          reqId: reqId,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'upsert_reward_unlock',
        uri: uri,
        method: 'POST',
        meta: {'journey_id': journeyId},
        accessToken: accessToken,
      );
      if (kDebugMode) {
        debugPrint('[Unlock] reqId=$reqId OK journeyId=$journeyId');
      }
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        final preview = _buildBodyPreview(error.rawBody);
        debugPrint(
          '[RewardUnlock] 실패: reqId=$reqId type=${error.type} status=${error.statusCode} '
          'bodyLength=${error.rawBody?.length ?? 0} bodyPreview=$preview code=${error.parsedErrorCode ?? "-"}',
        );
        if (error.statusCode == HttpStatus.conflict &&
            error.parsedErrorCode == '23503' &&
            (error.rawBody?.contains('common_codes') ?? false)) {
          debugPrint(
            '[Unlock] HINT reqId=$reqId missing common_codes: reward_unlock_type/ADMOB_REWARDED '
            '(check supabase/sql/06_seed.sql)',
          );
        }
      }
      return false;
    }
  }

  String _buildBodyPreview(String? body) {
    if (body == null || body.isEmpty) {
      return 'empty';
    }
    final collapsed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= 200) {
      return collapsed;
    }
    return '${collapsed.substring(0, 200)}...';
  }

  Future<bool> _executeUpsert({
    required Uri uri,
    required String journeyId,
    required String accessToken,
    required String reqId,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode({'p_journey_id': journeyId})));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'upsert_reward_unlock',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'journey_id': journeyId},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'upsert_reward_unlock',
      );
    }

    if (kDebugMode) {
      final preview = _buildBodyPreview(body);
      debugPrint(
        '[Unlock] reqId=$reqId OK status=${response.statusCode} bodyPreview=$preview',
      );
    }

    final payload = jsonDecode(body);
    Map<String, dynamic>? row;
    if (payload is Map<String, dynamic>) {
      row = payload;
    } else if (payload is List &&
        payload.isNotEmpty &&
        payload.first is Map<String, dynamic>) {
      row = payload.first as Map<String, dynamic>;
    }
    if (row == null) {
      throw const FormatException('Invalid payload format');
    }

    final success = row['success'] == true;
    final unlocked = row['unlocked'] == true;
    return unlocked || success;
  }
}
