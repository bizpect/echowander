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
  String get loginDescription => 'Commencez votre message relais anonyme';

  @override
  String get loginKakao => 'Continuer avec Kakao';

  @override
  String get loginGoogle => 'Continuer avec Google';

  @override
  String get loginApple => 'Continuer avec Apple';

  @override
  String get loginTerms =>
      'En vous connectant, vous acceptez nos Conditions d\'utilisation et notre Politique de confidentialité';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get homeGreeting => 'Bon retour';

  @override
  String get homeRecentJourneysTitle => 'Messages récents';

  @override
  String get homeActionsTitle => 'Commencer';

  @override
  String get homeEmptyTitle => 'Bienvenue sur EchoWander';

  @override
  String get homeEmptyDescription =>
      'Envoyez votre premier message relais ou consultez votre boîte de réception.';

  @override
  String get homeInboxCardTitle => 'Boîte de réception';

  @override
  String get homeInboxCardDescription =>
      'Consultez et répondez aux messages que vous avez reçus.';

  @override
  String get homeCreateCardTitle => 'Créer un message';

  @override
  String get homeCreateCardDescription => 'Démarrez un nouveau message relais.';

  @override
  String get homeJourneyCardViewDetails => 'Voir les détails';

  @override
  String get homeRefresh => 'Actualiser';

  @override
  String get homeLoadFailed => 'Nous n\'avons pas pu charger vos données.';

  @override
  String homeInboxCount(Object count) {
    return '$count nouveau(x)';
  }

  @override
  String get settingsCta => 'Réglages';

  @override
  String get settingsNotificationInbox => 'Boîte de notifications';

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
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'Aucune notification pour le moment.';

  @override
  String get notificationsUnreadOnly => 'Afficher uniquement les non lues';

  @override
  String get notificationsRead => 'Lue';

  @override
  String get notificationsUnread => 'Nouveau';

  @override
  String get notificationsDeleteTitle => 'Supprimer la notification';

  @override
  String get notificationsDeleteMessage => 'Supprimer cette notification ?';

  @override
  String get notificationsDeleteConfirm => 'Supprimer';

  @override
  String get pushJourneyAssignedTitle => 'Nouveau message';

  @override
  String get pushJourneyAssignedBody => 'Un nouveau message relais est arrivé.';

  @override
  String get pushJourneyResultTitle => 'Résultat disponible';

  @override
  String get pushJourneyResultBody => 'Votre résultat de relais est prêt.';

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

  @override
  String get composeTitle => 'Écrire un message';

  @override
  String get composeWizardStep1Title => 'Quel message pour ce voyage ?';

  @override
  String get composeWizardStep1Subtitle =>
      'Écrivez une phrase pour lancer le relais.';

  @override
  String get composeWizardStep2Title => 'À combien de personnes l’envoyer ?';

  @override
  String get composeWizardStep2Subtitle => 'Choisissez entre 1 et 5.';

  @override
  String get composeWizardStep3Title => 'Une photo à ajouter ?';

  @override
  String get composeWizardStep3Subtitle =>
      'Jusqu’à 3 photos. Vous pouvez aussi envoyer sans photo.';

  @override
  String get composeWizardBack => 'Retour';

  @override
  String get composeWizardNext => 'Suivant';

  @override
  String get composeLabel => 'Message';

  @override
  String get composeHint => 'Partagez vos pensées...';

  @override
  String composeCharacterCount(Object current, Object total) {
    return '$current/$total';
  }

  @override
  String get composeImagesTitle => 'Images';

  @override
  String get composeAddImage => 'Ajouter une photo';

  @override
  String get composeSubmit => 'Envoyer';

  @override
  String get composeCta => 'Écrire un message';

  @override
  String get composeTooLong => 'Le message est trop long.';

  @override
  String get composeForbidden => 'Supprimez les URL ou coordonnées.';

  @override
  String get composeEmpty => 'Veuillez saisir un message.';

  @override
  String get composeInvalid => 'Veuillez vérifier le contenu.';

  @override
  String get composeImageLimit => 'Vous pouvez joindre jusqu\'à 3 images.';

  @override
  String get composePermissionDenied => 'L\'accès aux photos est nécessaire.';

  @override
  String get composeSessionMissing => 'Veuillez vous reconnecter.';

  @override
  String get composeSubmitFailed =>
      'Impossible d\'envoyer le message. Réessayez.';

  @override
  String get composeServerMisconfigured =>
      'Le service n\'est pas encore configuré. Réessayez plus tard.';

  @override
  String get composeSubmitSuccess => 'Votre message a été envoyé.';

  @override
  String get composeRecipientCountLabel => 'Nombre de relais';

  @override
  String get composeRecipientCountHint => 'Sélectionnez de 1 à 5 personnes.';

  @override
  String composeRecipientCountOption(Object count) {
    return '$count personnes';
  }

  @override
  String get composeRecipientRequired =>
      'Sélectionnez le nombre de personnes à relayer.';

  @override
  String get composeRecipientInvalid =>
      'Vous pouvez sélectionner entre 1 et 5 personnes.';

  @override
  String get composeErrorTitle => 'Info';

  @override
  String get composeSuccessTitle => 'Terminé';

  @override
  String get composeOk => 'OK';

  @override
  String get composeCancel => 'Annuler';

  @override
  String get composePermissionTitle => 'Autoriser l\'accès aux photos';

  @override
  String get composePermissionMessage =>
      'Ouvrez les réglages pour autoriser l\'accès aux photos.';

  @override
  String get composeOpenSettings => 'Ouvrir les réglages';

  @override
  String get journeyListTitle => 'Messages envoyés';

  @override
  String get journeyListEmpty => 'Aucun message envoyé pour le moment.';

  @override
  String get journeyListCta => 'Voir les messages envoyés';

  @override
  String get journeyListStatusLabel => 'Statut :';

  @override
  String get journeyStatusCreated => 'Envoyé';

  @override
  String get journeyStatusWaiting => 'En attente de correspondance';

  @override
  String get journeyStatusCompleted => 'Terminé';

  @override
  String get journeyStatusInProgress => 'En cours';

  @override
  String get journeyStatusUnknown => 'Inconnu';

  @override
  String get journeyInProgressHint =>
      'Vous pourrez voir les réponses après la fin';

  @override
  String get journeyFilterOk => 'Autorisé';

  @override
  String get journeyFilterHeld => 'En attente';

  @override
  String get journeyFilterRemoved => 'Supprimé';

  @override
  String get journeyFilterUnknown => 'Inconnu';

  @override
  String get inboxTitle => 'Boîte de réception';

  @override
  String get inboxEmpty => 'Aucun message reçu pour le moment.';

  @override
  String get inboxCta => 'Voir la boîte de réception';

  @override
  String get inboxRefresh => 'Actualiser';

  @override
  String get inboxLoadFailed =>
      'Nous n\'avons pas pu charger votre boîte de réception.';

  @override
  String inboxImageCount(Object count) {
    return '$count photo(s)';
  }

  @override
  String get inboxStatusLabel => 'Statut :';

  @override
  String get inboxStatusAssigned => 'En attente';

  @override
  String get inboxStatusResponded => 'Répondu';

  @override
  String get inboxStatusPassed => 'Passé';

  @override
  String get inboxStatusReported => 'Signalé';

  @override
  String get inboxStatusUnknown => 'Inconnu';

  @override
  String get inboxDetailTitle => 'Message reçu';

  @override
  String get inboxDetailMissing => 'Impossible de charger ce message.';

  @override
  String get inboxImagesLabel => 'Photos';

  @override
  String get inboxImagesLoadFailed => 'Impossible de charger les photos.';

  @override
  String get inboxBlockCta => 'Bloquer l\'expéditeur';

  @override
  String get inboxBlockTitle => 'Bloquer l\'utilisateur';

  @override
  String get inboxBlockMessage =>
      'Bloquer cet utilisateur pour les prochains messages ?';

  @override
  String get inboxBlockConfirm => 'Bloquer';

  @override
  String get inboxBlockSuccessTitle => 'Bloqué';

  @override
  String get inboxBlockSuccessBody => 'L\'utilisateur a été bloqué.';

  @override
  String get inboxBlockFailed => 'Impossible de bloquer l\'utilisateur.';

  @override
  String get inboxBlockMissing => 'Impossible d\'identifier l\'expéditeur.';

  @override
  String get inboxRespondLabel => 'Répondre';

  @override
  String get inboxRespondHint => 'Écrivez votre réponse...';

  @override
  String get inboxRespondCta => 'Envoyer la réponse';

  @override
  String get inboxRespondEmpty => 'Veuillez saisir une réponse.';

  @override
  String get inboxRespondSuccessTitle => 'Réponse envoyée';

  @override
  String get inboxRespondSuccessBody => 'Votre réponse a été envoyée.';

  @override
  String get inboxPassCta => 'Passer';

  @override
  String get inboxPassSuccessTitle => 'Passé';

  @override
  String get inboxPassSuccessBody => 'Vous avez passé ce message.';

  @override
  String get inboxReportCta => 'Signaler';

  @override
  String get inboxReportTitle => 'Motif du signalement';

  @override
  String get inboxReportSpam => 'Spam';

  @override
  String get inboxReportAbuse => 'Abus';

  @override
  String get inboxReportOther => 'Autre';

  @override
  String get inboxReportSuccessTitle => 'Signalement envoyé';

  @override
  String get inboxReportSuccessBody => 'Votre signalement a été envoyé.';

  @override
  String get inboxActionFailed => 'Impossible d\'effectuer cette action.';

  @override
  String get journeyDetailTitle => 'Message';

  @override
  String get journeyDetailMessageLabel => 'Message';

  @override
  String get journeyDetailMessageUnavailable =>
      'Impossible de charger le message.';

  @override
  String get journeyDetailProgressTitle => 'Progression du relais';

  @override
  String get journeyDetailStatusLabel => 'Statut';

  @override
  String get journeyDetailDeadlineLabel => 'Date limite du relais';

  @override
  String get journeyDetailResponseTargetLabel => 'Objectif de réponses';

  @override
  String get journeyDetailRespondedLabel => 'Réponses';

  @override
  String get journeyDetailAssignedLabel => 'Attribués';

  @override
  String get journeyDetailPassedLabel => 'Passés';

  @override
  String get journeyDetailReportedLabel => 'Signalés';

  @override
  String get journeyDetailCountriesLabel => 'Zones du relais';

  @override
  String get journeyDetailCountriesEmpty => 'Aucune zone pour le moment.';

  @override
  String get journeyDetailResultsTitle => 'Résultats';

  @override
  String get journeyDetailResultsLocked =>
      'Les résultats apparaîtront après la fin.';

  @override
  String get journeyDetailResultsEmpty => 'Aucune réponse pour le moment.';

  @override
  String get journeyDetailResultsLoadFailed =>
      'Impossible de charger les résultats.';

  @override
  String get journeyDetailLoadFailed => 'Impossible de charger la progression.';

  @override
  String get journeyDetailRetry => 'Réessayer';

  @override
  String get journeyDetailAdRequired =>
      'Regardez une pub pour voir les résultats.';

  @override
  String get journeyDetailAdCta => 'Voir la pub et débloquer';

  @override
  String get journeyDetailAdFailedTitle => 'Pub indisponible';

  @override
  String get journeyDetailAdFailedBody =>
      'Impossible de charger la pub. Voir les résultats quand même ?';

  @override
  String get journeyDetailAdFailedConfirm => 'Voir les résultats';

  @override
  String get journeyResultReportCta => 'Signaler la réponse';

  @override
  String get journeyResultReportSuccessTitle => 'Signalement envoyé';

  @override
  String get journeyResultReportSuccessBody =>
      'Votre signalement a été envoyé.';

  @override
  String get journeyResultReportFailed =>
      'Impossible d\'envoyer le signalement.';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsSectionNotification => 'Notifications';

  @override
  String get settingsNotificationToggle => 'Autoriser les notifications';

  @override
  String get settingsNotificationHint =>
      'Recevez les mises à jour et résultats.';

  @override
  String get settingsSectionSafety => 'Sécurité';

  @override
  String get settingsBlockedUsers => 'Utilisateurs bloqués';

  @override
  String get settingsLoadFailed => 'Impossible de charger les réglages.';

  @override
  String get settingsUpdateFailed =>
      'Impossible de mettre à jour les réglages.';

  @override
  String get blockListTitle => 'Utilisateurs bloqués';

  @override
  String get blockListEmpty => 'Aucun utilisateur bloqué.';

  @override
  String get blockListUnknownUser => 'Utilisateur inconnu';

  @override
  String get blockListLoadFailed =>
      'Impossible de charger la liste de blocage.';

  @override
  String get blockListUnblock => 'Débloquer';

  @override
  String get blockListUnblockTitle => 'Débloquer l\'utilisateur';

  @override
  String get blockListUnblockMessage =>
      'Autoriser de nouveau les messages de cet utilisateur ?';

  @override
  String get blockListUnblockConfirm => 'Débloquer';

  @override
  String get blockListUnblockFailed =>
      'Impossible de débloquer l\'utilisateur.';

  @override
  String get onboardingTitle => 'Démarrage';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return 'Étape $current sur $total';
  }

  @override
  String get onboardingNotificationTitle => 'Autorisation des notifications';

  @override
  String get onboardingNotificationDescription =>
      'Nous vous informerons de l\'arrivée des messages relais et de la disponibilité des résultats.';

  @override
  String get onboardingNotificationNote =>
      'Vous pouvez modifier ceci à tout moment dans Réglages. Cette étape est facultative.';

  @override
  String get onboardingAllowNotifications => 'Autoriser';

  @override
  String get onboardingPhotoTitle => 'Accès aux photos';

  @override
  String get onboardingPhotoDescription =>
      'Utilisé uniquement pour définir des images de profil et joindre des images aux messages.';

  @override
  String get onboardingPhotoNote =>
      'Nous n\'accédons qu\'aux photos que vous sélectionnez. Cette étape est facultative.';

  @override
  String get onboardingAllowPhotos => 'Autoriser';

  @override
  String get onboardingGuidelineTitle => 'Règles de la communauté';

  @override
  String get onboardingGuidelineDescription =>
      'Pour une utilisation sûre, le harcèlement, les discours haineux et le partage d\'informations personnelles sont interdits. Les violations peuvent entraîner des restrictions de contenu.';

  @override
  String get onboardingAgreeGuidelines =>
      'J\'accepte les règles de la communauté.';

  @override
  String get onboardingContentPolicyTitle => 'Politique de contenu';

  @override
  String get onboardingContentPolicyDescription =>
      'Le contenu illégal, nuisible et violent est interdit. Le contenu en violation peut être restreint après examen.';

  @override
  String get onboardingAgreeContentPolicy =>
      'J\'accepte la politique de contenu.';

  @override
  String get onboardingSafetyTitle => 'Signaler et bloquer';

  @override
  String get onboardingSafetyDescription =>
      'Vous pouvez signaler du contenu offensant ou inapproprié, ou bloquer des utilisateurs spécifiques pour ne plus recevoir leurs messages.';

  @override
  String get onboardingConfirmSafety =>
      'Je comprends la politique de signalement et de blocage.';

  @override
  String get onboardingSkip => 'Ignorer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingAgreeAndDisagree => 'Accepter et Refuser';

  @override
  String get onboardingPrevious => 'Précédent';

  @override
  String get ctaPermissionChoice => 'Choisir Permission';

  @override
  String get onboardingExitTitle => 'Quitter l\'intégration ?';

  @override
  String get onboardingExitMessage => 'Vous pourrez recommencer plus tard.';

  @override
  String get onboardingExitConfirm => 'Quitter';

  @override
  String get onboardingExitCancel => 'Continuer';

  @override
  String get exitConfirmTitle => 'Annuler l\'écriture?';

  @override
  String get exitConfirmMessage => 'Votre saisie sera perdue.';

  @override
  String get exitConfirmContinue => 'Continuer à écrire';

  @override
  String get exitConfirmLeave => 'Quitter';

  @override
  String get tabHomeLabel => 'Accueil';

  @override
  String get tabSentLabel => 'Envoyés';

  @override
  String get tabInboxLabel => 'Boîte de réception';

  @override
  String get tabCreateLabel => 'Créer un message';

  @override
  String get tabAlertsLabel => 'Notifications';

  @override
  String get tabProfileLabel => 'Profil';

  @override
  String get profileSignOutCta => 'Se déconnecter';

  @override
  String get profileSignOutTitle => 'Se déconnecter';

  @override
  String get profileSignOutMessage => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get profileSignOutConfirm => 'Se déconnecter';

  @override
  String get profileUserIdLabel => 'ID utilisateur';

  @override
  String get profileDefaultNickname => 'Utilisateur';

  @override
  String get journeyDetailAnonymous => 'Anonyme';

  @override
  String get errorNetwork => 'Veuillez vérifier votre connexion réseau.';

  @override
  String get errorTimeout => 'Délai d\'attente dépassé. Veuillez réessayer.';

  @override
  String get errorServerUnavailable =>
      'Le serveur est temporairement indisponible. Veuillez réessayer plus tard.';

  @override
  String get errorUnauthorized => 'Veuillez vous reconnecter.';

  @override
  String get errorRetry => 'Réessayer';

  @override
  String get errorCancel => 'Annuler';

  @override
  String get errorAuthRefreshFailed =>
      'Le réseau est instable. Veuillez réessayer dans un moment.';
}
