import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'auth_rpc_client.dart';
import 'session_state.dart';
import 'session_tokens.dart';
import 'token_store.dart';

const _logPrefix = '[SessionManager]';

/// 토큰 fingerprint 생성 (SHA256 prefix 12자, 민감정보 제외 로깅용)
String _tokenFingerprint(String token) {
  final bytes = utf8.encode(token);
  final digest = sha256.convert(bytes);
  return digest.toString().substring(0, 12);
}

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

  /// Silent refresh single-flight 락: 동시에 여러 silentRefresh 호출을 1회로 병합
  Completer<void>? _silentRefreshCompleter;

  /// Silent refresh 쿨다운: 최근 refresh 후 일정 시간 동안 재시도 차단 (연타 방지)
  DateTime? _lastSilentRefreshAt;
  static const _silentRefreshCooldown = Duration(seconds: 30);

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

  /// 세션 만료 확정 및 토큰 purge (단일 진입점)
  ///
  /// 어떤 경로에서 실패하든 반드시 동일한 결말로 수렴합니다:
  /// - TokenStore purge
  /// - state = unauthenticated + message = sessionExpired
  /// - 재시도 금지 플래그/쿨다운 갱신
  Future<void> _markSessionExpiredAndPurge({
    String reason = 'session_expired',
    String source = 'unknown',
  }) async {
    if (kDebugMode) {
      debugPrint('$_logPrefix markSessionExpiredAndPurge (reason=$reason, source=$source)');
    }

    await _tokenStore.clear();
    state = state.copyWith(
      status: SessionStatus.unauthenticated,
      isBusy: false,
      accessToken: null,
      message: SessionMessage.sessionExpired,
    );
    _lastRestoreFailedAt = DateTime.now();
    _lastSilentRefreshAt = DateTime.now(); // 쿨다운 갱신
  }

  /// SessionMessage consume (1회성 이벤트 처리)
  ///
  /// 알럿 표시 후 반드시 호출하여 중복 알럿을 방지합니다.
  void consumeMessage(SessionMessage message) {
    if (state.message == message) {
      state = state.copyWith(resetMessage: true);
      if (kDebugMode) {
        debugPrint('$_logPrefix consumeMessage: $message');
      }
    }
  }

  /// Silent refresh in-flight Future (외부에서 await 가능)
  Future<void>? get silentRefreshInFlight {
    final completer = _silentRefreshCompleter;
    if (completer != null && !completer.isCompleted) {
      return completer.future;
    }
    return null;
  }

  /// 401 발생 시 처리 (단일 진입점)
  ///
  /// 정책:
  /// - unauthenticated면 바로 return
  /// - cooldown이면 return
  /// - in-flight 있으면 join
  /// - refresh 시도(필요 시) → 성공하면 상태 최소 업데이트
  /// - 실패 확정이면 purge + unauthenticated로 전환(재시도 금지 플래그 포함)
  ///
  /// 이 메서드를 통해 401 처리가 단일 진입점으로 수렴하여,
  /// 갱신 정책/중복 방지/실패 처리/로그인 이동 트리거가 한 군데로만 흐르게 됩니다.
  Future<void> handleUnauthorized({
    String reason = 'unauthorized',
    String source = 'unknown',
  }) async {
    if (kDebugMode) {
      debugPrint('$_logPrefix handleUnauthorized start (reason=$reason, source=$source)');
    }

    // ✅ unauthenticated 상태에서는 바로 return
    if (state.status == SessionStatus.unauthenticated) {
      if (kDebugMode) {
        debugPrint('$_logPrefix handleUnauthorized skip: 이미 unauthenticated 상태');
      }
      return;
    }

    // ✅ cooldown 중에도 refresh 불가(토큰 없음/invalid 확정) 상황은 즉시 purge 확정
    // cooldown은 "refresh 시도 연타 방지" 목적이지 "만료 확정 회피" 목적이 아님
    final tokens = await _tokenStore.read();
    if (tokens == null || tokens.refreshToken.isEmpty) {
      // 토큰이 없으면 즉시 purge 확정
      if (kDebugMode) {
        debugPrint('$_logPrefix handleUnauthorized: 토큰 없음 → 즉시 purge 확정');
      }
      await _markSessionExpiredAndPurge(reason: 'no_tokens', source: source);
      return;
    }

    // ✅ cooldown이면 return (단, 위에서 토큰 없음은 이미 처리됨)
    if (isSilentRefreshBlocked) {
      if (kDebugMode) {
        debugPrint('$_logPrefix handleUnauthorized skip: 쿨다운 중');
      }
      return;
    }

    // ✅ in-flight 있으면 join 후 상태 검증
    final existing = _silentRefreshCompleter;
    if (existing != null && !existing.isCompleted) {
      if (kDebugMode) {
        debugPrint('$_logPrefix handleUnauthorized join existing in-flight');
      }
      try {
        await existing.future;
        // ✅ join 후 상태 검증: 이미 unauthenticated면 return
        final currentState = state;
        if (currentState.status == SessionStatus.unauthenticated) {
          if (kDebugMode) {
            debugPrint('$_logPrefix handleUnauthorized: in-flight 완료 후 unauthenticated 확인');
          }
          return;
        }
        // authenticated인데도 401 원인이 계속이면 재시도 (쿨다운 허용 시)
        // 여기서는 이미 in-flight가 완료되었으므로 추가 처리 불필요
      } catch (e) {
        // in-flight 실패: 상태 검증 후 필요 시 purge 확정
        if (kDebugMode) {
          debugPrint('$_logPrefix handleUnauthorized in-flight 실패: $e');
        }
        final currentState = state;
        if (currentState.status != SessionStatus.unauthenticated) {
          // 실패했는데도 unauthenticated가 아니면 purge 확정
          await _markSessionExpiredAndPurge(reason: 'in_flight_failed', source: source);
        }
      }
      return;
    }

    // ✅ silentRefreshIfNeeded를 통해서만 refresh 시도
    await silentRefreshIfNeeded(reason: '401:$source');
  }

  /// Silent refresh 쿨다운 중인지 확인
  bool get isSilentRefreshBlocked {
    if (_lastSilentRefreshAt == null) return false;
    return DateTime.now().difference(_lastSilentRefreshAt!) < _silentRefreshCooldown;
  }

  /// Silent refresh (사용자 모르게 토큰 갱신, UI 영향 최소화)
  ///
  /// 만료 임박/만료 상황에서만 refresh를 시도하며,
  /// single-flight + cooldown으로 연타/무한 반복을 방지합니다.
  ///
  /// 성공 시: 토큰 저장, 상태는 authenticated 유지 (isBusy만 변경)
  /// 실패 확정 시: purge + unauthenticated 전환
  Future<void> silentRefreshIfNeeded({String reason = 'proactive'}) async {
    // ✅ unauthenticated 상태에서는 호출 차단
    if (state.status == SessionStatus.unauthenticated) {
      if (kDebugMode) {
        debugPrint('$_logPrefix silentRefreshIfNeeded 차단: 이미 unauthenticated 상태');
      }
      return;
    }

    // ✅ 쿨다운 중이면 skip
    if (isSilentRefreshBlocked) {
      if (kDebugMode) {
        debugPrint('$_logPrefix silentRefreshIfNeeded skip: 쿨다운 중 (reason=$reason)');
      }
      return;
    }

    // ✅ in-flight가 있으면 join
    final existing = _silentRefreshCompleter;
    if (existing != null && !existing.isCompleted) {
      if (kDebugMode) {
        debugPrint('$_logPrefix silentRefreshIfNeeded join existing (reason=$reason)');
      }
      return existing.future;
    }

    // ✅ 만료 임박 확인
    final accessToken = state.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix silentRefreshIfNeeded skip: accessToken 없음');
      }
      return;
    }

    // JWT 만료 임박 확인 (60초 이내)
    final parts = accessToken.split('.');
    if (parts.length != 3) {
      if (kDebugMode) {
        debugPrint('$_logPrefix silentRefreshIfNeeded skip: JWT 형식 아님');
      }
      return;
    }

    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = (map['exp'] as num?)?.toInt();
      if (exp == null) {
        if (kDebugMode) {
          debugPrint('$_logPrefix silentRefreshIfNeeded skip: exp 없음');
        }
        return;
      }

      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final secondsLeft = exp - nowSec;
      if (secondsLeft > 60) {
        // 만료 임박 아님 (60초 초과)
        if (kDebugMode) {
          debugPrint('$_logPrefix silentRefreshIfNeeded skip: 만료 임박 아님 ($secondsLeft초 남음)');
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix silentRefreshIfNeeded skip: JWT 파싱 실패: $e');
      }
      return;
    }

    // ✅ 새 completer 생성
    final completer = Completer<void>();
    _silentRefreshCompleter = completer;

    if (kDebugMode) {
      debugPrint('$_logPrefix silentRefreshIfNeeded start (reason=$reason)');
    }

    try {
      // ✅ 내부 함수 실행 (결과만 반환, 상태 변경 없음)
      final outcome = await _restoreSessionInternal();

      switch (outcome) {
        case RestoreSuccess(:final tokens):
          // ✅ 토큰 변경 여부 비교 (fp/iat/exp) 후 실제 변경 시에만 저장
          final currentTokens = await _tokenStore.read();
          final tokenChanged = currentTokens == null ||
              currentTokens.accessToken != tokens.accessToken ||
              currentTokens.refreshToken != tokens.refreshToken;

          if (tokenChanged) {
            // 토큰이 실제로 변경된 경우에만 저장
            await _tokenStore.save(tokens);
            if (kDebugMode) {
              debugPrint('$_logPrefix silentRefreshIfNeeded: 토큰 변경됨 → 저장');
            }
          } else {
            if (kDebugMode) {
              debugPrint('$_logPrefix silentRefreshIfNeeded: 토큰 변경 없음 → 저장 생략');
            }
          }

          // 상태는 authenticated 유지 (isBusy만 변경)
          state = state.copyWith(
            status: SessionStatus.authenticated,
            isBusy: false,
            accessToken: tokens.accessToken,
          );
          _lastSilentRefreshAt = DateTime.now();
          _lastRestoreFailedAt = null; // 쿨다운 해제
          if (kDebugMode) {
            debugPrint('$_logPrefix silentRefreshIfNeeded done (success)');
          }

        case RestoreAuthFailed():
          // 인증 실패 확정: 단일 진입점으로 purge 확정
          await _markSessionExpiredAndPurge(reason: 'refresh_failed', source: 'silentRefresh');
          if (kDebugMode) {
            debugPrint('$_logPrefix silentRefreshIfNeeded done (authFailed)');
          }

        case RestoreTransient():
          // 일시 장애: 토큰 유지 및 authenticated 유지
          final currentTokens = await _tokenStore.read();
          state = state.copyWith(
            status: SessionStatus.authenticated,
            isBusy: false,
            accessToken: currentTokens?.accessToken,
          );
          _lastSilentRefreshAt = DateTime.now();
          if (kDebugMode) {
            debugPrint('$_logPrefix silentRefreshIfNeeded done (transient)');
          }
      }

      completer.complete();
    } catch (e, st) {
      // 예상치 못한 예외: 일시 장애로 처리
      final currentTokens = await _tokenStore.read();
      state = state.copyWith(
        status: SessionStatus.authenticated,
        isBusy: false,
        accessToken: currentTokens?.accessToken,
      );
      _lastSilentRefreshAt = DateTime.now();

      completer.completeError(e, st);
      if (kDebugMode) {
        debugPrint('$_logPrefix silentRefreshIfNeeded done (error: $e)');
      }
    } finally {
      if (identical(_silentRefreshCompleter, completer)) {
        _silentRefreshCompleter = null;
      }
    }
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
    // ✅ unauthenticated 상태에서 restoreSession 호출 차단 (루프 방지)
    if (state.status == SessionStatus.unauthenticated) {
      if (kDebugMode) {
        debugPrint('$_logPrefix restoreSession 차단: 이미 unauthenticated 상태 (루프 방지)');
      }
      throw RestoreSessionFailedException();
    }

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

    // ✅ SSOT 검증: restore에서 사용 직전 토큰 형태 검증
    final accessJwt = tokens.accessToken.split('.').length == 3;
    final refreshJwt = tokens.refreshToken.split('.').length == 3;
    
    if (kDebugMode) {
      final accessLen = tokens.accessToken.length;
      final accessFp = _tokenFingerprint(tokens.accessToken);
      final refreshLen = tokens.refreshToken.length;
      final refreshFp = _tokenFingerprint(tokens.refreshToken);
      debugPrint(
        '$_logPrefix 토큰 로드 성공: '
        'accessLen=$accessLen, accessJwt=$accessJwt, accessFp=$accessFp, '
        'refreshLen=$refreshLen, refreshJwt=$refreshJwt, refreshFp=$refreshFp',
      );
      debugPrint('$_logPrefix 세션 검증 시작');
    }

    // ✅ 불변식 검사: access_token은 JWT여야 함
    if (!accessJwt) {
      final fingerprint = _tokenFingerprint(tokens.accessToken);
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix ⚠️ 치명적 토큰 매핑 오류: restoreSession에서 access_token이 JWT 형태가 아닙니다 '
          '(fp=$fingerprint, len=${tokens.accessToken.length})',
        );
      }
      // 토큰 clear는 wrapper에서 수행
      return const RestoreOutcome.authFailed();
    }

    // ✅ 불변식 검사: refresh_token은 JWT가 아니어야 함 (점 2개면 안 됨)
    if (refreshJwt) {
      final fingerprint = _tokenFingerprint(tokens.refreshToken);
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix ⚠️ 치명적 토큰 매핑 오류: restoreSession에서 refresh_token이 JWT 형태입니다 '
          '(fp=$fingerprint, len=${tokens.refreshToken.length}) - access_token을 잘못 매핑한 것',
        );
      }
      // 토큰 clear는 wrapper에서 수행
      return const RestoreOutcome.authFailed();
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
    
    // ✅ SSOT 검증: signInWithTokens에서 저장 직전 토큰 형태 검증 로그
    if (kDebugMode) {
      final accessLen = tokens.accessToken.length;
      final accessJwt = tokens.accessToken.split('.').length == 3;
      final accessFp = _tokenFingerprint(tokens.accessToken);
      final refreshLen = tokens.refreshToken.length;
      final refreshJwt = tokens.refreshToken.split('.').length == 3;
      final refreshFp = _tokenFingerprint(tokens.refreshToken);
      debugPrint(
        '$_logPrefix 로그인 토큰 저장 직전: '
        'accessLen=$accessLen, accessJwt=$accessJwt, accessFp=$accessFp, '
        'refreshLen=$refreshLen, refreshJwt=$refreshJwt, refreshFp=$refreshFp',
      );
    }
    
    await _tokenStore.save(tokens);
    if (kDebugMode) {
      debugPrint('$_logPrefix 로그인 성공: 토큰 저장 완료');
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
    // ✅ SSOT 검증: 소셜 로그인 직후 토큰 형태 검증 로그
    if (kDebugMode) {
      final accessLen = tokens.accessToken.length;
      final accessJwt = tokens.accessToken.split('.').length == 3;
      final accessFp = _tokenFingerprint(tokens.accessToken);
      final refreshLen = tokens.refreshToken.length;
      final refreshJwt = tokens.refreshToken.split('.').length == 3;
      final refreshFp = _tokenFingerprint(tokens.refreshToken);
      debugPrint(
        '$_logPrefix 소셜 로그인 토큰 수신: '
        'accessLen=$accessLen, accessJwt=$accessJwt, accessFp=$accessFp, '
        'refreshLen=$refreshLen, refreshJwt=$refreshJwt, refreshFp=$refreshFp',
      );
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
