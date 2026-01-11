import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/server_error_logger.dart';
import '../../../core/network/network_error.dart';
import '../../../core/network/network_guard.dart';
import '../domain/board_error.dart';
import '../domain/board_post.dart';
import '../domain/board_repository.dart';

const _logPrefix = '[BoardRepo]';

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return SupabaseBoardRepository(config: AppConfigStore.current);
});

class SupabaseBoardRepository implements BoardRepository {
  SupabaseBoardRepository({required AppConfig config})
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
  Future<List<BoardPostSummary>> listBoardPosts({
    required String boardKey,
    String? typeCode,
    int limit = 20,
    int offset = 0,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix listBoardPosts: 설정 누락');
      }
      return [];
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix listBoardPosts: accessToken 없음');
      }
      return [];
    }

    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/list_board_posts',
    );

    try {
      final result = await _networkGuard.execute<List<BoardPostSummary>>(
        operation: () => _executeListBoardPosts(
          uri: uri,
          boardKey: boardKey,
          typeCode: typeCode,
          limit: limit,
          offset: offset,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_board_posts',
        uri: uri,
        method: 'POST',
        meta: {
          'board_key': boardKey,
          'type_code': typeCode,
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix listBoardPosts 실패: $error');
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

  @override
  Future<BoardPostDetail> getBoardPost({
    required String postId,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix getBoardPost: 설정 누락');
      }
      throw BoardException(BoardError.missingConfig);
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix getBoardPost: accessToken 없음');
      }
      throw BoardException(BoardError.unauthorized);
    }

    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/get_board_post',
    );

    try {
      final result = await _networkGuard.execute<BoardPostDetail>(
        operation: () => _executeGetBoardPost(
          uri: uri,
          postId: postId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'get_board_post',
        uri: uri,
        method: 'POST',
        meta: {'post_id': postId},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix getBoardPost 실패: $error');
      }
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw BoardException(BoardError.network);
        case NetworkErrorType.unauthorized:
        case NetworkErrorType.forbidden:
          throw BoardException(BoardError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw BoardException(BoardError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw BoardException(BoardError.serverRejected);
      }
    }
  }

  Future<List<BoardPostSummary>> _executeListBoardPosts({
    required Uri uri,
    required String boardKey,
    required String? typeCode,
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
      utf8.encode(
        jsonEncode({
          'p_board_key': boardKey,
          'p_type_code': typeCode,
          'p_limit': limit,
          'p_offset': offset,
        }),
      ),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'list_board_posts',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'board_key': boardKey, 'type_code': typeCode},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'list_board_posts',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      throw const FormatException('Invalid payload format');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(BoardPostSummary.fromJson)
        .toList();
  }

  Future<BoardPostDetail> _executeGetBoardPost({
    required Uri uri,
    required String postId,
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
      utf8.encode(jsonEncode({'p_post_id': postId})),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'get_board_post',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'post_id': postId},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'get_board_post',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List || payload.isEmpty) {
      throw const FormatException('Invalid payload format');
    }

    final row = payload.first as Map<String, dynamic>;
    return BoardPostDetail.fromJson(row);
  }
}
