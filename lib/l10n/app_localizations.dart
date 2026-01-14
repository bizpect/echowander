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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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
    Locale('pt')
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

  /// No description provided for @homeExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit EchoWander?'**
  String get homeExitTitle;

  /// No description provided for @homeExitMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close the app?'**
  String get homeExitMessage;

  /// No description provided for @homeExitCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get homeExitCancel;

  /// No description provided for @homeExitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get homeExitConfirm;

  /// No description provided for @homeExitAdLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading ad...'**
  String get homeExitAdLoading;

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

  /// No description provided for @notificationsUnreadCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Unread notifications {count}'**
  String notificationsUnreadCountLabel(Object count);

  /// No description provided for @notificationsUnreadCountOverflow.
  ///
  /// In en, this message translates to:
  /// **'9+'**
  String get notificationsUnreadCountOverflow;

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
  /// **'Pick 10 to 50 recipients.'**
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

  /// No description provided for @composeImageHelper.
  ///
  /// In en, this message translates to:
  /// **'You can attach up to 3 photos.'**
  String get composeImageHelper;

  /// No description provided for @composeImageUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload an image.'**
  String get composeImageUploadHint;

  /// No description provided for @composeImageDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete image'**
  String get composeImageDelete;

  /// No description provided for @composeSelectedImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected images'**
  String get composeSelectedImagesTitle;

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

  /// No description provided for @composeImageReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the image. Please try again.'**
  String get composeImageReadFailed;

  /// No description provided for @composeImageOptimizationFailed.
  ///
  /// In en, this message translates to:
  /// **'Image processing failed. Please try again.'**
  String get composeImageOptimizationFailed;

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

  /// No description provided for @composeSendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your message has been queued for delivery.'**
  String get composeSendRequestAccepted;

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

  /// No description provided for @sessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionExpiredTitle;

  /// No description provided for @sessionExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get sessionExpiredBody;

  /// No description provided for @sessionExpiredCtaLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sessionExpiredCtaLogin;

  /// No description provided for @sendFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Failed'**
  String get sendFailedTitle;

  /// No description provided for @sendFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message. Please try again.'**
  String get sendFailedTryAgain;

  /// No description provided for @moderationContentBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message contains inappropriate content.'**
  String get moderationContentBlockedMessage;

  /// No description provided for @moderationBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot Send'**
  String get moderationBlockedTitle;

  /// No description provided for @nicknameForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'Your nickname contains prohibited words.'**
  String get nicknameForbiddenMessage;

  /// No description provided for @nicknameTakenMessage.
  ///
  /// In en, this message translates to:
  /// **'This nickname is already in use.'**
  String get nicknameTakenMessage;

  /// No description provided for @composeContentBlocked.
  ///
  /// In en, this message translates to:
  /// **'This content cannot be sent.'**
  String get composeContentBlocked;

  /// No description provided for @composeContentBlockedProfanity.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate language is not allowed.'**
  String get composeContentBlockedProfanity;

  /// No description provided for @composeContentBlockedSexual.
  ///
  /// In en, this message translates to:
  /// **'Sexual content is prohibited.'**
  String get composeContentBlockedSexual;

  /// No description provided for @composeContentBlockedHate.
  ///
  /// In en, this message translates to:
  /// **'Hate speech is prohibited.'**
  String get composeContentBlockedHate;

  /// No description provided for @composeContentBlockedThreat.
  ///
  /// In en, this message translates to:
  /// **'Threatening content is prohibited.'**
  String get composeContentBlockedThreat;

  /// No description provided for @replyContentBlocked.
  ///
  /// In en, this message translates to:
  /// **'This content cannot be sent.'**
  String get replyContentBlocked;

  /// No description provided for @replyContentBlockedProfanity.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate language is not allowed.'**
  String get replyContentBlockedProfanity;

  /// No description provided for @replyContentBlockedSexual.
  ///
  /// In en, this message translates to:
  /// **'Sexual content is prohibited.'**
  String get replyContentBlockedSexual;

  /// No description provided for @replyContentBlockedHate.
  ///
  /// In en, this message translates to:
  /// **'Hate speech is prohibited.'**
  String get replyContentBlockedHate;

  /// No description provided for @replyContentBlockedThreat.
  ///
  /// In en, this message translates to:
  /// **'Threatening content is prohibited.'**
  String get replyContentBlockedThreat;

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

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @journeyListTitle.
  ///
  /// In en, this message translates to:
  /// **'Sent Messages'**
  String get journeyListTitle;

  /// No description provided for @sentTabInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get sentTabInProgress;

  /// No description provided for @sentTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get sentTabCompleted;

  /// No description provided for @inboxSentOngoingForwardedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent to {count}'**
  String inboxSentOngoingForwardedCountLabel(Object count);

  /// No description provided for @inboxSentOngoingRespondedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} responded'**
  String inboxSentOngoingRespondedCountLabel(Object count);

  /// No description provided for @sentEmptyInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages in progress'**
  String get sentEmptyInProgressTitle;

  /// No description provided for @sentEmptyInProgressDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a new relay message to see it here.'**
  String get sentEmptyInProgressDescription;

  /// No description provided for @sentEmptyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed messages'**
  String get sentEmptyCompletedTitle;

  /// No description provided for @sentEmptyCompletedDescription.
  ///
  /// In en, this message translates to:
  /// **'Completed relays will appear here.'**
  String get sentEmptyCompletedDescription;

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

  /// No description provided for @inboxTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get inboxTabPending;

  /// No description provided for @inboxTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get inboxTabCompleted;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages received yet.'**
  String get inboxEmpty;

  /// No description provided for @inboxEmptyPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'No pending messages'**
  String get inboxEmptyPendingTitle;

  /// No description provided for @inboxEmptyPendingDescription.
  ///
  /// In en, this message translates to:
  /// **'New messages will appear here.'**
  String get inboxEmptyPendingDescription;

  /// No description provided for @inboxEmptyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed messages'**
  String get inboxEmptyCompletedTitle;

  /// No description provided for @inboxEmptyCompletedDescription.
  ///
  /// In en, this message translates to:
  /// **'Messages you\'ve responded to will appear here.'**
  String get inboxEmptyCompletedDescription;

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

  /// No description provided for @inboxCardArrivedPrompt.
  ///
  /// In en, this message translates to:
  /// **'Message arrived!\nPlease leave a reply.'**
  String get inboxCardArrivedPrompt;

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
  /// **'Message'**
  String get inboxRespondLabel;

  /// No description provided for @inboxRespondHint.
  ///
  /// In en, this message translates to:
  /// **'Write your message...'**
  String get inboxRespondHint;

  /// No description provided for @inboxRespondCta.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get inboxRespondCta;

  /// No description provided for @inboxRespondEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message.'**
  String get inboxRespondEmpty;

  /// No description provided for @inboxRespondConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get inboxRespondConfirmTitle;

  /// No description provided for @inboxRespondConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to send this message?'**
  String get inboxRespondConfirmMessage;

  /// No description provided for @inboxRespondSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get inboxRespondSuccessTitle;

  /// No description provided for @inboxRespondSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your message was sent.'**
  String get inboxRespondSuccessBody;

  /// No description provided for @inboxPassCta.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get inboxPassCta;

  /// No description provided for @inboxPassConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Pass'**
  String get inboxPassConfirmTitle;

  /// No description provided for @inboxPassConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to pass this message?'**
  String get inboxPassConfirmMessage;

  /// No description provided for @inboxPassConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get inboxPassConfirmAction;

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

  /// No description provided for @inboxPassedMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'This message was passed.'**
  String get inboxPassedMessageTitle;

  /// No description provided for @inboxRespondedMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'You replied to this message.'**
  String get inboxRespondedMessageTitle;

  /// No description provided for @inboxRespondedDetailSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reply'**
  String get inboxRespondedDetailSectionTitle;

  /// No description provided for @inboxRespondedDetailReplyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your reply.'**
  String get inboxRespondedDetailReplyUnavailable;

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

  /// No description provided for @inboxReportAlreadyReportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Already reported'**
  String get inboxReportAlreadyReportedTitle;

  /// No description provided for @inboxReportAlreadyReportedBody.
  ///
  /// In en, this message translates to:
  /// **'You have already reported this message.'**
  String get inboxReportAlreadyReportedBody;

  /// No description provided for @inboxActionFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete this action.'**
  String get inboxActionFailed;

  /// No description provided for @actionReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get actionReportMessage;

  /// No description provided for @actionBlockSender.
  ///
  /// In en, this message translates to:
  /// **'Block sender'**
  String get actionBlockSender;

  /// No description provided for @inboxDetailMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get inboxDetailMoreTitle;

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
  /// **'Replies'**
  String get journeyDetailResultsTitle;

  /// No description provided for @journeyDetailResultsLocked.
  ///
  /// In en, this message translates to:
  /// **'Replies will appear after completion.'**
  String get journeyDetailResultsLocked;

  /// No description provided for @journeyDetailResultsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No replies yet.'**
  String get journeyDetailResultsEmpty;

  /// No description provided for @journeyDetailResultsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the replies.'**
  String get journeyDetailResultsLoadFailed;

  /// No description provided for @commonTemporaryErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Temporary error'**
  String get commonTemporaryErrorTitle;

  /// No description provided for @sentDetailRepliesLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the replies. We\'ll return to the list.'**
  String get sentDetailRepliesLoadFailedMessage;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @journeyDetailResponsesMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Temporary error'**
  String get journeyDetailResponsesMissingTitle;

  /// No description provided for @journeyDetailResponsesMissingBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the responses. Please try again.\nWe\'ll return to the list.'**
  String get journeyDetailResponsesMissingBody;

  /// No description provided for @journeyDetailGateConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad not ready'**
  String get journeyDetailGateConfigTitle;

  /// No description provided for @journeyDetailGateConfigBody.
  ///
  /// In en, this message translates to:
  /// **'Ads aren\'t configured yet. We\'ll open the details without an ad.'**
  String get journeyDetailGateConfigBody;

  /// No description provided for @journeyDetailGateDismissedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad not completed'**
  String get journeyDetailGateDismissedTitle;

  /// No description provided for @journeyDetailGateDismissedBody.
  ///
  /// In en, this message translates to:
  /// **'Please watch the ad to view details.'**
  String get journeyDetailGateDismissedBody;

  /// No description provided for @journeyDetailGateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad unavailable'**
  String get journeyDetailGateFailedTitle;

  /// No description provided for @journeyDetailGateFailedBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the ad. Please try again.'**
  String get journeyDetailGateFailedBody;

  /// No description provided for @journeyDetailUnlockFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock failed'**
  String get journeyDetailUnlockFailedTitle;

  /// No description provided for @journeyDetailUnlockFailedBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save the unlock due to a network or server issue. Please try again.'**
  String get journeyDetailUnlockFailedBody;

  /// No description provided for @journeyDetailGateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with a reward ad'**
  String get journeyDetailGateDialogTitle;

  /// No description provided for @journeyDetailGateDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock by watching a reward ad.\nWatch once to unlock forever.'**
  String get journeyDetailGateDialogBody;

  /// No description provided for @journeyDetailGateDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get journeyDetailGateDialogConfirm;

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

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

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

  /// No description provided for @blockUnblockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get blockUnblockedTitle;

  /// No description provided for @blockUnblockedMessage.
  ///
  /// In en, this message translates to:
  /// **'User unblocked.'**
  String get blockUnblockedMessage;

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

  /// No description provided for @noticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get noticeTitle;

  /// No description provided for @noticeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get noticeDetailTitle;

  /// No description provided for @noticeFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Notice type'**
  String get noticeFilterLabel;

  /// No description provided for @noticeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get noticeFilterAll;

  /// No description provided for @noticeFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select notice type'**
  String get noticeFilterSheetTitle;

  /// No description provided for @noticeTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get noticeTypeUnknown;

  /// No description provided for @noticePinnedBadge.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get noticePinnedBadge;

  /// No description provided for @noticeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notices yet'**
  String get noticeEmptyTitle;

  /// No description provided for @noticeEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'There are no notices for this type.'**
  String get noticeEmptyDescription;

  /// No description provided for @noticeErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notices'**
  String get noticeErrorTitle;

  /// No description provided for @noticeErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get noticeErrorDescription;

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

  /// No description provided for @profileEditCta.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditCta;

  /// No description provided for @authProviderKakaoLogin.
  ///
  /// In en, this message translates to:
  /// **'Kakao login'**
  String get authProviderKakaoLogin;

  /// No description provided for @authProviderGoogleLogin.
  ///
  /// In en, this message translates to:
  /// **'Google login'**
  String get authProviderGoogleLogin;

  /// No description provided for @authProviderAppleLogin.
  ///
  /// In en, this message translates to:
  /// **'Apple login'**
  String get authProviderAppleLogin;

  /// No description provided for @authProviderUnknownLogin.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get authProviderUnknownLogin;

  /// No description provided for @profileLoginProviderKakao.
  ///
  /// In en, this message translates to:
  /// **'Kakao login'**
  String get profileLoginProviderKakao;

  /// No description provided for @profileLoginProviderGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google login'**
  String get profileLoginProviderGoogle;

  /// No description provided for @profileLoginProviderApple.
  ///
  /// In en, this message translates to:
  /// **'Apple login'**
  String get profileLoginProviderApple;

  /// No description provided for @profileLoginProviderEmail.
  ///
  /// In en, this message translates to:
  /// **'Email login'**
  String get profileLoginProviderEmail;

  /// No description provided for @profileLoginProviderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get profileLoginProviderUnknown;

  /// No description provided for @profileAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get profileAppSettings;

  /// No description provided for @profileMenuNotices.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get profileMenuNotices;

  /// No description provided for @profileMenuSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get profileMenuSupport;

  /// No description provided for @profileMenuAppInfo.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get profileMenuAppInfo;

  /// No description provided for @profileMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get profileMenuTitle;

  /// No description provided for @profileMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick access to common settings.'**
  String get profileMenuSubtitle;

  /// No description provided for @profileWithdrawCta.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileWithdrawCta;

  /// No description provided for @profileWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileWithdrawTitle;

  /// No description provided for @profileWithdrawMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This cannot be undone.'**
  String get profileWithdrawMessage;

  /// No description provided for @profileWithdrawConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileWithdrawConfirm;

  /// No description provided for @profileFeaturePreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get profileFeaturePreparingTitle;

  /// No description provided for @profileFeaturePreparingBody.
  ///
  /// In en, this message translates to:
  /// **'This feature is not available yet.'**
  String get profileFeaturePreparingBody;

  /// No description provided for @profileAvatarSemantics.
  ///
  /// In en, this message translates to:
  /// **'Profile avatar'**
  String get profileAvatarSemantics;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportTitle;

  /// No description provided for @supportStatusMessage.
  ///
  /// In en, this message translates to:
  /// **'Your app is up to date.'**
  String get supportStatusMessage;

  /// No description provided for @supportReleaseNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Release notes'**
  String get supportReleaseNotesTitle;

  /// No description provided for @supportReleaseNotesHeader.
  ///
  /// In en, this message translates to:
  /// **'Latest version {version} updates'**
  String supportReleaseNotesHeader(Object version);

  /// No description provided for @supportReleaseNotesBody.
  ///
  /// In en, this message translates to:
  /// **'• Improved the relay experience and stability.\n• Polished dark theme visuals for profile and support.\n• Fixed minor bugs and performance issues.'**
  String get supportReleaseNotesBody;

  /// No description provided for @supportVersionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown version'**
  String get supportVersionUnknown;

  /// No description provided for @supportSuggestCta.
  ///
  /// In en, this message translates to:
  /// **'Send suggestions'**
  String get supportSuggestCta;

  /// No description provided for @supportReportCta.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get supportReportCta;

  /// No description provided for @supportFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get supportFaqTitle;

  /// No description provided for @supportFaqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check common questions.'**
  String get supportFaqSubtitle;

  /// No description provided for @supportFaqQ1.
  ///
  /// In en, this message translates to:
  /// **'Messages don\'t seem to be delivered. Why?'**
  String get supportFaqQ1;

  /// No description provided for @supportFaqA1.
  ///
  /// In en, this message translates to:
  /// **'Delivery may be delayed or restricted due to network status, temporary server delays, or safety policies (reports/blocks, etc.). Please try again later.'**
  String get supportFaqA1;

  /// No description provided for @supportFaqQ2.
  ///
  /// In en, this message translates to:
  /// **'I\'m not receiving notifications. What should I do?'**
  String get supportFaqQ2;

  /// No description provided for @supportFaqA2.
  ///
  /// In en, this message translates to:
  /// **'Echowander notification permissions may be turned off in your phone settings. Go to App Settings → App Settings (Notification Settings) to turn on notification permissions, and also check battery saver/background restrictions.'**
  String get supportFaqA2;

  /// No description provided for @supportFaqQ3.
  ///
  /// In en, this message translates to:
  /// **'I received an unpleasant message. How do I block/report?'**
  String get supportFaqQ3;

  /// No description provided for @supportFaqA3.
  ///
  /// In en, this message translates to:
  /// **'You can select Report or Block from the message screen. Blocking prevents you from receiving further messages from that user. Reported content may be reviewed for community safety.'**
  String get supportFaqA3;

  /// No description provided for @supportFaqQ4.
  ///
  /// In en, this message translates to:
  /// **'Can I edit or cancel a message I sent?'**
  String get supportFaqQ4;

  /// No description provided for @supportFaqA4.
  ///
  /// In en, this message translates to:
  /// **'Once sent, messages cannot be easily edited or cancelled. Please review the content before sending.'**
  String get supportFaqA4;

  /// No description provided for @supportFaqQ5.
  ///
  /// In en, this message translates to:
  /// **'What happens if I violate community guidelines?'**
  String get supportFaqQ5;

  /// No description provided for @supportFaqA5.
  ///
  /// In en, this message translates to:
  /// **'Repeated violations may result in message restrictions or account limitations. Please follow the guidelines for a safe community.'**
  String get supportFaqA5;

  /// No description provided for @supportActionPreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get supportActionPreparingTitle;

  /// No description provided for @supportActionPreparingBody.
  ///
  /// In en, this message translates to:
  /// **'This action will be available soon.'**
  String get supportActionPreparingBody;

  /// No description provided for @supportSuggestionSubject.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get supportSuggestionSubject;

  /// No description provided for @supportBugSubject.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get supportBugSubject;

  /// No description provided for @supportEmailFooterUser.
  ///
  /// In en, this message translates to:
  /// **'User : {userId}'**
  String supportEmailFooterUser(String userId);

  /// No description provided for @supportEmailFooterVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version : {version}'**
  String supportEmailFooterVersion(String version);

  /// No description provided for @supportEmailLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open mail app. Please try again later.'**
  String get supportEmailLaunchFailed;

  /// No description provided for @appInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get appInfoTitle;

  /// No description provided for @appInfoSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get appInfoSettingsTitle;

  /// No description provided for @appInfoSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review licenses and policies.'**
  String get appInfoSettingsSubtitle;

  /// No description provided for @appInfoSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected services'**
  String get appInfoSectionTitle;

  /// No description provided for @appInfoSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See apps linked to this service.'**
  String get appInfoSectionSubtitle;

  /// No description provided for @appInfoVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appInfoVersionLabel(Object version);

  /// No description provided for @appInfoVersionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown version'**
  String get appInfoVersionUnknown;

  /// No description provided for @appInfoOpenLicenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Open licenses'**
  String get appInfoOpenLicenseTitle;

  /// No description provided for @appInfoRelatedAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'BIZPECT related apps'**
  String get appInfoRelatedAppsTitle;

  /// No description provided for @appInfoRelatedApp1Title.
  ///
  /// In en, this message translates to:
  /// **'Test app 1'**
  String get appInfoRelatedApp1Title;

  /// No description provided for @appInfoRelatedApp1Description.
  ///
  /// In en, this message translates to:
  /// **'A sample app for testing related services.'**
  String get appInfoRelatedApp1Description;

  /// No description provided for @appInfoRelatedApp2Title.
  ///
  /// In en, this message translates to:
  /// **'Test app 2'**
  String get appInfoRelatedApp2Title;

  /// No description provided for @appInfoRelatedApp2Description.
  ///
  /// In en, this message translates to:
  /// **'Another sample app for related integrations.'**
  String get appInfoRelatedApp2Description;

  /// No description provided for @appInfoExternalLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Open external link'**
  String get appInfoExternalLinkLabel;

  /// No description provided for @appInfoLinkPreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get appInfoLinkPreparingTitle;

  /// No description provided for @appInfoLinkPreparingBody.
  ///
  /// In en, this message translates to:
  /// **'This link will be available soon.'**
  String get appInfoLinkPreparingBody;

  /// No description provided for @openLicenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Open licenses'**
  String get openLicenseTitle;

  /// No description provided for @openLicenseHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Open source libraries'**
  String get openLicenseHeaderTitle;

  /// No description provided for @openLicenseHeaderBody.
  ///
  /// In en, this message translates to:
  /// **'This app uses the following open source libraries.'**
  String get openLicenseHeaderBody;

  /// No description provided for @openLicenseSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'License list'**
  String get openLicenseSectionTitle;

  /// No description provided for @openLicenseSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review the open source packages in use.'**
  String get openLicenseSectionSubtitle;

  /// No description provided for @openLicenseChipVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String openLicenseChipVersion(Object version);

  /// No description provided for @openLicenseChipLicense.
  ///
  /// In en, this message translates to:
  /// **'License: {license}'**
  String openLicenseChipLicense(Object license);

  /// No description provided for @openLicenseChipDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get openLicenseChipDetails;

  /// No description provided for @openLicenseTypeMit.
  ///
  /// In en, this message translates to:
  /// **'MIT'**
  String get openLicenseTypeMit;

  /// No description provided for @openLicenseTypeApache.
  ///
  /// In en, this message translates to:
  /// **'Apache 2.0'**
  String get openLicenseTypeApache;

  /// No description provided for @openLicenseTypeBsd3.
  ///
  /// In en, this message translates to:
  /// **'BSD 3-Clause'**
  String get openLicenseTypeBsd3;

  /// No description provided for @openLicenseTypeBsd2.
  ///
  /// In en, this message translates to:
  /// **'BSD 2-Clause'**
  String get openLicenseTypeBsd2;

  /// No description provided for @openLicenseTypeMpl2.
  ///
  /// In en, this message translates to:
  /// **'MPL 2.0'**
  String get openLicenseTypeMpl2;

  /// No description provided for @openLicenseTypeGpl.
  ///
  /// In en, this message translates to:
  /// **'GPL'**
  String get openLicenseTypeGpl;

  /// No description provided for @openLicenseTypeLgpl.
  ///
  /// In en, this message translates to:
  /// **'LGPL'**
  String get openLicenseTypeLgpl;

  /// No description provided for @openLicenseTypeIsc.
  ///
  /// In en, this message translates to:
  /// **'ISC'**
  String get openLicenseTypeIsc;

  /// No description provided for @openLicenseTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get openLicenseTypeUnknown;

  /// No description provided for @openLicenseUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get openLicenseUnknown;

  /// No description provided for @openLicenseEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No license information available.'**
  String get openLicenseEmptyMessage;

  /// No description provided for @openLicenseDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'{package} license'**
  String openLicenseDetailTitle(Object package);

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

  /// No description provided for @homeInboxSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Inbox'**
  String get homeInboxSummaryTitle;

  /// No description provided for @homeInboxSummaryPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get homeInboxSummaryPending;

  /// No description provided for @homeInboxSummaryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get homeInboxSummaryCompleted;

  /// No description provided for @homeInboxSummarySentResponses.
  ///
  /// In en, this message translates to:
  /// **'Responses'**
  String get homeInboxSummarySentResponses;

  /// No description provided for @homeInboxSummaryUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String homeInboxSummaryUpdatedAt(Object time);

  /// No description provided for @homeInboxSummaryRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get homeInboxSummaryRefresh;

  /// No description provided for @homeInboxSummaryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the summary.'**
  String get homeInboxSummaryLoadFailed;

  /// No description provided for @homeInboxSummaryItemSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} {count}'**
  String homeInboxSummaryItemSemantics(Object label, Object count);

  /// No description provided for @homeTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get homeTimelineTitle;

  /// No description provided for @homeTimelineEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet'**
  String get homeTimelineEmptyTitle;

  /// No description provided for @homeTimelineReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'New message received'**
  String get homeTimelineReceivedTitle;

  /// No description provided for @homeTimelineRespondedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get homeTimelineRespondedTitle;

  /// No description provided for @homeTimelineSentResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'Response arrived'**
  String get homeTimelineSentResponseTitle;

  /// No description provided for @homeTimelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{time}'**
  String homeTimelineSubtitle(Object time);

  /// No description provided for @homeDailyPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Question'**
  String get homeDailyPromptTitle;

  /// No description provided for @homeDailyPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to start a message'**
  String get homeDailyPromptHint;

  /// No description provided for @homeDailyPromptAction.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get homeDailyPromptAction;

  /// No description provided for @homeAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get homeAnnouncementTitle;

  /// No description provided for @homeAnnouncementSummary.
  ///
  /// In en, this message translates to:
  /// **'See what\'s new in Echowander.'**
  String get homeAnnouncementSummary;

  /// No description provided for @homeAnnouncementAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get homeAnnouncementAction;

  /// No description provided for @homeAnnouncementDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get homeAnnouncementDetailTitle;

  /// No description provided for @homeAnnouncementDetailBody.
  ///
  /// In en, this message translates to:
  /// **'We added improvements for a smoother experience.'**
  String get homeAnnouncementDetailBody;

  /// No description provided for @homePromptQ1.
  ///
  /// In en, this message translates to:
  /// **'What made you smile today?'**
  String get homePromptQ1;

  /// No description provided for @homePromptQ2.
  ///
  /// In en, this message translates to:
  /// **'What are you looking forward to this week?'**
  String get homePromptQ2;

  /// No description provided for @homePromptQ3.
  ///
  /// In en, this message translates to:
  /// **'What\'s a place you want to revisit?'**
  String get homePromptQ3;

  /// No description provided for @homePromptQ4.
  ///
  /// In en, this message translates to:
  /// **'Share a small win from today.'**
  String get homePromptQ4;

  /// No description provided for @homePromptQ5.
  ///
  /// In en, this message translates to:
  /// **'What\'s a habit you\'d like to build?'**
  String get homePromptQ5;

  /// No description provided for @homePromptQ6.
  ///
  /// In en, this message translates to:
  /// **'Who do you want to thank today?'**
  String get homePromptQ6;

  /// No description provided for @homePromptQ7.
  ///
  /// In en, this message translates to:
  /// **'What\'s a song you keep replaying?'**
  String get homePromptQ7;

  /// No description provided for @homePromptQ8.
  ///
  /// In en, this message translates to:
  /// **'Describe your day in three words.'**
  String get homePromptQ8;

  /// No description provided for @homePromptQ9.
  ///
  /// In en, this message translates to:
  /// **'What\'s something you learned recently?'**
  String get homePromptQ9;

  /// No description provided for @homePromptQ10.
  ///
  /// In en, this message translates to:
  /// **'If you could send one message to yourself, what would it be?'**
  String get homePromptQ10;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// No description provided for @profileEditNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileEditNicknameLabel;

  /// No description provided for @profileEditNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get profileEditNicknameHint;

  /// No description provided for @profileEditNicknameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get profileEditNicknameEmpty;

  /// No description provided for @profileEditNicknameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be at least {min} characters'**
  String profileEditNicknameTooShort(Object min);

  /// No description provided for @profileEditNicknameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Nickname can be up to {max} characters'**
  String profileEditNicknameTooLong(Object max);

  /// No description provided for @profileEditNicknameConsecutiveSpaces.
  ///
  /// In en, this message translates to:
  /// **'Consecutive spaces are not allowed'**
  String get profileEditNicknameConsecutiveSpaces;

  /// No description provided for @profileEditNicknameInvalidCharacters.
  ///
  /// In en, this message translates to:
  /// **'Only Korean, English, numbers, and underscore (_) are allowed'**
  String get profileEditNicknameInvalidCharacters;

  /// No description provided for @profileEditNicknameUnderscoreAtEnds.
  ///
  /// In en, this message translates to:
  /// **'Underscore (_) cannot be used at the beginning or end'**
  String get profileEditNicknameUnderscoreAtEnds;

  /// No description provided for @profileEditNicknameConsecutiveUnderscores.
  ///
  /// In en, this message translates to:
  /// **'Consecutive underscores (__) are not allowed'**
  String get profileEditNicknameConsecutiveUnderscores;

  /// No description provided for @profileEditNicknameForbidden.
  ///
  /// In en, this message translates to:
  /// **'This nickname is not allowed'**
  String get profileEditNicknameForbidden;

  /// No description provided for @profileEditNicknameChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get profileEditNicknameChecking;

  /// No description provided for @profileEditNicknameAvailable.
  ///
  /// In en, this message translates to:
  /// **'This nickname is available'**
  String get profileEditNicknameAvailable;

  /// No description provided for @profileEditNicknameTaken.
  ///
  /// In en, this message translates to:
  /// **'This nickname is already in use'**
  String get profileEditNicknameTaken;

  /// No description provided for @profileEditNicknameError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while checking'**
  String get profileEditNicknameError;

  /// No description provided for @profileEditAvatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profileEditAvatarLabel;

  /// No description provided for @profileEditAvatarChange.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get profileEditAvatarChange;

  /// No description provided for @profileEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileEditSave;

  /// No description provided for @profileEditCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileEditCancel;

  /// No description provided for @profileEditSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get profileEditSaveSuccess;

  /// No description provided for @profileEditSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again'**
  String get profileEditSaveFailed;

  /// No description provided for @profileEditImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image file is too large. Please select another image'**
  String get profileEditImageTooLarge;

  /// No description provided for @profileEditImageOptimizationFailed.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while processing the image. Please try again'**
  String get profileEditImageOptimizationFailed;

  /// No description provided for @profileEditCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Photo'**
  String get profileEditCropTitle;

  /// No description provided for @profileEditCropDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust the position as desired'**
  String get profileEditCropDescription;

  /// No description provided for @profileEditCropCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileEditCropCancel;

  /// No description provided for @profileEditCropComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get profileEditCropComplete;

  /// No description provided for @profileEditCropFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo edit failed'**
  String get profileEditCropFailedTitle;

  /// No description provided for @profileEditCropFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while editing the photo. Please try again.'**
  String get profileEditCropFailedMessage;

  /// No description provided for @profileEditCropFailedAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get profileEditCropFailedAction;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr', 'ja', 'ko', 'pt', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt': {
  switch (locale.countryCode) {
    case 'BR': return AppLocalizationsPtBr();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
    case 'pt': return AppLocalizationsPt();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
