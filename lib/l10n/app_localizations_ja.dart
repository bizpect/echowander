// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'EchoWander';

  @override
  String get splashTitle => '起動中...';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get loginDescription => '匿名リレーメッセージを始めましょう';

  @override
  String get loginKakao => 'Kakaoで続行';

  @override
  String get loginGoogle => 'Googleで続行';

  @override
  String get loginApple => 'Appleで続行';

  @override
  String get loginTerms => 'ログインすることで、利用規約およびプライバシーポリシーに同意したことになります';

  @override
  String get homeTitle => 'ホーム';

  @override
  String get homeGreeting => 'お帰りなさい';

  @override
  String get homeRecentJourneysTitle => '最近のメッセージ';

  @override
  String get homeActionsTitle => 'はじめる';

  @override
  String get homeEmptyTitle => 'EchoWanderへようこそ';

  @override
  String get homeEmptyDescription => '最初のリレーメッセージを作成するか、受信トレイを確認してください。';

  @override
  String get homeInboxCardTitle => '受信トレイ';

  @override
  String get homeInboxCardDescription => '受信したメッセージを確認して返信します。';

  @override
  String get homeCreateCardTitle => 'メッセージ作成';

  @override
  String get homeCreateCardDescription => '新しいリレーメッセージを開始します。';

  @override
  String get homeJourneyCardViewDetails => '詳細を見る';

  @override
  String get homeRefresh => '更新';

  @override
  String get homeExitTitle => 'アプリを終了しますか？';

  @override
  String get homeExitMessage => 'アプリを終了します。';

  @override
  String get homeExitCancel => 'キャンセル';

  @override
  String get homeExitConfirm => '終了';

  @override
  String get homeExitAdLoading => '広告を読み込み中…';

  @override
  String get homeLoadFailed => 'データを読み込めませんでした。';

  @override
  String homeInboxCount(Object count) {
    return '$count件の新着';
  }

  @override
  String get settingsCta => '設定';

  @override
  String get settingsNotificationInbox => '通知一覧';

  @override
  String get pushPreviewTitle => '通知';

  @override
  String get pushPreviewDescription => 'プッシュディープリンクのテスト画面です。';

  @override
  String get notificationTitle => '新しい通知';

  @override
  String get notificationOpen => '開く';

  @override
  String get notificationDismiss => '閉じる';

  @override
  String get notificationsTitle => '通知';

  @override
  String notificationsUnreadCountLabel(Object count) {
    return '未読の通知 $count件';
  }

  @override
  String get notificationsUnreadCountOverflow => '9+';

  @override
  String get notificationsEmpty => '通知はまだありません。';

  @override
  String get notificationsUnreadOnly => '未読のみ表示';

  @override
  String get notificationsRead => '既読';

  @override
  String get notificationsUnread => '新着';

  @override
  String get notificationsDeleteTitle => '通知を削除';

  @override
  String get notificationsDeleteMessage => 'この通知を削除しますか？';

  @override
  String get notificationsDeleteConfirm => '削除';

  @override
  String get pushJourneyAssignedTitle => '新しいメッセージ';

  @override
  String get pushJourneyAssignedBody => '新しいリレーメッセージが届きました。';

  @override
  String get pushJourneyResultTitle => '結果が到着';

  @override
  String get pushJourneyResultBody => 'リレー結果を確認してください。';

  @override
  String get errorTitle => 'お知らせ';

  @override
  String get errorGeneric => '問題が発生しました。もう一度お試しください。';

  @override
  String get errorLoginFailed => 'ログインに失敗しました。もう一度お試しください。';

  @override
  String get errorLoginCancelled => 'ログインがキャンセルされました。';

  @override
  String get errorLoginNetwork => 'ネットワーク状態を確認してから再試行してください。';

  @override
  String get errorLoginInvalidToken => 'ログインの検証に失敗しました。もう一度お試しください。';

  @override
  String get errorLoginUnsupportedProvider => 'このログイン方法はサポートされていません。';

  @override
  String get errorLoginUserSyncFailed => 'アカウント情報を保存できませんでした。もう一度お試しください。';

  @override
  String get errorLoginServiceUnavailable => 'ログインサービスを利用できません。しばらくしてから再試行してください。';

  @override
  String get errorSessionExpired => 'セッションの有効期限が切れました。もう一度ログインしてください。';

  @override
  String get errorForbiddenTitle => 'Permission Required';

  @override
  String get errorForbiddenMessage => 'You don\'t have permission to perform this action. Please check your login status or try again later.';

  @override
  String get journeyInboxForbiddenTitle => 'Cannot Load Inbox';

  @override
  String get journeyInboxForbiddenMessage => 'You don\'t have permission to view the inbox. If the problem persists, please sign in again.';

  @override
  String get languageSectionTitle => '言語';

  @override
  String get languageSystem => 'システム設定';

  @override
  String get languageKorean => '韓国語';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSpanish => 'スペイン語';

  @override
  String get languageFrench => 'フランス語';

  @override
  String get languagePortuguese => 'ポルトガル語';

  @override
  String get languageChinese => '中国語';

  @override
  String get composeTitle => 'メッセージ作成';

  @override
  String get composeWizardStep1Title => 'どんな内容で旅を送りますか？';

  @override
  String get composeWizardStep1Subtitle => 'リレーを始める一言を書いてください。';

  @override
  String get composeWizardStep2Title => '何人に届けますか？';

  @override
  String get composeWizardStep2Subtitle => '10〜50人から選べます。';

  @override
  String get composeWizardStep3Title => '写真も一緒に送りますか？';

  @override
  String get composeWizardStep3Subtitle => '最大3枚。なくても送信できます。';

  @override
  String get composeWizardBack => '戻る';

  @override
  String get composeWizardNext => '次へ';

  @override
  String get composeLabel => 'メッセージ';

  @override
  String get composeHint => '伝えたいことを書いてください。';

  @override
  String composeCharacterCount(Object current, Object total) {
    return '$current/$total';
  }

  @override
  String get composeImagesTitle => '写真';

  @override
  String get composeImageHelper => '写真は最大3枚まで添付できます。';

  @override
  String get composeImageUploadHint => '画像を登録してください。';

  @override
  String get composeImageDelete => '画像を削除';

  @override
  String get composeSelectedImagesTitle => '選択した画像';

  @override
  String get composeAddImage => '写真を追加';

  @override
  String get composeSubmit => '送信';

  @override
  String get composeCta => 'メッセージ作成';

  @override
  String get composeTooLong => '文字数が多すぎます。';

  @override
  String get composeForbidden => 'URLや連絡先を削除してください。';

  @override
  String get composeEmpty => 'メッセージを入力してください。';

  @override
  String get composeInvalid => '内容を確認してください。';

  @override
  String get composeImageLimit => '写真は最大3枚まで添付できます。';

  @override
  String get composeImageReadFailed => '画像を読み込めませんでした。もう一度お試しください。';

  @override
  String get composeImageOptimizationFailed => '画像処理に失敗しました。もう一度お試しください。';

  @override
  String get composePermissionDenied => '写真へのアクセスが必要です。';

  @override
  String get composeSessionMissing => '再度ログインしてください。';

  @override
  String get composeSubmitFailed => '送信に失敗しました。もう一度お試しください。';

  @override
  String get composeServerMisconfigured => 'サービス設定が完了していません。しばらくしてからお試しください。';

  @override
  String get composeSubmitSuccess => 'メッセージを送信しました。';

  @override
  String get composeRecipientCountLabel => 'リレー人数';

  @override
  String get composeRecipientCountHint => '1〜5人を選択してください。';

  @override
  String composeRecipientCountOption(Object count) {
    return '$count人';
  }

  @override
  String get composeRecipientRequired => 'リレー人数を選択してください。';

  @override
  String get composeRecipientInvalid => '1〜5人の間で選択してください。';

  @override
  String get composeErrorTitle => 'お知らせ';

  @override
  String get composeSuccessTitle => '完了';

  @override
  String get composeOk => 'OK';

  @override
  String get composeCancel => 'キャンセル';

  @override
  String get composePermissionTitle => '写真の許可';

  @override
  String get composePermissionMessage => '設定で写真へのアクセスを許可してください。';

  @override
  String get composeOpenSettings => '設定を開く';

  @override
  String get commonClose => '閉じる';

  @override
  String get journeyListTitle => '送信したメッセージ';

  @override
  String get sentTabInProgress => '進行中';

  @override
  String get sentTabCompleted => '完了';

  @override
  String get sentEmptyInProgressTitle => '進行中のメッセージはありません';

  @override
  String get sentEmptyInProgressDescription => '新しいリレーメッセージを開始してください。';

  @override
  String get sentEmptyCompletedTitle => '完了したメッセージはありません';

  @override
  String get sentEmptyCompletedDescription => '完了したリレーがここに表示されます。';

  @override
  String get journeyListEmpty => 'まだ送信したメッセージがありません。';

  @override
  String get journeyListCta => '送信したメッセージを見る';

  @override
  String get journeyListStatusLabel => '状態:';

  @override
  String get journeyStatusCreated => '送信済み';

  @override
  String get journeyStatusWaiting => 'マッチング待ち';

  @override
  String get journeyStatusCompleted => '完了';

  @override
  String get journeyStatusInProgress => '進行中';

  @override
  String get journeyStatusUnknown => '不明';

  @override
  String get journeyInProgressHint => '完了後に詳細で返信を確認できます';

  @override
  String get journeyFilterOk => '許可';

  @override
  String get journeyFilterHeld => '保留';

  @override
  String get journeyFilterRemoved => '削除';

  @override
  String get journeyFilterUnknown => '不明';

  @override
  String get inboxTitle => '受信箱';

  @override
  String get inboxTabPending => '未返信';

  @override
  String get inboxTabCompleted => '返信済み';

  @override
  String get inboxEmpty => '受け取ったメッセージはありません。';

  @override
  String get inboxEmptyPendingTitle => '未返信のメッセージはありません';

  @override
  String get inboxEmptyPendingDescription => '新しいメッセージがここに表示されます。';

  @override
  String get inboxEmptyCompletedTitle => '返信済みのメッセージはありません';

  @override
  String get inboxEmptyCompletedDescription => '返信済みのメッセージがここに表示されます。';

  @override
  String get inboxCta => '受信箱を見る';

  @override
  String get inboxRefresh => '更新';

  @override
  String get inboxLoadFailed => '受信箱を読み込めませんでした。';

  @override
  String inboxImageCount(Object count) {
    return '$count枚の写真';
  }

  @override
  String get inboxStatusLabel => '状態:';

  @override
  String get inboxStatusAssigned => '待機中';

  @override
  String get inboxStatusResponded => '返信済み';

  @override
  String get inboxStatusPassed => 'パス';

  @override
  String get inboxStatusReported => '報告済み';

  @override
  String get inboxStatusUnknown => '不明';

  @override
  String get inboxDetailTitle => '受信メッセージ';

  @override
  String get inboxDetailMissing => 'メッセージを読み込めませんでした。';

  @override
  String get inboxImagesLabel => '写真';

  @override
  String get inboxImagesLoadFailed => '写真を読み込めませんでした。';

  @override
  String get inboxBlockCta => '送信者をブロック';

  @override
  String get inboxBlockTitle => 'ブロック';

  @override
  String get inboxBlockMessage => 'このユーザーの次のメッセージを受け取らないようにしますか？';

  @override
  String get inboxBlockConfirm => 'ブロック';

  @override
  String get inboxBlockSuccessTitle => 'ブロック完了';

  @override
  String get inboxBlockSuccessBody => 'ユーザーをブロックしました。';

  @override
  String get inboxBlockFailed => 'ブロックに失敗しました。';

  @override
  String get inboxBlockMissing => '送信者情報が見つかりません。';

  @override
  String get inboxRespondLabel => '返信';

  @override
  String get inboxRespondHint => '返信を書いてください...';

  @override
  String get inboxRespondCta => '返信を送信';

  @override
  String get inboxRespondEmpty => '返信を入力してください。';

  @override
  String get inboxRespondSuccessTitle => '返信完了';

  @override
  String get inboxRespondSuccessBody => '返信を送信しました。';

  @override
  String get inboxPassCta => 'パス';

  @override
  String get inboxPassSuccessTitle => 'パス完了';

  @override
  String get inboxPassSuccessBody => 'このメッセージをパスしました。';

  @override
  String get inboxPassedTitle => 'パスしたメッセージ';

  @override
  String get inboxPassedDetailUnavailable => 'パス処理により内容を閲覧できません。';

  @override
  String get inboxReportCta => '報告';

  @override
  String get inboxReportTitle => '報告理由';

  @override
  String get inboxReportSpam => 'スパム';

  @override
  String get inboxReportAbuse => '不適切';

  @override
  String get inboxReportOther => 'その他';

  @override
  String get inboxReportSuccessTitle => '報告完了';

  @override
  String get inboxReportSuccessBody => '報告を送信しました。';

  @override
  String get inboxActionFailed => '操作を完了できませんでした。';

  @override
  String get journeyDetailTitle => 'メッセージ';

  @override
  String get journeyDetailMessageLabel => 'メッセージ';

  @override
  String get journeyDetailMessageUnavailable => 'メッセージを取得できません。';

  @override
  String get journeyDetailProgressTitle => 'リレー進行';

  @override
  String get journeyDetailStatusLabel => '状態';

  @override
  String get journeyDetailDeadlineLabel => 'リレー期限';

  @override
  String get journeyDetailResponseTargetLabel => '目標返信数';

  @override
  String get journeyDetailRespondedLabel => '返信';

  @override
  String get journeyDetailAssignedLabel => '割り当て';

  @override
  String get journeyDetailPassedLabel => 'パス';

  @override
  String get journeyDetailReportedLabel => '報告';

  @override
  String get journeyDetailCountriesLabel => 'リレー地域';

  @override
  String get journeyDetailCountriesEmpty => 'まだ地域情報がありません。';

  @override
  String get journeyDetailResultsTitle => '返信';

  @override
  String get journeyDetailResultsLocked => '完了後に返信を確認できます。';

  @override
  String get journeyDetailResultsEmpty => 'まだ返信がありません。';

  @override
  String get journeyDetailResultsLoadFailed => '返信を読み込めませんでした。';

  @override
  String get commonTemporaryErrorTitle => '一時的なエラー';

  @override
  String get sentDetailRepliesLoadFailedMessage => '返信を読み込めませんでした。\n一覧に戻ります。';

  @override
  String get commonOk => 'OK';

  @override
  String get journeyDetailResponsesMissingTitle => '一時的なエラー';

  @override
  String get journeyDetailResponsesMissingBody => '返信を読み込めませんでした。もう一度お試しください。\n一覧に戻ります。';

  @override
  String get journeyDetailGateConfigTitle => '広告準備中';

  @override
  String get journeyDetailGateConfigBody => '広告設定が未準備のため、広告なしで詳細に移動します。';

  @override
  String get journeyDetailGateDismissedTitle => '広告視聴未完了';

  @override
  String get journeyDetailGateDismissedBody => '詳細を見るには広告を最後まで視聴してください。';

  @override
  String get journeyDetailGateFailedTitle => '広告を利用できません';

  @override
  String get journeyDetailGateFailedBody => '広告の読み込みに失敗しました。もう一度お試しください。';

  @override
  String get journeyDetailUnlockFailedTitle => 'ロック解除の保存に失敗しました';

  @override
  String get journeyDetailUnlockFailedBody => 'ネットワーク/サーバーの問題でロック解除の保存に失敗しました。もう一度お試しください。';

  @override
  String get journeyDetailGateDialogTitle => 'リワード広告でロック解除';

  @override
  String get journeyDetailGateDialogBody => 'リワード広告の視聴でロック解除します。\n一度視聴すれば永久に解除されます。';

  @override
  String get journeyDetailGateDialogConfirm => 'ロック解除';

  @override
  String get journeyDetailLoadFailed => '進行状況を読み込めませんでした。';

  @override
  String get journeyDetailRetry => '再試行';

  @override
  String get journeyDetailAdRequired => '結果を見るには広告の視聴が必要です。';

  @override
  String get journeyDetailAdCta => '広告を見て結果を見る';

  @override
  String get journeyDetailAdFailedTitle => '広告を読み込めませんでした';

  @override
  String get journeyDetailAdFailedBody => '広告なしで結果を見ますか？';

  @override
  String get journeyDetailAdFailedConfirm => '結果を見る';

  @override
  String get journeyResultReportCta => '返信を報告';

  @override
  String get journeyResultReportSuccessTitle => '報告完了';

  @override
  String get journeyResultReportSuccessBody => '報告を送信しました。';

  @override
  String get journeyResultReportFailed => '報告に失敗しました。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionNotification => '通知';

  @override
  String get settingsNotificationToggle => '通知を受け取る';

  @override
  String get settingsNotificationHint => 'リレー進行と結果をお知らせします。';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get settingsSectionSafety => '安全';

  @override
  String get settingsBlockedUsers => 'ブロック一覧';

  @override
  String get settingsLoadFailed => '設定を読み込めませんでした。';

  @override
  String get settingsUpdateFailed => '設定を保存できませんでした。';

  @override
  String get blockListTitle => 'ブロック一覧';

  @override
  String get blockListEmpty => 'ブロックしたユーザーはいません。';

  @override
  String get blockListUnknownUser => '不明なユーザー';

  @override
  String get blockListLoadFailed => 'ブロック一覧を読み込めませんでした。';

  @override
  String get blockListUnblock => 'ブロック解除';

  @override
  String get blockListUnblockTitle => 'ブロック解除';

  @override
  String get blockListUnblockMessage => 'このユーザーのメッセージを再び受け取りますか？';

  @override
  String get blockListUnblockConfirm => '解除';

  @override
  String get blockListUnblockFailed => 'ブロック解除に失敗しました。';

  @override
  String get onboardingTitle => 'オンボーディング';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return '全$totalステップ中$currentステップ';
  }

  @override
  String get onboardingNotificationTitle => '通知の許可';

  @override
  String get onboardingNotificationDescription => 'リレーメッセージの到着と結果の完了をお知らせします。';

  @override
  String get onboardingNotificationNote => '設定でいつでも変更できます。このステップはスキップできます。';

  @override
  String get onboardingAllowNotifications => '許可する';

  @override
  String get onboardingPhotoTitle => '写真へのアクセス';

  @override
  String get onboardingPhotoDescription => 'プロフィール画像設定とメッセージ画像添付の際にのみ使用します。';

  @override
  String get onboardingPhotoNote => '選択した写真のみアクセスします。このステップはスキップできます。';

  @override
  String get onboardingAllowPhotos => '許可する';

  @override
  String get onboardingGuidelineTitle => 'コミュニティガイドライン';

  @override
  String get onboardingGuidelineDescription => '安全な利用のため、嫌がらせ、ヘイトスピーチ、個人情報の共有などを禁止します。違反時にはコンテンツが制限される場合があります。';

  @override
  String get onboardingAgreeGuidelines => 'コミュニティガイドラインに同意します。';

  @override
  String get onboardingContentPolicyTitle => 'コンテンツポリシー';

  @override
  String get onboardingContentPolicyDescription => '違法、有害、暴力的なコンテンツは禁止されており、違反コンテンツは審査後に制限される場合があります。';

  @override
  String get onboardingAgreeContentPolicy => 'コンテンツポリシーに同意します。';

  @override
  String get onboardingSafetyTitle => '報告とブロック';

  @override
  String get onboardingSafetyDescription => '不快または不適切なコンテンツを報告したり、特定のユーザーをブロックしてメッセージを受信しないようにできます。';

  @override
  String get onboardingConfirmSafety => '報告とブロックのポリシーを確認しました。';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingStart => '開始';

  @override
  String get onboardingAgreeAndDisagree => '同意と不同意';

  @override
  String get onboardingPrevious => '前へ';

  @override
  String get ctaPermissionChoice => '権限を選択';

  @override
  String get onboardingExitTitle => 'オンボーディングを終了しますか？';

  @override
  String get onboardingExitMessage => '後で再開できます。';

  @override
  String get onboardingExitConfirm => '終了';

  @override
  String get onboardingExitCancel => '続ける';

  @override
  String get exitConfirmTitle => '作成をキャンセルしますか？';

  @override
  String get exitConfirmMessage => '入力した内容が失われます。';

  @override
  String get exitConfirmContinue => '作成を続ける';

  @override
  String get exitConfirmLeave => '終了';

  @override
  String get tabHomeLabel => 'ホーム';

  @override
  String get tabSentLabel => '送信済み';

  @override
  String get tabInboxLabel => '受信トレイ';

  @override
  String get tabCreateLabel => 'メッセージ作成';

  @override
  String get tabAlertsLabel => '通知';

  @override
  String get tabProfileLabel => 'プロフィール';

  @override
  String get noticeTitle => 'お知らせ';

  @override
  String get noticeDetailTitle => 'お知らせ';

  @override
  String get noticeFilterLabel => 'お知らせの種類';

  @override
  String get noticeFilterAll => 'すべて';

  @override
  String get noticeFilterSheetTitle => 'お知らせの種類を選択';

  @override
  String get noticeTypeUnknown => '不明';

  @override
  String get noticePinnedBadge => '固定';

  @override
  String get noticeEmptyTitle => 'お知らせはありません';

  @override
  String get noticeEmptyDescription => 'この種類のお知らせはありません。';

  @override
  String get noticeErrorTitle => 'お知らせを読み込めませんでした';

  @override
  String get noticeErrorDescription => 'しばらくしてからもう一度お試しください。';

  @override
  String get profileSignOutCta => 'ログアウト';

  @override
  String get profileSignOutTitle => 'ログアウト';

  @override
  String get profileSignOutMessage => '本当にログアウトしますか？';

  @override
  String get profileSignOutConfirm => 'ログアウト';

  @override
  String get profileUserIdLabel => 'ユーザーID';

  @override
  String get profileDefaultNickname => 'ユーザー';

  @override
  String get profileEditCta => 'プロフィール編集';

  @override
  String get authProviderKakaoLogin => 'Kakaoログイン';

  @override
  String get authProviderGoogleLogin => 'Googleログイン';

  @override
  String get authProviderAppleLogin => 'Appleログイン';

  @override
  String get authProviderUnknownLogin => 'ログイン済み';

  @override
  String get profileLoginProviderKakao => 'Kakaoログイン';

  @override
  String get profileLoginProviderGoogle => 'Googleログイン';

  @override
  String get profileLoginProviderApple => 'Appleログイン';

  @override
  String get profileLoginProviderEmail => 'メールログイン';

  @override
  String get profileLoginProviderUnknown => 'ログイン済み';

  @override
  String get profileAppSettings => 'アプリ設定';

  @override
  String get profileMenuNotices => 'お知らせ';

  @override
  String get profileMenuSupport => 'サポート';

  @override
  String get profileMenuAppInfo => 'アプリ情報';

  @override
  String get profileMenuTitle => 'メニュー';

  @override
  String get profileMenuSubtitle => 'よく使う設定にすぐアクセスできます。';

  @override
  String get profileWithdrawCta => '退会する';

  @override
  String get profileWithdrawTitle => '退会する';

  @override
  String get profileWithdrawMessage => '退会しますか？この操作は取り消せません。';

  @override
  String get profileWithdrawConfirm => '退会';

  @override
  String get profileFeaturePreparingTitle => '準備中';

  @override
  String get profileFeaturePreparingBody => 'この機能はまだ利用できません。';

  @override
  String get profileAvatarSemantics => 'プロフィールのアバター';

  @override
  String get supportTitle => 'サポート';

  @override
  String get supportStatusMessage => 'インストール済みのアプリは最新です。';

  @override
  String get supportReleaseNotesTitle => 'アップデート内容';

  @override
  String supportReleaseNotesHeader(Object version) {
    return '最新バージョン $version の更新内容';
  }

  @override
  String get supportReleaseNotesBody => '• リレー体験と安定性を改善しました。\n• プロフィール/サポート画面のダークテーマを調整しました。\n• 軽微な不具合とパフォーマンスを改善しました。';

  @override
  String get supportVersionUnknown => '不明';

  @override
  String get supportSuggestCta => 'ご意見を送る';

  @override
  String get supportReportCta => '不具合を報告';

  @override
  String get supportFaqTitle => 'よくある質問';

  @override
  String get supportFaqSubtitle => 'よくある質問を確認してください。';

  @override
  String get supportFaqQ1 => 'メッセージが配信されないようです。なぜですか？';

  @override
  String get supportFaqA1 => 'ネットワーク状態、一時的なサーバー遅延、または安全ポリシー（報告/ブロックなど）により、配信が遅延または制限される場合があります。しばらくしてから再度お試しください。';

  @override
  String get supportFaqQ2 => '通知が来ません。どうすればいいですか？';

  @override
  String get supportFaqA2 => 'スマートフォンの設定でEchowanderの通知権限がオフになっている可能性があります。アプリ設定 → アプリ設定（通知設定）に移動して通知権限をオンにし、バッテリー節約/バックグラウンド制限も確認してください。';

  @override
  String get supportFaqQ3 => '不快なメッセージを受け取りました。ブロック/報告はどうすればいいですか？';

  @override
  String get supportFaqA3 => 'メッセージ画面から報告またはブロックを選択できます。ブロックすると、そのユーザーからのメッセージは今後受信されません。報告された内容はコミュニティの安全のために審査される場合があります。';

  @override
  String get supportFaqQ4 => '送信したメッセージを編集またはキャンセルできますか？';

  @override
  String get supportFaqA4 => '一度送信されたメッセージは編集/キャンセルが困難です。送信前に内容を再度確認してください。';

  @override
  String get supportFaqQ5 => 'コミュニティガイドラインに違反するとどうなりますか？';

  @override
  String get supportFaqA5 => '繰り返し違反すると、メッセージ機能が制限されたり、アカウントの利用が制限される場合があります。安全なコミュニティのため、ガイドラインを守ってください。';

  @override
  String get supportActionPreparingTitle => '準備中';

  @override
  String get supportActionPreparingBody => 'この操作はまもなく利用できます。';

  @override
  String get supportSuggestionSubject => 'ご意見・ご要望';

  @override
  String get supportBugSubject => '不具合の報告';

  @override
  String supportEmailFooterUser(String userId) {
    return 'ユーザー : $userId';
  }

  @override
  String supportEmailFooterVersion(String version) {
    return 'アプリバージョン : $version';
  }

  @override
  String get supportEmailLaunchFailed => 'メールアプリを開けませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get appInfoTitle => 'アプリ情報';

  @override
  String get appInfoSettingsTitle => 'アプリ設定';

  @override
  String get appInfoSettingsSubtitle => 'ライセンスとポリシーを確認できます。';

  @override
  String get appInfoSectionTitle => '連携サービス';

  @override
  String get appInfoSectionSubtitle => '連携中のアプリを確認できます。';

  @override
  String appInfoVersionLabel(Object version) {
    return 'バージョン $version';
  }

  @override
  String get appInfoVersionUnknown => '不明';

  @override
  String get appInfoOpenLicenseTitle => 'オープンライセンス';

  @override
  String get appInfoRelatedAppsTitle => 'BIZPECT 関連アプリ';

  @override
  String get appInfoRelatedApp1Title => 'テストアプリ 1';

  @override
  String get appInfoRelatedApp1Description => '関連サービスのテスト用サンプルアプリです。';

  @override
  String get appInfoRelatedApp2Title => 'テストアプリ 2';

  @override
  String get appInfoRelatedApp2Description => '連携テスト用のサンプルアプリです。';

  @override
  String get appInfoExternalLinkLabel => '外部リンクを開く';

  @override
  String get appInfoLinkPreparingTitle => '準備中';

  @override
  String get appInfoLinkPreparingBody => 'まもなく利用できます。';

  @override
  String get openLicenseTitle => 'オープンライセンス';

  @override
  String get openLicenseHeaderTitle => 'オープンソースライブラリ';

  @override
  String get openLicenseHeaderBody => 'このアプリは以下のオープンソースライブラリを使用しています。';

  @override
  String get openLicenseSectionTitle => 'ライセンス一覧';

  @override
  String get openLicenseSectionSubtitle => '使用中のオープンソースを確認してください。';

  @override
  String openLicenseChipVersion(Object version) {
    return 'バージョン: $version';
  }

  @override
  String openLicenseChipLicense(Object license) {
    return 'ライセンス: $license';
  }

  @override
  String get openLicenseChipDetails => '詳細';

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
  String get openLicenseTypeUnknown => '不明';

  @override
  String get openLicenseUnknown => '不明';

  @override
  String get openLicenseEmptyMessage => 'ライセンス情報が見つかりません。';

  @override
  String openLicenseDetailTitle(Object package) {
    return '$package のライセンス';
  }

  @override
  String get journeyDetailAnonymous => '匿名';

  @override
  String get errorNetwork => 'ネットワーク接続を確認してください。';

  @override
  String get errorTimeout => 'リクエストがタイムアウトしました。もう一度お試しください。';

  @override
  String get errorServerUnavailable => 'サーバーに一時的な問題があります。しばらくしてからもう一度お試しください。';

  @override
  String get errorUnauthorized => '再度ログインしてください。';

  @override
  String get errorRetry => '再試行';

  @override
  String get errorCancel => 'キャンセル';

  @override
  String get errorAuthRefreshFailed => 'ネットワークが不安定です。しばらくしてからもう一度お試しください。';

  @override
  String get homeInboxSummaryTitle => '今日のインボックス';

  @override
  String get homeInboxSummaryPending => '未返信';

  @override
  String get homeInboxSummaryCompleted => '返信済み';

  @override
  String get homeInboxSummarySentResponses => '返信到着';

  @override
  String homeInboxSummaryUpdatedAt(Object time) {
    return '更新 $time';
  }

  @override
  String get homeInboxSummaryRefresh => '更新';

  @override
  String get homeInboxSummaryLoadFailed => '要約を読み込めませんでした。';

  @override
  String homeInboxSummaryItemSemantics(Object label, Object count) {
    return '$label $count件';
  }

  @override
  String get homeTimelineTitle => '最近のアクティビティ';

  @override
  String get homeTimelineEmptyTitle => '最近のアクティビティはありません';

  @override
  String get homeTimelineReceivedTitle => '新しいメッセージ';

  @override
  String get homeTimelineRespondedTitle => '返信を送信';

  @override
  String get homeTimelineSentResponseTitle => '返信が届きました';

  @override
  String homeTimelineSubtitle(Object time) {
    return '$time';
  }

  @override
  String get homeDailyPromptTitle => '今日の質問';

  @override
  String get homeDailyPromptHint => 'タップしてメッセージ作成';

  @override
  String get homeDailyPromptAction => '作成する';

  @override
  String get homeAnnouncementTitle => 'アップデート';

  @override
  String get homeAnnouncementSummary => '新機能を確認しましょう。';

  @override
  String get homeAnnouncementAction => '詳細';

  @override
  String get homeAnnouncementDetailTitle => 'アップデート';

  @override
  String get homeAnnouncementDetailBody => 'よりスムーズに使えるよう改善しました。';

  @override
  String get homePromptQ1 => '今日笑顔になったことは何ですか？';

  @override
  String get homePromptQ2 => '今週楽しみにしていることは？';

  @override
  String get homePromptQ3 => 'もう一度行きたい場所はどこですか？';

  @override
  String get homePromptQ4 => '今日の小さな成功を教えてください。';

  @override
  String get homePromptQ5 => '身につけたい習慣は何ですか？';

  @override
  String get homePromptQ6 => '今日感謝を伝えたい人は誰ですか？';

  @override
  String get homePromptQ7 => '最近ずっと聴いている曲は？';

  @override
  String get homePromptQ8 => '今日を3つの言葉で表すと？';

  @override
  String get homePromptQ9 => '最近学んだことは？';

  @override
  String get homePromptQ10 => '自分に一言送るなら何と言いますか？';

  @override
  String get profileEditTitle => 'プロフィール編集';

  @override
  String get profileEditNicknameLabel => 'ニックネーム';

  @override
  String get profileEditNicknameHint => 'ニックネームを入力';

  @override
  String get profileEditNicknameEmpty => 'ニックネームを入力してください';

  @override
  String profileEditNicknameTooShort(Object min) {
    return 'ニックネームは最低$min文字以上である必要があります';
  }

  @override
  String profileEditNicknameTooLong(Object max) {
    return 'ニックネームは最大$max文字まで入力できます';
  }

  @override
  String get profileEditNicknameConsecutiveSpaces => '連続したスペースは使用できません';

  @override
  String get profileEditNicknameInvalidCharacters => '韓国語、英語、数字、アンダースコア(_)のみ使用できます';

  @override
  String get profileEditNicknameUnderscoreAtEnds => 'Underscore (_) cannot be used at the beginning or end';

  @override
  String get profileEditNicknameConsecutiveUnderscores => 'Consecutive underscores (__) are not allowed';

  @override
  String get profileEditNicknameForbidden => 'This nickname is not allowed';

  @override
  String get profileEditNicknameChecking => '確認中...';

  @override
  String get profileEditNicknameAvailable => 'このニックネームは使用可能です';

  @override
  String get profileEditNicknameTaken => 'このニックネームは既に使用されています';

  @override
  String get profileEditNicknameError => '確認中にエラーが発生しました';

  @override
  String get profileEditAvatarLabel => 'プロフィール写真';

  @override
  String get profileEditAvatarChange => '写真を変更';

  @override
  String get profileEditSave => '保存';

  @override
  String get profileEditCancel => 'キャンセル';

  @override
  String get profileEditSaveSuccess => 'プロフィールが保存されました';

  @override
  String get profileEditSaveFailed => '保存に失敗しました。もう一度お試しください';

  @override
  String get profileEditImageTooLarge => 'Image file is too large. Please select another image';

  @override
  String get profileEditImageOptimizationFailed => 'An error occurred while processing the image. Please try again';

  @override
  String get profileEditCropTitle => '写真編集';

  @override
  String get profileEditCropDescription => '希望の位置に調整してください';

  @override
  String get profileEditCropCancel => 'キャンセル';

  @override
  String get profileEditCropComplete => '完了';

  @override
  String get profileEditCropFailedTitle => '写真編集に失敗しました';

  @override
  String get profileEditCropFailedMessage => '写真の編集中にエラーが発生しました。もう一度お試しください。';

  @override
  String get profileEditCropFailedAction => 'OK';
}
