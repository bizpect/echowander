-- 검증 SQL: journey_recipients의 snapshot_image_paths 저장 확인
--
-- 사용법:
-- 1. 특정 journeyId에 대해 실행
-- 2. snapshot_image_count와 path_len이 일치하는지 확인
-- 3. snapshot_image_paths 배열이 올바르게 저장되었는지 확인

select
  jr.journey_id,
  jr.recipient_user_id,
  jr.snapshot_image_count,
  coalesce(array_length(jr.snapshot_image_paths, 1), 0) as path_len,
  jr.snapshot_image_paths,
  -- 검증: count와 path_len이 일치해야 함
  case
    when snapshot_image_count = coalesce(array_length(snapshot_image_paths, 1), 0) then 'OK'
    else 'MISMATCH'
  end as validation_status
from public.journey_recipients as jr
where jr.journey_id = '<journeyId>'  -- 실제 journeyId로 교체
  and jr.recipient_user_id = auth.uid()
order by jr.created_at desc;

-- 전체 인박스 항목 검증 (현재 사용자 기준)
select
  jr.journey_id,
  jr.snapshot_image_count,
  coalesce(array_length(jr.snapshot_image_paths, 1), 0) as path_len,
  case
    when snapshot_image_count = coalesce(array_length(snapshot_image_paths, 1), 0) then 'OK'
    else 'MISMATCH'
  end as validation_status
from public.journey_recipients as jr
where jr.recipient_user_id = auth.uid()
  and jr.snapshot_image_count > 0
order by jr.created_at desc
limit 20;
