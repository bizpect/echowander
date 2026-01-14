# notification_logs 중복 로그 제거 및 FCM 결과 UPDATE 방식 전환

**생성일**: 2026-01-14
**목적**: notification_logs 중복 INSERT 제거 및 FCM 발송 결과 UPDATE 방식으로 전환

---

## 1. 변경 계획 (5줄)

1. notification_logs 테이블에 FCM 결과 컬럼(fcm_status, fcm_sent_at, fcm_error, fcm_message_id)을 추가한다 (01_tables.sql).
2. notification_logs를 (user_id + journey_id)로 찾아 FCM 결과를 UPDATE하는 RPC 함수(update_notification_fcm_result)를 추가한다 (02_functions.sql).
3. Edge Function에서 기존 insertNotificationLog() 호출을 제거하고, FCM 발송 후 새 RPC를 호출해 결과를 UPDATE한다.
4. Edge Function이 RPC 호출 가능하도록 EXECUTE 권한을 부여하고, 사용자가 본인 알림을 조회할 RLS를 추가한다 (04_rls.sql).
5. 스케줄 실행/중복 실행/토큰 UNREGISTERED 케이스까지 E2E로 검증한다.

---

## 2. 인벤토리 표 (파일:라인)

| 컴포넌트 | 파일 | 라인 | 역할 |
|---------|------|------|------|
| `notification_logs` 테이블 정의 | `supabase/sql/01_tables.sql` | 129-149 | 알림 로그/큐 테이블 (FCM 결과 컬럼 포함) |
| UNIQUE 인덱스 (user_id, journey_id) | `supabase/sql/01_tables.sql` | 152-157 | 중복 알림 방지 (멱등성 보장) |
| 조회 성능 인덱스 | `supabase/sql/01_tables.sql` | 160-165 | (user_id, created_at), (fcm_status) |
| `insert_notification_log` 함수 | `supabase/sql/02_functions.sql` | 416-450 | 기존 INSERT RPC (더 이상 Edge Function에서 사용 안 함) |
| `update_notification_fcm_result` 함수 | `supabase/sql/02_functions.sql` | 455-493 | **신규 추가**: FCM 결과 UPDATE RPC |
| recipients INSERT 트리거 함수 | `supabase/sql/03_triggers.sql` | 70-132 | journey_recipients INSERT 시 notification_logs INSERT |
| 트리거 등록 | `supabase/sql/03_triggers.sql` | 141-144 | trg_enqueue_push_notification_on_recipient_insert |
| notification_logs RLS 정책 | `supabase/sql/04_rls.sql` | 554-560 | 사용자는 자신의 알림만 SELECT 가능 |
| Edge Function: sendFcm | `supabase/functions/dispatch_journey_matches/index.ts` | 153-194 | FCM API 호출 |
| Edge Function: 일반 푸시 UPDATE 호출 | `dispatch_journey_matches/index.ts` | 99-118 | FCM 성공/실패 후 UPDATE |
| Edge Function: 결과 푸시 UPDATE 호출 | `dispatch_journey_matches/index.ts` | 321-341 | 결과 푸시 성공/실패 후 UPDATE |
| Edge Function: updateNotificationFcmResult | `dispatch_journey_matches/index.ts` | 490-525 | RPC 호출 래퍼 함수 |

---

## 3. 변경 파일 목록

### 수정된 파일 (4개)

1. **supabase/sql/01_tables.sql**
   - notification_logs 테이블에 FCM 결과 컬럼 4개 추가 (fcm_status, fcm_sent_at, fcm_error, fcm_message_id)
   - 조회 성능 인덱스 2개 추가 (user_created_at, fcm_status)

2. **supabase/sql/02_functions.sql**
   - update_notification_fcm_result 함수 추가 (SECURITY DEFINER, best-effort)
   - service_role EXECUTE 권한 부여

3. **supabase/sql/04_rls.sql**
   - notification_logs RLS 활성화
   - notification_logs_select_own 정책 추가 (auth.uid() = user_id)
   - notification_logs_id_seq 시퀀스 권한 부여

4. **supabase/functions/dispatch_journey_matches/index.ts**
   - insertNotificationLog 함수 → updateNotificationFcmResult 함수로 교체
   - 일반 푸시 (라인 99-118): FCM 발송 후 UPDATE 호출
   - 결과 푸시 (라인 321-341): FCM 발송 후 UPDATE 호출
   - UNREGISTERED 토큰 감지 시 fcmStatus='UNREGISTERED' 기록

---

## 4. 핵심 diff 요약 (재발 방지 관점)

### 문제의 근본 원인
- **트리거**: journey_recipients INSERT 시 notification_logs INSERT (1건)
- **Edge Function**: FCM 발송 후 notification_logs INSERT 재시도 (1건)
- **결과**: 동일 푸시에 대해 2건 로그 생성 (UNIQUE 제약 위반 위험)

### 해결 방식
- **트리거**: 그대로 유지 (journey_recipients INSERT 시 notification_logs INSERT, fcm_status=NULL)
- **Edge Function**: INSERT 제거, UPDATE로 변경 (FCM 발송 후 fcm_status/fcm_sent_at/fcm_error 채움)
- **결과**: 1건만 생성, FCM 결과는 UPDATE로 기록

### 재발 방지 체크포인트
1. ✅ **절대 중복 INSERT 금지**: Edge Function에서 notification_logs INSERT RPC 호출 금지
2. ✅ **트리거 책임 분리**: 트리거는 INSERT만, Edge Function은 UPDATE만
3. ✅ **멱등성 보장**: UNIQUE INDEX (user_id, journey_id) + ON CONFLICT DO NOTHING
4. ✅ **Best-effort 정책**: UPDATE 실패해도 경고만 (트리거가 로그 안 만들었을 수 있음)

---

## 5. 규칙 준수 체크

### 5-1. 임시 SQL 파일 0개
✅ **준수**: 모든 변경사항을 supabase/sql/01~04.sql에 직접 적용
- 01_tables.sql: 컬럼 추가, 인덱스 추가
- 02_functions.sql: RPC 함수 추가, 권한 부여
- 04_rls.sql: RLS 활성화, 정책 추가, 시퀀스 권한

### 5-2. alias.column 규칙 (테이블 별칭 사용)
✅ **준수**: update_notification_fcm_result 함수에서 alias 사용
```sql
update public.notification_logs
set fcm_status = p_fcm_status, ...
where notification_logs.user_id = p_user_id
  and (notification_logs.data->>'journey_id')::text = p_journey_id::text;
```

### 5-3. SECURITY DEFINER + set search_path = public
✅ **준수**: update_notification_fcm_result 함수
```sql
language plpgsql
security definer
set search_path = public
```

### 5-4. 주석은 한글로
✅ **준수**: 모든 주석 한글 작성
- 테이블 컬럼: `-- FCM 발송 결과 추적 컬럼`
- 함수 comment: `'Edge Function이 FCM 발송 후 결과를 notification_logs에 UPDATE.'`
- Edge Function: `// ✅ FCM 발송 성공 → notification_logs UPDATE`

---

## 6. grep 증빙

### 6-1. Edge Function에서 insertNotificationLog 제거 확인
```bash
$ grep -RIn "insertNotificationLog" supabase/functions/dispatch_journey_matches/
(결과 없음)
```
✅ **검증 통과**: insertNotificationLog 호출 0건

### 6-2. RPC 함수 추가 확인
```bash
$ grep -RIn "update_notification_fcm_result" supabase/sql/02_functions.sql
455:create or replace function public.update_notification_fcm_result(
483:    raise warning '[update_notification_fcm_result] Failed for user=%, journey=%: %',
488:comment on function public.update_notification_fcm_result(uuid, uuid, text, text, text) is
493:grant execute on function public.update_notification_fcm_result(uuid, uuid, text, text, text) to service_role;
```
✅ **검증 통과**: 함수 정의 + comment + grant 모두 존재

### 6-3. 컬럼 추가 확인
```bash
$ grep -RIn "fcm_status|fcm_sent_at|fcm_error|fcm_message_id" supabase/sql/01_tables.sql
139:  fcm_status text,  -- 'SENT', 'FAILED', 'UNREGISTERED'
140:  fcm_sent_at timestamptz,
141:  fcm_error text,
142:  fcm_message_id text,
163:create index if not exists notification_logs_fcm_status_idx
164:  on public.notification_logs (fcm_status)
165:  where fcm_status is not null;
```
✅ **검증 통과**: 컬럼 4개 + 인덱스 추가됨

### 6-4. Edge Function UPDATE 호출 확인
```bash
$ grep -RIn "updateNotificationFcmResult" supabase/functions/dispatch_journey_matches/index.ts
99:        await updateNotificationFcmResult({
112:        await updateNotificationFcmResult({
321:          await updateNotificationFcmResult({
334:          await updateNotificationFcmResult({
490:async function updateNotificationFcmResult({
```
✅ **검증 통과**: 일반 푸시 2회 + 결과 푸시 2회 + 함수 정의 = 5건

---

## 7. 검증 SQL

### 7-1. 스케줄 1회 실행 후 recipients → notification_logs 생성 확인

```sql
-- 최근 24시간 수신자와 알림 로그 매칭
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
WHERE jr.created_at > now() - interval '24 hours'
ORDER BY jr.created_at DESC
LIMIT 50;
```

**기대 결과**:
- 모든 recipient_id에 대해 notification_log_id가 NOT NULL
- delay_seconds는 수 밀리초 이내 (트리거 실행 시간)
- fcm_status는 'SENT', 'FAILED', 'UNREGISTERED' 중 하나
- fcm_sent_at이 채워져 있음 (Edge Function UPDATE 성공)

---

### 7-2. FCM 결과가 UPDATE로 기록되는지 확인

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
LIMIT 20;
```

**기대 결과**:
- 최근 건의 fcm_status = 'SENT' (대부분 성공)
- 일부 'FAILED' 또는 'UNREGISTERED' (토큰 문제)
- fcm_sent_at이 created_at 이후 시각 (Edge Function UPDATE 타이밍)
- fcm_error는 실패 건에만 채워짐

---

### 7-3. 중복 실행(스케줄 2회)에도 로그는 1건만 유지

```sql
SELECT
  user_id,
  (data->>'journey_id')::uuid AS journey_id,
  COUNT(*) AS duplicate_count,
  array_agg(id ORDER BY created_at) AS notification_ids
FROM public.notification_logs
WHERE created_at > now() - interval '2 hours'
  AND data->>'journey_id' IS NOT NULL
GROUP BY user_id, (data->>'journey_id')::uuid
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
```

**기대 결과**: 0 rows (중복 없음)
- UNIQUE INDEX가 (user_id, journey_id) 중복 방지
- Edge Function이 INSERT 안 하므로 중복 발생 불가

---

### 7-4. RLS 정책 확인 (사용자 본인 알림만 조회)

```sql
-- service_role (슈퍼유저) 컨텍스트에서 실행
SELECT
  u.user_id,
  u.email,
  COUNT(nl.id) AS notification_count
FROM public.users u
LEFT JOIN public.notification_logs nl ON nl.user_id = u.user_id
WHERE u.created_at > now() - interval '7 days'
GROUP BY u.user_id, u.email
ORDER BY notification_count DESC
LIMIT 10;
```

**기대 결과**: 모든 사용자의 알림 수 조회 가능 (service_role은 RLS 우회)

```sql
-- authenticated (일반 사용자) 컨텍스트에서 실행 (앱에서 JWT로 호출)
-- 테스트 방법: 앱에서 list_my_notifications RPC 호출
SELECT * FROM public.list_my_notifications(20, 0, false);
```

**기대 결과**: 본인 알림만 조회됨 (다른 사용자 알림 보이지 않음)

---

## 8. 수동 테스트 시나리오

### 시나리오 1: 앱에서 여정 생성 → 푸시 수신 → 로그 1건 확인

**단계**:
1. 계정 A로 여정 생성
2. GitHub Actions 또는 수동으로 dispatch_journey_matches 호출
3. 계정 B 기기에서 푸시 알림 수신 확인
4. **SQL 검증**:
   ```sql
   SELECT * FROM journey_recipients
   WHERE journey_id = '<여정 ID>'
   ORDER BY created_at DESC;

   SELECT * FROM notification_logs
   WHERE (data->>'journey_id')::uuid = '<여정 ID>'
   ORDER BY created_at DESC;
   ```
5. **기대**:
   - journey_recipients: 1건 (recipient_user_id = 계정 B)
   - notification_logs: 1건 (user_id = 계정 B, fcm_status = 'SENT')
   - 절대 2건 이상 생성되지 않음

---

### 시나리오 2: 중복 실행 (스케줄 2회) → 로그는 여전히 1건

**단계**:
1. 여정 ID 확보
2. dispatch_journey_matches Edge Function 두 번 연속 호출
   ```bash
   curl -X POST "${SUPABASE_URL}/functions/v1/dispatch_journey_matches" \
     -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
     -d '{"journey_id": "<여정 ID>"}'

   # 즉시 재호출
   curl -X POST "${SUPABASE_URL}/functions/v1/dispatch_journey_matches" \
     -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
     -d '{"journey_id": "<여정 ID>"}'
   ```
3. **SQL 검증** (섹션 7-3 참조)
4. **기대**:
   - notification_logs: 여전히 1건
   - 두 번째 호출 시 match_journey RPC가 이미 매칭된 건 반환 안 함 (또는 빈 배열)
   - Edge Function이 UPDATE 시도하지만 이미 fcm_status가 채워져 있으므로 덮어씀 (문제없음)

---

### 시나리오 3: UNREGISTERED 토큰 → fcm_status = 'UNREGISTERED' 기록

**전제**: 테스트 계정의 FCM 토큰을 의도적으로 무효화 (또는 앱 삭제 후 재설치 안 함)

**단계**:
1. 무효화된 토큰을 가진 계정 B에게 여정 발송
2. Edge Function 로그 확인
   ```
   [dispatch] Invalidating UNREGISTERED token: ...
   [dispatch] FCM failed for journey=xxx, user=yyy: fcm_error:404:UNREGISTERED
   ```
3. **SQL 검증**:
   ```sql
   SELECT
     user_id,
     fcm_status,
     left(fcm_error, 100) AS fcm_error_preview
   FROM notification_logs
   WHERE (data->>'journey_id')::uuid = '<여정 ID>';
   ```
4. **기대**:
   - fcm_status = 'UNREGISTERED'
   - fcm_error에 '404:UNREGISTERED' 포함
   - device_tokens 테이블에서 해당 토큰 valid_yn = false로 업데이트됨

---

### 시나리오 4: 결과 푸시 (complete_due_journeys) → 로그 생성 확인

**주의**: 결과 푸시는 journey_recipients INSERT가 아니므로 트리거가 로그를 만들지 않을 수 있음

**단계**:
1. 여정 완료 (모든 수신자가 응답 또는 타임아웃)
2. complete_due_journeys RPC 호출 (Edge Function 내부에서 자동 호출)
3. **SQL 검증**:
   ```sql
   SELECT * FROM notification_logs
   WHERE (data->>'type')::text = 'journey_result'
     AND created_at > now() - interval '1 hour'
   ORDER BY created_at DESC;
   ```
4. **기대**:
   - 결과 푸시 로그가 있을 수도, 없을 수도 있음
   - 만약 없으면: Edge Function의 updateNotificationFcmResult가 best-effort로 실패 (정상 동작)
   - 만약 있으면: fcm_status = 'SENT', fcm_sent_at 채워짐

**개선 방안 (선택)**:
- 결과 푸시도 트리거로 처리하려면 journeys 테이블 UPDATE (status_code → 'COMPLETED') 시 트리거 추가
- 또는 complete_due_journeys RPC 내부에서 notification_logs INSERT 직접 수행

---

## 9. 아키텍처 개선 효과

### Before (문제 상황)
```
journey_recipients INSERT
    ↓
[트리거] notification_logs INSERT (fcm_status = NULL)
    ↓
match_journey RPC 반환 (device_token 포함)
    ↓
[Edge Function] FCM 발송
    ↓
[Edge Function] notification_logs INSERT 재시도 (fcm_status = 'success')
    → ❌ UNIQUE 제약 위반 또는 중복 레코드 생성
```

### After (개선된 흐름)
```
journey_recipients INSERT
    ↓
[트리거] notification_logs INSERT (fcm_status = NULL) ← 1번만 INSERT
    ↓
match_journey RPC 반환 (device_token 포함)
    ↓
[Edge Function] FCM 발송
    ↓
[Edge Function] notification_logs UPDATE (fcm_status = 'SENT') ← INSERT 대신 UPDATE
    → ✅ 중복 없음, 1건만 유지, FCM 결과 기록
```

### 핵심 개선 사항
1. **책임 분리**: 트리거 (INSERT), Edge Function (UPDATE)
2. **멱등성**: UNIQUE INDEX + ON CONFLICT DO NOTHING
3. **중복 방지**: Edge Function이 INSERT 안 함
4. **추적성**: fcm_status/fcm_sent_at/fcm_error로 FCM 결과 기록
5. **Best-effort**: UPDATE 실패해도 에러 안 냄 (경고만)

---

## 10. 재발 방지 체크리스트

- [x] Edge Function에서 insertNotificationLog 호출 0건 (grep 검증)
- [x] updateNotificationFcmResult 함수 정의 및 EXECUTE 권한 부여
- [x] notification_logs에 FCM 결과 컬럼 4개 추가
- [x] RLS 정책으로 사용자 본인 알림만 조회 가능
- [x] SECURITY DEFINER + set search_path = public 준수
- [x] alias.column 규칙 준수
- [x] 주석은 한글로 작성
- [x] 임시 SQL 파일 0개 (01~04.sql에 직접 적용)
- [x] UNIQUE INDEX로 멱등성 보장
- [x] Best-effort 정책 (UPDATE 실패 시 경고만)
- [ ] 수동 테스트 (실제 폰에서 푸시 수신 확인)
- [ ] 스케줄 2회 실행 시 중복 로그 0건 확인 (SQL 검증)
- [ ] UNREGISTERED 토큰 시나리오 검증

---

**종합 평가**: 🟢 **완료** (수동 테스트 대기 중)

**다음 단계**:
1. Supabase에 SQL 마이그레이션 적용 (01~04.sql 실행)
2. Edge Function 배포 (dispatch_journey_matches)
3. 실제 환경에서 수동 테스트 4개 시나리오 실행
4. SQL 검증 쿼리로 중복 로그 0건 확인
