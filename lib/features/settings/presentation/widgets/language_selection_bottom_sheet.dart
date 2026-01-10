import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/locale/locale_controller.dart';
import '../../../../l10n/app_localizations.dart';

/// 언어 선택 바텀시트
class LanguageSelectionBottomSheet extends ConsumerWidget {
  const LanguageSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final currentCode = ref.watch(localeControllerProvider.notifier).getCurrentLanguageCode();
    final controller = ref.read(localeControllerProvider.notifier);

    final languages = [
      _LanguageOption(code: 'system', label: l10n.languageSystem),
      _LanguageOption(code: 'ko', label: l10n.languageKorean),
      _LanguageOption(code: 'en', label: l10n.languageEnglish),
      _LanguageOption(code: 'ja', label: l10n.languageJapanese),
      _LanguageOption(code: 'es', label: l10n.languageSpanish),
      _LanguageOption(code: 'fr', label: l10n.languageFrench),
      _LanguageOption(code: 'pt', label: l10n.languagePortuguese),
      _LanguageOption(code: 'zh', label: l10n.languageChinese),
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
              l10n.settingsLanguage,
              style: AppTextStyles.titleMd.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final option = languages[index];
                final isSelected = currentCode == option.code;
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
                    controller.setLocaleTag(option.code);
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

class _LanguageOption {
  const _LanguageOption({required this.code, required this.label});

  final String code;
  final String label;
}
