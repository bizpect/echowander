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
  String get loginKakao => 'Kakaoで続行';

  @override
  String get loginGoogle => 'Googleで続行';

  @override
  String get loginApple => 'Appleで続行';

  @override
  String get homeTitle => 'ホーム';

  @override
  String get homeGreeting => 'お帰りなさい';

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
  String get errorLoginServiceUnavailable =>
      'ログインサービスを利用できません。しばらくしてから再試行してください。';

  @override
  String get errorSessionExpired => 'セッションの有効期限が切れました。もう一度ログインしてください。';

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
  String get journeyListTitle => '送信したメッセージ';

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
  String get journeyStatusUnknown => '不明';

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
  String get inboxEmpty => '受け取ったメッセージはありません。';

  @override
  String get inboxCta => '受信箱を見る';

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
  String get journeyDetailResultsTitle => '結果';

  @override
  String get journeyDetailResultsLocked => '完了後に結果が表示されます。';

  @override
  String get journeyDetailResultsEmpty => 'まだ返信がありません。';

  @override
  String get journeyDetailResultsLoadFailed => '結果を読み込めませんでした。';

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
  String get onboardingNotificationDescription => '結果や重要なお知らせを受け取れます。';

  @override
  String get onboardingNotificationNote => '広告の通知は送りません。設定でいつでも変更できます。';

  @override
  String get onboardingAllowNotifications => '通知を許可する';

  @override
  String get onboardingPhotoTitle => '写真へのアクセス';

  @override
  String get onboardingPhotoDescription => 'メッセージに画像を添付するために必要です。';

  @override
  String get onboardingPhotoNote => '最大3枚まで添付できます。選択した写真のみアクセスします。';

  @override
  String get onboardingAllowPhotos => '写真へのアクセスを許可する';

  @override
  String get onboardingGuidelineTitle => 'コミュニティガイドライン';

  @override
  String get onboardingGuidelineDescription => '嫌がらせ、ヘイト、個人情報の共有は禁止です。';

  @override
  String get onboardingAgreeGuidelines => 'ガイドラインに同意します。';

  @override
  String get onboardingContentPolicyTitle => 'コンテンツポリシー';

  @override
  String get onboardingContentPolicyDescription => '有害または禁止された内容は削除される場合があります。';

  @override
  String get onboardingAgreeContentPolicy => 'コンテンツポリシーに同意します。';

  @override
  String get onboardingSafetyTitle => '報告・ブロック';

  @override
  String get onboardingSafetyDescription => 'いつでも報告やブロックができます。';

  @override
  String get onboardingConfirmSafety => '報告・ブロックの方針を確認しました。';

  @override
  String get onboardingSkip => 'あとで';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingStart => '開始';
}
