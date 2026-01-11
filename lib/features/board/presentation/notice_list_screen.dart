import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/common_codes/common_code_constants.dart';
import '../../../core/common_codes/common_codes_provider.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
import '../../../core/presentation/widgets/empty_state.dart';
import '../../../core/presentation/widgets/error_state.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/presentation/slivers/fixed_extent_header_delegate.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../application/board_filter_provider.dart';
import '../application/board_posts_provider.dart';
import '../domain/board_constants.dart';
import '../domain/board_post.dart';
import 'widgets/notice_filter_bar.dart';
import 'widgets/notice_list_item.dart';
import 'widgets/notice_type_bottom_sheet.dart';

/// 공지사항 필터 바의 고정 높이 (터치 영역 고려)
const double kNoticeFilterHeaderExtent = 64.0;

class NoticeListScreen extends ConsumerWidget {
  const NoticeListScreen({super.key, this.boardKey = BoardKeys.notice});

  final String boardKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final selectedType = ref.watch(selectedNoticeTypeProvider);
    final typeCodesAsync =
        ref.watch(commonCodesProvider(CommonCodeType.noticeType));
    final typeCodes = typeCodesAsync.value ?? const [];
    final typeLabelMap = {
      for (final code in typeCodes) code.codeValue: code.resolveLabel(locale),
    };
    final selectedLabel = selectedType == null
        ? l10n.noticeFilterAll
        : (typeLabelMap[selectedType] ?? l10n.noticeTypeUnknown);

    final query = BoardPostQuery(
      boardKey: boardKey,
      typeCode: selectedType,
    );
    final postsAsync = ref.watch(boardPostsProvider(query));
    final posts = postsAsync.value ?? const <BoardPostSummary>[];
    final isLoading = postsAsync.isLoading;
    final hasError = postsAsync.hasError;

    if (kDebugMode) {
      debugPrint(
        '[NoticeList] boardKey=$boardKey type=$selectedType posts=${posts.length} headerExtent=$kNoticeFilterHeaderExtent',
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack(context);
      },
      child: AppScaffold(
        appBar: AppHeader(
          title: l10n.noticeTitle,
          leadingIcon: Icons.arrow_back,
          onLeadingTap: () => _handleBack(context),
          leadingSemanticLabel: MaterialLocalizations.of(
            context,
          ).backButtonTooltip,
        ),
        bodyPadding: EdgeInsets.zero,
        body: LoadingOverlay(
          isLoading: isLoading,
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(boardPostsProvider(query).future),
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: FixedExtentPersistentHeaderDelegate(
                    extent: kNoticeFilterHeaderExtent,
                    child: SizedBox(
                      height: kNoticeFilterHeaderExtent,
                      child: NoticeFilterBar(
                        label: l10n.noticeFilterLabel,
                        selectedLabel: selectedLabel,
                        onTap: () async {
                          final selected = await NoticeTypeBottomSheet.show(
                            context: context,
                            title: l10n.noticeFilterSheetTitle,
                            allLabel: l10n.noticeFilterAll,
                            selectedCode: selectedType ??
                                NoticeTypeBottomSheet.allCode,
                            types: typeCodes,
                            locale: locale,
                          );
                          if (selected == null) {
                            return;
                          }
                          final resolved = selected ==
                                  NoticeTypeBottomSheet.allCode
                              ? null
                              : selected;
                          ref
                              .read(selectedNoticeTypeProvider.notifier)
                              .select(resolved);
                        },
                      ),
                    ),
                  ),
                ),
                if (hasError && posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorStateWidget(
                      icon: Icons.wifi_off,
                      title: l10n.noticeErrorTitle,
                      description: l10n.noticeErrorDescription,
                      actionLabel: l10n.errorRetry,
                      onRetry: () => ref.refresh(
                        boardPostsProvider(query),
                      ),
                    ),
                  )
                else if (posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.campaign_outlined,
                      title: l10n.noticeEmptyTitle,
                      description: l10n.noticeEmptyDescription,
                      actionLabel: selectedType == null
                          ? null
                          : l10n.noticeFilterAll,
                      onAction: selectedType == null
                          ? null
                          : () {
                              ref
                                  .read(selectedNoticeTypeProvider.notifier)
                                  .select(null);
                            },
                    ),
                  )
                else
                  SliverPadding(
                    padding: AppSpacing.pagePadding.copyWith(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.xl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          final typeLabel = post.typeCode == null
                              ? l10n.noticeTypeUnknown
                              : (typeLabelMap[post.typeCode] ??
                                  post.typeCode ??
                                  l10n.noticeTypeUnknown);
                          final publishedLabel =
                              AnnouncementDateFormatter.formatLocalDateTime(
                            post.publishedAt,
                            locale,
                            pattern: DateFormat.yMMMd(locale),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: NoticeListItem(
                              typeLabel: typeLabel,
                              dateLabel: publishedLabel,
                              title: post.title,
                              preview: post.contentPreview,
                              isPinned: post.isPinned,
                              pinnedLabel: l10n.noticePinnedBadge,
                              onTap: () => context.push(
                                AppRoutes.noticeDetailPath(post.id),
                              ),
                            ),
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
      context.go(AppRoutes.home);
  }
}
