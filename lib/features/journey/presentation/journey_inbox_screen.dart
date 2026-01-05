import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/fullscreen_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_inbox_controller.dart';
import '../domain/journey_repository.dart';

class JourneyInboxScreen extends ConsumerStatefulWidget {
  const JourneyInboxScreen({super.key});

  @override
  ConsumerState<JourneyInboxScreen> createState() => _JourneyInboxScreenState();
}

class _JourneyInboxScreenState extends ConsumerState<JourneyInboxScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(journeyInboxControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(journeyInboxControllerProvider);
    final controller = ref.read(journeyInboxControllerProvider.notifier);
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    ref.listen<JourneyInboxState>(journeyInboxControllerProvider, (previous, next) {
      if (next.message == null || next.message == previous?.message) {
        return;
      }
      unawaited(_handleMessage(l10n, next.message!));
      controller.clearMessage();
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.inboxTitle),
          leading: IconButton(
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () => controller.load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FullScreenLoadingOverlay(
          isLoading: state.isLoading,
          child: SafeArea(
            child: state.items.isEmpty
                ? Center(
                    child: Text(
                      l10n.inboxEmpty,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            item.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateFormat.format(item.createdAt.toLocal())),
                              const SizedBox(height: 4),
                              Text(
                                _recipientStatusLine(l10n, item.recipientStatus),
                              ),
                            ],
                          ),
                          onTap: () {
                            context.go(
                              '${AppRoutes.inbox}/${item.journeyId}',
                              extra: item,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMessage(AppLocalizations l10n, JourneyInboxMessage message) async {
    switch (message) {
      case JourneyInboxMessage.missingSession:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorSessionExpired,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyInboxMessage.loadFailed:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorGeneric,
          confirmLabel: l10n.composeOk,
        );
        return;
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  String _recipientStatusLine(AppLocalizations l10n, String status) {
    return '${l10n.inboxStatusLabel} ${_recipientStatusLabel(l10n, status)}';
  }

  String _recipientStatusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'ASSIGNED':
        return l10n.inboxStatusAssigned;
      case 'RESPONDED':
        return l10n.inboxStatusResponded;
      case 'PASSED':
        return l10n.inboxStatusPassed;
      case 'REPORTED':
        return l10n.inboxStatusReported;
      default:
        return l10n.inboxStatusUnknown;
    }
  }
}
