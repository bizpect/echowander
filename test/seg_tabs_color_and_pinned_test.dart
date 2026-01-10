import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echowander/app/theme/app_theme.dart';
import 'package:echowander/features/journey/application/journey_list_controller.dart';
import 'package:echowander/features/journey/presentation/journey_list_screen.dart';
import 'package:echowander/core/presentation/widgets/app_segmented_tabs.dart';
import 'package:echowander/l10n/app_localizations.dart';

class _FakeJourneyListController extends JourneyListController {
  @override
  JourneyListState build() {
    return const JourneyListState(
      items: [],
      isLoading: false,
      message: null,
    );
  }

  @override
  Future<void> load({int limit = 20, int offset = 0}) async {}
}

void main() {
  testWidgets('segmented selected background matches bottom nav token',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: AppSegmentedTabs(
              tabs: const [
                AppSegmentedTab(label: 'A'),
                AppSegmentedTab(label: 'B'),
              ],
              selectedIndex: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final theme = Theme.of(tester.element(find.byType(AppSegmentedTabs)));
    final expected =
        theme.bottomNavigationBarTheme.selectedItemColor ??
            theme.colorScheme.primary;

    final indicatorFinder = find.descendant(
      of: find.byType(AnimatedPositioned),
      matching: find.byType(DecoratedBox),
    );
    final indicator =
        tester.widget<DecoratedBox>(indicatorFinder.first);
    final decoration = indicator.decoration as BoxDecoration;

    expect(decoration.color, expected);
  });

  testWidgets('segmented tabs are pinned outside scrollable',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journeyListControllerProvider.overrideWith(
            _FakeJourneyListController.new,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const JourneyListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final tabsFinder = find.byType(AppSegmentedTabs);
    expect(
      find.ancestor(
        of: tabsFinder,
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
  });
}
