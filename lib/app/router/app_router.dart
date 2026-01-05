import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/session_manager.dart';
import '../../core/session/session_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/journey/presentation/journey_compose_screen.dart';
import '../../features/journey/presentation/journey_inbox_detail_screen.dart';
import '../../features/journey/presentation/journey_inbox_screen.dart';
import '../../features/journey/presentation/journey_list_screen.dart';
import '../../features/journey/presentation/journey_sent_detail_screen.dart';
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
  final sessionState = ref.watch(sessionManagerProvider);
  final onboardingState = ref.watch(onboardingControllerProvider);

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
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.compose,
        builder: (context, state) => const JourneyComposeScreen(),
      ),
      GoRoute(
        path: AppRoutes.journeyList,
        builder: (context, state) => const JourneyListScreen(),
      ),
      GoRoute(
        path: AppRoutes.journeyDetail,
        builder: (context, state) => JourneySentDetailScreen(
          journeyId: state.pathParameters['journeyId'] ?? '',
          summary: state.extra as JourneySummary?,
        ),
      ),
      GoRoute(
        path: AppRoutes.inbox,
        builder: (context, state) => JourneyInboxScreen(
          highlightJourneyId: state.uri.queryParameters['highlight'],
        ),
      ),
      GoRoute(
        path: AppRoutes.inboxDetail,
        builder: (context, state) => JourneyInboxDetailScreen(
          item: state.extra as JourneyInboxItem?,
        ),
      ),
      GoRoute(
        path: AppRoutes.journeyResults,
        builder: (context, state) => JourneySentDetailScreen(
          journeyId: state.pathParameters['journeyId'] ?? '',
          summary: state.extra as JourneySummary?,
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
      final status = sessionState.status;
      final location = state.matchedLocation;
      final onboardingStatus = onboardingState.status;

      if (status == SessionStatus.unknown ||
          onboardingStatus == OnboardingStatus.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (onboardingStatus == OnboardingStatus.required) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      if (status == SessionStatus.unauthenticated) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }

      if (status == SessionStatus.authenticated) {
        if (location == AppRoutes.pushPreview ||
            location == AppRoutes.compose ||
            location == AppRoutes.journeyList ||
            location.startsWith('/journeys/') ||
            location == AppRoutes.inbox ||
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
