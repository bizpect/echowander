import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../logging/server_error_logger.dart';
import '../network/network_error.dart';
import '../network/network_guard.dart';
import 'block_repository.dart';

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return SupabaseBlockRepository(config: AppConfigStore.current);
});

class SupabaseBlockRepository implements BlockRepository {
  SupabaseBlockRepository({required AppConfig config})
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
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<List<BlockedUser>>(
        operation: () => _executeFetchBlocks(
          uri: uri,
          limit: limit,
          offset: offset,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_my_blocks',
        uri: uri,
        method: 'POST',
        meta: {'limit': limit, 'offset': offset},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('block: list_my_blocks NetworkRequestException: $error');
      }

      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw BlockException(BlockError.network);
        case NetworkErrorType.unauthorized:
          throw BlockException(BlockError.unauthorized);
        case NetworkErrorType.forbidden:
          throw BlockException(BlockError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw BlockException(BlockError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw BlockException(BlockError.serverRejected);
      }
    }
  }

  /// fetchBlocks RPC 실제 실행 (NetworkGuard가 호출)
  Future<List<BlockedUser>> _executeFetchBlocks({
    required Uri uri,
    required int limit,
    required int offset,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(
      utf8.encode(jsonEncode({'page_size': limit, 'page_offset': offset})),
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
        meta: {'limit': limit, 'offset': offset},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'list_my_blocks',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      throw const FormatException('Invalid payload format');
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
  }

  @override
  Future<void> blockUser({
    required String targetUserId,
    required String accessToken,
  }) async {
    // 사전 검증
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw BlockException(BlockError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw BlockException(BlockError.unauthorized);
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/block_user');

    try {
      // NetworkGuard를 통한 요청 실행 (재시도 없음: 커밋 액션)
      await _networkGuard.execute<void>(
        operation: () => _executeRpcPost(
          uri: uri,
          payload: {'target_user_id': targetUserId},
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'block_user',
        uri: uri,
        method: 'POST',
        meta: {'target_user_id': targetUserId},
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (error) {
      // NetworkRequestException을 BlockException으로 변환
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw BlockException(BlockError.network);
        case NetworkErrorType.unauthorized:
          throw BlockException(BlockError.unauthorized);
        case NetworkErrorType.forbidden:
          throw BlockException(BlockError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw BlockException(BlockError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw BlockException(BlockError.serverRejected);
      }
    }
  }

  @override
  Future<void> unblockUser({
    required String targetUserId,
    required String accessToken,
    String? traceId,
  }) async {
    // ✅ traceId 로깅
    final finalTraceId = traceId ?? DateTime.now().microsecondsSinceEpoch.toString();
    if (kDebugMode) {
      debugPrint(
        'block:unblock rpc call traceId=$finalTraceId fn=unblock_user args={target_user_id: $targetUserId}',
      );
    }
    // 사전 검증
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw BlockException(BlockError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw BlockException(BlockError.unauthorized);
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/unblock_user');

    try {
      // NetworkGuard를 통한 요청 실행 (재시도 없음: 커밋 액션)
      // ✅ unblock_user는 이제 jsonb를 반환하므로 Map<String, dynamic>으로 처리
      final result = await _networkGuard.execute<Map<String, dynamic>>(
        operation: () => _executeRpcPost(
          uri: uri,
          payload: {'target_user_id': targetUserId},
          accessToken: accessToken,
          traceId: finalTraceId,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'unblock_user',
        uri: uri,
        method: 'POST',
        meta: {
          'target_user_id': targetUserId,
          'traceId': finalTraceId,
        },
        accessToken: accessToken,
      );
      // ✅ restored_count 로깅 (운영/검증)
      if (kDebugMode) {
        final restoredCount = result['restored_count'] as int? ?? 0;
        debugPrint(
          'block:unblock restored_count=$restoredCount traceId=$finalTraceId',
        );
      }
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'block:unblock rpc error traceId=$finalTraceId status=${error.statusCode} type=${error.type}',
        );
      }
      // NetworkRequestException을 BlockException으로 변환
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw BlockException(BlockError.network);
        case NetworkErrorType.unauthorized:
          throw BlockException(BlockError.unauthorized);
        case NetworkErrorType.forbidden:
          throw BlockException(BlockError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw BlockException(BlockError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw BlockException(BlockError.serverRejected);
      }
    }
  }

  /// RPC POST 요청 실제 실행 (NetworkGuard가 호출)
  /// unblock_user는 jsonb를 반환하므로 Map[String, dynamic]으로 파싱
  Future<Map<String, dynamic>> _executeRpcPost({
    required Uri uri,
    required Map<String, dynamic> payload,
    required String accessToken,
    String? traceId,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode(payload)));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    // ✅ 200 OK는 jsonb 응답, 204 No Content는 빈 응답 (하위 호환성)
    if (response.statusCode == HttpStatus.ok) {
      if (kDebugMode) {
        debugPrint(
          'block:unblock rpc success traceId=$traceId status=${response.statusCode} bodyLen=${body.length}',
        );
      }
      // ✅ jsonb 응답 파싱
      if (body.isNotEmpty) {
        try {
          final result = jsonDecode(body) as Map<String, dynamic>;
          return result;
        } on FormatException {
          // 파싱 실패 시 빈 맵 반환 (하위 호환성)
          if (kDebugMode) {
            debugPrint(
              'block:unblock rpc parse failed traceId=$traceId body=$body',
            );
          }
          return {};
        }
      }
      return {}; // 빈 응답 (하위 호환성)
    }

    if (response.statusCode == HttpStatus.noContent) {
      // ✅ 204는 빈 응답 (하위 호환성, void 반환 함수)
      if (kDebugMode) {
        debugPrint(
          'block:unblock rpc success (204) traceId=$traceId bodyLen=${body.length}',
        );
      }
      return {}; // 빈 맵 반환
    }

    if (kDebugMode) {
      debugPrint(
        'block:unblock rpc failed traceId=$traceId status=${response.statusCode} bodyLen=${body.length}',
      );
    }

    // NetworkGuard가 처리할 수 있도록 NetworkRequestException 발생
    throw _networkGuard.statusCodeToException(
      statusCode: response.statusCode,
      responseBody: body,
    );
  }
}
