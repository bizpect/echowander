import 'dart:async';

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

  /// Single-flight 락: 동시에 여러 restoreSession 호출을 1회로 병합
  Completer<void>? _restoreCompleter;

  /// restoreSession 실패 쿨다운: 최근 실패 후 일정 시간 동안 재시도 차단
  DateTime? _lastRestoreFailedAt;
  static const _restoreCooldown = Duration(seconds: 15);

  /// restoreSession 쿨다운 중인지 확인
  bool get isRestoreBlocked {
    if (_lastRestoreFailedAt == null) return false;
    return DateTime.now().difference(_lastRestoreFailedAt!) < _restoreCooldown;
  }

  @override
  SessionState build() {
    _tokenStore = ref.read(tokenStoreProvider);
    _authRpcClient = ref.read(authRpcClientProvider);
    return const SessionState.unknown();
  }

  /// 세션 복원 (single-flight + cooldown)
  ///
  /// 동시에 여러 호출이 와도 실제 복원 로직은 1번만 실행되고,
  /// 나머지 호출자는 동일한 Future를 await합니다.
  /// 최근 실패 후 cooldown 기간에는 즉시 실패 반환합니다.
  Future<void> restoreSession() async {
    // 쿨다운 중이면 즉시 예외 (무한 루프 방지)
    if (isRestoreBlocked) {
      if (kDebugMode) {
        debugPrint('$_logPrefix restoreSession 쿨다운 중 → 즉시 실패');
      }
      throw RestoreSessionBlockedException();
    }

    // 이미 복원 진행 중이면 기존 Future를 await
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 세션 복원 진행 중 → 기존 작업 대기 (single-flight)');
      }
      return _restoreCompleter!.future;
    }

    _restoreCompleter = Completer<void>();

    try {
      await _doRestoreSession();
      // 성공 시 쿨다운 해제
      _lastRestoreFailedAt = null;
      _restoreCompleter!.complete();
    } catch (e) {
      // 실패 시 쿨다운 기록
      _lastRestoreFailedAt = DateTime.now();
      _restoreCompleter!.completeError(e);
      rethrow;
    }
  }

  /// 실제 세션 복원 로직 (내부용)
  Future<void> _doRestoreSession() async {
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

    final refreshResult = await _authRpcClient.refreshSession(tokens);

    switch (refreshResult) {
      case RefreshSuccess(:final tokens):
        // 성공: 새 토큰 저장
        if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
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
          throw RestoreSessionFailedException();
        }

        if (kDebugMode) {
          debugPrint('$_logPrefix 리프레시 성공 → 토큰 저장 → authenticated');
        }
        await _tokenStore.save(tokens);
        state = state.copyWith(
          status: SessionStatus.authenticated,
          isBusy: false,
          accessToken: tokens.accessToken,
        );

      case RefreshAuthFailed():
        // 인증 실패 확정: refresh 토큰 만료/무효 (401/403)
        // → 토큰 clear + unauthenticated (로그아웃)
        if (kDebugMode) {
          debugPrint('$_logPrefix 인증 실패 확정 → 토큰 정리 → unauthenticated');
        }
        await _tokenStore.clear();
        state = state.copyWith(
          status: SessionStatus.unauthenticated,
          isBusy: false,
          accessToken: null,
          message: SessionMessage.sessionExpired,
        );
        throw RestoreSessionFailedException();

      case RefreshTransientError():
        // 일시 장애: 네트워크/서버 문제
        // → 토큰 유지 + authenticated 유지 (로그아웃 금지!)
        if (kDebugMode) {
          debugPrint('$_logPrefix 일시 장애 → 토큰 유지 + authenticated 유지 (로그아웃 금지)');
        }
        state = state.copyWith(
          status: SessionStatus.authenticated,
          isBusy: false,
          accessToken: tokens.accessToken,
          message: SessionMessage.authRefreshFailed,
        );
        // 일시 장애 예외 → AuthExecutor에서 transientError로 처리
        throw RestoreSessionTransientException();
    }
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

/// restoreSession이 쿨다운 중일 때 발생하는 예외
class RestoreSessionBlockedException implements Exception {
  @override
  String toString() => 'RestoreSessionBlockedException: 쿨다운 중';
}

/// restoreSession이 실패했을 때 발생하는 예외 (인증 실패 확정)
class RestoreSessionFailedException implements Exception {
  @override
  String toString() => 'RestoreSessionFailedException: 세션 복원 실패 (인증 만료)';
}

/// restoreSession이 일시 장애로 실패했을 때 발생하는 예외
/// (네트워크/서버 문제, 로그아웃 아님)
class RestoreSessionTransientException implements Exception {
  @override
  String toString() => 'RestoreSessionTransientException: 세션 복원 일시 장애';
}
