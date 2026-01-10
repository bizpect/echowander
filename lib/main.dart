import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/session/session_manager.dart';

const _logPrefix = '[Main]';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Unhandled Exception 최종 안전망
  FlutterError.onError = (details) {
    if (kDebugMode) {
      debugPrint(
        '$_logPrefix FlutterError.onError: ${details.exception} '
        '(stack: ${details.stack})',
      );
    }
    // 프로덕션에서는 크래시 리포팅 서비스로 전송
    FlutterError.presentError(details);
  };

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

  // 세션 복원 실패해도 앱은 계속 진행 (router redirect가 /login으로 안내)
  // RestoreSessionFailedException 발생 시 session_manager가 이미
  // 토큰 clear + unauthenticated 상태로 전환함
  // Future 체인 밖 예외 방지: catchError로 추가 보호
  final restoreFuture = container
      .read(sessionManagerProvider.notifier)
      .restoreSession()
      .catchError((error, stackTrace) {
        // RestoreSessionTransientException은 try-catch에서 처리되지만,
        // catchError로 Future 체인 밖 예외도 흡수
        if (kDebugMode) {
          debugPrint('$_logPrefix restoreSession Future 체인 예외 흡수: $error');
        }
      });

  try {
    await restoreFuture;
  } on RestoreSessionBlockedException {
    // 쿨다운 중 - 이전 실패로 인해 차단됨, 앱 계속 진행
    if (kDebugMode) {
      debugPrint('$_logPrefix 세션 복원 쿨다운 중 → 건너뜀');
    }
  } on RestoreSessionFailedException {
    // refresh 실패 - 이미 unauthenticated로 전환됨, 앱 계속 진행
    if (kDebugMode) {
      debugPrint('$_logPrefix 세션 복원 실패 → router가 /login으로 안내');
    }
  } on RestoreSessionTransientException {
    // 일시 장애 - 토큰 유지, 앱 계속 진행 (Unhandled Exception 방지)
    if (kDebugMode) {
      debugPrint('$_logPrefix 세션 복원 일시 장애 → 앱 계속 진행');
    }
  } catch (e) {
    // 예상치 못한 오류 - 로그만 남기고 앱 계속 진행
    if (kDebugMode) {
      debugPrint('$_logPrefix 세션 복원 중 예외: $e');
    }
  }

  if (kDebugMode) {
    final status = container.read(sessionManagerProvider).status;
    debugPrint('$_logPrefix 세션 복원 완료: status=$status');
  }

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
