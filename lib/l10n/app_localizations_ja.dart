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
}
