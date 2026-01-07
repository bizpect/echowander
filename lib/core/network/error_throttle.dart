import 'package:flutter/foundation.dart';

/// 에러 메시지 중복 노출 방지 헬퍼 (쿨다운)
///
/// 동일 화면/동일 에러 타입으로 연속 실패 시
/// 스낵바/배너가 계속 뜨지 않게 쿨다운 적용
class ErrorThrottle {
  ErrorThrottle({
    this.cooldownDuration = const Duration(seconds: 5),
  });

  final Duration cooldownDuration;
  final Map<String, DateTime> _lastShownMap = {};

  /// 에러 메시지 표시 가능 여부 확인 및 기록
  ///
  /// [key]: 에러 식별 키 (예: "home_fetch_journeys_network")
  /// 반환값: true면 표시 가능, false면 쿨다운 중
  bool shouldShow(String key) {
    final now = DateTime.now();
    final lastShown = _lastShownMap[key];

    if (lastShown == null || now.difference(lastShown) >= cooldownDuration) {
      _lastShownMap[key] = now;
      if (kDebugMode) {
        debugPrint('[ErrorThrottle] 에러 표시 허용: $key');
      }
      return true;
    }

    if (kDebugMode) {
      final remaining = cooldownDuration - now.difference(lastShown);
      debugPrint('[ErrorThrottle] 쿨다운 중: $key (남은 시간: ${remaining.inSeconds}초)');
    }
    return false;
  }

  /// 쿨다운 초기화 (예: 화면 이탈 시)
  void reset([String? key]) {
    if (key != null) {
      _lastShownMap.remove(key);
      if (kDebugMode) {
        debugPrint('[ErrorThrottle] 초기화: $key');
      }
    } else {
      _lastShownMap.clear();
      if (kDebugMode) {
        debugPrint('[ErrorThrottle] 전체 초기화');
      }
    }
  }
}
