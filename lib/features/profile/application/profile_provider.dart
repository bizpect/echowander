import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_manager.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/profile_repository.dart';

const _logPrefix = '[ProfileProvider]';

/// 프로필 단일 소스 Provider
final profileProvider = FutureProvider<ProfileData?>((ref) async {
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
    return await repository.getMyProfile(accessToken: accessToken);
  } catch (error) {
    if (kDebugMode) {
      debugPrint('$_logPrefix 프로필 로드 실패: $error');
    }
    return null;
  }
});
