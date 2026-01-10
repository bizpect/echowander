final RegExp _urlPattern = RegExp(r'(https?:\/\/|www\.)', caseSensitive: false);
final RegExp _emailPattern = RegExp(
  r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
  caseSensitive: false,
);
final RegExp _phonePattern = RegExp(r'(\+?\d[\d\s\-]{6,})');

bool containsForbiddenPattern(String text) {
  return _urlPattern.hasMatch(text) ||
      _emailPattern.hasMatch(text) ||
      _phonePattern.hasMatch(text);
}
