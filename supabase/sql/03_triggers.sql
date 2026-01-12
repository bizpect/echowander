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