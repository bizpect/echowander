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
