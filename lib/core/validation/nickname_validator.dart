/// 닉네임 검증 유틸
class NicknameValidator {
  /// 닉네임 최소 길이
  static const int minLength = 2;

  /// 닉네임 최대 길이
  static const int maxLength = 12;

  /// 닉네임 정규화 (DB nickname_norm과 동일 기준: lower(trim(nickname)))
  /// 서버와 클라이언트 간 정규화 기준을 통일하여 변경 판정/유니크 체크에 사용
  static String normalize(String nickname) {
    return nickname.trim().toLowerCase();
  }

  /// 허용된 문자 정규식 (한글/영문/숫자/언더스코어만)
  /// ^[a-zA-Z0-9가-힣_]+$
  static final RegExp _allowedPattern = RegExp(r'^[a-zA-Z0-9가-힣_]+$');

  /// 금칙어 리스트 (로컬, 운영 시 서버 테이블로 확장)
  static const List<String> _forbiddenWords = [
    'admin',
    'administrator',
    'moderator',
    'test',
    'null',
    'undefined',
    'echowander',
    '에코원더',
  ];

  /// 닉네임 검증 결과
  static NicknameValidationResult validate(String nickname) {
    // 공백 trim
    final trimmed = nickname.trim();

    // 빈 문자열 체크
    if (trimmed.isEmpty) {
      return NicknameValidationResult(
        isValid: false,
        error: NicknameValidationError.empty,
      );
    }

    // 길이 체크
    if (trimmed.length < minLength) {
      return NicknameValidationResult(
        isValid: false,
        error: NicknameValidationError.tooShort,
      );
    }

    if (trimmed.length > maxLength) {
      return NicknameValidationResult(
        isValid: false,
        error: NicknameValidationError.tooLong,
      );
    }

    // 연속 공백 체크
    if (trimmed.contains('  ')) {
      return NicknameValidationResult(
        isValid: false,
        error: NicknameValidationError.consecutiveSpaces,
      );
    }

    // 특수문자 체크 (허용된 문자만)
    if (!_allowedPattern.hasMatch(trimmed)) {
      return NicknameValidationResult(
        isValid: false,
        error: NicknameValidationError.invalidCharacters,
      );
    }

    // 양끝 언더스코어 체크
    if (trimmed.startsWith('_') || trimmed.endsWith('_')) {
      return NicknameValidationResult(
        isValid: false,
        error: NicknameValidationError.underscoreAtEnds,
      );
    }

    // 연속 언더스코어 체크
    if (trimmed.contains('__')) {
      return NicknameValidationResult(
        isValid: false,
        error: NicknameValidationError.consecutiveUnderscores,
      );
    }

    // 금칙어 체크 (정규화 + compact 기준)
    final normalized = trimmed.toLowerCase();
    final compact = normalized.replaceAll(RegExp(r'[_\s]+'), '');

    for (final word in _forbiddenWords) {
      final wordNormalized = word.toLowerCase();
      final wordCompact = wordNormalized.replaceAll(RegExp(r'[_\s]+'), '');

      // 정규화된 닉네임에 금칙어 포함 체크
      if (normalized.contains(wordNormalized)) {
        return NicknameValidationResult(
          isValid: false,
          error: NicknameValidationError.forbiddenWord,
        );
      }

      // compact 기준으로도 체크 (띄어쓰기/언더스코어 회피 방지)
      if (compact.contains(wordCompact)) {
        return NicknameValidationResult(
          isValid: false,
          error: NicknameValidationError.forbiddenWord,
        );
      }
    }

    return NicknameValidationResult(isValid: true);
  }
}

/// 닉네임 검증 결과
class NicknameValidationResult {
  const NicknameValidationResult({
    required this.isValid,
    this.error,
  });

  final bool isValid;
  final NicknameValidationError? error;
}

/// 닉네임 검증 에러 타입
enum NicknameValidationError {
  empty,
  tooShort,
  tooLong,
  consecutiveSpaces,
  invalidCharacters,
  underscoreAtEnds,
  consecutiveUnderscores,
  forbiddenWord,
}
