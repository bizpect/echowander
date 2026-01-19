import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/presentation/navigation/tab_navigation_helper.dart';
import '../../../../core/presentation/widgets/app_button.dart';
import '../../../../core/presentation/widgets/app_dialog.dart';
import '../../../../core/presentation/widgets/app_header.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/fullscreen_image_viewer.dart';
import '../../../../core/presentation/widgets/loading_overlay.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/sent_journey_detail_controller.dart';
import '../../domain/sent_journey_detail.dart';
import '../../domain/sent_journey_response.dart';
import '../widgets/chat_thread/chat_item.dart';
import '../widgets/chat_thread/chat_thread_view.dart';

class SentJourneyDetailScreen extends ConsumerStatefulWidget {
  const SentJourneyDetailScreen({
    super.key,
    required this.journeyId,
    this.fromNotification = false,
  });

  final String journeyId;
  final bool fromNotification;

  @override
  ConsumerState<SentJourneyDetailScreen> createState() =>
      _SentJourneyDetailScreenState();
}

class _SentJourneyDetailScreenState
    extends ConsumerState<SentJourneyDetailScreen> {
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
    await ref
        .read(sentJourneyDetailControllerProvider.notifier)
        .load(
          journeyId: widget.journeyId,
          accessToken: accessToken,
          reqId: _reqId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(sentJourneyDetailControllerProvider);
    if ((state.responsesMissing || state.responsesLoadFailed) &&
        !_didShowMissingAlert) {
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
      child: AppScaffold(
        appBar: AppHeader(
          title: l10n.journeyDetailTitle,
          leadingIcon: Icons.arrow_back,
          onLeadingTap: () => TabNavigationHelper.goToSentRoot(context, ref),
          leadingSemanticLabel: MaterialLocalizations.of(
            context,
          ).backButtonTooltip,
        ),
        body: LoadingOverlay(
          isLoading: state.isLoading,
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
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: AppSpacing.spacing16),
            Text(
              l10n.journeyDetailLoadFailed,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.onSurface),
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
    final isCompleted = detail.statusCode == 'COMPLETED';
    final isUnlocked = detail.isRewardUnlocked;

    // COMPLETED(=RESPONDED) 상태: 채팅 UI만 표시
    if (isCompleted) {
      return _buildResponsesSection(
        l10n,
        isCompleted: isCompleted,
        isUnlocked: isUnlocked,
        responses: responses,
        responsesLoadFailed: responsesLoadFailed,
      );
    }

    // 다른 상태(WAITING/CREATED 등): 기존 UI 유지
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(l10n, detail),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [_buildStatusBadge(l10n, detail.statusCode)]),
        SizedBox(height: AppSpacing.spacing12),
        Row(
          children: [
            Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant),
            SizedBox(width: AppSpacing.spacing4),
            Text(
              AppDateFormatter.formatCardTimestamp(
                detail.createdAt,
                l10n.localeName,
              ),
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
    final state = ref.watch(sentJourneyDetailControllerProvider);
    final imageUrls = state.imageUrls;

    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
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
            // 이미지 슬라이더 (진행 중 상태 + 이미지 URL이 있을 때만 표시)
            if (imageUrls.isNotEmpty) ...[
              SizedBox(height: AppSpacing.spacing16),
              _buildImageCarousel(imageUrls),
            ],
            // 이미지 개수 표시 (이미지가 있지만 URL 로딩 실패했을 때)
            if (detail.imageCount > 0 && imageUrls.isEmpty) ...[
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

  /// 이미지 캐러셀 (슬라이더)
  Widget _buildImageCarousel(List<String> imageUrls) {
    return _ImageCarousel(
      imageUrls: imageUrls,
      fromNotification: widget.fromNotification,
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
            border: Border.all(color: AppColors.primary, width: 1.5),
          )
        : null;
    return Container(
      padding: widget.fromNotification
          ? EdgeInsets.all(AppSpacing.spacing16)
          : EdgeInsets.zero,
      decoration: highlightDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 채팅 UI만 표시 (섹션 타이틀 제거)
          if (!canShowResponses)
            _buildLocked(l10n)
          else if (responsesLoadFailed || responses.isEmpty)
            const SizedBox.shrink()
          else
            _buildChatThreadView(l10n, responses),
        ],
      ),
    );
  }

  Widget _buildLocked(AppLocalizations l10n) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.warning),
            SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Text(
                l10n.journeyDetailResultsLocked,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 채팅 스레드 UI: 내 메시지(오른쪽) + 답글들(왼쪽)
  /// 날짜 그룹화 구분선 포함 (카카오톡 스타일)
  Widget _buildChatThreadView(
    AppLocalizations l10n,
    List<SentJourneyResponse> responses,
  ) {
    final state = ref.watch(sentJourneyDetailControllerProvider);
    final detail = state.detail;
    if (detail == null) {
      return const SizedBox.shrink();
    }

    // 공통 ChatItem 모델로 변환
    final chatItems = <ChatItem>[
      // 내 메시지 (보낸 원문)
      ChatItem(
        id: 'sent-${detail.journeyId}',
        speaker: ChatSpeaker.me,
        message: detail.displayContent,
        createdAt: detail.createdAt,
      ),
      // 답글들 (상대방)
      ...responses.map(
        (response) => ChatItem(
          id: 'response-${response.responseId}',
          speaker: ChatSpeaker.other,
          message: response.displayContent,
          createdAt: response.createdAt,
          displayName: response.responderNickname,
        ),
      ),
    ];

    return ChatThreadView(
      items: chatItems,
      locale: l10n.localeName,
      onImageTap: (item) => _handleImageTap(item),
    );
  }

  /// 이미지 탭 처리 (풀스크린 뷰어로 이동)
  void _handleImageTap(ChatItem item) {
    if (item.imageUrl == null || item.imageUrl!.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullscreenImageViewer(imageUrl: item.imageUrl!),
      ),
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
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
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

/// 이미지 캐러셀 위젯 (PageController 메모리 누수 방지를 위한 StatefulWidget)
class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({
    required this.imageUrls,
    this.fromNotification = false,
  });

  final List<String> imageUrls;
  final bool fromNotification;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (_pageController.hasClients && _pageController.page != null) {
      final newPage = _pageController.page!.round();
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              final imageUrl = widget.imageUrls[index];
              return GestureDetector(
                onTap: () {
                  if (!mounted) {
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => FullscreenImageViewer(
                        imageUrl: imageUrl,
                        initialIndex: index,
                        imageUrls: widget.imageUrls,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacing8),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.medium,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.primary,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        // 페이지 인디케이터 (이미지가 2개 이상일 때만 표시)
        if (widget.imageUrls.length > 1) ...[
          SizedBox(height: AppSpacing.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (index) => Container(
                width: 6,
                height: 6,
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
