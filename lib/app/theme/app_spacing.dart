/// 앱 전체에서 사용하는 간격(Spacing) 토큰
/// 4dp 기준 스케일
class AppSpacing {
  // 기본 간격 스케일
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0; // 기본 단위
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // 화면별 패딩
  static const double screenPaddingHorizontal = 20.0; // 좌우 여백
  static const double screenPaddingTop = 20.0; // 상단 여백
  static const double screenPaddingBottom = 24.0; // 하단 여백 (SafeArea 포함)

  static const double listItemPadding = 16.0; // 리스트 아이템 내부 패딩
  static const double cardPadding = 16.0; // 카드 내부 패딩

  // 요소 간 간격
  static const double sectionGap = 24.0; // 섹션 간 간격
  static const double elementGap = 16.0; // 요소 간 기본 간격
  static const double tightGap = 8.0; // 관련 요소 간 좁은 간격
  static const double compactGap = 4.0; // 매우 밀접한 요소 간격

  // 최소 터치 영역 (접근성)
  static const double minTouchTarget = 48.0;
}
