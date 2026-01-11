import 'package:flutter_riverpod/misc.dart';

import '../../features/journey/application/journey_compose_controller.dart';
import '../../features/journey/application/journey_inbox_controller.dart';
import '../../features/journey/application/journey_list_controller.dart';
import '../../features/notifications/application/notification_inbox_controller.dart';
import '../../features/notifications/application/unread_notification_count_provider.dart';
import '../../features/block/application/block_list_controller.dart';
import '../../features/settings/application/settings_controller.dart';

/// 세션 변경(accessToken 변경) 시 invalidate해야 하는 Provider 목록
///
/// 계정 전환/로그아웃/로그인 시 이전 사용자의 데이터가 캐시에 남아있을 수 있으므로,
/// 이 목록의 모든 Provider를 invalidate하여 데이터 잔상을 방지합니다.
///
/// 포함 기준:
/// - 사용자별 데이터를 캐시하는 Controller
/// - accessToken을 사용하여 API 호출하는 Controller
///
/// 제외 기준:
/// - 사용자와 무관한 앱 설정 (locale, theme 등)
/// - 온보딩 상태 (디바이스 단위)
final List<ProviderOrFamily> sessionInvalidationTargets = [
  // 작성 중인 여정 초안 - 이전 사용자의 작성 내용 제거
  journeyComposeControllerProvider,

  // 받은 여정 목록 - 이전 사용자의 inbox 캐시 제거
  journeyInboxControllerProvider,

  // 보낸 여정 목록 - 이전 사용자의 여정 캐시 제거
  journeyListControllerProvider,

  // 알림 목록 - 이전 사용자의 알림 캐시 제거
  notificationInboxControllerProvider,
  unreadNotificationCountProvider,

  // 차단 목록 - 이전 사용자의 차단 목록 캐시 제거
  blockListControllerProvider,

  // 설정 상태 - 이전 사용자의 알림 설정 캐시 제거
  settingsControllerProvider,
];
