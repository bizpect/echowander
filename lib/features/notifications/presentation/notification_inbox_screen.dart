import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/presentation/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../application/notification_inbox_controller.dart';
import '../domain/notification_item.dart';

/// Alerts 화면 - 알림 목록
///
/// 특징:
/// - 읽음/미읽음 시각적 구분 (배경색, 아이콘)
/// - 알림 타입별 아이콘 표시
/// - EmptyStateWidget로 빈 상태 처리
/// - LoadingOverlay로 로딩 상태 처리
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
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          actions: [
            IconButton(
              onPressed: () => controller.load(),
              icon: const Icon(Icons.refresh),
              tooltip: l10n.inboxRefresh,
            ),
          ],
        ),
        body: LoadingOverlay(
          isLoading: state.isLoading,
          child: SafeArea(
            child: _buildBody(context, l10n, state, controller),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    NotificationInboxState state,
    NotificationInboxController controller,
  ) {
    // 빈 상태
    if (state.items.isEmpty && !state.isLoading) {
      return EmptyStateWidget(
        icon: Icons.notifications_outlined,
        title: l10n.notificationsEmpty,
        description: l10n.homeEmptyDescription,
        actionLabel: l10n.homeCreateCardTitle,
        onAction: () => context.go(AppRoutes.compose),
      );
    }

    // 정상 상태 - 알림 리스트
    return Column(
      children: [
        // 미읽음 필터 토글
        SwitchListTile.adaptive(
          value: state.unreadOnly,
          onChanged: controller.toggleUnreadOnly,
          title: Text(l10n.notificationsUnreadOnly),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing16,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => controller.load(),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.spacing16,
                AppSpacing.spacing8,
                AppSpacing.spacing16,
                AppSpacing.spacing24,
              ),
              itemCount: state.items.length,
              separatorBuilder: (context, index) => SizedBox(height: AppSpacing.spacing12),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _NotificationCard(
                  item: item,
                  onTap: () => _openNotification(item),
                  onDelete: () => _confirmDelete(l10n, item),
                );
              },
            ),
          ),
        ),
      ],
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

/// 알림 카드
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    // 읽음/미읽음 스타일 결정
    final isRead = item.isRead;
    final backgroundColor = isRead
        ? AppColors.surface
        : AppColors.primary.withValues(alpha: 0.08);
    final elevation = isRead ? 1.0 : 2.0;

    // 알림 타입 정보 추출
    final notificationInfo = _getNotificationInfo(item);

    return Card(
      color: backgroundColor,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacing16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 알림 타입 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notificationInfo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notificationInfo.icon,
                  size: 20,
                  color: notificationInfo.color,
                ),
              ),
              SizedBox(width: AppSpacing.spacing12),

              // 알림 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 + 읽음 상태
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title.isNotEmpty
                                ? item.title
                                : l10n.notificationTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: EdgeInsets.only(left: AppSpacing.spacing8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.spacing4),
                      Text(
                        item.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: AppSpacing.spacing8),

                    // 하단 정보 (날짜 + 읽음 상태 라벨)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        SizedBox(width: AppSpacing.spacing4),
                        Text(
                          dateFormat.format(item.createdAt.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                        SizedBox(width: AppSpacing.spacing8),
                        Text(
                          '•',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                        SizedBox(width: AppSpacing.spacing8),
                        Text(
                          isRead ? l10n.notificationsRead : l10n.notificationsUnread,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isRead
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.primary,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 삭제 버튼
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                iconSize: 20,
                color: AppColors.onSurfaceVariant,
                tooltip: l10n.notificationsDeleteConfirm,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _NotificationInfo _getNotificationInfo(NotificationItem item) {
    // 제목 또는 라우트 기반으로 알림 타입 판단
    final title = item.title.toLowerCase();
    final route = item.route?.toLowerCase() ?? '';

    if (title.contains('result') || route.contains('result')) {
      return _NotificationInfo(
        icon: Icons.celebration,
        color: AppColors.success,
      );
    } else if (title.contains('new') || title.contains('message') || route.contains('inbox')) {
      return _NotificationInfo(
        icon: Icons.mail_outline,
        color: AppColors.primary,
      );
    } else {
      return _NotificationInfo(
        icon: Icons.notifications_active,
        color: AppColors.warning,
      );
    }
  }
}

/// 알림 타입 정보 (아이콘 + 색상)
class _NotificationInfo {
  const _NotificationInfo({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}
