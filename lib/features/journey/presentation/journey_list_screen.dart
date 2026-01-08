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

    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.journeyListTitle),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: LoadingOverlay(
          isLoading: state.isLoading,
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                // Pull-to-Refresh: 보낸메세지 리스트 갱신
                await controller.load();
              },
              child: state.items.isEmpty
                  ? ListView(
                      padding: EdgeInsets.all(AppSpacing.spacing24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Center(
                          child: Text(
                            l10n.journeyListEmpty,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      final isCompleted = item.statusCode == 'COMPLETED';

                      return Card(
                        color: AppColors.surface,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                        child: InkWell(
                          onTap: isCompleted
                              ? () {
                                  context.go(
                                    '${AppRoutes.journeyList}/${item.journeyId}',
                                    extra: item,
                                  );
                                }
                              : null,
                          borderRadius: AppRadius.medium,
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.spacing20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 상태 배지
                                _buildStatusBadge(
                                  l10n: l10n,
                                  statusCode: item.statusCode,
                                  filterCode: item.filterCode,
                                ),
                                SizedBox(height: AppSpacing.spacing12),

                                // 메시지 내용
                                Text(
                                  item.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w500,
                                        height: 1.5,
                                      ),
                                ),
                                SizedBox(height: AppSpacing.spacing12),

                                // 날짜 + 이미지 수
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
                                    if (item.imageCount > 0) ...[
                                      SizedBox(width: AppSpacing.spacing8),
                                      Text('•', style: TextStyle(color: AppColors.onSurfaceVariant)),
                                      SizedBox(width: AppSpacing.spacing8),
                                      Icon(
                                        Icons.image,
                                        size: 14,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      SizedBox(width: AppSpacing.spacing4),
                                      Text(
                                        '${item.imageCount}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),

                                // 진행중 안내 (미완료일 때만)
                                if (!isCompleted) ...[
                                  SizedBox(height: AppSpacing.spacing12),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.spacing12,
                                      vertical: AppSpacing.spacing8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.warning.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: AppColors.warning,
                                        ),
                                        SizedBox(width: AppSpacing.spacing8),
                                        Expanded(
                                          child: Text(
                                            l10n.journeyInProgressHint,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppColors.onSurface,
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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

  Widget _buildStatusBadge({
    required AppLocalizations l10n,
    required String statusCode,
    required String filterCode,
  }) {
    final isCompleted = statusCode == 'COMPLETED';
    final statusLabel = _statusLabel(l10n, statusCode);
    final statusColor = isCompleted ? AppColors.success : AppColors.warning;
    final statusIcon = isCompleted ? Icons.check_circle : Icons.schedule;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing12,
            vertical: AppSpacing.spacing4,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                size: 14,
                color: statusColor,
              ),
              SizedBox(width: AppSpacing.spacing4),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (filterCode != 'OK') ...[
          SizedBox(width: AppSpacing.spacing8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing8,
              vertical: AppSpacing.spacing4,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _filterLabel(l10n, filterCode),
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _statusLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'CREATED':
      case 'WAITING':
        return l10n.journeyStatusInProgress;
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
