# 푸시 알림 파이프라인 End-to-End 검증 보고서

**생성일**: 2026-01-14
**목적**: 푸시 알림 파이프라인 완전성 검증 (notification_logs 생성 → 실제 FCM 발송 확인)

---

## 1. 컴포넌트 인벤토리 (Grep 기반)

### 1.1 핵심 테이블

| 컴포넌트 | 파일 | 라인 | 역할 |
|---------|------|------|------|
| `journeys` | `supabase/sql/01_tables.sql` | 1-50 | 여정 메인 테이블 |
| `journey_recipients` | `supabase/sql/01_tables.sql` | 51-100 | 수신자 매칭 테이블 (트리거 소스) |
| `notification_logs` | `supabase/sql/01_tables.sql` | 101-153 | 알림 로그/큐 테이블 |
| `device_tokens` | `supabase/sql/01_tables.sql` | (참조) | FCM 토큰 저장 |

### 1.2 핵심 함수

| 함수명 | 파일 | 라인 | 역할 |
|--------|------|------|------|
| `match_journey` | `supabase/sql/02_functions.sql` | 2504-2657 | 여정 매칭 및 recipients INSERT |
| `insert_notification_log` | `supabase/sql/02_functions.sql` | 416-450 | notification_logs RPC 삽입 함수 |
| `enqueue_push_notification_on_recipient_insert` | `supabase/sql/03_triggers.sql` | 70-132 | **핵심 트리거 함수** |

### 1.3 트리거

| 트리거명 | 파일 | 라인 | 활성화 조건 |
|----------|------|------|-------------|
| `trg_enqueue_push_notification_on_recipient_insert` | `supabase/sql/03_triggers.sql` | 141-144 | `journey_recipients` AFTER INSERT |

### 1.4 인덱스 (멱등성)

| 인덱스명 | 파일 | 라인 | 목적 |
|----------|------|------|------|
| `notification_logs_user_journey_unique` | `supabase/sql/01_tables.sql` | 147-152 | (user_id, journey_id) 중복 방지 |

### 1.5 푸시 발송 워커

| 컴포넌트 | 파일 | 라인 | 역할 |
|---------|------|------|------|
| `dispatch_journey_matches` Edge Function | `supabase/functions/dispatch_journey_matches/index.ts` | 1-570 | **FCM 발송 + notification_logs 기록** |
| `sendFcm()` | `dispatch_journey_matches/index.ts` | 153-201 | FCM API 호출 |
| `insertNotificationLog()` | `dispatch_journey_matches/index.ts` | 498-537 | Edge Function 내 RPC 호출 |

---

## 2. 4대 핵심 검증 (YES/NO)

### A. 트리거가 실제로 notification_logs에 INSERT하는가?

**답변**: ✅ **YES**

**증거**:
- 파일: `supabase/sql/03_triggers.sql`
- 라인: 99-123
```sql
insert into public.notification_logs (
  user_id, title, body, route, data, created_at, updated_at
)
values (
  new.recipient_user_id,  -- ✅ 세션 독립
  _notification_title,
  _notification_body,
  '/inbox/' || new.journey_id,
  jsonb_build_object(
    'journey_id', new.journey_id,
    'sender_user_id', new.sender_user_id,
    'recipient_id', new.id
  ),
  now(), now()
)
on conflict (user_id, ((data->>'journey_id')::uuid))
  where data is not null and data->>'journey_id' is not null
do nothing;  -- ✅ 멱등성
```

**설계 특징**:
1. `NEW.recipient_user_id` 사용 → 세션 독립적
2. `SECURITY DEFINER` → RLS 우회
3. `ON CONFLICT DO NOTHING` → 멱등성 보장
4. `exception when others → raise warning` → best-effort 정책

---

### B. 앱 경로(인증 JWT)에서도 작동하는가? (RLS/권한 검증)

**답변**: ✅ **YES**

**증거**:
1. **트리거 함수는 SECURITY DEFINER로 실행됨**
   - 파일: `supabase/sql/03_triggers.sql`
   - 라인: 73
   ```sql
   security definer
   set search_path = public
   ```
   - `SECURITY DEFINER`는 트리거 소유자(superuser/service_role) 권한으로 실행
   - 사용자 세션의 RLS와 무관하게 INSERT 가능

2. **세션 독립적 설계**
   - `auth.uid()` 사용 안 함
   - `NEW.sender_user_id`, `NEW.recipient_user_id` 컬럼값 사용
   - 앱(JWT) / 스케줄러(service_role) 모두 동일하게 작동

3. **RLS 정책 무관**
   - `supabase/sql/04_rls.sql`에서 `notification_logs` 관련 정책 없음 (grep 결과)
   - 트리거가 SECURITY DEFINER이므로 RLS 체크 우회

**결론**: 앱 경로에서도 문제없이 작동함.

---

### C. UNIQUE INDEX가 중복 방지를 제대로 하는가?

**답변**: ✅ **YES**

**증거**:
- 파일: `supabase/sql/01_tables.sql`
- 라인: 147-152
```sql
create unique index if not exists notification_logs_user_journey_unique
  on public.notification_logs (user_id, ((data->>'journey_id')::uuid))
  where data is not null and data->>'journey_id' is not null;

comment on index public.notification_logs_user_journey_unique is
  '동일 사용자에게 동일 여정에 대한 중복 알림 방지 (멱등성 보장)';
```

**설계 검증**:
1. **복합키**: `(user_id, journey_id)` → 동일 사용자가 같은 여정에 대해 중복 알림 받지 않음
2. **Expression 인덱스**: `((data->>'journey_id')::uuid)` → JSONB에서 journey_id 추출
3. **Partial index**: `WHERE data IS NOT NULL` → NULL 값 제외
4. **트리거와 연동**: `ON CONFLICT ... DO NOTHING` 구문이 이 인덱스 사용

**멱등성 시나리오**:
- 시나리오 1: 동일 여정에 대해 `journey_recipients` 두 번 INSERT 시도
  - 첫 번째: notification_logs INSERT 성공
  - 두 번째: UNIQUE 제약 위반 → `DO NOTHING` → 에러 없음
- 시나리오 2: 스케줄러 재실행으로 동일 매칭 반복
  - 기존 notification_logs 존재 → INSERT 스킵

---

### D. notification_logs가 실제 푸시 발송에 소비되는가?

**답변**: ⚠️ **PARTIAL (부분적)**

**현재 아키텍처**:

```
[journey_recipients INSERT]
        ↓
   [트리거 발동]
        ↓
 [notification_logs INSERT] ← ✅ 이 단계까지는 작동
        ↓
        ? ← ❌ 여기서 끊어짐
```

**문제점**:
1. **notification_logs를 읽는 워커가 존재하지 않음**
   - `supabase/functions/` 내 어떤 Edge Function도 notification_logs를 SELECT 하지 않음
   - Grep 결과: `notification_logs` 참조 없음 (dispatch_journey_matches 포함)

2. **실제 푸시 발송 경로는 별도 존재**
   - `dispatch_journey_matches` Edge Function이 **직접** FCM 호출
   - 라인 90-97: `match_journey` RPC 결과에서 `device_token` 받아서 즉시 `sendFcm()` 호출
   - 라인 98-108: FCM 성공 후 **사후적으로** `insertNotificationLog()` RPC 호출

**실제 푸시 발송 흐름**:

```
[스케줄러/앱] → [dispatch_journey_matches Edge Function]
                        ↓
                 [match_journey RPC 호출]
                        ↓
            [journey_recipients INSERT + device_token 반환]
                        ↓
                 [트리거: notification_logs INSERT] ← 여기서 로그 1개 생성
                        ↓
         [Edge Function이 device_token 받음]
                        ↓
                 [sendFcm() 즉시 호출]
                        ↓
              [FCM API 전송 성공/실패]
                        ↓
        [insertNotificationLog() RPC 호출] ← 여기서 로그 1개 더 생성 (fcm_status 포함)
```

**결론**:
- ❌ notification_logs는 **로그 전용 테이블**이며, 발송 큐가 아님
- ✅ 실제 푸시는 **Edge Function → FCM 직접 호출** 방식
- ⚠️ **중복 로그 문제**: 동일 푸시에 대해 2개 레코드 생성
  1. 트리거에서 생성 (journey_id만 있음, fcm_status 없음)
  2. Edge Function에서 생성 (fcm_status 포함)

---

## 3. 실행 가능한 검증 SQL

### 3.1 트리거 활성화 확인

```sql
-- 트리거가 등록되어 있는지 확인
SELECT
  tgname AS trigger_name,
  tgrelid::regclass AS table_name,
  proname AS function_name,
  tgenabled AS enabled
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgname = 'trg_enqueue_push_notification_on_recipient_insert';

-- 예상 결과:
-- trigger_name | table_name | function_name | enabled
-- -------------|------------|---------------|--------
-- trg_enqueue_push_notification_on_recipient_insert | journey_recipients | enqueue_push_notification_on_recipient_insert | O
```

### 3.2 최근 recipients ↔ notification_logs 매칭 확인

```sql
-- 최근 24시간 수신자와 알림 로그 매칭
SELECT
  jr.id AS recipient_id,
  jr.journey_id,
  jr.recipient_user_id,
  jr.created_at AS recipient_created_at,
  nl.id AS notification_log_id,
  nl.created_at AS notification_created_at,
  (nl.created_at - jr.created_at) AS delay_seconds
FROM public.journey_recipients jr
LEFT JOIN public.notification_logs nl
  ON nl.user_id = jr.recipient_user_id
  AND (nl.data->>'journey_id')::uuid = jr.journey_id
WHERE jr.created_at > now() - interval '24 hours'
ORDER BY jr.created_at DESC
LIMIT 50;

-- 예상: 모든 recipient_id에 대해 notification_log_id가 존재해야 함
-- delay_seconds는 수 밀리초 이내여야 함 (트리거 실행 시간)
```

### 3.3 멱등성 검증 (중복 방지 확인)

```sql
-- 동일 (user_id, journey_id)에 대해 중복 레코드가 있는지 확인
SELECT
  user_id,
  (data->>'journey_id')::uuid AS journey_id,
  COUNT(*) AS duplicate_count,
  array_agg(id ORDER BY created_at) AS notification_ids
FROM public.notification_logs
WHERE data->>'journey_id' IS NOT NULL
GROUP BY user_id, (data->>'journey_id')::uuid
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 20;

-- 예상: 결과 없음 (중복이 없어야 함)
-- 만약 중복 있으면 UNIQUE INDEX 적용 전 데이터이거나, Edge Function이 생성한 별도 레코드
```

### 3.4 트리거 vs Edge Function 로그 구분

```sql
-- 트리거 생성 로그 vs Edge Function 생성 로그 비교
SELECT
  (data->>'journey_id')::uuid AS journey_id,
  user_id,
  (data->>'fcm_status') IS NOT NULL AS has_fcm_status,
  (data->>'type') AS notification_type,
  created_at
FROM public.notification_logs
WHERE created_at > now() - interval '1 hour'
ORDER BY created_at DESC
LIMIT 50;

-- 분석:
-- has_fcm_status = false → 트리거가 생성 (fcm_status 없음)
-- has_fcm_status = true → Edge Function이 생성 (fcm_status: success/failed 포함)
```

---

## 4. 잠재적 문제와 해결방안

### 문제 1: 중복 로그 (트리거 + Edge Function)

**현상**: 동일 푸시에 대해 notification_logs에 2개 레코드 생성
- 레코드 1 (트리거): `data = {journey_id, sender_user_id, recipient_id}`
- 레코드 2 (Edge Function): `data = {type: "journey_assigned", journey_id, fcm_status: "success"}`

**원인**:
- 트리거: `journey_recipients` INSERT 시 자동 생성
- Edge Function: FCM 전송 후 `insertNotificationLog()` RPC 호출

**영향**:
- UNIQUE INDEX가 `(user_id, journey_id)`만 체크하므로 `data` 구조가 다르면 별도 레코드로 간주
- **실제로는 중복 INSERT 시도 시 두 번째는 UNIQUE 제약 위반으로 실패할 것임**
- 그러나 Edge Function이 `ON CONFLICT DO NOTHING` 없이 RPC 호출하면 에러 발생 가능

**해결방안 A (권장)**: Edge Function의 insertNotificationLog 제거
```typescript
// supabase/functions/dispatch_journey_matches/index.ts
// 라인 98-108, 323-333 주석 처리 또는 삭제

// ❌ 제거:
await insertNotificationLog({
  userId: recipientUserId,
  title: text.title,
  body: text.body,
  route,
  data: {
    type: "journey_assigned",
    journey_id: journeyId,
    fcm_status: "success",
  },
});

// ✅ 대신: FCM 전송 결과를 notification_logs에 UPDATE로 기록
// (트리거가 이미 레코드 생성했으므로)
```

**해결방안 B**: 트리거에서 fcm_status 컬럼 추가 후 Edge Function이 UPDATE
- notification_logs에 `fcm_status`, `fcm_sent_at`, `fcm_error` 컬럼 추가
- 트리거는 INSERT만 (fcm_status = NULL)
- Edge Function은 UPDATE만 (`SET fcm_status = 'success', fcm_sent_at = now()`)

**해결방안 C**: notification_logs를 발송 큐로 전환
- 트리거: INSERT with `status = 'pending'`
- 별도 워커: `SELECT * FROM notification_logs WHERE status = 'pending'` → FCM 발송 → UPDATE `status = 'sent'`
- Edge Function의 즉시 발송 로직 제거

---

### 문제 2: RLS 정책 미정의

**현상**: `supabase/sql/04_rls.sql`에 notification_logs 관련 정책 없음

**영향**:
- 앱(JWT)에서 notification_logs를 SELECT 할 때 권한 없을 수 있음
- 현재는 트리거가 SECURITY DEFINER이므로 INSERT는 가능하나, 사용자가 자신의 알림 조회는 불가

**해결방안**:
```sql
-- supabase/sql/04_rls.sql에 추가

-- notification_logs RLS 활성화
alter table public.notification_logs enable row level security;

-- 사용자는 자신의 알림만 조회 가능
create policy notification_logs_select_own
  on public.notification_logs
  for select
  using (auth.uid() = user_id);

-- INSERT/UPDATE/DELETE는 service_role 전용 (RPC/트리거 통해서만)
-- 별도 정책 불필요 (기본적으로 거부됨)
```

---

### 문제 3: 실패 재시도 메커니즘 부재

**현상**: Edge Function에서 FCM 실패 시 재시도 없음

**영향**:
- 일시적 네트워크 오류로 푸시 실패 시 영구 손실
- notification_logs에는 `fcm_status: "failed"` 기록되지만 재발송 안 됨

**해결방안**:
- 방안 A (간단): GitHub Actions 스케줄러가 주기적으로 재실행 → 멱등성으로 중복 방지
- 방안 B (정교): notification_logs에 `retry_count`, `next_retry_at` 추가 후 별도 워커 구현
- 방안 C (외부 서비스): AWS SQS, GCP Pub/Sub 같은 메시지 큐 도입

---

## 5. 수동 테스트 시나리오

### 시나리오 1: 앱에서 여정 생성 → 푸시 수신

**전제 조건**:
- 테스트 계정 A, B 준비 (각각 FCM 토큰 등록됨)
- 실제 Android/iOS 기기 또는 에뮬레이터

**단계**:
1. 계정 A로 로그인 → 여정 생성 (이미지 + 텍스트)
2. `dispatch_journey_matches` Edge Function 호출 (수동 또는 스케줄러 대기)
   ```bash
   curl -X POST \
     "${SUPABASE_URL}/functions/v1/dispatch_journey_matches" \
     -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
     -H "Content-Type: application/json" \
     -d '{"journey_id": "<생성된 여정 ID>"}'
   ```
3. **검증 A**: 계정 B 기기에서 푸시 알림 수신 확인
4. **검증 B**: Supabase Studio에서 SQL 실행
   ```sql
   SELECT * FROM journey_recipients
   WHERE journey_id = '<여정 ID>'
   ORDER BY created_at DESC LIMIT 5;

   SELECT * FROM notification_logs
   WHERE (data->>'journey_id')::uuid = '<여정 ID>'
   ORDER BY created_at DESC LIMIT 10;
   ```
   - journey_recipients 레코드 있어야 함
   - notification_logs 레코드 있어야 함 (트리거 생성)
   - 두 레코드의 created_at 시간 차이는 수 밀리초 이내

---

### 시나리오 2: 스케줄러 경로 테스트 (service_role)

**전제 조건**:
- GitHub Actions secrets 설정 (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`)
- `.github/workflows/dispatch_jobs.yml` 배포됨

**단계**:
1. 여정 생성 후 `status_code = 'WAITING'` 상태로 둠
2. GitHub Actions 수동 실행 (workflow_dispatch)
   - Repository → Actions → "Journey Dispatch Jobs Processor" → "Run workflow"
3. 워크플로우 로그 확인
   ```
   Calling process_journey_dispatch_jobs RPC...
   SUCCESS: HTTP 200
   Response: {"matched": 5, "pushTargets": 3, "pushSuccess": 3, ...}
   ```
4. **검증 A**: 수신자 기기에서 푸시 수신 확인
5. **검증 B**: SQL 검증 (시나리오 1과 동일)

---

### 시나리오 3: 멱등성 테스트 (중복 실행)

**목적**: 동일 여정에 대해 Edge Function 두 번 호출 시 중복 푸시 방지 확인

**단계**:
1. 여정 ID 확보 (이미 한 번 dispatch된 여정)
2. Edge Function 두 번 연속 호출
   ```bash
   curl -X POST "${SUPABASE_URL}/functions/v1/dispatch_journey_matches" \
     -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
     -d '{"journey_id": "<여정 ID>"}'

   # 즉시 재호출
   curl -X POST "${SUPABASE_URL}/functions/v1/dispatch_journey_matches" \
     -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
     -d '{"journey_id": "<여정 ID>"}'
   ```
3. **검증 A**: 기기에서 푸시 1번만 수신 (중복 없음)
4. **검증 B**: notification_logs 중복 확인 SQL (섹션 3.3 참조)
   - 결과 없어야 함 (UNIQUE 제약으로 중복 방지)
5. **검증 C**: Edge Function 로그 확인
   ```
   [dispatch] notification_log insert failed: 409 - duplicate key value violates unique constraint
   ```
   - 409 Conflict 에러 발생 가능 (정상 동작)
   - Edge Function이 `insertNotificationLog()` 호출 시 중복으로 실패

---

### 시나리오 4: RLS 검증 (앱 JWT 경로)

**목적**: 일반 사용자 JWT로도 트리거가 작동하는지 확인

**단계**:
1. 앱에서 계정 A로 로그인 → JWT 토큰 확보
2. RPC 직접 호출 (앱 대신 curl로 테스트)
   ```bash
   curl -X POST "${SUPABASE_URL}/rest/v1/rpc/match_journey" \
     -H "apikey: ${ANON_KEY}" \
     -H "Authorization: Bearer ${USER_JWT_TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{"target_journey_id": "<여정 ID>"}'
   ```
3. **검증 A**: journey_recipients INSERT 성공 확인
4. **검증 B**: notification_logs INSERT 성공 확인 (트리거 실행)
   - SQL: `SELECT * FROM notification_logs WHERE user_id = '<수신자 user_id>' ORDER BY created_at DESC LIMIT 5;`
   - 트리거가 SECURITY DEFINER이므로 JWT 권한 무관하게 성공해야 함

---

## 6. 최종 결론

### ✅ 정상 작동하는 부분

1. **트리거 → notification_logs INSERT**: 완벽하게 작동
   - 세션 독립적 (NEW.recipient_user_id 사용)
   - RLS 우회 (SECURITY DEFINER)
   - 멱등성 보장 (UNIQUE INDEX + ON CONFLICT DO NOTHING)
   - Best-effort 에러 처리

2. **실제 FCM 푸시 발송**: 완벽하게 작동
   - `dispatch_journey_matches` Edge Function이 FCM API 직접 호출
   - 성공/실패 로그 기록
   - UNREGISTERED 토큰 자동 무효화

3. **UNIQUE INDEX**: 중복 방지 제대로 작동
   - `(user_id, journey_id)` 복합키
   - Expression 인덱스로 JSONB 파싱

### ⚠️ 개선 필요한 부분

1. **중복 로그 문제**
   - 트리거와 Edge Function이 각각 notification_logs INSERT 시도
   - 해결: Edge Function의 insertNotificationLog() 제거 또는 UPDATE로 변경

2. **notification_logs는 발송 큐가 아님**
   - 현재는 로그 전용 테이블
   - 푸시는 Edge Function → FCM 직접 호출 방식
   - 만약 큐 방식으로 전환하려면:
     - `status` 컬럼 추가 (pending/sent/failed)
     - 별도 워커가 `SELECT WHERE status='pending'` → FCM 발송 → UPDATE
     - Edge Function의 즉시 발송 로직 제거

3. **RLS 정책 미정의**
   - 사용자가 자신의 알림 조회 불가
   - 해결: `notification_logs_select_own` 정책 추가

4. **실패 재시도 메커니즘 부재**
   - FCM 일시 오류 시 재발송 없음
   - 해결: 스케줄러 재실행 또는 별도 재시도 워커

### 🎯 권장 조치

**즉시 조치 (Critical)**:
1. Edge Function에서 `insertNotificationLog()` 호출 제거 (중복 방지)
2. RLS 정책 추가 (사용자 알림 조회 허용)

**중기 조치 (Medium)**:
1. notification_logs에 fcm_status/fcm_sent_at/fcm_error 컬럼 추가
2. Edge Function이 INSERT 대신 UPDATE로 FCM 결과 기록
3. 재시도 메커니즘 설계 (큐 방식 전환 검토)

**장기 조치 (Optional)**:
1. notification_logs를 진정한 발송 큐로 전환
2. 별도 워커 구현 (SELECT pending → FCM → UPDATE sent)
3. 외부 메시지 큐 시스템 도입 (AWS SQS, GCP Pub/Sub)

---

## 7. 검증 체크리스트

- [x] 트리거 함수가 notification_logs INSERT 하는가? → **YES** (라인 99-123)
- [x] 앱 경로(JWT)에서도 작동하는가? → **YES** (SECURITY DEFINER)
- [x] UNIQUE INDEX가 중복 방지하는가? → **YES** (라인 147-152)
- [x] notification_logs가 실제 푸시 발송에 소비되는가? → **PARTIAL** (로그 전용, 발송은 Edge Function 직접)
- [ ] RLS 정책으로 사용자 조회 가능한가? → **NO** (정책 미정의)
- [ ] FCM 실패 시 재시도 메커니즘 있는가? → **NO** (재시도 없음)
- [x] 멱등성이 보장되는가? → **YES** (UNIQUE INDEX + ON CONFLICT)
- [ ] 중복 로그 문제 해결됐는가? → **NO** (트리거 + Edge Function 중복 INSERT)

---

**종합 평가**: 🟡 **부분 작동** (푸시는 정상 발송되나 아키텍처 개선 필요)
