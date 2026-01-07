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
  String get loginDescription => '익명 릴레이 메시지를 시작하세요';

  @override
  String get loginKakao => '카카오로 계속';

  @override
  String get loginGoogle => '구글로 계속';

  @override
  String get loginApple => '애플로 계속';

  @override
  String get loginTerms => '로그인 시 서비스 약관 및 개인정보 처리방침에 동의하게 됩니다';

  @override
  String get homeTitle => '홈';

  @override
  String get homeGreeting => '다시 오신 걸 환영합니다';

  @override
  String get homeRecentJourneysTitle => '최근 보낸 메시지';

  @override
  String get homeActionsTitle => '시작하기';

  @override
  String get homeEmptyTitle => '에코원더에 오신 것을 환영합니다';

  @override
  String get homeEmptyDescription => '첫 릴레이 메시지를 작성하거나 받은 메시지를 확인해 보세요.';

  @override
  String get homeInboxCardTitle => '받은 편지함';

  @override
  String get homeInboxCardDescription => '받은 메시지를 확인하고 응답하세요.';

  @override
  String get homeCreateCardTitle => '메시지 작성';

  @override
  String get homeCreateCardDescription => '새로운 릴레이 메시지를 시작하세요.';

  @override
  String get homeJourneyCardViewDetails => '자세히 보기';

  @override
  String get homeRefresh => '새로고침';

  @override
  String get homeLoadFailed => '데이터를 불러올 수 없습니다.';

  @override
  String homeInboxCount(Object count) {
    return '$count개의 새 메시지';
  }

  @override
  String get settingsCta => '설정';

  @override
  String get settingsNotificationInbox => '알림함';

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
  String get notificationsTitle => '알림함';

  @override
  String get notificationsEmpty => '아직 알림이 없어요.';

  @override
  String get notificationsUnreadOnly => '미읽음만 보기';

  @override
  String get notificationsRead => '읽음';

  @override
  String get notificationsUnread => '새 알림';

  @override
  String get notificationsDeleteTitle => '알림 삭제';

  @override
  String get notificationsDeleteMessage => '이 알림을 삭제할까요?';

  @override
  String get notificationsDeleteConfirm => '삭제';

  @override
  String get pushJourneyAssignedTitle => '새 메시지';

  @override
  String get pushJourneyAssignedBody => '새 릴레이 메시지가 도착했어요.';

  @override
  String get pushJourneyResultTitle => '결과 도착';

  @override
  String get pushJourneyResultBody => '릴레이 결과를 확인해 주세요.';

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

  @override
  String get composeTitle => '메시지 작성';

  @override
  String get composeLabel => '메시지';

  @override
  String get composeHint => '전하고 싶은 이야기를 적어주세요.';

  @override
  String composeCharacterCount(Object current, Object total) {
    return '$total자 중 $current자';
  }

  @override
  String get composeImagesTitle => '사진';

  @override
  String get composeAddImage => '사진 추가';

  @override
  String get composeSubmit => '보내기';

  @override
  String get composeCta => '메시지 작성';

  @override
  String get composeTooLong => '글자 수가 너무 많아요.';

  @override
  String get composeForbidden => 'URL이나 연락처는 제외해 주세요.';

  @override
  String get composeEmpty => '메시지를 입력해 주세요.';

  @override
  String get composeInvalid => '메시지를 다시 확인해 주세요.';

  @override
  String get composeImageLimit => '사진은 최대 3장까지 첨부할 수 있어요.';

  @override
  String get composePermissionDenied => '사진 접근 권한이 필요해요.';

  @override
  String get composeSessionMissing => '다시 로그인해 주세요.';

  @override
  String get composeSubmitFailed => '메시지 전송에 실패했어요. 다시 시도해 주세요.';

  @override
  String get composeServerMisconfigured =>
      '서비스 설정이 아직 완료되지 않았어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get composeSubmitSuccess => '메시지를 보냈어요.';

  @override
  String get composeRecipientCountLabel => '릴레이 인원';

  @override
  String get composeRecipientCountHint => '1~5명을 선택해 주세요.';

  @override
  String composeRecipientCountOption(Object count) {
    return '$count명';
  }

  @override
  String get composeRecipientRequired => '릴레이 인원을 선택해 주세요.';

  @override
  String get composeRecipientInvalid => '릴레이 인원은 1~5명만 선택할 수 있어요.';

  @override
  String get composeErrorTitle => '안내';

  @override
  String get composeSuccessTitle => '완료';

  @override
  String get composeOk => '확인';

  @override
  String get composeCancel => '취소';

  @override
  String get composePermissionTitle => '사진 권한 필요';

  @override
  String get composePermissionMessage => '설정에서 사진 접근을 허용해 주세요.';

  @override
  String get composeOpenSettings => '설정 열기';

  @override
  String get journeyListTitle => '보낸 메시지';

  @override
  String get journeyListEmpty => '아직 보낸 메시지가 없어요.';

  @override
  String get journeyListCta => '보낸 메시지 보기';

  @override
  String get journeyListStatusLabel => '상태:';

  @override
  String get journeyStatusCreated => '전송 완료';

  @override
  String get journeyStatusWaiting => '매칭 대기';

  @override
  String get journeyStatusCompleted => '처리 완료';

  @override
  String get journeyStatusInProgress => '진행중';

  @override
  String get journeyStatusUnknown => '알 수 없음';

  @override
  String get journeyInProgressHint => '완료 후 상세에서 답변을 확인할 수 있어요';

  @override
  String get journeyFilterOk => '정상';

  @override
  String get journeyFilterHeld => '검토 중';

  @override
  String get journeyFilterRemoved => '제한됨';

  @override
  String get journeyFilterUnknown => '알 수 없음';

  @override
  String get inboxTitle => '받은 메시지';

  @override
  String get inboxEmpty => '받은 메시지가 없어요.';

  @override
  String get inboxCta => '받은 메시지 보기';

  @override
  String get inboxRefresh => '새로고침';

  @override
  String get inboxLoadFailed => '받은 메시지를 불러올 수 없습니다.';

  @override
  String inboxImageCount(Object count) {
    return '사진 $count개';
  }

  @override
  String get inboxStatusLabel => '상태:';

  @override
  String get inboxStatusAssigned => '대기 중';

  @override
  String get inboxStatusResponded => '응답 완료';

  @override
  String get inboxStatusPassed => '패스';

  @override
  String get inboxStatusReported => '신고됨';

  @override
  String get inboxStatusUnknown => '알 수 없음';

  @override
  String get inboxDetailTitle => '받은 메시지';

  @override
  String get inboxDetailMissing => '메시지를 불러오지 못했어요.';

  @override
  String get inboxImagesLabel => '사진';

  @override
  String get inboxImagesLoadFailed => '사진을 불러오지 못했어요.';

  @override
  String get inboxBlockCta => '보낸 사람 차단';

  @override
  String get inboxBlockTitle => '차단하기';

  @override
  String get inboxBlockMessage => '이 사용자의 다음 메시지는 받지 않아요.';

  @override
  String get inboxBlockConfirm => '차단';

  @override
  String get inboxBlockSuccessTitle => '차단 완료';

  @override
  String get inboxBlockSuccessBody => '사용자를 차단했어요.';

  @override
  String get inboxBlockFailed => '차단을 완료하지 못했어요.';

  @override
  String get inboxBlockMissing => '보낸 사람 정보를 찾지 못했어요.';

  @override
  String get inboxRespondLabel => '답장';

  @override
  String get inboxRespondHint => '답장을 입력하세요...';

  @override
  String get inboxRespondCta => '답장 보내기';

  @override
  String get inboxRespondEmpty => '답장을 입력해 주세요.';

  @override
  String get inboxRespondSuccessTitle => '답장 완료';

  @override
  String get inboxRespondSuccessBody => '답장을 보냈어요.';

  @override
  String get inboxPassCta => '패스';

  @override
  String get inboxPassSuccessTitle => '패스 완료';

  @override
  String get inboxPassSuccessBody => '이번 메시지는 패스했어요.';

  @override
  String get inboxReportCta => '신고';

  @override
  String get inboxReportTitle => '신고 사유';

  @override
  String get inboxReportSpam => '스팸';

  @override
  String get inboxReportAbuse => '부적절한 내용';

  @override
  String get inboxReportOther => '기타';

  @override
  String get inboxReportSuccessTitle => '신고 완료';

  @override
  String get inboxReportSuccessBody => '신고가 접수됐어요.';

  @override
  String get inboxActionFailed => '처리를 완료하지 못했어요.';

  @override
  String get journeyDetailTitle => '메시지';

  @override
  String get journeyDetailMessageLabel => '메시지';

  @override
  String get journeyDetailMessageUnavailable => '메시지를 불러올 수 없어요.';

  @override
  String get journeyDetailProgressTitle => '릴레이 진행';

  @override
  String get journeyDetailStatusLabel => '상태';

  @override
  String get journeyDetailDeadlineLabel => '릴레이 마감';

  @override
  String get journeyDetailResponseTargetLabel => '목표 응답 수';

  @override
  String get journeyDetailRespondedLabel => '응답';

  @override
  String get journeyDetailAssignedLabel => '할당';

  @override
  String get journeyDetailPassedLabel => '패스';

  @override
  String get journeyDetailReportedLabel => '신고';

  @override
  String get journeyDetailCountriesLabel => '릴레이 지역';

  @override
  String get journeyDetailCountriesEmpty => '아직 지역 정보가 없어요.';

  @override
  String get journeyDetailResultsTitle => '결과';

  @override
  String get journeyDetailResultsLocked => '릴레이 완료 후 결과가 표시돼요.';

  @override
  String get journeyDetailResultsEmpty => '아직 응답이 없어요.';

  @override
  String get journeyDetailResultsLoadFailed => '결과를 불러오지 못했어요.';

  @override
  String get journeyDetailLoadFailed => '진행 정보를 불러오지 못했어요.';

  @override
  String get journeyDetailRetry => '다시 시도';

  @override
  String get journeyDetailAdRequired => '결과를 보기 전에 광고를 시청해 주세요.';

  @override
  String get journeyDetailAdCta => '광고 보고 결과 보기';

  @override
  String get journeyDetailAdFailedTitle => '광고를 불러오지 못했어요';

  @override
  String get journeyDetailAdFailedBody => '광고 없이 결과를 볼까요?';

  @override
  String get journeyDetailAdFailedConfirm => '그냥 보기';

  @override
  String get journeyResultReportCta => '응답 신고';

  @override
  String get journeyResultReportSuccessTitle => '신고 완료';

  @override
  String get journeyResultReportSuccessBody => '신고가 접수됐어요.';

  @override
  String get journeyResultReportFailed => '신고를 완료하지 못했어요.';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionNotification => '알림';

  @override
  String get settingsNotificationToggle => '알림 받기';

  @override
  String get settingsNotificationHint => '릴레이 진행과 결과를 알려드려요.';

  @override
  String get settingsSectionSafety => '안전';

  @override
  String get settingsBlockedUsers => '차단 목록';

  @override
  String get settingsLoadFailed => '설정을 불러오지 못했어요.';

  @override
  String get settingsUpdateFailed => '설정을 저장하지 못했어요.';

  @override
  String get blockListTitle => '차단 목록';

  @override
  String get blockListEmpty => '차단한 사용자가 없어요.';

  @override
  String get blockListUnknownUser => '알 수 없는 사용자';

  @override
  String get blockListLoadFailed => '차단 목록을 불러오지 못했어요.';

  @override
  String get blockListUnblock => '차단 해제';

  @override
  String get blockListUnblockTitle => '차단 해제';

  @override
  String get blockListUnblockMessage => '이 사용자의 메시지를 다시 받을까요?';

  @override
  String get blockListUnblockConfirm => '해제';

  @override
  String get blockListUnblockFailed => '차단 해제를 완료하지 못했어요.';

  @override
  String get onboardingTitle => '온보딩';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return '총 $total단계 중 $current단계';
  }

  @override
  String get onboardingNotificationTitle => '알림 권한';

  @override
  String get onboardingNotificationDescription => '릴레이 메시지 도착과 결과 완료를 알려드립니다.';

  @override
  String get onboardingNotificationNote =>
      '설정에서 언제든 변경할 수 있으며, 이 단계는 건너뛸 수 있습니다.';

  @override
  String get onboardingAllowNotifications => '허용';

  @override
  String get onboardingPhotoTitle => '사진 접근 권한';

  @override
  String get onboardingPhotoDescription => '프로필 이미지 설정 및 메시지 이미지 첨부 시에만 사용됩니다.';

  @override
  String get onboardingPhotoNote => '선택한 사진만 접근하며, 이 단계는 건너뛸 수 있습니다.';

  @override
  String get onboardingAllowPhotos => '허용';

  @override
  String get onboardingGuidelineTitle => '커뮤니티 가이드라인';

  @override
  String get onboardingGuidelineDescription =>
      '안전한 이용을 위해 혐오, 괴롭힘, 개인정보 노출 등의 행위를 금지합니다. 위반 시 콘텐츠가 제한될 수 있습니다.';

  @override
  String get onboardingAgreeGuidelines => '커뮤니티 가이드라인에 동의합니다.';

  @override
  String get onboardingContentPolicyTitle => '콘텐츠 정책';

  @override
  String get onboardingContentPolicyDescription =>
      '불법, 유해, 폭력적 콘텐츠는 금지되며, 위반 콘텐츠는 검토 후 제한될 수 있습니다.';

  @override
  String get onboardingAgreeContentPolicy => '콘텐츠 정책에 동의합니다.';

  @override
  String get onboardingSafetyTitle => '신고 및 차단';

  @override
  String get onboardingSafetyDescription =>
      '불쾌하거나 부적절한 콘텐츠를 신고하거나, 특정 사용자를 차단하여 메시지를 받지 않을 수 있습니다.';

  @override
  String get onboardingConfirmSafety => '신고 및 차단 정책을 확인했습니다.';

  @override
  String get onboardingSkip => '건너뛰기';

  @override
  String get onboardingNext => '다음';

  @override
  String get onboardingStart => '시작하기';

  @override
  String get onboardingAgreeAndDisagree => '동의 및 미동의';

  @override
  String get onboardingPrevious => '이전';

  @override
  String get ctaPermissionChoice => '권한 선택';

  @override
  String get onboardingExitTitle => '온보딩을 종료하시겠어요?';

  @override
  String get onboardingExitMessage => '나중에 다시 시작할 수 있어요.';

  @override
  String get onboardingExitConfirm => '종료';

  @override
  String get onboardingExitCancel => '계속하기';

  @override
  String get exitConfirmTitle => '작성을 취소하시겠어요?';

  @override
  String get exitConfirmMessage => '입력한 내용이 사라집니다.';

  @override
  String get exitConfirmContinue => '계속 작성';

  @override
  String get exitConfirmLeave => '나가기';

  @override
  String get tabHomeLabel => '홈';

  @override
  String get tabSentLabel => '보낸 메시지';

  @override
  String get tabInboxLabel => '받은편지함';

  @override
  String get tabCreateLabel => '메시지 작성';

  @override
  String get tabAlertsLabel => '알림';

  @override
  String get tabProfileLabel => '프로필';

  @override
  String get profileSignOutCta => '로그아웃';

  @override
  String get profileSignOutTitle => '로그아웃';

  @override
  String get profileSignOutMessage => '정말 로그아웃하시겠습니까?';

  @override
  String get profileSignOutConfirm => '로그아웃';

  @override
  String get profileUserIdLabel => '사용자 ID';

  @override
  String get profileDefaultNickname => '사용자';

  @override
  String get journeyDetailAnonymous => '익명';

  @override
  String get errorNetwork => '네트워크 연결을 확인해 주세요.';

  @override
  String get errorTimeout => '요청 시간이 초과되었습니다. 다시 시도해 주세요.';

  @override
  String get errorServerUnavailable => '서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorUnauthorized => '다시 로그인해 주세요.';

  @override
  String get errorRetry => '다시 시도';

  @override
  String get errorCancel => '취소';
}
