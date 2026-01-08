import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/block/supabase_block_repository.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/session/session_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../application/journey_inbox_controller.dart';
import '../data/supabase_journey_repository.dart';
import '../domain/journey_repository.dart';

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
  List<String> _imageUrls = [];
  bool _loadFailed = false;
  bool _isActionLoading = false;
  late final TextEditingController _responseController;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController();
    _loadImages();
  }

  @override
  void dispose() {
    _responseController.dispose();
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
      final urls =
          await ref.read(journeyRepositoryProvider).fetchInboxJourneyImageUrls(
                journeyId: item.journeyId,
                accessToken: accessToken,
              );
      if (!mounted) {
        return;
      }
      setState(() {
        _imageUrls = urls;
        _isLoading = false;
        _loadFailed = urls.isEmpty && item.imageCount > 0;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

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
          title: Text(l10n.inboxDetailTitle),
          leading: IconButton(
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: LoadingOverlay(
          isLoading: _isLoading || _isActionLoading,
          child: SafeArea(
            child: widget.item == null
                ? Center(
                    child: Text(l10n.inboxDetailMissing),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          24 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateFormat.format(widget.item!.createdAt.toLocal()),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 12),
                              // PASSED 상태일 때는 내용 차단
                              if (widget.item!.recipientStatus == 'PASSED') ...[
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 48),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.forward,
                                          size: 64,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          l10n.inboxPassedTitle,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: AppColors.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          l10n.inboxPassedDetailUnavailable,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppColors.onSurfaceVariant,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  widget.item!.content,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${l10n.inboxImagesLabel} ${widget.item!.imageCount}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                if (_loadFailed)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      l10n.inboxImagesLoadFailed,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                if (_imageUrls.isNotEmpty)
                                  GridView.builder(
                                    padding: const EdgeInsets.only(top: 16),
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                    ),
                                    itemCount: _imageUrls.length,
                                    itemBuilder: (context, index) {
                                      final url = _imageUrls[index];
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Semantics(
                                          label: '${l10n.inboxImagesLabel} ${index + 1}',
                                          button: true,
                                          child: InkWell(
                                            onTap: () => _openViewer(index),
                                            child: Image.network(
                                              url,
                                              semanticLabel: '${l10n.inboxImagesLabel} ${index + 1}',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _responseController,
                                  maxLength: 500,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.newline,
                                  decoration: InputDecoration(
                                    labelText: l10n.inboxRespondLabel,
                                    hintText: l10n.inboxRespondHint,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _isActionLoading ? null : _handleRespond,
                                  child: Text(l10n.inboxRespondCta),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _isActionLoading ? null : _handlePass,
                                  child: Text(l10n.inboxPassCta),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _isActionLoading ? null : _handleReport,
                                  child: Text(l10n.inboxReportCta),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _isActionLoading ? null : _handleBlock,
                                  child: Text(l10n.inboxBlockCta),
                                ),
                              ],
                            ],
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

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _openViewer(int initialIndex) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _ImageViewerDialog(
          imageUrls: _imageUrls,
          initialIndex: initialIndex,
        );
      },
    );
  }

  Future<void> _handleRespond() async {
    if (kDebugMode) {
      debugPrint('[InboxReplyTrace][UI] _handleRespond - START');
    }
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    if (item == null) {
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - ABORT: item is null');
      }
      return;
    }
    if (kDebugMode) {
      debugPrint('[InboxReplyTrace][UI] _handleRespond - item.journeyId: ${item.journeyId}');
    }
    final text = _responseController.text.trim();
    if (kDebugMode) {
      debugPrint('[InboxReplyTrace][UI] _handleRespond - text length: ${text.length}');
    }
    if (text.isEmpty) {
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - ABORT: text is empty, showing validation dialog');
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.inboxRespondEmpty,
        confirmLabel: l10n.composeOk,
      );
      return;
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (kDebugMode) {
      debugPrint('[InboxReplyTrace][UI] _handleRespond - accessToken exists: ${accessToken != null && accessToken.isNotEmpty}');
      if (accessToken != null && accessToken.isNotEmpty) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - accessToken length: ${accessToken.length}');
        debugPrint('[InboxReplyTrace][UI] _handleRespond - accessToken starts with: ${accessToken.substring(0, min(20, accessToken.length))}...');
      }
    }
    if (accessToken == null || accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - ABORT: no accessToken');
      }
      return;
    }
    if (kDebugMode) {
      debugPrint('[InboxReplyTrace][UI] _handleRespond - setting isActionLoading = true');
    }
    setState(() {
      _isActionLoading = true;
    });
    try {
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - calling repository.respondJourney...');
      }
      await ref.read(journeyRepositoryProvider).respondJourney(
            journeyId: item.journeyId,
            content: text,
            accessToken: accessToken,
          );
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - repository.respondJourney completed successfully');
      }
      if (!mounted) {
        if (kDebugMode) {
          debugPrint('[InboxReplyTrace][UI] _handleRespond - widget not mounted, aborting UI update');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - clearing text field');
      }
      _responseController.clear();
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - showing success dialog');
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.inboxRespondSuccessTitle,
        message: l10n.inboxRespondSuccessBody,
        confirmLabel: l10n.composeOk,
      );
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - SUCCESS: dialog closed');
      }
    } on JourneyActionException catch (e) {
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - EXCEPTION: JourneyActionException ${e.error}');
      }
      if (!mounted) {
        if (kDebugMode) {
          debugPrint('[InboxReplyTrace][UI] _handleRespond - widget not mounted, skipping error dialog');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - showing error dialog');
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.composeErrorTitle,
        message: l10n.inboxActionFailed,
        confirmLabel: l10n.composeOk,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InboxReplyTrace][UI] _handleRespond - UNEXPECTED EXCEPTION: $e');
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
          debugPrint('[InboxReplyTrace][UI] _handleRespond - setting isActionLoading = false');
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
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }
    setState(() {
      _isActionLoading = true;
    });
    try {
      await ref.read(journeyRepositoryProvider).passJourney(
            journeyId: item.journeyId,
            accessToken: accessToken,
          );
      if (!mounted) {
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.inboxPassSuccessTitle,
        message: l10n.inboxPassSuccessBody,
        confirmLabel: l10n.composeOk,
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
        debugPrint('[InboxReportTrace][UI] 신고 시작: journeyId=${item.journeyId}, reason=$reason');
      }
      await ref.read(journeyRepositoryProvider).reportJourney(
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
      ref.read(journeyInboxControllerProvider.notifier).removeItem(item.journeyId);
      
      // 성공 다이얼로그 표시
      await showAppAlertDialog(
        context: context,
        title: l10n.inboxReportSuccessTitle,
        message: l10n.inboxReportSuccessBody,
        confirmLabel: l10n.composeOk,
      );
      
      // 상세 화면 닫기
      if (mounted && context.canPop()) {
        context.pop();
      }
    } on JourneyActionException catch (e) {
      if (kDebugMode) {
        debugPrint('[InboxReportTrace][UI] 신고 실패: JourneyActionException ${e.error}');
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
    setState(() {
      _isActionLoading = true;
    });
    try {
      await ref.read(blockRepositoryProvider).blockUser(
            targetUserId: item.senderUserId,
            accessToken: accessToken,
          );
      if (!mounted) {
        return;
      }
      await showAppAlertDialog(
        context: context,
        title: l10n.inboxBlockSuccessTitle,
        message: l10n.inboxBlockSuccessBody,
        confirmLabel: l10n.composeOk,
      );
    } catch (_) {
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
                  semanticLabel: widget.imageUrls.length > 1 ? "${index + 1} / ${widget.imageUrls.length}" : "",
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
