import 'dart:io';

/// 표준 비즈니스 에러 키 (P0001 에러의 message 필드와 매핑)
enum BusinessErrorKey {
  /// 콘텐츠 차단 (moderation BLOCK)
  contentBlocked,

  /// 닉네임 금칙어 포함
  nicknameForbidden,

  /// 닉네임 중복
  nicknameTaken,
}

/// PostgREST 비즈니스 에러 매퍼
///
/// 서버에서 Postgres RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='key'로
/// 내려오는 비즈니스 에러를 표준 키로 변환합니다.
class BusinessErrorMapper {
  /// PostgREST 에러 응답에서 비즈니스 에러 키 추출
  ///
  /// [statusCode]: HTTP 상태 코드
  /// [code]: PostgREST 에러 바디의 code 필드 (예: 'P0001')
  /// [message]: PostgREST 에러 바디의 message 필드 (예: 'content_blocked')
  ///
  /// 반환: 비즈니스 에러 키 또는 null (비즈니스 에러가 아닌 경우)
  static BusinessErrorKey? fromPostgrest({
    required int? statusCode,
    required String? code,
    required String? message,
  }) {
    // ✅ statusCode == 400 && code == 'P0001' 일 때만 매핑 시도
    if (statusCode != HttpStatus.badRequest) {
      return null;
    }
    if (code != 'P0001') {
      return null;
    }

    // ✅ parsedErrorMessage 값에 따라 enum으로 변환
    switch (message) {
      case 'content_blocked':
        return BusinessErrorKey.contentBlocked;
      case 'nickname_forbidden':
        return BusinessErrorKey.nicknameForbidden;
      case 'nickname_taken':
        return BusinessErrorKey.nicknameTaken;
      default:
        // 모르는 키면 null 반환 (기존 serverRejected 흐름 유지)
        return null;
    }
  }
}
