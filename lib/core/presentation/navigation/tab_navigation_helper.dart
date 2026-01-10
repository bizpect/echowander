import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../features/journey/application/journey_inbox_controller.dart';
import '../../../features/journey/application/journey_list_controller.dart';
import '../scaffolds/main_tab_controller.dart';

/// 탭 루트로 복귀하는 네비게이션 helper
///
/// 상세 화면에서 뒤로가기 시 각 탭의 루트 화면(리스트)으로 정확히 복귀하도록 보장합니다.
/// 딥링크로 상세만 열린 경우에도 탭 루트를 구성하고 해당 탭을 활성화합니다.
class TabNavigationHelper {
  /// 홈 탭으로 복귀
  ///
  /// - 홈 탭 활성화
  /// - /home으로 이동하여 탭 쉘 유지
  static void goToHomeTab(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final tabController = ref.read(mainTabControllerProvider.notifier);

    tabController.switchToHomeTab();
    router.go(AppRoutes.home);
  }

  /// 받은 메시지 탭 루트로 복귀
  ///
  /// - 상세 화면이 스택에 있으면 pop
  /// - 탭 루트로 이동하고 받은 메시지 탭 활성화
  /// - limit: 20으로 명시적으로 로드하여 홈 화면의 limit:3 로드가 덮어쓰지 않도록 보장
  static void goToInboxRoot(BuildContext context, WidgetRef ref) {
    // router와 controller를 사전에 캡처하여 context 안전성 보장
    final router = GoRouter.of(context);
    final tabController = ref.read(mainTabControllerProvider.notifier);
    final inboxController = ref.read(journeyInboxControllerProvider.notifier);

    // 받은 메시지 탭 활성화 (먼저 탭 전환)
    tabController.switchToInboxTab();

    // limit: 20으로 명시적으로 로드하여 홈 화면의 limit:3 로드가 덮어쓰지 않도록 보장
    inboxController.load(limit: 20);

    // /home으로 이동하여 탭 쉘 내부의 받은 메시지 리스트로 복귀
    router.go(AppRoutes.home);
  }

  /// 보낸 메시지 탭 루트로 복귀
  ///
  /// - 상세 화면이 스택에 있으면 pop
  /// - 탭 루트로 이동하고 보낸 메시지 탭 활성화
  /// - limit: 20으로 명시적으로 로드하여 홈 화면의 limit:3 로드가 덮어쓰지 않도록 보장
  static void goToSentRoot(BuildContext context, WidgetRef ref) {
    // router와 controller를 사전에 캡처하여 context 안전성 보장
    final router = GoRouter.of(context);
    final tabController = ref.read(mainTabControllerProvider.notifier);
    final listController = ref.read(journeyListControllerProvider.notifier);

    // 보낸 메시지 탭 활성화 (먼저 탭 전환)
    tabController.switchToSentTab();

    // limit: 20으로 명시적으로 로드하여 홈 화면의 limit:3 로드가 덮어쓰지 않도록 보장
    listController.load(limit: 20);

    // /home으로 이동하여 탭 쉘 내부의 보낸 메시지 리스트로 복귀
    router.go(AppRoutes.home);
  }
}
