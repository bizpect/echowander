import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/home/presentation/home_screen.dart';
import '../../../features/journey/presentation/journey_compose_screen.dart';
import '../../../features/journey/presentation/journey_inbox_screen.dart';
import '../../../features/journey/presentation/journey_list_screen.dart';
import '../../../features/journey/application/journey_inbox_controller.dart';
import '../../../features/profile/presentation/profile_screen.dart';
import '../widgets/app_bottom_navigation.dart';

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
  int _currentIndex = AppTab.home.tabIndex;
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
    // 다른 탭으로 전환 시에만 fade 애니메이션 실행
    if (_currentIndex != index) {
      _fadeController.forward(from: 0.0);
    }

    setState(() {
      _currentIndex = index;
    });

    // 탭 전환 시 해당 탭의 데이터 새로고침
    if (index == AppTab.inbox.tabIndex) {
      ref.read(journeyInboxControllerProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 루트 화면에서 뒤로가기 시 앱 종료 확인
      canPop: _currentIndex != AppTab.home.tabIndex,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != AppTab.home.tabIndex) {
          // 다른 탭에서 뒤로가기 시 Home으로 이동
          setState(() {
            _currentIndex = AppTab.home.tabIndex;
          });
        }
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: IndexedStack(
            index: _currentIndex,
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

              // Create 탭 (단일 화면, Navigator 불필요)
              const JourneyComposeScreen(),

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
          currentIndex: _currentIndex,
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
