insert into public.common_codes (code_type, code_value, name, sort_order)
values
  ('login_type', 'kakao', 'Kakao', 10),
  ('login_type', 'google', 'Google', 20),
  ('login_type', 'apple', 'Apple', 30),
  ('login_type', 'unknown', 'Unknown', 90),
  ('login_type', 'dev', 'Developer', 99),
  ('journey_status', 'CREATED', 'Created', 10),
  ('journey_status', 'WAITING', 'Waiting', 20),
  ('journey_status', 'COMPLETED', 'Completed', 90),
  ('journey_recipient_status', 'ASSIGNED', 'Assigned', 10),
  ('journey_recipient_status', 'RESPONDED', 'Responded', 20),
  ('journey_recipient_status', 'PASSED', 'Passed', 30),
  ('journey_recipient_status', 'REPORTED', 'Reported', 40),
  ('report_reason', 'SPAM', 'Spam', 10),
  ('report_reason', 'ABUSE', 'Abuse', 20),
  ('report_reason', 'OTHER', 'Other', 90),
  ('journey_filter_status', 'OK', 'Allowed', 10),
  ('journey_filter_status', 'HELD', 'Held', 20),
  ('journey_filter_status', 'REMOVED', 'Removed', 90),
  ('journey_action_type', 'PASS', 'Pass', 10),
  ('journey_action_type', 'REPLY', 'Reply', 20),
  ('journey_action_type', 'REPORT', 'Report', 30),
  ('journey_action_type', 'BLOCK', 'Block', 40),
  ('hide_reason', 'HIDE_REPORTED', 'Hidden due to report', 10),
  ('hide_reason', 'HIDE_BLOCKED', 'Hidden due to block', 20),
  ('ad_placement', 'SENT_DETAIL_GATE', 'Sent detail gate', 10),
  ('app_env', 'DEV', 'Development', 10),
  ('app_env', 'STG', 'Staging', 20),
  ('app_env', 'PROD', 'Production', 90),
  ('ad_network', 'ADMOB', 'AdMob', 10),
  ('reward_unlock_type', 'ADMOB_REWARDED', 'AdMob Rewarded', 10),
  ('ad_reward_event', 'REQUEST', 'Request', 10),
  ('ad_reward_event', 'SHOW', 'Show', 20),
  ('ad_reward_event', 'EARN', 'Earn', 30),
  ('ad_reward_event', 'DISMISS', 'Dismiss', 40),
  ('ad_reward_event', 'FAIL_LOAD', 'Fail load', 80),
  ('ad_reward_event', 'FAIL_SHOW', 'Fail show', 81),
  ('ad_reward_event', 'FAIL_CONFIG', 'Fail config', 90)
on conflict (code_type, code_value) do update
set name = excluded.name,
    sort_order = excluded.sort_order,
    updated_at = now();

insert into public.common_codes (code_type, code_value, name, labels, sort_order)
values
  (
    'board_key',
    'NOTICE',
    'Notice',
    '{"ko":"공지사항","en":"Notice","ja":"お知らせ","zh":"公告","es":"Avisos","fr":"Actualités","pt":"Avisos","pt_BR":"Avisos"}'::jsonb,
    10
  ),
  (
    'notice_type',
    'UPDATE',
    'Update',
    '{"ko":"업데이트","en":"Update","ja":"アップデート","zh":"更新","es":"Actualización","fr":"Mise à jour","pt":"Atualização","pt_BR":"Atualização"}'::jsonb,
    10
  ),
  (
    'notice_type',
    'NEWS',
    'News',
    '{"ko":"소식","en":"News","ja":"ニュース","zh":"新闻","es":"Noticias","fr":"Actualités","pt":"Notícias","pt_BR":"Notícias"}'::jsonb,
    20
  ),
  (
    'notice_type',
    'MAINTENANCE',
    'Maintenance',
    '{"ko":"점검","en":"Maintenance","ja":"メンテナンス","zh":"维护","es":"Mantenimiento","fr":"Maintenance","pt":"Manutenção","pt_BR":"Manutenção"}'::jsonb,
    30
  )
on conflict (code_type, code_value) do update
set name = excluded.name,
    labels = excluded.labels,
    sort_order = excluded.sort_order,
    updated_at = now();

insert into public.boards (board_key, is_active)
values ('NOTICE', true)
on conflict (board_key) do update
set is_active = excluded.is_active;

insert into public.board_posts (
  board_id,
  type_code,
  title,
  content,
  status,
  is_pinned,
  published_at
)
select b.id,
       'UPDATE',
       '서비스 업데이트 안내',
       '더 안정적인 경험을 위해 앱 내부 흐름을 개선했습니다. 최신 버전으로 업데이트해 주세요.',
       'PUBLISHED',
       true,
       now()
from public.boards b
where b.board_key = 'NOTICE'
  and not exists (
    select 1
    from public.board_posts bp
    where bp.board_id = b.id
      and bp.title = '서비스 업데이트 안내'
  );

insert into public.board_posts (
  board_id,
  type_code,
  title,
  content,
  status,
  is_pinned,
  published_at
)
select b.id,
       'NEWS',
       '새로운 기능 소식',
       '프로필과 메시지 흐름이 더 직관적으로 개선됩니다. 곧 자세한 소식을 전해드릴게요.',
       'PUBLISHED',
       false,
       now()
from public.boards b
where b.board_key = 'NOTICE'
  and not exists (
    select 1
    from public.board_posts bp
    where bp.board_id = b.id
      and bp.title = '새로운 기능 소식'
  );

insert into public.board_posts (
  board_id,
  type_code,
  title,
  content,
  status,
  is_pinned,
  published_at
)
select b.id,
       'MAINTENANCE',
       '정기 점검 안내',
       '안정적인 서비스 제공을 위해 점검이 예정되어 있습니다. 점검 시간 동안 일부 기능이 제한될 수 있습니다.',
       'PUBLISHED',
       false,
       now()
from public.boards b
where b.board_key = 'NOTICE'
  and not exists (
    select 1
    from public.board_posts bp
    where bp.board_id = b.id
      and bp.title = '정기 점검 안내'
  );

insert into storage.buckets (id, name, public)
values ('journey-images', 'journey-images', false)
on conflict (id) do update
set name = excluded.name,
    public = excluded.public;

insert into storage.buckets (id, name, public)
values ('profile-avatars', 'profile-avatars', false)
on conflict (id) do nothing;

-- 금칙어 시드 데이터
insert into public.forbidden_words (word, is_enabled)
values
  ('admin', true),
  ('administrator', true),
  ('moderator', true),
  ('test', true),
  ('null', true),
  ('undefined', true),
  ('echowander', true),
  ('에코원더', true)
on conflict (word) do update
set is_enabled = excluded.is_enabled,
    updated_at = now();
