import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

const _logPrefix = '[AppDateFormatter]';

/// 카드/리스트 보조 정보용 날짜 포맷터 (A안 규칙)
///
/// 포맷 규칙:
/// - 오늘: HH:mm
/// - 올해(오늘 아님): ko는 M월 d일 HH:mm, 그 외는 M/d HH:mm
/// - 올해 아님: ko는 yyyy.MM.dd HH:mm, 그 외는 yyyy-MM-dd HH:mm
class AppDateFormatter {
  /// 카드/리스트용 간단 날짜 포맷 (A안)
  ///
  /// [dateTime] DateTime 객체 (UTC 또는 로컬)
  /// [locale] 로케일 문자열 (예: 'ko', 'en', 'ja')
  /// [now] 현재 시각 (테스트/예측 가능성을 위해 optional, 기본값: DateTime.now())
  ///
  /// 반환: 포맷된 날짜 문자열
  ///
  /// 변환 규칙:
  /// - 입력 DateTime이 UTC인 경우 로컬로 변환
  /// - 오늘/올해 판정은 locale이 아니라 DateTime 비교로 처리
  static String formatCardTimestamp(
    DateTime dateTime,
    String locale, {
    DateTime? now,
  }) {
    try {
      // UTC인 경우에만 toLocal() 적용, 이미 로컬이면 그대로 사용
      final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
      final nowTime = now ?? DateTime.now();

      // 오늘인지 판정 (날짜만 비교, 자정 경계 주의)
      final today = DateTime(nowTime.year, nowTime.month, nowTime.day);
      final targetDate = DateTime(localTime.year, localTime.month, localTime.day);
      final isToday = targetDate == today;

      // 올해인지 판정
      final isThisYear = localTime.year == nowTime.year;

      if (kDebugMode) {
        debugPrint(
          '$_logPrefix formatCardTimestamp - input: $dateTime (isUtc: ${dateTime.isUtc}), '
          'local: $localTime, now: $nowTime, isToday: $isToday, isThisYear: $isThisYear',
        );
      }

      // 오늘: HH:mm
      if (isToday) {
        final timeFormat = DateFormat.Hm(locale);
        return timeFormat.format(localTime);
      }

      // 올해이지만 오늘 아님
      if (isThisYear) {
        if (locale == 'ko') {
          // ko: M월 d일 HH:mm
          final format = DateFormat('M월 d일 HH:mm', locale);
          return format.format(localTime);
        } else {
          // 그 외: M/d HH:mm
          final format = DateFormat('M/d HH:mm', locale);
          return format.format(localTime);
        }
      }

      // 올해가 아님
      if (locale == 'ko') {
        // ko: yyyy.MM.dd HH:mm
        final format = DateFormat('yyyy.MM.dd HH:mm', locale);
        return format.format(localTime);
      } else {
        // 그 외: yyyy-MM-dd HH:mm
        final format = DateFormat('yyyy-MM-dd HH:mm', locale);
        return format.format(localTime);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 날짜 포맷팅 실패: $e, dateTime: $dateTime');
      }
      return dateTime.toString();
    }
  }

  /// 상세 화면용 날짜 포맷 (YYYY년 MM월 DD일 HH:MM)
  ///
  /// [dateTime] DateTime 객체 (UTC 또는 로컬)
  /// [locale] 로케일 문자열 (예: 'ko', 'en', 'ja')
  ///
  /// 반환: 포맷된 날짜 문자열
  /// - ko: yyyy년 MM월 dd일 HH:mm
  /// - 그 외: yyyy-MM-dd HH:mm
  ///
  /// 변환 규칙:
  /// - 입력 DateTime이 UTC인 경우 로컬로 변환
  static String formatDetailTimestamp(
    DateTime dateTime,
    String locale,
  ) {
    try {
      // UTC인 경우에만 toLocal() 적용, 이미 로컬이면 그대로 사용
      final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;

      if (locale == 'ko') {
        // ko: yyyy년 MM월 dd일 HH:mm
        final format = DateFormat('yyyy년 MM월 dd일 HH:mm', locale);
        return format.format(localTime);
      } else {
        // 그 외: yyyy-MM-dd HH:mm
        final format = DateFormat('yyyy-MM-dd HH:mm', locale);
        return format.format(localTime);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 날짜 포맷팅 실패: $e, dateTime: $dateTime');
      }
      return dateTime.toString();
    }
  }

  /// 채팅 날짜 구분선용 날짜 포맷 (날짜만, 시간 제외)
  ///
  /// [dateTime] DateTime 객체 (UTC 또는 로컬)
  /// [locale] 로케일 문자열 (예: 'ko', 'en', 'ja')
  ///
  /// 반환: 포맷된 날짜 문자열 (시간 제외)
  /// - ko: yyyy년 MM월 dd일
  /// - 그 외: yMMMd (예: Jan 15, 2026)
  ///
  /// 변환 규칙:
  /// - 입력 DateTime이 UTC인 경우 로컬로 변환
  static String formatChatDateDivider(
    DateTime dateTime,
    String locale,
  ) {
    try {
      // UTC인 경우에만 toLocal() 적용, 이미 로컬이면 그대로 사용
      final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;

      if (locale == 'ko') {
        // ko: yyyy년 MM월 dd일
        final format = DateFormat('yyyy년 MM월 dd일', locale);
        return format.format(localTime);
      } else {
        // 그 외: yMMMd (예: Jan 15, 2026)
        final format = DateFormat.yMMMd(locale);
        return format.format(localTime);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 날짜 포맷팅 실패: $e, dateTime: $dateTime');
      }
      return dateTime.toString();
    }
  }
}
