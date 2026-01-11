import '../../../l10n/app_localizations.dart';

enum AuthProviderType {
  kakao,
  google,
  apple,
  email,
  unknown,
}

AuthProviderType authProviderFromString(String? provider) {
  switch (provider) {
    case 'kakao':
      return AuthProviderType.kakao;
    case 'google':
      return AuthProviderType.google;
    case 'apple':
      return AuthProviderType.apple;
    case 'email':
      return AuthProviderType.email;
    default:
      return AuthProviderType.unknown;
  }
}

String authProviderLoginLabel(
  AppLocalizations l10n,
  AuthProviderType provider,
) {
  switch (provider) {
    case AuthProviderType.kakao:
      return l10n.authProviderKakaoLogin;
    case AuthProviderType.google:
      return l10n.authProviderGoogleLogin;
    case AuthProviderType.apple:
      return l10n.authProviderAppleLogin;
    case AuthProviderType.email:
    case AuthProviderType.unknown:
      return l10n.authProviderUnknownLogin;
  }
}
