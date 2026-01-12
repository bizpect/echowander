import 'package:flutter/foundation.dart';

const _logPrefix = '[StorageUrlNormalizer]';

/// Supabase Storage signed URL 정규화 유틸
///
/// Supabase Storage API가 반환하는 signedURL은 다음 형태일 수 있음:
/// - 상대경로: `/object/sign/<bucket>/<path>?token=...`
/// - 절대경로: `https://.../storage/v1/object/sign/...`
///
/// 상대경로인 경우 `/storage/v1`을 포함한 절대 URL로 정규화
class StorageUrlNormalizer {
  /// signed URL을 정규화하여 항상 `/storage/v1`을 포함한 절대 URL로 반환
  ///
  /// [supabaseUrl] Supabase 프로젝트 URL (예: `https://xxx.supabase.co`)
  /// [signedUrlOrPath] Supabase가 반환한 signedURL (상대경로 또는 절대경로)
  ///
  /// 반환: 정규화된 절대 URL (항상 `/storage/v1` 포함)
  static String normalizeSignedUrl({
    required String supabaseUrl,
    required String signedUrlOrPath,
  }) {
    // base URL 정규화 (trailing slash 제거)
    final base = supabaseUrl.endsWith('/')
        ? supabaseUrl.substring(0, supabaseUrl.length - 1)
        : supabaseUrl;

    // 이미 절대 URL인 경우 그대로 반환
    if (signedUrlOrPath.startsWith('http://') ||
        signedUrlOrPath.startsWith('https://')) {
      // 이미 절대 URL이지만 `/storage/v1`이 없는 경우 체크
      if (signedUrlOrPath.contains('/object/sign/') &&
          !signedUrlOrPath.contains('/storage/v1/')) {
        // `/object/sign/`를 `/storage/v1/object/sign/`로 교체
        final normalized = signedUrlOrPath.replaceFirst(
          '/object/sign/',
          '/storage/v1/object/sign/',
        );
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix 정규화: 절대 URL이지만 /storage/v1 누락 → 교체: $normalized',
          );
        }
        return normalized;
      }
      return signedUrlOrPath;
    }

    // 상대경로 처리
    String normalizedPath;
    if (signedUrlOrPath.startsWith('/storage/v1/')) {
      // 이미 `/storage/v1/` 포함
      normalizedPath = signedUrlOrPath;
    } else if (signedUrlOrPath.startsWith('/object/sign/')) {
      // `/object/sign/...` → `/storage/v1/object/sign/...`
      normalizedPath = '/storage/v1$signedUrlOrPath';
    } else {
      // 기타 경우: 안전하게 `/storage/v1/` prefix 추가 (중복 슬래시 제거)
      final cleanPath = signedUrlOrPath.startsWith('/')
          ? signedUrlOrPath.substring(1)
          : signedUrlOrPath;
      normalizedPath = '/storage/v1/$cleanPath';
    }

    final normalizedUrl = '$base$normalizedPath';

    if (kDebugMode) {
      debugPrint(
        '$_logPrefix 정규화: raw=$signedUrlOrPath → normalized=$normalizedUrl',
      );
    }

    return normalizedUrl;
  }
}
