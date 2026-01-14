-- =====================================================
-- 08_dispatch_jobs_migration.sql
-- 목적: journey dispatch outbox 패턴 전환
-- - journey_dispatch_jobs 테이블 생성
-- - journey_recipients unique constraint 추가
-- - process_journey_dispatch_jobs RPC 생성
-- - create_journey RPC 수정
-- =====================================================

-- ===========================
-- 1. journey_dispatch_jobs 테이블 생성 (Outbox)
-- ===========================
create table if not exists public.journey_dispatch_jobs (
  journey_id uuid primary key,
  status text not null default 'pending',
  attempt_count integer not null default 0,
  next_run_at timestamptz not null default now(),
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint journey_dispatch_jobs_journey_fk
    foreign key (journey_id)
    references public.journeys (id)
    on delete cascade,
  constraint journey_dispatch_jobs_status_check
    check (status in ('pending', 'processing', 'done', 'failed'))
);

-- 인덱스: 처리 대상 job 빠른 선정용
create index if not exists idx_journey_dispatch_jobs_status_next_run
  on public.journey_dispatch_jobs (status, next_run_at)
  where status in ('pending', 'failed');

comment on table public.journey_dispatch_jobs is
  '여정 분배 작업 큐: pending job은 GitHub Actions cron이 주기적으로 처리';

-- ===========================
-- 2. journey_recipients 멱등 보장 (unique constraint)
-- ===========================
-- 이미 unique constraint가 있는지 확인 (01_tables.sql:321~322)
-- constraint journey_recipients_unique unique (journey_id, recipient_user_id)
-- → 이미 존재하므로 추가 작업 불필요
-- 하지만 명시적으로 확인하고 없으면 추가

do $$
begin
  -- unique constraint 존재 여부 확인
  if not exists (
    select 1
    from pg_constraint
    where conname = 'journey_recipients_unique'
      and conrelid = 'public.journey_recipients'::regclass
  ) then
    -- constraint 추가
    alter table public.journey_recipients
      add constraint journey_recipients_unique
      unique (journey_id, recipient_user_id);

    raise notice 'Added unique constraint journey_recipients_unique';
  else
    raise notice 'Unique constraint journey_recipients_unique already exists';
  end if;
end;
$$;

-- ===========================
-- 3. process_journey_dispatch_jobs RPC 생성
-- ===========================
drop function if exists public.process_journey_dispatch_jobs(integer);

create or replace function public.process_journey_dispatch_jobs(
  p_batch integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_batch integer;
  v_job_id uuid;
  v_journey record;
  v_assigned_count integer;
  v_processed_count integer := 0;
  v_failed_count integer := 0;
  v_error_message text;
  v_next_run_at timestamptz;
begin
  -- service_role만 실행 가능
  if auth.role() <> 'service_role' then
    raise exception using
      errcode = 'P0001',
      message = 'unauthorized',
      detail = 'This function can only be called by service_role';
  end if;

  -- 배치 크기 보정
  v_batch := greatest(least(coalesce(p_batch, 20), 100), 1);

  -- 처리 대상 job 선정 및 처리
  for v_job_id in
    select jdj.journey_id
    from public.journey_dispatch_jobs jdj
    where jdj.status in ('pending', 'failed')
      and jdj.next_run_at <= now()
    order by jdj.next_run_at asc
    limit v_batch
    for update skip locked
  loop
    begin
      -- job 상태를 processing으로 전환
      update public.journey_dispatch_jobs
      set status = 'processing',
          updated_at = now()
      where journey_id = v_job_id;

      -- journey 정보 조회
      select j.* into v_journey
      from public.journeys j
      where j.id = v_job_id;

      if not found then
        -- journey가 삭제됨 → job done 처리
        update public.journey_dispatch_jobs
        set status = 'done',
            updated_at = now()
        where journey_id = v_job_id;

        v_processed_count := v_processed_count + 1;
        continue;
      end if;

      -- 이미 분배 완료 여부 확인 (멱등 보장)
      select count(*) into v_assigned_count
      from public.journey_recipients jr
      where jr.journey_id = v_job_id;

      if v_assigned_count >= v_journey.requested_recipient_count then
        -- 이미 분배 완료 → job done 처리
        update public.journey_dispatch_jobs
        set status = 'done',
            last_error = null,
            updated_at = now()
        where journey_id = v_job_id;

        -- journey 상태 업데이트 (WAITING → CREATED)
        update public.journeys
        set status_code = 'CREATED',
            updated_at = now()
        where id = v_job_id
          and status_code = 'WAITING';

        v_processed_count := v_processed_count + 1;
        continue;
      end if;

      -- 분배 실행: match_journey 호출 (기존 로직 재사용)
      -- match_journey는 멱등: ON CONFLICT 처리로 중복 방지
      -- 반환값: journey_id, recipient_user_id, device_token, platform, device_id, locale_tag
      perform public.match_journey(v_job_id);

      -- 분배 완료 여부 재확인
      select count(*) into v_assigned_count
      from public.journey_recipients jr
      where jr.journey_id = v_job_id;

      if v_assigned_count > 0 then
        -- 분배 성공 → job done 처리
        update public.journey_dispatch_jobs
        set status = 'done',
            last_error = null,
            updated_at = now()
        where journey_id = v_job_id;

        -- journey 상태 업데이트
        update public.journeys
        set status_code = 'CREATED',
            updated_at = now()
        where id = v_job_id
          and status_code = 'WAITING';

        v_processed_count := v_processed_count + 1;
      else
        -- 분배 실패 (수신자 부족 등) → 재시도 대기
        update public.journey_dispatch_jobs
        set status = 'failed',
            attempt_count = attempt_count + 1,
            last_error = 'no_recipients_found',
            next_run_at = least(
              now() + (power(2, attempt_count + 1)::integer * interval '30 seconds'),
              now() + interval '30 minutes'
            ),
            updated_at = now()
        where journey_id = v_job_id;

        v_failed_count := v_failed_count + 1;
      end if;

    exception
      when others then
        -- 에러 발생 → attempt_count 증가, backoff 적용
        get stacked diagnostics v_error_message = message_text;

        update public.journey_dispatch_jobs
        set status = 'failed',
            attempt_count = attempt_count + 1,
            last_error = v_error_message,
            next_run_at = least(
              now() + (power(2, attempt_count + 1)::integer * interval '30 seconds'),
              now() + interval '30 minutes'
            ),
            updated_at = now()
        where journey_id = v_job_id;

        v_failed_count := v_failed_count + 1;
    end;
  end loop;

  -- 결과 반환
  return jsonb_build_object(
    'ok', true,
    'processed', v_processed_count,
    'failed', v_failed_count,
    'batch_size', v_batch
  );
end;
$$;

comment on function public.process_journey_dispatch_jobs(integer) is
  'Outbox 패턴: pending/failed job을 처리하여 journey 분배 수행. GitHub Actions cron에서 호출.';

-- ===========================
-- 4. create_journey RPC 수정
-- ===========================
drop function if exists public.create_journey(text, text, text[], integer);

create or replace function public.create_journey(
  content text,
  language_tag text,
  image_paths text[],
  recipient_count integer
)
returns table (
  journey_id uuid,
  created_at timestamptz,
  moderation_status text,
  content_clean text
)
language plpgsql
as $$
declare
  _journey_id uuid;
  _created_at timestamptz;
  _image_path text;
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if content is null or length(trim(content)) = 0 then
    raise exception 'empty_content';
  end if;
  if char_length(content) > 500 then
    raise exception 'content_too_long';
  end if;
  if language_tag is null or length(trim(language_tag)) = 0 then
    raise exception 'missing_language';
  end if;
  if image_paths is not null and array_length(image_paths, 1) > 3 then
    raise exception 'too_many_images';
  end if;
  if recipient_count is null or recipient_count < 1 or recipient_count > 5 then
    raise exception 'invalid_recipient_count';
  end if;
  if not exists (
    select 1
    from public.common_codes
    where code_type = 'journey_status'
      and code_value = 'WAITING'
  ) then
    raise exception 'missing_code_value';
  end if;
  if not exists (
    select 1
    from public.common_codes
    where code_type = 'journey_filter_status'
      and code_value = 'OK'
  ) then
    raise exception 'missing_code_value';
  end if;
  if content ~* '(https?://|www\\.)' then
    raise exception 'contains_url';
  end if;
  if content ~* '([A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,})' then
    raise exception 'contains_email';
  end if;
  if content ~* '(\\+?\\d[\\d\\s\\-]{6,})' then
    raise exception 'contains_phone';
  end if

;

  -- journey 생성
  insert into public.journeys (
    user_id,
    status_code,
    filter_code,
    language_tag,
    content,
    requested_recipient_count,
    response_target,
    relay_deadline_at
  )
  values (
    auth.uid(),
    'WAITING',
    'OK',
    language_tag,
    content,
    recipient_count,
    recipient_count,
    now() + interval '72 hours'
  )
  returning id, public.journeys.created_at into _journey_id, _created_at;

  -- 이미지 첨부 처리
  if image_paths is not null then
    foreach _image_path in array image_paths loop
      insert into public.journey_images (
        journey_id,
        user_id,
        storage_path
      )
      values (
        _journey_id,
        auth.uid(),
        _image_path
      );
    end loop;
  end if;

  -- ✅ dispatch job 생성 (outbox)
  insert into public.journey_dispatch_jobs (
    journey_id,
    status,
    attempt_count,
    next_run_at
  )
  values (
    _journey_id,
    'pending',
    0,
    now()
  )
  on conflict (journey_id) do update
  set status = 'pending',
      attempt_count = 0,
      next_run_at = now(),
      last_error = null,
      updated_at = now();

  -- 트리거가 moderation을 적용한 후 조회
  return query
  select
    j.id as journey_id,
    j.created_at as created_at,
    j.moderation_status,
    j.content_clean
  from public.journeys j
  where j.id = _journey_id;
end;
$$;

comment on function public.create_journey(text, text, text[], integer) is
  '여정 생성: journey_dispatch_jobs에 pending job 생성하여 백엔드 워커가 분배 처리';

-- ===========================
-- 5. RLS 정책 (journey_dispatch_jobs)
-- ===========================
-- journey_dispatch_jobs는 service_role만 접근
alter table public.journey_dispatch_jobs enable row level security;

-- service_role은 모든 작업 가능
create policy "service_role can manage all jobs"
  on public.journey_dispatch_jobs
  for all
  to service_role
  using (true)
  with check (true);

-- authenticated 사용자는 자신의 journey에 대한 job만 조회 가능 (선택)
create policy "users can view their own jobs"
  on public.journey_dispatch_jobs
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.journeys j
      where j.id = journey_dispatch_jobs.journey_id
        and j.user_id = auth.uid()
    )
  );

-- ===========================
-- 6. Grant 권한 설정
-- ===========================
grant execute on function public.process_journey_dispatch_jobs(integer) to service_role;

-- ===========================
-- 완료
-- ===========================
-- 마이그레이션 완료: journey_dispatch_jobs 테이블, process_journey_dispatch_jobs RPC, create_journey 수정
