/// 채팅 아이템 데이터 모델 (프레젠테이션 레벨)
class ChatItem {
  ChatItem({
    required this.id,
    required this.speaker,
    required this.message,
    required this.createdAt,
    this.displayName,
    this.avatarUrl,
  });

  /// 안정적인 키 (날짜 그룹화/위젯 트리 최적화용)
  final String id;

  /// 발화자 (나/상대)
  final ChatSpeaker speaker;

  /// 메시지 내용
  final String message;

  /// 생성 시각 (UTC 또는 로컬)
  final DateTime createdAt;

  /// 표시 이름 (speaker == other일 때만 사용, 닉네임)
  final String? displayName;

  /// 아바타 이미지 URL (speaker == other일 때만 사용, signed URL 또는 null)
  final String? avatarUrl;
}

/// 발화자 구분
enum ChatSpeaker {
  /// 나
  me,

  /// 상대
  other,
}
