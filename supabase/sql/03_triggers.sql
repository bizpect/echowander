-- 완료 상태 전환 시 응답 존재 여부를 강제한다.
drop trigger if exists trg_journeys_require_responses on public.journeys;
create trigger trg_journeys_require_responses
before update of status_code on public.journeys
for each row
when (old.status_code is distinct from new.status_code)
execute function public.ensure_journey_responses_before_complete();
