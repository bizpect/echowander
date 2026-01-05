import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';
import 'block_repository.dart';

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return SupabaseBlockRepository(config: AppConfigStore.current);
});

class SupabaseBlockRepository implements BlockRepository {
  SupabaseBlockRepository({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config),
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final HttpClient _client;

  @override
  Future<List<BlockedUser>> fetchBlocks({
    required int limit,
    required int offset,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw BlockException(BlockError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw BlockException(BlockError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/list_my_blocks');
    try {
      final request = await _client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set('apikey', _config.supabaseAnonKey);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.add(
        utf8.encode(
          jsonEncode({
            'page_size': limit,
            'page_offset': offset,
          }),
        ),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        if (kDebugMode) {
          debugPrint('block: list 실패 ${response.statusCode} $body');
        }
        await _errorLogger.logHttpFailure(
          context: 'list_my_blocks',
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: {
            'limit': limit,
            'offset': offset,
          },
          accessToken: accessToken,
        );
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw BlockException(BlockError.unauthorized);
        }
        throw BlockException(BlockError.serverRejected);
      }
      final payload = jsonDecode(body);
      if (payload is! List) {
        throw BlockException(BlockError.invalidPayload);
      }
      return payload
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => BlockedUser(
              userId: row['blocked_user_id'] as String? ?? '',
              nickname: row['blocked_nickname'] as String? ?? '',
              avatarUrl: row['blocked_avatar_url'] as String? ?? '',
              createdAt: DateTime.parse(row['created_at'] as String),
            ),
          )
          .where((item) => item.userId.isNotEmpty)
          .toList();
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'list_my_blocks',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw BlockException(BlockError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'list_my_blocks',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw BlockException(BlockError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'list_my_blocks',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw BlockException(BlockError.invalidPayload);
    }
  }

  @override
  Future<void> blockUser({
    required String targetUserId,
    required String accessToken,
  }) async {
    await _postRpc(
      rpc: 'block_user',
      payload: {
        'target_user_id': targetUserId,
      },
      accessToken: accessToken,
    );
  }

  @override
  Future<void> unblockUser({
    required String targetUserId,
    required String accessToken,
  }) async {
    await _postRpc(
      rpc: 'unblock_user',
      payload: {
        'target_user_id': targetUserId,
      },
      accessToken: accessToken,
    );
  }

  Future<void> _postRpc({
    required String rpc,
    required Map<String, dynamic> payload,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw BlockException(BlockError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw BlockException(BlockError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/$rpc');
    try {
      final request = await _client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set('apikey', _config.supabaseAnonKey);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        if (kDebugMode) {
          debugPrint('block: $rpc 실패 ${response.statusCode} $body');
        }
        await _errorLogger.logHttpFailure(
          context: rpc,
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: payload,
          accessToken: accessToken,
        );
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw BlockException(BlockError.unauthorized);
        }
        throw BlockException(BlockError.serverRejected);
      }
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: rpc,
        uri: uri,
        method: 'POST',
        error: error,
        meta: payload,
        accessToken: accessToken,
      );
      throw BlockException(BlockError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: rpc,
        uri: uri,
        method: 'POST',
        error: error,
        meta: payload,
        accessToken: accessToken,
      );
      throw BlockException(BlockError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: rpc,
        uri: uri,
        method: 'POST',
        error: error,
        meta: payload,
        accessToken: accessToken,
      );
      throw BlockException(BlockError.invalidPayload);
    }
  }
}
