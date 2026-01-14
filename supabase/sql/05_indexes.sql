-- users 테이블 인덱스
create unique index if not exists users_provider_subject_uk
  on public.users (provider, provider_subject);

-- user_profiles 테이블 인덱스
-- 기존 nickname 유니크 인덱스 제거 (nickname_norm 기반으로 대체)
drop index if exists user_profiles_nickname_uk;

-- nickname_norm 기반 유니크 인덱스 (대소문자/공백 차이 무시)
create unique index if not exists user_profiles_nickname_norm_uk
  on public.user_profiles (nickname_norm)
  where nickname_norm is not null;

-- notification_logs 테이블 인덱스
create index if not exists notification_logs_user_created_idx
  on public.notification_logs (user_id, created_at desc);

create index if not exists notification_logs_user_delete_idx
  on public.notification_logs (user_id, delete_yn, created_at desc);

drop index if exists notification_logs_unread_idx;
create index if not exists notification_logs_unread_idx
  on public.notification_logs (user_id, created_at desc)
  where delete_yn = false
    and read_at is null;

-- login_logs 테이블 인덱스
create index if not exists login_logs_user_id_idx
  on public.login_logs (user_id);

create index if not exists login_logs_created_at_idx
  on public.login_logs (created_at desc);

drop index if exists device_tokens_token_uk;
drop index if exists device_tokens_active_token_uk;

create unique index if not exists device_tokens_user_device_uk
  on public.device_tokens (user_id, device_id);

create index if not exists journeys_user_id_idx
  on public.journeys (user_id);

create index if not exists journeys_created_at_idx
  on public.journeys (created_at desc);

create index if not exists journey_images_journey_id_idx
  on public.journey_images (journey_id);

create index if not exists journey_images_user_id_idx
  on public.journey_images (user_id);

create index if not exists user_blocks_blocker_idx
  on public.user_blocks (blocker_user_id);

create index if not exists user_blocks_blocked_idx
  on public.user_blocks (blocked_user_id);

create index if not exists journey_recipients_journey_id_idx
  on public.journey_recipients (journey_id);

create index if not exists journey_recipients_recipient_id_idx
  on public.journey_recipients (recipient_user_id);

create index if not exists journey_responses_journey_id_idx
  on public.journey_responses (journey_id);

create index if not exists journey_responses_user_id_idx
  on public.journey_responses (responder_user_id);

create index if not exists journey_reports_journey_id_idx
  on public.journey_reports (journey_id);

create index if not exists journey_reports_user_id_idx
  on public.journey_reports (reporter_user_id);

create index if not exists journey_response_reports_response_id_idx
  on public.journey_response_reports (response_id);

create index if not exists journey_response_reports_user_id_idx
  on public.journey_response_reports (reporter_user_id);

create index if not exists ad_reward_logs_user_created_idx
  on public.ad_reward_logs (user_id, created_at desc);

create index if not exists ad_reward_logs_journey_created_idx
  on public.ad_reward_logs (journey_id, created_at desc);

create index if not exists reward_unlocks_user_idx
  on public.reward_unlocks (user_id, journey_id);

create index if not exists users_response_suspended_until_idx
  on public.users (response_suspended_until);

create index if not exists journey_responses_hidden_idx
  on public.journey_responses (journey_id, is_hidden);

create index if not exists client_error_logs_created_at_idx
  on public.client_error_logs (created_at desc);

create index if not exists client_error_logs_user_id_idx
  on public.client_error_logs (user_id);

create index if not exists journey_actions_recipient_id_idx
  on public.journey_actions (journey_recipient_id);

create index if not exists journey_actions_actor_id_idx
  on public.journey_actions (actor_user_id, created_at desc);

create index if not exists board_posts_board_status_published_idx
  on public.board_posts (board_id, status, published_at desc);

create index if not exists board_posts_board_type_status_published_idx
  on public.board_posts (board_id, type_code, status, published_at desc);

create index if not exists board_posts_board_pinned_published_idx
  on public.board_posts (board_id, is_pinned desc, published_at desc);

create index if not exists journey_dispatch_jobs_status_next_run_idx
  on public.journey_dispatch_jobs (status, next_run_at)
  where status in ('pending', 'failed');
