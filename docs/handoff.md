# 작업 인수인계 메모

## 진행 요약
- 보낸 메시지 상세(진행/결과) 화면 + 리워드 광고 게이트 완료.
- 인박스 상세에서 응답/패스/신고 + 보낸 사람 차단 추가.
- 차단 목록 화면: 닉네임 + 아바타만 표시(사용자 ID 노출 금지), 아바타 로딩 실패 시 기본 아이콘 처리.
- 설정 화면: 알림 토글 + 차단 목록 진입.
- 딥링크 `/safety` 관련 소스 전부 제거.
- 응답 신고/여정 신고 누적 처리 정책 반영.
- AdMob: 앱 ID는 플레이스홀더로 분리, 보상형 유닛 ID는 .env로 분기.

## 정책 반영(요청 확정)
- 언어 기반 매칭 제거(랜덤 + 차단 제외 + 활성 계정 유지).
- 응답 신고 2건 이상: 응답 숨김(결과 목록에서 제외).
- 응답 신고 5건 이상: 해당 사용자 응답 제한(임시 정지, 현재 7일).
- Journey 신고 3건 이상: filter_code = HELD 전환.
- 사용자 노출 화면에서 user_id 절대 표시 금지(AGENTS.md 반영).

## 주요 변경 파일
### SQL
- `supabase/sql/01_tables.sql`
  - `users.response_suspended_until` 추가
  - `journey_responses.is_hidden` 추가
  - `journey_response_reports` 테이블 추가
- `supabase/sql/02_functions.sql`
  - `list_my_blocks`에 `blocked_avatar_url` 추가 + security definer
  - `report_journey_response` 누적 처리(응답 숨김/응답 제한)
  - `report_journey` 누적 처리(3건 HELD)
  - `respond_journey`에서 응답 제한 체크
  - `list_journey_results`에서 `is_hidden=false` 필터
- `supabase/sql/04_rls.sql`
  - `journey_response_reports` RLS/권한/함수 실행 권한 추가
- `supabase/sql/05_indexes.sql`
  - `journey_response_reports` 인덱스
  - `journey_responses (journey_id, is_hidden)`
  - `users.response_suspended_until`

### Flutter
- 새 화면/라우팅
  - `lib/features/journey/presentation/journey_sent_detail_screen.dart`
  - `lib/features/block/presentation/block_list_screen.dart`
  - `lib/features/settings/presentation/settings_screen.dart`
  - `lib/app/router/app_router.dart`
- 차단/알림 레포지토리
  - `lib/core/block/block_repository.dart`
  - `lib/core/block/supabase_block_repository.dart`
  - `lib/core/notifications/notification_preference_repository.dart`
- 리워드 광고
  - `lib/core/ads/rewarded_ad_service.dart`
  - `lib/core/bootstrap/app_bootstrap.dart`
  - `lib/core/config/app_config.dart`
- 인박스 상세 차단
  - `lib/features/journey/presentation/journey_inbox_detail_screen.dart`
- 홈 화면 설정 버튼
  - `lib/features/home/presentation/home_screen.dart`
- 안전 딥링크 제거
  - `lib/features/safety/presentation/safety_screen.dart` (삭제)
  - l10n에서 `settingsSafetyGuide`, `safetyTitle` 제거

### 환경/플랫폼
- Android AdMob 앱 ID 플레이스홀더:
  - `android/app/src/main/AndroidManifest.xml` -> `${ADMOB_APP_ID}`
  - `android/app/build.gradle.kts` 기본 테스트 ID 설정
- iOS AdMob 앱 ID 플레이스홀더:
  - `ios/Runner/Info.plist` -> `$(ADMOB_APP_ID_IOS)`
  - `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig`에 테스트 ID 설정
- pubspec:
  - `google_mobile_ads` 추가

## 아직 해야 할 것(다음 작업자용)
1) 로컬 실행 전
   - `flutter pub get`
   - `flutter gen-l10n`
2) Supabase SQL 반영
   - `supabase/sql/01_tables.sql`
   - `supabase/sql/02_functions.sql`
   - `supabase/sql/04_rls.sql`
   - `supabase/sql/05_indexes.sql`
3) AdMob 실 ID 세팅
   - Android: `android/gradle.properties`에 `ADMOB_APP_ID=실제값`
   - iOS: `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig`의 `ADMOB_APP_ID_IOS` 교체
   - `.env.local`에 `ADMOB_REWARDED_UNIT_ID_ANDROID`, `ADMOB_REWARDED_UNIT_ID_IOS`

## 동작 확인 체크리스트
- 보낸 메시지 상세에서 리워드 광고 게이트 -> 광고 성공 시 결과 노출
- 광고 실패 시 “그냥 보기” 동작
- 결과 응답 신고 -> 2회 이상 숨김 확인, 5회 이상 응답 제한 확인
- 차단 목록에서 닉네임+아바타만 표시(아이디 노출 없음)
- 인박스 상세에서 차단 동작 정상
- 알림 토글 OFF 시 토큰 미등록/비활성 확인

## 메모
- 응답 제한 기간은 현재 7일. 변경 원하면 `report_journey_response`에서 interval 수정.
