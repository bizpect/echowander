import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt', 'BR'),
    Locale('zh'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'EchoWander'**
  String get appTitle;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting up...'**
  String get splashTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginDescription.
  ///
  /// In en, this message translates to:
  /// **'Start your anonymous relay message'**
  String get loginDescription;

  /// No description provided for @loginKakao.
  ///
  /// In en, this message translates to:
  /// **'Continue with Kakao'**
  String get loginKakao;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogle;

  /// No description provided for @loginApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get loginApple;

  /// No description provided for @loginTerms.
  ///
  /// In en, this message translates to:
  /// **'By signing in, you agree to our Terms of Service and Privacy Policy'**
  String get loginTerms;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get homeGreeting;

  /// No description provided for @homeRecentJourneysTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Messages'**
  String get homeRecentJourneysTitle;

  /// No description provided for @homeActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get homeActionsTitle;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to EchoWander'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Send your first relay message or check your inbox.'**
  String get homeEmptyDescription;

  /// No description provided for @homeInboxCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get homeInboxCardTitle;

  /// No description provided for @homeInboxCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Check and reply to messages you\'ve received.'**
  String get homeInboxCardDescription;

  /// No description provided for @homeCreateCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Message'**
  String get homeCreateCardTitle;

  /// No description provided for @homeCreateCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a new relay message.'**
  String get homeCreateCardDescription;

  /// No description provided for @homeJourneyCardViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get homeJourneyCardViewDetails;

  /// No description provided for @homeRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get homeRefresh;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your data.'**
  String get homeLoadFailed;

  /// No description provided for @homeInboxCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String homeInboxCount(Object count);

  /// No description provided for @settingsCta.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsCta;

  /// No description provided for @settingsNotificationInbox.
  ///
  /// In en, this message translates to:
  /// **'Notification inbox'**
  String get settingsNotificationInbox;

  /// No description provided for @pushPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get pushPreviewTitle;

  /// No description provided for @pushPreviewDescription.
  ///
  /// In en, this message translates to:
  /// **'This is a preview screen for push deep links.'**
  String get pushPreviewDescription;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notificationTitle;

  /// No description provided for @notificationOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notificationOpen;

  /// No description provided for @notificationDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get notificationDismiss;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsUnreadOnly.
  ///
  /// In en, this message translates to:
  /// **'Show unread only'**
  String get notificationsUnreadOnly;

  /// No description provided for @notificationsRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationsRead;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get notificationsUnread;

  /// No description provided for @notificationsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get notificationsDeleteTitle;

  /// No description provided for @notificationsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove this notification from your inbox?'**
  String get notificationsDeleteMessage;

  /// No description provided for @notificationsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notificationsDeleteConfirm;

  /// No description provided for @pushJourneyAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get pushJourneyAssignedTitle;

  /// No description provided for @pushJourneyAssignedBody.
  ///
  /// In en, this message translates to:
  /// **'A new relay message has arrived.'**
  String get pushJourneyAssignedBody;

  /// No description provided for @pushJourneyResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result ready'**
  String get pushJourneyResultTitle;

  /// No description provided for @pushJourneyResultBody.
  ///
  /// In en, this message translates to:
  /// **'Your relay result is ready.'**
  String get pushJourneyResultBody;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get errorTitle;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get errorLoginFailed;

  /// No description provided for @errorLoginCancelled.
  ///
  /// In en, this message translates to:
  /// **'Login was cancelled.'**
  String get errorLoginCancelled;

  /// No description provided for @errorLoginNetwork.
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection and try again.'**
  String get errorLoginNetwork;

  /// No description provided for @errorLoginInvalidToken.
  ///
  /// In en, this message translates to:
  /// **'Login verification failed. Please try again.'**
  String get errorLoginInvalidToken;

  /// No description provided for @errorLoginUnsupportedProvider.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not supported.'**
  String get errorLoginUnsupportedProvider;

  /// No description provided for @errorLoginUserSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your account. Please try again.'**
  String get errorLoginUserSyncFailed;

  /// No description provided for @errorLoginServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is temporarily unavailable. Please try again later.'**
  String get errorLoginServiceUnavailable;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get errorForbiddenTitle;

  /// No description provided for @errorForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action. Please check your login status or try again later.'**
  String get errorForbiddenMessage;

  /// No description provided for @journeyInboxForbiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot Load Inbox'**
  String get journeyInboxForbiddenTitle;

  /// No description provided for @journeyInboxForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to view the inbox. If the problem persists, please sign in again.'**
  String get journeyInboxForbiddenMessage;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;

  /// No description provided for @composeTitle.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get composeTitle;

  /// No description provided for @composeWizardStep1Title.
  ///
  /// In en, this message translates to:
  /// **'What will your journey say?'**
  String get composeWizardStep1Title;

  /// No description provided for @composeWizardStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Write a short hook to start the relay.'**
  String get composeWizardStep1Subtitle;

  /// No description provided for @composeWizardStep2Title.
  ///
  /// In en, this message translates to:
  /// **'How many people should it reach?'**
  String get composeWizardStep2Title;

  /// No description provided for @composeWizardStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick 1 to 5 recipients.'**
  String get composeWizardStep2Subtitle;

  /// No description provided for @composeWizardStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Add a photo? (optional)'**
  String get composeWizardStep3Title;

  /// No description provided for @composeWizardStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Attach up to 3 photos, or send without one.'**
  String get composeWizardStep3Subtitle;

  /// No description provided for @composeWizardBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get composeWizardBack;

  /// No description provided for @composeWizardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get composeWizardNext;

  /// No description provided for @composeLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get composeLabel;

  /// No description provided for @composeHint.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts...'**
  String get composeHint;

  /// No description provided for @composeCharacterCount.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String composeCharacterCount(Object current, Object total);

  /// No description provided for @composeImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get composeImagesTitle;

  /// No description provided for @composeAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get composeAddImage;

  /// No description provided for @composeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get composeSubmit;

  /// No description provided for @composeCta.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get composeCta;

  /// No description provided for @composeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Message is too long.'**
  String get composeTooLong;

  /// No description provided for @composeForbidden.
  ///
  /// In en, this message translates to:
  /// **'Remove URLs or contact info.'**
  String get composeForbidden;

  /// No description provided for @composeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message.'**
  String get composeEmpty;

  /// No description provided for @composeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please fix the message content.'**
  String get composeInvalid;

  /// No description provided for @composeImageLimit.
  ///
  /// In en, this message translates to:
  /// **'You can attach up to 3 images.'**
  String get composeImageLimit;

  /// No description provided for @composePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo access is needed to attach images.'**
  String get composePermissionDenied;

  /// No description provided for @composeSessionMissing.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get composeSessionMissing;

  /// No description provided for @composeSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your message. Try again.'**
  String get composeSubmitFailed;

  /// No description provided for @composeServerMisconfigured.
  ///
  /// In en, this message translates to:
  /// **'Service setup is not ready yet. Please try again later.'**
  String get composeServerMisconfigured;

  /// No description provided for @composeSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your message was sent.'**
  String get composeSubmitSuccess;

  /// No description provided for @composeRecipientCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Relay count'**
  String get composeRecipientCountLabel;

  /// No description provided for @composeRecipientCountHint.
  ///
  /// In en, this message translates to:
  /// **'Select 1 to 5 people.'**
  String get composeRecipientCountHint;

  /// No description provided for @composeRecipientCountOption.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String composeRecipientCountOption(Object count);

  /// No description provided for @composeRecipientRequired.
  ///
  /// In en, this message translates to:
  /// **'Select how many people to relay to.'**
  String get composeRecipientRequired;

  /// No description provided for @composeRecipientInvalid.
  ///
  /// In en, this message translates to:
  /// **'You can select between 1 and 5 people.'**
  String get composeRecipientInvalid;

  /// No description provided for @composeErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get composeErrorTitle;

  /// No description provided for @composeSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get composeSuccessTitle;

  /// No description provided for @composeOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get composeOk;

  /// No description provided for @composeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get composeCancel;

  /// No description provided for @composePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow photo access'**
  String get composePermissionTitle;

  /// No description provided for @composePermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Open Settings to allow photo access.'**
  String get composePermissionMessage;

  /// No description provided for @composeOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get composeOpenSettings;

  /// No description provided for @journeyListTitle.
  ///
  /// In en, this message translates to:
  /// **'Sent Messages'**
  String get journeyListTitle;

  /// No description provided for @journeyListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get journeyListEmpty;

  /// No description provided for @journeyListCta.
  ///
  /// In en, this message translates to:
  /// **'View sent messages'**
  String get journeyListCta;

  /// No description provided for @journeyListStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get journeyListStatusLabel;

  /// No description provided for @journeyStatusCreated.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get journeyStatusCreated;

  /// No description provided for @journeyStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for match'**
  String get journeyStatusWaiting;

  /// No description provided for @journeyStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get journeyStatusCompleted;

  /// No description provided for @journeyStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get journeyStatusInProgress;

  /// No description provided for @journeyStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get journeyStatusUnknown;

  /// No description provided for @journeyInProgressHint.
  ///
  /// In en, this message translates to:
  /// **'You can view responses after completion'**
  String get journeyInProgressHint;

  /// No description provided for @journeyFilterOk.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get journeyFilterOk;

  /// No description provided for @journeyFilterHeld.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get journeyFilterHeld;

  /// No description provided for @journeyFilterRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get journeyFilterRemoved;

  /// No description provided for @journeyFilterUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get journeyFilterUnknown;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxTitle;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages received yet.'**
  String get inboxEmpty;

  /// No description provided for @inboxCta.
  ///
  /// In en, this message translates to:
  /// **'View inbox'**
  String get inboxCta;

  /// No description provided for @inboxRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get inboxRefresh;

  /// No description provided for @inboxLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your inbox.'**
  String get inboxLoadFailed;

  /// No description provided for @inboxImageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photo(s)'**
  String inboxImageCount(Object count);

  /// No description provided for @inboxStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get inboxStatusLabel;

  /// No description provided for @inboxStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get inboxStatusAssigned;

  /// No description provided for @inboxStatusResponded.
  ///
  /// In en, this message translates to:
  /// **'Responded'**
  String get inboxStatusResponded;

  /// No description provided for @inboxStatusPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get inboxStatusPassed;

  /// No description provided for @inboxStatusReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get inboxStatusReported;

  /// No description provided for @inboxStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get inboxStatusUnknown;

  /// No description provided for @inboxDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxDetailTitle;

  /// No description provided for @inboxDetailMissing.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this message.'**
  String get inboxDetailMissing;

  /// No description provided for @inboxImagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get inboxImagesLabel;

  /// No description provided for @inboxImagesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the photos.'**
  String get inboxImagesLoadFailed;

  /// No description provided for @inboxBlockCta.
  ///
  /// In en, this message translates to:
  /// **'Block sender'**
  String get inboxBlockCta;

  /// No description provided for @inboxBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get inboxBlockTitle;

  /// No description provided for @inboxBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'Block this user from future relay messages?'**
  String get inboxBlockMessage;

  /// No description provided for @inboxBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get inboxBlockConfirm;

  /// No description provided for @inboxBlockSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get inboxBlockSuccessTitle;

  /// No description provided for @inboxBlockSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'The user has been blocked.'**
  String get inboxBlockSuccessBody;

  /// No description provided for @inboxBlockFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t block this user.'**
  String get inboxBlockFailed;

  /// No description provided for @inboxBlockMissing.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t identify the sender.'**
  String get inboxBlockMissing;

  /// No description provided for @inboxRespondLabel.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get inboxRespondLabel;

  /// No description provided for @inboxRespondHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reply...'**
  String get inboxRespondHint;

  /// No description provided for @inboxRespondCta.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get inboxRespondCta;

  /// No description provided for @inboxRespondEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reply.'**
  String get inboxRespondEmpty;

  /// No description provided for @inboxRespondSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get inboxRespondSuccessTitle;

  /// No description provided for @inboxRespondSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your reply was sent.'**
  String get inboxRespondSuccessBody;

  /// No description provided for @inboxPassCta.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get inboxPassCta;

  /// No description provided for @inboxPassSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get inboxPassSuccessTitle;

  /// No description provided for @inboxPassSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve passed this message.'**
  String get inboxPassSuccessBody;

  /// No description provided for @inboxPassedTitle.
  ///
  /// In en, this message translates to:
  /// **'Passed message'**
  String get inboxPassedTitle;

  /// No description provided for @inboxPassedDetailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This message was passed and content is unavailable.'**
  String get inboxPassedDetailUnavailable;

  /// No description provided for @inboxReportCta.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get inboxReportCta;

  /// No description provided for @inboxReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report reason'**
  String get inboxReportTitle;

  /// No description provided for @inboxReportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get inboxReportSpam;

  /// No description provided for @inboxReportAbuse.
  ///
  /// In en, this message translates to:
  /// **'Abuse'**
  String get inboxReportAbuse;

  /// No description provided for @inboxReportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get inboxReportOther;

  /// No description provided for @inboxReportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get inboxReportSuccessTitle;

  /// No description provided for @inboxReportSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your report was submitted.'**
  String get inboxReportSuccessBody;

  /// No description provided for @inboxActionFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete this action.'**
  String get inboxActionFailed;

  /// No description provided for @journeyDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get journeyDetailTitle;

  /// No description provided for @journeyDetailMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get journeyDetailMessageLabel;

  /// No description provided for @journeyDetailMessageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Message unavailable.'**
  String get journeyDetailMessageUnavailable;

  /// No description provided for @journeyDetailProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Relay progress'**
  String get journeyDetailProgressTitle;

  /// No description provided for @journeyDetailStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get journeyDetailStatusLabel;

  /// No description provided for @journeyDetailDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Relay deadline'**
  String get journeyDetailDeadlineLabel;

  /// No description provided for @journeyDetailResponseTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target replies'**
  String get journeyDetailResponseTargetLabel;

  /// No description provided for @journeyDetailRespondedLabel.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get journeyDetailRespondedLabel;

  /// No description provided for @journeyDetailAssignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get journeyDetailAssignedLabel;

  /// No description provided for @journeyDetailPassedLabel.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get journeyDetailPassedLabel;

  /// No description provided for @journeyDetailReportedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get journeyDetailReportedLabel;

  /// No description provided for @journeyDetailCountriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Relay locations'**
  String get journeyDetailCountriesLabel;

  /// No description provided for @journeyDetailCountriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No locations yet.'**
  String get journeyDetailCountriesEmpty;

  /// No description provided for @journeyDetailResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get journeyDetailResultsTitle;

  /// No description provided for @journeyDetailResultsLocked.
  ///
  /// In en, this message translates to:
  /// **'Results will appear after completion.'**
  String get journeyDetailResultsLocked;

  /// No description provided for @journeyDetailResultsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No replies yet.'**
  String get journeyDetailResultsEmpty;

  /// No description provided for @journeyDetailResultsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the results.'**
  String get journeyDetailResultsLoadFailed;

  /// No description provided for @journeyDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the progress.'**
  String get journeyDetailLoadFailed;

  /// No description provided for @journeyDetailRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get journeyDetailRetry;

  /// No description provided for @journeyDetailAdRequired.
  ///
  /// In en, this message translates to:
  /// **'Watch a reward ad to view results.'**
  String get journeyDetailAdRequired;

  /// No description provided for @journeyDetailAdCta.
  ///
  /// In en, this message translates to:
  /// **'Watch ad and unlock'**
  String get journeyDetailAdCta;

  /// No description provided for @journeyDetailAdFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad unavailable'**
  String get journeyDetailAdFailedTitle;

  /// No description provided for @journeyDetailAdFailedBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the ad. View results anyway?'**
  String get journeyDetailAdFailedBody;

  /// No description provided for @journeyDetailAdFailedConfirm.
  ///
  /// In en, this message translates to:
  /// **'View results'**
  String get journeyDetailAdFailedConfirm;

  /// No description provided for @journeyResultReportCta.
  ///
  /// In en, this message translates to:
  /// **'Report reply'**
  String get journeyResultReportCta;

  /// No description provided for @journeyResultReportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get journeyResultReportSuccessTitle;

  /// No description provided for @journeyResultReportSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your report was submitted.'**
  String get journeyResultReportSuccessBody;

  /// No description provided for @journeyResultReportFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t submit your report.'**
  String get journeyResultReportFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionNotification.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotification;

  /// No description provided for @settingsNotificationToggle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get settingsNotificationToggle;

  /// No description provided for @settingsNotificationHint.
  ///
  /// In en, this message translates to:
  /// **'Receive relay updates and results.'**
  String get settingsNotificationHint;

  /// No description provided for @settingsSectionSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get settingsSectionSafety;

  /// No description provided for @settingsBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get settingsBlockedUsers;

  /// No description provided for @settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load settings.'**
  String get settingsLoadFailed;

  /// No description provided for @settingsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update settings.'**
  String get settingsUpdateFailed;

  /// No description provided for @blockListTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockListTitle;

  /// No description provided for @blockListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No blocked users.'**
  String get blockListEmpty;

  /// No description provided for @blockListUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get blockListUnknownUser;

  /// No description provided for @blockListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the block list.'**
  String get blockListLoadFailed;

  /// No description provided for @blockListUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get blockListUnblock;

  /// No description provided for @blockListUnblockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock user'**
  String get blockListUnblockTitle;

  /// No description provided for @blockListUnblockMessage.
  ///
  /// In en, this message translates to:
  /// **'Allow messages from this user again?'**
  String get blockListUnblockMessage;

  /// No description provided for @blockListUnblockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get blockListUnblockConfirm;

  /// No description provided for @blockListUnblockFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t unblock this user.'**
  String get blockListUnblockFailed;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboardingTitle;

  /// No description provided for @onboardingStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepCounter(Object current, Object total);

  /// No description provided for @onboardingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification permission'**
  String get onboardingNotificationTitle;

  /// No description provided for @onboardingNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when relay messages arrive and results are ready.'**
  String get onboardingNotificationDescription;

  /// No description provided for @onboardingNotificationNote.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings. This step is optional.'**
  String get onboardingNotificationNote;

  /// No description provided for @onboardingAllowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get onboardingAllowNotifications;

  /// No description provided for @onboardingPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo access'**
  String get onboardingPhotoTitle;

  /// No description provided for @onboardingPhotoDescription.
  ///
  /// In en, this message translates to:
  /// **'Used only for setting profile images and attaching images to messages.'**
  String get onboardingPhotoDescription;

  /// No description provided for @onboardingPhotoNote.
  ///
  /// In en, this message translates to:
  /// **'We only access photos you select. This step is optional.'**
  String get onboardingPhotoNote;

  /// No description provided for @onboardingAllowPhotos.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get onboardingAllowPhotos;

  /// No description provided for @onboardingGuidelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Community guidelines'**
  String get onboardingGuidelineTitle;

  /// No description provided for @onboardingGuidelineDescription.
  ///
  /// In en, this message translates to:
  /// **'For safe use, harassment, hate speech, and sharing personal information are prohibited. Violations may result in content restrictions.'**
  String get onboardingGuidelineDescription;

  /// No description provided for @onboardingAgreeGuidelines.
  ///
  /// In en, this message translates to:
  /// **'I agree to the community guidelines.'**
  String get onboardingAgreeGuidelines;

  /// No description provided for @onboardingContentPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Content policy'**
  String get onboardingContentPolicyTitle;

  /// No description provided for @onboardingContentPolicyDescription.
  ///
  /// In en, this message translates to:
  /// **'Illegal, harmful, and violent content is prohibited. Violating content may be restricted after review.'**
  String get onboardingContentPolicyDescription;

  /// No description provided for @onboardingAgreeContentPolicy.
  ///
  /// In en, this message translates to:
  /// **'I agree to the content policy.'**
  String get onboardingAgreeContentPolicy;

  /// No description provided for @onboardingSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Report and block'**
  String get onboardingSafetyTitle;

  /// No description provided for @onboardingSafetyDescription.
  ///
  /// In en, this message translates to:
  /// **'You can report offensive or inappropriate content, or block specific users to stop receiving their messages.'**
  String get onboardingSafetyDescription;

  /// No description provided for @onboardingConfirmSafety.
  ///
  /// In en, this message translates to:
  /// **'I understand the report and block policy.'**
  String get onboardingConfirmSafety;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @onboardingAgreeAndDisagree.
  ///
  /// In en, this message translates to:
  /// **'Agree and Disagree'**
  String get onboardingAgreeAndDisagree;

  /// No description provided for @onboardingPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get onboardingPrevious;

  /// No description provided for @ctaPermissionChoice.
  ///
  /// In en, this message translates to:
  /// **'Choose Permission'**
  String get ctaPermissionChoice;

  /// No description provided for @onboardingExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit onboarding?'**
  String get onboardingExitTitle;

  /// No description provided for @onboardingExitMessage.
  ///
  /// In en, this message translates to:
  /// **'You can start again later.'**
  String get onboardingExitMessage;

  /// No description provided for @onboardingExitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get onboardingExitConfirm;

  /// No description provided for @onboardingExitCancel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingExitCancel;

  /// No description provided for @exitConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel writing?'**
  String get exitConfirmTitle;

  /// No description provided for @exitConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your input will be lost.'**
  String get exitConfirmMessage;

  /// No description provided for @exitConfirmContinue.
  ///
  /// In en, this message translates to:
  /// **'Keep writing'**
  String get exitConfirmContinue;

  /// No description provided for @exitConfirmLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get exitConfirmLeave;

  /// No description provided for @tabHomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHomeLabel;

  /// No description provided for @tabSentLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get tabSentLabel;

  /// No description provided for @tabInboxLabel.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get tabInboxLabel;

  /// No description provided for @tabCreateLabel.
  ///
  /// In en, this message translates to:
  /// **'Create message'**
  String get tabCreateLabel;

  /// No description provided for @tabAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tabAlertsLabel;

  /// No description provided for @tabProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfileLabel;

  /// No description provided for @profileSignOutCta.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOutCta;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get profileSignOutMessage;

  /// No description provided for @profileSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOutConfirm;

  /// No description provided for @profileUserIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get profileUserIdLabel;

  /// No description provided for @profileDefaultNickname.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileDefaultNickname;

  /// No description provided for @journeyDetailAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get journeyDetailAnonymous;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server is temporarily unavailable. Please try again later.'**
  String get errorServerUnavailable;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorRetry;

  /// No description provided for @errorCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get errorCancel;

  /// No description provided for @errorAuthRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Network is unstable. Please try again in a moment.'**
  String get errorAuthRefreshFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
