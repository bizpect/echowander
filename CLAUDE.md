# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ 필수 개발 규칙 (작업 전 반드시 확인)

### 코드 작성 기본 원칙
- **주석은 모두 한글로 작성합니다.**
- **아키텍처는 Feature-first Clean Architecture를 고정으로 사용합니다**: `lib/features/<feature>/presentation|application|domain|data`
- **공통 코드는 모두 `lib/core/`로 이동하며, feature 내부는 해당 기능 전용 코드만 둡니다.**
- **기술 스택은 Flutter + Riverpod + intl 고정이며, 플랫폼 차이는 어댑터로 격리합니다.**

### 다국어 처리 (i18n)
- **다국어는 ARB를 단일 소스로 관리하고 `flutter gen-l10n`으로 생성 파일을 갱신합니다.**
- **작업 중 추가/변경하는 모든 사용자 노출 문자열은 모든 ARB 로케일에 번역을 반영합니다.**
- **앱은 초기 개발 단계부터 다국어(i18n) 처리 상태로 시작해야 합니다.**

### 백엔드 및 데이터 처리
- **Supabase는 RPC 함수로만 접근하고, 테이블 직접 CRUD 및 RLS 우회는 금지합니다.**
- **DB SQL은 `supabase/sql/01_tables.sql`~`06_seed.sql`에 역할별로 분리해 관리합니다.**
- **코드값은 `common_codes`로 관리하고, 사용자 노출 문자열은 intl(ARB)에서 매핑합니다.**
- **서버 시간(timestamp)은 화면 표시 시 `toLocal()`로 명시적으로 변환해 로컬 타임존 기준으로 보여줍니다.**

### 환경 설정
- **Android 디버그 키스토어 경로는 `C:\project\echowander\debug.keystore`로 고정하며 변경하지 않습니다.**
- **환경은 DEV/PROD(필요 시 STG)로 분리하고 단일 config 진입점으로만 참조합니다.**

### 앱 초기화 및 라우팅
- **`main.dart`는 최소 엔트리만 유지하고 초기화/분기는 별도 부트스트랩으로 분리합니다.**
- **라우팅은 `go_router`를 사용합니다.**
- **앱은 중앙 통제 지점(라우팅/초기화/딥링크/설정)을 기준으로 설계해 유지보수를 쉽게 합니다.**
- **모든 화면에서 뒤로가기(물리키/아이콘) 시 스택의 이전 화면으로 이동하고, 이전 화면이 없으면 홈으로 이동합니다. 딥링크 진입도 동일 규칙을 적용합니다.**

### 푸시 알림 및 딥링크
- **FCM + 딥링크는 메인 기능으로, Coordinator가 상태별로 일관 처리해야 합니다.**

### 인증 및 핵심 플로우
- **인증/결제/핵심 플로우는 외부 브라우저 호출 없이 앱 내에서 처리되도록 설계합니다.**

### UI/UX 가이드라인
- **알럿 다이얼로그는 `confirm`/`alert` 형태를 공통 컴포넌트로 제공하고, 전역에서 재사용합니다.**
- **모든 화면에서 SafeArea 상/하단을 적용합니다.**
- **키보드로 인한 오버플로우가 발생하지 않도록 입력 화면은 스크롤/뷰 인셋 처리를 적용합니다.**

### 사용자 정보 표시
- **사용자에게 노출되는 모든 화면에서는 user_id를 표시하지 않고 닉네임만 표시합니다.**

### 에러 처리 및 로깅
- **에러/로그/크래시는 수집 규칙을 준수하고, 임시 해결(워크어라운드)은 금지합니다.**
- **에러 로그는 사용자에게/화면에 절대 노출하지 않고, 사용자 메시지는 유연하게 처리합니다.**
- **모든 서버 접근에서 에러 발생 시 `client_error_logs` 테이블에 로그를 남길 수 있도록 처리합니다.**

---

## 프로젝트 개요

echowander는 사용자가 "여정(journey)"(이미지가 포함된 메시지)을 생성하고 다른 사용자와 공유할 수 있는 Flutter 모바일 애플리케이션입니다. 이 앱은 백엔드 서비스로 Supabase를 사용하고, 푸시 알림을 위해 Firebase를 사용하며, 다국어 현지화를 지원합니다.

## 개발 명령어

### 초기 설정
```bash
# 의존성 설치
flutter pub get

# ARB 파일 업데이트 후 현지화 파일 생성
flutter gen-l10n

# 환경 변수 로드 (실행에 필수)
# 필요한 변수가 포함된 .env.local 파일 생성 (lib/core/config/app_config.dart 참조)
```

### 앱 실행
```bash
# 연결된 기기/에뮬레이터에서 실행
flutter run

# 특정 환경으로 실행
flutter run --dart-define=APP_ENV=dev
flutter run --dart-define=APP_ENV=stg
flutter run --dart-define=APP_ENV=prod
```

### 테스트
```bash
# 모든 테스트 실행
flutter test

# 특정 테스트 파일 실행
flutter test test/widget_test.dart

# 커버리지와 함께 테스트 실행
flutter test --coverage
```

### 코드 품질
```bash
# 정적 분석 실행
flutter analyze

# 코드 포맷팅
flutter format lib/ test/
```

### 빌드
```bash
# APK 빌드 (안드로이드)
flutter build apk

# App Bundle 빌드 (안드로이드)
flutter build appbundle

# iOS 빌드
flutter build ios
```

## 아키텍처

### 전체 구조

코드베이스는 클린 아키텍처 원칙을 따르는 **기능 기반 아키텍처(feature-based architecture)**를 따릅니다:

```
lib/
├── app/                    # 앱 레벨 설정
│   ├── router/            # GoRouter 네비게이션 설정
│   └── theme/             # 앱 테마
├── core/                  # 공유 인프라
│   ├── auth/             # 소셜 인증 (Google, Apple, Kakao)
│   ├── session/          # 세션/토큰 관리
│   ├── push/             # Firebase Cloud Messaging
│   ├── deeplink/         # 딥링크 처리
│   ├── config/           # 환경 설정
│   ├── locale/           # 로케일 관리 및 동기화
│   └── ...               # 기타 공유 서비스
├── features/             # 기능 모듈
│   ├── journey/          # 메인 기능 (여정 생성/전송/수신)
│   ├── auth/             # 로그인 화면
│   ├── notifications/    # 알림 인박스
│   ├── settings/         # 앱 설정
│   └── ...
└── l10n/                 # 현지화 (ARB 파일)
```

### 기능 모듈 패턴

각 기능은 클린 아키텍처 레이어를 따릅니다:

```
features/[feature_name]/
├── domain/              # 비즈니스 로직 레이어
│   └── *_repository.dart     # 추상 리포지토리 인터페이스
├── data/                # 데이터 레이어
│   └── supabase_*_repository.dart  # Supabase 구현체
├── application/         # 애플리케이션 로직 레이어
│   └── *_controller.dart     # Riverpod 상태 컨트롤러
└── presentation/        # UI 레이어
    └── *_screen.dart         # 화면 위젯
```

### 주요 아키텍처 패턴

1. **상태 관리**: 전체적으로 Riverpod 프로바이더 사용
   - 컨트롤러는 `StateNotifier` 또는 `AsyncNotifier` 패턴 사용
   - 모든 기능은 의존성 주입을 위한 프로바이더 노출

2. **리포지토리 패턴**: `domain/`에 추상 인터페이스, `data/`에 구현체
   - 테스트 가능성 및 구현체 교체 용이
   - 주요 구현체는 Supabase 사용

3. **네비게이션**: 인증 가드가 있는 GoRouter
   - `lib/app/router/app_router.dart`에 라우트 정의
   - 세션 상태 및 온보딩 상태에 따른 자동 리다이렉트

4. **세션 관리**: `core/session/session_manager.dart`에 중앙화
   - 인증 상태 처리
   - 보안 저장소로 토큰 관리
   - 소셜 인증 프로바이더와 조정

## 백엔드 통합

### Supabase
- 데이터베이스 작업, 인증, 스토리지를 위한 주요 백엔드
- SQL 스키마는 `supabase/sql/` 디렉토리에 위치:
  - `01_tables.sql` - 테이블 정의
  - `02_functions.sql` - 저장 프로시저 및 함수
  - `03_triggers.sql` - 데이터베이스 트리거
  - `04_rls.sql` - Row Level Security 정책
  - `05_indexes.sql` - 데이터베이스 인덱스
  - `06_seed.sql` - 시드 데이터
- 리포지토리 구현체는 `lib/features/*/data/supabase_*_repository.dart`에 위치

### Firebase
- **Firebase Cloud Messaging (FCM)**: 푸시 알림
  - 백그라운드 핸들러: `lib/core/push/fcm_background_handler.dart`
  - 코디네이터: `lib/core/push/push_coordinator.dart`
- **Firebase Core**: FCM 초기화에 필수

### 인증 프로바이더
- Google Sign-In
- Apple Sign-In (iOS)
- Kakao Login (한국 시장)
- 모두 `lib/core/auth/social_auth_service.dart`를 통해 조정됨

## 설정

### 환경 변수

앱은 환경 설정을 위해 `.env.local` 파일을 사용합니다. 필수 변수 (`lib/core/config/app_config.dart` 참조):

- `APP_ENV` - 환경 (dev/stg/prod)
- `AUTH_BASE_URL` - 커스텀 인증 서비스 URL
- `APP_SUPABASE_URL` - Supabase 프로젝트 URL
- `APP_SUPABASE_ANON_KEY` - Supabase 익명 키
- `APP_DISPATCH_JOB_SECRET` - 작업 디스패치 시크릿
- `KAKAO_NATIVE_APP_KEY` - Kakao SDK 키
- `GOOGLE_SERVER_CLIENT_ID` - Google OAuth 클라이언트 ID
- `GOOGLE_IOS_CLIENT_ID` - Google iOS 클라이언트 ID
- `ADMOB_APP_ID_ANDROID` - AdMob 앱 ID (안드로이드)
- `ADMOB_APP_ID_IOS` - AdMob 앱 ID (iOS)
- `ADMOB_REWARDED_UNIT_ID_ANDROID` - AdMob 보상형 광고 단위 (안드로이드)
- `ADMOB_REWARDED_UNIT_ID_IOS` - AdMob 보상형 광고 단위 (iOS)

## 현지화

앱은 8개 언어를 지원합니다: 영어, 한국어, 일본어, 스페인어, 프랑스어, 포르투갈어, 브라질 포르투갈어, 중국어.

**워크플로우:**
1. `lib/l10n/app_*.arb` ARB 파일 업데이트 (단일 정보원)
2. `flutter gen-l10n` 실행하여 Dart 파일 생성
3. ARB 파일과 생성된 `.dart` 파일 모두 커밋
4. 위젯에서 `AppLocalizations.of(context)` 사용하여 번역 접근

**언어 선택:**
- 사용자는 앱 내 설정을 통해 언어 변경 가능
- `lib/core/locale/locale_controller.dart`로 관리됨
- `lib/core/locale/locale_sync_controller.dart`를 통해 백엔드와 동기화

## 주요 기능

### Journey (여정)
사용자가 여정(선택적 이미지가 포함된 메시지)을 생성하고 공유할 수 있는 핵심 기능.

- **작성**: `lib/features/journey/presentation/journey_compose_screen.dart`
- **목록 (보낸 편)**: `lib/features/journey/presentation/journey_list_screen.dart`
- **인박스 (받은 편)**: `lib/features/journey/presentation/journey_inbox_screen.dart`
- **리포지토리**: `lib/features/journey/domain/journey_repository.dart`

### 푸시 알림
- 포그라운드/백그라운드 핸들러가 있는 FCM 통합
- 알림 탭 시 특정 콘텐츠로 딥링크
- 사용자별 알림 환경설정 관리
- 알림 히스토리 조회를 위한 인박스

### 세션 및 인증
- 소셜 로그인 (Google, Apple, Kakao)
- 리프레시 메커니즘이 있는 토큰 기반 인증
- `flutter_secure_storage`를 사용한 안전한 토큰 저장
- Riverpod 프로바이더를 통한 세션 상태 전파

### 딥링크
- `lib/core/deeplink/deeplink_coordinator.dart`에서 처리
- 네비게이션을 위해 푸시 알림과 조정
- 앱이 준비되면 라우트가 큐에 대기되고 처리됨

## 중요한 구현 세부사항

### 앱 부트스트랩 시퀀스
1. `main.dart`가 `AppBootstrap().initialize()` 호출
2. `.env.local` 환경 변수 로드
3. Firebase 초기화
4. FCM 백그라운드 핸들러 설정
5. AdMob 초기화
6. Kakao SDK 초기화 (설정된 경우)
7. Riverpod을 위해 앱을 `ProviderScope`로 래핑

### 라우터 인증 플로우
`lib/app/router/app_router.dart`의 라우터는 자동 리다이렉트를 구현합니다:
- 알 수 없는 세션/온보딩 상태 → 스플래시
- 온보딩 필요 → 온보딩 화면
- 비인증 → 로그인 화면
- 인증됨 → 홈 또는 요청된 라우트

### Riverpod 프로바이더 리스너
메인 `App` 위젯 (`lib/app/app.dart`)은 중요한 리스너들을 설정합니다:
- 에러 다이얼로그를 위한 세션 상태 변경
- 백엔드 동기화를 위한 로케일 변경
- 푸시 메시지 포그라운드 처리
- 딥링크 네비게이션 조정

## 일반적인 패턴

### 새 기능 생성하기
1. 기능 디렉토리 생성: `lib/features/[feature_name]/`
2. domain 레이어 추가: 리포지토리 인터페이스, 모델
3. data 레이어 추가: 리포지토리 구현체 (일반적으로 Supabase)
4. application 레이어 추가: 상태 관리를 위한 Riverpod 컨트롤러
5. presentation 레이어 추가: 화면 및 위젯
6. `lib/app/router/app_router.dart`에 라우트 등록

### 현지화 추가하기
1. `lib/l10n/`의 모든 ARB 파일에 키-값 쌍 추가
2. `flutter gen-l10n` 실행
3. `AppLocalizations.of(context)!.yourKey`를 통해 접근

### 리포지토리 작업하기
- 항상 `domain/`에 추상 인터페이스 정의
- `data/`에 구체적인 클래스 구현
- Riverpod 프로바이더를 통해 노출
- 프로바이더 의존성을 통해 컨트롤러에 주입
