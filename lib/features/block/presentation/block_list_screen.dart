import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/formatters/app_date_formatter.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/presentation/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../journey/application/journey_inbox_controller.dart';
import '../../journey/application/journey_list_controller.dart';
import '../application/block_list_controller.dart';

/// 차단 목록 화면
///
/// 특징:
/// - 차단한 사용자 목록 표시
/// - 차단 해제 기능 (확인 다이얼로그)
/// - EmptyStateWidget로 빈 상태 처리
/// - LoadingOverlay로 로딩 상태 처리
class BlockListScreen extends ConsumerStatefulWidget {
  const BlockListScreen({super.key});

  @override
  ConsumerState<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends ConsumerState<BlockListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(blockListControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(blockListControllerProvider);
    final controller = ref.read(blockListControllerProvider.notifier);

    ref.listen<BlockListState>(blockListControllerProvider, (previous, next) {
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
          title: Text(l10n.blockListTitle),
          leading: IconButton(
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          actions: const [],
        ),
        body: LoadingOverlay(
          isLoading: state.isLoading,
          child: SafeArea(child: _buildBody(context, l10n, state)),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    BlockListState state,
  ) {
    // 빈 상태
    if (state.items.isEmpty && !state.isLoading) {
      return EmptyStateWidget(
        icon: Icons.block,
        title: l10n.blockListEmpty,
        description: l10n.onboardingSafetyDescription,
      );
    }

    // 정상 상태 - 차단 목록

    return RefreshIndicator(
      onRefresh: () => ref.read(blockListControllerProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        itemCount: state.items.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.spacing12),
        itemBuilder: (context, index) {
          final item = state.items[index];
          return Card(
            color: AppColors.surface,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              child: Row(
                children: [
                  // 아바타
                  _Avatar(avatarUrl: item.avatarUrl),
                  const SizedBox(width: AppSpacing.spacing12),

                  // 사용자 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nickname.isNotEmpty
                              ? item.nickname
                              : l10n.blockListUnknownUser,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.spacing4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.spacing4),
                            Text(
                              AppDateFormatter.formatCardTimestamp(
                                item.createdAt,
                                l10n.localeName,
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 차단 해제 버튼
                  TextButton(
                    onPressed: () => _confirmUnblock(l10n, item.userId),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(l10n.blockListUnblock),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmUnblock(
    AppLocalizations l10n,
    String targetUserId,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.blockListUnblockTitle,
      message: l10n.blockListUnblockMessage,
      confirmLabel: l10n.blockListUnblockConfirm,
      cancelLabel: l10n.composeCancel,
    );
    if (confirmed != true) {
      return;
    }
    // ✅ traceId 생성 및 전파
    final traceId = DateTime.now().microsecondsSinceEpoch.toString();
    if (kDebugMode) {
      debugPrint('block:unblock tap traceId=$traceId target=$targetUserId');
    }
    await ref
        .read(blockListControllerProvider.notifier)
        .unblock(targetUserId, traceId: traceId);
  }

  Future<void> _handleMessage(
    AppLocalizations l10n,
    BlockListMessage message,
  ) async {
    switch (message) {
      case BlockListMessage.missingSession:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorSessionExpired,
          confirmLabel: l10n.composeOk,
        );
        return;
      case BlockListMessage.loadFailed:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.blockListLoadFailed,
          confirmLabel: l10n.composeOk,
        );
        return;
      case BlockListMessage.unblockFailed:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.blockListUnblockFailed,
          confirmLabel: l10n.composeOk,
        );
        return;
      case BlockListMessage.unblockSuccess:
        // ✅ 차단 해제 성공 알럿 표시
        await showAppAlertDialog(
          context: context,
          title: l10n.blockUnblockedTitle,
          message: l10n.blockUnblockedMessage,
          confirmLabel: l10n.commonOk,
          onConfirm: () {
            // ✅ 알럿 확인 후 provider invalidate로 숨김 메시지 복구
            // invalidate만으로도 provider가 자동으로 재생성되고, watch하는 화면이 자동으로 재조회됨
            if (!context.mounted) return;
            // 차단 목록 갱신
            ref.invalidate(blockListControllerProvider);
            // 메시지 리스트 갱신 (차단 필터가 변경되었으므로 재조회)
            ref.invalidate(journeyInboxControllerProvider);
            ref.invalidate(journeyListControllerProvider);
          },
        );
        // await 이후: 다이얼로그가 외부 탭으로 닫힌 경우에도 갱신
        if (!context.mounted) return;
        ref.invalidate(blockListControllerProvider);
        ref.invalidate(journeyInboxControllerProvider);
        ref.invalidate(journeyListControllerProvider);
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

/// 아바타 위젯
class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, color: AppColors.primary),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          avatarUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.primary),
            );
          },
        ),
      ),
    );
  }
}
