create extension if not exists "pgcrypto";

create table if not exists public.common_codes (
  code_type text not null,
  code_value text not null,
  name text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (code_type, code_value)
);

create table if not exists public.users (
  user_id uuid primary key,
  login_type_group text not null default 'login_type',
  login_type_code text not null,
  provider text not null,
  provider_subject text not null,
  is_deleted boolean not null default false,
  is_suspended boolean not null default false,
  response_suspended_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint users_login_type_fk
    foreign key (login_type_group, login_type_code)
    references public.common_codes (code_type, code_value)
);

create unique index if not exists users_provider_subject_uk
  on public.users (provider, provider_subject);

create table if not exists public.user_profiles (
  user_id uuid primary key,
  nickname text,
  avatar_url text,
  bio text,
  locale_tag text,
  notifications_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_profiles_user_fk
    foreign key (user_id)
    references public.users (user_id)
    on delete cascade
);

create table if not exists public.user_blocks (
  blocker_user_id uuid not null,
  blocked_user_id uuid not null,
  reason_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (blocker_user_id, blocked_user_id),
  constraint user_blocks_blocker_fk
    foreign key (blocker_user_id)
    references public.users (user_id)
    on delete cascade,
  constraint user_blocks_blocked_fk
    foreign key (blocked_user_id)
    references public.users (user_id)
    on delete cascade
);

create table if not exists public.device_tokens (
  id bigserial primary key,
  user_id uuid not null,
  token text not null,
  platform text not null,
  device_id text not null,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint device_tokens_user_fk
    foreign key (user_id)
    references public.users (user_id)
    on delete cascade,
  constraint device_tokens_user_device_unique
    unique (user_id, device_id)
);

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

create index if not exists notification_logs_user_created_idx
  on public.notification_logs (user_id, created_at desc);

create index if not exists notification_logs_user_delete_idx
  on public.notification_logs (user_id, delete_yn, created_at desc);

create unique index if not exists user_profiles_nickname_uk
  on public.user_profiles (nickname)
  where nickname is not null;

create table if not exists public.login_logs (
  id bigserial primary key,
  user_id uuid,
  login_type_group text not null default 'login_type',
  login_type_code text not null,
  result text not null,
  created_at timestamptz not null default now(),
  constraint login_logs_login_type_fk
    foreign key (login_type_group, login_type_code)
    references public.common_codes (code_type, code_value)
);

create table if not exists public.client_error_logs (
  id bigserial primary key,
  user_id uuid,
  device_id text,
  error_context text not null,
  status_code integer,
  error_message text,
  meta jsonb,
  created_at timestamptz not null default now(),
  constraint client_error_logs_user_fk
    foreign key (user_id)
    references public.users (user_id)
    on delete set null
);

create table if not exists public.journeys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  status_group text not null default 'journey_status',
  status_code text not null default 'CREATED',
  filter_group text not null default 'journey_filter_status',
  filter_code text not null default 'OK',
  language_tag text not null,
  content text not null,
  requested_recipient_count integer not null default 1,
  response_target integer not null default 1,
  relay_deadline_at timestamptz not null default (now() + interval '72 hours'),
  result_notified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint journeys_user_fk
    foreign key (user_id)
    references public.users (user_id)
    on delete cascade,
  constraint journeys_status_fk
    foreign key (status_group, status_code)
    references public.common_codes (code_type, code_value),
  constraint journeys_filter_fk
    foreign key (filter_group, filter_code)
    references public.common_codes (code_type, code_value),
  constraint journeys_content_length
    check (char_length(content) <= 500),
  constraint journeys_recipient_count_range
    check (requested_recipient_count between 1 and 5)
);

create table if not exists public.journey_images (
  id bigserial primary key,
  journey_id uuid not null,
  user_id uuid not null,
  storage_path text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint journey_images_journey_fk
    foreign key (journey_id)
    references public.journeys (id)
    on delete cascade,
  constraint journey_images_user_fk
    foreign key (user_id)
    references public.users (user_id)
    on delete cascade
);

create table if not exists public.journey_recipients (
  id bigserial primary key,
  journey_id uuid not null,
  recipient_user_id uuid not null,
  status_group text not null default 'journey_recipient_status',
  status_code text not null default 'ASSIGNED',
  recipient_locale_tag text,
  -- 스냅샷 필드: journeys JOIN 없이 인박스 조회 가능 (RLS 유지)
  sender_user_id uuid,
  snapshot_content text,
  snapshot_image_count integer not null default 0,
  -- 숨김 처리 필드: 신고/차단 등으로 수신자 기준 숨김 (soft-hide)
  is_hidden boolean not null default false,
  hidden_reason_code text,
  hidden_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint journey_recipients_journey_fk
    foreign key (journey_id)
    references public.journeys (id)
    on delete cascade,
  constraint journey_recipients_user_fk
    foreign key (recipient_user_id)
    references public.users (user_id)
    on delete cascade,
  constraint journey_recipients_status_fk
    foreign key (status_group, status_code)
    references public.common_codes (code_type, code_value),
  constraint journey_recipients_unique
    unique (journey_id, recipient_user_id)
);

create table if not exists public.journey_responses (
  id bigserial primary key,
  journey_id uuid not null,
  responder_user_id uuid not null,
  content text not null,
  is_hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint journey_responses_journey_fk
    foreign key (journey_id)
    references public.journeys (id)
    on delete cascade,
  constraint journey_responses_user_fk
    foreign key (responder_user_id)
    references public.users (user_id)
    on delete cascade,
  constraint journey_responses_length
    check (char_length(content) <= 500)
);

create table if not exists public.journey_reports (
  id bigserial primary key,
  journey_id uuid not null,
  reporter_user_id uuid not null,
  reason_group text not null default 'report_reason',
  reason_code text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint journey_reports_journey_fk
    foreign key (journey_id)
    references public.journeys (id)
    on delete cascade,
  constraint journey_reports_user_fk
    foreign key (reporter_user_id)
    references public.users (user_id)
    on delete cascade,
  constraint journey_reports_reason_fk
    foreign key (reason_group, reason_code)
    references public.common_codes (code_type, code_value)
);

create table if not exists public.journey_response_reports (
  id bigserial primary key,
  response_id bigint not null,
  reporter_user_id uuid not null,
  reason_group text not null default 'report_reason',
  reason_code text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint journey_response_reports_unique
    unique (response_id, reporter_user_id),
  constraint journey_response_reports_response_fk
    foreign key (response_id)
    references public.journey_responses (id)
    on delete cascade,
  constraint journey_response_reports_user_fk
    foreign key (reporter_user_id)
    references public.users (user_id)
    on delete cascade,
  constraint journey_response_reports_reason_fk
    foreign key (reason_group, reason_code)
    references public.common_codes (code_type, code_value)
);

create table if not exists public.journey_actions (
  id bigserial primary key,
  journey_recipient_id bigint not null,
  actor_user_id uuid not null,
  action_type_group text not null default 'journey_action_type',
  action_type_code text not null,
  created_at timestamptz not null default now(),
  constraint journey_actions_recipient_fk
    foreign key (journey_recipient_id)
    references public.journey_recipients (id)
    on delete cascade,
  constraint journey_actions_user_fk
    foreign key (actor_user_id)
    references public.users (user_id)
    on delete cascade,
  constraint journey_actions_type_fk
    foreign key (action_type_group, action_type_code)
    references public.common_codes (code_type, code_value),
  constraint journey_actions_unique
    unique (actor_user_id, journey_recipient_id, action_type_code)
);
