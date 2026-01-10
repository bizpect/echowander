import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echowander/core/presentation/widgets/app_empty_state.dart';
import 'package:echowander/features/journey/application/journey_list_controller.dart';
import 'package:echowander/features/journey/presentation/journey_list_screen.dart';
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
  testWidgets('empty state is rendered in SliverFillRemaining', (tester) async {
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

    expect(find.byType(SliverFillRemaining), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SliverFillRemaining),
        matching: find.byType(AppEmptyState),
      ),
      findsOneWidget,
    );
  });
}
