// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '에코원더';

  @override
  String get splashTitle => '시작 중...';

  @override
  String get loginTitle => '로그인';

  @override
  String get loginKakao => '카카오로 계속';

  @override
  String get loginGoogle => '구글로 계속';

  @override
  String get loginApple => '애플로 계속';

  @override
  String get homeTitle => '홈';

  @override
  String get homeGreeting => '다시 오신 걸 환영합니다';

  @override
  String get pushPreviewTitle => '알림';

  @override
  String get pushPreviewDescription => '푸시 딥링크 테스트 화면입니다.';

  @override
  String get notificationTitle => '새 알림';

  @override
  String get notificationOpen => '열기';

  @override
  String get notificationDismiss => '닫기';

  @override
  String get errorTitle => '안내';

  @override
  String get errorGeneric => '문제가 발생했습니다. 다시 시도해주세요.';

  @override
  String get errorLoginFailed => '로그인에 실패했습니다. 다시 시도해주세요.';

  @override
  String get errorLoginCancelled => '로그인이 취소되었습니다.';

  @override
  String get errorLoginNetwork => '네트워크 상태를 확인한 뒤 다시 시도해주세요.';

  @override
  String get errorLoginInvalidToken => '로그인 검증에 실패했습니다. 다시 시도해주세요.';

  @override
  String get errorLoginUnsupportedProvider => '지원하지 않는 로그인 방식입니다.';

  @override
  String get errorLoginUserSyncFailed => '계정 정보를 저장하지 못했습니다. 다시 시도해주세요.';

  @override
  String get errorLoginServiceUnavailable =>
      '로그인 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get errorSessionExpired => '세션이 만료되었습니다. 다시 로그인해주세요.';

  @override
  String get languageSectionTitle => '언어';

  @override
  String get languageSystem => '시스템 기본';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => '영어';

  @override
  String get languageJapanese => '일본어';

  @override
  String get languageSpanish => '스페인어';

  @override
  String get languageFrench => '프랑스어';

  @override
  String get languagePortuguese => '포르투갈어';

  @override
  String get languageChinese => '중국어';
}
