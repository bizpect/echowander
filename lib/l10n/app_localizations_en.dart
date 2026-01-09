// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EchoWander';

  @override
  String get splashTitle => 'Starting up...';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginDescription => 'Start your anonymous relay message';

  @override
  String get loginKakao => 'Continue with Kakao';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginApple => 'Continue with Apple';

  @override
  String get loginTerms =>
      'By signing in, you agree to our Terms of Service and Privacy Policy';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeGreeting => 'Welcome back';

  @override
  String get homeRecentJourneysTitle => 'Recent Messages';

  @override
  String get homeActionsTitle => 'Get Started';

  @override
  String get homeEmptyTitle => 'Welcome to EchoWander';

  @override
  String get homeEmptyDescription =>
      'Send your first relay message or check your inbox.';

  @override
  String get homeInboxCardTitle => 'Inbox';

  @override
  String get homeInboxCardDescription =>
      'Check and reply to messages you\'ve received.';

  @override
  String get homeCreateCardTitle => 'Create Message';

  @override
  String get homeCreateCardDescription => 'Start a new relay message.';

  @override
  String get homeJourneyCardViewDetails => 'View details';

  @override
  String get homeRefresh => 'Refresh';

  @override
  String get homeLoadFailed => 'We couldn\'t load your data.';

  @override
  String homeInboxCount(Object count) {
    return '$count new';
  }

  @override
  String get settingsCta => 'Settings';

  @override
  String get settingsNotificationInbox => 'Notification inbox';

  @override
  String get pushPreviewTitle => 'Notification';

  @override
  String get pushPreviewDescription =>
      'This is a preview screen for push deep links.';

  @override
  String get notificationTitle => 'New message';

  @override
  String get notificationOpen => 'Open';

  @override
  String get notificationDismiss => 'Dismiss';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsUnreadOnly => 'Show unread only';

  @override
  String get notificationsRead => 'Read';

  @override
  String get notificationsUnread => 'New';

  @override
  String get notificationsDeleteTitle => 'Delete notification';

  @override
  String get notificationsDeleteMessage =>
      'Remove this notification from your inbox?';

  @override
  String get notificationsDeleteConfirm => 'Delete';

  @override
  String get pushJourneyAssignedTitle => 'New message';

  @override
  String get pushJourneyAssignedBody => 'A new relay message has arrived.';

  @override
  String get pushJourneyResultTitle => 'Result ready';

  @override
  String get pushJourneyResultBody => 'Your relay result is ready.';

  @override
  String get errorTitle => 'Notice';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorLoginFailed => 'Login failed. Please try again.';

  @override
  String get errorLoginCancelled => 'Login was cancelled.';

  @override
  String get errorLoginNetwork =>
      'Please check your network connection and try again.';

  @override
  String get errorLoginInvalidToken =>
      'Login verification failed. Please try again.';

  @override
  String get errorLoginUnsupportedProvider =>
      'This sign-in method is not supported.';

  @override
  String get errorLoginUserSyncFailed =>
      'We couldn\'t save your account. Please try again.';

  @override
  String get errorLoginServiceUnavailable =>
      'Sign-in is temporarily unavailable. Please try again later.';

  @override
  String get errorSessionExpired =>
      'Your session expired. Please sign in again.';

  @override
  String get errorForbiddenTitle => 'Permission Required';

  @override
  String get errorForbiddenMessage =>
      'You don\'t have permission to perform this action. Please check your login status or try again later.';

  @override
  String get journeyInboxForbiddenTitle => 'Cannot Load Inbox';

  @override
  String get journeyInboxForbiddenMessage =>
      'You don\'t have permission to view the inbox. If the problem persists, please sign in again.';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageKorean => 'Korean';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageFrench => 'French';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get languageChinese => 'Chinese';

  @override
  String get composeTitle => 'Write a message';

  @override
  String get composeWizardStep1Title => 'What will your journey say?';

  @override
  String get composeWizardStep1Subtitle =>
      'Write a short hook to start the relay.';

  @override
  String get composeWizardStep2Title => 'How many people should it reach?';

  @override
  String get composeWizardStep2Subtitle => 'Pick 1 to 5 recipients.';

  @override
  String get composeWizardStep3Title => 'Add a photo? (optional)';

  @override
  String get composeWizardStep3Subtitle =>
      'Attach up to 3 photos, or send without one.';

  @override
  String get composeWizardBack => 'Back';

  @override
  String get composeWizardNext => 'Next';

  @override
  String get composeLabel => 'Message';

  @override
  String get composeHint => 'Share your thoughts...';

  @override
  String composeCharacterCount(Object current, Object total) {
    return '$current/$total';
  }

  @override
  String get composeImagesTitle => 'Images';

  @override
  String get composeAddImage => 'Add photo';

  @override
  String get composeSubmit => 'Send';

  @override
  String get composeCta => 'Write a message';

  @override
  String get composeTooLong => 'Message is too long.';

  @override
  String get composeForbidden => 'Remove URLs or contact info.';

  @override
  String get composeEmpty => 'Please enter a message.';

  @override
  String get composeInvalid => 'Please fix the message content.';

  @override
  String get composeImageLimit => 'You can attach up to 3 images.';

  @override
  String get composePermissionDenied =>
      'Photo access is needed to attach images.';

  @override
  String get composeSessionMissing => 'Please sign in again.';

  @override
  String get composeSubmitFailed =>
      'We couldn\'t send your message. Try again.';

  @override
  String get composeServerMisconfigured =>
      'Service setup is not ready yet. Please try again later.';

  @override
  String get composeSubmitSuccess => 'Your message was sent.';

  @override
  String get composeRecipientCountLabel => 'Relay count';

  @override
  String get composeRecipientCountHint => 'Select 1 to 5 people.';

  @override
  String composeRecipientCountOption(Object count) {
    return '$count people';
  }

  @override
  String get composeRecipientRequired => 'Select how many people to relay to.';

  @override
  String get composeRecipientInvalid =>
      'You can select between 1 and 5 people.';

  @override
  String get composeErrorTitle => 'Notice';

  @override
  String get composeSuccessTitle => 'Done';

  @override
  String get composeOk => 'OK';

  @override
  String get composeCancel => 'Cancel';

  @override
  String get composePermissionTitle => 'Allow photo access';

  @override
  String get composePermissionMessage => 'Open Settings to allow photo access.';

  @override
  String get composeOpenSettings => 'Open settings';

  @override
  String get journeyListTitle => 'Sent Messages';

  @override
  String get journeyListEmpty => 'No messages yet.';

  @override
  String get journeyListCta => 'View sent messages';

  @override
  String get journeyListStatusLabel => 'Status:';

  @override
  String get journeyStatusCreated => 'Sent';

  @override
  String get journeyStatusWaiting => 'Waiting for match';

  @override
  String get journeyStatusCompleted => 'Completed';

  @override
  String get journeyStatusInProgress => 'In Progress';

  @override
  String get journeyStatusUnknown => 'Unknown';

  @override
  String get journeyInProgressHint => 'You can view responses after completion';

  @override
  String get journeyFilterOk => 'Allowed';

  @override
  String get journeyFilterHeld => 'Held';

  @override
  String get journeyFilterRemoved => 'Removed';

  @override
  String get journeyFilterUnknown => 'Unknown';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxEmpty => 'No messages received yet.';

  @override
  String get inboxCta => 'View inbox';

  @override
  String get inboxRefresh => 'Refresh';

  @override
  String get inboxLoadFailed => 'We couldn\'t load your inbox.';

  @override
  String inboxImageCount(Object count) {
    return '$count photo(s)';
  }

  @override
  String get inboxStatusLabel => 'Status:';

  @override
  String get inboxStatusAssigned => 'Waiting';

  @override
  String get inboxStatusResponded => 'Responded';

  @override
  String get inboxStatusPassed => 'Passed';

  @override
  String get inboxStatusReported => 'Reported';

  @override
  String get inboxStatusUnknown => 'Unknown';

  @override
  String get inboxDetailTitle => 'Inbox';

  @override
  String get inboxDetailMissing => 'We couldn\'t load this message.';

  @override
  String get inboxImagesLabel => 'Photos';

  @override
  String get inboxImagesLoadFailed => 'We couldn\'t load the photos.';

  @override
  String get inboxBlockCta => 'Block sender';

  @override
  String get inboxBlockTitle => 'Block user';

  @override
  String get inboxBlockMessage => 'Block this user from future relay messages?';

  @override
  String get inboxBlockConfirm => 'Block';

  @override
  String get inboxBlockSuccessTitle => 'Blocked';

  @override
  String get inboxBlockSuccessBody => 'The user has been blocked.';

  @override
  String get inboxBlockFailed => 'We couldn\'t block this user.';

  @override
  String get inboxBlockMissing => 'We couldn\'t identify the sender.';

  @override
  String get inboxRespondLabel => 'Reply';

  @override
  String get inboxRespondHint => 'Write your reply...';

  @override
  String get inboxRespondCta => 'Send reply';

  @override
  String get inboxRespondEmpty => 'Please enter a reply.';

  @override
  String get inboxRespondSuccessTitle => 'Reply sent';

  @override
  String get inboxRespondSuccessBody => 'Your reply was sent.';

  @override
  String get inboxPassCta => 'Pass';

  @override
  String get inboxPassSuccessTitle => 'Passed';

  @override
  String get inboxPassSuccessBody => 'You\'ve passed this message.';

  @override
  String get inboxPassedTitle => 'Passed message';

  @override
  String get inboxPassedDetailUnavailable =>
      'This message was passed and content is unavailable.';

  @override
  String get inboxReportCta => 'Report';

  @override
  String get inboxReportTitle => 'Report reason';

  @override
  String get inboxReportSpam => 'Spam';

  @override
  String get inboxReportAbuse => 'Abuse';

  @override
  String get inboxReportOther => 'Other';

  @override
  String get inboxReportSuccessTitle => 'Reported';

  @override
  String get inboxReportSuccessBody => 'Your report was submitted.';

  @override
  String get inboxActionFailed => 'We couldn\'t complete this action.';

  @override
  String get journeyDetailTitle => 'Message';

  @override
  String get journeyDetailMessageLabel => 'Message';

  @override
  String get journeyDetailMessageUnavailable => 'Message unavailable.';

  @override
  String get journeyDetailProgressTitle => 'Relay progress';

  @override
  String get journeyDetailStatusLabel => 'Status';

  @override
  String get journeyDetailDeadlineLabel => 'Relay deadline';

  @override
  String get journeyDetailResponseTargetLabel => 'Target replies';

  @override
  String get journeyDetailRespondedLabel => 'Replies';

  @override
  String get journeyDetailAssignedLabel => 'Assigned';

  @override
  String get journeyDetailPassedLabel => 'Passed';

  @override
  String get journeyDetailReportedLabel => 'Reported';

  @override
  String get journeyDetailCountriesLabel => 'Relay locations';

  @override
  String get journeyDetailCountriesEmpty => 'No locations yet.';

  @override
  String get journeyDetailResultsTitle => 'Replies';

  @override
  String get journeyDetailResultsLocked =>
      'Replies will appear after completion.';

  @override
  String get journeyDetailResultsEmpty => 'No replies yet.';

  @override
  String get journeyDetailResultsLoadFailed => 'We couldn\'t load the replies.';

  @override
  String get commonTemporaryErrorTitle => 'Temporary error';

  @override
  String get sentDetailRepliesLoadFailedMessage =>
      'We couldn\'t load the replies. We\'ll return to the list.';

  @override
  String get commonOk => 'OK';

  @override
  String get journeyDetailResponsesMissingTitle => 'Temporary error';

  @override
  String get journeyDetailResponsesMissingBody =>
      'We couldn\'t load the responses. Please try again.\nWe\'ll return to the list.';

  @override
  String get journeyDetailGateConfigTitle => 'Ad not ready';

  @override
  String get journeyDetailGateConfigBody =>
      'Ads aren\'t configured yet. We\'ll open the details without an ad.';

  @override
  String get journeyDetailGateDismissedTitle => 'Ad not completed';

  @override
  String get journeyDetailGateDismissedBody =>
      'Please watch the ad to view details.';

  @override
  String get journeyDetailGateFailedTitle => 'Ad unavailable';

  @override
  String get journeyDetailGateFailedBody =>
      'We couldn\'t load the ad. Please try again.';

  @override
  String get journeyDetailUnlockFailedTitle => 'Unlock failed';

  @override
  String get journeyDetailUnlockFailedBody =>
      'We couldn\'t save the unlock due to a network or server issue. Please try again.';

  @override
  String get journeyDetailGateDialogTitle => 'Unlock with a reward ad';

  @override
  String get journeyDetailGateDialogBody =>
      'Unlock by watching a reward ad.\nWatch once to unlock forever.';

  @override
  String get journeyDetailGateDialogConfirm => 'Unlock';

  @override
  String get journeyDetailLoadFailed => 'We couldn\'t load the progress.';

  @override
  String get journeyDetailRetry => 'Retry';

  @override
  String get journeyDetailAdRequired => 'Watch a reward ad to view results.';

  @override
  String get journeyDetailAdCta => 'Watch ad and unlock';

  @override
  String get journeyDetailAdFailedTitle => 'Ad unavailable';

  @override
  String get journeyDetailAdFailedBody =>
      'We couldn\'t load the ad. View results anyway?';

  @override
  String get journeyDetailAdFailedConfirm => 'View results';

  @override
  String get journeyResultReportCta => 'Report reply';

  @override
  String get journeyResultReportSuccessTitle => 'Reported';

  @override
  String get journeyResultReportSuccessBody => 'Your report was submitted.';

  @override
  String get journeyResultReportFailed => 'We couldn\'t submit your report.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionNotification => 'Notifications';

  @override
  String get settingsNotificationToggle => 'Allow notifications';

  @override
  String get settingsNotificationHint => 'Receive relay updates and results.';

  @override
  String get settingsSectionSafety => 'Safety';

  @override
  String get settingsBlockedUsers => 'Blocked users';

  @override
  String get settingsLoadFailed => 'We couldn\'t load settings.';

  @override
  String get settingsUpdateFailed => 'We couldn\'t update settings.';

  @override
  String get blockListTitle => 'Blocked users';

  @override
  String get blockListEmpty => 'No blocked users.';

  @override
  String get blockListUnknownUser => 'Unknown user';

  @override
  String get blockListLoadFailed => 'We couldn\'t load the block list.';

  @override
  String get blockListUnblock => 'Unblock';

  @override
  String get blockListUnblockTitle => 'Unblock user';

  @override
  String get blockListUnblockMessage => 'Allow messages from this user again?';

  @override
  String get blockListUnblockConfirm => 'Unblock';

  @override
  String get blockListUnblockFailed => 'We couldn\'t unblock this user.';

  @override
  String get onboardingTitle => 'Onboarding';

  @override
  String onboardingStepCounter(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingNotificationTitle => 'Notification permission';

  @override
  String get onboardingNotificationDescription =>
      'We\'ll notify you when relay messages arrive and results are ready.';

  @override
  String get onboardingNotificationNote =>
      'You can change this anytime in Settings. This step is optional.';

  @override
  String get onboardingAllowNotifications => 'Allow';

  @override
  String get onboardingPhotoTitle => 'Photo access';

  @override
  String get onboardingPhotoDescription =>
      'Used only for setting profile images and attaching images to messages.';

  @override
  String get onboardingPhotoNote =>
      'We only access photos you select. This step is optional.';

  @override
  String get onboardingAllowPhotos => 'Allow';

  @override
  String get onboardingGuidelineTitle => 'Community guidelines';

  @override
  String get onboardingGuidelineDescription =>
      'For safe use, harassment, hate speech, and sharing personal information are prohibited. Violations may result in content restrictions.';

  @override
  String get onboardingAgreeGuidelines =>
      'I agree to the community guidelines.';

  @override
  String get onboardingContentPolicyTitle => 'Content policy';

  @override
  String get onboardingContentPolicyDescription =>
      'Illegal, harmful, and violent content is prohibited. Violating content may be restricted after review.';

  @override
  String get onboardingAgreeContentPolicy => 'I agree to the content policy.';

  @override
  String get onboardingSafetyTitle => 'Report and block';

  @override
  String get onboardingSafetyDescription =>
      'You can report offensive or inappropriate content, or block specific users to stop receiving their messages.';

  @override
  String get onboardingConfirmSafety =>
      'I understand the report and block policy.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingAgreeAndDisagree => 'Agree and Disagree';

  @override
  String get onboardingPrevious => 'Previous';

  @override
  String get ctaPermissionChoice => 'Choose Permission';

  @override
  String get onboardingExitTitle => 'Exit onboarding?';

  @override
  String get onboardingExitMessage => 'You can start again later.';

  @override
  String get onboardingExitConfirm => 'Exit';

  @override
  String get onboardingExitCancel => 'Continue';

  @override
  String get exitConfirmTitle => 'Cancel writing?';

  @override
  String get exitConfirmMessage => 'Your input will be lost.';

  @override
  String get exitConfirmContinue => 'Keep writing';

  @override
  String get exitConfirmLeave => 'Leave';

  @override
  String get tabHomeLabel => 'Home';

  @override
  String get tabSentLabel => 'Sent';

  @override
  String get tabInboxLabel => 'Inbox';

  @override
  String get tabCreateLabel => 'Create message';

  @override
  String get tabAlertsLabel => 'Notifications';

  @override
  String get tabProfileLabel => 'Profile';

  @override
  String get profileSignOutCta => 'Sign out';

  @override
  String get profileSignOutTitle => 'Sign out';

  @override
  String get profileSignOutMessage => 'Are you sure you want to sign out?';

  @override
  String get profileSignOutConfirm => 'Sign out';

  @override
  String get profileUserIdLabel => 'User ID';

  @override
  String get profileDefaultNickname => 'User';

  @override
  String get journeyDetailAnonymous => 'Anonymous';

  @override
  String get errorNetwork => 'Please check your network connection.';

  @override
  String get errorTimeout => 'Request timed out. Please try again.';

  @override
  String get errorServerUnavailable =>
      'Server is temporarily unavailable. Please try again later.';

  @override
  String get errorUnauthorized => 'Please sign in again.';

  @override
  String get errorRetry => 'Retry';

  @override
  String get errorCancel => 'Cancel';

  @override
  String get errorAuthRefreshFailed =>
      'Network is unstable. Please try again in a moment.';
}
