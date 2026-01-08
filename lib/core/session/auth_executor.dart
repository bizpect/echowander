import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // 1) accessToken 확인
    var accessToken = _ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix accessToken 없음 → noSession');
      }
      return const AuthExecutorResult.noSession();
    }

    // 2) JWT 만료 임박/만료 사전 점검 (선제적 refresh로 401 방지)
    // verify_jwt=true 환경에서는 만료된 토큰으로 refresh_session 호출 불가
    // 따라서 만료 "전"에 선제적으로 refresh 수행
    if (JwtUtils.isExpiringSoon(accessToken, thresholdSeconds: 60)) {
      if (kDebugMode) {
        debugPrint('$_logPrefix JWT 만료 임박/만료 → 선제적 restoreSession 시도');
      }

      // 쿨다운 중이면 즉시 transientError 반환 (일시 장애, 로그아웃 아님)
      if (sessionManager.isRestoreBlocked) {
        if (kDebugMode) {
          debugPrint('$_logPrefix restoreSession 쿨다운 중 → transientError');
        }
        return const AuthExecutorResult.transientError();
      }

      try {
        await sessionManager.restoreSession();
        accessToken = _ref.read(sessionManagerProvider).accessToken;
        if (accessToken == null || accessToken.isEmpty) {
          return const AuthExecutorResult.noSession();
        }
      } on RestoreSessionTransientException {
        // 일시 장애: 토큰은 유지됨, 로그아웃 아님
        if (kDebugMode) {
          debugPrint('$_logPrefix 선제 restoreSession 일시 장애 → transientError');
        }
        return const AuthExecutorResult.transientError();
      } on RestoreSessionFailedException {
        // 인증 실패 확정: 토큰 만료
        if (kDebugMode) {
          debugPrint('$_logPrefix 선제 restoreSession 인증 실패 → unauthorized');
        }
        return const AuthExecutorResult.unauthorized();
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix 선제 restoreSession 기타 오류: $error → transientError',
          );
        }
        return const AuthExecutorResult.transientError();
      }
    }

    // 3) 첫 번째 시도
    try {
      final result = await operation(accessToken);
      return AuthExecutorResult.success(result);
    } catch (error) {
      if (!isUnauthorized(error)) {
        // 401이 아니면 그대로 throw (네트워크 오류 등)
        rethrow;
      }

      if (kDebugMode) {
        debugPrint('$_logPrefix 401 발생 → restoreSession 시도');
      }
    }

    // 4) restoreSession (single-flight + cooldown)
    // 쿨다운 중이면 즉시 transientError 반환 (일시 장애, 로그아웃 아님)
    if (sessionManager.isRestoreBlocked) {
      if (kDebugMode) {
        debugPrint('$_logPrefix restoreSession 쿨다운 중 → transientError');
      }
      return const AuthExecutorResult.transientError();
    }

    try {
      await sessionManager.restoreSession();
    } on RestoreSessionTransientException {
      // 일시 장애: 토큰은 유지됨, 로그아웃 아님
      if (kDebugMode) {
        debugPrint('$_logPrefix restoreSession 일시 장애 → transientError');
      }
      return const AuthExecutorResult.transientError();
    } on RestoreSessionFailedException {
      // 인증 실패 확정: 토큰 만료
      if (kDebugMode) {
        debugPrint('$_logPrefix restoreSession 인증 실패 → unauthorized');
      }
      return const AuthExecutorResult.unauthorized();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix restoreSession 기타 오류: $error → transientError');
      }
      return const AuthExecutorResult.transientError();
    }

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
