import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_error.dart';
import 'session_manager.dart';
import 'session_state.dart';

const _logPrefix = '[AuthExecutor]';

/// JWT 만료 여부 확인 유틸
class JwtUtils {
  /// JWT 만료까지 남은 초 반환 (음수: 이미 만료됨, null: 파싱 실패)
  static int? getSecondsUntilExpiry(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = (map['exp'] as num?)?.toInt();

      if (exp == null) return null;

      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      return exp - nowSec;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix JWT 파싱 실패: $e');
      }
      return null;
    }
  }

  /// JWT가 만료되었는지 확인 (skew: 만료 N초 전부터 만료로 간주)
  static bool isExpired(String jwt, {int skewSeconds = 30}) {
    final secondsLeft = getSecondsUntilExpiry(jwt);
    if (secondsLeft == null) return true; // 파싱 실패 시 만료로 간주

    final isExpired = secondsLeft <= skewSeconds;

    if (kDebugMode && isExpired) {
      debugPrint(
        '$_logPrefix JWT 만료 감지: $secondsLeft초 남음 (skew=$skewSeconds초)',
      );
    }

    return isExpired;
  }

  /// JWT가 만료 임박인지 확인 (threshold초 이내면 true)
  /// 선제적 refresh를 위한 체크
  static bool isExpiringSoon(String jwt, {int thresholdSeconds = 60}) {
    final secondsLeft = getSecondsUntilExpiry(jwt);
    if (secondsLeft == null) return true; // 파싱 실패 시 갱신 필요로 간주

    final isExpiringSoon = secondsLeft <= thresholdSeconds;

    if (kDebugMode && isExpiringSoon) {
      debugPrint(
        '$_logPrefix JWT 만료 임박: $secondsLeft초 남음 (threshold=$thresholdSeconds초)',
      );
    }

    return isExpiringSoon;
  }
}

/// 401(Unauthorized) 발생 시 세션 갱신 후 1회 재시도하는 공통 유틸
///
/// 동작:
/// 1. accessToken 없으면 즉시 [AuthExecutorResult.noSession] 반환
/// 2. operation 실행
/// 3. Unauthorized 예외 발생 시:
///    - SessionManager.restoreSession() 호출 (single-flight로 중복 방지됨)
///    - 새 accessToken 확인 후 딱 1회만 재시도
/// 4. 그래도 실패하면 [AuthExecutorResult.unauthorized] 반환
///
/// 주의:
/// - 무한 루프/무한 재시도 절대 금지
/// - 재시도는 정확히 1회만 수행
/// - 네트워크 오류(network/timeout)는 재시도하지 않음 (그대로 throw)
class AuthExecutor {
  AuthExecutor(this._ref);

  final Ref _ref;

  /// 401 발생 시 세션 갱신 후 1회 재시도
  ///
  /// [operation]: accessToken을 받아 실행할 비동기 작업
  /// [isUnauthorized]: 발생한 예외가 401인지 판단하는 함수
  ///
  /// 반환:
  /// - [AuthExecutorResult.success]: 성공 (data 포함)
  /// - [AuthExecutorResult.noSession]: accessToken 없음
  /// - [AuthExecutorResult.unauthorized]: 재시도 후에도 401
  /// - 기타 예외: 그대로 throw (네트워크 오류 등)
  Future<AuthExecutorResult<T>> execute<T>({
    required Future<T> Function(String accessToken) operation,
    required bool Function(Object error) isUnauthorized,
  }) async {
    final sessionManager = _ref.read(sessionManagerProvider.notifier);
    final sessionState = _ref.read(sessionManagerProvider);

    // ✅ unauthenticated 상태에서는 즉시 noSession 반환 (루프 방지)
    if (sessionState.status == SessionStatus.unauthenticated) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 세션 상태 가드: unauthenticated → noSession (루프 방지)');
      }
      return const AuthExecutorResult.noSession();
    }

    // ✅ SSOT: restoreInFlight가 있으면 재호출 금지, 그 Future만 await
    final restoreFuture = sessionManager.restoreInFlight;
    if (restoreFuture != null) {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix restoreInFlight exists → await '
          '(status=${sessionState.status})',
        );
      }
      try {
        // ✅ SSOT: restoreInFlight가 있으면 그것만 await
        await restoreFuture;
        final newSessionState = _ref.read(sessionManagerProvider);
        // ✅ unauthenticated로 전환되었으면 noSession 반환
        if (newSessionState.status == SessionStatus.unauthenticated) {
          if (kDebugMode) {
            debugPrint('$_logPrefix restoreInFlight 완료 후 unauthenticated → noSession');
          }
          return const AuthExecutorResult.noSession();
        }
        final newAccessToken = newSessionState.accessToken;
        if (newAccessToken == null || newAccessToken.isEmpty) {
          return const AuthExecutorResult.noSession();
        }
        // refresh 완료 후 Query 실행
      } on RestoreSessionTransientException {
        return const AuthExecutorResult.transientError();
      } on RestoreSessionFailedException {
        return const AuthExecutorResult.unauthorized();
      } catch (error) {
        if (kDebugMode) {
          debugPrint('$_logPrefix restoreInFlight await 중 예외: $error → transientError');
        }
        return const AuthExecutorResult.transientError();
      }
    }

    // 1) accessToken 확인
    var accessToken = sessionState.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix accessToken 없음 → noSession');
      }
      return const AuthExecutorResult.noSession();
    }

    // 2) JWT 만료 임박/만료 사전 점검 (silent refresh로 401 방지)
    // silent refresh는 single-flight + cooldown으로 연타/무한 반복 방지
    if (JwtUtils.isExpiringSoon(accessToken, thresholdSeconds: 60)) {
      if (kDebugMode) {
        debugPrint('$_logPrefix JWT 만료 임박/만료 → silentRefreshIfNeeded 시도');
      }

      try {
        // ✅ silent refresh (사용자 모르게 처리, UI 영향 없음)
        final silentRefreshFuture = sessionManager.silentRefreshInFlight;
        if (silentRefreshFuture != null) {
          if (kDebugMode) {
            debugPrint('$_logPrefix silentRefresh inFlight exists → await');
          }
          await silentRefreshFuture;
        } else {
          // silentRefreshIfNeeded는 쿨다운/상태 체크를 내부에서 수행
          await sessionManager.silentRefreshIfNeeded(reason: 'proactive');
        }
        // refresh 완료 후 accessToken 재확인
        final newSessionState = _ref.read(sessionManagerProvider);
        if (newSessionState.status == SessionStatus.unauthenticated) {
          if (kDebugMode) {
            debugPrint('$_logPrefix silentRefresh 완료 후 unauthenticated → noSession');
          }
          return const AuthExecutorResult.noSession();
        }
        accessToken = newSessionState.accessToken;
        if (accessToken == null || accessToken.isEmpty) {
          return const AuthExecutorResult.noSession();
        }
      } catch (error) {
        // silent refresh 실패는 일시 장애로 처리 (로그아웃 아님)
        if (kDebugMode) {
          debugPrint('$_logPrefix silentRefresh 기타 오류: $error → transientError');
        }
        return const AuthExecutorResult.transientError();
      }
    }

    // 3) 첫 번째 시도
    try {
      final result = await operation(accessToken);
      return AuthExecutorResult.success(result);
    } catch (error) {
      // ✅ forbidden(403, 42501)은 refresh로 해결 불가 → 즉시 반환
      if (error is NetworkRequestException && error.type == NetworkErrorType.forbidden) {
        if (kDebugMode) {
          debugPrint('$_logPrefix forbidden(403) 발생 → refresh 불가, 즉시 반환');
        }
        rethrow; // forbidden은 그대로 throw (재시도/refresh 금지)
      }

      if (!isUnauthorized(error)) {
        // 401이 아니면 그대로 throw (네트워크 오류 등)
        rethrow;
      }

      if (kDebugMode) {
        debugPrint('$_logPrefix 401 발생 → handleUnauthorized 호출');
      }
    }

    // 4) 401 처리: SessionManager의 단일 진입점으로 위임
    // handleUnauthorized는 in-flight/cooldown을 존중하면서 refresh 또는 만료 확정을 처리
    await sessionManager.handleUnauthorized(
      reason: 'unauthorized',
      source: 'AuthExecutor',
    );

    // 5) 새 accessToken 확인
    final newAccessToken = _ref.read(sessionManagerProvider).accessToken;
    final sessionStatus = _ref.read(sessionManagerProvider).status;

    if (newAccessToken == null ||
        newAccessToken.isEmpty ||
        sessionStatus != SessionStatus.authenticated) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 세션 갱신 후에도 토큰 없음 → unauthorized');
      }
      return const AuthExecutorResult.unauthorized();
    }

    // 6) 딱 1회만 재시도
    if (kDebugMode) {
      debugPrint('$_logPrefix 새 토큰으로 1회 재시도');
    }

    try {
      final result = await operation(newAccessToken);
      if (kDebugMode) {
        debugPrint('$_logPrefix 재시도 성공');
      }
      return AuthExecutorResult.success(result);
    } catch (error) {
      // ✅ forbidden(403, 42501)은 refresh로 해결 불가 → 즉시 반환
      if (error is NetworkRequestException && error.type == NetworkErrorType.forbidden) {
        if (kDebugMode) {
          debugPrint('$_logPrefix 재시도 후에도 forbidden(403) → 즉시 반환');
        }
        rethrow; // forbidden은 그대로 throw (재시도/refresh 금지)
      }

      if (isUnauthorized(error)) {
        if (kDebugMode) {
          debugPrint('$_logPrefix 재시도 후에도 401 → unauthorized');
        }
        return const AuthExecutorResult.unauthorized();
      }
      // 401이 아닌 다른 에러면 그대로 throw
      rethrow;
    }
  }
}

/// AuthExecutor 실행 결과
sealed class AuthExecutorResult<T> {
  const AuthExecutorResult();

  const factory AuthExecutorResult.success(T data) = AuthExecutorSuccess<T>;
  const factory AuthExecutorResult.noSession() = AuthExecutorNoSession<T>;
  const factory AuthExecutorResult.unauthorized() = AuthExecutorUnauthorized<T>;

  /// 일시 장애 (네트워크/서버 문제, 로그아웃 아님)
  const factory AuthExecutorResult.transientError() =
      AuthExecutorTransientError<T>;
}

/// 성공 결과
class AuthExecutorSuccess<T> extends AuthExecutorResult<T> {
  const AuthExecutorSuccess(this.data);
  final T data;
}

/// accessToken 없음 (로그인 필요)
class AuthExecutorNoSession<T> extends AuthExecutorResult<T> {
  const AuthExecutorNoSession();
}

/// 재시도 후에도 401 (세션 만료 확정)
class AuthExecutorUnauthorized<T> extends AuthExecutorResult<T> {
  const AuthExecutorUnauthorized();
}

/// 일시 장애 (네트워크/서버 문제, 로그아웃 아님)
class AuthExecutorTransientError<T> extends AuthExecutorResult<T> {
  const AuthExecutorTransientError();
}
