import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/presentation/scaffolds/main_tab_controller.dart';
import '../../core/session/session_manager.dart';
import '../../core/session/session_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../core/presentation/scaffolds/main_scaffold.dart';
import '../../features/journey/presentation/journey_compose_screen.dart';
import '../../features/journey/presentation/journey_inbox_detail_screen.dart';
import '../../features/journey/presentation/sent_detail/sent_journey_detail_screen.dart';
import '../../features/onboarding/application/onboarding_controller.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/push/presentation/push_preview_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/journey/domain/journey_repository.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/block/presentation/block_list_screen.dart';
import '../../features/notifications/presentation/notification_inbox_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const home = '/home';
  static const compose = '/compose';
  static const journeyList = '/journeys';
  static const journeyDetail = '/journeys/:journeyId';
  static const inbox = '/inbox';
  static const inboxDetail = '/inbox/:journeyId';
  static const journeyResults = '/results/:journeyId';
  static const settings = '/settings';
  static const blockList = '/settings/blocks';
  static const notifications = '/notifications';
  static const pushPreview = '/push-preview';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // ✅ 라우팅은 status만 구독 (isBusy/message 변화로 재생성 방지)
  final sessionStatus = ref.watch(
    sessionManagerProvider.select((state) => state.status),
  );
  // redirect에 필요한 onboardingStatus만 select로 watch
  // 체크 토글 시 전체 state 변경이 router 재생성을 유발하지 않도록 방지
  final onboardingStatus = ref.watch(
    onboardingControllerProvider.select((state) => state.status),
  );

  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: AppRoutes.compose,
        builder: (context, state) => const JourneyComposeScreen(),
      ),
      GoRoute(
        path: AppRoutes.journeyDetail,
        builder: (context, state) => SentJourneyDetailScreen(
          journeyId: state.pathParameters['journeyId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.inboxDetail,
        builder: (context, state) =>
            JourneyInboxDetailScreen(item: state.extra as JourneyInboxItem?),
      ),
      GoRoute(
        path: AppRoutes.journeyResults,
        builder: (context, state) => SentJourneyDetailScreen(
          journeyId: state.pathParameters['journeyId'] ?? '',
          fromNotification:
              state.uri.queryParameters['highlight'] == '1' ||
              state.uri.queryParameters['highlight'] == 'true',
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.blockList,
        builder: (context, state) => const BlockListScreen(),
      ),
      GoRoute(
        path: AppRoutes.pushPreview,
        builder: (context, state) => const PushPreviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationInboxScreen(),
      ),
    ],
    redirect: (context, state) {
      final status = sessionStatus;
      final location = state.matchedLocation;

      if (status == SessionStatus.unknown ||
          onboardingStatus == OnboardingStatus.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (onboardingStatus == OnboardingStatus.required) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      if (status == SessionStatus.unauthenticated) {
        // ✅ 로그인 경로는 항상 허용 (redirect 충돌 방지)
        if (location == AppRoutes.login) {
          return null; // 이미 로그인 화면이면 stay
        }
        // ✅ unauthenticated 상태에서는 반드시 로그인으로 이동
        if (kDebugMode) {
          debugPrint(
            '[Router] redirect: status=unauthenticated, from=$location, to=${AppRoutes.login}',
          );
        }
        return AppRoutes.login;
      }

      if (status == SessionStatus.authenticated) {
        // 탭 없는 리스트 화면으로의 직접 접근을 막고 /home으로 리다이렉트하며 탭 활성화
        if (location == AppRoutes.journeyList) {
          // 보낸 메시지 탭 활성화 후 /home으로 리다이렉트
          ref.read(mainTabControllerProvider.notifier).switchToSentTab();
          return AppRoutes.home;
        }
        if (location == AppRoutes.inbox) {
          // 받은 메시지 탭 활성화 후 /home으로 리다이렉트
          ref.read(mainTabControllerProvider.notifier).switchToInboxTab();
          return AppRoutes.home;
        }

        if (location == AppRoutes.pushPreview ||
            location == AppRoutes.compose ||
            location.startsWith('/journeys/') ||
            location.startsWith('/inbox/') ||
            location.startsWith('/results/') ||
            location == AppRoutes.settings ||
            location == AppRoutes.blockList ||
            location == AppRoutes.notifications) {
          return null;
        }
        return location == AppRoutes.home ? null : AppRoutes.home;
      }

      return null;
    },
  );
});
