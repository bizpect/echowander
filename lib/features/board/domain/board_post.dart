class BoardPostSummary {
  const BoardPostSummary({
    required this.id,
    required this.boardKey,
    required this.typeCode,
    required this.title,
    required this.contentPreview,
    required this.isPinned,
    required this.publishedAt,
  });

  final String id;
  final String boardKey;
  final String? typeCode;
  final String title;
  final String contentPreview;
  final bool isPinned;
  final DateTime publishedAt;

  factory BoardPostSummary.fromJson(Map<String, dynamic> json) {
    return BoardPostSummary(
      id: json['id'] as String? ?? '',
      boardKey: json['board_key'] as String? ?? '',
      typeCode: json['type_code'] as String?,
      title: json['title'] as String? ?? '',
      contentPreview: json['content_preview'] as String? ?? '',
      isPinned: json['is_pinned'] as bool? ?? false,
      publishedAt: DateTime.parse(
        json['published_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class BoardPostDetail {
  const BoardPostDetail({
    required this.id,
    required this.boardKey,
    required this.typeCode,
    required this.title,
    required this.content,
    required this.isPinned,
    required this.publishedAt,
  });

  final String id;
  final String boardKey;
  final String? typeCode;
  final String title;
  final String content;
  final bool isPinned;
  final DateTime publishedAt;

  factory BoardPostDetail.fromJson(Map<String, dynamic> json) {
    return BoardPostDetail(
      id: json['id'] as String? ?? '',
      boardKey: json['board_key'] as String? ?? '',
      typeCode: json['type_code'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isPinned: json['is_pinned'] as bool? ?? false,
      publishedAt: DateTime.parse(
        json['published_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
