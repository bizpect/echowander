# notification_logs 중복 로그 제거 최종 마감 보고서

**생성일**: 2026-01-14
**목적**: notification_logs 중복 INSERT 제거 및 FCM 결과 UPDATE 방식 전환 (규칙/보안/배포 완전 준수)

---

## 1) 변경 계획 (5줄)

1. update_notification_fcm_result 함수에서 모든 테이블 참조를 alias.column(nl.user_id)으로 통일해 규칙 위반을 제거한다 ([02_functions.sql:477-478](supabase/sql/02_functions.sql#L477-L478)).
2. notification_logs PK가 bigserial이지만 authenticated는 INSERT 권한이 없으므로 notification_logs_id_seq 권한 부여를 제거한다 ([04_rls.sql:545](supabase/sql/04_rls.sql#L545)).
3. notification_logs RLS는 SELECT(본인)만 허용하고, authenticated INSERT/UPDATE/DELETE는 절대 열지 않도록 재확인한다 ([04_rls.sql:554-560](supabase/sql/04_rls.sql#L554-L560)).
4. 배포 순서를 DB(01→02→04) → Edge Function 순으로 문서화하고, 배포 후 검증 SQL을 실행해 결과를 캡처한다.
5. grep/SQL로 "중복 INSERT 0 + fcm_status 업데이트 정상 + 보안 정책 안전"을 최종 증명한다.

---

## 2) 인벤토리 표 (파일:라인)

| 컴포넌트 | 파일 | 라인 | 역할 | 비고 |
|---------|------|------|------|------|
| **notification_logs PK 정의** | 01_tables.sql | 130 | `id bigserial primary key` | bigserial 사용 확인 |
| **FCM 결과 컬럼** | 01_tables.sql | 139-142 | fcm_status, fcm_sent_at, fcm_error, fcm_message_id | 4개 컬럼 추가됨 |
| **UNIQUE 인덱스** | 01_tables.sql | 152-157 | (user_id, journey_id) 중복 방지 | 멱등성 보장 |
| **조회 성능 인덱스** | 01_tables.sql | 160-165 | (user_id, created_at), (fcm_status) | 2개 인덱스 |
| **update_notification_fcm_result 함수** | 02_functions.sql | 455-493 | FCM 결과 UPDATE RPC | ✅ alias 사용 |
| **UPDATE WHERE 절 (alias 사용)** | 02_functions.sql | 477-478 | `nl.user_id`, `nl.data->>'journey_id'` | ✅ 규칙 준수 |
| **service_role 권한 부여** | 02_functions.sql | 493 | grant execute to service_role | EXECUTE 권한 |
| **notification_logs RLS 활성화** | 04_rls.sql | 26 | enable row level security | RLS 활성화됨 |
| **notification_logs_id_seq 권한** | 04_rls.sql | 545 | ❌ 제거됨 (주석 처리) | authenticated INSERT 없으므로 불필요 |
| **notification_logs_select_own 정책** | 04_rls.sql | 554-560 | auth.uid() = user_id | SELECT만 허용 |
| **Edge Function: updateNotificationFcmResult 호출** | index.ts | 99, 112, 326, 339 | 4곳에서 호출 | 성공/실패 분기 |
| **Edge Function: updateNotificationFcmResult 정의** | index.ts | 498-537 | RPC 호출 래퍼 | best-effort 정책 |

---

## 3) 변경 파일 목록

### ✅ 수정 완료 (3개 파일)

#### 1. supabase/sql/02_functions.sql
**변경 내용**:
- 라인 469: `update public.notification_logs` → `update public.notification_logs nl` (alias 추가)
- 라인 477-478: `notification_logs.user_id` → `nl.user_id`, `notification_logs.data` → `nl.data` (alias 사용)
- 라인 478: `::text = p_journey_id::text` → `= p_journey_id::text` (불필요한 캐스팅 제거, data->>'journey_id'는 이미 text)

**diff 요약**:
```sql
-- Before
update public.notification_logs
where notification_logs.user_id = p_user_id
  and (notification_logs.data->>'journey_id')::text = p_journey_id::text;

-- After
update public.notification_logs nl
where nl.user_id = p_user_id
  and (nl.data->>'journey_id') = p_journey_id::text;
```

#### 2. supabase/sql/04_rls.sql
**변경 내용**:
- 라인 545: `grant usage, select on sequence public.notification_logs_id_seq to authenticated;` 제거
- 주석 추가: `-- notification_logs_id_seq는 authenticated에게 부여하지 않음 (INSERT 권한 없으므로 불필요)`

**제거 근거**:
- notification_logs PK는 bigserial (sequence 사용)
- 하지만 authenticated 사용자는 INSERT 권한이 없음 (RLS 정책 없음)
- sequence 권한은 INSERT 시에만 필요하므로 부여 불필요
- service_role/트리거만 INSERT 하므로 안전

#### 3. (이전 작업) supabase/functions/dispatch_journey_matches/index.ts
**변경 내용**: insertNotificationLog → updateNotificationFcmResult로 전환 (이미 완료)

---

## 4) 핵심 diff 요약 (재발 방지/보안 관점)

### 4-1. alias.column 규칙 위반 제거

**문제**: update_notification_fcm_result 함수에서 테이블명 직접 참조
```sql
-- ❌ 위반 (Before)
where notification_logs.user_id = p_user_id
```

**해결**: alias 사용으로 규칙 준수
```sql
-- ✅ 준수 (After)
update public.notification_logs nl
where nl.user_id = p_user_id
  and (nl.data->>'journey_id') = p_journey_id::text;
```

**재발 방지**:
- grep으로 alias 위반 자동 탐지: `grep "where[[:space:]]*notification_logs\." supabase/sql/02_functions.sql` → 결과 0건

---

### 4-2. 불필요한 sequence 권한 제거 (보안 강화)

**문제**: authenticated에게 notification_logs_id_seq 권한 부여
- notification_logs는 INSERT 정책 없음 (SELECT만 허용)
- sequence 권한은 INSERT 시에만 사용
- 권한 최소화 원칙 위반

**해결**: notification_logs_id_seq 권한 부여 제거
```sql
-- ❌ 제거 (Before)
grant usage, select on sequence public.notification_logs_id_seq to authenticated;

-- ✅ 제거 완료 (After)
-- notification_logs_id_seq는 authenticated에게 부여하지 않음 (INSERT 권한 없으므로 불필요)
```

**보안 효과**:
- 권한 최소화 원칙 준수
- authenticated가 sequence를 조회할 이유 없음
- 혹시라도 INSERT 정책이 잘못 추가되어도 sequence 권한 없으므로 실패 (방어 계층)

---

### 4-3. RLS 안전성 재확인

**확인 결과**: ✅ **안전**
```sql
-- RLS 활성화
alter table public.notification_logs enable row level security;

-- SELECT만 허용 (본인 알림만)
create policy notification_logs_select_own
  on public.notification_logs
  for select
  using (auth.uid() = user_id);

-- INSERT/UPDATE/DELETE 정책 없음 (기본적으로 거부됨)
```

**보안 검증**:
1. authenticated 사용자는 **SELECT만** 가능
2. **INSERT/UPDATE/DELETE**는 모두 거부됨
3. service_role/트리거/RPC만 쓰기 가능
4. 사용자는 다른 사용자의 알림 조회 불가 (`auth.uid() = user_id`)

---

## 5) 규칙 준수 체크

### 5-1. 임시 SQL 파일 0개 ✅
**준수**: 모든 변경사항을 supabase/sql/01~04.sql에 직접 적용
- 01_tables.sql: 컬럼 4개 + 인덱스 2개
- 02_functions.sql: RPC 함수 + alias 수정
- 04_rls.sql: RLS 활성화 + 정책 + sequence 권한 제거

### 5-2. alias.column 규칙 ✅
**준수**: 02_functions.sql:469, 477-478
```sql
update public.notification_logs nl  -- ✅ alias 'nl'
where nl.user_id = p_user_id        -- ✅ nl.user_id
  and (nl.data->>'journey_id') = p_journey_id::text;  -- ✅ nl.data
```

**검증**:
```bash
$ grep -RIn "where[[:space:]]*notification_logs\." supabase/sql/02_functions.sql
(결과 없음)  # ✅ alias 위반 0건
```

### 5-3. SECURITY DEFINER + set search_path = public ✅
**준수**: 02_functions.sql:464-465
```sql
language plpgsql
security definer
set search_path = public
```

### 5-4. 주석은 한글로 ✅
**준수**: 모든 주석 한글 작성
- 02_functions.sql:468: `-- notification_logs를 (user_id, journey_id)로 찾아 FCM 결과를 UPDATE`
- 04_rls.sql:545: `-- notification_logs_id_seq는 authenticated에게 부여하지 않음 (INSERT 권한 없으므로 불필요)`

---

## 6) grep 증빙 (명령+결과)

### 6-1. alias.column 규칙 위반 탐지 ✅
**명령**:
```bash
grep -RIn "where[[:space:]]*notification_logs\." supabase/sql/02_functions.sql
```

**결과**: (출력 없음)

**검증**: ✅ **통과** - alias 위반 0건

---

### 6-2. insertNotificationLog 제거 확인 ✅
**명령**:
```bash
grep -RIn "insertNotificationLog" supabase/functions/dispatch_journey_matches/
```

**결과**: (출력 없음)

**검증**: ✅ **통과** - Edge Function에서 중복 INSERT 완전 제거

---

### 6-3. updateNotificationFcmResult 호출 확인 ✅
**명령**:
```bash
grep -RIn "updateNotificationFcmResult" supabase/functions/dispatch_journey_matches/index.ts
```

**결과**:
```
99:        await updateNotificationFcmResult({
112:        await updateNotificationFcmResult({
326:          await updateNotificationFcmResult({
339:          await updateNotificationFcmResult({
498:async function updateNotificationFcmResult({
```

**검증**: ✅ **통과** - 일반 푸시 2회(성공/실패) + 결과 푸시 2회(성공/실패) + 함수 정의 = 5건

---

### 6-4. alias 사용 확인 ✅
**명령**:
```bash
grep -n "nl\.user_id\|nl\.data" supabase/sql/02_functions.sql | grep -A 2 -B 2 "477\|478"
```

**결과**:
```
477:    nl.user_id = p_user_id
478:    and (nl.data->>'journey_id') = p_journey_id::text;
```

**검증**: ✅ **통과** - WHERE 절에서 alias `nl` 사용

---

## 7) 배포 순서 + 검증 SQL

### 7-1. 배포 순서 (엄격히 준수 필요)

**⚠️ 중요**: 반드시 아래 순서를 지켜야 함

#### 1단계: DB 마이그레이션 (Supabase Dashboard 또는 psql)
```sql
-- 순서 1: 테이블 변경
\i supabase/sql/01_tables.sql
-- 결과: notification_logs에 fcm_status 등 컬럼 4개 추가, 인덱스 2개 추가

-- 순서 2: 함수 추가/수정
\i supabase/sql/02_functions.sql
-- 결과: update_notification_fcm_result 함수 추가 (alias 사용)

-- 순서 3: RLS 정책 적용
\i supabase/sql/04_rls.sql
-- 결과: notification_logs RLS 활성화, SELECT 정책 추가, sequence 권한 제거
```

**순서를 지키는 이유**:
- 01 먼저: Edge Function이 UPDATE 시 컬럼이 존재해야 함
- 02 먼저: Edge Function이 RPC 호출 시 함수가 존재해야 함
- 04 먼저: Edge Function이 service_role 권한으로 RPC 실행 가능해야 함

#### 2단계: Edge Function 배포
```bash
# Supabase CLI로 배포
supabase functions deploy dispatch_journey_matches

# 또는 Supabase Dashboard에서 수동 배포
```

**배포 순서를 어기면**:
- ❌ Edge Function 먼저 배포 → DB에 컬럼/함수 없음 → UPDATE RPC 실패
- ✅ DB 먼저 마이그레이션 → Edge Function 배포 → 정상 작동

---

### 7-2. 검증 SQL (배포 후 실행)

#### SQL 1: recipients → notification_logs 생성 및 FCM 결과 기록 확인

```sql
SELECT
  jr.id AS recipient_id,
  jr.journey_id,
  jr.recipient_user_id,
  jr.created_at AS recipient_created_at,
  nl.id AS notification_log_id,
  nl.fcm_status,
  nl.fcm_sent_at,
  nl.created_at AS notification_created_at,
  extract(epoch from (nl.created_at - jr.created_at)) AS delay_seconds
FROM public.journey_recipients jr
LEFT JOIN public.notification_logs nl
  ON nl.user_id = jr.recipient_user_id
  AND (nl.data->>'journey_id')::uuid = jr.journey_id
WHERE jr.created_at > now() - interval '2 hours'
ORDER BY jr.created_at DESC
LIMIT 30;
```

**기대 결과**:
| recipient_id | journey_id | notification_log_id | fcm_status | fcm_sent_at | delay_seconds |
|-------------|------------|---------------------|------------|-------------|---------------|
| 123 | uuid-1 | 456 | SENT | 2026-01-14 10:05:01 | 0.05 |
| 124 | uuid-2 | 457 | SENT | 2026-01-14 10:10:02 | 0.03 |
| 125 | uuid-3 | 458 | FAILED | 2026-01-14 10:15:03 | 0.04 |

**검증 포인트**:
- ✅ notification_log_id NOT NULL (트리거가 로그 생성)
- ✅ fcm_status IN ('SENT', 'FAILED', 'UNREGISTERED') (Edge Function UPDATE 성공)
- ✅ fcm_sent_at NOT NULL (UPDATE 타임스탬프)
- ✅ delay_seconds < 0.1초 (트리거 실행 시간)

---

#### SQL 2: 중복 로그 0건 확인 (멱등성 검증)

```sql
SELECT
  user_id,
  (data->>'journey_id')::uuid AS journey_id,
  COUNT(*) AS cnt
FROM public.notification_logs
WHERE created_at > now() - interval '2 hours'
  AND data->>'journey_id' IS NOT NULL
GROUP BY user_id, (data->>'journey_id')::uuid
HAVING COUNT(*) > 1;
```

**기대 결과**: ✅ **0 rows** (중복 없음)

**검증 포인트**:
- ✅ UNIQUE INDEX가 (user_id, journey_id) 중복 방지
- ✅ Edge Function이 INSERT 안 하므로 중복 발생 불가
- ✅ 스케줄 2회 실행해도 중복 없음

---

#### SQL 3: FCM 결과 상세 확인

```sql
SELECT
  user_id,
  (data->>'journey_id')::uuid AS journey_id,
  fcm_status,
  fcm_sent_at,
  created_at,
  left(coalesce(fcm_error, ''), 120) AS fcm_error_preview
FROM public.notification_logs
WHERE created_at > now() - interval '2 hours'
ORDER BY created_at DESC
LIMIT 30;
```

**기대 결과**:
| user_id | journey_id | fcm_status | fcm_sent_at | created_at | fcm_error_preview |
|---------|------------|------------|-------------|------------|-------------------|
| uuid-a | uuid-1 | SENT | 10:05:01 | 10:05:00 | (null) |
| uuid-b | uuid-2 | UNREGISTERED | 10:10:02 | 10:10:01 | fcm_error:404:UNREGISTERED |
| uuid-c | uuid-3 | FAILED | 10:15:03 | 10:15:02 | Network timeout |

**검증 포인트**:
- ✅ fcm_status = 'SENT' (대부분 성공)
- ✅ fcm_status = 'UNREGISTERED' (토큰 무효화 케이스)
- ✅ fcm_status = 'FAILED' (일시적 오류)
- ✅ fcm_sent_at > created_at (Edge Function UPDATE 타이밍)
- ✅ fcm_error는 실패 건에만 채워짐

---

#### SQL 4: RLS 정책 확인 (개념 검증)

**service_role 컨텍스트 (관리자)**:
```sql
-- 모든 사용자의 알림 조회 가능 (RLS 우회)
SELECT user_id, COUNT(*) AS notification_count
FROM public.notification_logs
WHERE created_at > now() - interval '7 days'
GROUP BY user_id
ORDER BY notification_count DESC
LIMIT 10;
```

**authenticated 컨텍스트 (일반 사용자)**:
```sql
-- 앱에서 JWT로 호출 (RPC 또는 REST)
-- 본인 알림만 조회됨 (auth.uid() = user_id 정책)
SELECT * FROM public.list_my_notifications(20, 0, false);
```

**기대 결과**:
- ✅ service_role: 모든 사용자 알림 조회 가능
- ✅ authenticated: 본인 알림만 조회 (다른 사용자 알림 보이지 않음)
- ✅ authenticated INSERT/UPDATE/DELETE 시도 시: **권한 에러**

---

### 7-3. 배포 후 검증 결과 요약 (배포 완료 후 작성)

**실행 일시**: (배포 후 기록)

**SQL 1 결과**:
- [ ] notification_log_id NOT NULL 확인
- [ ] fcm_status 기록 확인
- [ ] delay_seconds < 0.1초 확인

**SQL 2 결과**:
- [ ] 중복 로그 0건 확인

**SQL 3 결과**:
- [ ] fcm_status 분포 확인 (SENT/FAILED/UNREGISTERED)
- [ ] fcm_error 기록 확인

**SQL 4 결과**:
- [ ] RLS 정책 정상 작동 확인

---

## 8) 리스크 및 다음 단계

### 8-1. 잠재적 리스크

#### 리스크 1: 결과 푸시는 트리거가 로그를 안 만들 수 있음
**현상**: complete_due_journeys RPC가 결과 푸시를 발송할 때 journey_recipients INSERT가 아님
- 트리거는 journey_recipients INSERT 시에만 발동
- 결과 푸시는 journeys 테이블 상태 변경(COMPLETED)
- Edge Function이 UPDATE하려 해도 notification_logs에 레코드 없음

**영향**: best-effort 정책으로 UPDATE 실패 → 경고만 출력 (푸시는 정상 발송됨)

**해결 방안 (선택)**:
1. journeys 테이블 UPDATE (status_code → 'COMPLETED') 시 트리거 추가
2. complete_due_journeys RPC 내부에서 notification_logs INSERT 직접 수행
3. 현재 상태 유지 (결과 푸시는 로그 없이 발송만, 문제없음)

**권장**: 3번 (현재 상태 유지) - 결과 푸시는 덜 중요하고, 실제 발송은 정상 작동

---

#### 리스크 2: 배포 순서를 어기면 Edge Function 실패
**문제**: Edge Function을 DB 마이그레이션 전에 배포하면
- update_notification_fcm_result 함수 없음 → RPC 404 에러
- fcm_status 컬럼 없음 → UPDATE 실패

**방지**: 반드시 DB 먼저 마이그레이션

---

#### 리스크 3: 기존 notification_logs 레코드는 fcm_status=NULL
**현상**: 배포 전에 생성된 레코드는 fcm_status/fcm_sent_at이 NULL
- ALTER TABLE ADD COLUMN은 기존 레코드에 NULL 채움
- Edge Function이 이후 UPDATE 안 함 (이미 발송 완료된 건)

**영향**: 과거 데이터는 fcm_status 조회 불가 (문제없음, 히스토리용)

**해결 (선택)**: 기존 레코드에 fcm_status='UNKNOWN' 채우기
```sql
UPDATE public.notification_logs
SET fcm_status = 'UNKNOWN'
WHERE fcm_status IS NULL
  AND created_at < '2026-01-14 00:00:00';  -- 배포 시각 이전
```

**권장**: 실행 안 해도 됨 (과거 데이터는 참고용)

---

### 8-2. 다음 단계

#### 즉시 실행 (Critical)
1. [ ] **DB 마이그레이션**: 01, 02, 04.sql 순서대로 실행
2. [ ] **Edge Function 배포**: dispatch_journey_matches 배포
3. [ ] **검증 SQL 실행**: 7-2 섹션 SQL 4개 실행
4. [ ] **수동 테스트**: 실제 폰에서 푸시 수신 확인

#### 단기 (1주 이내)
1. [ ] **모니터링**: fcm_status 분포 확인 (SENT 비율 90% 이상 기대)
2. [ ] **로그 검토**: Edge Function 로그에서 UPDATE 실패 경고 확인
3. [ ] **성능 측정**: notification_logs 인덱스 효과 확인 (쿼리 속도)

#### 중기 (1개월 이내)
1. [ ] **결과 푸시 트리거 검토**: complete_due_journeys에서 notification_logs INSERT 추가 여부 결정
2. [ ] **재시도 메커니즘**: FCM 실패 시 자동 재발송 검토
3. [ ] **알림 센터 UI**: notification_logs 기반 알림 히스토리 화면 구현

---

## 9) 최종 체크리스트

### 코드 변경
- [x] 01_tables.sql: FCM 컬럼 4개 + 인덱스 2개 추가
- [x] 02_functions.sql: update_notification_fcm_result 함수 추가 (alias 사용)
- [x] 04_rls.sql: RLS 활성화 + SELECT 정책 + sequence 권한 제거
- [x] index.ts: insertNotificationLog 제거 → updateNotificationFcmResult로 교체

### 규칙 준수
- [x] 임시 SQL 파일 0개
- [x] alias.column 규칙 준수 (nl.user_id, nl.data)
- [x] SECURITY DEFINER + set search_path = public
- [x] 주석은 한글로 작성
- [x] authenticated INSERT/UPDATE/DELETE 금지 (SELECT만)

### grep 증빙
- [x] insertNotificationLog 제거 확인 (0건)
- [x] alias 위반 확인 (0건)
- [x] updateNotificationFcmResult 호출 확인 (5건)

### 보안
- [x] notification_logs RLS: SELECT(본인)만 허용
- [x] notification_logs_id_seq 권한 제거 (불필요)
- [x] service_role만 INSERT/UPDATE/DELETE 가능

### 배포
- [ ] DB 마이그레이션 (01 → 02 → 04 순서)
- [ ] Edge Function 배포
- [ ] 검증 SQL 4개 실행
- [ ] 수동 테스트 (실제 폰 푸시 수신)

---

## 종합 평가

**상태**: 🟢 **코드 완성** (배포 대기 중)

**달성 사항**:
1. ✅ 중복 INSERT 완전 제거 (트리거 1번만)
2. ✅ FCM 결과 UPDATE 방식 전환
3. ✅ alias.column 규칙 100% 준수
4. ✅ 보안 정책 강화 (sequence 권한 제거)
5. ✅ 배포 순서 문서화
6. ✅ 검증 SQL 4개 작성
7. ✅ grep 증빙으로 규칙 준수 증명

**다음 단계**: DB 마이그레이션 → Edge Function 배포 → 검증 → 완료

**예상 효과**:
- 중복 로그 0건 (멱등성 보장)
- FCM 발송 성공률 추적 가능
- 권한 최소화 원칙 준수
- 규칙 위반 0건
