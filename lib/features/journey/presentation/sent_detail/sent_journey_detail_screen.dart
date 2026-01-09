import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/presentation/navigation/tab_navigation_helper.dart';
import '../../../../core/presentation/widgets/app_button.dart';
import '../../../../core/presentation/widgets/app_dialog.dart';
import '../../../../core/presentation/widgets/loading_overlay.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/sent_journey_detail_controller.dart';
import '../../domain/sent_journey_detail.dart';
import '../../domain/sent_journey_response.dart';

class SentJourneyDetailScreen extends ConsumerStatefulWidget {
  const SentJourneyDetailScreen({
    super.key,
    required this.journeyId,
    this.fromNotification = false,
  });

  final String journeyId;
  final bool fromNotification;

  @override
  ConsumerState<SentJourneyDetailScreen> createState() => _SentJourneyDetailScreenState();
}

class _SentJourneyDetailScreenState extends ConsumerState<SentJourneyDetailScreen> {
  late final String _reqId;
  bool _didShowMissingAlert = false;

  @override
  void initState() {
    super.initState();
    _reqId = DateTime.now().microsecondsSinceEpoch.toString();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      await showAppAlertDialog(
        context: context,
        title: l10n.errorTitle,
        message: l10n.errorSessionExpired,
        confirmLabel: l10n.composeOk,
      );
      return;
    }
    await ref.read(sentJourneyDetailControllerProvider.notifier).load(
          journeyId: widget.journeyId,
          accessToken: accessToken,
          reqId: _reqId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(sentJourneyDetailControllerProvider);
    if ((state.responsesMissing || state.responsesLoadFailed) && !_didShowMissingAlert) {
      _didShowMissingAlert = true;
      Future.microtask(() => _showMissingResponsesAlert(l10n));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        TabNavigationHelper.goToSentRoot(context, ref);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.journeyDetailTitle),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => TabNavigationHelper.goToSentRoot(context, ref),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          actions: const [],
        ),
        body: LoadingOverlay(
          isLoading: state.isLoading || state.isRefreshing,
          child: SafeArea(
            child: state.loadFailed
                ? _buildError(l10n)
                : state.detail == null
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: _buildContent(
                          l10n,
                          state.detail!,
                          state.responses,
                          state.responsesLoadFailed,
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: AppSpacing.spacing16),
            Text(
              l10n.journeyDetailLoadFailed,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacing24),
            AppFilledButton(
              onPressed: _load,
              child: Text(l10n.journeyDetailRetry),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMissingResponsesAlert(AppLocalizations l10n) async {
    if (!mounted) {
      return;
    }
    await showAppAlertDialog(
      context: context,
      title: l10n.commonTemporaryErrorTitle,
      message: l10n.sentDetailRepliesLoadFailedMessage,
      confirmLabel: l10n.commonOk,
      onConfirm: () => TabNavigationHelper.goToSentRoot(context, ref),
    );
  }

  Widget _buildContent(
    AppLocalizations l10n,
    SentJourneyDetail detail,
    List<SentJourneyResponse> responses,
    bool responsesLoadFailed,
  ) {
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();
    final isCompleted = detail.statusCode == 'COMPLETED';
    final isUnlocked = detail.isRewardUnlocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(l10n, detail, dateFormat),
        SizedBox(height: AppSpacing.spacing20),
        _buildContentCard(detail),
        SizedBox(height: AppSpacing.spacing20),
        _buildResponsesSection(
          l10n,
          isCompleted: isCompleted,
          isUnlocked: isUnlocked,
          responses: responses,
          responsesLoadFailed: responsesLoadFailed,
        ),
      ],
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    SentJourneyDetail detail,
    DateFormat dateFormat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatusBadge(l10n, detail.statusCode),
          ],
        ),
        SizedBox(height: AppSpacing.spacing12),
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 14,
              color: AppColors.onSurfaceVariant,
            ),
            SizedBox(width: AppSpacing.spacing4),
            Text(
              dateFormat.format(detail.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentCard(SentJourneyDetail detail) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.content,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
            ),
            if (detail.imageCount > 0) ...[
              SizedBox(height: AppSpacing.spacing12),
              Row(
                children: [
                  Icon(
                    Icons.image,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  SizedBox(width: AppSpacing.spacing4),
                  Text(
                    '${detail.imageCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesSection(
    AppLocalizations l10n, {
    required bool isCompleted,
    required bool isUnlocked,
    required List<SentJourneyResponse> responses,
    required bool responsesLoadFailed,
  }) {
    final canShowResponses = isCompleted && isUnlocked;
    final highlightDecoration = widget.fromNotification
        ? BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: AppColors.primary,
              width: 1.5,
            ),
          )
        : null;
    return Container(
      padding: widget.fromNotification ? EdgeInsets.all(AppSpacing.spacing16) : EdgeInsets.zero,
      decoration: highlightDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSpacing.spacing8),
              Text(
                l10n.journeyDetailResultsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacing16),
          if (!canShowResponses)
            _buildLocked(l10n)
          else if (responsesLoadFailed || responses.isEmpty)
            const SizedBox.shrink()
          else
            _buildResponsesList(l10n, responses),
        ],
      ),
    );
  }

  Widget _buildLocked(AppLocalizations l10n) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.warning),
            SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Text(
                l10n.journeyDetailResultsLocked,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesList(
    AppLocalizations l10n,
    List<SentJourneyResponse> responses,
  ) {
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: responses.length,
      separatorBuilder: (_, index) => SizedBox(height: AppSpacing.spacing12),
      itemBuilder: (context, index) {
        final response = responses[index];
        return Card(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      response.responderNickname,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      dateFormat.format(response.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacing12),
                Text(
                  response.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurface,
                        height: 1.6,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(AppLocalizations l10n, String statusCode) {
    final isCompleted = statusCode == 'COMPLETED';
    final statusLabel = _statusLabel(l10n, statusCode);
    final statusColor = isCompleted ? AppColors.success : AppColors.warning;
    final statusIcon = isCompleted ? Icons.check_circle : Icons.schedule;
    return Container(
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
          Icon(statusIcon, size: 14, color: statusColor),
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
}
