import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/empty_state.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/session/session_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_inbox_controller.dart';
import '../domain/journey_repository.dart';

/// Inbox 화면 - 받은 Journey 목록
///
/// 특징:
/// - 상태별 시각적 구분 (아이콘, 색상)
/// - 딥링크 하이라이트
/// - RefreshIndicator
/// - 접근성 최적화
class JourneyInboxScreen extends ConsumerStatefulWidget {
  const JourneyInboxScreen({super.key, this.highlightJourneyId});

  final String? highlightJourneyId;

  @override
  ConsumerState<JourneyInboxScreen> createState() => _JourneyInboxScreenState();
}

class _JourneyInboxScreenState extends ConsumerState<JourneyInboxScreen> {
  bool _initLogged = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode && !_initLogged) {
      _initLogged = true;
      final session = ref.read(sessionManagerProvider);
      final hasSession = session.accessToken != null && session.accessToken!.isNotEmpty;
      debugPrint('[InboxTrace][UI] initState - highlightJourneyId: ${widget.highlightJourneyId}, hasSession: $hasSession');
    }
    Future.microtask(
      () => ref.read(journeyInboxControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(journeyInboxControllerProvider);
    final controller = ref.read(journeyInboxControllerProvider.notifier);

    if (kDebugMode) {
      debugPrint('[InboxTrace][UI] build - isLoading: ${state.isLoading}, items: ${state.items.length}, message: ${state.message}');
    }

    ref.listen<JourneyInboxState>(journeyInboxControllerProvider, (previous, next) {
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
          title: Text(l10n.inboxTitle),
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
            child: _buildBody(context, l10n, state),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, JourneyInboxState state) {
    if (kDebugMode) {
      final hasMessage = state.message != null;
      final isEmpty = state.items.isEmpty;
      final isLoading = state.isLoading;
      final emptyStateCondition = isEmpty && !isLoading;
      debugPrint('[InboxTrace][UI] _buildBody - hasMessage: $hasMessage, isEmpty: $isEmpty, isLoading: $isLoading, emptyStateCondition: $emptyStateCondition');
    }

    // 에러 상태
    if (state.message != null) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][UI] _buildBody - showing error state');
      }
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: l10n.inboxLoadFailed,
        actionLabel: l10n.inboxRefresh,
        onAction: () => ref.read(journeyInboxControllerProvider.notifier).load(),
      );
    }

    // 빈 상태
    if (state.items.isEmpty && !state.isLoading) {
      if (kDebugMode) {
        debugPrint('[InboxTrace][UI] _buildBody - showing empty state');
      }
      return EmptyStateWidget(
        icon: Icons.inbox_outlined,
        title: l10n.inboxEmpty,
      );
    }

    // 정상 상태 - 리스트 표시
    if (kDebugMode) {
      debugPrint('[InboxTrace][UI] _buildBody - showing list, itemCount: ${state.items.length}');
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(journeyInboxControllerProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        itemCount: state.items.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.spacing12),
        itemBuilder: (context, index) {
          final item = state.items[index];
          final isHighlighted = item.journeyId == widget.highlightJourneyId;
          return _InboxCard(
            item: item,
            isHighlighted: isHighlighted,
            onTap: () {
              context.go(
                '${AppRoutes.inbox}/${item.journeyId}',
                extra: item,
              );
            },
          );
        },
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
}

/// Inbox 아이템 카드
class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.item,
    required this.isHighlighted,
    required this.onTap,
  });

  final JourneyInboxItem item;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    // recipientStatus에 따른 스타일 결정
    final statusInfo = _getStatusInfo(item.recipientStatus);

    return Card(
      color: isHighlighted
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.surface,
      elevation: isHighlighted ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: isHighlighted
            ? const BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 행 (아이콘 + 상태 라벨 + 날짜)
              Row(
                children: [
                  // 상태 아이콘
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusInfo.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusInfo.icon,
                      size: 18,
                      color: statusInfo.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing8),

                  // 상태 라벨
                  Expanded(
                    child: Text(
                      _getStatusLabel(l10n, item.recipientStatus),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: statusInfo.color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                  // 날짜
                  Text(
                    dateFormat.format(item.createdAt.toLocal()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing12),

              // 메시지 내용 (PASSED 상태일 때는 고정 제목만 표시)
              if (item.recipientStatus == 'PASSED') ...[
                Text(
                  l10n.inboxPassedTitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ] else ...[
                Text(
                  item.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurface,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.spacing8),
                // 하단 정보 (이미지 카운트 + 화살표)
                Row(
                  children: [
                    // 이미지 카운트
                    if (item.imageCount > 0) ...[
                      Icon(
                        Icons.image_outlined,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.spacing4),
                      Text(
                        l10n.inboxImageCount(item.imageCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const Spacer(),
                    // 화살표 아이콘
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(AppLocalizations l10n, String status) {
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

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'ASSIGNED':
        return _StatusInfo(
          icon: Icons.notifications_active,
          color: AppColors.warning,
        );
      case 'RESPONDED':
        return _StatusInfo(
          icon: Icons.check_circle,
          color: AppColors.success,
        );
      case 'PASSED':
        return _StatusInfo(
          icon: Icons.forward,
          color: AppColors.onSurfaceVariant,
        );
      case 'REPORTED':
        return _StatusInfo(
          icon: Icons.flag,
          color: AppColors.error,
        );
      default:
        return _StatusInfo(
          icon: Icons.help_outline,
          color: AppColors.onSurfaceVariant,
        );
    }
  }
}

/// 상태 정보 (아이콘 + 색상)
class _StatusInfo {
  const _StatusInfo({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}
