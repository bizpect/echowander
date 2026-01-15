import 'package:flutter/material.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/formatters/app_date_formatter.dart';
import '../../../../../l10n/app_localizations.dart';
import 'chat_item.dart';

/// 채팅 말풍선 위젯 (카카오톡/토스 스타일)
///
/// - 내 말풍선: 오른쪽 정렬, primaryContainer
/// - 상대 말풍선: 왼쪽 정렬, surfaceContainerHighest, Avatar + 닉네임 표시
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.item,
    required this.locale,
  });

  /// 채팅 아이템
  final ChatItem item;

  /// 로케일 (날짜 포맷팅용)
  final String locale;

  /// 아바타 크기 (dp)
  static const double avatarSize = 40.0;

  /// 아바타-콘텐츠 간격
  static const double avatarSpacing = 10.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMe = item.speaker == ChatSpeaker.me;

    return Semantics(
      label: isMe
          ? l10n.chatBubbleMyMessageLabel(item.message)
          : l10n.chatBubbleOtherMessageLabel(item.message),
      child: isMe ? _buildMyBubble(context) : _buildOtherBubble(context),
    );
  }

  /// 내 메시지: 오른쪽 정렬, Avatar 없음
  Widget _buildMyBubble(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 메시지 내용
              Text(
                item.message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  height: 1.5,
                ),
              ),
              SizedBox(height: AppSpacing.spacing4),
              // 시간
              Text(
                AppDateFormatter.formatCardTimestamp(
                  item.createdAt,
                  locale,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상대 메시지: 왼쪽 정렬, Avatar + Nickname + 말풍선
  /// 레이아웃: Avatar | [Nickname 위 / Bubble 아래 (Avatar 중앙선 기준)]
  Widget _buildOtherBubble(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasNickname = item.displayName != null && item.displayName!.isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar (원형)
          _buildAvatar(context),
          SizedBox(width: avatarSpacing),
          // 닉네임 + 말풍선 영역
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 닉네임 (Avatar 상단 절반 높이에 위치)
                if (hasNickname)
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.spacing4,
                      bottom: AppSpacing.spacing4,
                    ),
                    child: Text(
                      item.displayName!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                // 말풍선 (닉네임 아래, Avatar 중앙선 기준 하단부터 시작)
                // 닉네임이 있으면 자연스럽게 배치됨
                // 닉네임이 없으면 Avatar 상단 약간 아래서 시작하도록 패딩 추가
                Padding(
                  padding: EdgeInsets.only(
                    top: hasNickname ? 0 : avatarSize * 0.15,
                  ),
                  child: _buildBubbleContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Avatar 원형 위젯
  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
            ? Image.network(
                item.avatarUrl!,
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultAvatarIcon(context),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildDefaultAvatarIcon(context);
                },
              )
            : _buildDefaultAvatarIcon(context),
      ),
    );
  }

  /// 기본 Avatar 아이콘 (이미지 없을 때)
  Widget _buildDefaultAvatarIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Icon(
        Icons.person,
        size: avatarSize * 0.6,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }

  /// 말풍선 내용 (상대용)
  Widget _buildBubbleContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메시지 내용
            Text(
              item.message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.spacing4),
            // 시간
            Text(
              AppDateFormatter.formatCardTimestamp(
                item.createdAt,
                locale,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
