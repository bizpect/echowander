import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/fullscreen_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_list_controller.dart';

class JourneyListScreen extends ConsumerStatefulWidget {
  const JourneyListScreen({super.key});

  @override
  ConsumerState<JourneyListScreen> createState() => _JourneyListScreenState();
}

class _JourneyListScreenState extends ConsumerState<JourneyListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(journeyListControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(journeyListControllerProvider);
    final controller = ref.read(journeyListControllerProvider.notifier);
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    ref.listen<JourneyListState>(journeyListControllerProvider, (previous, next) {
      if (next.message == null || next.message == previous?.message) {
        return;
      }
      unawaited(_handleMessage(l10n, next.message!));
      controller.clearMessage();
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.journeyListTitle),
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
                      l10n.journeyListEmpty,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                                _statusLine(
                                  l10n: l10n,
                                  statusCode: item.statusCode,
                                  filterCode: item.filterCode,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            context.go(
                              '${AppRoutes.journeyList}/${item.journeyId}',
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

  Future<void> _handleMessage(AppLocalizations l10n, JourneyListMessage message) async {
    switch (message) {
      case JourneyListMessage.missingSession:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorSessionExpired,
          confirmLabel: l10n.composeOk,
        );
        return;
      case JourneyListMessage.loadFailed:
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

  String _statusLine({
    required AppLocalizations l10n,
    required String statusCode,
    required String filterCode,
  }) {
    final statusLabel = _statusLabel(l10n, statusCode);
    final filterLabel = _filterLabel(l10n, filterCode);
    final combined =
        filterCode == 'OK' ? statusLabel : '$statusLabel / $filterLabel';
    return '${l10n.journeyListStatusLabel} $combined';
  }

  String _statusLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'CREATED':
        return l10n.journeyStatusCreated;
      case 'WAITING':
        return l10n.journeyStatusWaiting;
      case 'COMPLETED':
        return l10n.journeyStatusCompleted;
      default:
        return l10n.journeyStatusUnknown;
    }
  }

  String _filterLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'OK':
        return l10n.journeyFilterOk;
      case 'HELD':
        return l10n.journeyFilterHeld;
      case 'REMOVED':
        return l10n.journeyFilterRemoved;
      default:
        return l10n.journeyFilterUnknown;
    }
  }
}
