import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 테마 선택 바텀시트
class ThemeSelectionBottomSheet extends ConsumerWidget {
  const ThemeSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final currentMode = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    final themes = [
      _ThemeOption(mode: ThemeMode.dark, label: l10n.themeDark),
      _ThemeOption(mode: ThemeMode.light, label: l10n.themeLight),
    ];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l10n.settingsTheme,
              style: AppTextStyles.titleMd.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final option = themes[index];
                final isSelected = currentMode == option.mode;
                return ListTile(
                  title: Text(
                    option.label,
                    style: AppTextStyles.body.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    controller.setThemeMode(option.mode);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption({required this.mode, required this.label});

  final ThemeMode mode;
  final String label;
}
