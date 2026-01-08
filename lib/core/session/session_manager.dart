import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'auth_rpc_client.dart';
import 'session_state.dart';
import 'session_tokens.dart';
import 'token_store.dart';

const _logPrefix = '[SessionManager]';

/// restoreSession 내부 함수의 결과 모델
/// 상태 변경 없이 결과만 반환하여 wrapper에서 일관된 상태 전환 보장
sealed class RestoreOutcome {
  const RestoreOutcome();

  /// 성공: 새 토큰 발급 또는 기존 토큰 유효
  const factory RestoreOutcome.success(SessionTokens tokens) = RestoreSuccess;

  /// 인증 실패 확정: 토큰 없음 또는 refresh 토큰 만료/무효
  /// → 토큰 clear + unauthenticated (로그아웃)
  const factory RestoreOutcome.authFailed() = RestoreAuthFailed;

  /// 일시 장애: 네트워크/서버 문제
  /// → 토큰 유지 + authenticated 유지 (로그아웃 금지)
  const factory RestoreOutcome.transient() = RestoreTransient;
}

class RestoreSuccess extends RestoreOutcome {
  const RestoreSuccess(this.tokens);
  final SessionTokens tokens;
}

class RestoreAuthFailed extends RestoreOutcome {
  const RestoreAuthFailed();
}

class RestoreTransient extends RestoreOutcome {
  const RestoreTransient();
}

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

  /// restoreInFlight Future (외부에서 await 가능)
  /// 
  /// SSOT: 복구 중인지 판단하는 단일 소스
  /// status.refreshing은 파생값이며, restoreInFlight와 항상 동기화되어야 함
  Future<void>? get restoreInFlight {
    final completer = _restoreCompleter;
    if (completer != null && !completer.isCompleted) {
      return completer.future;
    }
    // ✅ 불변식 검증: status==refreshing인데 restoreInFlight가 null이면 구조적 버그
    if (state.status == SessionStatus.refreshing) {
      assert(
        false,
        '$_logPrefix ⚠️ 불변식 위반: status==refreshing인데 restoreInFlight==null '
        '(completer=${completer != null ? "completed" : "null"})',
      );
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix ⚠️ 불변식 위반: status==refreshing인데 restoreInFlight==null '
          '(completer=${completer != null ? "completed" : "null"})',
        );
      }
    }
    return null;
  }

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
  ///
  /// 반환값: restoreInFlight Future (외부에서 await 가능)
  ///
  /// 상태 전환 순서 (절대 변경 금지):
  /// 1. 기존 inFlight 확인 → 있으면 join
  /// 2. 새 completer 생성 → _restoreCompleter 할당
  /// 3. state.status = refreshing (이 순서로 "refreshing인데 inFlight 없음" 방지)
  /// 4. 내부 함수 실행 (결과만 반환, 상태 변경 없음)
  /// 5. 결과에 따라 최종 state 세팅
  /// 6. completer complete/completeError
  /// 7. _restoreCompleter = null (이 순서로 "inFlight 정리 → 아직 refreshing" 방지)
  Future<void> restoreSession() async {
    // 쿨다운 중이면 즉시 예외 (무한 루프 방지)
    if (isRestoreBlocked) {
      if (kDebugMode) {
        debugPrint('$_logPrefix restoreSession 쿨다운 중 → 즉시 실패');
      }
      throw RestoreSessionBlockedException();
    }

    // ✅ 1단계: 기존 inFlight 확인 → 있으면 join (재호출 금지)
    final existing = _restoreCompleter;
    if (existing != null && !existing.isCompleted) {
      if (kDebugMode) {
        debugPrint('$_logPrefix restoreSession join existing (inFlight)');
      }
      return existing.future;
    }

    // ✅ 2단계: 새 Completer 생성 및 할당 (반드시 상태 전환 전)
    final completer = Completer<void>();
    _restoreCompleter = completer;

    if (kDebugMode) {
      debugPrint('$_logPrefix restoreSession start (new)');
    }

    // ✅ 3단계: refreshing 상태로 전환 (inFlight 할당 후)
    // 이 순서로 "refreshing인데 inFlight 없음" 상태를 구조적으로 방지
    state = state.copyWith(
      status: SessionStatus.refreshing,
      isBusy: true,
    );

    // ✅ 불변식 검증: refreshing이면 반드시 inFlight가 있어야 함
    assert(
      _restoreCompleter != null && !_restoreCompleter!.isCompleted,
      '$_logPrefix 불변식 위반: refreshing 상태인데 inFlight가 null 또는 completed',
    );

    RestoreOutcome? outcome;
    try {
      // ✅ 4단계: 내부 함수 실행 (결과만 반환, 상태 변경 없음)
      outcome = await _restoreSessionInternal();
      
      // ✅ 5단계: 결과에 따라 최종 state 세팅 (completer 완료 전)
      switch (outcome) {
        case RestoreSuccess(:final tokens):
          // 성공: 토큰 저장 및 authenticated 상태
          await _tokenStore.save(tokens);
          state = state.copyWith(
            status: SessionStatus.authenticated,
            isBusy: false,
            accessToken: tokens.accessToken,
          );
          _lastRestoreFailedAt = null; // 쿨다운 해제
          if (kDebugMode) {
            debugPrint('$_logPrefix restoreSession done (success)');
          }

        case RestoreAuthFailed():
          // 인증 실패: 토큰 clear 및 unauthenticated 상태
          await _tokenStore.clear();
          state = state.copyWith(
            status: SessionStatus.unauthenticated,
            isBusy: false,
            accessToken: null,
            message: SessionMessage.sessionExpired,
          );
          _lastRestoreFailedAt = DateTime.now(); // 쿨다운 기록
          if (kDebugMode) {
            debugPrint('$_logPrefix restoreSession done (authFailed)');
          }

        case RestoreTransient():
          // 일시 장애: 토큰 유지 및 authenticated 유지
          // (내부 함수에서 이미 토큰을 읽었으므로, 기존 토큰 유지)
          final currentTokens = await _tokenStore.read();
          state = state.copyWith(
            status: SessionStatus.authenticated,
            isBusy: false,
            accessToken: currentTokens?.accessToken,
            message: SessionMessage.authRefreshFailed,
          );
          _lastRestoreFailedAt = DateTime.now(); // 쿨다운 기록
          if (kDebugMode) {
            debugPrint('$_logPrefix restoreSession done (transient)');
          }
      }

      // ✅ 6단계: completer 완료 (상태 전환 후)
      if (!completer.isCompleted) {
        completer.complete();
      }

      // ✅ 예외 변환: outcome에 따라 적절한 예외 throw
      switch (outcome) {
        case RestoreAuthFailed():
          throw RestoreSessionFailedException();
        case RestoreTransient():
          throw RestoreSessionTransientException();
        case RestoreSuccess():
          // 성공 케이스는 예외 없음
          break;
      }
    } catch (e, st) {
      // 예상치 못한 예외: 일시 장애로 처리
      if (outcome == null) {
        outcome = const RestoreOutcome.transient();
        _lastRestoreFailedAt = DateTime.now();
        
        // 상태는 transient와 동일하게 처리
        final currentTokens = await _tokenStore.read();
        state = state.copyWith(
          status: SessionStatus.authenticated,
          isBusy: false,
          accessToken: currentTokens?.accessToken,
          message: SessionMessage.authRefreshFailed,
        );
      }

      // ✅ 6단계: completer 완료 (에러)
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
      if (kDebugMode) {
        debugPrint('$_logPrefix restoreSession done (error: $e)');
      }
      
      // 예외를 적절한 타입으로 변환하여 rethrow
      if (e is! RestoreSessionBlockedException &&
          e is! RestoreSessionFailedException &&
          e is! RestoreSessionTransientException) {
        // 예상치 못한 예외는 transient로 처리
        throw RestoreSessionTransientException();
      }
      rethrow;
    } finally {
      // ✅ 7단계: _restoreCompleter 정리 (마지막)
      // 불변식 검증: refreshing 상태면 안 됨
      if (identical(_restoreCompleter, completer)) {
        // 상태가 아직 refreshing이면 불변식 위반
        if (state.status == SessionStatus.refreshing) {
          assert(
            false,
            '$_logPrefix 불변식 위반: _restoreCompleter 정리 시점에 status가 여전히 refreshing',
          );
          if (kDebugMode) {
            debugPrint(
              '$_logPrefix ⚠️ 불변식 위반: _restoreCompleter 정리 시점에 status가 여전히 refreshing',
            );
          }
        }
        _restoreCompleter = null;
      }
    }
  }

  /// 실제 세션 복원 로직 (내부용)
  ///
  /// 중요: 상태 변경 금지. 오직 결과만 반환.
  /// 상태 전환은 wrapper(restoreSession)에서만 수행.
  Future<RestoreOutcome> _restoreSessionInternal() async {
    if (kDebugMode) {
      debugPrint('$_logPrefix _restoreSessionInternal 시작');
    }

    final tokens = await _tokenStore.read();
    if (tokens == null) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 저장된 토큰 없음 → authFailed');
      }
      return const RestoreOutcome.authFailed();
    }
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 빈 토큰 발견 → authFailed');
      }
      // 토큰 clear는 wrapper에서 수행
      return const RestoreOutcome.authFailed();
    }

    if (kDebugMode) {
      debugPrint('$_logPrefix 토큰 로드 성공 (access=${tokens.accessToken.length}자, refresh=${tokens.refreshToken.length}자)');
      debugPrint('$_logPrefix 세션 검증 시작');
    }

    final isValid = await _authRpcClient.validateSession(tokens);
    if (isValid) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 세션 검증 성공 → success');
      }
      // 기존 토큰 유효
      return RestoreOutcome.success(tokens);
    }

    if (kDebugMode) {
      debugPrint('$_logPrefix 세션 검증 실패 → 리프레시 시도');
    }

    final refreshResult = await _authRpcClient.refreshSession(tokens);

    switch (refreshResult) {
      case RefreshSuccess(:final tokens):
        // 성공: 새 토큰 발급
        if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
          if (kDebugMode) {
            debugPrint('$_logPrefix 리프레시 응답에 빈 토큰 → authFailed');
          }
          // 토큰 clear는 wrapper에서 수행
          return const RestoreOutcome.authFailed();
        }

        if (kDebugMode) {
          debugPrint('$_logPrefix 리프레시 성공 → success');
        }
        // 토큰 저장은 wrapper에서 수행
        return RestoreOutcome.success(tokens);

      case RefreshAuthFailed():
        // 인증 실패 확정: refresh 토큰 만료/무효 (401/403)
        if (kDebugMode) {
          debugPrint('$_logPrefix 인증 실패 확정 → authFailed');
        }
        // 토큰 clear는 wrapper에서 수행
        return const RestoreOutcome.authFailed();

      case RefreshTransientError():
        // 일시 장애: 네트워크/서버 문제
        if (kDebugMode) {
          debugPrint('$_logPrefix 일시 장애 → transient');
        }
        // 기존 토큰 유지 (wrapper에서 처리)
        return const RestoreOutcome.transient();

      case RefreshFatalMisconfig(:final reason):
        // 치명적 설정 오류: 요청 자체가 잘못됨
        if (kDebugMode) {
          debugPrint('$_logPrefix 치명적 설정 오류: $reason → authFailed');
        }
        // 토큰 clear는 wrapper에서 수행
        return const RestoreOutcome.authFailed();
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
