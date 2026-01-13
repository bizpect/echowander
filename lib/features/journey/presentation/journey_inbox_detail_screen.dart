import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/formatters/app_date_formatter.dart';
import '../../../core/logging/log_sanitizer.dart';
import '../../../core/media/journey_image_url_resolver.dart';
import '../../../core/presentation/navigation/tab_navigation_helper.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/session/session_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_inbox_controller.dart';
import '../data/supabase_journey_repository.dart';
import '../domain/journey_repository.dart';
import 'widgets/journey_images_section.dart';

class JourneyInboxDetailScreen extends ConsumerStatefulWidget {
  const JourneyInboxDetailScreen({super.key, required this.item});

  final JourneyInboxItem? item;

  @override
  ConsumerState<JourneyInboxDetailScreen> createState() =>
      _JourneyInboxDetailScreenState();
}

class _JourneyInboxDetailScreenState
    extends ConsumerState<JourneyInboxDetailScreen> {
  bool _isLoading = false;
  List<String> _imagePaths = []; // objectPath 리스트
  List<String?> _imageUrls = []; // signedUrl 리스트 (null 가능)
  bool _loadFailed = false;
  bool _isActionLoading = false;
  late final JourneyImageUrlResolver _imageResolver;
  final Set<String> _retriedImagePaths = {}; // 재시도된 경로 추적

  // 인라인 답장 입력 컨트롤러
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  // RESPONDED 상태일 때 내가 보낸 답글 정보
  MyLatestResponse? _myResponse;
  bool _isResponseLoading = false;
  bool _responseLoadFailed = false;

  static const String _journeyImagesBucketId = 'journey-images';

  @override
  void initState() {
    super.initState();
    _imageResolver = JourneyImageUrlResolver(
      repository: ref.read(journeyRepositoryProvider),
    );
    // PASSED 상태일 때는 이미지 로드하지 않음 (불필요한 네트워크 작업 방지)
    if (widget.item?.recipientStatus != 'PASSED') {
      _loadImages();
    }
    // RESPONDED 상태일 때는 내가 보낸 답글 로드
    if (widget.item?.recipientStatus == 'RESPONDED') {
      _loadMyResponse();
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    final item = widget.item;
    if (item == null || item.imageCount == 0) {
      return;
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      // RPC 호출 직전 로그
      if (kDebugMode) {
        debugPrint(
          '[InboxDetail][Images] RPC 호출 직전: journeyId=${item.journeyId} expectedCount=${item.imageCount}',
        );
      }

      // objectPath 리스트 조회
      final paths = await ref
          .read(journeyRepositoryProvider)
          .fetchInboxJourneyImagePaths(
            journeyId: item.journeyId,
            accessToken: accessToken,
          );
      if (!mounted) {
        return;
      }

      // RPC 응답 파싱 직후 로그
      if (kDebugMode) {
        final pathsPreview = paths.take(3).map((p) => LogSanitizer.previewPath(p)).join(',');
        debugPrint(
          '[InboxDetail][Images] RPC 응답 파싱 직후: pathsLen=${paths.length} pathsPreview=[$pathsPreview]',
        );

        // 카운트 불일치 경고
        if (item.imageCount > 0 && paths.isEmpty) {
          debugPrint(
            '[InboxDetail][Images][WARN] DB returned 0 paths but recipients has snapshot_image_count=${item.imageCount} -> parsing/column mismatch',
          );
        } else if (item.imageCount != paths.length) {
          debugPrint(
            '[InboxDetail][Images][WARN] imageCount=${item.imageCount} but fetchedPaths=${paths.length} -> path storage mismatch',
          );
        }
      }

      // 디버그: Storage 객체 존재 여부 확인 (kDebugMode에서만)
      if (kDebugMode && paths.isNotEmpty) {
        try {
          final storageCheck = await ref
              .read(journeyRepositoryProvider)
              .debugCheckStorageObjects(
                bucket: _journeyImagesBucketId,
                paths: paths,
                accessToken: accessToken,
              );
          for (final check in storageCheck) {
            final path = check['path'] as String? ?? 'N/A';
            final exists = check['exists'] as bool? ?? false;
            final foundName = check['found_name'] as String?;
            final bucketId = check['bucket_id'] as String? ?? 'N/A';
            debugPrint(
              '[InboxDetail][Images][DEBUG] Storage check: path=$path exists=$exists found_name=$foundName bucket_id=$bucketId',
            );
            if (exists && foundName == null) {
              debugPrint(
                '[InboxDetail][Images][WARN] exists=true but found_name is null -> RLS may be blocking',
              );
            }
          }
        } catch (e) {
          debugPrint(
            '[InboxDetail][Images][DEBUG] Storage check failed: $e',
          );
        }
      }

      if (paths.isEmpty) {
        setState(() {
          _imagePaths = [];
          _imageUrls = [];
          _isLoading = false;
          _loadFailed = item.imageCount > 0;
        });
        return;
      }

      // signedUrl 발급
      final signedUrls = await _imageResolver.getSignedUrls(
        bucketId: _journeyImagesBucketId,
        paths: paths,
        accessToken: accessToken,
        journeyId: item.journeyId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _imagePaths = paths;
        _imageUrls = signedUrls;
        _isLoading = false;
        _loadFailed = signedUrls.every((url) => url == null) && item.imageCount > 0;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  /// 이미지 로딩 실패 시 1회 재발급
  Future<void> _handleImageLoadFailed(int index) async {
    if (index < 0 || index >= _imagePaths.length) {
      return;
    }
    final path = _imagePaths[index];
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    final item = widget.item;
    final traceId = item != null
        ? 'imgtrace-${item.journeyId}-$index-${DateTime.now().microsecondsSinceEpoch}'
        : 'imgtrace-unknown-$index-${DateTime.now().microsecondsSinceEpoch}';

    // 재시도 여부 확인
    final retried = _retriedImagePaths.contains(path);

    if (kDebugMode) {
      debugPrint(
        '[JourneyInboxDetail] [3] 이미지 로딩 실패: traceId=$traceId, index=$index, path=${LogSanitizer.previewPath(path)}, retried=$retried',
      );
    }

    // 1회 재발급
    _retriedImagePaths.add(path); // 재시도 마킹
    final refreshedUrl = await _imageResolver.refreshSignedUrl(
      bucketId: _journeyImagesBucketId,
      path: path,
      accessToken: accessToken,
      traceId: traceId,
    );

    if (!mounted) {
      return;
    }

    if (refreshedUrl != null) {
      // 재발급 성공 → URL 업데이트
      final updatedUrls = List<String?>.from(_imageUrls);
      updatedUrls[index] = refreshedUrl;
      setState(() {
        _imageUrls = updatedUrls;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppHeader(
          title: l10n.inboxDetailTitle,
          leadingIcon: Icons.arrow_back,
          onLeadingTap: () => _handleBack(context),
          leadingSemanticLabel: MaterialLocalizations.of(
            context,
          ).backButtonTooltip,
          trailingWidget: widget.item?.recipientStatus != 'PASSED' &&
                  widget.item?.recipientStatus != 'RESPONDED'
              ? IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showMoreBottomSheet(context),
                  tooltip: l10n.inboxDetailMoreTitle,
                )
              : null,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        resizeToAvoidBottomInset: true, // 키보드가 올라올 때 입력칸 보이도록
        body: SafeArea(
          child: LoadingOverlay(
            isLoading: _isLoading || _isActionLoading || _isResponseLoading,
            child: widget.item == null
                ? Center(child: Text(l10n.inboxDetailMissing))
                // PASSED 상태일 때는 화면 정중앙에 안내 UI만 표시
                : widget.item!.recipientStatus == 'PASSED'
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPaddingHorizontal,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_off_outlined,
                                size: 80,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                l10n.inboxPassedDetailUnavailable,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    // PASSED가 아닌 경우 기존 상세 화면 표시
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPaddingHorizontal,
                          AppSpacing.screenPaddingTop,
                          AppSpacing.screenPaddingHorizontal,
                          AppSpacing.screenPaddingBottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 날짜 (우측 정렬)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                AppDateFormatter.formatDetailTimestamp(
                                  widget.item!.createdAt,
                                  l10n.localeName,
                                ),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // 연한 구분선
                            Divider(
                              height: AppSpacing.lg,
                              thickness: 1,
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                            // 메시지 내용
                            Text(
                              widget.item!.content,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            // 사진 영역 (메시지 내용 아래)
                            if (_loadFailed)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.md),
                                child: Text(
                                  l10n.inboxImagesLoadFailed,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            JourneyImagesSection(
                              imageUrls: _imageUrls.whereType<String>().toList(),
                              onImageLoadFailed: _handleImageLoadFailed,
                              onImageTap: _openViewer,
                              traceIdPrefix: widget.item != null
                                  ? 'imgtrace-${widget.item!.journeyId}'
                                  : null,
                              journeyId: widget.item?.journeyId,
                            ),
                            // RESPONDED 상태일 때는 답글 표시, 아닐 때는 입력 UI
                            if (widget.item!.recipientStatus == 'RESPONDED')
                              _buildMyResponseSection(context)
                            else ...[
                              const SizedBox(height: AppSpacing.lg),
                              _buildInlineReplySection(context),
                            ],
                          ],
                    ),
                  ),
          ),
        ),
        bottomNavigationBar: widget.item?.recipientStatus != 'PASSED' &&
                widget.item?.recipientStatus != 'RESPONDED'
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenPaddingHorizontal,
                    AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Pass 버튼 (5:5 비율 중 왼쪽)
                      Expanded(
                        flex: 5,
                        child: OutlinedButton(
                          onPressed: _isActionLoading ? null : _handlePass,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, AppSpacing.minTouchTarget),
                          ),
                          child: Text(l10n.inboxPassCta),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // 보내기 버튼 (5:5 비율 중 오른쪽)
                      Expanded(
                        flex: 5,
                        child: FilledButton.icon(
                          onPressed: _isActionLoading ? null : _handleInlineReplySubmit,
                          icon: const Icon(Icons.send),
                          label: Text(l10n.inboxRespondCta),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, AppSpacing.minTouchTarget),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  /// 내가 보낸 답글 로드
  Future<void> _loadMyResponse() async {
    final item = widget.item;
    if (item == null) {
      return;
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }
    setState(() {
      _isResponseLoading = true;
      _responseLoadFailed = false;
    });
    try {
      final response = await ref
          .read(journeyRepositoryProvider)
          .fetchMyLatestResponse(
            journeyId: item.journeyId,
            accessToken: accessToken,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _myResponse = response;
        _isResponseLoading = false;
        _responseLoadFailed = response == null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isResponseLoading = false;
        _responseLoadFailed = true;
      });
    }
  }

  /// 내가 보낸 답글 표시 UI
  Widget _buildMyResponseSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_isResponseLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_responseLoadFailed || _myResponse == null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.inboxRespondedDetailReplyUnavailable,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final response = _myResponse!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.send_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.inboxRespondedDetailSectionTitle,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              response.displayContent,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppDateFormatter.formatDetailTimestamp(
                  response.createdAt,
                  l10n.localeName,
                ),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 인라인 메시지 입력 UI 구현 (자동 확장 입력칸만)
  Widget _buildInlineReplySection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        // 자동 확장 입력 필드
        TextField(
          controller: _replyController,
          focusNode: _replyFocusNode,
          maxLength: 500,
          maxLines: null, // 자동 확장
          minLines: 3,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: l10n.inboxRespondHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
          ),
          style: textTheme.bodyLarge,
          enabled: !_isActionLoading,
        ),
      ],
    );
  }

  void _handleBack(BuildContext context) {
    // 받은 메시지 탭 루트로 복귀
    TabNavigationHelper.goToInboxRoot(context, ref);
  }

  void _openViewer(int initialIndex) {
    if (!mounted) {
      return;
    }
    final validUrls = _imageUrls.whereType<String>().toList();
    if (validUrls.isEmpty) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _ImageViewerDialog(
          imageUrls: validUrls,
          initialIndex: initialIndex.clamp(0, validUrls.length - 1),
        );
      },
    );
  }

  void _showMoreBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        // bottom safe area 명시적 추가 (갤럭시 제스처/물리키 영역 방지)
        final bottomPadding = MediaQuery.of(sheetContext).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl + bottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘+텍스트 가운데 정렬 (2개 액션을 가로로 배치)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 신고 액션
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        if (mounted) {
                          _handleReport();
                        }
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.report_outlined,
                              size: 32,
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.actionReportMessage,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 차단 액션
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        if (mounted) {
                          _handleBlock();
                        }
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.block_outlined,
                              size: 32,
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.actionBlockSender,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 인라인 답장 전송 (빈 메시지 알럿 + 컨펌)
  Future<void> _handleInlineReplySubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _replyController.text.trim();

    // 1) 빈 메시지 체크
    if (text.isEmpty) {
      await showAppAlertDialog(
        context: context,
        title: l10n.errorTitle,
        message: l10n.inboxRespondEmpty,
        confirmLabel: l10n.commonOk,
      );
      // 알럿 닫힌 후 포커스 복귀
      if (mounted) {
        _replyFocusNode.requestFocus();
      }
      return;
    }

    // 2) 전송 컨펌
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.inboxRespondConfirmTitle,
      message: l10n.inboxRespondConfirmMessage,
      confirmLabel: l10n.commonOk,
      cancelLabel: l10n.composeCancel,
    );

    if (confirmed != true) {
      return;
    }

    // 3) 전송 로직 실행
    await _handleRespond(text);
  }

  Future<void> _handleRespond(String text) async {
    if (kDebugMode) {
      debugPrint('[InboxReplyTrace][UI] _handleRespond - START');
    }
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    if (item == null) {
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - ABORT: item is null',
        );
      }
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[InboxReplyTrace][UI] _handleRespond - item.journeyId: ${item.journeyId}',
      );
    }
    final trimmedText = text.trim();
    if (kDebugMode) {
      debugPrint(
        '[InboxReplyTrace][UI] _handleRespond - text length: ${trimmedText.length}',
      );
    }
    if (trimmedText.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - ABORT: text is empty',
        );
      }
      return;
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (kDebugMode) {
      debugPrint(
        '[InboxReplyTrace][UI] _handleRespond - accessToken exists: ${accessToken != null && accessToken.isNotEmpty}',
      );
      if (accessToken != null && accessToken.isNotEmpty) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - accessToken length: ${accessToken.length}',
        );
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - accessToken starts with: ${accessToken.substring(0, min(20, accessToken.length))}...',
        );
      }
    }
    if (accessToken == null || accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - ABORT: no accessToken',
        );
      }
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[InboxReplyTrace][UI] _handleRespond - setting isActionLoading = true',
      );
    }
    setState(() {
      _isActionLoading = true;
    });
    try {
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - calling repository.respondJourney...',
        );
      }
      await ref
          .read(journeyRepositoryProvider)
          .respondJourney(
            journeyId: item.journeyId,
            content: trimmedText,
            accessToken: accessToken,
          );
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - repository.respondJourney completed successfully',
        );
      }
      if (!mounted) {
        if (kDebugMode) {
          debugPrint(
            '[InboxReplyTrace][UI] _handleRespond - widget not mounted, aborting UI update',
          );
        }
        return;
      }
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - showing success dialog',
        );
      }

      await showAppAlertDialog(
        context: context,
        title: l10n.inboxRespondSuccessTitle,
        message: l10n.inboxRespondSuccessBody,
        confirmLabel: l10n.composeOk,
        onConfirm: () {
          // 알럿이 닫힌 후 실행됨
          // 받은메세지 탭 루트로 복귀 (TabNavigationHelper에서 이미 limit: 20으로 로드함)
          if (mounted) {
            TabNavigationHelper.goToInboxRoot(context, ref);
          }
        },
      );
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - SUCCESS: dialog closed',
        );
      }
    } on JourneyActionException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - EXCEPTION: JourneyActionException ${e.error}',
        );
      }
      if (!mounted) {
        if (kDebugMode) {
          debugPrint(
            '[InboxReplyTrace][UI] _handleRespond - widget not mounted, skipping error dialog',
          );
        }
        return;
      }
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - showing error dialog',
        );
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.inboxActionFailed,
        confirmLabel: l10n.composeOk,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[InboxReplyTrace][UI] _handleRespond - UNEXPECTED EXCEPTION: $e',
        );
      }
      if (mounted) {
        await showAppAlertDialog(
          context: context,
          title: l10n.composeErrorTitle,
          message: l10n.inboxActionFailed,
          confirmLabel: l10n.composeOk,
        );
      }
    } finally {
      if (mounted) {
        if (kDebugMode) {
          debugPrint(
            '[InboxReplyTrace][UI] _handleRespond - setting isActionLoading = false',
          );
        }
        setState(() {
          _isActionLoading = false;
        });
      }
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - END');
      }
    }
  }

  Future<void> _handlePass() async {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    if (item == null) {
      return;
    }

    // 확인 다이얼로그 표시
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.inboxPassConfirmTitle,
      message: l10n.inboxPassConfirmMessage,
      confirmLabel: l10n.inboxPassConfirmAction,
      cancelLabel: l10n.composeCancel,
    );

    if (confirmed != true) {
      return;
    }

    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }
    setState(() {
      _isActionLoading = true;
    });
    try {
      await ref
          .read(journeyRepositoryProvider)
          .passJourney(journeyId: item.journeyId, accessToken: accessToken);
      if (!mounted) {
        return;
      }

      // 성공 알럿 표시 후 리스트로 이동
      await showAppAlertDialog(
        context: context,
        title: l10n.inboxPassSuccessTitle,
        message: l10n.inboxPassSuccessBody,
        confirmLabel: l10n.composeOk,
        onConfirm: () {
          // 알럿이 닫힌 후 실행됨
          // 받은메세지 탭 루트로 복귀
          if (mounted) {
            TabNavigationHelper.goToInboxRoot(context, ref);
          }
        },
      );
    } on JourneyActionException {
      if (!mounted) {
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.inboxActionFailed,
        confirmLabel: l10n.composeOk,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _handleReport() async {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    if (item == null) {
      return;
    }
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.inboxReportTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('SPAM'),
            child: Text(l10n.inboxReportSpam),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('ABUSE'),
            child: Text(l10n.inboxReportAbuse),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('OTHER'),
            child: Text(l10n.inboxReportOther),
          ),
        ],
      ),
    );
    if (reason == null) {
      return;
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }
    setState(() {
      _isActionLoading = true;
    });
    try {
      if (kDebugMode) {
        debugPrint(
          '[InboxReportTrace][UI] 신고 시작: journeyId=${item.journeyId}, reason=$reason',
        );
      }
      await ref
          .read(journeyRepositoryProvider)
          .reportJourney(
            journeyId: item.journeyId,
            reasonCode: reason,
            accessToken: accessToken,
          );
      if (kDebugMode) {
        debugPrint('[InboxReportTrace][UI] 신고 성공: journeyId=${item.journeyId}');
      }
      if (!mounted) {
        return;
      }

      // 신고 성공 시: 리스트에서 제거 (optimistic update)
      final controllerNotifier = ref.read(
        journeyInboxControllerProvider.notifier,
      );
      controllerNotifier.removeItem(item.journeyId);

      // 성공 다이얼로그 표시 (확인 클릭 시 인박스로 이동)
      await showAppAlertDialog(
        context: context,
        title: l10n.inboxReportSuccessTitle,
        message: l10n.inboxReportSuccessBody,
        confirmLabel: l10n.composeOk,
        onConfirm: () {
          // 알럿이 닫힌 후 실행됨
          // 받은메세지 탭 루트로 복귀 (TabNavigationHelper에서 이미 limit: 20으로 로드함)
          TabNavigationHelper.goToInboxRoot(context, ref);
        },
      );
    } on JourneyActionException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[InboxReportTrace][UI] 신고 실패: JourneyActionException ${e.error}',
        );
      }
      if (!mounted) {
        return;
      }
      // 중복 신고 에러 처리
      if (e.error == JourneyActionError.alreadyReported) {
        await showAppAlertDialog(
          context: context,
          title: l10n.inboxReportAlreadyReportedTitle,
          message: l10n.inboxReportAlreadyReportedBody,
          confirmLabel: l10n.composeOk,
        );
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.inboxActionFailed,
        confirmLabel: l10n.composeOk,
      );
    } catch (e, stackTrace) {
      // 예상치 못한 예외 로깅
      if (kDebugMode) {
        debugPrint('[InboxReportTrace][UI] 신고 예상치 못한 예외: $e');
        debugPrint('[InboxReportTrace][UI] 스택 트레이스: $stackTrace');
      }
      if (!mounted) {
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.inboxActionFailed,
        confirmLabel: l10n.composeOk,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _handleBlock() async {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    if (item == null || item.senderUserId.isEmpty) {
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.inboxBlockMissing,
        confirmLabel: l10n.composeOk,
      );
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.inboxBlockTitle,
      message: l10n.inboxBlockMessage,
      confirmLabel: l10n.inboxBlockConfirm,
      cancelLabel: l10n.composeCancel,
    );
    if (confirmed != true) {
      return;
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    // Flutter 로그 1: UI 클릭 (reqId 포함)
    final reqId = DateTime.now().microsecondsSinceEpoch.toString();
    if (kDebugMode) {
      debugPrint(
        '[InboxBlockTrace][UI] block_click reqId=$reqId recipientId=${item.recipientId} journeyId=${item.journeyId} sender=${item.senderUserId}',
      );
    }

    setState(() {
      _isActionLoading = true;
    });
    try {
      // 차단 + 숨김 + 랜덤 재전송 RPC 호출
      // 주의: recipientId는 journey_recipients.id (PK)입니다
      await ref
          .read(journeyRepositoryProvider)
          .blockSenderAndPass(
            recipientId: item.recipientId,
            reasonCode: null, // 차단 사유는 선택사항
            accessToken: accessToken,
            reqId: reqId, // 로그 연계용
          );
      if (!mounted) {
        return;
      }

      // 차단 성공 시: 리스트에서 제거 (optimistic update)
      final controllerNotifier = ref.read(
        journeyInboxControllerProvider.notifier,
      );
      controllerNotifier.removeItem(item.journeyId);

      // 성공 다이얼로그 표시 (확인 클릭 시 인박스로 이동)
      await showAppAlertDialog(
        context: context,
        title: l10n.inboxBlockSuccessTitle,
        message: l10n.inboxBlockSuccessBody,
        confirmLabel: l10n.composeOk,
        onConfirm: () {
          // 알럿이 닫힌 후 실행됨
          // 받은메세지 탭 루트로 복귀 (TabNavigationHelper에서 이미 limit: 20으로 로드함)
          TabNavigationHelper.goToInboxRoot(context, ref);
        },
      );
    } on JourneyActionException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[InboxBlockTrace][UI] 차단 실패: JourneyActionException ${e.error}',
        );
      }
      if (!mounted) {
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.inboxBlockFailed,
        confirmLabel: l10n.composeOk,
      );
    } catch (e, stackTrace) {
      // 예상치 못한 예외 로깅
      if (kDebugMode) {
        debugPrint('[InboxBlockTrace][UI] 차단 예상치 못한 예외: $e');
        debugPrint('[InboxBlockTrace][UI] 스택 트레이스: $stackTrace');
      }
      if (!mounted) {
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.inboxBlockFailed,
        confirmLabel: l10n.composeOk,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }
}

class _ImageViewerDialog extends StatefulWidget {
  const _ImageViewerDialog({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: theme.colorScheme.surface,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Image.network(
                  widget.imageUrls[index],
                  semanticLabel: widget.imageUrls.length > 1
                      ? "${index + 1} / ${widget.imageUrls.length}"
                      : "",
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
