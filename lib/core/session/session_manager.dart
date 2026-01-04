import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'auth_rpc_client.dart';
import 'session_state.dart';
import 'session_tokens.dart';
import 'token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final authRpcClientProvider = Provider<AuthRpcClient>((ref) {
  final baseUrl = AppConfigStore.current.authBaseUrl;
  if (baseUrl.isEmpty) {
    return DevAuthRpcClient();
  }
  return HttpAuthRpcClient(baseUrl: baseUrl);
});

final sessionManagerProvider = NotifierProvider<SessionManager, SessionState>(
  SessionManager.new,
);

class SessionManager extends Notifier<SessionState> {
  late final TokenStore _tokenStore;
  late final AuthRpcClient _authRpcClient;

  @override
  SessionState build() {
    _tokenStore = ref.read(tokenStoreProvider);
    _authRpcClient = ref.read(authRpcClientProvider);
    return const SessionState.unknown();
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isBusy: true);
    final tokens = await _tokenStore.read();
    if (tokens == null) {
      state = state.copyWith(
        status: SessionStatus.unauthenticated,
        isBusy: false,
        accessToken: null,
      );
      return;
    }

    final isValid = await _authRpcClient.validateSession(tokens);
    if (isValid) {
      state = state.copyWith(
        status: SessionStatus.authenticated,
        isBusy: false,
        accessToken: tokens.accessToken,
      );
      return;
    } else {
      final refreshed = await _authRpcClient.refreshSession(tokens);
      if (refreshed == null) {
        await _tokenStore.clear();
        state = state.copyWith(
          status: SessionStatus.unauthenticated,
          isBusy: false,
          accessToken: null,
          message: SessionMessage.sessionExpired,
        );
        return;
      }
      await _tokenStore.save(refreshed);
      state = state.copyWith(
        status: SessionStatus.authenticated,
        isBusy: false,
        accessToken: refreshed.accessToken,
      );
    }
  }

  Future<void> signInWithTokens(SessionTokens tokens) async {
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
      state = state.copyWith(
        status: SessionStatus.unauthenticated,
        isBusy: false,
        accessToken: null,
        message: SessionMessage.loginFailed,
      );
      return;
    }
    state = state.copyWith(isBusy: true);
    await _tokenStore.save(tokens);
    state = state.copyWith(
      status: SessionStatus.authenticated,
      isBusy: false,
      accessToken: tokens.accessToken,
    );
  }

  Future<void> signInWithSocialToken({
    required String provider,
    required String idToken,
  }) async {
    state = state.copyWith(isBusy: true);
    final result = await _authRpcClient.exchangeSocialToken(
      provider: provider,
      idToken: idToken,
    );
    final tokens = result.tokens;
    if (tokens == null) {
      state = state.copyWith(
        status: SessionStatus.unauthenticated,
        isBusy: false,
        accessToken: null,
        message: _mapLoginError(result.error),
      );
      return;
    }
    await signInWithTokens(tokens);
  }

  Future<void> signOut() async {
    state = state.copyWith(isBusy: true);
    await _tokenStore.clear();
    state = state.copyWith(
      status: SessionStatus.unauthenticated,
      isBusy: false,
      accessToken: null,
    );
  }

  void reportLoginMessage(SessionMessage message) {
    state = state.copyWith(
      status: SessionStatus.unauthenticated,
      isBusy: false,
      accessToken: null,
      message: message,
    );
  }

  void clearMessage() {
    state = state.copyWith(resetMessage: true);
  }

  SessionMessage _mapLoginError(AuthRpcLoginError? error) {
    switch (error) {
      case AuthRpcLoginError.network:
        return SessionMessage.loginNetworkError;
      case AuthRpcLoginError.invalidToken:
        return SessionMessage.loginInvalidToken;
      case AuthRpcLoginError.unsupportedProvider:
        return SessionMessage.loginUnsupportedProvider;
      case AuthRpcLoginError.userSyncFailed:
        return SessionMessage.loginUserSyncFailed;
      case AuthRpcLoginError.serverMisconfigured:
        return SessionMessage.loginServiceUnavailable;
      case AuthRpcLoginError.missingPayload:
      case AuthRpcLoginError.unknown:
      default:
        return SessionMessage.loginFailed;
    }
  }
}
