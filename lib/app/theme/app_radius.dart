import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 Border Radius 토큰
class AppRadius {
  // Border Radius 값
  static const double radiusSmall = 8.0; // 작은 요소 (칩, 작은 버튼)
  static const double radiusMedium = 12.0; // 기본 (카드, 이미지, 중형 버튼)
  static const double radiusLarge = 16.0; // 큰 요소 (다이얼로그, 시트)
  static const double radiusXLarge = 24.0; // 매우 큰 요소 (풀스크린 모달)
  static const double radiusFull = 9999.0; // 완전한 원 (뱃지, 아바타)

  // 토스 톤 기준 네이밍
  static const double card = radiusLarge;
  static const double sheet = radiusXLarge;
  static const double pill = radiusFull;

  // BorderRadius 헬퍼
  static BorderRadius get small => BorderRadius.circular(radiusSmall);
  static BorderRadius get medium => BorderRadius.circular(radiusMedium);
  static BorderRadius get large => BorderRadius.circular(radiusLarge);
  static BorderRadius get xLarge => BorderRadius.circular(radiusXLarge);
  static BorderRadius get full => BorderRadius.circular(radiusFull);

  // Radius 헬퍼
  static Radius get smallRadius => const Radius.circular(radiusSmall);
  static Radius get mediumRadius => const Radius.circular(radiusMedium);
  static Radius get largeRadius => const Radius.circular(radiusLarge);
  static Radius get xLargeRadius => const Radius.circular(radiusXLarge);
  static Radius get fullRadius => const Radius.circular(radiusFull);
}
