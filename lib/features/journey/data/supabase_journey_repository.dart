import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/server_error_logger.dart';
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
  SupabaseJourneyRepository({required AppConfig config})
      : _config = config,
        _errorLogger = ServerErrorLogger(config: config),
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final HttpClient _client;

  @override
  Future<JourneyCreationResult> createJourney({
    required String content,
    required String languageTag,
    required List<String> imagePaths,
    required int recipientCount,
    required String accessToken,
  }) async {
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
    int? responseStatusCode;
    String? responseBody;
    try {
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
      responseStatusCode = response.statusCode;
      responseBody = await response.transform(utf8.decoder).join();
      final body = responseBody;
      if (response.statusCode != HttpStatus.ok) {
        if (kDebugMode) {
          debugPrint('compose: create_journey 실패 ${response.statusCode} $body');
        }
        await _errorLogger.logHttpFailure(
          context: 'create_journey',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: {
            'rpc': 'create_journey',
          },
          uri: uri,
          method: 'POST',
          accessToken: accessToken,
        );
        if (response.statusCode == HttpStatus.unauthorized) {
          throw JourneyCreationException(JourneyCreationError.unauthorized);
        }
        if (response.statusCode == HttpStatus.forbidden) {
          throw JourneyCreationException(JourneyCreationError.unauthorized);
        }
        final mapped = _mapErrorFromResponse(body);
        throw JourneyCreationException(mapped ?? JourneyCreationError.serverRejected);
      }
      if (kDebugMode) {
        debugPrint('compose: create_journey 응답 $body');
      }
      final payload = jsonDecode(body);
      if (payload is! List || payload.isEmpty) {
        if (kDebugMode) {
          debugPrint('compose: create_journey 응답 형식 오류 ($payload)');
        }
        throw JourneyCreationException(JourneyCreationError.invalidPayload);
      }
      final first = payload.first;
      if (first is! Map<String, dynamic>) {
        if (kDebugMode) {
          debugPrint('compose: create_journey 응답 첫 항목 형식 오류 ($first)');
        }
        throw JourneyCreationException(JourneyCreationError.invalidPayload);
      }
      final journeyId = first['journey_id'];
      final createdAt = first['created_at'];
      if (journeyId is! String || createdAt is! String) {
        if (kDebugMode) {
          debugPrint('compose: create_journey 응답 키 누락 ($first)');
        }
        throw JourneyCreationException(JourneyCreationError.invalidPayload);
      }
      return JourneyCreationResult(
        journeyId: journeyId,
        createdAt: DateTime.parse(createdAt),
      );
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'create_journey',
        error: error,
        meta: {
          'rpc': 'create_journey',
        },
        uri: uri,
        method: 'POST',
        accessToken: accessToken,
      );
      throw JourneyCreationException(JourneyCreationError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'create_journey',
        error: error,
        meta: {
          'rpc': 'create_journey',
        },
        uri: uri,
        method: 'POST',
        accessToken: accessToken,
      );
      throw JourneyCreationException(JourneyCreationError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'create_journey',
        error: error,
        meta: {
          'rpc': 'create_journey',
          'response_status': responseStatusCode,
          'response_body': responseBody,
        },
        uri: uri,
        method: 'POST',
        accessToken: accessToken,
      );
      throw JourneyCreationException(JourneyCreationError.invalidPayload);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('compose: create_journey 알 수 없는 오류 $error');
        debugPrint('compose: create_journey 응답 상태 $responseStatusCode');
        debugPrint('compose: create_journey 응답 바디 $responseBody');
      }
      await _errorLogger.logException(
        context: 'create_journey',
        error: error,
        meta: {
          'rpc': 'create_journey',
          'response_status': responseStatusCode,
          'response_body': responseBody,
        },
        uri: uri,
        method: 'POST',
        accessToken: accessToken,
      );
      throw JourneyCreationException(JourneyCreationError.unknown);
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
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: dispatch accessToken 없음');
      }
      return;
    }
    final uri = Uri.parse('${_config.supabaseUrl}/functions/v1/dispatch_journey_matches');
    try {
      final request = await _client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set('apikey', _config.supabaseAnonKey);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
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
        return;
      }
      if (kDebugMode) {
        debugPrint('compose: dispatch 성공 $body');
      }
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'dispatch_journey_matches',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'dispatch_journey_matches',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'dispatch_journey_matches',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
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
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw JourneyListException(JourneyListError.unauthorized);
        }
        final mapped = _mapListErrorFromResponse(body);
        throw JourneyListException(mapped ?? JourneyListError.serverRejected);
      }
      final payload = jsonDecode(body);
      if (payload is! List) {
        throw JourneyListException(JourneyListError.invalidPayload);
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
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'list_journeys',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw JourneyListException(JourneyListError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'list_journeys',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw JourneyListException(JourneyListError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'list_journeys',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw JourneyListException(JourneyListError.invalidPayload);
    }
  }

  @override
  Future<List<JourneyInboxItem>> fetchInboxJourneys({
    required int limit,
    required int offset,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('inbox: supabase 설정 누락');
      }
      throw JourneyInboxException(JourneyInboxError.missingConfig);
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('inbox: accessToken 없음');
      }
      throw JourneyInboxException(JourneyInboxError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/list_inbox_journeys');
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
          debugPrint('inbox: list 실패 ${response.statusCode} $body');
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
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw JourneyInboxException(JourneyInboxError.unauthorized);
        }
        throw JourneyInboxException(JourneyInboxError.serverRejected);
      }
      final payload = jsonDecode(body);
      if (payload is! List) {
        throw JourneyInboxException(JourneyInboxError.invalidPayload);
      }
      return payload
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => JourneyInboxItem(
              journeyId: row['journey_id'] as String,
              senderUserId: row['sender_user_id'] as String? ?? '',
              content: row['content'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              imageCount: (row['image_count'] as num?)?.toInt() ?? 0,
              recipientStatus: row['recipient_status'] as String? ?? 'ASSIGNED',
            ),
          )
          .toList();
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'list_inbox_journeys',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw JourneyInboxException(JourneyInboxError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'list_inbox_journeys',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw JourneyInboxException(JourneyInboxError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'list_inbox_journeys',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'limit': limit,
          'offset': offset,
        },
        accessToken: accessToken,
      );
      throw JourneyInboxException(JourneyInboxError.invalidPayload);
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
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyActionException(JourneyActionError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyActionException(JourneyActionError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/respond_journey');
    try {
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
        await _errorLogger.logHttpFailure(
          context: 'respond_journey',
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: {
            'journey_id': journeyId,
          },
          accessToken: accessToken,
        );
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw JourneyActionException(JourneyActionError.unauthorized);
        }
        throw JourneyActionException(JourneyActionError.serverRejected);
      }
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'respond_journey',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyActionException(JourneyActionError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'respond_journey',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyActionException(JourneyActionError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'respond_journey',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyActionException(JourneyActionError.invalidPayload);
    }
  }

  @override
  Future<void> passJourney({
    required String journeyId,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyActionException(JourneyActionError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyActionException(JourneyActionError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/pass_journey');
    try {
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
          context: 'pass_journey',
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: {
            'journey_id': journeyId,
          },
          accessToken: accessToken,
        );
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw JourneyActionException(JourneyActionError.unauthorized);
        }
        throw JourneyActionException(JourneyActionError.serverRejected);
      }
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'pass_journey',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyActionException(JourneyActionError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'pass_journey',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyActionException(JourneyActionError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'pass_journey',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyActionException(JourneyActionError.invalidPayload);
    }
  }

  @override
  Future<void> reportJourney({
    required String journeyId,
    required String reasonCode,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyActionException(JourneyActionError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyActionException(JourneyActionError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/report_journey');
    try {
      final request = await _client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set('apikey', _config.supabaseAnonKey);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.add(
        utf8.encode(
          jsonEncode({
            'target_journey_id': journeyId,
            'reason_code': reasonCode,
          }),
        ),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        await _errorLogger.logHttpFailure(
          context: 'report_journey',
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: {
            'journey_id': journeyId,
            'reason_code': reasonCode,
          },
          accessToken: accessToken,
        );
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw JourneyActionException(JourneyActionError.unauthorized);
        }
        throw JourneyActionException(JourneyActionError.serverRejected);
      }
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'report_journey',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
          'reason_code': reasonCode,
        },
        accessToken: accessToken,
      );
      throw JourneyActionException(JourneyActionError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'report_journey',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
          'reason_code': reasonCode,
        },
        accessToken: accessToken,
      );
      throw JourneyActionException(JourneyActionError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'report_journey',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
          'reason_code': reasonCode,
        },
        accessToken: accessToken,
      );
      throw JourneyActionException(JourneyActionError.invalidPayload);
    }
  }

  @override
  Future<void> reportJourneyResponse({
    required int responseId,
    required String reasonCode,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      throw JourneyResultReportException(JourneyResultReportError.missingConfig);
    }
    if (accessToken.isEmpty) {
      throw JourneyResultReportException(JourneyResultReportError.unauthorized);
    }
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/report_journey_response');
    try {
      final request = await _client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set('apikey', _config.supabaseAnonKey);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.add(
        utf8.encode(
          jsonEncode({
            'target_response_id': responseId,
            'reason_code': reasonCode,
          }),
        ),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        await _errorLogger.logHttpFailure(
          context: 'report_journey_response',
          uri: uri,
          method: 'POST',
          statusCode: response.statusCode,
          errorMessage: body,
          meta: {
            'response_id': responseId,
            'reason_code': reasonCode,
          },
          accessToken: accessToken,
        );
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw JourneyResultReportException(JourneyResultReportError.unauthorized);
        }
        throw JourneyResultReportException(JourneyResultReportError.serverRejected);
      }
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'report_journey_response',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'response_id': responseId,
          'reason_code': reasonCode,
        },
        accessToken: accessToken,
      );
      throw JourneyResultReportException(JourneyResultReportError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'report_journey_response',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'response_id': responseId,
          'reason_code': reasonCode,
        },
        accessToken: accessToken,
      );
      throw JourneyResultReportException(JourneyResultReportError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'report_journey_response',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'response_id': responseId,
          'reason_code': reasonCode,
        },
        accessToken: accessToken,
      );
      throw JourneyResultReportException(JourneyResultReportError.invalidPayload);
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
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw JourneyProgressException(JourneyProgressError.unauthorized);
        }
        throw JourneyProgressException(JourneyProgressError.serverRejected);
      }
      final payload = jsonDecode(body);
      if (payload is! List || payload.isEmpty) {
        throw JourneyProgressException(JourneyProgressError.invalidPayload);
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
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'get_journey_progress',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyProgressException(JourneyProgressError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'get_journey_progress',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyProgressException(JourneyProgressError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'get_journey_progress',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyProgressException(JourneyProgressError.invalidPayload);
    }
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
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw JourneyResultException(JourneyResultError.unauthorized);
        }
        throw JourneyResultException(JourneyResultError.serverRejected);
      }
      final payload = jsonDecode(body);
      if (payload is! List) {
        throw JourneyResultException(JourneyResultError.invalidPayload);
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
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'list_journey_results',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyResultException(JourneyResultError.network);
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'list_journey_results',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyResultException(JourneyResultError.network);
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'list_journey_results',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      throw JourneyResultException(JourneyResultError.invalidPayload);
    }
  }

  Future<List<String>> _fetchInboxJourneyImagePaths({
    required String journeyId,
    required String accessToken,
  }) async {
    final uri = Uri.parse('${_config.supabaseUrl}/rest/v1/rpc/list_inbox_journey_images');
    try {
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
        return [];
      }
      final payload = jsonDecode(body);
      if (payload is! List) {
        return [];
      }
      return payload
          .whereType<Map<String, dynamic>>()
          .map((row) => row['storage_path'] as String?)
          .whereType<String>()
          .toList();
    } on SocketException catch (error) {
      await _errorLogger.logException(
        context: 'list_inbox_journey_images',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      return [];
    } on HttpException catch (error) {
      await _errorLogger.logException(
        context: 'list_inbox_journey_images',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      return [];
    } on FormatException catch (error) {
      await _errorLogger.logException(
        context: 'list_inbox_journey_images',
        uri: uri,
        method: 'POST',
        error: error,
        meta: {
          'journey_id': journeyId,
        },
        accessToken: accessToken,
      );
      return [];
    }
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
        _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
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
    Uri? currentUri;
    String? currentStoragePath;
    try {
      for (var i = 0; i < filePaths.length; i += 1) {
        final path = filePaths[i];
        if (kDebugMode) {
          debugPrint('compose: 이미지 업로드 시작 ($path)');
        }
        final bytes = await File(path).readAsBytes();
        final storagePath = _buildStoragePath(path, i);
        currentStoragePath = storagePath;
        currentUri = _storageUri(storagePath);
        await _uploadObject(
          uri: currentUri,
          storagePath: storagePath,
          bytes: bytes,
          accessToken: accessToken,
          contentType: _contentTypeForPath(path),
        );
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
    } on SocketException catch (error) {
      if (kDebugMode) {
        debugPrint('compose: 이미지 업로드 실패 (SocketException)');
      }
      if (currentUri != null) {
        await _errorLogger.logException(
          context: 'journey_image_upload',
          uri: currentUri,
          method: 'POST',
          error: error,
          meta: {
            'storage_path': currentStoragePath,
          },
          accessToken: accessToken,
        );
      }
      await deleteImages(paths: uploaded, accessToken: accessToken);
      throw JourneyStorageException(JourneyStorageError.network);
    } on HttpException catch (error) {
      if (currentUri != null) {
        await _errorLogger.logException(
          context: 'journey_image_upload',
          uri: currentUri,
          method: 'POST',
          error: error,
          meta: {
            'storage_path': currentStoragePath,
          },
          accessToken: accessToken,
        );
      }
      await deleteImages(paths: uploaded, accessToken: accessToken);
      throw JourneyStorageException(JourneyStorageError.network);
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
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      return;
    }
    if (accessToken.isEmpty) {
      return;
    }
    for (final path in paths) {
      if (kDebugMode) {
        debugPrint('compose: 이미지 삭제 ($path)');
      }
      final uri = _storageUri(path);
      try {
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
            meta: {
              'storage_path': path,
            },
            accessToken: accessToken,
          );
        }
      } on SocketException catch (error) {
        await _errorLogger.logException(
          context: 'journey_image_delete',
          uri: uri,
          method: 'DELETE',
          error: error,
          meta: {
            'storage_path': path,
          },
          accessToken: accessToken,
        );
      }
    }
  }

  Future<void> _uploadObject({
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
      throw JourneyStorageException(JourneyStorageError.uploadFailed);
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
