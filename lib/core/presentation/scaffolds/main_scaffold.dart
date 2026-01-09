import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../features/home/presentation/home_screen.dart';
import '../../../features/journey/presentation/journey_inbox_screen.dart';
import '../../../features/journey/presentation/journey_list_screen.dart';
import '../../../features/journey/application/journey_inbox_controller.dart';
import '../../../features/journey/application/journey_list_controller.dart';
import '../../../features/profile/presentation/profile_screen.dart';
import '../widgets/app_bottom_navigation.dart';
import 'main_tab_controller.dart';

/// 메인 앱 Scaffold - 5탭 네비게이션 구조
///
/// 각 탭은 독립적인 화면을 가지며, IndexedStack으로 상태를 유지합니다.
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 탭 전환 시 subtle fade 애니메이션 설정 (150ms, 과하지 않은 수준)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..value = 1.0; // 초기값 1.0 (완전 표시)

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Create 탭(index 2)은 GoRouter로 navigate
    if (index == AppTab.create.tabIndex) {
      context.go(AppRoutes.compose);
      return;
    }

    final currentIndex = ref.read(mainTabControllerProvider);
    
    // 다른 탭으로 전환 시에만 fade 애니메이션 실행
    if (currentIndex != index) {
      _fadeController.forward(from: 0.0);
    }

    // Provider를 통해 탭 인덱스 업데이트
    ref.read(mainTabControllerProvider.notifier).switchToTab(AppTab.fromIndex(index));

    // 탭 전환 시 해당 탭의 데이터 새로고침
    // limit을 명시적으로 20으로 설정하여 홈 화면의 limit:3 로드가 덮어쓰지 않도록 보장
    if (index == AppTab.inbox.tabIndex) {
      ref.read(journeyInboxControllerProvider.notifier).load(limit: 20);
    } else if (index == AppTab.sent.tabIndex) {
      ref.read(journeyListControllerProvider.notifier).load(limit: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider에서 현재 탭 인덱스 구독
    final currentIndex = ref.watch(mainTabControllerProvider);
    
    return PopScope(
      // 루트 화면에서 뒤로가기 시 앱 종료 확인
      canPop: currentIndex != AppTab.home.tabIndex,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != AppTab.home.tabIndex) {
          // 다른 탭에서 뒤로가기 시 Home으로 이동
          ref.read(mainTabControllerProvider.notifier).switchToTab(AppTab.home);
        }
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: IndexedStack(
            index: currentIndex,
            children: [
              // Home 탭 (Nested Navigator)
              _buildTabNavigator(
                const HomeScreen(),
                key: const ValueKey('home_navigator'),
              ),

              // Sent 탭 (Nested Navigator)
              _buildTabNavigator(
                const JourneyListScreen(),
                key: const ValueKey('sent_navigator'),
              ),

              // Create 탭은 GoRouter로 navigate하므로 빈 위젯
              const SizedBox.shrink(),

              // Inbox 탭 (Nested Navigator)
              _buildTabNavigator(
                const JourneyInboxScreen(),
                key: const ValueKey('inbox_navigator'),
              ),

              // Profile 탭 (Nested Navigator)
              _buildTabNavigator(
                const ProfileScreen(),
                key: const ValueKey('profile_navigator'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }

  /// 탭별 독립 Navigator 생성
  ///
  /// 각 탭은 자체 Navigator 스택을 가지며,
  /// 탭 전환 시에도 스크롤 위치와 라우트 상태가 유지됩니다.
  Widget _buildTabNavigator(Widget rootScreen, {required Key key}) {
    return Navigator(
      key: key,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => rootScreen,
          settings: settings,
        );
      },
    );
  }
}
