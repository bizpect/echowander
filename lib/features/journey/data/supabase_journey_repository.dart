import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/server_error_logger.dart';
import '../../../core/network/network_error.dart';
import '../../../core/network/network_guard.dart';
import '../domain/journey_repository.dart';
import '../domain/journey_storage_repository.dart';

const _journeyImagesBucketId = 'journey-images';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return SupabaseJourneyRepository(config: AppConfigStore.current);
});

final journeyStorageRepositoryProvider = Provider<JourneyStorageRepository>((ref) {
  return SupabaseJourneyStorageRepository(config: AppConfigStore.current);
});

class SupabaseJourneyRepository implements JourneyRepository {
  static const String _logPrefix = '📦[JourneyRepo]';

  SupabaseJourneyRepository({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config),
        _networkGuard = NetworkGuard(errorLogger: ServerErrorLogger(config: config)),
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  @override
  Future<JourneyCreationResult> createJourney({
    required String content,
    required String languageTag,
    required List<String> imagePaths,
    required int recipientCount,
    required String accessToken,
  }) async {
    // 사전 검증: 설정 및 인증
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: supabase 설정 누락');
      }
      throw JourneyCreationException(JourneyCreationError.missingConfig);
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: accessToken 없음');
      }
      throw JourneyCreationException(JourneyCreationError.unauthorized);
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/create_journey');

    try {
      // NetworkGuard를 통한 요청 실행 (재시도 없음: 커밋 액션)
      final result = await _networkGuard.execute<JourneyCreationResult>(
        operation: () => _executeCreateJourney(
          uri: uri,
          content: content,
          languageTag: languageTag,
          imagePaths: imagePaths,
          recipientCount: recipientCount,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'create_journey',
        uri: uri,
        method: 'POST',
        meta: {
          'rpc': 'create_journey',
          'content_length': content.length,
          'image_count': imagePaths.length,
        },
        accessToken: accessToken,
      );

      return result;
    } on NetworkRequestException catch (error) {
      // NetworkRequestException을 JourneyCreationException으로 변환
      if (kDebugMode) {
        debugPrint('compose: create_journey NetworkRequestException: $error');
      }

      switch (error.type) {
        case NetworkErrorType.network:
          throw JourneyCreationException(JourneyCreationError.network);
        case NetworkErrorType.timeout:
          throw JourneyCreationException(JourneyCreationError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyCreationException(JourneyCreationError.unauthorized);
        case NetworkErrorType.forbidden:
          throw JourneyCreationException(JourneyCreationError.serverRejected);
        case NetworkErrorType.serverUnavailable:
          throw JourneyCreationException(JourneyCreationError.serverRejected);
        case NetworkErrorType.invalidPayload:
          throw JourneyCreationException(JourneyCreationError.invalidPayload);
        case NetworkErrorType.serverRejected:
          // 서버 거부 메시지에서 상세 에러 코드 추출 시도
          final mapped = _mapErrorFromResponse(error.message ?? '');
          throw JourneyCreationException(mapped ?? JourneyCreationError.serverRejected);
        case NetworkErrorType.missingConfig:
          throw JourneyCreationException(JourneyCreationError.missingConfig);
        case NetworkErrorType.unknown:
          throw JourneyCreationException(JourneyCreationError.unknown);
      }
    }
  }

  /// create_journey RPC 실제 실행 (NetworkGuard가 호출)
  Future<JourneyCreationResult> _executeCreateJourney({
    required Uri uri,
    required String content,
    required String languageTag,
    required List<String> imagePaths,
    required int recipientCount,
    required String accessToken,
  }) async {
    if (kDebugMode) {
      debugPrint(
        'compose: create_journey 요청 (len=${content.length}, lang=$languageTag, images=${imagePaths.length})',
      );
    }

    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(
      utf8.encode(
        jsonEncode({
          'content': content,
          'language_tag': languageTag,
          'image_paths': imagePaths,
          'recipient_count': recipientCount,
        }),
      ),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      if (kDebugMode) {
        debugPrint('compose: create_journey 실패 ${response.statusCode} $body');
      }

      await _errorLogger.logHttpFailure(
        context: 'create_journey',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'rpc': 'create_journey'},
        uri: uri,
        method: 'POST',
        accessToken: accessToken,
      );

      // NetworkGuard가 처리할 수 있도록 NetworkRequestException 발생
      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'create_journey',
      );
    }

    if (kDebugMode) {
      debugPrint('compose: create_journey 응답 $body');
    }

    // 응답 파싱
    final payload = jsonDecode(body);
    if (payload is! List || payload.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: create_journey 응답 형식 오류 ($payload)');
      }
      throw const FormatException('Invalid payload format');
    }

    final first = payload.first;
    if (first is! Map<String, dynamic>) {
      if (kDebugMode) {
        debugPrint('compose: create_journey 응답 첫 항목 형식 오류 ($first)');
      }
      throw const FormatException('Invalid first item format');
    }

    final journeyId = first['journey_id'];
    final createdAt = first['created_at'];
    if (journeyId is! String || createdAt is! String) {
      if (kDebugMode) {
        debugPrint('compose: create_journey 응답 키 누락 ($first)');
      }
      throw const FormatException('Missing required fields');
    }

    return JourneyCreationResult(
      journeyId: journeyId,
      createdAt: DateTime.parse(createdAt),
    );
  }

  @override
  Future<void> dispatchJourneyMatch({
    required String journeyId,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: dispatch 설정 누락');
      }
      return;
    }
    if (_config.dispatchJobSecret.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: dispatch secret 누락');
      }
      return;
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: dispatch accessToken 없음');
      }
      return;
    }
    final uri = Uri.parse('${_config.supabaseUrl}/functions/v1/dispatch_journey_matches');
    try {
      await _networkGuard.execute<void>(
        operation: () => _executeDispatchJourneyMatch(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'dispatch_journey_matches',
        uri: uri,
        method: 'POST',
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (error) {
      // dispatch 실패는 비블로킹: 이미 로깅되었으므로 조용히 종료
      if (kDebugMode) {
        debugPrint('compose: dispatch 실패 (NetworkRequestException: ${error.type})');
      }
    }
  }

  Future<void> _executeDispatchJourneyMatch({
    required Uri uri,
    required String journeyId,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.headers.set('x-dispatch-secret', _config.dispatchJobSecret);
    request.add(
      utf8.encode(
        jsonEncode({
          'journey_id': journeyId,
        }),
      ),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      if (kDebugMode) {
        debugPrint('compose: dispatch 실패 ${response.statusCode} $body');
      }
      await _errorLogger.logHttpFailure(
        context: 'dispatch_journey_matches',
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
        context: 'dispatch_journey_matches',
      );
    }

    if (kDebugMode) {
      debugPrint('compose: dispatch 성공 $body');
    }
  }

  @override
  Future<List<JourneySummary>> fetchJourneys({
    required int limit,
    required int offset,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('journeys: supabase 설정 누락');
      }
      throw JourneyListException(JourneyListError.missingConfig);
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('journeys: accessToken 없음');
      }
      throw JourneyListException(JourneyListError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/list_journeys');

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<List<JourneySummary>>(
        operation: () => _executeFetchJourneys(
          uri: uri,
          limit: limit,
          offset: offset,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_journeys',
        uri: uri,
        method: 'POST',
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('journeys: list_journeys NetworkRequestException: $error');
      }

      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw JourneyListException(JourneyListError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyListException(JourneyListError.unauthorized);
        case NetworkErrorType.forbidden:
          throw JourneyListException(JourneyListError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw JourneyListException(JourneyListError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
          // 서버 거부 메시지에서 상세 에러 코드 추출 시도
          final mapped = _mapListErrorFromResponse(error.message ?? '');
          throw JourneyListException(mapped ?? JourneyListError.serverRejected);
        case NetworkErrorType.missingConfig:
          throw JourneyListException(JourneyListError.missingConfig);
        case NetworkErrorType.unknown:
          throw JourneyListException(JourneyListError.unknown);
      }
    }
  }

  /// fetchJourneys RPC 실제 실행 (NetworkGuard가 호출)
  Future<List<JourneySummary>> _executeFetchJourneys({
    required Uri uri,
    required int limit,
    required int offset,
    required String accessToken,
  }) async {
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
        debugPrint('journeys: list 실패 ${response.statusCode} $body');
      }
      await _errorLogger.logHttpFailure(
        context: 'list_journeys',
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

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'list_journeys',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      throw const FormatException('Invalid payload format');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => JourneySummary(
            journeyId: row['journey_id'] as String,
            content: row['content'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
            imageCount: (row['image_count'] as num?)?.toInt() ?? 0,
            statusCode: row['status_code'] as String? ?? 'CREATED',
            filterCode: row['filter_code'] as String? ?? 'OK',
          ),
        )
        .toList();
  }

  @override
  Future<List<JourneyInboxItem>> fetchInboxJourneys({
    required int limit,
    required int offset,
    required String accessToken,
  }) async {
    if (kDebugMode) {
      debugPrint('[InboxTrace][Repo] fetchInboxJourneys - start, limit: $limit, offset: $offset, accessToken length: ${accessToken.length}');
    }
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][Repo] fetchInboxJourneys - missing config');
      }
      throw JourneyInboxException(JourneyInboxError.missingConfig);
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][Repo] fetchInboxJourneys - empty accessToken');
      }
      throw JourneyInboxException(JourneyInboxError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/list_inbox_journeys');
    if (kDebugMode) {
      debugPrint('[InboxTrace][Supabase] fetchInboxJourneys - calling RPC: $uri');
    }

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<List<JourneyInboxItem>>(
        operation: () => _executeFetchInboxJourneys(
          uri: uri,
          limit: limit,
          offset: offset,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_inbox_journeys',
        uri: uri,
        method: 'POST',
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][Repo] fetchInboxJourneys NetworkRequestException: $error');
      }

      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw JourneyInboxException(JourneyInboxError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyInboxException(JourneyInboxError.unauthorized);
        case NetworkErrorType.forbidden:
          // ✅ 403(42501) = 권한/정책 문제, refresh로 해결 불가
          throw JourneyInboxException(JourneyInboxError.forbidden);
        case NetworkErrorType.invalidPayload:
          throw JourneyInboxException(JourneyInboxError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw JourneyInboxException(JourneyInboxError.serverRejected);
      }
    }
  }

  /// fetchInboxJourneys RPC 실제 실행 (NetworkGuard가 호출)
  Future<List<JourneyInboxItem>> _executeFetchInboxJourneys({
    required Uri uri,
    required int limit,
    required int offset,
    required String accessToken,
  }) async {
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
    if (kDebugMode) {
      debugPrint('[InboxTrace][Supabase] fetchInboxJourneys - request sent, waiting for response');
    }
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (kDebugMode) {
      debugPrint('[InboxTrace][Supabase] fetchInboxJourneys - response received, statusCode: ${response.statusCode}, body length: ${body.length}');
    }

    if (response.statusCode != HttpStatus.ok) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][Supabase] fetchInboxJourneys - error response: ${response.statusCode} $body');
      }
      await _errorLogger.logHttpFailure(
        context: 'list_inbox_journeys',
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

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'list_inbox_journeys',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][Repo] fetchInboxJourneys - invalid payload type: ${payload.runtimeType}');
      }
      throw const FormatException('Invalid payload format');
    }
    if (kDebugMode) {
      debugPrint('[InboxTrace][Supabase] fetchInboxJourneys - response row count: ${payload.length}');
    }

    final items = <JourneyInboxItem>[];
    for (var i = 0; i < payload.length; i++) {
      final row = payload[i];
      if (row is! Map<String, dynamic>) {
        if (kDebugMode) {
          debugPrint('[InboxTrace][Repo] fetchInboxJourneys - row $i is not Map, skipping');
        }
        continue;
      }
      try {
        final item = JourneyInboxItem(
          journeyId: row['journey_id'] as String,
          senderUserId: row['sender_user_id'] as String? ?? '',
          content: row['content'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          imageCount: (row['image_count'] as num?)?.toInt() ?? 0,
          recipientStatus: row['recipient_status'] as String? ?? 'ASSIGNED',
        );
        if (kDebugMode && i == 0) {
          debugPrint('[InboxTrace][Repo] fetchInboxJourneys - first item mapped: journeyId=${item.journeyId}, createdAt=${item.createdAt}, status=${item.recipientStatus}');
        }
        items.add(item);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[InboxTrace][Repo] fetchInboxJourneys - mapping failed for row $i: $e');
        }
      }
    }
    if (kDebugMode) {
      debugPrint('[InboxTrace][Repo] fetchInboxJourneys - completed, mapped items: ${items.length}');
    }
    return items;
  }

  @override
  Future<String> debugAuth({
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return 'missing_config';
    }
    // debug_inbox 함수 호출 (auth.uid()와 쿼리 결과 확인)
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/debug_inbox');
    try {
      final request = await _client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set('apikey', _config.supabaseAnonKey);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.add(utf8.encode('{}'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return 'status: ${response.statusCode}, body: $body';
    } catch (e) {
      return 'error: $e';
    }
  }

  @override
  Future<List<String>> fetchInboxJourneyImageUrls({
    required String journeyId,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return [];
    }
    if (accessToken.isEmpty) {
      return [];
    }
    final paths = await _fetchInboxJourneyImagePaths(
      journeyId: journeyId,
      accessToken: accessToken,
    );
    if (paths.isEmpty) {
      return [];
    }
    final signedUrls = <String>[];
    for (final path in paths) {
      final signed = await _signStoragePath(
        storagePath: path,
        accessToken: accessToken,
      );
      if (signed != null) {
        signedUrls.add(signed);
      }
    }
    return signedUrls;
  }

  @override
  Future<void> respondJourney({
    required String journeyId,
    required String content,
    required String accessToken,
  }) async {
    // 사전 검증
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyActionException(JourneyActionError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyActionException(JourneyActionError.unauthorized);
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/respond_journey');

    try {
      await _networkGuard.execute<void>(
        operation: () => _executeRespondJourney(
          uri: uri,
          journeyId: journeyId,
          content: content,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'respond_journey',
        uri: uri,
        method: 'POST',
        meta: {'journey_id': journeyId, 'content_length': content.length},
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][Repo] respondJourney NetworkRequestException: $error');
      }

      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw JourneyActionException(JourneyActionError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyActionException(JourneyActionError.unauthorized);
        case NetworkErrorType.forbidden:
          throw JourneyActionException(JourneyActionError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw JourneyActionException(JourneyActionError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw JourneyActionException(JourneyActionError.serverRejected);
      }
    }
  }

  Future<void> _executeRespondJourney({
    required Uri uri,
    required String journeyId,
    required String content,
    required String accessToken,
  }) async {
    if (kDebugMode) {
      debugPrint('[InboxReplyTrace][Repo] respond_journey 요청 (journeyId: $journeyId, content length: ${content.length})');
    }

    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(
      utf8.encode(
        jsonEncode({
          'target_journey_id': journeyId,
          'response_content': content,
        }),
      ),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][Repo] respond_journey 실패 ${response.statusCode} $body');
      }

      await _errorLogger.logHttpFailure(
        context: 'respond_journey',
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
        context: 'respond_journey',
      );
    }

    if (kDebugMode) {
      debugPrint('[InboxReplyTrace][Repo] respond_journey 성공');
    }
  }

  @override
  Future<void> passJourney({
    required String journeyId,
    required String accessToken,
  }) async {
    // 새로운 RPC: pass_inbox_item_and_forward 사용 (pass 기록 + 랜덤 전송 + redaction)
    await _executeSimpleJourneyAction(
      rpc: 'pass_inbox_item_and_forward',
      journeyId: journeyId,
      accessToken: accessToken,
      payload: {'target_journey_id': journeyId},
    );
  }

  @override
  Future<void> reportJourney({
    required String journeyId,
    required String reasonCode,
    required String accessToken,
  }) async {
    await _executeSimpleJourneyAction(
      rpc: 'report_journey',
      journeyId: journeyId,
      accessToken: accessToken,
      payload: {
        'target_journey_id': journeyId,
        'reason_code': reasonCode,
      },
      meta: {'reason_code': reasonCode},
    );
  }

  /// 단순 Journey 액션 실행 (pass, report 등)
  Future<void> _executeSimpleJourneyAction({
    required String rpc,
    required String journeyId,
    required String accessToken,
    required Map<String, dynamic> payload,
    Map<String, dynamic>? meta,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyActionException(JourneyActionError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyActionException(JourneyActionError.unauthorized);
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/$rpc');

    try {
      if (kDebugMode) {
        debugPrint('[$_logPrefix][report_journey:journeyId=$journeyId] 신고 시작: reason=${meta?['reason_code'] ?? payload['reason_code']}');
      }
      await _networkGuard.execute<void>(
        operation: () => _executeRpcPost(
          uri: uri,
          payload: payload,
          accessToken: accessToken,
          context: rpc,
        ),
        retryPolicy: RetryPolicy.none,
        context: rpc,
        uri: uri,
        method: 'POST',
        meta: {'journey_id': journeyId, ...?meta},
        accessToken: accessToken,
      );
      if (kDebugMode) {
        debugPrint('[$_logPrefix][report_journey:journeyId=$journeyId] 신고 성공 판정: NetworkGuard 완료');
      }
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('[$_logPrefix][report_journey:journeyId=$journeyId] NetworkRequestException: type=${error.type}, statusCode=${error.statusCode}, message=${error.message}');
      }
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw JourneyActionException(JourneyActionError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyActionException(JourneyActionError.unauthorized);
        case NetworkErrorType.forbidden:
          throw JourneyActionException(JourneyActionError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw JourneyActionException(JourneyActionError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          if (kDebugMode) {
            debugPrint('[$_logPrefix][report_journey:journeyId=$journeyId] serverRejected로 매핑: 원인 type=${error.type}, statusCode=${error.statusCode}, isEmpty=${error.isEmpty}, isHtml=${error.isHtml}, parsedErrorCode=${error.parsedErrorCode}');
          }
          throw JourneyActionException(JourneyActionError.serverRejected);
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[$_logPrefix][report_journey:journeyId=$journeyId] 예상치 못한 예외: $error');
        debugPrint('[$_logPrefix][report_journey:journeyId=$journeyId] 스택 트레이스: $stackTrace');
      }
      // 예상치 못한 예외도 serverRejected로 매핑
      throw JourneyActionException(JourneyActionError.serverRejected);
    }
  }

  /// RPC POST 요청 실행 (공통)
  Future<void> _executeRpcPost({
    required Uri uri,
    required Map<String, dynamic> payload,
    required String accessToken,
    required String context,
  }) async {
    final journeyId = payload['target_journey_id'] as String? ?? payload['journey_id'] as String?;
    final traceLabel = journeyId != null ? '$context:journeyId=$journeyId' : context;

    final request = await _client.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode(payload)));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    // 200 OK 또는 204 No Content는 성공으로 처리
    // (PostgREST는 void 반환 함수에 대해 204를 반환할 수 있음)
    if (response.statusCode == HttpStatus.ok || response.statusCode == HttpStatus.noContent) {
      // 성공: body가 비어있어도 OK (void 반환 함수의 경우)
      if (kDebugMode) {
        if (body.isEmpty) {
          debugPrint('[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, body=empty');
        } else {
          try {
            final decoded = jsonDecode(body);
            if (decoded is List && decoded.isNotEmpty) {
              final first = decoded[0];
              if (first is Map<String, dynamic>) {
                final success = first['success'] as bool?;
                final reportId = first['report_id'];
                debugPrint('[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, success=$success, report_id=$reportId, resType=List[Map], resKeys=${first.keys.toList()}');
              } else {
                debugPrint('[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, resType=${decoded.runtimeType}');
              }
            } else if (decoded is Map<String, dynamic>) {
              final success = decoded['success'] as bool?;
              final reportId = decoded['report_id'];
              debugPrint('[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, success=$success, report_id=$reportId, resType=Map, resKeys=${decoded.keys.toList()}');
            } else {
              debugPrint('[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, resType=${decoded.runtimeType}');
            }
          } catch (e) {
            // JSON 파싱 실패는 무시 (void 반환 함수는 빈 body 가능)
            debugPrint('[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, body 파싱 실패(무시): $e');
          }
        }
      }
      return;
    }

    // 그 외의 상태 코드는 실패
    if (kDebugMode) {
      debugPrint('[$_logPrefix][$traceLabel] 실패: status=${response.statusCode}, bodyLength=${body.length}, bodyPreview=${body.length > 200 ? body.substring(0, 200) : body}');
    }

    await _errorLogger.logHttpFailure(
      context: context,
      uri: uri,
      method: 'POST',
      statusCode: response.statusCode,
      errorMessage: body,
      meta: payload,
      accessToken: accessToken,
    );

    throw _networkGuard.statusCodeToException(
      statusCode: response.statusCode,
      responseBody: body,
      context: context,
    );
  }

  @override
  Future<void> reportJourneyResponse({
    required int responseId,
    required String reasonCode,
    required String accessToken,
  }) async {
    // 사전 검증
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyResultReportException(JourneyResultReportError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyResultReportException(JourneyResultReportError.unauthorized);
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/report_journey_response');

    try {
      // NetworkGuard를 통한 요청 실행 (재시도 없음: 커밋 액션)
      await _networkGuard.execute<void>(
        operation: () => _executeRpcPost(
          uri: uri,
          payload: {
            'target_response_id': responseId,
            'reason_code': reasonCode,
          },
          accessToken: accessToken,
          context: 'report_journey_response',
        ),
        retryPolicy: RetryPolicy.none,
        context: 'report_journey_response',
        uri: uri,
        method: 'POST',
        meta: {
          'response_id': responseId,
          'reason_code': reasonCode,
        },
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (error) {
      // NetworkRequestException을 JourneyResultReportException으로 변환
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw JourneyResultReportException(JourneyResultReportError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyResultReportException(JourneyResultReportError.unauthorized);
        case NetworkErrorType.forbidden:
          throw JourneyResultReportException(JourneyResultReportError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw JourneyResultReportException(JourneyResultReportError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw JourneyResultReportException(JourneyResultReportError.serverRejected);
      }
    }
  }

  @override
  Future<JourneyProgress> fetchJourneyProgress({
    required String journeyId,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyProgressException(JourneyProgressError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyProgressException(JourneyProgressError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/get_journey_progress');

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<JourneyProgress>(
        operation: () => _executeFetchJourneyProgress(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'get_journey_progress',
        uri: uri,
        method: 'POST',
        meta: {'journey_id': journeyId},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw JourneyProgressException(JourneyProgressError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyProgressException(JourneyProgressError.unauthorized);
        case NetworkErrorType.forbidden:
          throw JourneyProgressException(JourneyProgressError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw JourneyProgressException(JourneyProgressError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw JourneyProgressException(JourneyProgressError.serverRejected);
      }
    }
  }

  /// fetchJourneyProgress RPC 실제 실행 (NetworkGuard가 호출)
  Future<JourneyProgress> _executeFetchJourneyProgress({
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
        jsonEncode({
          'target_journey_id': journeyId,
        }),
      ),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'get_journey_progress',
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
        context: 'get_journey_progress',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List || payload.isEmpty) {
      throw const FormatException('Invalid payload format');
    }
    final row = payload.first as Map<String, dynamic>;
    return JourneyProgress(
      journeyId: row['journey_id'] as String,
      statusCode: row['status_code'] as String,
      responseTarget: (row['response_target'] as num?)?.toInt() ?? 0,
      respondedCount: (row['responded_count'] as num?)?.toInt() ?? 0,
      assignedCount: (row['assigned_count'] as num?)?.toInt() ?? 0,
      passedCount: (row['passed_count'] as num?)?.toInt() ?? 0,
      reportedCount: (row['reported_count'] as num?)?.toInt() ?? 0,
      relayDeadlineAt: DateTime.parse(row['relay_deadline_at'] as String),
      countryCodes: (row['country_codes'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
    );
  }

  @override
  Future<List<JourneyResultItem>> fetchJourneyResults({
    required String journeyId,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyResultException(JourneyResultError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyResultException(JourneyResultError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/list_journey_results');

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<List<JourneyResultItem>>(
        operation: () => _executeFetchJourneyResults(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_journey_results',
        uri: uri,
        method: 'POST',
        meta: {'journey_id': journeyId},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw JourneyResultException(JourneyResultError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyResultException(JourneyResultError.unauthorized);
        case NetworkErrorType.forbidden:
          throw JourneyResultException(JourneyResultError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw JourneyResultException(JourneyResultError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw JourneyResultException(JourneyResultError.serverRejected);
      }
    }
  }

  /// fetchJourneyResults RPC 실제 실행 (NetworkGuard가 호출)
  Future<List<JourneyResultItem>> _executeFetchJourneyResults({
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
        jsonEncode({
          'target_journey_id': journeyId,
        }),
      ),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'list_journey_results',
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
        context: 'list_journey_results',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      throw const FormatException('Invalid payload format');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => JourneyResultItem(
            responseId: (row['response_id'] as num?)?.toInt() ?? 0,
            content: row['content'] as String? ?? '',
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<List<String>> _fetchInboxJourneyImagePaths({
    required String journeyId,
    required String accessToken,
  }) async {
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/list_inbox_journey_images');

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<List<String>>(
        operation: () => _executeFetchInboxJourneyImagePaths(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_inbox_journey_images',
        uri: uri,
        method: 'POST',
        meta: {'journey_id': journeyId},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (_) {
      // 이미지 경로 조회 실패는 빈 배열 반환 (비블로킹)
      return [];
    }
  }

  /// _fetchInboxJourneyImagePaths RPC 실제 실행 (NetworkGuard가 호출)
  Future<List<String>> _executeFetchInboxJourneyImagePaths({
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
        jsonEncode({
          'target_journey_id': journeyId,
        }),
      ),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'list_inbox_journey_images',
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
        context: 'list_inbox_journey_images',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      throw const FormatException('Invalid payload format');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map((row) => row['storage_path'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<String?> _signStoragePath({
    required String storagePath,
    required String accessToken,
  }) async {
    final uri = Uri.parse(
      '${_config.supabaseUrl}/storage/v1/object/sign/$_journeyImagesBucketId/$storagePath',
    );
    try {
      final request = await _client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set('apikey', _config.supabaseAnonKey);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.add(
        utf8.encode(
          jsonEncode({
            'expiresIn': 3600,
          }),
        ),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        await _errorLogger.logHttpFailure(
          context: 'sign_journey_image',
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: {
            'storage_path': storagePath,
          },
          accessToken: accessToken,
        );
        return null;
      }
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic>) {
        final signed = payload['signedURL'];
        if (signed is String && signed.isNotEmpty) {
          return '${_config.supabaseUrl}$signed';
        }
      }
      return null;
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'sign_journey_image',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'storage_path': storagePath,
        },
        accessToken: accessToken,
      );
      return null;
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'sign_journey_image',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'storage_path': storagePath,
        },
        accessToken: accessToken,
      );
      return null;
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'sign_journey_image',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'storage_path': storagePath,
        },
        accessToken: accessToken,
      );
      return null;
    }
  }

  JourneyCreationError? _mapErrorFromResponse(String body) {
    final errorCode = _extractErrorCode(body);
    switch (errorCode) {
      case 'empty_content':
        return JourneyCreationError.emptyContent;
      case 'content_too_long':
        return JourneyCreationError.contentTooLong;
      case 'missing_language':
        return JourneyCreationError.missingLanguage;
      case 'too_many_images':
        return JourneyCreationError.tooManyImages;
      case 'contains_url':
      case 'contains_email':
      case 'contains_phone':
        return JourneyCreationError.containsForbidden;
      case 'invalid_recipient_count':
        return JourneyCreationError.invalidRecipientCount;
      case 'unauthorized':
        return JourneyCreationError.unauthorized;
      case 'missing_code_value':
        return JourneyCreationError.missingCodeValue;
      default:
        return null;
    }
  }

  JourneyListError? _mapListErrorFromResponse(String body) {
    final errorCode = _extractErrorCode(body);
    switch (errorCode) {
      case 'unauthorized':
        return JourneyListError.unauthorized;
      default:
        return null;
    }
  }

  String? _extractErrorCode(String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic>) {
        final message = payload['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        final code = payload['code'];
        if (code is String && code.isNotEmpty) {
          return code;
        }
        final error = payload['error'];
        if (error is String && error.isNotEmpty) {
          return error;
        }
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

class SupabaseJourneyStorageRepository implements JourneyStorageRepository {
  SupabaseJourneyStorageRepository({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config),
        _networkGuard = NetworkGuard(errorLogger: ServerErrorLogger(config: config)),
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  @override
  Future<List<String>> uploadImages({
    required List<String> filePaths,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: storage 설정 누락');
      }
      throw JourneyStorageException(JourneyStorageError.missingConfig);
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: storage accessToken 없음');
      }
      throw JourneyStorageException(JourneyStorageError.unauthorized);
    }
    final uploaded = <String>[];
    try {
      for (var i = 0; i < filePaths.length; i += 1) {
        final path = filePaths[i];
        if (kDebugMode) {
          debugPrint('compose: 이미지 업로드 시작 ($path)');
        }
        final bytes = await File(path).readAsBytes();
        final storagePath = _buildStoragePath(path, i);
        final uploadUri = _storageUri(storagePath);
        try {
          await _networkGuard.execute<void>(
            operation: () => _executeUploadObject(
              uri: uploadUri,
              storagePath: storagePath,
              bytes: bytes,
              accessToken: accessToken,
              contentType: _contentTypeForPath(path),
            ),
            retryPolicy: RetryPolicy.none,
            context: 'journey_image_upload',
            uri: uploadUri,
            method: 'POST',
            meta: {
              'storage_path': storagePath,
            },
            accessToken: accessToken,
          );
        } on NetworkRequestException catch (error) {
          if (kDebugMode) {
            debugPrint('compose: 이미지 업로드 실패 (NetworkRequestException: ${error.type})');
          }
          await deleteImages(paths: uploaded, accessToken: accessToken);
          switch (error.type) {
            case NetworkErrorType.unauthorized:
              throw JourneyStorageException(JourneyStorageError.unauthorized);
            case NetworkErrorType.forbidden:
              throw JourneyStorageException(JourneyStorageError.unauthorized);
            case NetworkErrorType.network:
            case NetworkErrorType.timeout:
            case NetworkErrorType.serverUnavailable:
              throw JourneyStorageException(JourneyStorageError.network);
            case NetworkErrorType.serverRejected:
            case NetworkErrorType.invalidPayload:
            case NetworkErrorType.missingConfig:
            case NetworkErrorType.unknown:
              throw JourneyStorageException(JourneyStorageError.uploadFailed);
          }
        }
        uploaded.add(storagePath);
        if (kDebugMode) {
          debugPrint('compose: 이미지 업로드 완료 ($storagePath)');
        }
      }
      return uploaded;
    } on JourneyStorageException {
      if (kDebugMode) {
        debugPrint('compose: 이미지 업로드 실패 (JourneyStorageException)');
      }
      await deleteImages(paths: uploaded, accessToken: accessToken);
      rethrow;
    } on FileSystemException {
      if (kDebugMode) {
        debugPrint('compose: 이미지 업로드 실패 (FileSystemException)');
      }
      await deleteImages(paths: uploaded, accessToken: accessToken);
      throw JourneyStorageException(JourneyStorageError.uploadFailed);
    }
  }

  @override
  Future<void> deleteImages({
    required List<String> paths,
    required String accessToken,
  }) async {
    // 백그라운드 작업: 설정 누락 시 조용히 실패
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return;
    }
    if (accessToken.isEmpty) {
      return;
    }

    // NetworkGuard 인스턴스 생성 (storage 작업용)
    final networkGuard = NetworkGuard(errorLogger: _errorLogger);

    for (final path in paths) {
      if (kDebugMode) {
        debugPrint('compose: 이미지 삭제 ($path)');
      }
      final uri = _storageUri(path);

      try {
        // NetworkGuard를 통한 DELETE 요청 (재시도 없음: storage 정리는 멱등성 보장)
        await networkGuard.execute<void>(
          operation: () => _executeDeleteImage(
            uri: uri,
            path: path,
            accessToken: accessToken,
          ),
          retryPolicy: RetryPolicy.none,
          context: 'journey_image_delete',
          uri: uri,
          method: 'DELETE',
          meta: {'storage_path': path},
          accessToken: accessToken,
        );
      } on NetworkRequestException catch (_) {
        // 백그라운드 삭제 실패는 조용히 무시 (이미 로깅됨)
        if (kDebugMode) {
          debugPrint('compose: 이미지 삭제 실패 ($path) - 무시됨');
        }
      }
    }
  }

  /// 이미지 삭제 실제 실행 (NetworkGuard가 호출)
  Future<void> _executeDeleteImage({
    required Uri uri,
    required String path,
    required String accessToken,
  }) async {
    final request = await _client.deleteUrl(uri);
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode >= HttpStatus.badRequest) {
      await _errorLogger.logHttpFailure(
        context: 'journey_image_delete',
        uri: uri,
        method: 'DELETE',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'storage_path': path},
        accessToken: accessToken,
      );

      final networkGuard = NetworkGuard(errorLogger: _errorLogger);
      throw networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'journey_image_delete',
      );
    }
  }

  Future<void> _executeUploadObject({
    required Uri uri,
    required String storagePath,
    required List<int> bytes,
    required String accessToken,
    required String contentType,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.headers.set(HttpHeaders.contentTypeHeader, contentType);
    request.headers.set('x-upsert', 'true');
    request.add(bytes);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.created) {
      if (kDebugMode) {
        debugPrint('compose: storage 업로드 실패 ${response.statusCode}');
      }
      await _errorLogger.logHttpFailure(
        context: 'journey_image_upload',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {
          'storage_path': storagePath,
        },
        accessToken: accessToken,
      );
      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'journey_image_upload',
      );
    }
  }

  Uri _storageUri(String storagePath) {
    return Uri.parse(
      '${_config.supabaseUrl}/storage/v1/object/$_journeyImagesBucketId/$storagePath',
    );
  }

  String _buildStoragePath(String path, int index) {
    final extension = _extensionFromPath(path);
    final random = Random.secure().nextInt(1 << 32);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'journeys/$timestamp-$random-$index.$extension';
  }

  String _extensionFromPath(String path) {
    final parts = path.split('.');
    if (parts.length < 2) {
      return 'jpg';
    }
    return parts.last.toLowerCase();
  }

  String _contentTypeForPath(String path) {
    final extension = _extensionFromPath(path);
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
