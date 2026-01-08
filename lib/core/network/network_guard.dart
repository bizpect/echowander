import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../logging/server_error_logger.dart';
import 'network_error.dart';

/// 네트워크 요청 재시도 정책
class RetryPolicy {
  const RetryPolicy({
    required this.maxAttempts,
    required this.backoffDuration,
  });

  /// 재시도 없음 (POST/커밋 액션용)
  static const none = RetryPolicy(maxAttempts: 1, backoffDuration: Duration.zero);

  /// 짧은 재시도 (GET/조회용)
  static const short = RetryPolicy(
    maxAttempts: 2,
    backoffDuration: Duration(milliseconds: 500),
  );

  final int maxAttempts;
  final Duration backoffDuration;
}

/// 네트워크 요청 가드 - 공통 네트워크 에러 처리 및 재시도 정책
class NetworkGuard {
  NetworkGuard({
    ServerErrorLogger? errorLogger,
  }) : _errorLogger = errorLogger;

  /// 에러 로거 (null이면 로깅 스킵 - 순환 의존성 방지용)
  final ServerErrorLogger? _errorLogger;

  /// 네트워크 요청 실행
  ///
  /// [operation]: 실행할 비동기 작업
  /// [retryPolicy]: 재시도 정책 (기본: none)
  /// [context]: 로깅용 컨텍스트 이름
  /// [uri]: 요청 URI (로깅용)
  /// [method]: HTTP 메소드 (로깅용)
  /// [meta]: 추가 메타데이터 (로깅용)
  /// [accessToken]: 액세스 토큰 (로깅용)
  Future<T> execute<T>({
    required Future<T> Function() operation,
    RetryPolicy retryPolicy = RetryPolicy.none,
    required String context,
    Uri? uri,
    String? method,
    Map<String, dynamic>? meta,
    String? accessToken,
  }) async {
    // nullable 파라미터를 non-nullable로 변환 (로깅용 기본값)
    final logUri = uri ?? Uri.parse('unknown://unknown');
    final logMethod = method ?? 'UNKNOWN';
    
    // journeyId 추출 (로깅용)
    final journeyId = meta?['journey_id'] as String?;
    final traceLabel = journeyId != null ? '$context:journeyId=$journeyId' : context;

    int attempt = 0;
    Object? lastError;
    int? lastStatusCode;
    String? lastResponseBody;

    while (attempt < retryPolicy.maxAttempts) {
      attempt++;

      try {
        if (kDebugMode && attempt > 1) {
          debugPrint('[NetworkGuard][$traceLabel] 재시도 시도 $attempt/${retryPolicy.maxAttempts}');
        }

        final result = await operation();
        return result;
      } on SocketException catch (error) {
        lastError = error;
        if (kDebugMode) {
          debugPrint('[NetworkGuard][$traceLabel] SocketException: $error');
        }

        // 에러 로거가 있으면 로깅 (null이면 스킵 - 순환 의존성 방지)
        await _errorLogger?.logException(
          context: context,
          uri: logUri,
          method: logMethod,
          error: error,
          meta: {...?meta, 'attempt': attempt},
          accessToken: accessToken,
        );

        if (attempt >= retryPolicy.maxAttempts) {
          throw NetworkRequestException(
            type: NetworkErrorType.network,
            originalError: error,
          );
        }

        await Future.delayed(retryPolicy.backoffDuration);
      } on TimeoutException catch (error) {
        lastError = error;
        if (kDebugMode) {
          debugPrint('[NetworkGuard][$traceLabel] TimeoutException: $error');
        }

        // 에러 로거가 있으면 로깅 (null이면 스킵 - 순환 의존성 방지)
        await _errorLogger?.logException(
          context: context,
          uri: logUri,
          method: logMethod,
          error: error,
          meta: {...?meta, 'attempt': attempt},
          accessToken: accessToken,
        );

        if (attempt >= retryPolicy.maxAttempts) {
          throw NetworkRequestException(
            type: NetworkErrorType.timeout,
            originalError: error,
          );
        }

        await Future.delayed(retryPolicy.backoffDuration);
      } on HttpException catch (error) {
        lastError = error;
        if (kDebugMode) {
          debugPrint('[NetworkGuard][$traceLabel] HttpException: $error');
        }

        // 에러 로거가 있으면 로깅 (null이면 스킵 - 순환 의존성 방지)
        await _errorLogger?.logException(
          context: context,
          uri: logUri,
          method: logMethod,
          error: error,
          meta: {...?meta, 'attempt': attempt},
          accessToken: accessToken,
        );

        if (attempt >= retryPolicy.maxAttempts) {
          throw NetworkRequestException(
            type: NetworkErrorType.network,
            originalError: error,
          );
        }

        await Future.delayed(retryPolicy.backoffDuration);
      } on FormatException catch (error) {
        lastError = error;
        if (kDebugMode) {
          debugPrint('[NetworkGuard][$traceLabel] FormatException: $error');
        }

        // 에러 로거가 있으면 로깅 (null이면 스킵 - 순환 의존성 방지)
        await _errorLogger?.logException(
          context: context,
          uri: logUri,
          method: logMethod,
          error: error,
          meta: {
            ...?meta,
            'attempt': attempt,
            'response_status': lastStatusCode,
            'response_body': lastResponseBody,
          },
          accessToken: accessToken,
        );

        // 파싱 에러는 재시도하지 않음
        throw NetworkRequestException(
          type: NetworkErrorType.invalidPayload,
          message: lastResponseBody,
          originalError: error,
        );
      } on NetworkRequestException {
        // 이미 NetworkRequestException으로 변환된 경우 재throw
        rethrow;
      } catch (error) {
        lastError = error;
        if (kDebugMode) {
          debugPrint('[NetworkGuard][$traceLabel] Unknown error: $error, type=${error.runtimeType}');
        }

        // 에러 로거가 있으면 로깅 (null이면 스킵 - 순환 의존성 방지)
        await _errorLogger?.logException(
          context: context,
          uri: logUri,
          method: logMethod,
          error: error,
          meta: {
            ...?meta,
            'attempt': attempt,
            'response_status': lastStatusCode,
            'response_body': lastResponseBody,
          },
          accessToken: accessToken,
        );

        // 알 수 없는 에러는 재시도하지 않음
        throw NetworkRequestException(
          type: NetworkErrorType.unknown,
          originalError: error,
        );
      }
    }

    // 모든 재시도 실패 시
    if (lastError != null) {
      throw NetworkRequestException.fromError(
        lastError,
        statusCode: lastStatusCode,
        responseBody: lastResponseBody,
      );
    }

    // 이론상 도달 불가
    throw NetworkRequestException(
      type: NetworkErrorType.unknown,
      message: 'All retry attempts failed',
    );
  }

  /// HTTP 응답 상태 코드를 NetworkRequestException으로 변환
  NetworkRequestException statusCodeToException({
    required int statusCode,
    required String responseBody,
    String? context,
    // 응답 파싱 결과 (SSOT)
    String? rawBody,
    String? parsedErrorCode,
    String? parsedErrorDescription,
    String? contentType,
    bool? isHtml,
    bool? isEmpty,
    String? endpoint,
  }) {
    // 정규화된 safe 메시지 생성
    final safeMessage = parsedErrorCode != null
        ? 'status=$statusCode error=$parsedErrorCode${parsedErrorDescription != null ? " desc=$parsedErrorDescription" : ""}'
        : (isHtml == true
            ? 'status=$statusCode html_response'
            : (isEmpty == true
                ? 'status=$statusCode empty_response'
                : 'status=$statusCode response_length=${responseBody.length}'));

    if (statusCode == HttpStatus.unauthorized || statusCode == HttpStatus.forbidden) {
      return NetworkRequestException(
        type: NetworkErrorType.unauthorized,
        statusCode: statusCode,
        message: safeMessage,
        rawBody: rawBody ?? responseBody,
        parsedErrorCode: parsedErrorCode,
        parsedErrorDescription: parsedErrorDescription,
        contentType: contentType,
        isHtml: isHtml,
        isEmpty: isEmpty,
        endpoint: endpoint,
      );
    }

    if (statusCode >= 500) {
      return NetworkRequestException(
        type: NetworkErrorType.serverUnavailable,
        statusCode: statusCode,
        message: safeMessage,
        rawBody: rawBody ?? responseBody,
        parsedErrorCode: parsedErrorCode,
        parsedErrorDescription: parsedErrorDescription,
        contentType: contentType,
        isHtml: isHtml,
        isEmpty: isEmpty,
        endpoint: endpoint,
      );
    }

    if (statusCode >= 400) {
      return NetworkRequestException(
        type: NetworkErrorType.serverRejected,
        statusCode: statusCode,
        message: safeMessage,
        rawBody: rawBody ?? responseBody,
        parsedErrorCode: parsedErrorCode,
        parsedErrorDescription: parsedErrorDescription,
        contentType: contentType,
        isHtml: isHtml,
        isEmpty: isEmpty,
        endpoint: endpoint,
      );
    }

    return NetworkRequestException(
      type: NetworkErrorType.unknown,
      statusCode: statusCode,
      message: safeMessage,
      rawBody: rawBody ?? responseBody,
      parsedErrorCode: parsedErrorCode,
      parsedErrorDescription: parsedErrorDescription,
      contentType: contentType,
      isHtml: isHtml,
      isEmpty: isEmpty,
      endpoint: endpoint,
    );
  }
}
