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
  String get loginKakao => '使用 Kakao 继续';

  @override
  String get loginGoogle => '使用 Google 继续';

  @override
  String get loginApple => '使用 Apple 继续';

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
  String get composePermissionTitle => '允许照片权限';

  @override
  String get composePermissionMessage => '请在设置中允许照片访问。';

  @override
  String get composeOpenSettings => '打开设置';

  @override
  String get journeyListTitle => '已发送消息';

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
  String get journeyStatusUnknown => '未知';

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
  String get inboxEmpty => '还没有收到消息。';

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
  String get inboxRespondLabel => '回复';

  @override
  String get inboxRespondHint => '写下你的回复...';

  @override
  String get inboxRespondCta => '发送回复';

  @override
  String get inboxRespondEmpty => '请输入回复。';

  @override
  String get inboxRespondSuccessTitle => '回复已发送';

  @override
  String get inboxRespondSuccessBody => '你的回复已发送。';

  @override
  String get inboxPassCta => '跳过';

  @override
  String get inboxPassSuccessTitle => '已跳过';

  @override
  String get inboxPassSuccessBody => '你已跳过这条消息。';

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
  String get inboxActionFailed => '无法完成此操作。';

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
  String get journeyDetailResultsTitle => '结果';

  @override
  String get journeyDetailResultsLocked => '完成后会显示结果。';

  @override
  String get journeyDetailResultsEmpty => '暂无回复。';

  @override
  String get journeyDetailResultsLoadFailed => '无法加载结果。';

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
  String get onboardingTitle => '新手引导';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return '第 $current/$total 步';
  }

  @override
  String get onboardingNotificationTitle => '通知权限';

  @override
  String get onboardingNotificationDescription => '接收结果和重要通知。';

  @override
  String get onboardingNotificationNote => '不会发送推广通知，可在设置中更改。';

  @override
  String get onboardingAllowNotifications => '允许通知';

  @override
  String get onboardingPhotoTitle => '照片访问';

  @override
  String get onboardingPhotoDescription => '用于给消息添加图片。';

  @override
  String get onboardingPhotoNote => '最多可添加 3 张，仅访问已选择的照片。';

  @override
  String get onboardingAllowPhotos => '允许访问照片';

  @override
  String get onboardingGuidelineTitle => '社区规范';

  @override
  String get onboardingGuidelineDescription => '禁止骚扰、仇恨或泄露个人信息。';

  @override
  String get onboardingAgreeGuidelines => '我同意社区规范。';

  @override
  String get onboardingContentPolicyTitle => '内容政策';

  @override
  String get onboardingContentPolicyDescription => '违规或有害内容可能被移除。';

  @override
  String get onboardingAgreeContentPolicy => '我同意内容政策。';

  @override
  String get onboardingSafetyTitle => '举报与屏蔽';

  @override
  String get onboardingSafetyDescription => '可随时举报或屏蔽。';

  @override
  String get onboardingConfirmSafety => '我已了解举报与屏蔽政策。';

  @override
  String get onboardingSkip => '稍后';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingStart => '开始';

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
  String get tabInboxLabel => '收件箱';

  @override
  String get tabCreateLabel => '创建消息';

  @override
  String get tabAlertsLabel => '通知';

  @override
  String get tabProfileLabel => '个人资料';

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
}
