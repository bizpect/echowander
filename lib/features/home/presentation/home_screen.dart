import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/session/session_manager.dart';
import '../../notifications/application/notification_inbox_controller.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationInboxControllerProvider.notifier).loadUnreadCount(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeControllerProvider);
    final selectedTag = _localeTag(currentLocale);
    final notificationState = ref.watch(notificationInboxControllerProvider);

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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.homeGreeting,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.compose),
                child: Text(l10n.composeCta),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.journeyList),
                child: Text(l10n.journeyListCta),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.inbox),
                child: Text(l10n.inboxCta),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.notifications),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.notificationsTitle),
                    if (notificationState.unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      _NotificationBadge(count: notificationState.unreadCount),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.settings),
                child: Text(l10n.settingsCta),
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

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final display = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        display,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
      ),
    );
  }
}
