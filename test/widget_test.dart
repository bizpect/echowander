import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echowander/app/app.dart';
import 'package:echowander/core/config/app_config.dart';
import 'package:echowander/core/push/push_coordinator.dart';
import 'package:echowander/features/splash/presentation/splash_screen.dart';

class _TestPushCoordinator extends PushCoordinator {
  @override
  Future<void> initialize() async {
    // 위젯 테스트 환경에서는 Firebase 초기화가 없으므로 푸시 초기화를 생략합니다.
    return;
  }
}

void main() {
  testWidgets('shows splash screen on launch', (WidgetTester tester) async {
    // 테스트 환경에서는 부트스트랩이 실행되지 않으므로 AppConfig를 선 주입합니다.
    AppConfigStore.current = const AppConfig(
      environment: AppEnvironment.dev,
      authBaseUrl: '',
      kakaoNativeAppKey: '',
      googleServerClientId: '',
      googleIosClientId: '',
      supabaseUrl: '',
      supabaseAnonKey: '',
      dispatchJobSecret: '',
      admobAppIdAndroid: '',
      admobAppIdIos: '',
      admobRewardedUnitIdAndroidProd: '',
      admobRewardedUnitIdIosProd: '',
      admobNativeUnitIdAndroidProd: '',
      admobNativeUnitIdIosProd: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushCoordinatorProvider.overrideWith(_TestPushCoordinator.new),
        ],
        child: const App(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
