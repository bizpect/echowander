import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';

/// 공용 세그먼트 탭 컴포넌트
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<AppSegmentedTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();

    final clampedSelected = selectedIndex.clamp(0, tabs.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseStyle = AppTextStyles.body;
        final measureStyle = AppTextStyles.bodyStrong;
        final selectedBackgroundColor =
            Theme.of(context).bottomNavigationBarTheme.selectedItemColor ??
                AppColors.primary;
        final selectedTextColor = Theme.of(context).colorScheme.onPrimary;
        final strut = StrutStyle.fromTextStyle(
          baseStyle,
          forceStrutHeight: true,
        );
        final contentWidth = _resolveContentWidth(
          context: context,
          constraints: constraints,
          measureStyle: measureStyle,
        );
        final totalWidth = contentWidth + (AppSpacing.xs * 2);
        final segmentWidth = contentWidth / tabs.length;
        assert(() {
          debugPrint(
            '[AppSegmentedTabs] bounded=${constraints.hasBoundedWidth} '
            'totalWidth=$totalWidth segmentWidth=$segmentWidth',
          );
          return true;
        }());

        return Semantics(
          container: true,
          child: SizedBox(
            width: totalWidth,
            child: ClipRRect(
              borderRadius: AppRadius.large,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.large,
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: SizedBox(
                    width: contentWidth,
                    height: AppSpacing.minTouchTarget,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          left: segmentWidth * clampedSelected,
                          top: 0,
                          bottom: 0,
                          width: segmentWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: selectedBackgroundColor,
                              borderRadius: AppRadius.large,
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(tabs.length, (index) {
                            final tab = tabs[index];
                            final isSelected = index == clampedSelected;
                            final targetColor = isSelected
                                ? selectedTextColor
                                : AppColors.textSecondary;

                            return SizedBox(
                              width: segmentWidth,
                              child: Semantics(
                                button: true,
                                selected: isSelected,
                                enabled: true,
                                label: tab.semanticsLabel ?? tab.label,
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: InkWell(
                                    borderRadius: AppRadius.large,
                                    onTap: isSelected
                                        ? null
                                        : () => onChanged(index),
                                    child: Center(
                                      child: TweenAnimationBuilder<Color?>(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        curve: Curves.easeOut,
                                        tween: ColorTween(end: targetColor),
                                        builder: (context, color, child) {
                                          return Text(
                                            tab.label,
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.ellipsis,
                                            strutStyle: strut,
                                            style: baseStyle.copyWith(
                                              color: color ?? targetColor,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _resolveContentWidth({
    required BuildContext context,
    required BoxConstraints constraints,
    required TextStyle measureStyle,
  }) {
    if (constraints.hasBoundedWidth) {
      final boundedWidth = constraints.maxWidth - (AppSpacing.xs * 2);
      return boundedWidth > 0 ? boundedWidth : 0.0;
    }
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final locale = Localizations.localeOf(context);
    var maxLabelWidth = 0.0;
    for (final tab in tabs) {
      final painter = TextPainter(
        text: TextSpan(text: tab.label, style: measureStyle),
        textScaler: textScaler,
        maxLines: 1,
        textDirection: direction,
        locale: locale,
      )..layout();
      if (painter.width > maxLabelWidth) {
        maxLabelWidth = painter.width;
      }
    }
    final paddedLabelWidth = maxLabelWidth + (AppSpacing.md * 2);
    final minSegmentWidth =
        AppSpacing.minTouchTarget.toDouble();
    final segmentWidth =
        paddedLabelWidth < minSegmentWidth ? minSegmentWidth : paddedLabelWidth;
    return segmentWidth * tabs.length;
  }
}

class AppSegmentedTab {
  const AppSegmentedTab({
    required this.label,
    this.semanticsLabel,
  });

  final String label;
  final String? semanticsLabel;
}
