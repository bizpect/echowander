# Repository Guidelines

## Project Structure & Module Organization
- `lib/`에 Dart 소스가 있으며, 엔트리 포인트는 `lib/main.dart`입니다.
- `test/`에 위젯/단위 테스트가 있습니다(예: `test/widget_test.dart`).
- `android/`, `ios/`는 플랫폼별 빌드 설정을 포함합니다.
- 현재 애셋은 미등록입니다. `assets/`에 파일을 추가하고 `pubspec.yaml`의 `flutter.assets`에 등록하세요.

## Build, Test, and Development Commands
- `flutter pub get`: `pubspec.yaml`의 의존성을 설치합니다.
- `flutter run`: 연결된 디바이스/에뮬레이터에서 앱을 실행합니다.
- `flutter test`: `test/`의 테스트를 실행합니다.
- `flutter analyze`: `analysis_options.yaml` 설정으로 정적 분석을 수행합니다.
- `flutter build apk` / `flutter build ios`: Android/iOS 릴리스 빌드를 생성합니다.

## Coding Style & Naming Conventions
- Dart/Flutter 기본 규칙: 2칸 들여쓰기, trailing comma 사용(포맷 유지에 유리).
- 제출 전 `dart format .`으로 포맷을 맞춥니다.
- 린트는 `analysis_options.yaml`에서 `package:flutter_lints`를 사용합니다.
- 파일은 `lower_snake_case`, 타입은 `UpperCamelCase`를 사용합니다.

## Testing Guidelines
- 테스트 프레임워크는 `flutter_test`입니다.
- 테스트 파일은 `*_test.dart`로 이름을 짓고, 기능 단위로 가깝게 배치합니다.
- 로컬에서 `flutter test`를 실행하고, UI 변경 시 집중 테스트를 추가하세요.

## Commit & Pull Request Guidelines
- Git 히스토리를 확인할 수 없어 규칙이 없습니다. 간결한 명령형 메시지(예: "Add onboarding screen")를 사용하세요.
- PR에는 변경 요약, 관련 이슈/티켓, 검증 절차, UI 변경 시 스크린샷을 포함합니다.

## Configuration Tips
- 의존성/애셋 추가 시 `pubspec.yaml`을 업데이트하세요.
- 플랫폼별 변경은 `android/`, `ios/`에 한정하고 PR에 근거를 적습니다.

## Agent Rules (강제)
- 주석은 모두 한글로 작성합니다.
- 아키텍처는 Feature-first Clean Architecture를 고정으로 사용합니다: `lib/features/<feature>/presentation|application|domain|data`.
- 공통 코드는 모두 `lib/core/`로 이동하며, feature 내부는 해당 기능 전용 코드만 둡니다.
- 기술 스택은 Flutter + Riverpod + intl 고정이며, 플랫폼 차이는 어댑터로 격리합니다.
- Supabase는 RPC 함수로만 접근하고, 테이블 직접 CRUD 및 RLS 우회는 금지입니다.
- DB SQL은 `supabase/sql/01_tables.sql`~`06_seed.sql`에 역할별로 분리해 관리합니다.
- 코드값은 `common_codes`로 관리하고, 사용자 노출 문자열은 intl(ARB)에서 매핑합니다.
- FCM + 딥링크는 메인 기능으로, Coordinator가 상태별로 일관 처리해야 합니다.
- `main.dart`는 최소 엔트리만 유지하고 초기화/분기는 별도 부트스트랩으로 분리합니다.
- 환경은 DEV/PROD(필요 시 STG)로 분리하고 단일 config 진입점으로만 참조합니다.
- 에러/로그/크래시는 수집 규칙을 준수하고, 임시 해결(워크어라운드)은 금지합니다.
- 앱은 중앙 통제 지점(라우팅/초기화/딥링크/설정)을 기준으로 설계해 유지보수를 쉽게 합니다.
- 인증/결제/핵심 플로우는 외부 브라우저 호출 없이 앱 내에서 처리되도록 설계합니다.
- 전체 UI는 다크 톤을 기본으로 하고, 자연스럽게 어울리는 포인트 색을 사용합니다.
- 애니메이션은 강하게 적용하되 촌스럽지 않은 UX를 유지합니다.
- 로딩 상태는 부분 인디케이터를 금지하고, 전체 화면 오버레이 + 중앙 단일 인디케이터를 공통 컴포넌트로 사용합니다.
- 알럿 다이얼로그는 `confirm`/`alert` 형태를 공통 컴포넌트로 제공하고, 전역에서 재사용합니다.
- 앱은 초기 개발 단계부터 다국어(i18n) 처리 상태로 시작해야 합니다.
- 라우팅은 `go_router`를 사용합니다.
- 에러 로그는 사용자에게/화면에 절대 노출하지 않고, 사용자 메시지는 유연하게 처리합니다.
