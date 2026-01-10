import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/app_bottom_navigation.dart';

/// MainScaffold의 탭 인덱스를 관리하는 Controller
///
/// 외부에서 탭 전환을 제어할 수 있도록 제공됩니다.
/// 예: 전송 완료 후 보낸메세지 탭으로 이동
class MainTabController extends Notifier<int> {
  @override
  int build() {
    return AppTab.home.tabIndex;
  }

  /// 특정 탭으로 전환
  void switchToTab(AppTab tab) {
    state = tab.tabIndex;
  }

  /// 보낸메세지 탭으로 전환
  void switchToSentTab() {
    switchToTab(AppTab.sent);
  }

  /// 인박스 탭으로 전환
  void switchToInboxTab() {
    switchToTab(AppTab.inbox);
  }

  /// 홈 탭으로 전환
  void switchToHomeTab() {
    switchToTab(AppTab.home);
  }
}

final mainTabControllerProvider = NotifierProvider<MainTabController, int>(
  MainTabController.new,
);
