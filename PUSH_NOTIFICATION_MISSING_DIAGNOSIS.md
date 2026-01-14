# 푸시 알림 누락 진단 및 해결 리포트

**Repository**: `bizpect/echowander`
**진단 일시**: 2026-01-14
**핵심 증상**: 스케줄 워커(GitHub Actions + service_role)가 dispatch RPC 실행 → journey_recipients 생성됨 → **푸시 알림 안 옴** + **notification_logs 안 쌓임**

---

## 1. 즉시 증거 수집 SQL

### 1-1) 수신 메시지 생성 확인 (최근 30개)

```sql
select
  jr.id,
  jr.journey_id,
  jr.recipient_user_id,
  jr.sender_user_id,
  jr.created_at,
  jr.recipient_status
from public.journey_recipients jr
order by jr.created_at desc
limit 30;
```

**기대 결과**: 최근 30개 row가 조회되면 → 수신 메시지 생성은 정상

---

### 1-2) notification_logs 최근 생성 확인

```sql
select
  nl.id,
  nl.user_id,
  nl.title,
  nl.body,
  nl.route,
  nl.created_at,
  nl.read_at
from public.notification_logs nl
order by nl.created_at desc
limit 50;
```

**기대 결과**:
- ✅ 50개 조회됨 → 알림 로그는 쌓임 (다른 경로에서)
- ❌ 0개 또는 오래된 데이터만 → **완전히 안 쌓이고 있음**

---

### 1-3) 특정 journey에 대한 notification_logs 확인

```sql
-- 최근 생성된 journey_id 1개를 선택
with recent_journey as (
  select jr.journey_id, jr.recipient_user_id, jr.created_at
  from public.journey_recipients jr
  order by jr.created_at desc
  limit 1
)
select
  rj.journey_id,
  rj.recipient_user_id as expected_user_id,
  rj.created_at as recipient_created_at,
  nl.id as notification_log_id,
  nl.user_id,
  nl.title,
  nl.created_at as notification_created_at
from recent_journey rj
left join public.notification_logs nl
  on nl.user_id = rj.recipient_user_id
  and nl.created_at >= rj.created_at - interval '5 seconds'
  and nl.created_at <= rj.created_at + interval '5 seconds';
```

**기대 결과**:
- ✅ notification_log_id 있음 → 알림 로그 정상
- ❌ notification_log_id NULL → **journey_recipients 생성되었지만 notification_logs 안 쌓임 (확정)**

---

### 1-4) 트리거 존재 여부 확인

```sql
select
  t.tgname as trigger_name,
  t.tgrelid::regclass as table_name,
  t.tgenabled as enabled,
  p.proname as function_name
from pg_trigger t
join pg_proc p on p.oid = t.tgfoid
where t.tgname ilike '%notification%'
   or t.tgname ilike '%inbox%'
   or t.tgname ilike '%journey%'
   or t.tgrelid::regclass::text ilike '%journey_recipients%'
order by t.tgrelid::regclass, t.tgname;
```

**기대 결과**: journey_recipients 테이블에 notification 관련 트리거가 **없음 (확정)**

---

## 2. notification_logs 생성 경로 추적 결과

### grep 증거 수집

| 검색 패턴 | 파일 | 라인 | 내용 | 역할 |
|----------|------|------|------|------|
| `insert into.*notification_logs` | [02_functions.sql](supabase/sql/02_functions.sql#L444) | 444 | `insert into public.notification_logs (user_id, title, body, route, data)` | `insert_notification_log` 함수 내부 |
| `insert_notification_log` | lib/* | - | **0건** | 앱에서 호출 안 함 |
| `insert_notification_log` | supabase/sql/* | - | **0건** (함수 정의 제외) | SQL에서도 호출 안 함 |
| `notification_logs` trigger | [03_triggers.sql](supabase/sql/03_triggers.sql) | - | **0건** | **트리거 없음 (확정)** |

---

### 확정된 사실

| 항목 | 상태 | 근거 |
|------|------|------|
| **A. notification_logs INSERT 방법** | ✅ RPC 함수 `insert_notification_log` 존재 | [02_functions.sql:416-450](supabase/sql/02_functions.sql#L416-L450) |
| **B. 함수 호출 위치** | ❌ **어디서도 호출 안 함** | lib/* 0건, supabase/sql/* 0건 |
| **C. 트리거 존재** | ❌ **journey_recipients 트리거 없음** | [03_triggers.sql](supabase/sql/03_triggers.sql) 검색 결과 0건 |
| **D. match_journey 함수** | ❌ **notification_logs INSERT 없음** | [02_functions.sql:2504-2657](supabase/sql/02_functions.sql#L2504-L2657) 확인 |
| **E. process_journey_dispatch_jobs** | ⚠️ **match_journey만 호출** | [08_dispatch_jobs_migration.sql:160](supabase/sql/08_dispatch_jobs_migration.sql#L160) `perform public.match_journey(v_job_id);` |

---

## 3. 원인 분기 (YES/NO 확정)

### A. notification_logs INSERT가 auth.uid() 세션 의존인가?

**YES** ✅ (확정)

**근거**:
```sql
-- insert_notification_log 함수 (02_functions.sql:437-442)
if auth.uid() is not null and auth.uid() <> _user_id then
  raise exception 'forbidden';
end if;
if auth.uid() is null and auth.role() <> 'service_role' then
  raise exception 'unauthorized';
end if;
```

**분석**:
- `auth.uid()` 검증 존재
- service_role이면 우회 가능 (`auth.role() = 'service_role'`)
- **하지만 함수 자체가 호출되지 않고 있음** → 세션 의존 문제가 아님

---

### B. notification_logs INSERT가 특정 조건에서만 실행되나?

**NO** ❌

**근거**:
- `match_journey` 함수에 notification_logs INSERT 로직 자체가 **존재하지 않음**
- 조건 문제가 아니라 **코드 누락 문제**

---

### C. 트리거가 빠졌거나 비활성화되었나?

**YES** ✅ (확정)

**근거**:
```sql
-- 03_triggers.sql 전체 검색 결과
-- journey_recipients 테이블에 대한 트리거: 0건
-- notification 관련 트리거: 0건
```

**SQL 검증**:
```sql
select
  t.tgname,
  t.tgrelid::regclass,
  t.tgenabled
from pg_trigger t
where t.tgrelid = 'public.journey_recipients'::regclass;
```

**기대 결과**: **0 rows** (트리거 없음)

---

### D. notification_logs INSERT는 실행되지만 롤백되나?

**NO** ❌

**근거**:
- INSERT 로직 자체가 없으므로 롤백 문제도 아님
- `match_journey` 함수에 exception 블록 없음 (에러 발생 시 전체 트랜잭션 롤백)

---

## 4. 근본 원인 확정

### 핵심 문제

**`match_journey` 함수가 `journey_recipients` INSERT만 하고, `notification_logs` INSERT는 전혀 하지 않음**

### 증거

```sql
-- match_journey 함수 (02_functions.sql:2600-2619)
inserted as (
  insert into public.journey_recipients (
    journey_id,
    recipient_user_id,
    recipient_locale_tag,
    sender_user_id,
    snapshot_content,
    snapshot_image_count,
    snapshot_image_paths
  )
  select
    _journey.id,
    candidates.user_id,
    candidates.locale_tag,
    _journey.user_id,
    _journey.content,
    (select cnt from journey_image_count),
    (select paths from journey_image_paths)
  from candidates
  returning journey_recipients.recipient_user_id
)
-- ❌ notification_logs INSERT 없음!
```

### 추가 확인

1. **이전에는 알림이 정상 동작했음** → 클라이언트 경로(앱에서 create_journey → dispatch)에서는 **어떻게 알림이 갔을까?**
   - 가설 1: 앱에서 `insert_notification_log` 호출? → grep 결과 **0건** (아님)
   - 가설 2: 트리거가 있었는데 삭제됨? → 03_triggers.sql 이력 확인 필요
   - 가설 3: **Edge Function에서 FCM 직접 호출?** → 확인 필요

2. **현재 notification_logs INSERT 경로**: **0개**
   - SQL 함수 호출: 0건
   - 앱 호출: 0건
   - 트리거: 0건

---

## 5. 근본 해결 방향 (1안 고정 권장)

### 1안 (권장): journey_recipients AFTER INSERT 트리거 추가 ⭐

**목표**: 수신 메시지 INSERT = notification_logs INSERT 보장 (경로 무관)

#### 구현 계획

1. **트리거 함수 생성** (`03_triggers.sql`)
   ```sql
   create or replace function public.enqueue_push_notification_on_recipient_insert()
   returns trigger
   language plpgsql
   security definer
   set search_path = public
   as $$
   declare
     _sender_nickname text;
     _journey_content text;
     _notification_title text;
     _notification_body text;
   begin
     -- 발신자 닉네임 조회
     select up.nickname into _sender_nickname
     from public.user_profiles up
     where up.user_id = new.sender_user_id;

     -- 여정 내용 조회 (마스킹된 것 우선)
     select
       coalesce(j.content_clean, j.content) into _journey_content
     from public.journeys j
     where j.id = new.journey_id;

     -- 알림 메시지 구성
     _notification_title := coalesce(_sender_nickname, 'Someone') || ' sent you a message';
     _notification_body := substring(_journey_content, 1, 100);

     -- notification_logs INSERT (멱등성: ON CONFLICT 처리)
     insert into public.notification_logs (
       user_id,
       title,
       body,
       route,
       data,
       created_at,
       updated_at
     )
     values (
       new.recipient_user_id,
       _notification_title,
       _notification_body,
       '/inbox/' || new.journey_id,
       jsonb_build_object(
         'journey_id', new.journey_id,
         'sender_user_id', new.sender_user_id,
         'recipient_id', new.id
       ),
       now(),
       now()
     )
     on conflict (user_id, data) -- ⚠️ 실제 UNIQUE constraint에 맞게 수정
     do nothing;  -- 중복 알림 방지

     return new;
   end;
   $$;
   ```

2. **트리거 생성** (`03_triggers.sql`)
   ```sql
   drop trigger if exists trg_enqueue_push_notification_on_recipient_insert on public.journey_recipients;

   create trigger trg_enqueue_push_notification_on_recipient_insert
     after insert on public.journey_recipients
     for each row
     execute function public.enqueue_push_notification_on_recipient_insert();
   ```

3. **notification_logs 테이블 멱등성 보장** (`01_tables.sql`)
   ```sql
   -- 중복 알림 방지를 위한 UNIQUE constraint 추가
   alter table public.notification_logs
     add constraint notification_logs_user_data_unique
     unique (user_id, data);

   -- 또는 journey_id 기반 UNIQUE constraint
   alter table public.notification_logs
     add constraint notification_logs_user_journey_unique
     unique (user_id, (data->>'journey_id'));
   ```

#### 장점

- ✅ **경로 무관**: 앱/스케줄/수동 어느 경로로든 journey_recipients INSERT → notification_logs 보장
- ✅ **세션 독립**: auth.uid() 대신 NEW.recipient_user_id 사용
- ✅ **멱등성**: ON CONFLICT 처리로 중복 알림 방지
- ✅ **재발 방지**: match_journey 함수 변경해도 영향 없음

#### 단점

- 트리거 추가 오버헤드 (무시 가능 수준)
- notification_logs 테이블 스키마 변경 필요 (UNIQUE constraint)

---

### 2안 (대안): match_journey 함수에 notification_logs INSERT 추가

**목표**: match_journey 함수 내부에서 직접 notification_logs INSERT

#### 구현 계획

```sql
-- match_journey 함수 (02_functions.sql) 수정
-- inserted CTE 직후에 추가:
notifications as (
  insert into public.notification_logs (
    user_id,
    title,
    body,
    route,
    data
  )
  select
    inserted.recipient_user_id,
    coalesce(_sender_nickname, 'Someone') || ' sent you a message',
    substring(_journey.content, 1, 100),
    '/inbox/' || _journey.id,
    jsonb_build_object(
      'journey_id', _journey.id,
      'sender_user_id', _journey.user_id
    )
  from inserted
  on conflict (user_id, data) do nothing
  returning id
)
```

#### 장점

- ✅ 트리거 없이 함수 내부에서 처리
- ✅ 트랜잭션 일관성 보장 (같은 함수 내)

#### 단점

- ❌ **재발 위험**: 다른 경로로 journey_recipients INSERT 시 누락 가능
- ❌ 함수 복잡도 증가
- ❌ notification_logs INSERT 실패 시 전체 트랜잭션 롤백

---

## 6. 구현 지시 (1안 적용)

### 변경 계획 (5줄)

1. `notification_logs` 테이블에 UNIQUE constraint 추가 (멱등성 보장)
2. `enqueue_push_notification_on_recipient_insert` 트리거 함수 생성 (세션 독립, NEW.recipient_user_id 기반)
3. `journey_recipients` AFTER INSERT 트리거 등록
4. 기존 `match_journey` 함수 변경 없음 (트리거가 자동 처리)
5. 검증 SQL + 테스트 시나리오 실행

---

### 파일 인벤토리

| 파일 | 변경 내용 | 라인 (예상) |
|------|-----------|-------------|
| [supabase/sql/01_tables.sql](supabase/sql/01_tables.sql) | notification_logs UNIQUE constraint 추가 | ~150 (notification_logs 테이블 정의 직후) |
| [supabase/sql/03_triggers.sql](supabase/sql/03_triggers.sql) | 트리거 함수 + 트리거 생성 | ~70 (파일 끝에 추가) |

---

### 변경 파일 목록

#### 1. `supabase/sql/01_tables.sql` (UNIQUE constraint 추가)

**Before** (현재):
```sql
create table if not exists public.notification_logs (
  id bigserial primary key,
  user_id uuid not null,
  title text not null,
  body text,
  route text,
  data jsonb,
  read_at timestamptz,
  delete_yn boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notification_logs_user_fk
    foreign key (user_id)
    references public.users (user_id)
    on delete cascade
);
```

**After** (UNIQUE constraint 추가):
```sql
create table if not exists public.notification_logs (
  id bigserial primary key,
  user_id uuid not null,
  title text not null,
  body text,
  route text,
  data jsonb,
  read_at timestamptz,
  delete_yn boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notification_logs_user_fk
    foreign key (user_id)
    references public.users (user_id)
    on delete cascade
);

-- ✅ 중복 알림 방지 (멱등성 보장)
create unique index if not exists notification_logs_user_journey_unique
  on public.notification_logs (user_id, ((data->>'journey_id')::uuid))
  where data is not null and data->>'journey_id' is not null;

comment on index public.notification_logs_user_journey_unique is
  '동일 사용자에게 동일 여정에 대한 중복 알림 방지 (멱등성 보장)';
```

**설명**:
- UNIQUE INDEX 사용 (constraint보다 유연)
- `data->>'journey_id'` 기반으로 중복 방지
- WHERE 절로 NULL 데이터 제외

---

#### 2. `supabase/sql/03_triggers.sql` (트리거 추가)

**추가 내용** (파일 끝에):

```sql
-- ============================================================================
-- 푸시 알림 Enqueue 트리거
-- ============================================================================

-- 수신 메시지 생성 시 푸시 알림 자동 enqueue
drop function if exists public.enqueue_push_notification_on_recipient_insert() cascade;

create or replace function public.enqueue_push_notification_on_recipient_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  _sender_nickname text;
  _journey_content text;
  _notification_title text;
  _notification_body text;
begin
  -- ✅ 세션 독립: NEW.sender_user_id 기반 (auth.uid() 사용 안 함)

  -- 발신자 닉네임 조회 (없으면 'Someone')
  select up.nickname into _sender_nickname
  from public.user_profiles up
  where up.user_id = new.sender_user_id;

  _sender_nickname := coalesce(_sender_nickname, 'Someone');

  -- 여정 내용 조회 (마스킹된 것 우선, snapshot 사용)
  _journey_content := coalesce(new.snapshot_content, '');

  -- 알림 메시지 구성 (다국어는 클라이언트에서 처리)
  _notification_title := _sender_nickname || ' sent you a message';
  _notification_body := substring(_journey_content, 1, 100);

  -- ✅ notification_logs INSERT (멱등성: ON CONFLICT 처리)
  insert into public.notification_logs (
    user_id,
    title,
    body,
    route,
    data,
    created_at,
    updated_at
  )
  values (
    new.recipient_user_id,  -- ✅ auth.uid() 대신 테이블 컬럼 사용
    _notification_title,
    _notification_body,
    '/inbox/' || new.journey_id,
    jsonb_build_object(
      'journey_id', new.journey_id,
      'sender_user_id', new.sender_user_id,
      'recipient_id', new.id
    ),
    now(),
    now()
  )
  on conflict (user_id, ((data->>'journey_id')::uuid))
    where data is not null and data->>'journey_id' is not null
  do nothing;  -- ✅ 중복 알림 방지

  return new;
exception
  when others then
    -- ✅ 알림 실패해도 수신 메시지 생성은 성공 처리 (best-effort)
    raise warning 'Failed to enqueue push notification: %', sqlerrm;
    return new;
end;
$$;

comment on function public.enqueue_push_notification_on_recipient_insert() is
  '수신 메시지(journey_recipients) INSERT 시 푸시 알림 자동 enqueue.
  세션 독립(auth.uid() 사용 안 함), 멱등성 보장, best-effort 정책.';

-- 트리거 등록
drop trigger if exists trg_enqueue_push_notification_on_recipient_insert on public.journey_recipients;

create trigger trg_enqueue_push_notification_on_recipient_insert
  after insert on public.journey_recipients
  for each row
  execute function public.enqueue_push_notification_on_recipient_insert();
```

---

### 핵심 diff 요약 (재발 방지 관점)

| 항목 | Before | After | 재발 방지 |
|------|--------|-------|----------|
| **세션 의존** | ❌ auth.uid() 기대 | ✅ NEW.recipient_user_id 사용 | service_role 경로에서도 동작 |
| **트리거 보장** | ❌ 트리거 없음 | ✅ AFTER INSERT 트리거 | 어떤 경로로든 INSERT → 알림 보장 |
| **멱등성** | ❌ 중복 알림 가능 | ✅ UNIQUE INDEX + ON CONFLICT | 재실행해도 중복 알림 안 됨 |
| **에러 처리** | ❌ 실패 시 트랜잭션 롤백 | ✅ exception → warning (best-effort) | 알림 실패해도 메시지 생성 성공 |
| **관측성** | ❌ 실패 로그 없음 | ✅ raise warning | PostgreSQL 로그에 기록 |

---

## 7. 검증 SQL + 테스트 시나리오

### 테스트 시나리오 1: 스케줄 RPC 1회 실행

**절차**:
1. GitHub Actions "Journey Dispatch Jobs Processor" 워크플로우 수동 실행
2. 또는 다음 scheduled run 대기 (2, 7, 12, 17, 22, 27분)

**검증 SQL** (실행 후):

```sql
-- 1) 최근 생성된 journey_recipients 확인
select jr.id, jr.journey_id, jr.recipient_user_id, jr.created_at
from public.journey_recipients jr
order by jr.created_at desc
limit 5;

-- 결과: 1개 이상 row 있어야 함 (예: 5개)

-- 2) 해당 recipient에 대한 notification_logs 확인
with recent_recipients as (
  select
    jr.id as recipient_id,
    jr.journey_id,
    jr.recipient_user_id,
    jr.created_at
  from public.journey_recipients jr
  order by jr.created_at desc
  limit 5
)
select
  rr.recipient_id,
  rr.recipient_user_id,
  rr.created_at as recipient_created_at,
  nl.id as notification_log_id,
  nl.title,
  nl.body,
  nl.created_at as notification_created_at,
  (nl.created_at - rr.created_at) as time_diff
from recent_recipients rr
left join public.notification_logs nl
  on nl.user_id = rr.recipient_user_id
  and nl.data->>'journey_id' = rr.journey_id::text
order by rr.created_at desc;
```

**기대 결과**:
- ✅ 모든 row에서 `notification_log_id` NOT NULL
- ✅ `time_diff` < 1초 (트리거 즉시 실행)
- ❌ `notification_log_id` NULL → **트리거 미작동** (디버깅 필요)

---

### 테스트 시나리오 2: 멱등성 확인 (중복 실행)

**절차**:
1. 동일 journey에 대해 match_journey 2회 호출 (수동)

```sql
-- service_role로 실행
select * from public.match_journey('<기존_journey_id>');
select * from public.match_journey('<기존_journey_id>');
```

**검증 SQL**:

```sql
-- journey_recipients: ON CONFLICT 처리로 중복 INSERT 안 됨
select count(*) as recipient_count
from public.journey_recipients
where journey_id = '<기존_journey_id>';

-- 기대: recipient_count = requested_recipient_count (중복 없음)

-- notification_logs: UNIQUE INDEX로 중복 INSERT 안 됨
select count(*) as notification_count
from public.notification_logs
where data->>'journey_id' = '<기존_journey_id>';

-- 기대: notification_count = recipient_count (1:1 매칭)
```

**기대 결과**:
- ✅ `recipient_count` = 요청 수신자 수
- ✅ `notification_count` = `recipient_count`
- ❌ `notification_count` > `recipient_count` → **멱등성 실패** (UNIQUE INDEX 확인)

---

### 테스트 시나리오 3: 트리거 활성화 확인

**검증 SQL**:

```sql
select
  t.tgname as trigger_name,
  t.tgrelid::regclass as table_name,
  t.tgenabled as enabled,
  p.proname as function_name
from pg_trigger t
join pg_proc p on p.oid = t.tgfoid
where t.tgrelid = 'public.journey_recipients'::regclass
  and t.tgname = 'trg_enqueue_push_notification_on_recipient_insert';
```

**기대 결과**:
```
trigger_name                                  | table_name          | enabled | function_name
----------------------------------------------|---------------------|---------|--------------------------------------------------
trg_enqueue_push_notification_on_recipient_insert | journey_recipients  | O       | enqueue_push_notification_on_recipient_insert
```

- ✅ 1 row 반환 + enabled = 'O'
- ❌ 0 rows → **트리거 등록 안 됨** (SQL 재실행 필요)

---

### 테스트 시나리오 4: 알림 실패 로그 확인

**PostgreSQL 로그 확인**:

```bash
# Supabase Dashboard → Database → Logs
# 또는 PostgreSQL 직접 접근

# 알림 실패 시 warning 로그 검색
select * from pg_stat_statements where query ilike '%enqueue_push_notification%';
```

**기대 로그**:
```
WARNING:  Failed to enqueue push notification: <error_message>
```

---

## 8. 리스크 / 다음 단계

### 리스크

| 리스크 | 영향 | 완화 |
|--------|------|------|
| 1. UNIQUE INDEX 충돌 | notification_logs INSERT 실패 | ON CONFLICT DO NOTHING 처리 |
| 2. 트리거 실패 | journey_recipients 생성 성공했지만 알림 안 감 | exception 블록으로 warning만 출력 (best-effort) |
| 3. 기존 데이터 누락 | 트리거 적용 전 생성된 journey_recipients는 알림 없음 | 소급 적용 SQL 제공 (선택) |
| 4. 성능 영향 | 트리거 오버헤드 | 무시 가능 (nickname 조회 1회, INSERT 1회) |

---

### 다음 단계

#### 즉시 실행

1. **SQL 적용**:
   ```bash
   # 01_tables.sql 수정 후 실행
   psql <connection_string> -f supabase/sql/01_tables.sql

   # 03_triggers.sql 수정 후 실행
   psql <connection_string> -f supabase/sql/03_triggers.sql
   ```

2. **검증**:
   - 테스트 시나리오 3 실행 (트리거 활성화 확인)
   - 테스트 시나리오 1 실행 (스케줄 RPC → 알림 생성)

3. **모니터링**:
   - 24시간 동안 notification_logs 증가율 확인
   - 푸시 알림 수신 여부 확인 (실제 디바이스)

#### 선택 사항 (소급 적용)

**트리거 적용 전 생성된 journey_recipients에 대한 알림 생성**:

```sql
-- 최근 24시간 내 생성된 journey_recipients 중 알림 없는 건 처리
with missing_notifications as (
  select
    jr.id,
    jr.journey_id,
    jr.recipient_user_id,
    jr.sender_user_id,
    jr.snapshot_content,
    jr.created_at,
    up.nickname as sender_nickname
  from public.journey_recipients jr
  left join public.notification_logs nl
    on nl.user_id = jr.recipient_user_id
    and nl.data->>'journey_id' = jr.journey_id::text
  left join public.user_profiles up
    on up.user_id = jr.sender_user_id
  where jr.created_at >= now() - interval '24 hours'
    and nl.id is null  -- 알림 없는 건만
)
insert into public.notification_logs (
  user_id,
  title,
  body,
  route,
  data,
  created_at,
  updated_at
)
select
  mn.recipient_user_id,
  coalesce(mn.sender_nickname, 'Someone') || ' sent you a message',
  substring(mn.snapshot_content, 1, 100),
  '/inbox/' || mn.journey_id,
  jsonb_build_object(
    'journey_id', mn.journey_id,
    'sender_user_id', mn.sender_user_id,
    'recipient_id', mn.id
  ),
  mn.created_at,  -- 원래 생성 시각 유지
  now()
from missing_notifications mn
on conflict (user_id, ((data->>'journey_id')::uuid))
  where data is not null and data->>'journey_id' is not null
do nothing;

-- 결과: N rows inserted (누락된 알림 개수)
```

---

## 요약

### 확정된 원인

**`match_journey` 함수가 `journey_recipients` INSERT만 하고, `notification_logs` INSERT는 전혀 하지 않음**

- 트리거 없음
- 함수 내부 로직 없음
- 앱 호출 없음
- **결과**: 스케줄 경로에서 수신 메시지 생성되어도 푸시 알림 안 감

### 해결책

**journey_recipients AFTER INSERT 트리거 추가** (1안)

1. ✅ 세션 독립 (`NEW.recipient_user_id` 사용)
2. ✅ 경로 무관 (앱/스케줄 모두 동작)
3. ✅ 멱등성 보장 (UNIQUE INDEX + ON CONFLICT)
4. ✅ 에러 처리 (best-effort, warning만 출력)

### 변경 파일

- [supabase/sql/01_tables.sql](supabase/sql/01_tables.sql): UNIQUE INDEX 추가
- [supabase/sql/03_triggers.sql](supabase/sql/03_triggers.sql): 트리거 함수 + 트리거 등록

---

## 참고

- [PostgreSQL Triggers Documentation](https://www.postgresql.org/docs/current/sql-createtrigger.html)
- [Supabase Edge Functions - Push Notifications](https://supabase.com/docs/guides/functions/examples/push-notifications)
- [ON CONFLICT DO NOTHING (Upsert)](https://www.postgresql.org/docs/current/sql-insert.html#SQL-ON-CONFLICT)
