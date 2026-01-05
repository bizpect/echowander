import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/fullscreen_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../application/notification_inbox_controller.dart';
import '../domain/notification_item.dart';

class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends ConsumerState<NotificationInboxScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationInboxControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(notificationInboxControllerProvider);
    final controller = ref.read(notificationInboxControllerProvider.notifier);
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    ref.listen<NotificationInboxState>(notificationInboxControllerProvider,
        (previous, next) {
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
          title: Text(l10n.notificationsTitle),
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
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: state.unreadOnly,
                  onChanged: controller.toggleUnreadOnly,
                  title: Text(l10n.notificationsUnreadOnly),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                Expanded(
                  child: state.items.isEmpty
                      ? Center(
                          child: Text(
                            l10n.notificationsEmpty,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: state.items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return Card(
                              child: ListTile(
                                leading: _UnreadDot(isRead: item.isRead),
                                title: Text(
                                  item.title.isNotEmpty
                                      ? item.title
                                      : l10n.notificationTitle,
                                ),
                                subtitle: _NotificationSubtitle(
                                  item: item,
                                  dateFormat: dateFormat,
                                  readLabel: item.isRead
                                      ? l10n.notificationsRead
                                      : l10n.notificationsUnread,
                                ),
                                trailing: IconButton(
                                  onPressed: () => _confirmDelete(l10n, item),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                                onTap: () => _openNotification(item),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openNotification(NotificationItem item) async {
    await ref
        .read(notificationInboxControllerProvider.notifier)
        .markRead(item.id);
    if (!mounted) {
      return;
    }
    final route = _resolveRoute(item);
    if (route != null && route.isNotEmpty) {
      context.go(route);
    }
  }

  Future<void> _confirmDelete(AppLocalizations l10n, NotificationItem item) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.notificationsDeleteTitle,
      message: l10n.notificationsDeleteMessage,
      confirmLabel: l10n.notificationsDeleteConfirm,
      cancelLabel: l10n.composeCancel,
    );
    if (confirmed != true) {
      return;
    }
    await ref
        .read(notificationInboxControllerProvider.notifier)
        .deleteNotification(item.id);
  }

  Future<void> _handleMessage(
    AppLocalizations l10n,
    NotificationInboxMessage message,
  ) async {
    switch (message) {
      case NotificationInboxMessage.missingSession:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorSessionExpired,
          confirmLabel: l10n.composeOk,
        );
        return;
      case NotificationInboxMessage.loadFailed:
      case NotificationInboxMessage.actionFailed:
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
      return;
    }
    context.go(AppRoutes.home);
  }

  String? _resolveRoute(NotificationItem item) {
    final rawRoute = item.route;
    if (rawRoute == null || rawRoute.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(rawRoute);
    if (uri == null) {
      return rawRoute;
    }
    final query = Map<String, String>.from(uri.queryParameters);
    final data = item.data;
    final journeyId = data?['journey_id'];
    if (journeyId is String && journeyId.isNotEmpty) {
      if (uri.path == AppRoutes.inbox && !query.containsKey('highlight')) {
        query['highlight'] = journeyId;
      } else if (uri.path.startsWith('/results/') &&
          !query.containsKey('highlight')) {
        query['highlight'] = '1';
      }
    }
    if (query.isEmpty) {
      return rawRoute;
    }
    return uri.replace(queryParameters: query).toString();
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final color = isRead
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NotificationSubtitle extends StatelessWidget {
  const _NotificationSubtitle({
    required this.item,
    required this.dateFormat,
    required this.readLabel,
  });

  final NotificationItem item;
  final DateFormat dateFormat;
  final String readLabel;

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${dateFormat.format(item.createdAt.toLocal())} - $readLabel';
    final body = item.body;
    if (body.isEmpty) {
      return Text(dateText);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(dateText),
      ],
    );
  }
}
