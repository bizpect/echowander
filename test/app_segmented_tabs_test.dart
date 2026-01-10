import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echowander/core/presentation/widgets/app_segmented_tabs.dart';

class _SegmentedTabsHarness extends StatefulWidget {
  const _SegmentedTabsHarness({
    required this.bounded,
  });

  final bool bounded;

  @override
  State<_SegmentedTabsHarness> createState() => _SegmentedTabsHarnessState();
}

class _SegmentedTabsHarnessState extends State<_SegmentedTabsHarness> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const AppSegmentedTab(label: 'In progress (12)'),
      const AppSegmentedTab(label: 'Completed (3)'),
    ];

    final segmented = AppSegmentedTabs(
      key: const ValueKey('segmented_tabs'),
      tabs: tabs,
      selectedIndex: _selectedIndex,
      onChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );

    if (widget.bounded) {
      return SizedBox(width: 360, child: segmented);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [segmented],
    );
  }
}

void main() {
  testWidgets('bounded width stays fixed on tab change', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: _SegmentedTabsHarness(bounded: true),
          ),
        ),
      ),
    );

    final segmentedFinder = find.byKey(const ValueKey('segmented_tabs'));
    final before = tester.getSize(segmentedFinder);

    await tester.tap(find.text('Completed (3)'));
    await tester.pumpAndSettle();

    final after = tester.getSize(segmentedFinder);
    expect(after.width, equals(before.width));
  });

  testWidgets('unbounded width stays fixed on tab change', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: _SegmentedTabsHarness(bounded: false),
          ),
        ),
      ),
    );

    final segmentedFinder = find.byKey(const ValueKey('segmented_tabs'));
    final before = tester.getSize(segmentedFinder);

    await tester.tap(find.text('Completed (3)'));
    await tester.pumpAndSettle();

    final after = tester.getSize(segmentedFinder);
    expect(after.width, equals(before.width));
  });
}
