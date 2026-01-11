import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_manager.dart';
import '../data/supabase_notification_repository.dart';

const _logPrefix = '[UnreadNotificationCount]';

final unreadNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final sessionState = ref.watch(sessionManagerProvider);
  final accessToken = sessionState.accessToken;
  if (accessToken == null || accessToken.isEmpty) {
    return 0;
  }

  final repository = ref.read(notificationRepositoryProvider);
  try {
    return await repository.fetchUnreadCount(accessToken: accessToken);
  } catch (error) {
    if (kDebugMode) {
      debugPrint('$_logPrefix fetch 실패: $error');
    }
    return 0;
  }
});
