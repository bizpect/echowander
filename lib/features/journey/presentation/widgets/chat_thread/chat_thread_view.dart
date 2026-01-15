import 'package:flutter/material.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/formatters/app_date_formatter.dart';
import '../../../../../core/presentation/widgets/chat_date_divider.dart';
import 'chat_bubble.dart';
import 'chat_item.dart';

/// 채팅 쓰레드 뷰 (날짜 그룹화 + 말풍선 리스트)
///
/// 사용법:
/// ```dart
/// ChatThreadView(
///   items: [
///     ChatItem(id: '1', speaker: ChatSpeaker.me, message: '안녕', createdAt: ...),
///     ChatItem(id: '2', speaker: ChatSpeaker.other, message: '반가워', createdAt: ...),
///   ],
///   locale: 'ko',
/// )
/// ```
class ChatThreadView extends StatelessWidget {
  const ChatThreadView({
    super.key,
    required this.items,
    required this.locale,
  });

  /// 채팅 아이템 리스트 (createdAt 오름차순 정렬 권장)
  final List<ChatItem> items;

  /// 로케일 (날짜 포맷팅용, 예: 'ko', 'en')
  final String locale;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // createdAt 오름차순 정렬 (과거 → 현재)
    final sortedItems = List<ChatItem>.from(items)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 위젯 리스트 생성: 날짜 구분선 + 채팅 버블
    final widgets = <Widget>[];
    DateTime? previousDate;

    for (var i = 0; i < sortedItems.length; i++) {
      final item = sortedItems[i];
      // UTC → 로컬 변환 (날짜 비교용)
      final localTime =
          item.createdAt.isUtc ? item.createdAt.toLocal() : item.createdAt;
      final currentDate = DateTime(
        localTime.year,
        localTime.month,
        localTime.day,
      );

      // 첫 아이템이거나 날짜가 바뀌면 구분선 삽입
      if (previousDate == null || currentDate != previousDate) {
        final dateText =
            AppDateFormatter.formatChatDateDivider(item.createdAt, locale);
        widgets.add(ChatDateDivider(dateText: dateText));
        previousDate = currentDate;
      }

      // 채팅 버블
      widgets.add(ChatBubble(item: item, locale: locale));

      // 버블 간 spacing (마지막 아이템 제외)
      if (i < sortedItems.length - 1) {
        widgets.add(SizedBox(height: AppSpacing.spacing12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}
