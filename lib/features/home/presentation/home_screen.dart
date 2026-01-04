import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/session/session_manager.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeControllerProvider);
    final selectedTag = _localeTag(currentLocale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            onPressed: () => ref.read(sessionManagerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.homeGreeting,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.languageSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: selectedTag,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                ref.read(localeControllerProvider.notifier).setLocaleTag(value);
              },
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.languageSystem),
                ),
                DropdownMenuItem(
                  value: 'ko',
                  child: Text(l10n.languageKorean),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.languageEnglish),
                ),
                DropdownMenuItem(
                  value: 'ja',
                  child: Text(l10n.languageJapanese),
                ),
                DropdownMenuItem(
                  value: 'es',
                  child: Text(l10n.languageSpanish),
                ),
                DropdownMenuItem(
                  value: 'fr',
                  child: Text(l10n.languageFrench),
                ),
                DropdownMenuItem(
                  value: 'pt_BR',
                  child: Text(l10n.languagePortuguese),
                ),
                DropdownMenuItem(
                  value: 'zh',
                  child: Text(l10n.languageChinese),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _localeTag(Locale? locale) {
    if (locale == null) {
      return 'system';
    }
    if (locale.languageCode == 'pt' && locale.countryCode == 'BR') {
      return 'pt_BR';
    }
    return locale.languageCode;
  }
}
