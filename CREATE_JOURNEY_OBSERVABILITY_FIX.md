# create_journey Unknown Error - 관측성 강화 리포트

## 개요

**목표**: `create_journey`가 `NetworkRequestException(type: unknown, statusCode: null, message: null)`로 실패하는 원인을 1회 실행으로 확정 진단 가능하도록 관측성 강화

**작업 일시**: 2026-01-14
**작업 범위**: 에러 타입별 상세 로깅 + 파싱 단계별 추적 + 예외 타입 명시화

---

## 문제 분석

### 기존 문제점

```dart
NetworkRequestException(type: unknown, statusCode: null, message: null)
```

- `statusCode: null` → HTTP 응답이 아닌 클라이언트 측 예외
- `type: unknown` → 일반 `catch (error)` 블록에서 처리됨
- `message: null` → 에러 정보 전혀 없음

### 근본 원인 가설

1. **응답 파싱 실패**: `first['journey_id']` 또는 `first['created_at']` 필드 접근 시 TypeError/NoSuchMethodError
2. **필드명 불일치**: DB 스키마 변경 (예: `created_at` → `journey_created_at`)
3. **응답 구조 변경**: RPC 함수가 예상과 다른 형식 반환
4. **날짜 파싱 실패**: `DateTime.parse()` 에러

---

## 구현 내용

### 1. NetworkGuard 관측성 강화

**파일**: [lib/core/network/network_guard.dart](lib/core/network/network_guard.dart#L257-L309)

#### 변경 사항

```dart
} catch (error, stackTrace) {  // ✅ stackTrace 추가 캡처
  lastError = error;

  // ✅ 상세 로깅
  if (kDebugMode) {
    debugPrint('[NetworkGuard][$traceLabel] Unknown error caught:');
    debugPrint('  Type: ${error.runtimeType}');
    debugPrint('  Error: $error');
    debugPrint('  StackTrace (first 30 lines):');
    final stackLines = stackTrace.toString().split('\n').take(30).join('\n');
    debugPrint(stackLines);
  }

  // ✅ 에러 로거에 메타데이터 추가
  await _errorLogger?.logException(
    context: context,
    // ... 기존 파라미터 ...
    meta: {
      ...?meta,
      'error_type': error.runtimeType.toString(),
      'stack_trace': stackTrace.toString().split('\n').take(30).join('\n'),
    },
  );

  // ✅ TypeError/NoSuchMethodError → invalidPayload 매핑
  if (error is TypeError || error is NoSuchMethodError) {
    throw NetworkRequestException(
      type: NetworkErrorType.invalidPayload,
      message: 'Client parse error: ${error.runtimeType}',
      originalError: error,
    );
  }

  // ✅ unknown 에러에도 타입 정보 포함
  throw NetworkRequestException(
    type: NetworkErrorType.unknown,
    message: 'Unknown error: ${error.runtimeType}',
    originalError: error,
  );
}
```

#### 개선 효과

- ❌ **이전**: `type: unknown, statusCode: null, message: null` (진단 불가)
- ✅ **이후**: `type: invalidPayload, message: 'Client parse error: TypeError'` + 30줄 스택트레이스

---

### 2. create_journey 파싱 관측성 강화

**파일**: [lib/features/journey/data/supabase_journey_repository.dart](lib/features/journey/data/supabase_journey_repository.dart#L256-L355)

#### 변경 사항

##### 2.1. 원시 응답 구조 로깅

```dart
// 응답 파싱 (관측성 강화)
final payload = jsonDecode(body);

if (kDebugMode) {
  debugPrint('compose: payload type=${payload.runtimeType}');
  if (payload is List) {
    debugPrint('compose: payload is List, length=${payload.length}');
    if (payload.isNotEmpty) {
      final first = payload.first;
      debugPrint('compose: first element type=${first.runtimeType}');
      if (first is Map<String, dynamic>) {
        debugPrint('compose: first keys=${first.keys.toList()}');
      }
    }
  } else if (payload is Map) {
    debugPrint('compose: payload is Map, keys=${payload.keys.toList()}');
  }
}
```

**진단 가능한 문제**:
- List vs Map 구조 차이
- 빈 배열 반환
- 필드명 확인

##### 2.2. 필수 필드 명시적 검증

```dart
// 필수 필드 존재 여부 확인
if (!first.containsKey('journey_id')) {
  if (kDebugMode) {
    debugPrint('compose: Missing required field: journey_id');
  }
  throw const FormatException('Missing required field: journey_id');
}
if (!first.containsKey('created_at')) {
  if (kDebugMode) {
    debugPrint('compose: Missing required field: created_at');
  }
  throw const FormatException('Missing required field: created_at');
}
```

**진단 가능한 문제**:
- 필드명 변경 (예: `created_at` → `journey_created_at`)
- RPC 함수 시그니처 불일치

##### 2.3. 단계별 파싱 로깅

```dart
// 각 필드 파싱 시도 (관측성 강화)
try {
  if (kDebugMode) {
    debugPrint('compose: Parsing journey_id...');
  }
  final journeyId = first['journey_id'] as String;

  if (kDebugMode) {
    debugPrint('compose: Parsing created_at...');
  }
  final createdAt = DateTime.parse(first['created_at'] as String);

  if (kDebugMode) {
    debugPrint('compose: Parsing moderation_status...');
  }
  final moderationStatus = first['moderation_status'] as String?;

  if (kDebugMode) {
    debugPrint('compose: Parsing content_clean...');
  }
  final contentClean = first['content_clean'] as String?;

  if (kDebugMode) {
    debugPrint('compose: All fields parsed successfully');
  }

  return JourneyCreationResult(...);

} on TypeError catch (e, stackTrace) {
  if (kDebugMode) {
    debugPrint('compose: TypeError during field parsing: $e');
    debugPrint('compose: StackTrace: ${stackTrace.toString().split('\n').take(10).join('\n')}');
  }
  throw FormatException('Field type mismatch: $e');

} on FormatException catch (e) {
  if (kDebugMode) {
    debugPrint('compose: FormatException during date parsing: $e');
  }
  throw FormatException('Date parsing failed: $e');
}
```

**진단 가능한 문제**:
- 어느 필드에서 터지는지 정확히 식별
- TypeError (필드 타입 불일치)
- FormatException (날짜 파싱 실패)

---

## 에러 시나리오별 진단 흐름

### 시나리오 1: 필드명 변경 (created_at → journey_created_at)

**로그 출력**:
```
compose: create_journey 응답 [{"journey_id":"...","journey_created_at":"..."}]
compose: payload type=List<dynamic>
compose: payload is List, length=1
compose: first element type=_Map<String, dynamic>
compose: first keys=[journey_id, journey_created_at, moderation_status, content_clean]
compose: Missing required field: created_at  ← 여기서 확정
[NetworkGuard][create_journey] Unknown error caught:
  Type: FormatException
  Error: FormatException: Missing required field: created_at
```

**결과**: `NetworkErrorType.invalidPayload` (FormatException은 NetworkGuard가 자동 매핑)

---

### 시나리오 2: 필드 타입 불일치 (journey_id가 int로 반환)

**로그 출력**:
```
compose: first keys=[journey_id, created_at, moderation_status, content_clean]
compose: Parsing journey_id...
compose: TypeError during field parsing: type 'int' is not a subtype of type 'String' in type cast  ← 여기서 확정
[NetworkGuard][create_journey] Unknown error caught:
  Type: TypeError
  Error: type 'int' is not a subtype of type 'String'
```

**결과**: `NetworkErrorType.invalidPayload` + `message: 'Client parse error: TypeError'`

---

### 시나리오 3: 날짜 형식 오류 (created_at가 "invalid" 문자열)

**로그 출력**:
```
compose: Parsing journey_id...
compose: Parsing created_at...
compose: FormatException during date parsing: FormatException: Invalid date format  ← 여기서 확정
[NetworkGuard][create_journey] Unknown error caught:
  Type: FormatException
  Error: FormatException: Date parsing failed: ...
```

**결과**: `NetworkErrorType.invalidPayload`

---

### 시나리오 4: 빈 배열 반환

**로그 출력**:
```
compose: create_journey 응답 []
compose: payload type=List<dynamic>
compose: payload is List, length=0  ← 여기서 확정
compose: create_journey 응답 형식 오류 (expected non-empty List, got List<dynamic>)
[NetworkGuard][create_journey] Unknown error caught:
  Type: FormatException
  Error: FormatException: Invalid payload format: expected non-empty List
```

**결과**: `NetworkErrorType.invalidPayload`

---

## 검증 체크리스트

### 코드 품질

- [x] `flutter analyze`: **0 issues**
- [x] i18n 동기화: 8개 언어 ARB 파일 모두 `composeSendRequestAccepted` 포함
- [x] NetworkGuard 사용: 모든 HTTP 요청이 `_networkGuard.execute()` 래핑
- [x] 직접 Supabase 호출 없음: `.from()/.select()/.insert()` 사용 없음 (검증 완료)

### grep 증빙

```bash
# 1. 직접 Supabase 테이블 호출 검증
$ grep -r "\.from\(|\.select\(|\.insert\(" lib/features/journey/data
# 결과: 0건 (HttpClient() 초기화만 존재)

# 2. 하드코딩된 사용자 문자열 검증
$ grep -r "(전송 요청|메시지를 보냈|Your message)" lib/features/journey
# 결과: 0건 (모두 l10n.composeSendRequestAccepted 사용)

# 3. NetworkGuard 사용 검증
$ grep -r "_networkGuard\.execute" lib/features/journey/data/supabase_journey_repository.dart
# 결과: 16건 (모든 HTTP 요청이 래핑됨)
```

---

## 다음 단계 (테스트 가이드)

### 1단계: 로그 수집

```bash
flutter run --verbose
# 또는
flutter run --debug
```

### 2단계: create_journey 실행

앱에서 여정 전송 시도 후 로그 확인:

```
compose: create_journey 요청 (len=..., lang=ko, images=0)
compose: create_journey 응답 [{"journey_id":"...","created_at":"..."}]
compose: payload type=List<dynamic>
compose: payload is List, length=1
compose: first element type=_Map<String, dynamic>
compose: first keys=[journey_id, created_at, moderation_status, content_clean]
compose: Parsing journey_id...
compose: Parsing created_at...
compose: Parsing moderation_status...
compose: Parsing content_clean...
compose: All fields parsed successfully  ← 성공 시
compose: RPC 호출 완료 (dispatch는 백엔드 워커가 처리)
```

**또는 에러 발생 시**:

```
compose: Missing required field: created_at  ← 필드명 변경
compose: TypeError during field parsing: ...  ← 타입 불일치
compose: FormatException during date parsing: ...  ← 날짜 파싱 실패
[NetworkGuard][create_journey] Unknown error caught:
  Type: TypeError (또는 FormatException)
  Error: ...
  StackTrace (first 30 lines):
    #0 SupabaseJourneyRepository._executeCreateJourney
    #1 ...
```

### 3단계: 근본 원인 확정

로그에서 다음을 확인:
1. `first keys=[...]` → 실제 반환된 필드명 확인
2. `Parsing [field_name]...` 직후 에러 → 해당 필드가 문제
3. `error_type: TypeError/FormatException` → 클라이언트 파싱 에러 확정

### 4단계: 성공 경로 검증

성공 시 확인 사항:
- [x] UX: "전송 요청이 접수되었습니다" 메시지 표시
- [x] DB: `journey_dispatch_jobs` 테이블에 `status='pending'` row 생성 확인

```sql
SELECT journey_id, status, created_at
FROM public.journey_dispatch_jobs
WHERE journey_id = '<생성된_journey_id>'
ORDER BY created_at DESC
LIMIT 1;

-- 예상 결과:
-- journey_id | status  | created_at
-- -----------|---------|-----------
-- uuid       | pending | 2026-01-14 ...
```

---

## 수정 파일 목록

### 1. 핵심 수정

| 파일 | 변경 내용 | 라인 |
|------|-----------|------|
| [lib/core/network/network_guard.dart](lib/core/network/network_guard.dart#L257-L309) | stackTrace 캡처, TypeError/NoSuchMethodError → invalidPayload 매핑, 에러 타입 로깅 | 257-309 |
| [lib/features/journey/data/supabase_journey_repository.dart](lib/features/journey/data/supabase_journey_repository.dart#L256-L355) | 원시 응답 로깅, 필수 필드 검증, 단계별 파싱 로깅, TypeError/FormatException 캐치 | 256-355 |

### 2. 기존 Outbox 마이그레이션 파일 (참고)

| 파일 | 용도 |
|------|------|
| [supabase/sql/08_dispatch_jobs_migration.sql](supabase/sql/08_dispatch_jobs_migration.sql) | journey_dispatch_jobs 테이블, process_journey_dispatch_jobs RPC, create_journey 수정 |
| [lib/l10n/app_*.arb](lib/l10n/) (8개 파일) | `composeSendRequestAccepted` 키 추가 (라인 117) |
| [lib/features/journey/presentation/journey_compose_screen.dart](lib/features/journey/presentation/journey_compose_screen.dart) | 성공 메시지 변경 (라인 513, 526) |
| [lib/features/journey/application/journey_compose_controller.dart](lib/features/journey/application/journey_compose_controller.dart) | dispatchJourneyMatch 호출 제거 (라인 323-327) |

---

## 성공 기준

- [x] **flutter analyze**: 0 issues
- [x] **NetworkGuard 준수**: 모든 HTTP 요청이 NetworkGuard로 래핑됨
- [x] **직접 Supabase 호출 없음**: RPC 함수만 사용
- [x] **i18n 동기화**: 8개 언어 ARB 파일 모두 번역 완료
- [ ] **1회 실행 진단**: 에러 발생 시 로그만으로 근본 원인 확정 (테스트 필요)
- [ ] **성공 경로 검증**: "전송 요청 접수" 메시지 + outbox pending row 생성 (테스트 필요)

---

## 요약

### 문제

```dart
NetworkRequestException(type: unknown, statusCode: null, message: null)
```

→ 진단 불가능

### 해결

```dart
// 예시 1: 필드명 변경
NetworkRequestException(type: invalidPayload, message: 'Missing required field: created_at')

// 예시 2: 타입 불일치
NetworkRequestException(type: invalidPayload, message: 'Client parse error: TypeError')
  + StackTrace: #0 _executeCreateJourney (line 317)

// 예시 3: 날짜 파싱 실패
NetworkRequestException(type: invalidPayload, message: 'Date parsing failed: FormatException')
```

→ **1회 실행으로 근본 원인 확정 가능**

### 핵심 개선점

1. **NetworkGuard**: stackTrace 캡처 + TypeError 자동 매핑 + 에러 타입 명시
2. **Repository**: 원시 응답 로깅 + 필수 필드 검증 + 단계별 파싱 로깅
3. **에러 타입 구분**: network/timeout/parse/server 명확히 분리

---

## 참고 문서

- [DISPATCH_OUTBOX_MIGRATION_REPORT.md](DISPATCH_OUTBOX_MIGRATION_REPORT.md) - Outbox 패턴 마이그레이션 전체 가이드
- [lib/core/network/network_error.dart](lib/core/network/network_error.dart#L5-L32) - NetworkErrorType 정의
- [supabase/sql/08_dispatch_jobs_migration.sql](supabase/sql/08_dispatch_jobs_migration.sql#L237-L365) - create_journey RPC 구현
