-- ✅ 차단 해제 후 메시지 복구 검증 SQL
-- 배포 후 실행하여 "왜 안 보였는지"를 확정

-- A) unblock 직후 blocks row가 남는지 확인
select *
from public.user_blocks
where blocker_user_id = auth.uid()
  and blocked_user_id = '<TARGET_UUID>'::uuid;
-- 기대: 0 rows (차단 해제 완료)

-- B) "숨김 플래그"가 남아있는지 확인
select 
  id, 
  journey_id,
  recipient_user_id,
  sender_user_id,
  is_hidden, 
  hidden_reason_code, 
  hidden_at,
  created_at
from public.journey_recipients
where recipient_user_id = auth.uid()
  and sender_user_id = '<TARGET_UUID>'::uuid
order by created_at desc
limit 20;
-- 기대: is_hidden = false, hidden_reason_code = null (복구 완료)

-- C) unblock RPC 실행 후 restored_count 확인(jsonb)
select public.unblock_user('<TARGET_UUID>'::uuid);
-- 기대: {"ok":true,"restored_count":N} (N >= 0)

-- D) 복구 전후 비교 (실제 테스트 시)
-- 1) 차단 전: 메시지 확인
select count(*) as visible_count
from public.journey_recipients
where recipient_user_id = auth.uid()
  and sender_user_id = '<TARGET_UUID>'::uuid
  and is_hidden = false;

-- 2) 차단 후: 숨김 확인
select count(*) as hidden_count
from public.journey_recipients
where recipient_user_id = auth.uid()
  and sender_user_id = '<TARGET_UUID>'::uuid
  and is_hidden = true
  and hidden_reason_code = 'HIDE_BLOCKED';

-- 3) 차단 해제 후: 복구 확인
select public.unblock_user('<TARGET_UUID>'::uuid) as result;
-- restored_count가 hidden_count와 일치하는지 확인

-- 4) 복구 후: 다시 보이는지 확인
select count(*) as restored_count
from public.journey_recipients
where recipient_user_id = auth.uid()
  and sender_user_id = '<TARGET_UUID>'::uuid
  and is_hidden = false;
