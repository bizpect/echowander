import 'package:flutter/material.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/formatters/app_date_formatter.dart';
import '../../../../../l10n/app_localizations.dart';
import 'chat_bubble_painter.dart';
import 'chat_item.dart';

/// 채팅 말풍선 위젯 (카카오톡 스타일, CustomPainter 꼬리)
///
/// - 내 말풍선: 오른쪽 정렬, 오른쪽 꼬리
/// - 상대 말풍선: 왼쪽 정렬, 왼쪽 꼬리, Avatar + 닉네임
/// - 이미지/텍스트 분리: imageUrl이 있으면 이미지 버블, 없으면 텍스트 버블
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.item,
    required this.locale,
    this.onImageTap,
  });

  /// 채팅 아이템
  final ChatItem item;

  /// 로케일 (날짜 포맷팅용)
  final String locale;

  /// 이미지 탭 콜백
  final VoidCallback? onImageTap;

  /// 아바타 크기 (dp)
  static const double avatarSize = 40.0;

  /// 아바타-콘텐츠 간격
  static const double avatarSpacing = 10.0;

  /// 말풍선 radius
  static const double bubbleRadius = 16.0;

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

  /// 내 메시지: 오른쪽 정렬, 오른쪽 꼬리
  Widget _buildMyBubble(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 이미지가 있으면 이미지 버블, 없으면 텍스트 버블
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 시간 (말풍선 왼쪽 아래)
            Padding(
              padding: EdgeInsets.only(
                right: AppSpacing.spacing4,
                bottom: AppSpacing.spacing4,
              ),
              child: Text(
                AppDateFormatter.formatTime(item.createdAt, locale),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ),
            // 이미지 버블
            _buildImageBubble(
              context,
              colorScheme.primaryContainer,
              colorScheme.primary.withValues(alpha: 0.3),
            ),
          ],
        ),
      );
    }

    // 텍스트 버블
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 시간 (말풍선 왼쪽 아래)
          Padding(
            padding: EdgeInsets.only(
              right: AppSpacing.spacing4,
              bottom: AppSpacing.spacing4,
            ),
            child: Text(
              AppDateFormatter.formatTime(item.createdAt, locale),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ),
          // 텍스트 버블
          _buildTextBubble(
            context,
            colorScheme.primaryContainer,
            colorScheme.onPrimaryContainer,
            colorScheme.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  /// 상대 메시지: 왼쪽 정렬, 왼쪽 꼬리, Avatar + Nickname
  Widget _buildOtherBubble(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasNickname =
        item.displayName != null && item.displayName!.isNotEmpty;

    // 이미지가 있으면 이미지 버블, 없으면 텍스트 버블
    final bubbleWidget = (item.imageUrl != null && item.imageUrl!.isNotEmpty)
        ? _buildImageBubble(
            context,
            colorScheme.surfaceContainerHighest,
            colorScheme.outline.withValues(alpha: 0.3),
          )
        : _buildTextBubble(
            context,
            colorScheme.surfaceContainerHighest,
            colorScheme.onSurface,
            colorScheme.outline.withValues(alpha: 0.3),
          );

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          _buildAvatar(context),
          SizedBox(width: avatarSpacing),
          // 닉네임 + 말풍선
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 닉네임
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
                // 말풍선 + 시간
                Padding(
                  padding: EdgeInsets.only(
                    top: hasNickname ? 0 : avatarSize * 0.15,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 말풍선
                      bubbleWidget,
                      // 시간 (말풍선 오른쪽 아래)
                      Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.spacing4,
                          bottom: AppSpacing.spacing4,
                        ),
                        child: Text(
                          AppDateFormatter.formatTime(item.createdAt, locale),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
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

  /// 텍스트 버블 (CustomPainter 꼬리 포함)
  Widget _buildTextBubble(
    BuildContext context,
    Color backgroundColor,
    Color textColor,
    Color borderColor,
  ) {
    final theme = Theme.of(context);
    final isMe = item.speaker == ChatSpeaker.me;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * (isMe ? 0.75 : 0.65),
      ),
      child: CustomPaint(
        painter: ChatBubblePainter(
          color: backgroundColor,
          isMe: isMe,
          radius: bubbleRadius,
        ),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.spacing12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(bubbleRadius),
          ),
          child: Text(
            item.message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: textColor,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  /// 이미지 버블 (CustomPainter 꼬리 포함)
  Widget _buildImageBubble(
    BuildContext context,
    Color backgroundColor,
    Color borderColor,
  ) {
    final isMe = item.speaker == ChatSpeaker.me;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
        maxHeight: 200,
      ),
      child: CustomPaint(
        painter: ChatBubblePainter(
          color: backgroundColor,
          isMe: isMe,
          radius: bubbleRadius,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(bubbleRadius),
          child: InkWell(
            onTap: onImageTap,
            child: Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(bubbleRadius),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
