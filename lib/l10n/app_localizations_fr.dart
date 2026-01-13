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
  String get loginTerms => 'En vous connectant, vous acceptez nos Conditions d\'utilisation et notre Politique de confidentialité';

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
  String get homeEmptyDescription => 'Envoyez votre premier message relais ou consultez votre boîte de réception.';

  @override
  String get homeInboxCardTitle => 'Boîte de réception';

  @override
  String get homeInboxCardDescription => 'Consultez et répondez aux messages que vous avez reçus.';

  @override
  String get homeCreateCardTitle => 'Créer un message';

  @override
  String get homeCreateCardDescription => 'Démarrez un nouveau message relais.';

  @override
  String get homeJourneyCardViewDetails => 'Voir les détails';

  @override
  String get homeRefresh => 'Actualiser';

  @override
  String get homeExitTitle => 'Quitter l\'application ?';

  @override
  String get homeExitMessage => 'L\'application va se fermer.';

  @override
  String get homeExitCancel => 'Annuler';

  @override
  String get homeExitConfirm => 'Quitter';

  @override
  String get homeExitAdLoading => 'Chargement de l\'annonce...';

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
  String get pushPreviewDescription => 'Ceci est un écran de test des liens profonds de notifications.';

  @override
  String get notificationTitle => 'Nouveau message';

  @override
  String get notificationOpen => 'Ouvrir';

  @override
  String get notificationDismiss => 'Fermer';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notificationsUnreadCountLabel(Object count) {
    return 'Notifications non lues $count';
  }

  @override
  String get notificationsUnreadCountOverflow => '9+';

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
  String get errorLoginNetwork => 'Vérifiez votre connexion réseau et réessayez.';

  @override
  String get errorLoginInvalidToken => 'La vérification de la connexion a échoué. Veuillez réessayer.';

  @override
  String get errorLoginUnsupportedProvider => 'Cette méthode de connexion n\'est pas prise en charge.';

  @override
  String get errorLoginUserSyncFailed => 'Impossible d\'enregistrer votre compte. Veuillez réessayer.';

  @override
  String get errorLoginServiceUnavailable => 'Le service de connexion est temporairement indisponible. Veuillez réessayer plus tard.';

  @override
  String get errorSessionExpired => 'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get errorForbiddenTitle => 'Permission Required';

  @override
  String get errorForbiddenMessage => 'You don\'t have permission to perform this action. Please check your login status or try again later.';

  @override
  String get journeyInboxForbiddenTitle => 'Cannot Load Inbox';

  @override
  String get journeyInboxForbiddenMessage => 'You don\'t have permission to view the inbox. If the problem persists, please sign in again.';

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
  String get composeWizardStep1Subtitle => 'Écrivez une phrase pour lancer le relais.';

  @override
  String get composeWizardStep2Title => 'À combien de personnes l\'envoyer ?';

  @override
  String get composeWizardStep2Subtitle => 'Choisissez entre 10 et 50.';

  @override
  String get composeWizardStep3Title => 'Une photo à ajouter ?';

  @override
  String get composeWizardStep3Subtitle => 'Jusqu’à 3 photos. Vous pouvez aussi envoyer sans photo.';

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
  String get composeImageHelper => 'Vous pouvez joindre jusqu\'à 3 photos.';

  @override
  String get composeImageUploadHint => 'Téléchargez une image.';

  @override
  String get composeImageDelete => 'Supprimer l\'image';

  @override
  String get composeSelectedImagesTitle => 'Images sélectionnées';

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
  String get composeImageReadFailed => 'Impossible de lire l\'image. Veuillez réessayer.';

  @override
  String get composeImageOptimizationFailed => 'Le traitement de l\'image a échoué. Veuillez réessayer.';

  @override
  String get composePermissionDenied => 'L\'accès aux photos est nécessaire.';

  @override
  String get composeSessionMissing => 'Veuillez vous reconnecter.';

  @override
  String get composeSubmitFailed => 'Impossible d\'envoyer le message. Réessayez.';

  @override
  String get composeServerMisconfigured => 'Le service n\'est pas encore configuré. Réessayez plus tard.';

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
  String get composeRecipientRequired => 'Sélectionnez le nombre de personnes à relayer.';

  @override
  String get composeRecipientInvalid => 'Vous ne pouvez sélectionner qu\'entre 1 et 5 personnes.';

  @override
  String get composeErrorTitle => 'Info';

  @override
  String get composeSuccessTitle => 'Terminé';

  @override
  String get composeOk => 'OK';

  @override
  String get composeCancel => 'Annuler';

  @override
  String get sessionExpiredTitle => 'Session Expirée';

  @override
  String get sessionExpiredBody => 'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get sessionExpiredCtaLogin => 'Se Connecter';

  @override
  String get sendFailedTitle => 'Échec de l\'Envoi';

  @override
  String get sendFailedTryAgain => 'Échec de l\'envoi du message. Veuillez réessayer.';

  @override
  String get moderationContentBlockedMessage => 'Le contenu du message est inapproprié.';

  @override
  String get moderationBlockedTitle => 'Impossible d\'envoyer';

  @override
  String get nicknameForbiddenMessage => 'Votre pseudonyme contient des mots interdits.';

  @override
  String get nicknameTakenMessage => 'Ce pseudonyme est déjà utilisé.';

  @override
  String get composeContentBlocked => 'Ce contenu ne peut pas être envoyé.';

  @override
  String get composeContentBlockedProfanity => 'Le langage inapproprié n\'est pas autorisé.';

  @override
  String get composeContentBlockedSexual => 'Le contenu sexuel est interdit.';

  @override
  String get composeContentBlockedHate => 'Les discours de haine sont interdits.';

  @override
  String get composeContentBlockedThreat => 'Le contenu menaçant est interdit.';

  @override
  String get replyContentBlocked => 'Ce contenu ne peut pas être envoyé.';

  @override
  String get replyContentBlockedProfanity => 'Le langage inapproprié n\'est pas autorisé.';

  @override
  String get replyContentBlockedSexual => 'Le contenu sexuel est interdit.';

  @override
  String get replyContentBlockedHate => 'Les discours de haine sont interdits.';

  @override
  String get replyContentBlockedThreat => 'Le contenu menaçant est interdit.';

  @override
  String get composePermissionTitle => 'Autoriser l\'accès aux photos';

  @override
  String get composePermissionMessage => 'Ouvrez les réglages pour autoriser l\'accès aux photos.';

  @override
  String get composeOpenSettings => 'Ouvrir les réglages';

  @override
  String get commonClose => 'Fermer';

  @override
  String get journeyListTitle => 'Messages envoyés';

  @override
  String get sentTabInProgress => 'En cours';

  @override
  String get sentTabCompleted => 'Terminé';

  @override
  String inboxSentOngoingForwardedCountLabel(Object count) {
    return 'Envoyé à $count';
  }

  @override
  String inboxSentOngoingRespondedCountLabel(Object count) {
    return '$count ont répondu';
  }

  @override
  String get sentEmptyInProgressTitle => 'Aucun message en cours';

  @override
  String get sentEmptyInProgressDescription => 'Démarrez un nouveau message pour l\'afficher ici.';

  @override
  String get sentEmptyCompletedTitle => 'Aucun message terminé';

  @override
  String get sentEmptyCompletedDescription => 'Les messages terminés apparaîtront ici.';

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
  String get journeyInProgressHint => 'Vous pourrez voir les réponses après la fin';

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
  String get inboxTabPending => 'En attente';

  @override
  String get inboxTabCompleted => 'Répondu';

  @override
  String get inboxEmpty => 'Aucun message reçu pour le moment.';

  @override
  String get inboxEmptyPendingTitle => 'Aucun message en attente';

  @override
  String get inboxEmptyPendingDescription => 'Les nouveaux messages apparaîtront ici.';

  @override
  String get inboxEmptyCompletedTitle => 'Aucun message répondu';

  @override
  String get inboxEmptyCompletedDescription => 'Les messages auxquels vous avez répondu apparaîtront ici.';

  @override
  String get inboxCta => 'Voir la boîte de réception';

  @override
  String get inboxRefresh => 'Actualiser';

  @override
  String get inboxLoadFailed => 'Nous n\'avons pas pu charger votre boîte de réception.';

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
  String get inboxCardArrivedPrompt => 'Un message est arrivé !\nLaissez une réponse.';

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
  String get inboxBlockMessage => 'Bloquer cet utilisateur pour les prochains messages ?';

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
  String get inboxRespondLabel => 'Message';

  @override
  String get inboxRespondHint => 'Écrivez votre message...';

  @override
  String get inboxRespondCta => 'Envoyer le message';

  @override
  String get inboxRespondEmpty => 'Veuillez saisir un message.';

  @override
  String get inboxRespondConfirmTitle => 'Envoyer un message';

  @override
  String get inboxRespondConfirmMessage => 'Voulez-vous envoyer ce message?';

  @override
  String get inboxRespondSuccessTitle => 'Message envoyé';

  @override
  String get inboxRespondSuccessBody => 'Votre message a été envoyé.';

  @override
  String get inboxPassCta => 'Passer';

  @override
  String get inboxPassConfirmTitle => 'Confirmer le passage';

  @override
  String get inboxPassConfirmMessage => 'Êtes-vous sûr de vouloir passer ce message?';

  @override
  String get inboxPassConfirmAction => 'Passer';

  @override
  String get inboxPassSuccessTitle => 'Passé';

  @override
  String get inboxPassSuccessBody => 'Vous avez passé ce message.';

  @override
  String get inboxPassedTitle => 'Message passé';

  @override
  String get inboxPassedDetailUnavailable => 'Ce message a été passé et le contenu n\'est pas disponible.';

  @override
  String get inboxPassedMessageTitle => 'Ce message a été passé.';

  @override
  String get inboxRespondedMessageTitle => 'Vous avez répondu à ce message.';

  @override
  String get inboxRespondedDetailSectionTitle => 'Ma réponse';

  @override
  String get inboxRespondedDetailReplyUnavailable => 'Impossible de charger votre réponse.';

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
  String get inboxReportAlreadyReportedTitle => 'Déjà signalé';

  @override
  String get inboxReportAlreadyReportedBody => 'Vous avez déjà signalé ce message.';

  @override
  String get inboxActionFailed => 'Impossible d\'effectuer cette action.';

  @override
  String get actionReportMessage => 'Signaler le message';

  @override
  String get actionBlockSender => 'Bloquer l\'expéditeur';

  @override
  String get inboxDetailMoreTitle => 'Options';

  @override
  String get journeyDetailTitle => 'Message';

  @override
  String get journeyDetailMessageLabel => 'Message';

  @override
  String get journeyDetailMessageUnavailable => 'Impossible de charger le message.';

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
  String get journeyDetailResultsTitle => 'Réponses';

  @override
  String get journeyDetailResultsLocked => 'Les réponses apparaîtront après la fin.';

  @override
  String get journeyDetailResultsEmpty => 'Aucune réponse pour le moment.';

  @override
  String get journeyDetailResultsLoadFailed => 'Impossible de charger les réponses.';

  @override
  String get commonTemporaryErrorTitle => 'Erreur temporaire';

  @override
  String get sentDetailRepliesLoadFailedMessage => 'Impossible de charger les réponses.\nRetour à la liste.';

  @override
  String get commonOk => 'OK';

  @override
  String get journeyDetailResponsesMissingTitle => 'Erreur temporaire';

  @override
  String get journeyDetailResponsesMissingBody => 'Impossible de charger les réponses. Veuillez réessayer.\nRetour à la liste.';

  @override
  String get journeyDetailGateConfigTitle => 'Publicité non prête';

  @override
  String get journeyDetailGateConfigBody => 'La publicité n\'est pas configurée. Nous ouvrons les détails sans publicité.';

  @override
  String get journeyDetailGateDismissedTitle => 'Publicité non terminée';

  @override
  String get journeyDetailGateDismissedBody => 'Regardez la publicité jusqu\'au bout pour voir les détails.';

  @override
  String get journeyDetailGateFailedTitle => 'Publicité indisponible';

  @override
  String get journeyDetailGateFailedBody => 'Impossible de charger la publicité. Veuillez réessayer.';

  @override
  String get journeyDetailUnlockFailedTitle => 'Échec de l’enregistrement du déverrouillage';

  @override
  String get journeyDetailUnlockFailedBody => 'Impossible d’enregistrer le déverrouillage à cause d’un problème réseau/serveur. Veuillez réessayer.';

  @override
  String get journeyDetailGateDialogTitle => 'Déverrouiller avec une pub récompensée';

  @override
  String get journeyDetailGateDialogBody => 'Déverrouillez en regardant une pub récompensée.\nUne seule fois suffit pour déverrouiller à vie.';

  @override
  String get journeyDetailGateDialogConfirm => 'Déverrouiller';

  @override
  String get journeyDetailLoadFailed => 'Impossible de charger la progression.';

  @override
  String get journeyDetailRetry => 'Réessayer';

  @override
  String get journeyDetailAdRequired => 'Regardez une pub pour voir les résultats.';

  @override
  String get journeyDetailAdCta => 'Voir la pub et débloquer';

  @override
  String get journeyDetailAdFailedTitle => 'Pub indisponible';

  @override
  String get journeyDetailAdFailedBody => 'Impossible de charger la pub. Voir les résultats quand même ?';

  @override
  String get journeyDetailAdFailedConfirm => 'Voir les résultats';

  @override
  String get journeyResultReportCta => 'Signaler la réponse';

  @override
  String get journeyResultReportSuccessTitle => 'Signalement envoyé';

  @override
  String get journeyResultReportSuccessBody => 'Votre signalement a été envoyé.';

  @override
  String get journeyResultReportFailed => 'Impossible d\'envoyer le signalement.';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsSectionNotification => 'Notifications';

  @override
  String get settingsNotificationToggle => 'Autoriser les notifications';

  @override
  String get settingsNotificationHint => 'Recevez les mises à jour et résultats.';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsSectionSafety => 'Sécurité';

  @override
  String get settingsBlockedUsers => 'Utilisateurs bloqués';

  @override
  String get settingsLoadFailed => 'Impossible de charger les réglages.';

  @override
  String get settingsUpdateFailed => 'Impossible de mettre à jour les réglages.';

  @override
  String get blockListTitle => 'Utilisateurs bloqués';

  @override
  String get blockListEmpty => 'Aucun utilisateur bloqué.';

  @override
  String get blockListUnknownUser => 'Utilisateur inconnu';

  @override
  String get blockListLoadFailed => 'Impossible de charger la liste de blocage.';

  @override
  String get blockListUnblock => 'Débloquer';

  @override
  String get blockListUnblockTitle => 'Débloquer l\'utilisateur';

  @override
  String get blockListUnblockMessage => 'Autoriser de nouveau les messages de cet utilisateur ?';

  @override
  String get blockListUnblockConfirm => 'Débloquer';

  @override
  String get blockListUnblockFailed => 'Impossible de débloquer l\'utilisateur.';

  @override
  String get blockUnblockedTitle => 'Terminé';

  @override
  String get blockUnblockedMessage => 'Utilisateur débloqué.';

  @override
  String get onboardingTitle => 'Démarrage';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return 'Étape $current sur $total';
  }

  @override
  String get onboardingNotificationTitle => 'Autorisation des notifications';

  @override
  String get onboardingNotificationDescription => 'Nous vous informerons de l\'arrivée des messages relais et de la disponibilité des résultats.';

  @override
  String get onboardingNotificationNote => 'Vous pouvez modifier ceci à tout moment dans Réglages. Cette étape est facultative.';

  @override
  String get onboardingAllowNotifications => 'Autoriser';

  @override
  String get onboardingPhotoTitle => 'Accès aux photos';

  @override
  String get onboardingPhotoDescription => 'Utilisé uniquement pour définir des images de profil et joindre des images aux messages.';

  @override
  String get onboardingPhotoNote => 'Nous n\'accédons qu\'aux photos que vous sélectionnez. Cette étape est facultative.';

  @override
  String get onboardingAllowPhotos => 'Autoriser';

  @override
  String get onboardingGuidelineTitle => 'Règles de la communauté';

  @override
  String get onboardingGuidelineDescription => 'Pour une utilisation sûre, le harcèlement, les discours haineux et le partage d\'informations personnelles sont interdits. Les violations peuvent entraîner des restrictions de contenu.';

  @override
  String get onboardingAgreeGuidelines => 'J\'accepte les règles de la communauté.';

  @override
  String get onboardingContentPolicyTitle => 'Politique de contenu';

  @override
  String get onboardingContentPolicyDescription => 'Le contenu illégal, nuisible et violent est interdit. Le contenu en violation peut être restreint après examen.';

  @override
  String get onboardingAgreeContentPolicy => 'J\'accepte la politique de contenu.';

  @override
  String get onboardingSafetyTitle => 'Signaler et bloquer';

  @override
  String get onboardingSafetyDescription => 'Vous pouvez signaler du contenu offensant ou inapproprié, ou bloquer des utilisateurs spécifiques pour ne plus recevoir leurs messages.';

  @override
  String get onboardingConfirmSafety => 'Je comprends la politique de signalement et de blocage.';

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
  String get noticeTitle => 'Actualités';

  @override
  String get noticeDetailTitle => 'Actualités';

  @override
  String get noticeFilterLabel => 'Type d’actualité';

  @override
  String get noticeFilterAll => 'Tout';

  @override
  String get noticeFilterSheetTitle => 'Sélectionner un type';

  @override
  String get noticeTypeUnknown => 'Inconnu';

  @override
  String get noticePinnedBadge => 'Épinglé';

  @override
  String get noticeEmptyTitle => 'Aucune actualité';

  @override
  String get noticeEmptyDescription => 'Il n’y a pas d’actualité pour ce type.';

  @override
  String get noticeErrorTitle => 'Impossible de charger les actualités';

  @override
  String get noticeErrorDescription => 'Veuillez réessayer plus tard.';

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
  String get profileEditCta => 'Modifier le profil';

  @override
  String get authProviderKakaoLogin => 'Connexion Kakao';

  @override
  String get authProviderGoogleLogin => 'Connexion Google';

  @override
  String get authProviderAppleLogin => 'Connexion Apple';

  @override
  String get authProviderUnknownLogin => 'Connecté';

  @override
  String get profileLoginProviderKakao => 'Connexion Kakao';

  @override
  String get profileLoginProviderGoogle => 'Connexion Google';

  @override
  String get profileLoginProviderApple => 'Connexion Apple';

  @override
  String get profileLoginProviderEmail => 'Connexion e-mail';

  @override
  String get profileLoginProviderUnknown => 'Connecté';

  @override
  String get profileAppSettings => 'Paramètres de l\'app';

  @override
  String get profileMenuNotices => 'Annonces';

  @override
  String get profileMenuSupport => 'Support';

  @override
  String get profileMenuAppInfo => 'Infos sur l’app';

  @override
  String get profileMenuTitle => 'Menu';

  @override
  String get profileMenuSubtitle => 'Accès rapide aux réglages courants.';

  @override
  String get profileWithdrawCta => 'Supprimer le compte';

  @override
  String get profileWithdrawTitle => 'Supprimer le compte';

  @override
  String get profileWithdrawMessage => 'Voulez-vous supprimer votre compte ? Cette action est irréversible.';

  @override
  String get profileWithdrawConfirm => 'Supprimer';

  @override
  String get profileFeaturePreparingTitle => 'Bientôt disponible';

  @override
  String get profileFeaturePreparingBody => 'Cette fonctionnalité n’est pas encore disponible.';

  @override
  String get profileAvatarSemantics => 'Avatar de profil';

  @override
  String get supportTitle => 'Support';

  @override
  String get supportStatusMessage => 'Votre application est à jour.';

  @override
  String get supportReleaseNotesTitle => 'Notes de version';

  @override
  String supportReleaseNotesHeader(Object version) {
    return 'Dernière version $version - nouveautés';
  }

  @override
  String get supportReleaseNotesBody => '• Amélioration de l’expérience et de la stabilité.\n• Optimisation du thème sombre pour le profil et le support.\n• Corrections mineures et performances améliorées.';

  @override
  String get supportVersionUnknown => 'Inconnue';

  @override
  String get supportSuggestCta => 'Envoyer une suggestion';

  @override
  String get supportReportCta => 'Signaler un problème';

  @override
  String get supportFaqTitle => 'FAQ';

  @override
  String get supportFaqSubtitle => 'Consultez les questions fréquentes.';

  @override
  String get supportFaqQ1 => 'Les messages ne semblent pas être livrés. Pourquoi ?';

  @override
  String get supportFaqA1 => 'La livraison peut être retardée ou restreinte en raison de l\'état du réseau, de retards temporaires du serveur ou de politiques de sécurité (signalements/blocages, etc.). Veuillez réessayer plus tard.';

  @override
  String get supportFaqQ2 => 'Je ne reçois pas de notifications. Que dois-je faire ?';

  @override
  String get supportFaqA2 => 'Les permissions de notification d\'Echowander peuvent être désactivées dans les paramètres de votre téléphone. Allez dans Paramètres de l\'app → Paramètres de l\'app (Paramètres de notification) pour activer les permissions de notification et vérifiez également les restrictions d\'économie de batterie/arrière-plan.';

  @override
  String get supportFaqQ3 => 'J\'ai reçu un message désagréable. Comment bloquer/signaler ?';

  @override
  String get supportFaqA3 => 'Vous pouvez sélectionner Signaler ou Bloquer depuis l\'écran du message. Le blocage empêche de recevoir d\'autres messages de cet utilisateur. Le contenu signalé peut être examiné pour la sécurité de la communauté.';

  @override
  String get supportFaqQ4 => 'Puis-je modifier ou annuler un message que j\'ai envoyé ?';

  @override
  String get supportFaqA4 => 'Une fois envoyé, les messages ne peuvent pas être facilement modifiés ou annulés. Veuillez vérifier le contenu avant d\'envoyer.';

  @override
  String get supportFaqQ5 => 'Que se passe-t-il si je viole les directives de la communauté ?';

  @override
  String get supportFaqA5 => 'Les violations répétées peuvent entraîner des restrictions de messages ou des limitations de compte. Veuillez suivre les directives pour une communauté sûre.';

  @override
  String get supportActionPreparingTitle => 'Bientôt disponible';

  @override
  String get supportActionPreparingBody => 'Cette action sera disponible prochainement.';

  @override
  String get supportSuggestionSubject => 'Demande de suggestion';

  @override
  String get supportBugSubject => 'Signalement d\'erreur';

  @override
  String supportEmailFooterUser(String userId) {
    return 'Utilisateur : $userId';
  }

  @override
  String supportEmailFooterVersion(String version) {
    return 'Version de l\'app : $version';
  }

  @override
  String get supportEmailLaunchFailed => 'Impossible d\'ouvrir l\'application de messagerie. Veuillez réessayer plus tard.';

  @override
  String get appInfoTitle => 'Infos sur l’app';

  @override
  String get appInfoSettingsTitle => 'Réglages de l’app';

  @override
  String get appInfoSettingsSubtitle => 'Consultez les licences et politiques.';

  @override
  String get appInfoSectionTitle => 'Services connectés';

  @override
  String get appInfoSectionSubtitle => 'Voir les apps liées au service.';

  @override
  String appInfoVersionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get appInfoVersionUnknown => 'Inconnue';

  @override
  String get appInfoOpenLicenseTitle => 'Licences ouvertes';

  @override
  String get appInfoRelatedAppsTitle => 'Apps liées BIZPECT';

  @override
  String get appInfoRelatedApp1Title => 'Application test 1';

  @override
  String get appInfoRelatedApp1Description => 'Application d’exemple pour tester les services liés.';

  @override
  String get appInfoRelatedApp2Title => 'Application test 2';

  @override
  String get appInfoRelatedApp2Description => 'Autre application d’exemple pour les intégrations liées.';

  @override
  String get appInfoExternalLinkLabel => 'Ouvrir un lien externe';

  @override
  String get appInfoLinkPreparingTitle => 'Bientôt disponible';

  @override
  String get appInfoLinkPreparingBody => 'Ce lien sera disponible prochainement.';

  @override
  String get openLicenseTitle => 'Licences ouvertes';

  @override
  String get openLicenseHeaderTitle => 'Bibliothèques open source';

  @override
  String get openLicenseHeaderBody => 'Cette application utilise les bibliothèques open source suivantes.';

  @override
  String get openLicenseSectionTitle => 'Liste des licences';

  @override
  String get openLicenseSectionSubtitle => 'Consultez les paquets open source utilisés.';

  @override
  String openLicenseChipVersion(Object version) {
    return 'Version : $version';
  }

  @override
  String openLicenseChipLicense(Object license) {
    return 'Licence : $license';
  }

  @override
  String get openLicenseChipDetails => 'Détails';

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
  String get openLicenseTypeUnknown => 'Inconnue';

  @override
  String get openLicenseUnknown => 'Inconnue';

  @override
  String get openLicenseEmptyMessage => 'Aucune information de licence disponible.';

  @override
  String openLicenseDetailTitle(Object package) {
    return 'Licence de $package';
  }

  @override
  String get journeyDetailAnonymous => 'Anonyme';

  @override
  String get errorNetwork => 'Veuillez vérifier votre connexion réseau.';

  @override
  String get errorTimeout => 'Délai d\'attente dépassé. Veuillez réessayer.';

  @override
  String get errorServerUnavailable => 'Le serveur est temporairement indisponible. Veuillez réessayer plus tard.';

  @override
  String get errorUnauthorized => 'Veuillez vous reconnecter.';

  @override
  String get errorRetry => 'Réessayer';

  @override
  String get errorCancel => 'Annuler';

  @override
  String get errorAuthRefreshFailed => 'Le réseau est instable. Veuillez réessayer dans un moment.';

  @override
  String get homeInboxSummaryTitle => 'Résumé du jour';

  @override
  String get homeInboxSummaryPending => 'En attente';

  @override
  String get homeInboxSummaryCompleted => 'Répondu';

  @override
  String get homeInboxSummarySentResponses => 'Réponses reçues';

  @override
  String homeInboxSummaryUpdatedAt(Object time) {
    return 'Mis à jour $time';
  }

  @override
  String get homeInboxSummaryRefresh => 'Actualiser';

  @override
  String get homeInboxSummaryLoadFailed => 'Impossible de charger le résumé.';

  @override
  String homeInboxSummaryItemSemantics(Object label, Object count) {
    return '$label $count';
  }

  @override
  String get homeTimelineTitle => 'Activité récente';

  @override
  String get homeTimelineEmptyTitle => 'Aucune activité récente';

  @override
  String get homeTimelineReceivedTitle => 'Nouveau message reçu';

  @override
  String get homeTimelineRespondedTitle => 'Réponse envoyée';

  @override
  String get homeTimelineSentResponseTitle => 'Réponse reçue';

  @override
  String homeTimelineSubtitle(Object time) {
    return '$time';
  }

  @override
  String get homeDailyPromptTitle => 'Question du jour';

  @override
  String get homeDailyPromptHint => 'Touchez pour écrire un message';

  @override
  String get homeDailyPromptAction => 'Écrire';

  @override
  String get homeAnnouncementTitle => 'Mise à jour';

  @override
  String get homeAnnouncementSummary => 'Découvrez les nouveautés d\'Echowander.';

  @override
  String get homeAnnouncementAction => 'Détails';

  @override
  String get homeAnnouncementDetailTitle => 'Mise à jour';

  @override
  String get homeAnnouncementDetailBody => 'Nous avons apporté des améliorations pour une expérience plus fluide.';

  @override
  String get homePromptQ1 => 'Qu\'est-ce qui t\'a fait sourire aujourd\'hui ?';

  @override
  String get homePromptQ2 => 'Qu\'attends-tu avec impatience cette semaine ?';

  @override
  String get homePromptQ3 => 'Quel endroit veux-tu revisiter ?';

  @override
  String get homePromptQ4 => 'Partage une petite victoire d\'aujourd\'hui.';

  @override
  String get homePromptQ5 => 'Quelle habitude aimerais-tu prendre ?';

  @override
  String get homePromptQ6 => 'À qui veux-tu dire merci aujourd\'hui ?';

  @override
  String get homePromptQ7 => 'Quelle chanson écoutes-tu en boucle ?';

  @override
  String get homePromptQ8 => 'Décris ta journée en trois mots.';

  @override
  String get homePromptQ9 => 'Qu\'as-tu appris récemment ?';

  @override
  String get homePromptQ10 => 'Si tu pouvais t\'envoyer un message, que dirais-tu ?';

  @override
  String get profileEditTitle => 'Modifier le profil';

  @override
  String get profileEditNicknameLabel => 'Pseudonyme';

  @override
  String get profileEditNicknameHint => 'Entrez un pseudonyme';

  @override
  String get profileEditNicknameEmpty => 'Veuillez entrer un pseudonyme';

  @override
  String profileEditNicknameTooShort(Object min) {
    return 'Le pseudonyme doit contenir au moins $min caractères';
  }

  @override
  String profileEditNicknameTooLong(Object max) {
    return 'Le pseudonyme peut contenir jusqu\'à $max caractères';
  }

  @override
  String get profileEditNicknameConsecutiveSpaces => 'Les espaces consécutifs ne sont pas autorisés';

  @override
  String get profileEditNicknameInvalidCharacters => 'Seuls le coréen, l\'anglais, les chiffres et le tiret bas (_) sont autorisés';

  @override
  String get profileEditNicknameUnderscoreAtEnds => 'Underscore (_) cannot be used at the beginning or end';

  @override
  String get profileEditNicknameConsecutiveUnderscores => 'Consecutive underscores (__) are not allowed';

  @override
  String get profileEditNicknameForbidden => 'This nickname is not allowed';

  @override
  String get profileEditNicknameChecking => 'Vérification...';

  @override
  String get profileEditNicknameAvailable => 'Ce pseudonyme est disponible';

  @override
  String get profileEditNicknameTaken => 'Ce pseudonyme est déjà utilisé';

  @override
  String get profileEditNicknameError => 'Une erreur s\'est produite lors de la vérification';

  @override
  String get profileEditAvatarLabel => 'Photo de profil';

  @override
  String get profileEditAvatarChange => 'Changer la photo';

  @override
  String get profileEditSave => 'Enregistrer';

  @override
  String get profileEditCancel => 'Annuler';

  @override
  String get profileEditSaveSuccess => 'Profil enregistré avec succès';

  @override
  String get profileEditSaveFailed => 'Échec de l\'enregistrement. Veuillez réessayer';

  @override
  String get profileEditImageTooLarge => 'Image file is too large. Please select another image';

  @override
  String get profileEditImageOptimizationFailed => 'An error occurred while processing the image. Please try again';

  @override
  String get profileEditCropTitle => 'Modifier la photo';

  @override
  String get profileEditCropDescription => 'Ajustez la position comme vous le souhaitez';

  @override
  String get profileEditCropCancel => 'Annuler';

  @override
  String get profileEditCropComplete => 'Terminer';

  @override
  String get profileEditCropFailedTitle => 'Échec de l\'édition de la photo';

  @override
  String get profileEditCropFailedMessage => 'Une erreur s\'est produite lors de l\'édition de la photo. Veuillez réessayer.';

  @override
  String get profileEditCropFailedAction => 'OK';
}
