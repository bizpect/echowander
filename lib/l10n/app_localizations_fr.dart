// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'EchoWander';

  @override
  String get splashTitle => 'Démarrage...';

  @override
  String get loginTitle => 'Se connecter';

  @override
  String get loginKakao => 'Continuer avec Kakao';

  @override
  String get loginGoogle => 'Continuer avec Google';

  @override
  String get loginApple => 'Continuer avec Apple';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get homeGreeting => 'Bon retour';

  @override
  String get pushPreviewTitle => 'Notification';

  @override
  String get pushPreviewDescription =>
      'Ceci est un écran de test des liens profonds de notifications.';

  @override
  String get notificationTitle => 'Nouveau message';

  @override
  String get notificationOpen => 'Ouvrir';

  @override
  String get notificationDismiss => 'Fermer';

  @override
  String get errorTitle => 'Information';

  @override
  String get errorGeneric => 'Un problème est survenu. Veuillez réessayer.';

  @override
  String get errorLoginFailed => 'Échec de la connexion. Veuillez réessayer.';

  @override
  String get errorLoginCancelled => 'La connexion a été annulée.';

  @override
  String get errorLoginNetwork =>
      'Vérifiez votre connexion réseau et réessayez.';

  @override
  String get errorLoginInvalidToken =>
      'La vérification de la connexion a échoué. Veuillez réessayer.';

  @override
  String get errorLoginUnsupportedProvider =>
      'Cette méthode de connexion n\'est pas prise en charge.';

  @override
  String get errorLoginUserSyncFailed =>
      'Impossible d\'enregistrer votre compte. Veuillez réessayer.';

  @override
  String get errorLoginServiceUnavailable =>
      'Le service de connexion est temporairement indisponible. Veuillez réessayer plus tard.';

  @override
  String get errorSessionExpired =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get languageSectionTitle => 'Langue';

  @override
  String get languageSystem => 'Par défaut du système';

  @override
  String get languageKorean => 'Coréen';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageJapanese => 'Japonais';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageFrench => 'Français';

  @override
  String get languagePortuguese => 'Portugais';

  @override
  String get languageChinese => 'Chinois';
}
