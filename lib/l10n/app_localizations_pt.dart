// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'EchoWander';

  @override
  String get splashTitle => 'A iniciar...';

  @override
  String get loginTitle => 'Iniciar sessão';

  @override
  String get loginKakao => 'Continuar com Kakao';

  @override
  String get loginGoogle => 'Continuar com Google';

  @override
  String get loginApple => 'Continuar com Apple';

  @override
  String get homeTitle => 'Início';

  @override
  String get homeGreeting => 'Bem-vindo de volta';

  @override
  String get pushPreviewTitle => 'Notificação';

  @override
  String get pushPreviewDescription =>
      'Este é um ecrã de teste para links profundos de notificações.';

  @override
  String get notificationTitle => 'Nova mensagem';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationDismiss => 'Fechar';

  @override
  String get errorTitle => 'Aviso';

  @override
  String get errorGeneric => 'Ocorreu um problema. Tente novamente.';

  @override
  String get errorLoginFailed => 'Falha ao iniciar sessão. Tente novamente.';

  @override
  String get errorLoginCancelled => 'O início de sessão foi cancelado.';

  @override
  String get errorLoginNetwork =>
      'Verifique a sua ligação de rede e tente novamente.';

  @override
  String get errorLoginInvalidToken =>
      'A verificação do início de sessão falhou. Tente novamente.';

  @override
  String get errorLoginUnsupportedProvider =>
      'Este método de início de sessão não é suportado.';

  @override
  String get errorLoginUserSyncFailed =>
      'Não foi possível guardar a sua conta. Tente novamente.';

  @override
  String get errorLoginServiceUnavailable =>
      'O serviço de início de sessão está temporariamente indisponível. Tente mais tarde.';

  @override
  String get errorSessionExpired =>
      'A sua sessão expirou. Inicie sessão novamente.';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageJapanese => 'Japonês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languageFrench => 'Francês';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageChinese => 'Chinês';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'EchoWander';

  @override
  String get splashTitle => 'Iniciando...';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginKakao => 'Continuar com Kakao';

  @override
  String get loginGoogle => 'Continuar com Google';

  @override
  String get loginApple => 'Continuar com Apple';

  @override
  String get homeTitle => 'Início';

  @override
  String get homeGreeting => 'Bem-vindo de volta';

  @override
  String get pushPreviewTitle => 'Notificação';

  @override
  String get pushPreviewDescription =>
      'Esta é uma tela de teste para links profundos de notificações.';

  @override
  String get notificationTitle => 'Nova mensagem';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationDismiss => 'Fechar';

  @override
  String get errorTitle => 'Aviso';

  @override
  String get errorGeneric => 'Ocorreu um problema. Tente novamente.';

  @override
  String get errorLoginFailed => 'Falha ao entrar. Tente novamente.';

  @override
  String get errorLoginCancelled => 'O login foi cancelado.';

  @override
  String get errorLoginNetwork =>
      'Verifique sua conexão de rede e tente novamente.';

  @override
  String get errorLoginInvalidToken =>
      'A verificação do login falhou. Tente novamente.';

  @override
  String get errorLoginUnsupportedProvider =>
      'Este método de login não é compatível.';

  @override
  String get errorLoginUserSyncFailed =>
      'Não foi possível salvar sua conta. Tente novamente.';

  @override
  String get errorLoginServiceUnavailable =>
      'O serviço de login está temporariamente indisponível. Tente mais tarde.';

  @override
  String get errorSessionExpired => 'Sua sessão expirou. Faça login novamente.';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get languageKorean => 'Coreano';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageJapanese => 'Japonês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languageFrench => 'Francês';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageChinese => 'Chinês';
}
