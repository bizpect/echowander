import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echowander/app/app.dart';
import 'package:echowander/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('shows splash screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
