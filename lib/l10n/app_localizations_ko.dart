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
  String get homeExitTitle => '앱을 종료할까요?';

  @override
  String get homeExitMessage => '지금 앱을 종료합니다.';

  @override
  String get homeExitCancel => '취소';

  @override
  String get homeExitConfirm => '앱 종료';

  @override
  String get homeExitAdLoading => '광고 로딩 중...';

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
  String get errorLoginServiceUnavailable => '로그인 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get errorSessionExpired => '세션이 만료되었습니다. 다시 로그인해주세요.';

  @override
  String get errorForbiddenTitle => '권한이 필요합니다';

  @override
  String get errorForbiddenMessage => '요청한 작업을 수행할 권한이 없습니다. 로그인 상태를 확인하거나 잠시 후 다시 시도해주세요.';

  @override
  String get journeyInboxForbiddenTitle => '인박스를 불러올 수 없어요';

  @override
  String get journeyInboxForbiddenMessage => '인박스를 조회할 권한이 없습니다. 문제가 계속되면 다시 로그인해 주세요.';

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
  String get composeWizardStep1Title => '어떤 내용으로 여정을 보낼까요?';

  @override
  String get composeWizardStep1Subtitle => '릴레이를 시작할 한 줄을 적어주세요.';

  @override
  String get composeWizardStep2Title => '몇 명에게 떨어뜨릴까요?';

  @override
  String get composeWizardStep2Subtitle => '1~5명 중에서 선택할 수 있어요.';

  @override
  String get composeWizardStep3Title => '같이 보낼 사진이 있으신가요?';

  @override
  String get composeWizardStep3Subtitle => '사진은 최대 3장, 없으면 바로 보내도 돼요.';

  @override
  String get composeWizardBack => '이전';

  @override
  String get composeWizardNext => '다음';

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
  String get composeServerMisconfigured => '서비스 설정이 아직 완료되지 않았어요. 잠시 후 다시 시도해 주세요.';

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
  String get commonClose => '닫기';

  @override
  String get journeyListTitle => '보낸 메시지';

  @override
  String get sentTabInProgress => '진행중';

  @override
  String get sentTabCompleted => '완료';

  @override
  String get sentEmptyInProgressTitle => '진행중인 메시지가 없어요';

  @override
  String get sentEmptyInProgressDescription => '새로운 릴레이 메시지를 시작해 보세요.';

  @override
  String get sentEmptyCompletedTitle => '완료된 메시지가 없어요';

  @override
  String get sentEmptyCompletedDescription => '완료된 릴레이가 여기에 표시됩니다.';

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
  String get inboxTabPending => '응답 전';

  @override
  String get inboxTabCompleted => '응답 완료';

  @override
  String get inboxEmpty => '받은 메시지가 없어요.';

  @override
  String get inboxEmptyPendingTitle => '응답 전 메시지가 없어요';

  @override
  String get inboxEmptyPendingDescription => '새로운 메시지가 도착하면 여기에 표시됩니다.';

  @override
  String get inboxEmptyCompletedTitle => '응답 완료 메시지가 없어요';

  @override
  String get inboxEmptyCompletedDescription => '응답을 완료한 메시지가 여기에 표시됩니다.';

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
  String get inboxPassedTitle => '패스한 메시지';

  @override
  String get inboxPassedDetailUnavailable => '패스 처리되어 내용을 볼 수 없습니다.';

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
  String get journeyDetailResultsTitle => '받은 댓글';

  @override
  String get journeyDetailResultsLocked => '처리완료 후 댓글을 확인할 수 있어요.';

  @override
  String get journeyDetailResultsEmpty => '아직 댓글이 없어요.';

  @override
  String get journeyDetailResultsLoadFailed => '댓글을 불러오지 못했어요.';

  @override
  String get commonTemporaryErrorTitle => '일시적인 오류';

  @override
  String get sentDetailRepliesLoadFailedMessage => '댓글을 불러오지 못했습니다.\n목록으로 이동합니다.';

  @override
  String get commonOk => '확인';

  @override
  String get journeyDetailResponsesMissingTitle => '일시적인 오류';

  @override
  String get journeyDetailResponsesMissingBody => '댓글을 불러오지 못했습니다. 다시 시도해 주세요.\n목록으로 이동합니다.';

  @override
  String get journeyDetailGateConfigTitle => '광고 준비 중';

  @override
  String get journeyDetailGateConfigBody => '광고 설정이 준비되지 않아 광고 없이 상세로 이동해요.';

  @override
  String get journeyDetailGateDismissedTitle => '광고 시청 미완료';

  @override
  String get journeyDetailGateDismissedBody => '상세를 보려면 광고를 끝까지 시청해 주세요.';

  @override
  String get journeyDetailGateFailedTitle => '광고 이용 불가';

  @override
  String get journeyDetailGateFailedBody => '광고 로드에 실패했습니다. 다시 시도해주세요.';

  @override
  String get journeyDetailUnlockFailedTitle => '잠금해제 저장에 실패했어요';

  @override
  String get journeyDetailUnlockFailedBody => '네트워크/서버 문제로 잠금해제에 실패했어요. 다시 시도해주세요.';

  @override
  String get journeyDetailGateDialogTitle => '리워드 광고로 잠금해제';

  @override
  String get journeyDetailGateDialogBody => '리워드 광고 시청으로 잠금해제 합니다.\n한 번 시청하면 영원히 잠금 풀립니다.';

  @override
  String get journeyDetailGateDialogConfirm => '잠금해제';

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
  String get settingsLanguage => '언어';

  @override
  String get settingsTheme => '테마';

  @override
  String get themeSystem => '시스템';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

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
  String get onboardingNotificationNote => '설정에서 언제든 변경할 수 있으며, 이 단계는 건너뛸 수 있습니다.';

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
  String get onboardingGuidelineDescription => '안전한 이용을 위해 혐오, 괴롭힘, 개인정보 노출 등의 행위를 금지합니다. 위반 시 콘텐츠가 제한될 수 있습니다.';

  @override
  String get onboardingAgreeGuidelines => '커뮤니티 가이드라인에 동의합니다.';

  @override
  String get onboardingContentPolicyTitle => '콘텐츠 정책';

  @override
  String get onboardingContentPolicyDescription => '불법, 유해, 폭력적 콘텐츠는 금지되며, 위반 콘텐츠는 검토 후 제한될 수 있습니다.';

  @override
  String get onboardingAgreeContentPolicy => '콘텐츠 정책에 동의합니다.';

  @override
  String get onboardingSafetyTitle => '신고 및 차단';

  @override
  String get onboardingSafetyDescription => '불쾌하거나 부적절한 콘텐츠를 신고하거나, 특정 사용자를 차단하여 메시지를 받지 않을 수 있습니다.';

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
  String get profileEditCta => '프로필 편집';

  @override
  String get profileLoginProviderGoogle => '구글 로그인';

  @override
  String get profileLoginProviderApple => '애플 로그인';

  @override
  String get profileLoginProviderEmail => '이메일 로그인';

  @override
  String get profileLoginProviderUnknown => '로그인됨';

  @override
  String get profileAppSettings => '앱 설정';

  @override
  String get profileMenuNotices => '공지사항';

  @override
  String get profileMenuSupport => '지원하기';

  @override
  String get profileMenuAppInfo => '앱 정보';

  @override
  String get profileMenuTitle => '메뉴';

  @override
  String get profileMenuSubtitle => '자주 쓰는 설정을 모아뒀어요.';

  @override
  String get profileWithdrawCta => '탈퇴하기';

  @override
  String get profileWithdrawTitle => '탈퇴하기';

  @override
  String get profileWithdrawMessage => '정말 탈퇴하시겠어요? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get profileWithdrawConfirm => '탈퇴';

  @override
  String get profileFeaturePreparingTitle => '준비 중';

  @override
  String get profileFeaturePreparingBody => '아직 준비되지 않은 기능입니다.';

  @override
  String get profileAvatarSemantics => '프로필 아바타';

  @override
  String get supportTitle => '지원하기';

  @override
  String get supportStatusMessage => '설치 된 앱은 최신버전입니다.';

  @override
  String get supportReleaseNotesTitle => '업데이트 내용';

  @override
  String supportReleaseNotesHeader(Object version) {
    return '최신버전 $version 버전 업데이트 내용';
  }

  @override
  String get supportReleaseNotesBody => '• 릴레이 경험과 안정성이 개선되었습니다.\n• 프로필/지원하기 화면의 다크 테마가 개선되었습니다.\n• 경미한 버그와 성능 문제를 수정했습니다.';

  @override
  String get supportVersionUnknown => '알 수 없음';

  @override
  String get supportSuggestCta => '건의사항 요구';

  @override
  String get supportReportCta => '오류사항 제보';

  @override
  String get supportFaqTitle => '자주 묻는 질문';

  @override
  String get supportFaqSubtitle => '많이 묻는 질문을 확인하세요.';

  @override
  String get supportFaqQ1 => '메시지가 전달되지 않는 것 같아요. 왜 그런가요?';

  @override
  String get supportFaqA1 => '네트워크 상태, 일시적인 서버 지연, 또는 안전 정책(신고/차단 등) 때문에 전달이 지연되거나 제한될 수 있어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get supportFaqQ2 => '알림이 안 와요. 어떻게 해야 하나요?';

  @override
  String get supportFaqA2 => '휴대폰 설정에서 Echowander 알림 권한이 꺼져 있을 수 있어요. 앱 설정 → 앱 설정(알림 설정) 으로 들어가서 알림 권한을 켜고, 배터리 절전/백그라운드 제한도 함께 확인해 주세요.';

  @override
  String get supportFaqQ3 => '불쾌한 메시지를 받았어요. 차단/신고는 어떻게 하나요?';

  @override
  String get supportFaqA3 => '메시지 화면에서 신고 또는 차단을 선택할 수 있어요. 차단하면 해당 사용자로부터 더 이상 메시지를 받지 않아요. 신고된 내용은 커뮤니티 안전을 위해 검토될 수 있어요.';

  @override
  String get supportFaqQ4 => '내가 보낸 메시지를 수정하거나 취소할 수 있나요?';

  @override
  String get supportFaqA4 => '한 번 전송된 메시지는 수정/취소가 어려워요. 전송 전에 내용을 다시 확인해 주세요.';

  @override
  String get supportFaqQ5 => '커뮤니티 가이드라인을 위반하면 어떻게 되나요?';

  @override
  String get supportFaqA5 => '반복 위반 시 메시지 기능이 제한되거나 계정 이용이 제한될 수 있어요. 안전한 커뮤니티를 위해 가이드라인을 지켜 주세요.';

  @override
  String get supportActionPreparingTitle => '준비 중';

  @override
  String get supportActionPreparingBody => '곧 이용할 수 있습니다.';

  @override
  String get supportSuggestionSubject => '건의사항 요청드립니다.';

  @override
  String get supportBugSubject => '오류사항 제보합니다.';

  @override
  String supportEmailFooterUser(String userId) {
    return '사용자 : $userId';
  }

  @override
  String supportEmailFooterVersion(String version) {
    return '앱 버전 : $version';
  }

  @override
  String get supportEmailLaunchFailed => '메일 앱을 열 수 없어요. 잠시 후 다시 시도해주세요.';

  @override
  String get appInfoTitle => '앱 정보';

  @override
  String get appInfoSettingsTitle => '앱 설정';

  @override
  String get appInfoSettingsSubtitle => '라이선스와 정책을 확인하세요.';

  @override
  String get appInfoSectionTitle => '연결된 서비스';

  @override
  String get appInfoSectionSubtitle => '서비스와 연동된 앱을 확인하세요.';

  @override
  String appInfoVersionLabel(Object version) {
    return '버전 $version';
  }

  @override
  String get appInfoVersionUnknown => '알 수 없음';

  @override
  String get appInfoOpenLicenseTitle => '오픈 라이센스';

  @override
  String get appInfoRelatedAppsTitle => 'BIZPECT 관련 앱';

  @override
  String get appInfoRelatedApp1Title => '테스트 앱 1';

  @override
  String get appInfoRelatedApp1Description => '관련 서비스 테스트용 샘플 앱입니다.';

  @override
  String get appInfoRelatedApp2Title => '테스트 앱 2';

  @override
  String get appInfoRelatedApp2Description => '연동 테스트를 위한 샘플 앱입니다.';

  @override
  String get appInfoExternalLinkLabel => '외부 링크 열기';

  @override
  String get appInfoLinkPreparingTitle => '준비 중';

  @override
  String get appInfoLinkPreparingBody => '곧 이용할 수 있습니다.';

  @override
  String get openLicenseTitle => '오픈 라이센스';

  @override
  String get openLicenseHeaderTitle => '오픈 소스 라이브러리';

  @override
  String get openLicenseHeaderBody => '이 앱은 다음 오픈 소스 라이브러리를 사용합니다.';

  @override
  String get openLicenseSectionTitle => '라이선스 목록';

  @override
  String get openLicenseSectionSubtitle => '사용 중인 오픈소스를 확인하세요.';

  @override
  String openLicenseChipVersion(Object version) {
    return '버전: $version';
  }

  @override
  String openLicenseChipLicense(Object license) {
    return '라이센스: $license';
  }

  @override
  String get openLicenseChipDetails => '세부정보';

  @override
  String get openLicenseTypeMit => 'MIT';

  @override
  String get openLicenseTypeApache => 'Apache 2.0';

  @override
  String get openLicenseTypeBsd3 => 'BSD 3-Clause';

  @override
  String get openLicenseTypeBsd2 => 'BSD 2-Clause';

  @override
  String get openLicenseTypeMpl2 => 'MPL 2.0';

  @override
  String get openLicenseTypeGpl => 'GPL';

  @override
  String get openLicenseTypeLgpl => 'LGPL';

  @override
  String get openLicenseTypeIsc => 'ISC';

  @override
  String get openLicenseTypeUnknown => '알 수 없음';

  @override
  String get openLicenseUnknown => '알 수 없음';

  @override
  String get openLicenseEmptyMessage => '라이센스 정보를 찾을 수 없습니다.';

  @override
  String openLicenseDetailTitle(Object package) {
    return '$package 라이센스';
  }

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

  @override
  String get errorAuthRefreshFailed => '네트워크가 불안정합니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get homeInboxSummaryTitle => '오늘의 인박스';

  @override
  String get homeInboxSummaryPending => '응답 전';

  @override
  String get homeInboxSummaryCompleted => '응답 완료';

  @override
  String get homeInboxSummarySentResponses => '보낸 응답';

  @override
  String homeInboxSummaryUpdatedAt(Object time) {
    return '업데이트 $time';
  }

  @override
  String get homeInboxSummaryRefresh => '새로고침';

  @override
  String get homeInboxSummaryLoadFailed => '요약을 불러올 수 없어요.';

  @override
  String homeInboxSummaryItemSemantics(Object label, Object count) {
    return '$label $count개';
  }

  @override
  String get homeTimelineTitle => '최근 활동';

  @override
  String get homeTimelineEmptyTitle => '최근 활동이 아직 없어요';

  @override
  String get homeTimelineReceivedTitle => '새 메시지 도착';

  @override
  String get homeTimelineRespondedTitle => '답장 보냄';

  @override
  String get homeTimelineSentResponseTitle => '응답 도착';

  @override
  String homeTimelineSubtitle(Object time) {
    return '$time';
  }

  @override
  String get homeDailyPromptTitle => '오늘의 질문';

  @override
  String get homeDailyPromptHint => '탭해서 메시지 작성';

  @override
  String get homeDailyPromptAction => '작성하기';

  @override
  String get homeAnnouncementTitle => '업데이트';

  @override
  String get homeAnnouncementSummary => '새로운 소식을 확인해 보세요.';

  @override
  String get homeAnnouncementAction => '자세히';

  @override
  String get homeAnnouncementDetailTitle => '업데이트';

  @override
  String get homeAnnouncementDetailBody => '더 부드러운 사용 경험을 위해 개선했어요.';

  @override
  String get homePromptQ1 => '오늘 웃게 만든 순간은 무엇이었나요?';

  @override
  String get homePromptQ2 => '이번 주에 기대하는 일은 무엇인가요?';

  @override
  String get homePromptQ3 => '다시 가보고 싶은 장소는 어디인가요?';

  @override
  String get homePromptQ4 => '오늘의 작은 성취를 알려주세요.';

  @override
  String get homePromptQ5 => '만들고 싶은 습관이 있나요?';

  @override
  String get homePromptQ6 => '오늘 고마움을 전하고 싶은 사람은 누구인가요?';

  @override
  String get homePromptQ7 => '요즘 반복해서 듣는 노래는 무엇인가요?';

  @override
  String get homePromptQ8 => '오늘을 세 단어로 표현해 주세요.';

  @override
  String get homePromptQ9 => '최근에 배운 것이 있나요?';

  @override
  String get homePromptQ10 => '나에게 한 줄 메시지를 보낸다면 무엇인가요?';
}
