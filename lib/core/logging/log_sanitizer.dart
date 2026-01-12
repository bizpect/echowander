import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

const _logPrefix = '[LogSanitizer]';

/// 로그용 URL/민감정보 마스킹 유틸
class LogSanitizer {
  /// signedUrl을 안전하게 로깅용으로 변환
  ///
  /// 반환: scheme://host/path (쿼리 제거) + hash(전체 URL의 앞 8자)
  static String sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // scheme://host/path만 반환 (쿼리 제거)
      return '${uri.scheme}://${uri.host}${uri.path}';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix URL 파싱 실패: $url, error=$e');
      }
      // 파싱 실패 시 전체 URL의 앞 50자만 반환
      return url.length > 50 ? '${url.substring(0, 50)}...' : url;
    }
  }

  /// URL 전체를 해시하여 앞 8자만 반환 (민감정보 보호)
  static String hashUrl(String url) {
    try {
      final bytes = utf8.encode(url);
      final digest = sha256.convert(bytes);
      return digest.toString().substring(0, 8);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix URL 해시 실패: error=$e');
      }
      return 'hash-fail';
    }
  }

  /// signedUrl을 로깅용 문자열로 변환
  ///
  /// 반환: "scheme://host/path [hash:xxxx]"
  static String sanitizeUrlForLog(String url) {
    final sanitized = sanitizeUrl(url);
    final hash = hashUrl(url);
    return '$sanitized [hash:$hash]';
  }

  /// objectPath 정규화 (앞의 / 제거, 중복 prefix 제거)
  static String normalizePath(String path) {
    var normalized = path.trim();
    // 앞의 / 제거
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    // 중복 prefix 제거 (예: journeys/journeys/... → journeys/...)
    final parts = normalized.split('/');
    final cleaned = <String>[];
    for (var i = 0; i < parts.length; i++) {
      if (i == 0 || parts[i] != parts[i - 1]) {
        cleaned.add(parts[i]);
      }
    }
    return cleaned.join('/');
  }

  /// 경로 미리보기 (너무 길면 끝부분만 남기기)
  ///
  /// [path] 경로 문자열
  /// [maxLength] 최대 길이 (기본 40)
  /// 반환: 길면 "...{끝부분}", 짧으면 원본
  static String previewPath(String path, {int maxLength = 40}) {
    if (path.length <= maxLength) {
      return path;
    }
    return '...${path.substring(path.length - maxLength)}';
  }
}
