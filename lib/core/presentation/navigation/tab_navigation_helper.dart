import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../scaffolds/main_tab_controller.dart';

/// 탭 루트로 복귀하는 네비게이션 helper
///
/// 상세 화면에서 뒤로가기 시 각 탭의 루트 화면(리스트)으로 정확히 복귀하도록 보장합니다.
/// 딥링크로 상세만 열린 경우에도 탭 루트를 구성하고 해당 탭을 활성화합니다.
class TabNavigationHelper {
  /// 받은 메시지 탭 루트로 복귀
  ///
  /// - 상세 화면이 스택에 있으면 pop
  /// - 탭 루트로 이동하고 받은 메시지 탭 활성화
  static void goToInboxRoot(BuildContext context, WidgetRef ref) {
    // router와 controller를 사전에 캡처하여 context 안전성 보장
    final router = GoRouter.of(context);
    final tabController = ref.read(mainTabControllerProvider.notifier);

    // 상세 화면이 스택에 있으면 pop (스택 정리)
    if (context.canPop()) {
      context.pop();
    }

    // 받은 메시지 탭 루트로 이동
    router.go(AppRoutes.inbox);
    // 받은 메시지 탭 활성화
    tabController.switchToInboxTab();
  }

  /// 보낸 메시지 탭 루트로 복귀
  ///
  /// - 상세 화면이 스택에 있으면 pop
  /// - 탭 루트로 이동하고 보낸 메시지 탭 활성화
  static void goToSentRoot(BuildContext context, WidgetRef ref) {
    // router와 controller를 사전에 캡처하여 context 안전성 보장
    final router = GoRouter.of(context);
    final tabController = ref.read(mainTabControllerProvider.notifier);

    // 상세 화면이 스택에 있으면 pop (스택 정리)
    if (context.canPop()) {
      context.pop();
    }

    // 보낸 메시지 탭 루트로 이동
    router.go(AppRoutes.journeyList);
    // 보낸 메시지 탭 활성화
    tabController.switchToSentTab();
  }
}
