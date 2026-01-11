class CommonCode {
  const CommonCode({
    required this.codeType,
    required this.codeValue,
    required this.name,
    required this.labels,
    required this.sortOrder,
  });

  final String codeType;
  final String codeValue;
  final String name;
  final Map<String, String> labels;
  final int sortOrder;

  factory CommonCode.fromJson(Map<String, dynamic> json) {
    final rawLabels = json['labels'];
    final labels = <String, String>{};
    if (rawLabels is Map) {
      for (final entry in rawLabels.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is String) {
          labels[key] = value;
        }
      }
    }
    return CommonCode(
      codeType: json['code_type'] as String? ?? '',
      codeValue: json['code_value'] as String? ?? '',
      name: json['name'] as String? ?? '',
      labels: labels,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  String resolveLabel(String locale) {
    if (labels.containsKey(locale)) {
      return labels[locale]!;
    }
    if (locale.contains('_')) {
      final languageCode = locale.split('_').first;
      if (labels.containsKey(languageCode)) {
        return labels[languageCode]!;
      }
    }
    if (labels.containsKey('en')) {
      return labels['en']!;
    }
    if (name.isNotEmpty) {
      return name;
    }
    return codeValue;
  }
}
