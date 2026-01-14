-- 완료 상태 전환 시 응답 존재 여부를 강제한다.
drop trigger if exists trg_journeys_require_responses on public.journeys;
create trigger trg_journeys_require_responses
before update of status_code on public.journeys
for each row
when (old.status_code is distinct from new.status_code)
execute function public.ensure_journey_responses_before_complete();

-- ============================================================================
-- UGC Moderation Triggers
-- ============================================================================

-- journeys 테이블 moderation 트리거
drop trigger if exists trg_journeys_moderation on public.journeys;
create trigger trg_journeys_moderation
before insert or update of content on public.journeys
for each row
execute function public.apply_journey_moderation();

-- journey_responses 테이블 moderation 트리거
drop trigger if exists trg_journey_responses_moderation on public.journey_responses;
create trigger trg_journey_responses_moderation
before insert or update of content on public.journey_responses
for each row
execute function public.apply_journey_response_moderation();

-- 여정 생성 시 분배 작업 큐 등록
drop trigger if exists trg_enqueue_journey_dispatch_job on public.journeys;
drop trigger if exists trg_enqueue_dispatch_job_on_journey_insert on public.journeys;
drop function if exists public.enqueue_journey_dispatch_job();
drop function if exists public.enqueue_dispatch_job_on_journey_insert();

create or replace function public.enqueue_dispatch_job_on_journey_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status_code = 'WAITING' then
    insert into public.journey_dispatch_jobs as jdj (
      journey_id, status, attempt_count, next_run_at, last_error, created_at, updated_at
    )
    values (
      new.id, 'pending', 0, now(), null, now(), now()
    )
    on conflict on constraint journey_dispatch_jobs_pkey do update
    set status = 'pending',
        attempt_count = 0,
        next_run_at = now(),
        last_error = null,
        updated_at = now();
  end if;
  return new;
end;
$$;

create trigger trg_enqueue_dispatch_job_on_journey_insert
  after insert on public.journeys
  for each row
  execute function public.enqueue_dispatch_job_on_journey_insert();

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

  -- 여정 내용 조회 (snapshot 사용)
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
    raise warning '[enqueue_push_notification] Failed: %', sqlerrm;
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
