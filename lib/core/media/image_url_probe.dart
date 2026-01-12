import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../network/network_guard.dart';
import '../network/network_error.dart';
import '../logging/server_error_logger.dart';
import '../logging/log_sanitizer.dart';

const _logPrefix = '[ImageUrlProbe]';

/// 이미지 URL 진단 결과
class ImageProbeResult {
  ImageProbeResult({
    required this.statusCode,
    required this.methodUsed,
    this.contentType,
    this.contentLength,
    this.cacheControl,
    this.date,
    this.etag,
    this.server,
    this.requestId,
  });

  final int statusCode;
  final String methodUsed; // 'HEAD' or 'GET(range)'
  final String? contentType;
  final int? contentLength;
  final String? cacheControl;
  final String? date;
  final String? etag;
  final String? server;
  final String? requestId; // x-amz-request-id 등
}

/// 이미지 URL 진단 프로브
/// HEAD 또는 Range GET으로 상태/헤더 수집
class ImageUrlProbe {
  ImageUrlProbe({
    required AppConfig config,
    ServerErrorLogger? errorLogger,
  })  : _networkGuard = NetworkGuard(errorLogger: errorLogger),
        _client = HttpClient();

  final NetworkGuard _networkGuard;
  final HttpClient _client;

  /// 이미지 URL을 프로브하여 상태/헤더 정보 수집
  ///
  /// [url] 프로브할 이미지 URL
  /// [traceId] 로깅용 traceId
  ///
  /// 반환: ImageProbeResult (실패 시 null)
  Future<ImageProbeResult?> probe(String url, String traceId) async {
    if (!kDebugMode) {
      return null; // 디버그 모드에서만 실행
    }

    final sanitized = LogSanitizer.sanitizeUrlForLog(url);
    if (kDebugMode) {
      debugPrint('$_logPrefix probe 시작: traceId=$traceId, url=$sanitized');
    }

    try {
      // HEAD 먼저 시도
      final headResult = await _probeHead(url, traceId);
      if (headResult != null) {
        return headResult;
      }

      // HEAD 실패 시 Range GET으로 fallback
      if (kDebugMode) {
        debugPrint('$_logPrefix HEAD 실패, Range GET으로 fallback: traceId=$traceId');
      }
      return await _probeRangeGet(url, traceId);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('$_logPrefix probe 실패: traceId=$traceId, error=$e');
        debugPrint('$_logPrefix 스택 트레이스: $stackTrace');
      }
      return null;
    }
  }

  /// HEAD 요청으로 프로브
  Future<ImageProbeResult?> _probeHead(String url, String traceId) async {
    final uri = Uri.parse(url);

    try {
      final result = await _networkGuard.execute<ImageProbeResult?>(
        operation: () => _executeHead(uri),
        retryPolicy: RetryPolicy.none, // 프로브는 재시도 없음
        context: 'image_url_probe_head',
        uri: uri,
        method: 'HEAD',
        meta: {'traceId': traceId, 'url_hash': LogSanitizer.hashUrl(url)},
      );
      return result;
    } on NetworkRequestException catch (e) {
      // 405 Method Not Allowed 등은 Range GET으로 fallback
      if (e.statusCode == 405 || e.statusCode == 403) {
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix HEAD 실패 (status=${e.statusCode}), Range GET으로 fallback: traceId=$traceId',
          );
        }
        return null;
      }
      // 기타 에러는 결과 반환 (404 등)
      return ImageProbeResult(
        statusCode: e.statusCode ?? 0,
        methodUsed: 'HEAD',
      );
    }
  }

  /// HEAD 요청 실제 실행
  Future<ImageProbeResult?> _executeHead(Uri uri) async {
    final request = await _client.openUrl('HEAD', uri);
    final response = await request.close();

    final headers = response.headers;
    return ImageProbeResult(
      statusCode: response.statusCode,
      methodUsed: 'HEAD',
      contentType: headers.value(HttpHeaders.contentTypeHeader),
      contentLength: headers.contentLength,
      cacheControl: headers.value(HttpHeaders.cacheControlHeader),
      date: headers.value(HttpHeaders.dateHeader),
      etag: headers.value(HttpHeaders.etagHeader),
      server: headers.value('server'),
      requestId: headers.value('x-amz-request-id') ?? headers.value('x-request-id'),
    );
  }

  /// Range GET 요청으로 프로브 (1바이트만)
  Future<ImageProbeResult?> _probeRangeGet(String url, String traceId) async {
    final uri = Uri.parse(url);

    try {
      final result = await _networkGuard.execute<ImageProbeResult?>(
        operation: () => _executeRangeGet(uri),
        retryPolicy: RetryPolicy.none,
        context: 'image_url_probe_range_get',
        uri: uri,
        method: 'GET',
        meta: {'traceId': traceId, 'url_hash': LogSanitizer.hashUrl(url)},
      );
      return result;
    } on NetworkRequestException catch (e) {
      return ImageProbeResult(
        statusCode: e.statusCode ?? 0,
        methodUsed: 'GET(range)',
      );
    }
  }

  /// Range GET 요청 실제 실행
  Future<ImageProbeResult?> _executeRangeGet(Uri uri) async {
    final request = await _client.openUrl('GET', uri);
    request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0'); // 1바이트만
    final response = await request.close();

    // 응답 본문 읽기 (1바이트)
    await response.drain();

    final headers = response.headers;
    return ImageProbeResult(
      statusCode: response.statusCode,
      methodUsed: 'GET(range)',
      contentType: headers.value(HttpHeaders.contentTypeHeader),
      contentLength: headers.contentLength,
      cacheControl: headers.value(HttpHeaders.cacheControlHeader),
      date: headers.value(HttpHeaders.dateHeader),
      etag: headers.value(HttpHeaders.etagHeader),
      server: headers.value('server'),
      requestId: headers.value('x-amz-request-id') ?? headers.value('x-request-id'),
    );
  }
}
