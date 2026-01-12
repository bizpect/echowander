import 'package:flutter/foundation.dart';

import '../../features/journey/domain/journey_repository.dart';
import '../logging/log_sanitizer.dart';
import '../network/network_error.dart';

const _logPrefix = '[JourneyImageUrlResolver]';

/// Journey 이미지 URL 리졸버
/// objectPath → signedUrl 변환 및 캐시 관리
class JourneyImageUrlResolver {
  JourneyImageUrlResolver({
    required JourneyRepository repository,
  }) : _repository = repository;

  final JourneyRepository _repository;

  /// 캐시 엔트리: signedUrl + 만료 시각
  final Map<String, _CacheEntry> _cache = {};

  /// 재시도된 경로 (무한 루프 방지)
  final Set<String> _retriedPaths = {};

  /// objectPath 리스트를 signedUrl 리스트로 변환
  ///
  /// [bucketId] Storage 버킷 ID
  /// [paths] objectPath 리스트
  /// [accessToken] 액세스 토큰
  /// [traceId] 로깅용 traceId (선택)
  /// [journeyId] 로깅용 journeyId (선택)
  ///
  /// 반환: signedUrl 리스트 (실패한 항목은 null)
  Future<List<String?>> getSignedUrls({
    required String bucketId,
    required List<String> paths,
    required String accessToken,
    String? traceId,
    String? journeyId,
  }) async {
    if (paths.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final results = <String?>[];
    int cacheHits = 0;
    int cacheMisses = 0;
    int signedUrlCount = 0;

    for (var index = 0; index < paths.length; index++) {
      final path = paths[index];
      final pathTraceId = traceId ?? 'imgtrace-${DateTime.now().microsecondsSinceEpoch}-$index';

      // objectPath 수신 로그
      if (kDebugMode) {
        final normalized = LogSanitizer.normalizePath(path);
        debugPrint(
          '$_logPrefix [1] objectPath 수신: traceId=$pathTraceId, journeyId=${journeyId ?? "N/A"}, index=$index, bucketId=$bucketId, path=$path, normalized=$normalized',
        );
      }

      // 캐시 확인
      final cached = _cache[path];
      if (cached != null && cached.expiresAt.isAfter(now)) {
        cacheHits++;
        if (kDebugMode) {
          final urlSanitized = LogSanitizer.sanitizeUrlForLog(cached.signedUrl);
          debugPrint(
            '$_logPrefix [2] signedUrl 캐시 히트: traceId=$pathTraceId, path=$path, expiresAt=${cached.expiresAt}, url=$urlSanitized',
          );
        }
        results.add(cached.signedUrl);
        continue;
      }
      cacheMisses++;

      // 캐시 만료 또는 없음 → 재발급
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix [2] signedUrl 캐시 미스/만료 → 발급: traceId=$pathTraceId, path=$path, bucketId=$bucketId, expiresIn=3600',
        );
      }

      try {
        final signedUrl = await _repository.createSignedUrls(
          bucketId: bucketId,
          paths: [path],
          accessToken: accessToken,
        );
        if (signedUrl.isNotEmpty) {
          signedUrlCount++;
          final url = signedUrl.first;
          // 캐시 저장 (만료 1시간 전에 재발급하도록 여유 시간 확보)
          _cache[path] = _CacheEntry(
            signedUrl: url,
            expiresAt: now.add(const Duration(seconds: 3300)), // 55분
          );
          if (kDebugMode) {
            final urlSanitized = LogSanitizer.sanitizeUrlForLog(url);
            // 정규화 여부 확인 로그
            final hasStorageV1 = url.contains('/storage/v1/');
            final isAbsolute = url.startsWith('http://') || url.startsWith('https://');
            debugPrint(
              '$_logPrefix [2] signedUrl 발급 성공: traceId=$pathTraceId, path=$path, expiresAt=${_cache[path]!.expiresAt}, url=$urlSanitized, isAbsolute=$isAbsolute, hasStorageV1=$hasStorageV1',
            );
          }
          results.add(url);
        } else {
          if (kDebugMode) {
            debugPrint('$_logPrefix [2] signedUrl 발급 실패 (빈 결과): traceId=$pathTraceId, path=$path');
          }
          results.add(null);
        }
      } on NetworkRequestException catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix [2] signedUrl 발급 NetworkRequestException: traceId=$pathTraceId, path=$path, errorType=${e.type} statusCode=${e.statusCode} parsedErrorCode=${e.parsedErrorCode} parsedErrorMessage=${e.parsedErrorMessage} parsedErrorDetails=${e.parsedErrorDetails}',
          );
          debugPrint('$_logPrefix 스택 트레이스: $stackTrace');
        }
        results.add(null);
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix [2] signedUrl 발급 예외: traceId=$pathTraceId, path=$path, error=$e',
          );
          debugPrint('$_logPrefix 스택 트레이스: $stackTrace');
        }
        results.add(null);
      }
    }

    // 발급 요약 로그 및 missingPaths 진단
    if (kDebugMode) {
      final successfulUrls = results.whereType<String>().toList();
      final failedIndices = <int>[];
      for (var i = 0; i < results.length; i++) {
        if (results[i] == null) {
          failedIndices.add(i);
        }
      }
      final missingPaths = failedIndices.map((i) => paths[i]).toList();

      if (journeyId != null) {
        final urlPreviews = successfulUrls.take(3).map((url) {
          final sanitized = LogSanitizer.sanitizeUrl(url);
          final hash = LogSanitizer.hashUrl(url);
          return '$sanitized#$hash';
        }).join(', ');
        debugPrint(
          '$_logPrefix journeyId=$journeyId cache=HIT:$cacheHits MISS:$cacheMisses paths=${paths.length} signedUrls=${successfulUrls.length} (issued=$signedUrlCount) u0=$urlPreviews',
        );
      }

      // missingPaths 진단 로그
      if (successfulUrls.isEmpty && paths.isNotEmpty) {
        final missingPreview = missingPaths.take(2).map((p) => LogSanitizer.previewPath(p)).join(',');
        debugPrint(
          '$_logPrefix [WARN] createSignedUrls 빈 결과: bucketId=$bucketId pathsLen=${paths.length} returnedLen=${successfulUrls.length} missingPathsPreview=[$missingPreview]',
        );
        debugPrint(
          '$_logPrefix [WARN] 가능한 원인: (A) bucketId 불일치 (journey-images vs journey_images) (B) Storage RLS 정책 문제 (C) 경로 정규화 문제 (journeys/ prefix 누락 등)',
        );
      } else if (successfulUrls.length < paths.length) {
        final missingPreview = missingPaths.take(5).map((p) => LogSanitizer.previewPath(p)).join(',');
        debugPrint(
          '$_logPrefix [WARN] createSignedUrls 부분 실패: bucketId=$bucketId pathsLen=${paths.length} returnedLen=${successfulUrls.length} missingPaths=[$missingPreview]',
        );
      }
    }

    return results;
  }

  /// 특정 경로의 캐시를 무효화하고 재발급
  ///
  /// [bucketId] Storage 버킷 ID
  /// [path] objectPath
  /// [accessToken] 액세스 토큰
  /// [traceId] 로깅용 traceId (선택)
  ///
  /// 반환: 재발급된 signedUrl 또는 null
  Future<String?> refreshSignedUrl({
    required String bucketId,
    required String path,
    required String accessToken,
    String? traceId,
  }) async {
    final refreshTraceId = traceId ?? 'refresh-${DateTime.now().microsecondsSinceEpoch}';

    // 무한 루프 방지: 이미 재시도한 경로는 스킵
    if (_retriedPaths.contains(path)) {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix [4] 재시도 스킵 (이미 시도함): traceId=$refreshTraceId, path=$path',
        );
      }
      return null;
    }

    _retriedPaths.add(path);
    _cache.remove(path); // 캐시 무효화

    if (kDebugMode) {
      debugPrint(
        '$_logPrefix [4] 캐시 무효화 및 재발급: traceId=$refreshTraceId, path=$path, bucketId=$bucketId',
      );
    }

    try {
      final signedUrls = await _repository.createSignedUrls(
        bucketId: bucketId,
        paths: [path],
        accessToken: accessToken,
      );
      if (signedUrls.isNotEmpty) {
        final url = signedUrls.first;
        final now = DateTime.now();
        _cache[path] = _CacheEntry(
          signedUrl: url,
          expiresAt: now.add(const Duration(seconds: 3300)),
        );
        if (kDebugMode) {
          final urlSanitized = LogSanitizer.sanitizeUrlForLog(url);
          // 정규화 여부 확인 로그
          final hasStorageV1 = url.contains('/storage/v1/');
          final isAbsolute = url.startsWith('http://') || url.startsWith('https://');
          debugPrint(
            '$_logPrefix [4] 재발급 성공: traceId=$refreshTraceId, path=$path, expiresAt=${_cache[path]!.expiresAt}, url=$urlSanitized, isAbsolute=$isAbsolute, hasStorageV1=$hasStorageV1',
          );
        }
        return url;
      } else {
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix [4] 재발급 실패 (빈 결과): traceId=$refreshTraceId, path=$path',
          );
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix [4] 재발급 예외: traceId=$refreshTraceId, path=$path, error=$e',
        );
        debugPrint('$_logPrefix 스택 트레이스: $stackTrace');
      }
    }

    return null;
  }

  /// 재시도 기록 초기화 (화면 전환 시 등)
  void clearRetryHistory() {
    _retriedPaths.clear();
  }
}

class _CacheEntry {
  _CacheEntry({
    required this.signedUrl,
    required this.expiresAt,
  });

  final String signedUrl;
  final DateTime expiresAt;
}
