import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/business_error_mapper.dart';
import '../../../core/logging/log_sanitizer.dart';
import '../../../core/logging/server_error_logger.dart';
import '../../../core/media/storage_url_normalizer.dart';
import '../../../core/network/network_error.dart';
import '../../../core/network/network_guard.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/session/session_state.dart';
import '../domain/journey_repository.dart';
import '../domain/sent_journey_detail.dart';
import '../domain/sent_journey_response.dart';
import '../domain/journey_storage_repository.dart';

const _journeyImagesBucketId = 'journey-images';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return SupabaseJourneyRepository(
    config: AppConfigStore.current,
    ref: ref,
  );
});

final journeyStorageRepositoryProvider = Provider<JourneyStorageRepository>((
  ref,
) {
  return SupabaseJourneyStorageRepository(config: AppConfigStore.current);
});

class SupabaseJourneyRepository implements JourneyRepository {
  static const String _logPrefix = '📦[JourneyRepo]';

  SupabaseJourneyRepository({
    required AppConfig config,
    required Ref ref,
  })  : _config = config,
        _ref = ref,
        _errorLogger = ServerErrorLogger(config: config),
        _networkGuard = NetworkGuard(
          errorLogger: ServerErrorLogger(config: config),
        ),
        _client = HttpClient();

  final AppConfig _config;
  final Ref _ref;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  /// ✅ 키 호환 헬퍼: created_at 또는 journey_created_at에서 DateTime 추출
  /// RPC 함수가 컬럼명을 변경해도 클라이언트가 깨지지 않도록 방어
  DateTime _parseCreatedAt(Map<String, dynamic> row, String context) {
    final createdAtRaw = row['created_at'] ?? row['journey_created_at'];
    if (createdAtRaw == null) {
      throw FormatException(
        '[$context] Missing required field: created_at (or journey_created_at)',
      );
    }
    if (createdAtRaw is! String) {
      throw FormatException(
        '[$context] createdAt field is not String: ${createdAtRaw.runtimeType}',
      );
    }
    return DateTime.parse(createdAtRaw);
  }

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

    // 최신 accessToken을 동적으로 가져오는 클로저
    String getCurrentAccessToken() {
      final sessionState = _ref.read(sessionManagerProvider);
      return sessionState.accessToken ?? accessToken;
    }

    try {
      // NetworkGuard를 통한 요청 실행 (재시도 없음: 커밋 액션)
      // PGRST303 발생 시 refresh + 1회 retry를 위해 onUnauthorizedRefresh 콜백 제공
      final result = await _networkGuard.execute<JourneyCreationResult>(
        operation: () => _executeCreateJourney(
          uri: uri,
          content: content,
          languageTag: languageTag,
          imagePaths: imagePaths,
          recipientCount: recipientCount,
          accessToken: getCurrentAccessToken(),
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
        onUnauthorizedRefresh: () async {
          // 401 + PGRST303 발생 시 refresh 시도
          if (kDebugMode) {
            debugPrint('$_logPrefix create_journey: PGRST303 → refresh 시도');
          }
          final sessionManager = _ref.read(sessionManagerProvider.notifier);
          await sessionManager.handleUnauthorized(
            reason: 'PGRST303',
            source: 'create_journey',
          );
          final newState = _ref.read(sessionManagerProvider);
          if (newState.status == SessionStatus.authenticated &&
              newState.accessToken != null &&
              newState.accessToken!.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('$_logPrefix create_journey: refresh 성공');
            }
            return newState.accessToken;
          }
          if (kDebugMode) {
            debugPrint('$_logPrefix create_journey: refresh 실패');
          }
          return null;
        },
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
          // ✅ 공통 비즈니스 에러 매퍼 사용
          final businessError = BusinessErrorMapper.fromPostgrest(
            statusCode: error.statusCode,
            code: error.parsedErrorCode,
            message: error.parsedErrorMessage,
          );
          if (businessError != null) {
            // 비즈니스 에러 키를 도메인 에러로 변환
            switch (businessError) {
              case BusinessErrorKey.contentBlocked:
                if (kDebugMode) {
                  debugPrint(
                    'compose: content_blocked 비즈니스 에러 감지 (P0001)',
                  );
                }
                throw JourneyCreationException(
                  JourneyCreationError.contentBlocked,
                );
              case BusinessErrorKey.nicknameForbidden:
              case BusinessErrorKey.nicknameTaken:
                // journey 생성에서는 발생하지 않는 에러
                break;
            }
          }
          // 서버 거부 메시지에서 상세 에러 코드 추출 시도
          final mapped = _mapErrorFromResponse(error.message ?? '');
          throw JourneyCreationException(
            mapped ?? JourneyCreationError.serverRejected,
          );
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
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
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

    // 응답 파싱 (관측성 강화)
    final payload = jsonDecode(body);

    if (kDebugMode) {
      debugPrint('compose: payload type=${payload.runtimeType}');
      if (payload is List) {
        debugPrint('compose: payload is List, length=${payload.length}');
        if (payload.isNotEmpty) {
          final first = payload.first;
          debugPrint('compose: first element type=${first.runtimeType}');
          if (first is Map<String, dynamic>) {
            debugPrint('compose: first keys=${first.keys.toList()}');
          }
        }
      } else if (payload is Map) {
        debugPrint('compose: payload is Map, keys=${payload.keys.toList()}');
      }
    }

    if (payload is! List || payload.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: create_journey 응답 형식 오류 (expected non-empty List, got ${payload.runtimeType})');
      }
      throw const FormatException('Invalid payload format: expected non-empty List');
    }

    final first = payload.first;
    if (first is! Map<String, dynamic>) {
      if (kDebugMode) {
        debugPrint('compose: create_journey 응답 형식 오류 (first element is not Map, got ${first.runtimeType})');
      }
      throw const FormatException('Invalid payload format: first element is not Map');
    }

    // content_blocked 에러 체크
    if (first.containsKey('code') && first['code'] == 'content_blocked') {
      if (kDebugMode) {
        debugPrint('compose: content_blocked 에러');
      }
      throw JourneyCreationException(JourneyCreationError.contentBlocked);
    }

    // 필수 필드 존재 여부 확인
    if (!first.containsKey('journey_id')) {
      if (kDebugMode) {
        debugPrint('compose: Missing required field: journey_id');
      }
      throw const FormatException('Missing required field: journey_id');
    }

    // 각 필드 파싱 시도 (관측성 강화)
    try {
      if (kDebugMode) {
        debugPrint('compose: Parsing journey_id...');
      }
      final journeyId = first['journey_id'] as String;

      if (kDebugMode) {
        debugPrint('compose: Parsing createdAt (source key: ${first.containsKey('created_at') ? 'created_at' : 'journey_created_at'})...');
      }
      final createdAt = _parseCreatedAt(first, 'create_journey');

      if (kDebugMode) {
        debugPrint('compose: Parsing moderation_status...');
      }
      final moderationStatus = first['moderation_status'] as String?;

      if (kDebugMode) {
        debugPrint('compose: Parsing content_clean...');
      }
      final contentClean = first['content_clean'] as String?;

      if (kDebugMode) {
        debugPrint('compose: All fields parsed successfully');
      }

      return JourneyCreationResult(
        journeyId: journeyId,
        createdAt: createdAt,
        moderationStatus: moderationStatus,
        contentClean: contentClean,
      );
    } on TypeError catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('compose: TypeError during field parsing: $e');
        debugPrint('compose: StackTrace: ${stackTrace.toString().split('\n').take(10).join('\n')}');
      }
      throw FormatException('Field type mismatch: $e');
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint('compose: FormatException during date parsing: $e');
      }
      throw FormatException('Date parsing failed: $e');
    }
  }

  /// 에러 메시지에서 에러 코드 매핑
  JourneyCreationError? _mapErrorFromResponse(String responseBody) {
    final errorCode = _extractErrorCode(responseBody);
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
      case 'content_blocked':
        return JourneyCreationError.contentBlocked;
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
    final uri = Uri.parse(
      '${_config.supabaseUrl}/functions/v1/dispatch_journey_matches',
    );
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
        meta: {'journey_id': journeyId},
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (error) {
      // dispatch 실패는 비블로킹: 이미 로깅되었으므로 조용히 종료
      if (kDebugMode) {
        debugPrint(
          'compose: dispatch 실패 (NetworkRequestException: ${error.type})',
        );
      }
    }
  }

  Future<void> _executeDispatchJourneyMatch({
    required Uri uri,
    required String journeyId,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.headers.set('x-dispatch-secret', _config.dispatchJobSecret);
    request.add(utf8.encode(jsonEncode({'journey_id': journeyId})));
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
        meta: {'journey_id': journeyId},
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
        meta: {'limit': limit, 'offset': offset},
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
        debugPrint('journeys: list 실패 ${response.statusCode} $body');
      }
      await _errorLogger.logHttpFailure(
        context: 'list_journeys',
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
            createdAt: _parseCreatedAt(row, 'list_journeys'),
            imageCount: (row['image_count'] as num?)?.toInt() ?? 0,
            statusCode: row['status_code'] as String? ?? 'CREATED',
            filterCode: row['filter_code'] as String? ?? 'OK',
            isRewardUnlocked: row['is_reward_unlocked'] as bool? ?? false,
            sentCount: (row['sent_count'] as num?)?.toInt() ?? 0,
            respondedCount: (row['responded_count'] as num?)?.toInt() ?? 0,
            requestedRecipientCount: (row['requested_recipient_count'] as num?)?.toInt() ?? 0,
            assignedCount: (row['assigned_count'] as num?)?.toInt() ?? 0,
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
      debugPrint(
        '[InboxTrace][Repo] fetchInboxJourneys - start, limit: $limit, offset: $offset, accessToken length: ${accessToken.length}',
      );
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
    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/list_inbox_journeys',
    );
    if (kDebugMode) {
      debugPrint(
        '[InboxTrace][Supabase] fetchInboxJourneys - calling RPC: $uri',
      );
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
        meta: {'limit': limit, 'offset': offset},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[InboxTrace][Repo] fetchInboxJourneys NetworkRequestException: $error',
        );
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
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(
      utf8.encode(jsonEncode({'page_size': limit, 'page_offset': offset})),
    );
    if (kDebugMode) {
      debugPrint(
        '[InboxTrace][Supabase] fetchInboxJourneys - request sent, waiting for response',
      );
    }
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (kDebugMode) {
      debugPrint(
        '[InboxTrace][Supabase] fetchInboxJourneys - response received, statusCode: ${response.statusCode}, body length: ${body.length}',
      );
    }

    if (response.statusCode != HttpStatus.ok) {
      if (kDebugMode) {
        debugPrint(
          '[InboxTrace][Supabase] fetchInboxJourneys - error response: ${response.statusCode} $body',
        );
      }
      await _errorLogger.logHttpFailure(
        context: 'list_inbox_journeys',
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
        context: 'list_inbox_journeys',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      if (kDebugMode) {
        debugPrint(
          '[InboxTrace][Repo] fetchInboxJourneys - invalid payload type: ${payload.runtimeType}',
        );
      }
      throw const FormatException('Invalid payload format');
    }
    if (kDebugMode) {
      debugPrint(
        '[InboxTrace][Supabase] fetchInboxJourneys - response row count: ${payload.length}',
      );
    }

    final items = <JourneyInboxItem>[];
    for (var i = 0; i < payload.length; i++) {
      final row = payload[i];
      if (row is! Map<String, dynamic>) {
        if (kDebugMode) {
          debugPrint(
            '[InboxTrace][Repo] fetchInboxJourneys - row $i is not Map, skipping',
          );
        }
        continue;
      }
      try {
        final recipientIdRaw = row['recipient_id'];
        if (recipientIdRaw == null) {
          if (kDebugMode) {
            debugPrint(
              '[InboxTrace][Repo] fetchInboxJourneys - row $i missing recipient_id, skipping',
            );
          }
          continue;
        }
        final item = JourneyInboxItem(
          recipientId: (recipientIdRaw as num).toInt(),
          journeyId: row['journey_id'] as String,
          senderUserId: row['sender_user_id'] as String? ?? '',
          senderNickname: (row['sender_nickname'] as String?)?.trim() ?? '',
          content: row['content'] as String,
          createdAt: _parseCreatedAt(row, 'fetch_inbox_journeys'),
          imageCount: (row['image_count'] as num?)?.toInt() ?? 0,
          recipientStatus: row['recipient_status'] as String? ?? 'ASSIGNED',
          contentClean: row['content_clean'] as String?,
        );
        if (kDebugMode && i == 0) {
          debugPrint(
            '[InboxTrace][Repo] fetchInboxJourneys - first item mapped: journeyId=${item.journeyId}, createdAt=${item.createdAt}, status=${item.recipientStatus}',
          );
        }
        items.add(item);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[InboxTrace][Repo] fetchInboxJourneys - mapping failed for row $i: $e',
          );
        }
      }
    }
    if (kDebugMode) {
      debugPrint(
        '[InboxTrace][Repo] fetchInboxJourneys - completed, mapped items: ${items.length}',
      );
    }
    return items;
  }

  @override
  Future<String> debugAuth({required String accessToken}) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return 'missing_config';
    }
    // debug_inbox 함수 호출 (auth.uid()와 쿼리 결과 확인)
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/debug_inbox');
    try {
      final request = await _client.postUrl(uri);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      request.headers.set('apikey', _config.supabaseAnonKey);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );
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
    final paths = await fetchInboxJourneyImagePaths(
      journeyId: journeyId,
      accessToken: accessToken,
    );
    if (paths.isEmpty) {
      return [];
    }
    // createSignedUrls로 일괄 변환 (NetworkGuard 경유)
    return await createSignedUrls(
      bucketId: _journeyImagesBucketId,
      paths: paths,
      accessToken: accessToken,
    );
  }

  @override
  Future<List<String>> createSignedUrls({
    required String bucketId,
    required List<String> paths,
    required String accessToken,
  }) async {
    // bucketId/path 정규화 검증
    final normalizedBucketId = bucketId.trim();
    if (normalizedBucketId.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix createSignedUrls: bucketId가 비어있음');
      }
      throw NetworkRequestException(
        type: NetworkErrorType.invalidPayload,
        message: 'bucketId is empty',
      );
    }
    if (normalizedBucketId.contains('_')) {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix createSignedUrls [WARN] bucketId에 언더스코어 포함: $normalizedBucketId (일반적으로 하이픈 사용)',
        );
      }
    }

    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix createSignedUrls: 설정 누락');
      }
      throw NetworkRequestException(
        type: NetworkErrorType.missingConfig,
        message: 'Supabase config is missing',
      );
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix createSignedUrls: accessToken 없음');
      }
      throw NetworkRequestException(
        type: NetworkErrorType.unauthorized,
        message: 'accessToken is empty',
      );
    }
    if (paths.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix createSignedUrls: paths가 비어있음');
      }
      return [];
    }

    // 요청 전 로그
    if (kDebugMode) {
      final pathsPreview = paths.take(2).map((p) => LogSanitizer.previewPath(p)).join(',');
      debugPrint(
        '$_logPrefix createSignedUrls 요청: bucketId=$normalizedBucketId expiresIn=3600 pathsCount=${paths.length} preview=[$pathsPreview]',
      );
    }

    final signedUrls = <String>[];
    final failedPaths = <String>[];
    NetworkRequestException? lastException;

    for (final path in paths) {
      // path 정규화 검증
      final normalizedPath = LogSanitizer.normalizePath(path);
      if (!normalizedPath.startsWith('journeys/')) {
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix createSignedUrls [WARN] path가 journeys/로 시작하지 않음: $normalizedPath',
          );
        }
      }
      // 중복 prefix 제거 (journey-images/journeys/... 같은 경우)
      final cleanPath = normalizedPath.replaceFirst(RegExp(r'^journey-images/'), '');

      try {
        final signed = await _signStoragePathWithGuard(
          bucketId: normalizedBucketId,
          storagePath: cleanPath,
          accessToken: accessToken,
        );
        if (signed != null) {
          signedUrls.add(signed);
        } else {
          failedPaths.add(cleanPath);
        }
      } on NetworkRequestException catch (e) {
        lastException = e;
        failedPaths.add(cleanPath);
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix createSignedUrls path 실패: path=$cleanPath errorType=${e.type} statusCode=${e.statusCode} parsedErrorCode=${e.parsedErrorCode} parsedErrorMessage=${e.parsedErrorMessage}',
          );
        }
      }
    }

    // 응답 후 로그
    if (kDebugMode) {
      final bodyPreview = lastException?.rawBody != null
          ? (lastException!.rawBody!.length > 200
              ? '${lastException.rawBody!.substring(0, 200)}...'
              : lastException.rawBody!)
          : 'N/A';
      debugPrint(
        '$_logPrefix createSignedUrls 응답: returnedCount=${signedUrls.length} failedCount=${failedPaths.length}',
      );
      if (lastException != null) {
        debugPrint(
          '$_logPrefix createSignedUrls 마지막 에러: statusCode=${lastException.statusCode} parsedErrorCode=${lastException.parsedErrorCode} parsedErrorMessage=${lastException.parsedErrorMessage} parsedErrorDetails=${lastException.parsedErrorDetails} bodyLength=${lastException.rawBody?.length ?? 0} bodyPreview=$bodyPreview',
        );
      }
    }

    // 빈 결과를 예외로 처리
    if (signedUrls.isEmpty && paths.isNotEmpty) {
      final errorMessage = failedPaths.isEmpty
          ? 'createSignedUrls returned empty (no errors logged)'
          : 'createSignedUrls returned empty (${failedPaths.length} paths failed)';
      throw NetworkRequestException(
        type: NetworkErrorType.serverRejected,
        statusCode: lastException?.statusCode,
        message: errorMessage,
        parsedErrorCode: lastException?.parsedErrorCode,
        parsedErrorMessage: lastException?.parsedErrorMessage,
        parsedErrorDetails: lastException?.parsedErrorDetails,
        rawBody: lastException?.rawBody,
      );
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
        debugPrint(
          '[InboxReplyTrace][Repo] respondJourney NetworkRequestException: $error',
        );
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
          // content_blocked 에러 체크
          final mapped = _mapReplyErrorFromResponse(error.message ?? '');
          throw JourneyReplyException(
            mapped ?? JourneyReplyError.serverRejected,
          );
        case NetworkErrorType.missingConfig:
          throw JourneyReplyException(JourneyReplyError.missingConfig);
        case NetworkErrorType.unknown:
          throw JourneyReplyException(JourneyReplyError.unknown);
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
      debugPrint(
        '[InboxReplyTrace][Repo] respond_journey 요청 (journeyId: $journeyId, content length: ${content.length})',
      );
    }

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
          'target_journey_id': journeyId,
          'response_content': content,
        }),
      ),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][Repo] respond_journey 실패 ${response.statusCode} $body',
        );
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
  Future<void> blockSenderAndPass({
    required int recipientId,
    String? reasonCode,
    required String accessToken,
    String? reqId,
  }) async {
    // Flutter 로그 2: RPC 직전 (reqId 포함)
    if (kDebugMode) {
      debugPrint(
        '[$_logPrefix][blockSenderAndPass] reqId=${reqId ?? 'N/A'} rpc=block_sender_and_pass params={p_recipient_id:$recipientId, reasonCode:$reasonCode}',
      );
    }

    // A. bigint 매핑 안전화: recipientId는 int로 전달 (문자열 변환 금지)
    // 차단 + 숨김 + 랜덤 재전송 RPC
    // 주의: block_sender_and_pass는 journey_recipients.id (PK)를 받아서 정확한 recipient row를 조회합니다.
    try {
      await _executeSimpleJourneyAction(
        rpc: 'block_sender_and_pass',
        journeyId: recipientId.toString(), // 로그용 (실제로는 recipientId 사용)
        accessToken: accessToken,
        payload: {
          'p_recipient_id': recipientId, // 숫자 그대로 전달 (문자열 변환 금지)
          if (reasonCode != null) 'p_reason_code': reasonCode,
        },
        meta: {
          'recipientId': recipientId,
          'reqId': reqId,
          if (reasonCode != null) 'reason_code': reasonCode,
        },
      );
      // Flutter 로그 3: RPC 성공 (reqId 포함)
      if (kDebugMode) {
        debugPrint(
          '[$_logPrefix][blockSenderAndPass] reqId=${reqId ?? 'N/A'} result=OK',
        );
      }
    } on JourneyActionException catch (e) {
      // Flutter 로그 3: RPC 실패 (reqId 포함)
      if (kDebugMode) {
        debugPrint(
          '[$_logPrefix][blockSenderAndPass] reqId=${reqId ?? 'N/A'} result=FAIL error=${e.error}',
        );
      }
      rethrow;
    } catch (e) {
      // Flutter 로그 3: RPC 실패 (예상치 못한 예외)
      if (kDebugMode) {
        debugPrint(
          '[$_logPrefix][blockSenderAndPass] reqId=${reqId ?? 'N/A'} result=FAIL exception=$e',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> reportJourney({
    required String journeyId,
    required String reasonCode,
    required String accessToken,
  }) async {
    // 가드: reasonCode가 null이면 절대 호출하지 않음
    if (reasonCode.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[$_logPrefix][reportJourney] BLOCKED: reasonCode가 비어있어 호출하지 않음',
        );
      }
      throw JourneyActionException(JourneyActionError.invalidPayload);
    }

    if (kDebugMode) {
      debugPrint(
        '[$_logPrefix][reportJourney] RPC 호출 직전: rpc=report_journey, target_journey_id=$journeyId, reasonCode=$reasonCode',
      );
    }

    await _executeSimpleJourneyAction(
      rpc: 'report_journey',
      journeyId: journeyId,
      accessToken: accessToken,
      payload: {'target_journey_id': journeyId, 'reason_code': reasonCode},
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
        // RPC별로 적절한 로그 메시지 출력
        if (rpc == 'report_journey') {
          debugPrint(
            '[$_logPrefix][$rpc:journeyId=$journeyId] 신고 시작: reason=${meta?['reason_code'] ?? payload['reason_code']}',
          );
        } else if (rpc == 'block_sender_and_pass') {
          // recipientId로 명확히 표시 (journeyId 혼선 제거)
          final recipientId = meta?['recipientId'] ?? payload['p_recipient_id'];
          debugPrint(
            '[$_logPrefix][$rpc:recipientId=$recipientId] 차단 시작: reason=${meta?['reason_code'] ?? payload['p_reason_code']}',
          );
        } else {
          debugPrint('[$_logPrefix][$rpc:journeyId=$journeyId] 액션 시작');
        }
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
        if (rpc == 'block_sender_and_pass') {
          final recipientId = meta?['recipientId'] ?? payload['p_recipient_id'];
          debugPrint(
            '[$_logPrefix][$rpc:recipientId=$recipientId] 성공 판정: NetworkGuard 완료',
          );
        } else {
          debugPrint(
            '[$_logPrefix][$rpc:journeyId=$journeyId] 성공 판정: NetworkGuard 완료',
          );
        }
      }
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        if (rpc == 'block_sender_and_pass') {
          final recipientId = meta?['recipientId'] ?? payload['p_recipient_id'];
          debugPrint(
            '[$_logPrefix][$rpc:recipientId=$recipientId] NetworkRequestException: type=${error.type}, statusCode=${error.statusCode}, message=${error.message}',
          );
        } else {
          debugPrint(
            '[$_logPrefix][$rpc:journeyId=$journeyId] NetworkRequestException: type=${error.type}, statusCode=${error.statusCode}, message=${error.message}',
          );
        }
      }
      // report_journey RPC에서 중복 신고 감지
      if (rpc == 'report_journey') {
        final errorCode = error.parsedErrorCode;
        final errorMessage = error.rawBody ?? '';
        if (errorCode == '23505' ||
            errorCode == 'already_reported' ||
            errorMessage.toLowerCase().contains('already_reported') ||
            errorMessage.toLowerCase().contains('unique constraint')) {
          if (kDebugMode) {
            debugPrint(
              '[$_logPrefix][report_journey:journeyId=$journeyId] 중복 신고 감지: errorCode=$errorCode',
            );
          }
          throw JourneyActionException(JourneyActionError.alreadyReported);
        }
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
            if (rpc == 'block_sender_and_pass') {
              final recipientId =
                  meta?['recipientId'] ?? payload['p_recipient_id'];
              debugPrint(
                '[$_logPrefix][$rpc:recipientId=$recipientId] serverRejected로 매핑: 원인 type=${error.type}, statusCode=${error.statusCode}, isEmpty=${error.isEmpty}, isHtml=${error.isHtml}, parsedErrorCode=${error.parsedErrorCode}',
              );
            } else {
              debugPrint(
                '[$_logPrefix][$rpc:journeyId=$journeyId] serverRejected로 매핑: 원인 type=${error.type}, statusCode=${error.statusCode}, isEmpty=${error.isEmpty}, isHtml=${error.isHtml}, parsedErrorCode=${error.parsedErrorCode}',
              );
            }
          }
          throw JourneyActionException(JourneyActionError.serverRejected);
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        if (rpc == 'block_sender_and_pass') {
          final recipientId = meta?['recipientId'] ?? payload['p_recipient_id'];
          debugPrint(
            '[$_logPrefix][$rpc:recipientId=$recipientId] 예상치 못한 예외: $error',
          );
          debugPrint(
            '[$_logPrefix][$rpc:recipientId=$recipientId] 스택 트레이스: $stackTrace',
          );
        } else {
          debugPrint(
            '[$_logPrefix][$rpc:journeyId=$journeyId] 예상치 못한 예외: $error',
          );
          debugPrint(
            '[$_logPrefix][$rpc:journeyId=$journeyId] 스택 트레이스: $stackTrace',
          );
        }
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
    final journeyId =
        payload['target_journey_id'] as String? ??
        payload['journey_id'] as String?;
    final traceLabel = journeyId != null
        ? '$context:journeyId=$journeyId'
        : context;

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

    // 200 OK 또는 204 No Content는 성공으로 처리
    // (PostgREST는 void 반환 함수에 대해 204를 반환할 수 있음)
    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.noContent) {
      // 성공: body가 비어있어도 OK (void 반환 함수의 경우)
      if (kDebugMode) {
        if (body.isEmpty) {
          debugPrint(
            '[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, body=empty',
          );
        } else {
          try {
            final decoded = jsonDecode(body);
            if (decoded is List && decoded.isNotEmpty) {
              final first = decoded[0];
              if (first is Map<String, dynamic>) {
                final success = first['success'] as bool?;
                final reportId = first['report_id'];
                debugPrint(
                  '[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, success=$success, report_id=$reportId, resType=List[Map], resKeys=${first.keys.toList()}',
                );
              } else {
                debugPrint(
                  '[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, resType=${decoded.runtimeType}',
                );
              }
            } else if (decoded is Map<String, dynamic>) {
              final success = decoded['success'] as bool?;
              final reportId = decoded['report_id'];
              debugPrint(
                '[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, success=$success, report_id=$reportId, resType=Map, resKeys=${decoded.keys.toList()}',
              );
            } else {
              debugPrint(
                '[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, resType=${decoded.runtimeType}',
              );
            }
          } catch (e) {
            // JSON 파싱 실패는 무시 (void 반환 함수는 빈 body 가능)
            debugPrint(
              '[$_logPrefix][$traceLabel] 성공: status=${response.statusCode}, body 파싱 실패(무시): $e',
            );
          }
        }
      }
      return;
    }

    // 그 외의 상태 코드는 실패
    if (kDebugMode) {
      debugPrint(
        '[$_logPrefix][$traceLabel] 실패: status=${response.statusCode}, bodyLength=${body.length}, bodyPreview=${body.length > 200 ? body.substring(0, 200) : body}',
      );
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
      throw JourneyReplyReportException(JourneyReplyReportError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyReplyReportException(JourneyReplyReportError.unauthorized);
    }

    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/report_journey_response',
    );

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
        meta: {'response_id': responseId, 'reason_code': reasonCode},
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (error) {
      // NetworkRequestException을 JourneyReplyReportException으로 변환
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw JourneyReplyReportException(JourneyReplyReportError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyReplyReportException(
            JourneyReplyReportError.unauthorized,
          );
        case NetworkErrorType.forbidden:
          throw JourneyReplyReportException(
            JourneyReplyReportError.unauthorized,
          );
        case NetworkErrorType.invalidPayload:
          throw JourneyReplyReportException(
            JourneyReplyReportError.invalidPayload,
          );
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw JourneyReplyReportException(
            JourneyReplyReportError.serverRejected,
          );
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
    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/get_journey_progress',
    );

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
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode({'target_journey_id': journeyId})));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'get_journey_progress',
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
      countryCodes:
          (row['country_codes'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
    );
  }

  @override
  Future<List<JourneyReplyItem>> fetchJourneyReplies({
    required String journeyId,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyReplyException(JourneyReplyError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyReplyException(JourneyReplyError.unauthorized);
    }
    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/list_sent_journey_replies',
    );

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<List<JourneyReplyItem>>(
        operation: () => _executeFetchJourneyReplies(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_sent_journey_replies',
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
          throw JourneyReplyException(JourneyReplyError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyReplyException(JourneyReplyError.unauthorized);
        case NetworkErrorType.forbidden:
          throw JourneyReplyException(JourneyReplyError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw JourneyReplyException(JourneyReplyError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw JourneyReplyException(JourneyReplyError.serverRejected);
      }
    }
  }

  @override
  Future<SentJourneyDetail> fetchSentJourneyDetail({
    required String journeyId,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyProgressException(JourneyProgressError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyProgressException(JourneyProgressError.unauthorized);
    }
    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/get_sent_journey_detail',
    );

    try {
      final result = await _networkGuard.execute<SentJourneyDetail>(
        operation: () => _executeFetchSentJourneyDetail(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'get_sent_journey_detail',
        uri: uri,
        method: 'POST',
        meta: {'journey_id': journeyId},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (_isResponsesMissing(error)) {
        throw JourneyReplyException(JourneyReplyError.unexpectedEmpty);
      }
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

  Future<SentJourneyDetail> _executeFetchSentJourneyDetail({
    required Uri uri,
    required String journeyId,
    required String accessToken,
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
    if (kDebugMode) {
      debugPrint(
        '[SentDetail] rpc=get_sent_journey_detail status=${response.statusCode} bodyLength=${body.length}',
      );
    }

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'get_sent_journey_detail',
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
        context: 'get_sent_journey_detail',
      );
    }

    final payload = jsonDecode(body);
    if (kDebugMode && payload is Map<String, dynamic>) {
      debugPrint(
        '[SentDetail] rpc=get_sent_journey_detail keys=${payload.keys.toList()}',
      );
    }
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

    return SentJourneyDetail(
      journeyId: row['journey_id'] as String,
      content: row['content'] as String? ?? '',
      createdAt: _parseCreatedAt(row, 'get_sent_journey_detail'),
      statusCode: row['status_code'] as String? ?? 'CREATED',
      responseCount: (row['response_count'] as num?)?.toInt() ?? 0,
      imageCount: (row['image_count'] as num?)?.toInt() ?? 0,
      isRewardUnlocked: row['is_reward_unlocked'] as bool? ?? false,
      contentClean: row['content_clean'] as String?,
    );
  }

  @override
  Future<List<SentJourneyResponse>> fetchSentJourneyResponses({
    required String journeyId,
    required int limit,
    required int offset,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyReplyException(JourneyReplyError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyReplyException(JourneyReplyError.unauthorized);
    }
    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/list_sent_journey_responses',
    );

    try {
      final result = await _networkGuard.execute<List<SentJourneyResponse>>(
        operation: () => _executeFetchSentJourneyResponses(
          uri: uri,
          journeyId: journeyId,
          limit: limit,
          offset: offset,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_sent_journey_responses',
        uri: uri,
        method: 'POST',
        meta: {'journey_id': journeyId},
        accessToken: accessToken,
      );
      if (result.isEmpty) {
        throw JourneyReplyException(JourneyReplyError.unexpectedEmpty);
      }
      return result;
    } on NetworkRequestException catch (error) {
      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw JourneyReplyException(JourneyReplyError.network);
        case NetworkErrorType.unauthorized:
          throw JourneyReplyException(JourneyReplyError.unauthorized);
        case NetworkErrorType.forbidden:
          throw JourneyReplyException(JourneyReplyError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw JourneyReplyException(JourneyReplyError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw JourneyReplyException(JourneyReplyError.serverRejected);
      }
    }
  }

  bool _isResponsesMissing(NetworkRequestException error) {
    if (error.parsedErrorCode != 'P0001') {
      return false;
    }
    final body = error.rawBody ?? '';
    return body.contains('responses_missing');
  }

  Future<List<SentJourneyResponse>> _executeFetchSentJourneyResponses({
    required Uri uri,
    required String journeyId,
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
          'p_journey_id': journeyId,
          'page_size': limit,
          'page_offset': offset,
        }),
      ),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (kDebugMode) {
      debugPrint(
        '[SentDetail] rpc=list_sent_journey_responses status=${response.statusCode} bodyLength=${body.length}',
      );
    }

    if (response.statusCode != HttpStatus.ok) {
      if (kDebugMode) {
        final preview = body.length > 200 ? body.substring(0, 200) : body;
        debugPrint(
          '[SentDetail] rpc=list_sent_journey_responses fail status=${response.statusCode} bodyPreview=$preview params={journey_id:$journeyId, page_size:$limit, page_offset:$offset}',
        );
      }
      await _errorLogger.logHttpFailure(
        context: 'list_sent_journey_responses',
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
        context: 'list_sent_journey_responses',
      );
    }

    final payload = jsonDecode(body);
    if (kDebugMode) {
      if (payload is List) {
        debugPrint(
          '[SentDetail] rpc=list_sent_journey_responses listLength=${payload.length}',
        );
      } else if (payload is Map<String, dynamic>) {
        debugPrint(
          '[SentDetail] rpc=list_sent_journey_responses keys=${payload.keys.toList()}',
        );
      }
    }
    if (payload is! List) {
      throw const FormatException('Invalid payload format');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => SentJourneyResponse(
            responseId: (row['response_id'] as num?)?.toInt() ?? 0,
            content: row['content'] as String? ?? '',
            createdAt: _parseCreatedAt(row, 'get_sent_journey_responses'),
            responderNickname: (row['responder_nickname'] as String? ?? '')
                .trim(),
            contentClean: row['content_clean'] as String?,
          ),
        )
        .toList();
  }

  /// fetchJourneyReplies RPC 실제 실행 (NetworkGuard가 호출)
  Future<List<JourneyReplyItem>> _executeFetchJourneyReplies({
    required Uri uri,
    required String journeyId,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode({'target_journey_id': journeyId})));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'list_sent_journey_replies',
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
        context: 'list_sent_journey_replies',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      throw const FormatException('Invalid payload format');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => JourneyReplyItem(
            responseId: (row['reply_id'] as num?)?.toInt() ?? 0,
            content: row['content'] as String? ?? '',
            createdAt: _parseCreatedAt(row, 'get_journey_replies'),
            responderNickname: row['responder_nickname'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<List<String>> fetchInboxJourneyImagePaths({
    required String journeyId,
    required String accessToken,
  }) async {
    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/get_inbox_journey_snapshot_image_paths',
    );

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<List<String>>(
        operation: () => _executeFetchInboxJourneyImagePaths(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'get_inbox_journey_snapshot_image_paths',
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
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode({'p_journey_id': journeyId})));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    // 디버그 로그: 응답 원문 (민감정보 제외)
    if (kDebugMode) {
      debugPrint(
        '[InboxDetail][Images][RPC] journeyId=$journeyId status=${response.statusCode}',
      );
    }

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'get_inbox_journey_snapshot_image_paths',
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
        context: 'get_inbox_journey_snapshot_image_paths',
      );
    }

    // jsonb 응답 파싱
    final payload = jsonDecode(body);
    if (payload is! Map<String, dynamic>) {
      if (kDebugMode) {
        debugPrint(
          '[InboxDetail][Images][RPC] Invalid payload format: ${payload.runtimeType}',
        );
      }
      throw const FormatException('Invalid payload format: expected jsonb object');
    }

    // 디버그 로그: 응답 키 목록
    if (kDebugMode) {
      final keys = payload.keys.toList();
      debugPrint('[InboxDetail][Images][RPC] keys=$keys');
    }

    // snapshot_image_paths 추출 (text[] 또는 jsonb array)
    final snapshotImagePaths = payload['snapshot_image_paths'];
    final snapshotImageCount = (payload['snapshot_image_count'] as num?)?.toInt() ?? 0;

    List<String> paths = [];
    if (snapshotImagePaths != null) {
      if (snapshotImagePaths is List) {
        // jsonb array 형태
        paths = snapshotImagePaths
            .whereType<String>()
            .toList();
      } else if (snapshotImagePaths is String) {
        // 단일 문자열인 경우 (예외 케이스)
        paths = [snapshotImagePaths];
      }
    }

    // 디버그 로그: 최종 파싱 결과
    if (kDebugMode) {
      final pathsPreview = paths.take(3).map((p) => LogSanitizer.previewPath(p)).join(',');
      debugPrint(
        '[InboxDetail][Images][RPC] countFromDB=$snapshotImageCount pathsLen=${paths.length} preview=[$pathsPreview]',
      );
    }

    return paths;
  }

  @override
  Future<List<Map<String, dynamic>>> debugCheckStorageObjects({
    required String bucket,
    required List<String> paths,
    required String accessToken,
  }) async {
    if (!kDebugMode) {
      throw StateError('debugCheckStorageObjects should only be called in debug mode');
    }
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return [];
    }
    if (accessToken.isEmpty) {
      return [];
    }
    if (paths.isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/debug_check_storage_objects',
    );

    try {
      final result = await _networkGuard.execute<List<Map<String, dynamic>>>(
        operation: () => _executeDebugCheckStorageObjects(
          uri: uri,
          bucket: bucket,
          paths: paths,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'debug_check_storage_objects',
        uri: uri,
        method: 'POST',
        meta: {'bucket': bucket, 'paths_count': paths.length},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _executeDebugCheckStorageObjects({
    required Uri uri,
    required String bucket,
    required List<String> paths,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode({
      'p_bucket': bucket,
      'p_paths': paths,
    })));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'debug_check_storage_objects',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'bucket': bucket, 'paths_count': paths.length},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'debug_check_storage_objects',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      throw const FormatException('Invalid payload format: expected array');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Storage 경로를 signedUrl로 변환 (NetworkGuard 경유)
  Future<String?> _signStoragePathWithGuard({
    required String bucketId,
    required String storagePath,
    required String accessToken,
  }) async {
    final uri = Uri.parse(
      '${_config.supabaseUrl}/storage/v1/object/sign/$bucketId/$storagePath',
    );

    try {
      final result = await _networkGuard.execute<String?>(
        operation: () => _executeSignStoragePath(
          uri: uri,
          storagePath: storagePath,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'sign_journey_image',
        uri: uri,
        method: 'POST',
        meta: {'storage_path': storagePath, 'bucket_id': bucketId},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException {
      // 에러 정보를 상위로 전달하기 위해 예외를 재throw
      // (createSignedUrls에서 빈 결과 처리)
      rethrow;
    }
  }

  /// _signStoragePath 실제 실행 (NetworkGuard가 호출)
  Future<String?> _executeSignStoragePath({
    required Uri uri,
    required String storagePath,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer $accessToken',
    );
    request.add(utf8.encode(jsonEncode({'expiresIn': 3600})));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'sign_journey_image',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'storage_path': storagePath},
        accessToken: accessToken,
      );

      final exception = _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'sign_journey_image',
      );

      // 디버그 로그: 응답 원문 (민감정보 제외)
      if (kDebugMode) {
        final bodyPreview = body.length > 200 ? '${body.substring(0, 200)}...' : body;
        debugPrint(
          '$_logPrefix _signStoragePathWithGuard 응답: statusCode=${response.statusCode} parsedErrorCode=${exception.parsedErrorCode} parsedErrorMessage=${exception.parsedErrorMessage} parsedErrorDetails=${exception.parsedErrorDetails} bodyLength=${body.length} bodyPreview=$bodyPreview',
        );
      }

      throw exception;
    }

    final payload = jsonDecode(body);
    if (payload is Map<String, dynamic>) {
      final signed = payload['signedURL'];
      if (signed is String && signed.isNotEmpty) {
        // signedURL 정규화: 상대경로(`/object/sign/...`)일 때 `/storage/v1` 포함 보장
        final normalizedUrl = StorageUrlNormalizer.normalizeSignedUrl(
          supabaseUrl: _config.supabaseUrl,
          signedUrlOrPath: signed,
        );
        if (kDebugMode) {
          final rawSanitized = LogSanitizer.sanitizeUrlForLog(signed);
          final normalizedSanitized = LogSanitizer.sanitizeUrlForLog(normalizedUrl);
          debugPrint(
            '$_logPrefix _executeSignStoragePath signedURL 정규화: raw=$rawSanitized → normalized=$normalizedSanitized',
          );
        }
        return normalizedUrl;
      }
    }
    return null;
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

  JourneyReplyError? _mapReplyErrorFromResponse(String body) {
    final errorCode = _extractErrorCode(body);
    switch (errorCode) {
      case 'empty_content':
        return JourneyReplyError.unexpectedEmpty;
      case 'content_too_long':
        return JourneyReplyError.invalidPayload;
      case 'content_blocked':
        return JourneyReplyError.contentBlocked;
      case 'unauthorized':
        return JourneyReplyError.unauthorized;
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

  @override
  Future<MyLatestResponse?> fetchMyLatestResponse({
    required String journeyId,
    required String accessToken,
  }) async {
    // 사전 검증
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyActionException(JourneyActionError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyActionException(JourneyActionError.unauthorized);
    }

    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/get_my_latest_response');

    try {
      final result = await _networkGuard.execute<MyLatestResponse?>(
        operation: () => _executeFetchMyLatestResponse(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'get_my_latest_response',
        uri: uri,
        method: 'POST',
        meta: {'journey_id': journeyId},
        accessToken: accessToken,
      );
      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[InboxDetail][MyResponse] fetchMyLatestResponse NetworkRequestException: $error',
        );
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
          // 답글이 없는 경우는 null 반환 (에러가 아님)
          if (error.statusCode == 404 || 
              (error.message?.contains('unauthorized') ?? false)) {
            return null;
          }
          throw JourneyActionException(JourneyActionError.serverRejected);
        case NetworkErrorType.missingConfig:
          throw JourneyActionException(JourneyActionError.missingConfig);
        case NetworkErrorType.unknown:
          throw JourneyActionException(JourneyActionError.unknown);
      }
    }
  }

  Future<MyLatestResponse?> _executeFetchMyLatestResponse({
    required Uri uri,
    required String journeyId,
    required String accessToken,
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

    if (response.statusCode == HttpStatus.notFound) {
      // 답글이 없는 경우 null 반환
      return null;
    }

    if (response.statusCode != HttpStatus.ok) {
      throw NetworkRequestException(
        type: NetworkErrorType.serverRejected,
        statusCode: response.statusCode,
        message: body,
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List || payload.isEmpty) {
      // 빈 배열이면 답글이 없음
      return null;
    }

    final row = payload[0] as Map<String, dynamic>;
    return MyLatestResponse(
      responseId: (row['response_id'] as num?)?.toInt() ?? 0,
      content: row['content'] as String? ?? '',
      contentClean: row['content_clean'] as String?,
      createdAt: _parseCreatedAt(row, 'get_my_latest_response'),
    );
  }

  @override
  Future<List<String>> fetchSentJourneyImageUrls({
    required String journeyId,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return [];
    }
    if (accessToken.isEmpty) {
      return [];
    }

    // RPC로 storage_path 리스트 조회
    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/list_sent_journey_images',
    );

    List<String> paths;
    try {
      paths = await _networkGuard.execute<List<String>>(
        operation: () => _executeFetchSentJourneyImagePaths(
          uri: uri,
          journeyId: journeyId,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'list_sent_journey_images',
        uri: uri,
        method: 'POST',
        meta: {'journey_id': journeyId},
        accessToken: accessToken,
      );
    } on NetworkRequestException catch (_) {
      // 이미지 경로 조회 실패는 빈 배열 반환 (비블로킹)
      return [];
    }

    if (paths.isEmpty) {
      return [];
    }

    // createSignedUrls로 일괄 변환 (NetworkGuard 경유)
    return await createSignedUrls(
      bucketId: _journeyImagesBucketId,
      paths: paths,
      accessToken: accessToken,
    );
  }

  /// _fetchSentJourneyImagePaths RPC 실제 실행 (NetworkGuard가 호출)
  Future<List<String>> _executeFetchSentJourneyImagePaths({
    required Uri uri,
    required String journeyId,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode({'target_journey_id': journeyId})));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    // 디버그 로그
    if (kDebugMode) {
      debugPrint(
        '[SentDetail][Images][RPC] journeyId=$journeyId status=${response.statusCode}',
      );
    }

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'list_sent_journey_images',
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
        context: 'list_sent_journey_images',
      );
    }

    // 배열 형태 응답 파싱 [{"storage_path": "..."}, ...]
    final payload = jsonDecode(body);
    if (payload is! List) {
      if (kDebugMode) {
        debugPrint(
          '[SentDetail][Images][RPC] Invalid payload format: ${payload.runtimeType}',
        );
      }
      throw const FormatException('Expected list of objects');
    }

    final paths = <String>[];
    for (final item in payload) {
      if (item is Map<String, dynamic>) {
        final path = item['storage_path'] as String?;
        if (path != null && path.isNotEmpty) {
          paths.add(path);
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[SentDetail][Images][RPC] Parsed ${paths.length} paths',
      );
    }

    return paths;
  }
}

class SupabaseJourneyStorageRepository implements JourneyStorageRepository {
  SupabaseJourneyStorageRepository({required AppConfig config})
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

        // 업로드 직전 파일 검증
        final file = File(path);
        if (!await file.exists()) {
          if (kDebugMode) {
            debugPrint(
              'compose: 이미지 업로드 실패 (파일 없음: $path)',
            );
          }
          await deleteImages(paths: uploaded, accessToken: accessToken);
          throw JourneyStorageException(JourneyStorageError.uploadFailed);
        }
        final fileSize = await file.length();
        if (fileSize == 0) {
          if (kDebugMode) {
            debugPrint(
              'compose: 이미지 업로드 실패 (파일 크기 0: $path)',
            );
          }
          await deleteImages(paths: uploaded, accessToken: accessToken);
          throw JourneyStorageException(JourneyStorageError.uploadFailed);
        }

        final bytes = await file.readAsBytes();
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
            meta: {'storage_path': storagePath},
            accessToken: accessToken,
          );
        } on NetworkRequestException catch (error) {
          if (kDebugMode) {
            debugPrint(
              'compose: 이미지 업로드 실패 (NetworkRequestException: ${error.type})',
            );
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
    } on FileSystemException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'compose: 이미지 업로드 실패 (FileSystemException: '
          'osError=${e.osError?.errorCode}, '
          'message=${e.osError?.message}, '
          'path=${e.path})',
        );
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
    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.created) {
      if (kDebugMode) {
        debugPrint('compose: storage 업로드 실패 ${response.statusCode}');
      }
      await _errorLogger.logHttpFailure(
        context: 'journey_image_upload',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'storage_path': storagePath},
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
