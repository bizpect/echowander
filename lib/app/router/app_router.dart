import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/session_manager.dart';
import '../../core/session/session_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionState = ref.watch(sessionManagerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final status = sessionState.status;
      final location = state.matchedLocation;

      if (status == SessionStatus.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (status == SessionStatus.unauthenticated) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }

      if (status == SessionStatus.authenticated) {
        return location == AppRoutes.home ? null : AppRoutes.home;
      }

      return null;
    },
  );
});
