import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_manager.dart';
import '../data/supabase_profile_repository.dart';

const _logPrefix = '[AvatarSignedUrl]';

/// signed URL 캐시 데이터
class SignedUrlCache {
  const SignedUrlCache({
    required this.url,
    required this.expiresAt,
  });

  final String url;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExpiringSoon {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.inSeconds < 300; // 5분 이내면 만료 임박
  }
}

/// 아바타 signed URL Provider
/// 
/// objectPath가 있으면 signed URL을 발급하고 캐싱합니다.
/// 만료되면 자동으로 재발급합니다.
final avatarSignedUrlProvider = FutureProvider.autoDispose
    .family<String?, String?>((ref, objectPath) async {
  if (objectPath == null || objectPath.isEmpty) {
    return null;
  }

  final sessionState = ref.watch(sessionManagerProvider);
  final accessToken = sessionState.accessToken;
  if (accessToken == null || accessToken.isEmpty) {
    if (kDebugMode) {
      debugPrint('$_logPrefix accessToken 없음');
    }
    return null;
  }

  final repository = ref.read(profileRepositoryProvider);
  
  try {
    final signedUrl = await repository.getAvatarSignedUrl(
      objectPath: objectPath,
      accessToken: accessToken,
      expiresInSeconds: 3600, // 1시간
    );

    if (kDebugMode) {
      if (signedUrl != null) {
        final hasStorageV1 = signedUrl.contains('/storage/v1/');
        debugPrint(
          '$_logPrefix signed URL 발급 완료: '
          'path=$objectPath '
          'hasStorageV1=$hasStorageV1 '
          'url=$signedUrl',
        );
      } else {
        debugPrint('$_logPrefix signed URL 발급 실패: path=$objectPath (null 반환)');
      }
    }

    return signedUrl;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('$_logPrefix signed URL 발급 예외: path=$objectPath error=$e');
    }
    return null;
  }
});
