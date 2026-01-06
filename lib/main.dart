import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/session/session_manager.dart';

const _logPrefix = '[Main]';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrint('$_logPrefix 앱 부트스트랩 시작');
  }
  await AppBootstrap().initialize();

  if (kDebugMode) {
    debugPrint('$_logPrefix Riverpod 컨테이너 생성');
  }
  final container = ProviderContainer();

  if (kDebugMode) {
    debugPrint('$_logPrefix 세션 복원 시작');
  }
  await container.read(sessionManagerProvider.notifier).restoreSession();

  if (kDebugMode) {
    final status = container.read(sessionManagerProvider).status;
    debugPrint('$_logPrefix 세션 복원 완료: status=$status');
  }

  runApp(UncontrolledProviderScope(
    container: container,
    child: const App(),
  ));
}
