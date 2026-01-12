import 'dart:async';
import 'dart:io';

/// 네트워크 에러 타입
enum NetworkErrorType {
  /// 네트워크 연결 불가
  network,

  /// 요청 타임아웃
  timeout,

  /// 인증 실패 (401) - 세션 만료/토큰 무효
  unauthorized,

  /// 권한 거부 (403, 42501) - 권한/정책 문제, refresh로 해결 불가
  forbidden,

  /// 서버 에러 (5xx)
  serverUnavailable,

  /// 응답 파싱 실패
  invalidPayload,

  /// 서버 거부 (4xx 중 401/403 제외)
  serverRejected,

  /// 설정 누락
  missingConfig,

  /// 알 수 없는 에러
  unknown,
}

/// 네트워크 요청 실패를 나타내는 예외
class NetworkRequestException implements Exception {
  const NetworkRequestException({
    required this.type,
    this.statusCode,
    this.message,
    this.originalError,
    // 응답 파싱 결과 (SSOT)
    this.rawBody,
    this.parsedErrorCode,
    this.parsedErrorDescription,
    this.parsedErrorMessage, // PostgREST 에러 바디의 message 필드 (예: 'content_blocked')
    this.parsedErrorDetails, // PostgREST 에러 바디의 details 필드 (에러 상세 설명)
    this.contentType,
    this.isHtml,
    this.isEmpty,
    this.endpoint,
  });

  final NetworkErrorType type;
  final int? statusCode;
  final String? message; // 정규화된 safe 문자열만 사용
  final Object? originalError;
  // 응답 파싱 결과 (SSOT) - 로그에 직접 출력 금지
  final String? rawBody;
  final String? parsedErrorCode;
  final String? parsedErrorDescription;
  final String? parsedErrorMessage; // PostgREST 에러 바디의 message 필드 (예: 'content_blocked')
  final String? parsedErrorDetails; // PostgREST 에러 바디의 details 필드 (에러 상세 설명)
  final String? contentType;
  final bool? isHtml;
  final bool? isEmpty;
  final String? endpoint;

  /// 원본 에러로부터 NetworkRequestException 생성
  factory NetworkRequestException.fromError(
    Object error, {
    int? statusCode,
    String? responseBody,
  }) {
    if (error is NetworkRequestException) {
      return error;
    }

    if (error is SocketException) {
      return NetworkRequestException(
        type: NetworkErrorType.network,
        originalError: error,
      );
    }

    if (error is TimeoutException) {
      return NetworkRequestException(
        type: NetworkErrorType.timeout,
        originalError: error,
      );
    }

    if (error is HttpException) {
      return NetworkRequestException(
        type: NetworkErrorType.network,
        originalError: error,
      );
    }

    if (error is FormatException) {
      return NetworkRequestException(
        type: NetworkErrorType.invalidPayload,
        message: responseBody,
        originalError: error,
      );
    }

    // HTTP 상태 코드 기반 분류
    if (statusCode != null) {
      // ✅ 403 = forbidden (권한/정책 문제, refresh로 해결 불가)
      if (statusCode == HttpStatus.forbidden) {
        return NetworkRequestException(
          type: NetworkErrorType.forbidden,
          statusCode: statusCode,
          message: responseBody,
        );
      }
      // ✅ 401만 unauthorized (세션 만료/토큰 무효)
      if (statusCode == HttpStatus.unauthorized) {
        return NetworkRequestException(
          type: NetworkErrorType.unauthorized,
          statusCode: statusCode,
          message: responseBody,
        );
      }

      if (statusCode >= 500) {
        return NetworkRequestException(
          type: NetworkErrorType.serverUnavailable,
          statusCode: statusCode,
          message: responseBody,
        );
      }

      if (statusCode >= 400) {
        return NetworkRequestException(
          type: NetworkErrorType.serverRejected,
          statusCode: statusCode,
          message: responseBody,
        );
      }
    }

    return NetworkRequestException(
      type: NetworkErrorType.unknown,
      originalError: error,
    );
  }

  @override
  String toString() {
    return 'NetworkRequestException(type: $type, statusCode: $statusCode, message: $message)';
  }
}
