import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

const _logPrefix = '[DateFormatter]';

/// 공지/업데이트 날짜 포맷터 (UTC/KST 변환 중앙화, 재발 방지 강화)
class AnnouncementDateFormatter {
  /// 서버에서 받은 UTC ISO-8601 문자열을 파싱하고 로컬 시간으로 변환하여 포맷팅
  ///
  /// [rawUtcIso] 서버에서 내려오는 ...Z 포함 ISO-8601 문자열 전용
  /// [locale] 로케일 문자열 (예: 'ko', 'en', 'ja')
  /// [pattern] DateFormat 패턴 (기본값: MMMd + Hm)
  ///
  /// 반환: 포맷된 날짜 문자열 (예: "1월 15일 14:30")
  ///
  /// 변환 규칙:
  /// - raw에 'T'가 없으면(date-only, 예: '2026-01-10') → 날짜 문자열로만 표시 (시간/UTC 변환 금지)
  /// - raw에 'Z' 또는 offset이 있으면 정상 UTC 파싱 후 local 변환 (표시 직전 1회만)
  /// - 어떤 경우든 "9시간 차이"가 생기는 경로를 차단
  static String formatUtcIsoString(
    String rawUtcIso,
    String locale, {
    DateFormat? pattern,
  }) {
    try {
      // date-only 방어: 'T'가 없으면 날짜만 표시 (타임존/시간 개념 완전 차단)
      if (!rawUtcIso.contains('T')) {
        // YYYY-MM-DD 형식인 경우 날짜 문자열을 직접 파싱 (DateTime.parse 사용 금지)
        // 타임존/시간 개념을 완전히 차단하여 어떤 기기/타임존에서도 동일한 날짜 문자열로 표시
        final parts = rawUtcIso.split('-');
        if (parts.length != 3) {
          throw FormatException('Invalid date-only format: $rawUtcIso');
        }
        
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        
        // 날짜만으로 DateTime 객체 생성 (로컬 시간으로 간주, 타임존 변환 없음)
        final dateOnly = DateTime(year, month, day);
        final dateFormat = pattern ?? DateFormat.MMMd(locale);
        
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix formatUtcIsoString (date-only) - raw: $rawUtcIso, '
            'parsed: $year-$month-$day (no timezone conversion)',
          );
        }
        
        // date-only는 시간 없이 날짜만 표시
        return dateFormat.format(dateOnly);
      }

      // timezone 정보 확인 (Z 또는 offset 포함 여부)
      // ISO 8601 형식: YYYY-MM-DDTHH:MM:SS[Z|±HH:MM]
      // T 이후 부분을 확인하여 timezone 정보가 있는지 판단
      final tIndex = rawUtcIso.indexOf('T');
      if (tIndex >= 0) {
        final afterT = rawUtcIso.substring(tIndex + 1);
        // Z로 끝나거나, + 또는 -offset이 있는지 확인
        // (시간 부분은 HH:MM:SS 형식이므로 -가 없음, -는 offset에만 사용)
        final hasTimezone = rawUtcIso.endsWith('Z') ||
            afterT.contains('+') ||
            (afterT.contains('-') && afterT.length > 8); // 시간 부분(최소 8자) 초과 시 offset으로 간주

        // T는 있는데 timezone 정보가 없으면 WARNING 로그 출력
        if (!hasTimezone && kDebugMode) {
          debugPrint(
            '$_logPrefix WARNING: formatUtcIsoString received timezone-less ISO string: $rawUtcIso. '
            'This may cause inconsistent date display across devices/timezones. '
            'Server should provide timezone information (Z or offset).',
          );
        }
      }

      // UTC ISO 문자열 파싱 (Z 또는 offset 포함)
      final parsed = DateTime.parse(rawUtcIso);
      
      // 표시 직전에만 toLocal() 1회 적용 (중복 변환 방지)
      final localTime = parsed.toLocal();

      if (kDebugMode) {
        final now = DateTime.now();
        final offset = now.timeZoneOffset;
        debugPrint(
          '$_logPrefix formatUtcIsoString - raw: $rawUtcIso, parsed: $parsed, '
          'local: $localTime, now: $now, offset: $offset',
        );
      }

      final dateFormat = pattern ?? DateFormat.MMMd(locale).add_Hm();
      return dateFormat.format(localTime);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix UTC ISO 문자열 파싱 실패: $e, rawUtcIso: $rawUtcIso');
      }
      // 파싱 실패 시 원본 반환
      return rawUtcIso;
    }
  }

  /// DateTime 객체를 로컬 시간으로 변환하여 포맷팅
  ///
  /// [dateTime] DateTime 객체 (UTC 또는 로컬)
  /// [locale] 로케일 문자열
  /// [pattern] DateFormat 패턴 (기본값: MMMd + Hm)
  ///
  /// 반환: 포맷된 날짜 문자열
  ///
  /// 변환 규칙:
  /// - 입력 DateTime이 UTC인지 아닌지에 관계없이 "표시용 local"로 통일
  /// - dateTime.isUtc ? dateTime.toLocal() : dateTime
  /// - 표시 직전에만 toLocal()을 1회 적용 (중복 변환 방지)
  static String formatLocalDateTime(
    DateTime dateTime,
    String locale, {
    DateFormat? pattern,
  }) {
    try {
      // UTC인 경우에만 toLocal() 적용, 이미 로컬이면 그대로 사용
      // 표시 직전에만 toLocal() 1회 적용 (중복 변환 방지)
      final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;

      if (kDebugMode) {
        final now = DateTime.now();
        final offset = now.timeZoneOffset;
        debugPrint(
          '$_logPrefix formatLocalDateTime - input: $dateTime (isUtc: ${dateTime.isUtc}), '
          'local: $localTime, now: $now, offset: $offset',
        );
      }

      final dateFormat = pattern ?? DateFormat.MMMd(locale).add_Hm();
      return dateFormat.format(localTime);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 날짜 포맷팅 실패: $e, dateTime: $dateTime');
      }
      return dateTime.toString();
    }
  }
}
