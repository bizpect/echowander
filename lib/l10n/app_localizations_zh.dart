// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'EchoWander';

  @override
  String get splashTitle => '启动中...';

  @override
  String get loginTitle => '登录';

  @override
  String get loginDescription => '开始您的匿名接力消息';

  @override
  String get loginKakao => '使用 Kakao 继续';

  @override
  String get loginGoogle => '使用 Google 继续';

  @override
  String get loginApple => '使用 Apple 继续';

  @override
  String get loginTerms => '登录即表示您同意我们的服务条款和隐私政策';

  @override
  String get homeTitle => '首页';

  @override
  String get homeGreeting => '欢迎回来';

  @override
  String get homeRecentJourneysTitle => '最近消息';

  @override
  String get homeActionsTitle => '开始使用';

  @override
  String get homeEmptyTitle => '欢迎来到 EchoWander';

  @override
  String get homeEmptyDescription => '发送您的第一条接力消息或查看收件箱。';

  @override
  String get homeInboxCardTitle => '收件箱';

  @override
  String get homeInboxCardDescription => '查看并回复您收到的消息。';

  @override
  String get homeCreateCardTitle => '创建消息';

  @override
  String get homeCreateCardDescription => '开始新的接力消息。';

  @override
  String get homeJourneyCardViewDetails => '查看详情';

  @override
  String get homeRefresh => '刷新';

  @override
  String get homeExitTitle => '要退出应用吗？';

  @override
  String get homeExitMessage => '应用将被关闭。';

  @override
  String get homeExitCancel => '取消';

  @override
  String get homeExitConfirm => '退出';

  @override
  String get homeExitAdLoading => '正在加载广告...';

  @override
  String get homeLoadFailed => '无法加载您的数据。';

  @override
  String homeInboxCount(Object count) {
    return '$count条新消息';
  }

  @override
  String get settingsCta => '设置';

  @override
  String get settingsNotificationInbox => '通知列表';

  @override
  String get pushPreviewTitle => '通知';

  @override
  String get pushPreviewDescription => '这是推送深度链接的测试页面。';

  @override
  String get notificationTitle => '新消息';

  @override
  String get notificationOpen => '打开';

  @override
  String get notificationDismiss => '关闭';

  @override
  String get notificationsTitle => '通知';

  @override
  String notificationsUnreadCountLabel(Object count) {
    return '未读通知 $count 条';
  }

  @override
  String get notificationsUnreadCountOverflow => '9+';

  @override
  String get notificationsEmpty => '暂无通知。';

  @override
  String get notificationsUnreadOnly => '仅显示未读';

  @override
  String get notificationsRead => '已读';

  @override
  String get notificationsUnread => '新通知';

  @override
  String get notificationsDeleteTitle => '删除通知';

  @override
  String get notificationsDeleteMessage => '要删除这条通知吗？';

  @override
  String get notificationsDeleteConfirm => '删除';

  @override
  String get pushJourneyAssignedTitle => '新消息';

  @override
  String get pushJourneyAssignedBody => '新的转发消息已到达。';

  @override
  String get pushJourneyResultTitle => '结果已到达';

  @override
  String get pushJourneyResultBody => '请查看你的转发结果。';

  @override
  String get errorTitle => '提示';

  @override
  String get errorGeneric => '发生问题，请重试。';

  @override
  String get errorLoginFailed => '登录失败，请重试。';

  @override
  String get errorLoginCancelled => '登录已取消。';

  @override
  String get errorLoginNetwork => '请检查网络连接后再试。';

  @override
  String get errorLoginInvalidToken => '登录验证失败，请重试。';

  @override
  String get errorLoginUnsupportedProvider => '不支持此登录方式。';

  @override
  String get errorLoginUserSyncFailed => '无法保存账号信息，请重试。';

  @override
  String get errorLoginServiceUnavailable => '登录服务暂时不可用，请稍后再试。';

  @override
  String get errorSessionExpired => '会话已过期，请重新登录。';

  @override
  String get errorForbiddenTitle => 'Permission Required';

  @override
  String get errorForbiddenMessage => 'You don\'t have permission to perform this action. Please check your login status or try again later.';

  @override
  String get journeyInboxForbiddenTitle => 'Cannot Load Inbox';

  @override
  String get journeyInboxForbiddenMessage => 'You don\'t have permission to view the inbox. If the problem persists, please sign in again.';

  @override
  String get languageSectionTitle => '语言';

  @override
  String get languageSystem => '系统默认';

  @override
  String get languageKorean => '韩语';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageJapanese => '日语';

  @override
  String get languageSpanish => '西班牙语';

  @override
  String get languageFrench => '法语';

  @override
  String get languagePortuguese => '葡萄牙语';

  @override
  String get languageChinese => '中文';

  @override
  String get composeTitle => '撰写消息';

  @override
  String get composeWizardStep1Title => '想用什么内容发送旅程？';

  @override
  String get composeWizardStep1Subtitle => '写一句话开启接力。';

  @override
  String get composeWizardStep2Title => '要落到多少人手里？';

  @override
  String get composeWizardStep2Subtitle => '可选择 10～50 人。';

  @override
  String get composeWizardStep3Title => '要一起发送照片吗？';

  @override
  String get composeWizardStep3Subtitle => '最多 3 张，不加也可以发送。';

  @override
  String get composeWizardBack => '返回';

  @override
  String get composeWizardNext => '下一步';

  @override
  String get composeLabel => '消息';

  @override
  String get composeHint => '分享你的想法...';

  @override
  String composeCharacterCount(Object current, Object total) {
    return '$current/$total';
  }

  @override
  String get composeImagesTitle => '图片';

  @override
  String get composeImageHelper => '最多可附加3张照片。';

  @override
  String get composeImageUploadHint => '请上传图片。';

  @override
  String get composeImageDelete => '删除图片';

  @override
  String get composeSelectedImagesTitle => '已选择的图片';

  @override
  String get composeAddImage => '添加照片';

  @override
  String get composeSubmit => '发送';

  @override
  String get composeCta => '撰写消息';

  @override
  String get composeTooLong => '消息太长了。';

  @override
  String get composeForbidden => '请移除 URL 或联系方式。';

  @override
  String get composeEmpty => '请输入消息。';

  @override
  String get composeInvalid => '请检查消息内容。';

  @override
  String get composeImageLimit => '最多可添加 3 张图片。';

  @override
  String get composeImageReadFailed => '无法读取图片。请重试。';

  @override
  String get composeImageOptimizationFailed => '图片处理失败。请重试。';

  @override
  String get composePermissionDenied => '需要照片权限才能添加图片。';

  @override
  String get composeSessionMissing => '请重新登录。';

  @override
  String get composeSubmitFailed => '发送失败，请重试。';

  @override
  String get composeServerMisconfigured => '服务尚未配置完成，请稍后再试。';

  @override
  String get composeSubmitSuccess => '消息已发送。';

  @override
  String get composeSendRequestAccepted => '发送请求已接受。';

  @override
  String get composeRecipientCountLabel => '接收人数';

  @override
  String get composeRecipientCountHint => '请选择 1 到 5 人。';

  @override
  String composeRecipientCountOption(Object count) {
    return '$count 人';
  }

  @override
  String get composeRecipientRequired => '请选择接收人数。';

  @override
  String get composeRecipientInvalid => '只能选择 1 到 5 人。';

  @override
  String get composeErrorTitle => '提示';

  @override
  String get composeSuccessTitle => '完成';

  @override
  String get composeOk => '确定';

  @override
  String get composeCancel => '取消';

  @override
  String get sessionExpiredTitle => '会话已过期';

  @override
  String get sessionExpiredBody => '您的会话已过期，请重新登录。';

  @override
  String get sessionExpiredCtaLogin => '登录';

  @override
  String get sendFailedTitle => '发送失败';

  @override
  String get sendFailedTryAgain => '消息发送失败，请重试。';

  @override
  String get moderationContentBlockedMessage => '消息内容不当。';

  @override
  String get moderationBlockedTitle => '无法发送';

  @override
  String get nicknameForbiddenMessage => '昵称包含禁用词。';

  @override
  String get nicknameTakenMessage => '该昵称已被使用。';

  @override
  String get composeContentBlocked => '包含无法发送的内容。';

  @override
  String get composeContentBlockedProfanity => '包含不当用语。';

  @override
  String get composeContentBlockedSexual => '禁止包含性内容。';

  @override
  String get composeContentBlockedHate => '禁止仇恨言论。';

  @override
  String get composeContentBlockedThreat => '禁止威胁性内容。';

  @override
  String get replyContentBlocked => '包含无法发送的内容。';

  @override
  String get replyContentBlockedProfanity => '包含不当用语。';

  @override
  String get replyContentBlockedSexual => '禁止包含性内容。';

  @override
  String get replyContentBlockedHate => '禁止仇恨言论。';

  @override
  String get replyContentBlockedThreat => '禁止威胁性内容。';

  @override
  String get composePermissionTitle => '允许照片权限';

  @override
  String get composePermissionMessage => '请在设置中允许照片访问。';

  @override
  String get composeOpenSettings => '打开设置';

  @override
  String get commonClose => '关闭';

  @override
  String get journeyListTitle => '已发送消息';

  @override
  String get sentTabInProgress => '进行中';

  @override
  String get sentTabCompleted => '已完成';

  @override
  String inboxSentOngoingForwardedCountLabel(Object count) {
    return '已发送给 $count 人';
  }

  @override
  String inboxSentOngoingRespondedCountLabel(Object count) {
    return '$count 人已回复';
  }

  @override
  String get sentEmptyInProgressTitle => '暂无进行中的消息';

  @override
  String get sentEmptyInProgressDescription => '开始新的接力消息后会显示在这里。';

  @override
  String get sentEmptyCompletedTitle => '暂无已完成的消息';

  @override
  String get sentEmptyCompletedDescription => '已完成的接力会显示在这里。';

  @override
  String get journeyListEmpty => '还没有发送过消息。';

  @override
  String get journeyListCta => '查看已发送消息';

  @override
  String get journeyListStatusLabel => '状态：';

  @override
  String get journeyStatusCreated => '已发送';

  @override
  String get journeyStatusWaiting => '等待匹配';

  @override
  String get journeyStatusCompleted => '已完成';

  @override
  String get journeyStatusInProgress => '进行中';

  @override
  String get journeyStatusUnknown => '未知';

  @override
  String get journeyInProgressHint => '完成后可在详情中查看回复';

  @override
  String get journeyFilterOk => '允许';

  @override
  String get journeyFilterHeld => '审核中';

  @override
  String get journeyFilterRemoved => '已移除';

  @override
  String get journeyFilterUnknown => '未知';

  @override
  String get inboxTitle => '收件箱';

  @override
  String get inboxTabPending => '待回复';

  @override
  String get inboxTabCompleted => '已回复';

  @override
  String get inboxEmpty => '还没有收到消息。';

  @override
  String get inboxEmptyPendingTitle => '暂无待回复消息';

  @override
  String get inboxEmptyPendingDescription => '新的消息会显示在这里。';

  @override
  String get inboxEmptyCompletedTitle => '暂无已回复消息';

  @override
  String get inboxEmptyCompletedDescription => '你已回复的消息会显示在这里。';

  @override
  String get inboxCta => '查看收件箱';

  @override
  String get inboxRefresh => '刷新';

  @override
  String get inboxLoadFailed => '无法加载您的收件箱。';

  @override
  String inboxImageCount(Object count) {
    return '$count张照片';
  }

  @override
  String get inboxStatusLabel => '状态：';

  @override
  String get inboxStatusAssigned => '等待中';

  @override
  String get inboxStatusResponded => '已回复';

  @override
  String get inboxStatusPassed => '已跳过';

  @override
  String get inboxStatusReported => '已举报';

  @override
  String get inboxStatusUnknown => '未知';

  @override
  String get inboxCardArrivedPrompt => '消息已到达！\n请留下回复。';

  @override
  String get inboxDetailTitle => '收到的消息';

  @override
  String get inboxDetailMissing => '无法加载该消息。';

  @override
  String get inboxImagesLabel => '照片';

  @override
  String get inboxImagesLoadFailed => '无法加载照片。';

  @override
  String get inboxBlockCta => '屏蔽发送者';

  @override
  String get inboxBlockTitle => '屏蔽用户';

  @override
  String get inboxBlockMessage => '要屏蔽该用户的后续消息吗？';

  @override
  String get inboxBlockConfirm => '屏蔽';

  @override
  String get inboxBlockSuccessTitle => '已屏蔽';

  @override
  String get inboxBlockSuccessBody => '已屏蔽该用户。';

  @override
  String get inboxBlockFailed => '无法屏蔽该用户。';

  @override
  String get inboxBlockMissing => '无法识别发送者。';

  @override
  String get inboxRespondLabel => '消息';

  @override
  String get inboxRespondHint => '写下你的消息...';

  @override
  String get inboxRespondCta => '发送消息';

  @override
  String get inboxRespondEmpty => '请输入消息。';

  @override
  String get inboxRespondConfirmTitle => '发送消息';

  @override
  String get inboxRespondConfirmMessage => '确定要发送此消息吗?';

  @override
  String get inboxRespondSuccessTitle => '消息已发送';

  @override
  String get inboxRespondSuccessBody => '你的消息已发送。';

  @override
  String get inboxPassCta => '跳过';

  @override
  String get inboxPassConfirmTitle => '确认跳过';

  @override
  String get inboxPassConfirmMessage => '您确定要跳过这条消息吗?';

  @override
  String get inboxPassConfirmAction => '跳过';

  @override
  String get inboxPassSuccessTitle => '已跳过';

  @override
  String get inboxPassSuccessBody => '你已跳过这条消息。';

  @override
  String get inboxPassedTitle => '已跳过的消息';

  @override
  String get inboxPassedDetailUnavailable => '此消息已跳过，内容不可查看。';

  @override
  String get inboxPassedMessageTitle => '此消息已被跳过。';

  @override
  String get inboxRespondedMessageTitle => '您已回复此消息。';

  @override
  String get inboxRespondedDetailSectionTitle => '我的回复';

  @override
  String get inboxRespondedDetailReplyUnavailable => '无法加载您的回复。';

  @override
  String get inboxReportCta => '举报';

  @override
  String get inboxReportTitle => '举报原因';

  @override
  String get inboxReportSpam => '垃圾信息';

  @override
  String get inboxReportAbuse => '不当内容';

  @override
  String get inboxReportOther => '其他';

  @override
  String get inboxReportSuccessTitle => '已举报';

  @override
  String get inboxReportSuccessBody => '你的举报已提交。';

  @override
  String get inboxReportAlreadyReportedTitle => '已举报';

  @override
  String get inboxReportAlreadyReportedBody => '你已经举报过这条消息了。';

  @override
  String get inboxActionFailed => '无法完成此操作。';

  @override
  String get actionReportMessage => '举报消息';

  @override
  String get actionBlockSender => '屏蔽发送者';

  @override
  String get inboxDetailMoreTitle => '选项';

  @override
  String get journeyDetailTitle => '消息';

  @override
  String get journeyDetailMessageLabel => '消息';

  @override
  String get journeyDetailMessageUnavailable => '无法加载消息。';

  @override
  String get journeyDetailProgressTitle => '转发进度';

  @override
  String get journeyDetailStatusLabel => '状态';

  @override
  String get journeyDetailDeadlineLabel => '转发截止';

  @override
  String get journeyDetailResponseTargetLabel => '目标回复数';

  @override
  String get journeyDetailRespondedLabel => '回复';

  @override
  String get journeyDetailAssignedLabel => '已分配';

  @override
  String get journeyDetailPassedLabel => '已跳过';

  @override
  String get journeyDetailReportedLabel => '已举报';

  @override
  String get journeyDetailCountriesLabel => '转发地区';

  @override
  String get journeyDetailCountriesEmpty => '暂无地区信息。';

  @override
  String get journeyDetailResultsTitle => '回复';

  @override
  String get journeyDetailResultsLocked => '完成后可查看回复。';

  @override
  String get journeyDetailResultsEmpty => '暂时没有回复。';

  @override
  String get journeyDetailResultsLoadFailed => '无法加载回复。';

  @override
  String get commonTemporaryErrorTitle => '临时错误';

  @override
  String get sentDetailRepliesLoadFailedMessage => '无法加载回复。\n将返回列表。';

  @override
  String get commonOk => '确定';

  @override
  String get journeyDetailResponsesMissingTitle => '临时错误';

  @override
  String get journeyDetailResponsesMissingBody => '无法加载回复。请重试。\n将返回列表。';

  @override
  String get journeyDetailGateConfigTitle => '广告未就绪';

  @override
  String get journeyDetailGateConfigBody => '广告设置尚未完成，将直接进入详情。';

  @override
  String get journeyDetailGateDismissedTitle => '广告未看完';

  @override
  String get journeyDetailGateDismissedBody => '观看完广告后才能查看详情。';

  @override
  String get journeyDetailGateFailedTitle => '广告不可用';

  @override
  String get journeyDetailGateFailedBody => '广告加载失败，请重试。';

  @override
  String get journeyDetailUnlockFailedTitle => '解锁保存失败';

  @override
  String get journeyDetailUnlockFailedBody => '由于网络或服务器问题，解锁保存失败。请重试。';

  @override
  String get journeyDetailGateDialogTitle => '观看广告解锁';

  @override
  String get journeyDetailGateDialogBody => '观看激励广告即可解锁。\n仅需一次即可永久解锁。';

  @override
  String get journeyDetailGateDialogConfirm => '解锁';

  @override
  String get journeyDetailLoadFailed => '无法加载进度。';

  @override
  String get journeyDetailRetry => '重试';

  @override
  String get journeyDetailAdRequired => '观看广告后查看结果。';

  @override
  String get journeyDetailAdCta => '观看广告并解锁';

  @override
  String get journeyDetailAdFailedTitle => '广告不可用';

  @override
  String get journeyDetailAdFailedBody => '无法加载广告。仍要查看结果吗？';

  @override
  String get journeyDetailAdFailedConfirm => '查看结果';

  @override
  String get journeyResultReportCta => '举报回复';

  @override
  String get journeyResultReportSuccessTitle => '已举报';

  @override
  String get journeyResultReportSuccessBody => '你的举报已提交。';

  @override
  String get journeyResultReportFailed => '无法提交举报。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionNotification => '通知';

  @override
  String get settingsNotificationToggle => '允许通知';

  @override
  String get settingsNotificationHint => '接收进度与结果提醒。';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsTheme => '主题';

  @override
  String get themeSystem => '系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsSectionSafety => '安全';

  @override
  String get settingsBlockedUsers => '已屏蔽用户';

  @override
  String get settingsLoadFailed => '无法加载设置。';

  @override
  String get settingsUpdateFailed => '无法更新设置。';

  @override
  String get blockListTitle => '已屏蔽用户';

  @override
  String get blockListEmpty => '暂无屏蔽用户。';

  @override
  String get blockListUnknownUser => '未知用户';

  @override
  String get blockListLoadFailed => '无法加载屏蔽列表。';

  @override
  String get blockListUnblock => '解除屏蔽';

  @override
  String get blockListUnblockTitle => '解除屏蔽';

  @override
  String get blockListUnblockMessage => '允许再次收到该用户消息？';

  @override
  String get blockListUnblockConfirm => '解除';

  @override
  String get blockListUnblockFailed => '无法解除屏蔽。';

  @override
  String get blockUnblockedTitle => '完成';

  @override
  String get blockUnblockedMessage => '已解除屏蔽。';

  @override
  String get onboardingTitle => '新手引导';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return '第 $current/$total 步';
  }

  @override
  String get onboardingNotificationTitle => '通知权限';

  @override
  String get onboardingNotificationDescription => '当接力消息到达和结果准备好时,我们会通知您。';

  @override
  String get onboardingNotificationNote => '您可以随时在设置中更改。此步骤为可选。';

  @override
  String get onboardingAllowNotifications => '允许';

  @override
  String get onboardingPhotoTitle => '照片访问';

  @override
  String get onboardingPhotoDescription => '仅用于设置个人资料图片和向消息附加图片。';

  @override
  String get onboardingPhotoNote => '我们仅访问您选择的照片。此步骤为可选。';

  @override
  String get onboardingAllowPhotos => '允许';

  @override
  String get onboardingGuidelineTitle => '社区准则';

  @override
  String get onboardingGuidelineDescription => '为了安全使用，禁止骚扰、仇恨言论和分享个人信息。违规行为可能导致内容限制。';

  @override
  String get onboardingAgreeGuidelines => '我同意社区准则。';

  @override
  String get onboardingContentPolicyTitle => '内容政策';

  @override
  String get onboardingContentPolicyDescription => '禁止非法、有害和暴力内容。违规内容经审核后可能会被限制。';

  @override
  String get onboardingAgreeContentPolicy => '我同意内容政策。';

  @override
  String get onboardingSafetyTitle => '举报与屏蔽';

  @override
  String get onboardingSafetyDescription => '您可以举报冒犯性或不当内容，或屏蔽特定用户以停止接收其消息。';

  @override
  String get onboardingConfirmSafety => '我了解举报与屏蔽政策。';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingStart => '开始';

  @override
  String get onboardingAgreeAndDisagree => '同意和不同意';

  @override
  String get onboardingPrevious => '上一步';

  @override
  String get ctaPermissionChoice => '选择权限';

  @override
  String get onboardingExitTitle => '退出新手引导？';

  @override
  String get onboardingExitMessage => '您可以稍后重新开始。';

  @override
  String get onboardingExitConfirm => '退出';

  @override
  String get onboardingExitCancel => '继续';

  @override
  String get exitConfirmTitle => '取消编辑？';

  @override
  String get exitConfirmMessage => '您的输入将丢失。';

  @override
  String get exitConfirmContinue => '继续编辑';

  @override
  String get exitConfirmLeave => '离开';

  @override
  String get tabHomeLabel => '首页';

  @override
  String get tabSentLabel => '已发送';

  @override
  String get tabInboxLabel => '收件箱';

  @override
  String get tabCreateLabel => '创建消息';

  @override
  String get tabAlertsLabel => '通知';

  @override
  String get tabProfileLabel => '个人资料';

  @override
  String get noticeTitle => '公告';

  @override
  String get noticeDetailTitle => '公告';

  @override
  String get noticeFilterLabel => '公告类型';

  @override
  String get noticeFilterAll => '全部';

  @override
  String get noticeFilterSheetTitle => '选择公告类型';

  @override
  String get noticeTypeUnknown => '未知';

  @override
  String get noticePinnedBadge => '置顶';

  @override
  String get noticeEmptyTitle => '暂无公告';

  @override
  String get noticeEmptyDescription => '该类型暂无公告。';

  @override
  String get noticeErrorTitle => '无法加载公告';

  @override
  String get noticeErrorDescription => '请稍后再试。';

  @override
  String get profileSignOutCta => '退出登录';

  @override
  String get profileSignOutTitle => '退出登录';

  @override
  String get profileSignOutMessage => '确定要退出登录吗？';

  @override
  String get profileSignOutConfirm => '退出登录';

  @override
  String get profileUserIdLabel => '用户 ID';

  @override
  String get profileDefaultNickname => '用户';

  @override
  String get profileEditCta => '编辑资料';

  @override
  String get authProviderKakaoLogin => 'Kakao 登录';

  @override
  String get authProviderGoogleLogin => 'Google 登录';

  @override
  String get authProviderAppleLogin => 'Apple 登录';

  @override
  String get authProviderUnknownLogin => '已登录';

  @override
  String get profileLoginProviderKakao => 'Kakao 登录';

  @override
  String get profileLoginProviderGoogle => 'Google 登录';

  @override
  String get profileLoginProviderApple => 'Apple 登录';

  @override
  String get profileLoginProviderEmail => '邮箱登录';

  @override
  String get profileLoginProviderUnknown => '已登录';

  @override
  String get profileAppSettings => '应用设置';

  @override
  String get profileMenuNotices => '公告';

  @override
  String get profileMenuSupport => '支持';

  @override
  String get profileMenuAppInfo => '应用信息';

  @override
  String get profileMenuTitle => '菜单';

  @override
  String get profileMenuSubtitle => '常用设置快速入口。';

  @override
  String get profileWithdrawCta => '注销账号';

  @override
  String get profileWithdrawTitle => '注销账号';

  @override
  String get profileWithdrawMessage => '确定要注销账号吗？此操作无法撤销。';

  @override
  String get profileWithdrawConfirm => '注销';

  @override
  String get profileFeaturePreparingTitle => '即将推出';

  @override
  String get profileFeaturePreparingBody => '该功能尚未开放。';

  @override
  String get profileAvatarSemantics => '个人头像';

  @override
  String get supportTitle => '支持';

  @override
  String get supportStatusMessage => '已安装的应用是最新版本。';

  @override
  String get supportReleaseNotesTitle => '更新内容';

  @override
  String supportReleaseNotesHeader(Object version) {
    return '最新版本 $version 更新内容';
  }

  @override
  String get supportReleaseNotesBody => '• 改进了转发体验与稳定性。\n• 优化了个人资料/支持页面的深色主题。\n• 修复了部分小问题并提升性能。';

  @override
  String get supportVersionUnknown => '未知';

  @override
  String get supportSuggestCta => '提交建议';

  @override
  String get supportReportCta => '反馈问题';

  @override
  String get supportFaqTitle => '常见问题';

  @override
  String get supportFaqSubtitle => '查看常见问题解答。';

  @override
  String get supportFaqQ1 => '消息似乎没有送达。为什么？';

  @override
  String get supportFaqA1 => '由于网络状态、临时服务器延迟或安全策略（举报/屏蔽等），消息可能会延迟或受限。请稍后再试。';

  @override
  String get supportFaqQ2 => '我没有收到通知。该怎么办？';

  @override
  String get supportFaqA2 => '手机设置中可能关闭了Echowander的通知权限。请前往应用设置 → 应用设置（通知设置）开启通知权限，并检查省电/后台限制设置。';

  @override
  String get supportFaqQ3 => '我收到了不愉快的消息。如何屏蔽/举报？';

  @override
  String get supportFaqA3 => '您可以在消息界面选择举报或屏蔽。屏蔽后，您将不再收到该用户的消息。举报内容可能会被审查以确保社区安全。';

  @override
  String get supportFaqQ4 => '我可以编辑或取消已发送的消息吗？';

  @override
  String get supportFaqA4 => '消息一旦发送，很难编辑或取消。请在发送前仔细检查内容。';

  @override
  String get supportFaqQ5 => '违反社区准则会怎样？';

  @override
  String get supportFaqA5 => '重复违规可能导致消息功能受限或账户使用受限。为了社区安全，请遵守准则。';

  @override
  String get supportActionPreparingTitle => '即将推出';

  @override
  String get supportActionPreparingBody => '该操作即将开放。';

  @override
  String get supportSuggestionSubject => '建议请求';

  @override
  String get supportBugSubject => '错误报告';

  @override
  String supportEmailFooterUser(String userId) {
    return '用户 : $userId';
  }

  @override
  String supportEmailFooterVersion(String version) {
    return '应用版本 : $version';
  }

  @override
  String get supportEmailLaunchFailed => '无法打开邮件应用。请稍后再试。';

  @override
  String get appInfoTitle => '应用信息';

  @override
  String get appInfoSettingsTitle => '应用设置';

  @override
  String get appInfoSettingsSubtitle => '查看许可与政策。';

  @override
  String get appInfoSectionTitle => '关联服务';

  @override
  String get appInfoSectionSubtitle => '查看与服务关联的应用。';

  @override
  String appInfoVersionLabel(Object version) {
    return '版本 $version';
  }

  @override
  String get appInfoVersionUnknown => '未知';

  @override
  String get appInfoOpenLicenseTitle => '开源许可';

  @override
  String get appInfoRelatedAppsTitle => 'BIZPECT 相关应用';

  @override
  String get appInfoRelatedApp1Title => '测试应用 1';

  @override
  String get appInfoRelatedApp1Description => '用于相关服务测试的示例应用。';

  @override
  String get appInfoRelatedApp2Title => '测试应用 2';

  @override
  String get appInfoRelatedApp2Description => '用于相关集成的示例应用。';

  @override
  String get appInfoExternalLinkLabel => '打开外部链接';

  @override
  String get appInfoLinkPreparingTitle => '即将推出';

  @override
  String get appInfoLinkPreparingBody => '该链接即将开放。';

  @override
  String get openLicenseTitle => '开源许可';

  @override
  String get openLicenseHeaderTitle => '开源库';

  @override
  String get openLicenseHeaderBody => '本应用使用了以下开源库。';

  @override
  String get openLicenseSectionTitle => '许可证列表';

  @override
  String get openLicenseSectionSubtitle => '查看正在使用的开源包。';

  @override
  String openLicenseChipVersion(Object version) {
    return '版本: $version';
  }

  @override
  String openLicenseChipLicense(Object license) {
    return '许可: $license';
  }

  @override
  String get openLicenseChipDetails => '详情';

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
  String get openLicenseTypeUnknown => '未知';

  @override
  String get openLicenseUnknown => '未知';

  @override
  String get openLicenseEmptyMessage => '未找到许可信息。';

  @override
  String openLicenseDetailTitle(Object package) {
    return '$package 许可';
  }

  @override
  String get journeyDetailAnonymous => '匿名';

  @override
  String get errorNetwork => '请检查网络连接。';

  @override
  String get errorTimeout => '请求超时。请重试。';

  @override
  String get errorServerUnavailable => '服务器暂时不可用。请稍后再试。';

  @override
  String get errorUnauthorized => '请重新登录。';

  @override
  String get errorRetry => '重试';

  @override
  String get errorCancel => '取消';

  @override
  String get errorAuthRefreshFailed => '网络不稳定。请稍后再试。';

  @override
  String get homeInboxSummaryTitle => '今日收件箱';

  @override
  String get homeInboxSummaryPending => '待回复';

  @override
  String get homeInboxSummaryCompleted => '已回复';

  @override
  String get homeInboxSummarySentResponses => '收到回复';

  @override
  String homeInboxSummaryUpdatedAt(Object time) {
    return '更新 $time';
  }

  @override
  String get homeInboxSummaryRefresh => '刷新';

  @override
  String get homeInboxSummaryLoadFailed => '无法加载摘要。';

  @override
  String homeInboxSummaryItemSemantics(Object label, Object count) {
    return '$label $count条';
  }

  @override
  String get homeTimelineTitle => '最近动态';

  @override
  String get homeTimelineEmptyTitle => '暂无最近动态';

  @override
  String get homeTimelineReceivedTitle => '收到新消息';

  @override
  String get homeTimelineRespondedTitle => '已发送回复';

  @override
  String get homeTimelineSentResponseTitle => '收到回复';

  @override
  String homeTimelineSubtitle(Object time) {
    return '$time';
  }

  @override
  String get homeDailyPromptTitle => '今日问题';

  @override
  String get homeDailyPromptHint => '点击开始写消息';

  @override
  String get homeDailyPromptAction => '去写';

  @override
  String get homeAnnouncementTitle => '更新';

  @override
  String get homeAnnouncementSummary => '查看 Echowander 的新内容。';

  @override
  String get homeAnnouncementAction => '详情';

  @override
  String get homeAnnouncementDetailTitle => '更新';

  @override
  String get homeAnnouncementDetailBody => '我们做了改进，让体验更顺畅。';

  @override
  String get homePromptQ1 => '今天有什么让你微笑？';

  @override
  String get homePromptQ2 => '这周你期待什么？';

  @override
  String get homePromptQ3 => '你想再去一次的地方是哪里？';

  @override
  String get homePromptQ4 => '分享一下今天的小成就。';

  @override
  String get homePromptQ5 => '你想养成什么习惯？';

  @override
  String get homePromptQ6 => '今天你想感谢谁？';

  @override
  String get homePromptQ7 => '最近你一直在循环的歌是什么？';

  @override
  String get homePromptQ8 => '用三个词形容你的今天。';

  @override
  String get homePromptQ9 => '你最近学到了什么？';

  @override
  String get homePromptQ10 => '如果可以给自己发一条消息，你会说什么？';

  @override
  String get profileEditTitle => '编辑个人资料';

  @override
  String get profileEditNicknameLabel => '昵称';

  @override
  String get profileEditNicknameHint => '输入昵称';

  @override
  String get profileEditNicknameEmpty => '请输入昵称';

  @override
  String profileEditNicknameTooShort(Object min) {
    return '昵称至少需要$min个字符';
  }

  @override
  String profileEditNicknameTooLong(Object max) {
    return '昵称最多可输入$max个字符';
  }

  @override
  String get profileEditNicknameConsecutiveSpaces => '不允许连续空格';

  @override
  String get profileEditNicknameInvalidCharacters => '仅允许韩语、英语、数字和下划线(_)';

  @override
  String get profileEditNicknameUnderscoreAtEnds => 'Underscore (_) cannot be used at the beginning or end';

  @override
  String get profileEditNicknameConsecutiveUnderscores => 'Consecutive underscores (__) are not allowed';

  @override
  String get profileEditNicknameForbidden => 'This nickname is not allowed';

  @override
  String get profileEditNicknameChecking => '检查中...';

  @override
  String get profileEditNicknameAvailable => '此昵称可用';

  @override
  String get profileEditNicknameTaken => '此昵称已被使用';

  @override
  String get profileEditNicknameError => '检查时发生错误';

  @override
  String get profileEditAvatarLabel => '个人资料照片';

  @override
  String get profileEditAvatarChange => '更改照片';

  @override
  String get profileEditSave => '保存';

  @override
  String get profileEditCancel => '取消';

  @override
  String get profileEditSaveSuccess => '个人资料已保存';

  @override
  String get profileEditSaveFailed => '保存失败。请重试';

  @override
  String get profileEditImageTooLarge => 'Image file is too large. Please select another image';

  @override
  String get profileEditImageOptimizationFailed => 'An error occurred while processing the image. Please try again';

  @override
  String get profileEditCropTitle => '编辑照片';

  @override
  String get profileEditCropDescription => '根据需要调整位置';

  @override
  String get profileEditCropCancel => '取消';

  @override
  String get profileEditCropComplete => '完成';

  @override
  String get profileEditCropFailedTitle => '照片编辑失败';

  @override
  String get profileEditCropFailedMessage => '编辑照片时发生错误。请重试。';

  @override
  String get profileEditCropFailedAction => '确定';
}
