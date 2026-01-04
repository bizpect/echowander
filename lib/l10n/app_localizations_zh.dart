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
}
