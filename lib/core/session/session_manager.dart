import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'auth_rpc_client.dart';
import 'session_state.dart';
import 'session_tokens.dart';
import 'token_store.dart';

const _logPrefix = '[SessionManager]';

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final authRpcClientProvider = Provider<AuthRpcClient>((ref) {
  final baseUrl = AppConfigStore.current.authBaseUrl;
  if (baseUrl.isEmpty) {
    return DevAuthRpcClient();
  }
  return HttpAuthRpcClient(
    baseUrl: baseUrl,
    config: AppConfigStore.current,
  );
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
    if (kDebugMode) {
      debugPrint('$_logPrefix 세션 복원 시작 (현재 상태: ${state.status})');
    }
    state = state.copyWith(isBusy: true);

    final tokens = await _tokenStore.read();
    if (tokens == null) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 저장된 토큰 없음 → unauthenticated');
      }
      state = state.copyWith(
        status: SessionStatus.unauthenticated,
        isBusy: false,
        accessToken: null,
      );
      return;
    }
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 빈 토큰 발견 → 저장소 정리 → unauthenticated');
      }
      await _tokenStore.clear();
      state = state.copyWith(
        status: SessionStatus.unauthenticated,
        isBusy: false,
        accessToken: null,
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('$_logPrefix 토큰 로드 성공 (access=${tokens.accessToken.length}자, refresh=${tokens.refreshToken.length}자)');
      debugPrint('$_logPrefix 세션 검증 시작');
    }

    final isValid = await _authRpcClient.validateSession(tokens);
    if (isValid) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 세션 검증 성공 → authenticated');
      }
      state = state.copyWith(
        status: SessionStatus.authenticated,
        isBusy: false,
        accessToken: tokens.accessToken,
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('$_logPrefix 세션 검증 실패 → 리프레시 시도');
    }

    final refreshed = await _authRpcClient.refreshSession(tokens);
    if (refreshed == null) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 리프레시 실패 → 네트워크 오류 가능성, 기존 토큰 유지');
        debugPrint('$_logPrefix 다음 API 호출 시 401 에러 발생 시 재검증됨');
      }
      // 네트워크 오류일 수 있으므로 바로 세션 clear하지 않음
      // 기존 토큰으로 계속 사용, 실제 API 호출 시 401 에러가 발생하면 그때 재시도
      state = state.copyWith(
        status: SessionStatus.authenticated,
        isBusy: false,
        accessToken: tokens.accessToken, // 기존 토큰 유지
      );
      return;
    }
    if (refreshed.accessToken.isEmpty || refreshed.refreshToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 리프레시 응답에 빈 토큰 → 저장소 정리 → unauthenticated');
      }
      await _tokenStore.clear();
      state = state.copyWith(
        status: SessionStatus.unauthenticated,
        isBusy: false,
        accessToken: null,
        message: SessionMessage.sessionExpired,
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('$_logPrefix 리프레시 성공 → 토큰 저장 → authenticated');
    }
    await _tokenStore.save(refreshed);
    state = state.copyWith(
      status: SessionStatus.authenticated,
      isBusy: false,
      accessToken: refreshed.accessToken,
    );
  }

  Future<void> signInWithTokens(SessionTokens tokens) async {
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 로그인 실패: 빈 토큰');
      }
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
    if (kDebugMode) {
      debugPrint('$_logPrefix 로그인 성공: 토큰 저장 완료 (access=${tokens.accessToken.length}자)');
    }
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
    if (kDebugMode) {
      debugPrint('$_logPrefix 소셜 로그인 시작: provider=$provider');
    }
    state = state.copyWith(isBusy: true);
    final result = await _authRpcClient.exchangeSocialToken(
      provider: provider,
      idToken: idToken,
    );
    final tokens = result.tokens;
    if (tokens == null) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 소셜 로그인 실패: 토큰 응답 없음 (error=${result.error})');
      }
      state = state.copyWith(
        status: SessionStatus.unauthenticated,
        isBusy: false,
        accessToken: null,
        message: _mapLoginError(result.error),
      );
      return;
    }
    if (kDebugMode) {
      debugPrint('$_logPrefix 소셜 로그인 토큰 수신: access=${tokens.accessToken.length}자');
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
