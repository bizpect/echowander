class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String? route;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      route: json['route'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      readAt: _parseDateTime(json['read_at']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NotificationItem copyWith({
    DateTime? readAt,
  }) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      route: route,
      data: data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return null;
  }
}
