import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';

enum SocialAuthStatus {
  success,
  cancelled,
  networkError,
  failed,
}

class SocialAuthResult {
  const SocialAuthResult._(this.status, this.token);

  final SocialAuthStatus status;
  final String? token;

  const SocialAuthResult.success(String token) : this._(SocialAuthStatus.success, token);
  const SocialAuthResult.cancelled() : this._(SocialAuthStatus.cancelled, null);
  const SocialAuthResult.networkError() : this._(SocialAuthStatus.networkError, null);
  const SocialAuthResult.failed() : this._(SocialAuthStatus.failed, null);
}

class SocialAuthService {
  SocialAuthService({required AppConfig config}) : _config = config;

  final AppConfig _config;
  bool _googleInitialized = false;

  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: _config.googleIosClientId.isEmpty ? null : _config.googleIosClientId,
          serverClientId:
              _config.googleServerClientId.isEmpty ? null : _config.googleServerClientId,
        );
        _googleInitialized = true;
      }
      final user = await GoogleSignIn.instance.authenticate();
      final token = user.authentication.idToken;
      if (token == null || token.isEmpty) {
        return const SocialAuthResult.failed();
      }
      return SocialAuthResult.success(token);
    } on GoogleSignInException catch (error) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          return const SocialAuthResult.cancelled();
        case GoogleSignInExceptionCode.interrupted:
          return const SocialAuthResult.networkError();
        default:
          return const SocialAuthResult.failed();
      }
    } on PlatformException {
      return const SocialAuthResult.failed();
    }
  }

  Future<SocialAuthResult> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final token = credential.identityToken;
      if (token == null || token.isEmpty) {
        return const SocialAuthResult.failed();
      }
      return SocialAuthResult.success(token);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code.toString().toLowerCase().contains('canceled')) {
        return const SocialAuthResult.cancelled();
      }
      return const SocialAuthResult.failed();
    } on PlatformException catch (error) {
      if (error.code == 'network_error') {
        return const SocialAuthResult.networkError();
      }
      return const SocialAuthResult.failed();
    }
  }

  Future<SocialAuthResult> signInWithKakao() async {
    try {
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }
      if (token.accessToken.isEmpty) {
        return const SocialAuthResult.failed();
      }
      return SocialAuthResult.success(token.accessToken);
    } on kakao.KakaoClientException catch (error) {
      if (error.toString().toLowerCase().contains('cancel')) {
        return const SocialAuthResult.cancelled();
      }
      if (error.toString().toLowerCase().contains('network')) {
        return const SocialAuthResult.networkError();
      }
      return const SocialAuthResult.failed();
    } on kakao.KakaoApiException catch (_) {
      return const SocialAuthResult.failed();
    }
  }
}
