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
  String get loginKakao => 'Continue with Kakao';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginApple => 'Continue with Apple';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeGreeting => 'Welcome back';

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
}
