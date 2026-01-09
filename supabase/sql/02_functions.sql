create or replace function public.create_or_get_user(
  _provider text,
  _provider_subject text,
  _login_type_code text
)
returns table (
  user_id uuid,
  provider text,
  provider_subject text,
  login_type_code text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
as $$
begin
  insert into public.users (user_id, provider, provider_subject, login_type_code)
  values (auth.uid(), _provider, _provider_subject, _login_type_code)
  on conflict on constraint users_pkey
  do update set
    provider = excluded.provider,
    provider_subject = excluded.provider_subject,
    login_type_code = excluded.login_type_code,
    updated_at = now();

  insert into public.user_profiles (user_id)
  values (auth.uid())
  on conflict on constraint user_profiles_pkey
  do nothing;

  return query
  select u.user_id, u.provider, u.provider_subject, u.login_type_code, u.created_at, u.updated_at
  from public.users u
  where u.user_id = auth.uid();
end;
$$;

create or replace function public.log_login_attempt(
  _login_type_code text,
  _result text
)
returns void
language plpgsql
as $$
begin
  insert into public.login_logs (user_id, login_type_code, result)
  values (auth.uid(), _login_type_code, _result);
end;
$$;

drop function if exists public.get_my_profile();

create or replace function public.get_my_profile()
returns table (
  user_id uuid,
  nickname text,
  avatar_url text,
  bio text,
  locale_tag text,
  notifications_enabled boolean,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
as $$
  select p.user_id,
         p.nickname,
         p.avatar_url,
         p.bio,
         p.locale_tag,
         p.notifications_enabled,
         p.created_at,
         p.updated_at
  from public.user_profiles p
  where p.user_id = auth.uid();
$$;

drop function if exists public.upsert_my_profile(text, text, text);

create or replace function public.upsert_my_profile(
  _nickname text,
  _avatar_url text,
  _bio text
)
returns table (
  user_id uuid,
  nickname text,
  avatar_url text,
  bio text,
  locale_tag text,
  notifications_enabled boolean,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
as $$
begin
  insert into public.user_profiles (user_id, nickname, avatar_url, bio, locale_tag)
  values (auth.uid(), _nickname, _avatar_url, _bio, null)
  on conflict on constraint user_profiles_pkey
  do update set
    nickname = excluded.nickname,
    avatar_url = excluded.avatar_url,
    bio = excluded.bio,
    updated_at = now();

  return query
  select p.user_id,
         p.nickname,
         p.avatar_url,
         p.bio,
         p.locale_tag,
         p.notifications_enabled,
         p.created_at,
         p.updated_at
  from public.user_profiles p
  where p.user_id = auth.uid();
end;
$$;

create or replace function public.update_my_locale(
  _locale_tag text
)
returns void
language plpgsql
as $$
begin
  if _locale_tag is null or length(trim(_locale_tag)) = 0 then
    raise exception 'missing_locale';
  end if;

  insert into public.user_profiles (user_id, locale_tag)
  values (auth.uid(), _locale_tag)
  on conflict on constraint user_profiles_pkey
  do update set
    locale_tag = excluded.locale_tag,
    updated_at = now();
end;
$$;

create or replace function public.update_my_notification_setting(
  _enabled boolean
)
returns void
language plpgsql
as $$
begin
  if _enabled is null then
    raise exception 'missing_enabled';
  end if;

  insert into public.user_profiles (user_id, notifications_enabled)
  values (auth.uid(), _enabled)
  on conflict on constraint user_profiles_pkey
  do update set
    notifications_enabled = excluded.notifications_enabled,
    updated_at = now();
end;
$$;

drop function if exists public.list_my_blocks(integer, integer);

create or replace function public.list_my_blocks(
  page_size integer,
  page_offset integer
)
returns table (
  blocked_user_id uuid,
  blocked_nickname text,
  blocked_avatar_url text,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select blocks.blocked_user_id,
         profiles.nickname as blocked_nickname,
         profiles.avatar_url as blocked_avatar_url,
         blocks.created_at
  from public.user_blocks blocks
  left join public.user_profiles profiles
    on profiles.user_id = blocks.blocked_user_id
  where blocks.blocker_user_id = auth.uid()
  order by blocks.created_at desc
  limit least(coalesce(page_size, 20), 50)
  offset greatest(coalesce(page_offset, 0), 0);
$$;

create or replace function public.block_user(
  target_user_id uuid
)
returns void
language plpgsql
as $$
begin
  if target_user_id is null then
    raise exception 'missing_user';
  end if;
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if target_user_id = auth.uid() then
    raise exception 'invalid_target';
  end if;
  if not exists (
    select 1
    from public.users
    where users.user_id = target_user_id
  ) then
    raise exception 'user_not_found';
  end if;

  insert into public.user_blocks (blocker_user_id, blocked_user_id)
  values (auth.uid(), target_user_id)
  on conflict (blocker_user_id, blocked_user_id)
  do update set
    updated_at = now();
end;
$$;

create or replace function public.unblock_user(
  target_user_id uuid
)
returns void
language plpgsql
as $$
begin
  if target_user_id is null then
    raise exception 'missing_user';
  end if;
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;

  delete from public.user_blocks
  where blocker_user_id = auth.uid()
    and blocked_user_id = target_user_id;
end;
$$;

create or replace function public.insert_notification_log(
  _user_id uuid,
  _title text,
  _body text,
  _route text,
  _data jsonb
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id bigint;
begin
  if _user_id is null then
    raise exception 'missing_user';
  end if;
  if _title is null or length(trim(_title)) = 0 then
    raise exception 'missing_title';
  end if;
  if auth.uid() is not null and auth.uid() <> _user_id then
    raise exception 'forbidden';
  end if;
  if auth.uid() is null and auth.role() <> 'service_role' then
    raise exception 'unauthorized';
  end if;

  insert into public.notification_logs (user_id, title, body, route, data)
  values (_user_id, _title, _body, _route, _data)
  returning id into new_id;

  return new_id;
end;
$$;

create or replace function public.list_my_notifications(
  page_size integer,
  page_offset integer,
  unread_only boolean default false
)
returns table (
  id bigint,
  title text,
  body text,
  route text,
  data jsonb,
  read_at timestamptz,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select logs.id,
         logs.title,
         logs.body,
         logs.route,
         logs.data,
         logs.read_at,
         logs.created_at
  from public.notification_logs logs
  where logs.user_id = auth.uid()
    and logs.delete_yn = false
    and logs.created_at >= now() - interval '7 days'
    and (not coalesce(unread_only, false) or logs.read_at is null)
  order by logs.created_at desc
  limit least(coalesce(page_size, 20), 50)
  offset greatest(coalesce(page_offset, 0), 0);
$$;

create or replace function public.count_my_unread_notifications()
returns integer
language sql
security definer
set search_path = public
as $$
  select count(*)
  from public.notification_logs logs
  where logs.user_id = auth.uid()
    and logs.delete_yn = false
    and logs.read_at is null
    and logs.created_at >= now() - interval '7 days';
$$;

create or replace function public.mark_notification_read(
  target_id bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;

  update public.notification_logs
  set read_at = coalesce(read_at, now()),
      updated_at = now()
  where id = target_id
    and user_id = auth.uid()
    and delete_yn = false;
end;
$$;

create or replace function public.delete_notification_log(
  target_id bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;

  update public.notification_logs
  set delete_yn = true,
      updated_at = now()
  where id = target_id
    and user_id = auth.uid();
end;
$$;

create or replace function public.report_journey_response(
  target_response_id bigint,
  reason_code text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _journey_id uuid;
  _response_owner uuid;
  _response_report_count integer;
  _user_report_count integer;
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if target_response_id is null then
    raise exception 'missing_response';
  end if;
  if reason_code is null or length(trim(reason_code)) = 0 then
    raise exception 'missing_reason';
  end if;
  if not exists (
    select 1
    from public.common_codes
    where code_type = 'report_reason'
      and code_value = reason_code
  ) then
    raise exception 'missing_code_value';
  end if;

  select journey_responses.journey_id,
         journey_responses.responder_user_id
  into _journey_id, _response_owner
  from public.journey_responses
  where journey_responses.id = target_response_id;

  if _journey_id is null then
    raise exception 'response_not_found';
  end if;
  if _response_owner is null then
    raise exception 'response_not_found';
  end if;

  if not exists (
    select 1
    from public.journeys
    where journeys.id = _journey_id
      and journeys.user_id = auth.uid()
  ) then
    raise exception 'unauthorized';
  end if;

  insert into public.journey_response_reports (
    response_id,
    reporter_user_id,
    reason_code
  )
  values (
    target_response_id,
    auth.uid(),
    reason_code
  )
  on conflict do nothing;

  select count(*)
  into _response_report_count
  from public.journey_response_reports
  where response_id = target_response_id;

  if _response_report_count >= 2 then
    update public.journey_responses
    set is_hidden = true,
        updated_at = now()
    where id = target_response_id;
  end if;

  select count(*)
  into _user_report_count
  from public.journey_response_reports reports
  join public.journey_responses responses
    on responses.id = reports.response_id
  where responses.responder_user_id = _response_owner;

  if _user_report_count >= 5 then
    update public.users
    set response_suspended_until = greatest(
          coalesce(response_suspended_until, now()),
          now() + interval '7 days'
        ),
        updated_at = now()
    where user_id = _response_owner;
  end if;
end;
$$;

create or replace function public.upsert_device_token(
  _token text,
  _platform text,
  _device_id text
)
returns void
language plpgsql
as $$
begin
  insert into public.device_tokens (user_id, token, platform, device_id)
  values (auth.uid(), _token, _platform, _device_id)
  on conflict (user_id, device_id)
  do update set
    token = excluded.token,
    platform = excluded.platform,
    is_active = true,
    last_seen_at = now(),
    updated_at = now();
end;
$$;

create or replace function public.deactivate_device_token(
  _token text
)
returns void
language plpgsql
as $$
begin
  update public.device_tokens
  set is_active = false,
      updated_at = now()
  where user_id = auth.uid()
    and token = _token;
end;
$$;

drop function if exists public.create_journey(text, text, text[]);

create or replace function public.create_journey(
  content text,
  language_tag text,
  image_paths text[],
  recipient_count integer
)
returns table (
  journey_id uuid,
  created_at timestamptz
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
  end if;

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

  return query
  select _journey_id as journey_id, _created_at as created_at;
end;
$$;

drop function if exists public.list_journeys(integer, integer);

create or replace function public.list_journeys(
  page_size integer,
  page_offset integer
)
returns table (
  journey_id uuid,
  content text,
  created_at timestamptz,
  image_count integer,
  status_code text,
  filter_code text,
  is_reward_unlocked boolean
)
language plpgsql
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;

  return query
  select
    journeys.id as journey_id,
    journeys.content,
    journeys.created_at,
    (
      select count(*)
      from public.journey_images
      where journey_images.journey_id = journeys.id
    )::integer as image_count,
    journeys.status_code,
    journeys.filter_code,
    (
      journeys.status_code = 'COMPLETED'
      and exists (
        select 1
        from public.reward_unlocks
        where reward_unlocks.user_id = auth.uid()
          and reward_unlocks.journey_id = journeys.id
      )
    ) as is_reward_unlocked
  from public.journeys
  where journeys.user_id = auth.uid()
  order by journeys.created_at desc
  limit least(coalesce(page_size, 20), 50)
  offset greatest(coalesce(page_offset, 0), 0);
end;
$$;

drop function if exists public.list_inbox_journeys(integer, integer);

-- 인박스 조회: journey_recipients 스냅샷 필드 사용 (journeys JOIN 제거, RLS 유지)
-- SECURITY DEFINER: 함수 내부에서 auth.uid() 필터 강제로 RLS 우회하되 데이터 노출 방지
create or replace function public.list_inbox_journeys(
  page_size integer,
  page_offset integer
)
returns table (
  recipient_id bigint,
  journey_id uuid,
  sender_user_id uuid,
  content text,
  created_at timestamptz,
  image_count integer,
  recipient_status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid;
begin
  -- ✅ auth.uid() 필터 강제 (데이터 노출 방지)
  current_user_id := auth.uid();
  if current_user_id is null then
    raise exception 'unauthorized';
  end if;

  -- C. recipient_id 보장: 명시적으로 jr.id만 반환하고 WHERE 조건으로 수신자만 필터링
  return query
  select
    jr.id as recipient_id,  -- 명시적 alias로 ambiguous 방지
    jr.journey_id,
    jr.sender_user_id,
    jr.snapshot_content as content,
    jr.created_at,
    jr.snapshot_image_count as image_count,
    jr.status_code as recipient_status
  from public.journey_recipients jr
  where jr.recipient_user_id = current_user_id  -- 반드시 현재 사용자가 수신자인 row만
    -- 스냅샷 필드가 존재하는 경우만 (마이그레이션 이전 데이터 제외)
    and jr.sender_user_id is not null
    -- 숨김 처리된 메시지 제외 (신고 완료 등)
    and jr.is_hidden = false
  order by jr.created_at desc
  limit least(coalesce(page_size, 20), 50)
  offset greatest(coalesce(page_offset, 0), 0);
  
  -- 보장: 반환된 모든 row의 recipient_id는 반드시 current_user_id가 recipient_user_id인 journey_recipients.id입니다
end;
$$;

-- ✅ 권한 최소화: PUBLIC에서 모든 권한 제거, authenticated에게만 EXECUTE 허용
revoke all on function public.list_inbox_journeys(integer, integer) from public;
grant execute on function public.list_inbox_journeys(integer, integer) to authenticated;

create or replace function public.list_inbox_journey_images(
  target_journey_id uuid
)
returns table (
  storage_path text
)
language plpgsql
as $$
begin
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if not exists (
    select 1
    from public.journey_recipients
    where journey_recipients.journey_id = target_journey_id
      and journey_recipients.recipient_user_id = auth.uid()
  ) and not exists (
    select 1
    from public.journeys
    where journeys.id = target_journey_id
      and journeys.user_id = auth.uid()
  ) then
    raise exception 'unauthorized';
  end if;

  return query
  select journey_images.storage_path
  from public.journey_images
  where journey_images.journey_id = target_journey_id
  order by journey_images.created_at asc;
end;
$$;

drop function if exists public.respond_journey(uuid, text);

create or replace function public.respond_journey(
  target_journey_id uuid,
  response_content text
)
returns table (
  journey_id uuid,
  completed boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  _response_count integer;
  _target integer;
  _journey_owner uuid;
  _status text;
  _suspended_until timestamptz;
  _snapshot_nickname text;
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if response_content is null or length(trim(response_content)) = 0 then
    raise exception 'empty_content';
  end if;
  if char_length(response_content) > 500 then
    raise exception 'content_too_long';
  end if;
  if response_content ~* '(https?://|www\\.)' then
    raise exception 'contains_url';
  end if;
  if response_content ~* '([A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,})' then
    raise exception 'contains_email';
  end if;
  if response_content ~* '(\\+?\\d[\\d\\s\\-]{6,})' then
    raise exception 'contains_phone';
  end if;

  select response_suspended_until
  into _suspended_until
  from public.users
  where user_id = auth.uid();

  if _suspended_until is not null and _suspended_until > now() then
    raise exception 'response_suspended';
  end if;

  -- RLS 우회를 위해 journey_recipients 조인으로 조회 (recipient가 ASSIGNED 상태인 journey만 조회 가능)
  select j.user_id, j.status_code, j.response_target
    into _journey_owner, _status, _target
  from public.journeys j
  inner join public.journey_recipients jr
    on j.id = jr.journey_id
  where j.id = target_journey_id
    and jr.recipient_user_id = auth.uid()
    and jr.status_code = 'ASSIGNED';

  if _journey_owner is null then
    raise exception 'journey_not_found';
  end if;
  if _status = 'COMPLETED' then
    raise exception 'already_completed';
  end if;

  select user_profiles.nickname
  into _snapshot_nickname
  from public.user_profiles
  where user_profiles.user_id = auth.uid();

  insert into public.journey_responses (
    journey_id,
    responder_user_id,
    snapshot_nickname,
    content
  )
  values (
    target_journey_id,
    auth.uid(),
    _snapshot_nickname,
    response_content
  );

  update public.journey_recipients
  set status_code = 'RESPONDED',
      updated_at = now()
  where journey_recipients.journey_id = target_journey_id
    and journey_recipients.recipient_user_id = auth.uid();

  select count(*)
  into _response_count
  from public.journey_responses
  where journey_responses.journey_id = target_journey_id;

  if _response_count >= _target then
    update public.journeys
    set status_code = 'COMPLETED',
        updated_at = now()
    where journeys.id = target_journey_id
      and journeys.status_code <> 'COMPLETED';
    return query
    select target_journey_id, true;
  end if;

  return query
  select target_journey_id, false;
end;
$$;

drop function if exists public.pass_journey(uuid);
drop function if exists public.pass_inbox_item_and_forward(uuid);

-- Pass 처리 + 랜덤 전송 + redaction (트랜잭션)
create or replace function public.pass_inbox_item_and_forward(
  target_journey_id uuid
)
returns table (
  success boolean,
  passed_at timestamptz,
  forwarded_recipient_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  _recipient_id bigint;
  _journey public.journeys%rowtype;
  _remaining integer;
  _forwarded_recipient_id uuid;
  _passed_at timestamptz := now();
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;

  -- 1) journey_recipient 조회 및 권한 체크
  select jr.id
  into _recipient_id
  from public.journey_recipients jr
  where jr.journey_id = target_journey_id
    and jr.recipient_user_id = auth.uid()
    and jr.status_code = 'ASSIGNED';

  if _recipient_id is null then
    raise exception 'unauthorized';
  end if;

  -- journey 조회 (rowtype 변수는 별도 SELECT 필요)
  select * into _journey
  from public.journeys
  where id = target_journey_id;

  -- 2) PASS action 기록 (idempotent)
  insert into public.journey_actions (
    journey_recipient_id,
    actor_user_id,
    action_type_code
  )
  values (
    _recipient_id,
    auth.uid(),
    'PASS'
  )
  on conflict (actor_user_id, journey_recipient_id, action_type_code) do nothing;

  -- 3) 랜덤 수신자 선정 및 전송 (기존 match_journey 로직 재사용)
  select greatest(_journey.requested_recipient_count - count(*), 0)
  into _remaining
  from public.journey_recipients
  where journey_recipients.journey_id = _journey.id;

  if _remaining > 0 then
    with candidates as (
      select
        users.user_id,
        user_profiles.locale_tag
      from public.users
      left join public.user_profiles
        on user_profiles.user_id = users.user_id
      where users.user_id <> _journey.user_id
        and users.is_deleted = false
        and users.is_suspended = false
        and (users.response_suspended_until is null
          or users.response_suspended_until <= now())
        and not exists (
          select 1
          from public.journey_recipients recipients
          where recipients.journey_id = _journey.id
            and recipients.recipient_user_id = users.user_id
        )
        and not exists (
          select 1
          from public.user_blocks blocks
          where (blocks.blocker_user_id = _journey.user_id
            and blocks.blocked_user_id = users.user_id)
            or (blocks.blocker_user_id = users.user_id
            and blocks.blocked_user_id = _journey.user_id)
        )
      order by random()
      limit 1
    ),
    journey_image_count as (
      select count(*)::integer as cnt
      from public.journey_images
      where journey_images.journey_id = _journey.id
    ),
    inserted as (
      insert into public.journey_recipients (
        journey_id,
        recipient_user_id,
        recipient_locale_tag,
        sender_user_id,
        snapshot_content,
        snapshot_image_count
      )
      select
        _journey.id,
        candidates.user_id,
        candidates.locale_tag,
        _journey.user_id,
        _journey.content,
        (select cnt from journey_image_count)
      from candidates
      returning journey_recipients.recipient_user_id, journey_recipients.id
    )
    select inserted.recipient_user_id into _forwarded_recipient_id
    from inserted
    limit 1;
  end if;

  -- 4) 현재 journey_recipient의 snapshot_content를 placeholder로 redaction
  --    (보안: passed된 메시지는 내용을 볼 수 없도록)
  update public.journey_recipients
  set status_code = 'PASSED',
      snapshot_content = '[패스한 메시지]',
      snapshot_image_count = 0,
      updated_at = _passed_at
  where id = _recipient_id;

  -- 5) 반환
  return query
  select true as success, _passed_at as passed_at, _forwarded_recipient_id as forwarded_recipient_id;
end;
$$;

-- 차단 처리 + 랜덤 전송 + 숨김 (트랜잭션)
-- pass_inbox_item_and_forward와 동일한 로직이지만 BLOCK action 기록 및 차단 관계 추가
-- 파라미터: p_recipient_id는 journey_recipients.id (PK)를 받습니다
-- 구버전 오버로드 제거 (bigint, text 버전만 유지)
drop function if exists public.block_sender_and_pass(uuid, text);
drop function if exists public.block_sender_and_pass(bigint, text);
create or replace function public.block_sender_and_pass(
  p_recipient_id bigint,
  p_reason_code text default null
)
returns table (
  success boolean,
  recipient_id bigint,
  blocked_user_id uuid,
  forwarded_recipient_id uuid,
  hidden_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  _recipient_id bigint;
  _journey public.journeys%rowtype;
  _sender_user_id uuid;
  _journey_id uuid;
  _remaining integer;
  _forwarded_recipient_id uuid;
  _hidden_at timestamptz := now();
  _current_uid uuid;
  _row_recipient_user_id uuid;
  _row_status_code text;
  _row_is_hidden boolean;
begin
  -- Server 로그 1: 함수 시작
  _current_uid := auth.uid();
  raise log '[block_sender_and_pass] START uid=% recipientId=%', 
    _current_uid, p_recipient_id;

  if _current_uid is null then
    raise log '[block_sender_and_pass] FAIL: auth.uid() is null';
    raise exception 'unauthorized: uid_null';
  end if;
  -- A. bigint 매핑 안전화: 입력 검증
  if p_recipient_id is null then
    raise log '[block_sender_and_pass] FAIL: p_recipient_id is null';
    raise exception 'invalid_argument: recipient_id_null';
  end if;
  if p_recipient_id <= 0 then
    raise log '[block_sender_and_pass] FAIL: p_recipient_id is invalid (<=0): %', p_recipient_id;
    raise exception 'invalid_argument: recipient_id_invalid';
  end if;

  -- 1) journey_recipient 조회 및 권한 체크 (정확한 recipient row 조회)
  -- 정책: 리스트에 보이는 건 모두 차단 가능 (list_inbox_journeys 조건과 일치)
  -- list_inbox_journeys 조건: recipient_user_id = auth.uid() AND is_hidden = false (status_code 필터 없음)
  -- 따라서 block_sender_and_pass도 동일 조건: recipient_user_id = auth.uid() AND is_hidden = false
  
  -- 먼저 row 존재 여부 및 상태 확인 (recipient_user_id 조건 없이)
  select jr.recipient_user_id, jr.status_code, jr.is_hidden
  into _row_recipient_user_id, _row_status_code, _row_is_hidden
  from public.journey_recipients jr
  where jr.id = p_recipient_id;

  if not found then
    raise log '[block_sender_and_pass] FAIL: recipient_not_found - p_recipient_id=%에 대한 row가 존재하지 않음, auth_uid=%', 
      p_recipient_id, _current_uid;
    raise exception 'unauthorized: recipient_not_found';
  end if;

  -- row는 존재하지만 recipient_user_id가 다름
  if _row_recipient_user_id != _current_uid then
    raise log '[block_sender_and_pass] FAIL: not_recipient - p_recipient_id=%의 recipient_user_id=%는 auth_uid=%와 불일치', 
      p_recipient_id, _row_recipient_user_id, _current_uid;
    raise exception 'unauthorized: not_recipient';
  end if;

  -- is_hidden 체크: 이미 숨김인 경우 에러 (리스트에 보이지 않으므로 차단 불가)
  if _row_is_hidden then
    raise log '[block_sender_and_pass] FAIL: recipient_hidden - p_recipient_id=%는 이미 숨김 처리됨 (is_hidden=true), auth_uid=%, hidden_reason=%', 
      p_recipient_id, _current_uid, _row_status_code;
    raise exception 'invalid_argument: recipient_hidden';
  end if;

  -- status_code는 체크하지 않음: 리스트에 보이면 어떤 상태든 차단 가능 (UX 정책)
  -- 단, 로그에는 기록
  raise log '[block_sender_and_pass] STATUS CHECK: p_recipient_id=%, status_code=%, is_hidden=%, auth_uid=%', 
    p_recipient_id, _row_status_code, _row_is_hidden, _current_uid;

  -- 권한 체크 통과 후 실제 데이터 조회 (status_code 조건 제거)
  select jr.id, jr.sender_user_id, jr.journey_id
  into _recipient_id, _sender_user_id, _journey_id
  from public.journey_recipients jr
  where jr.id = p_recipient_id
    and jr.recipient_user_id = _current_uid
    and jr.is_hidden = false;  -- status_code 조건 제거, is_hidden만 체크

  -- Server 로그 2: row 조회 직후
  raise log '[block_sender_and_pass] ROW recipient_user_id=% sender_user_id=% journey_id=% status=% hidden=%',
    _row_recipient_user_id, _sender_user_id, _journey_id, _row_status_code, _row_is_hidden;

  if _recipient_id is null then
    -- 이 분기는 이론적으로 도달하지 않아야 하지만 안전장치
    raise log '[block_sender_and_pass] FAIL: recipient_id is null after query (예상치 못한 상황), p_recipient_id=%, auth_uid=%', 
      p_recipient_id, _current_uid;
    raise exception 'unauthorized: not_recipient';
  end if;
  if _sender_user_id is null then
    raise log '[block_sender_and_pass] FAIL: sender_user_id is null';
    raise exception 'missing_sender';
  end if;
  if _journey_id is null then
    raise log '[block_sender_and_pass] FAIL: journey_id is null';
    raise exception 'missing_journey';
  end if;

  -- journey 조회
  select * into _journey
  from public.journeys
  where id = _journey_id;

  if not found then
    raise log '[block_sender_and_pass] FAIL: journey not found for journey_id=%', _journey_id;
    raise exception 'unauthorized: journey_not_found';
  end if;

  raise log '[block_sender_and_pass] JOURNEY LOADED: journey_id=%, user_id=%', 
    _journey.id, _journey.user_id;

  -- B. idempotent 보장: BLOCK action 존재 여부 확인 (중복 재전송 방지)
  declare
    _action_exists boolean;
  begin
    -- action이 이미 존재하는지 확인
    select exists (
      select 1
      from public.journey_actions
      where journey_recipient_id = _recipient_id
        and actor_user_id = _current_uid
        and action_type_code = 'BLOCK'
    ) into _action_exists;

    if _action_exists then
      raise log '[block_sender_and_pass] ALREADY_PROCESSED: recipient_id=%는 이미 차단 처리됨, forward 스킵', _recipient_id;
      -- 이미 처리된 경우: user_blocks upsert + 숨김 처리만 수행하고 forward 스킵
      -- Server 로그 3: user_blocks upsert 직전
      raise log '[block_sender_and_pass] UPSERT blocks blocker=% blocked=%',
        _current_uid, _sender_user_id;
      -- 2) user_blocks에 차단 기록 (idempotent)
      -- blocked_user_id ambiguous 방지: constraint 이름 사용
      insert into public.user_blocks (
        blocker_user_id,
        blocked_user_id,
        reason_code
      )
      values (
        _current_uid,
        _sender_user_id,
        p_reason_code
      )
      on conflict on constraint user_blocks_pkey
      do update set
        reason_code = coalesce(excluded.reason_code, user_blocks.reason_code),
        updated_at = now();

      -- Server 로그 4: 숨김 처리 직전
      raise log '[block_sender_and_pass] HIDE recipientId=%', p_recipient_id;
      -- 3) journey_recipient 숨김 처리 (이미 숨김일 수 있지만 안전하게)
      update public.journey_recipients
      set is_hidden = true,
          hidden_reason_code = 'HIDE_BLOCKED',
          hidden_at = _hidden_at,
          updated_at = _hidden_at
      where id = _recipient_id;

      -- 이미 처리된 경우: forward 없이 반환
      raise log '[block_sender_and_pass] SUCCESS (already_processed): recipient_id=%, blocked_user_id=%', 
        _recipient_id, _sender_user_id;
      return query
      select 
        true::boolean as success, 
        _recipient_id::bigint as recipient_id,
        _sender_user_id::uuid as blocked_user_id, 
        null::uuid as forwarded_recipient_id,
        _hidden_at::timestamptz as hidden_at;
      return;  -- 함수 종료 (forward 스킵)
    end if;

    -- 첫 실행인 경우: action 기록
    insert into public.journey_actions (
      journey_recipient_id,
      actor_user_id,
      action_type_code
    )
    values (
      _recipient_id,
      _current_uid,
      'BLOCK'
    )
    on conflict (actor_user_id, journey_recipient_id, action_type_code) do nothing;
    
    raise log '[block_sender_and_pass] FIRST_EXECUTION: recipient_id=% 차단 처리 시작 (action 기록 완료)', _recipient_id;
  end;

  -- Server 로그 3: user_blocks upsert 직전
  raise log '[block_sender_and_pass] UPSERT blocks blocker=% blocked=%',
    _current_uid, _sender_user_id;
  -- 2) user_blocks에 차단 기록 (idempotent)
  -- blocked_user_id ambiguous 방지: constraint 이름 사용
  insert into public.user_blocks (
    blocker_user_id,
    blocked_user_id,
    reason_code
  )
  values (
    _current_uid,
    _sender_user_id,
    p_reason_code
  )
  on conflict on constraint user_blocks_pkey
  do update set
    reason_code = coalesce(excluded.reason_code, user_blocks.reason_code),
    updated_at = now();

  -- Server 로그 4: 숨김 처리 직전
  raise log '[block_sender_and_pass] HIDE recipientId=%', p_recipient_id;
  -- 3) journey_recipient 숨김 처리 (첫 실행인 경우만 도달)
  update public.journey_recipients
  set is_hidden = true,
      hidden_reason_code = 'HIDE_BLOCKED',
      hidden_at = _hidden_at,
      updated_at = _hidden_at
  where id = _recipient_id;

  if not found then
    raise log '[block_sender_and_pass] FAIL: update affected 0 rows (RLS blocked?)';
    raise exception 'unauthorized: rls_blocked_update';
  end if;

  raise log '[block_sender_and_pass] UPDATE SUCCESS: recipient_id=% hidden', _recipient_id;

  -- Server 로그 5: forward 직전
  raise log '[block_sender_and_pass] FORWARD journey_id=% (dedupe enforced)', _journey_id;
  -- 4) 랜덤 수신자 선정 및 전송 (pass_inbox_item_and_forward와 동일 로직)
  -- 주의: 이미 처리된 경우는 위에서 return되었으므로 여기서는 첫 실행만 도달 (중복 재전송 방지)
  select greatest(_journey.requested_recipient_count - count(*), 0)
  into _remaining
  from public.journey_recipients
  where journey_recipients.journey_id = _journey.id;

  if _remaining > 0 then
    with candidates as (
      select
        users.user_id,
        user_profiles.locale_tag
      from public.users
      left join public.user_profiles
        on user_profiles.user_id = users.user_id
      where users.user_id <> _journey.user_id
        and users.is_deleted = false
        and users.is_suspended = false
        and (users.response_suspended_until is null
          or users.response_suspended_until <= now())
        and not exists (
          select 1
          from public.journey_recipients recipients
          where recipients.journey_id = _journey.id
            and recipients.recipient_user_id = users.user_id
        )
        and not exists (
          select 1
          from public.user_blocks blocks
          where (blocks.blocker_user_id = _journey.user_id
            and blocks.blocked_user_id = users.user_id)
            or (blocks.blocker_user_id = users.user_id
            and blocks.blocked_user_id = _journey.user_id)
        )
      order by random()
      limit 1
    ),
    journey_image_count as (
      select count(*)::integer as cnt
      from public.journey_images
      where journey_images.journey_id = _journey.id
    ),
    inserted as (
      insert into public.journey_recipients (
        journey_id,
        recipient_user_id,
        recipient_locale_tag,
        sender_user_id,
        snapshot_content,
        snapshot_image_count
      )
      select
        _journey.id,
        candidates.user_id,
        candidates.locale_tag,
        _journey.user_id,
        _journey.content,
        (select cnt from journey_image_count)
      from candidates
      returning journey_recipients.recipient_user_id, journey_recipients.id
    )
    select inserted.recipient_user_id into _forwarded_recipient_id
    from inserted
    limit 1;
  end if;

  -- 6) 반환
  raise log '[block_sender_and_pass] SUCCESS: recipient_id=%, blocked_user_id=%, forwarded_recipient_id=%', 
    _recipient_id, _sender_user_id, _forwarded_recipient_id;
  return query
  select 
    true::boolean as success, 
    _recipient_id::bigint as recipient_id,
    _sender_user_id::uuid as blocked_user_id, 
    _forwarded_recipient_id::uuid as forwarded_recipient_id,
    _hidden_at::timestamptz as hidden_at;
end;
$$;

-- 기존 pass_journey 함수는 호환성을 위해 유지 (deprecated)
create or replace function public.pass_journey(
  target_journey_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- 새로운 함수로 위임
  perform * from public.pass_inbox_item_and_forward(target_journey_id);
end;
$$;

drop function if exists public.report_journey(uuid, text);

create or replace function public.report_journey(
  target_journey_id uuid,
  reason_code text
)
returns table (
  success boolean,
  report_id bigint,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_report_count integer;
  v_report_id bigint;
  v_report_created_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if reason_code is null or length(trim(reason_code)) = 0 then
    raise exception 'missing_reason';
  end if;
  if not exists (
    select 1
    from public.common_codes cc
    where cc.code_type = 'report_reason'
      and cc.code_value = reason_code
  ) then
    raise exception 'missing_code_value';
  end if;
  if not exists (
    select 1
    from public.journey_recipients jr
    where jr.journey_id = target_journey_id
      and jr.recipient_user_id = auth.uid()
  ) then
    raise exception 'unauthorized';
  end if;

  -- INSERT with RETURNING: 테이블 스키마를 명시적으로 지정하여 ambiguous 제거
  -- returns table의 created_at과 충돌 방지를 위해 public.journey_reports.created_at 명시
  insert into public.journey_reports (
    journey_id,
    reporter_user_id,
    reason_code
  )
  values (
    target_journey_id,
    auth.uid(),
    reason_code
  )
  returning id, public.journey_reports.created_at into v_report_id, v_report_created_at;

  -- journey_recipients 업데이트: 신고 상태 + 숨김 처리
  update public.journey_recipients jr
  set status_code = 'REPORTED',
      is_hidden = true,
      hidden_reason_code = 'HIDE_REPORTED',
      hidden_at = now(),
      updated_at = now()
  where jr.journey_id = target_journey_id
    and jr.recipient_user_id = auth.uid();

  -- SELECT COUNT: 테이블 alias 사용
  select count(*)
  into v_report_count
  from public.journey_reports jr
  where jr.journey_id = target_journey_id;

  if v_report_count >= 3 then
    update public.journeys j
    set filter_code = 'HELD',
        updated_at = now()
    where j.id = target_journey_id
      and j.filter_code <> 'REMOVED';
  end if;

  -- RETURN QUERY: 변수명을 v_report_created_at으로 사용
  return query
  select true as success, v_report_id as report_id, v_report_created_at as created_at;
end;
$$;

drop function if exists public.get_journey_progress(uuid);

create or replace function public.get_journey_progress(
  target_journey_id uuid
)
returns table (
  journey_id uuid,
  status_code text,
  response_target integer,
  responded_count integer,
  assigned_count integer,
  passed_count integer,
  reported_count integer,
  relay_deadline_at timestamptz,
  country_codes text[]
)
language plpgsql
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if not exists (
    select 1
    from public.journeys
    where journeys.id = target_journey_id
      and journeys.user_id = auth.uid()
  ) then
    raise exception 'unauthorized';
  end if;

  return query
  select
    journeys.id,
    journeys.status_code,
    journeys.response_target,
    (select count(*) from public.journey_recipients
      where journey_id = journeys.id and status_code = 'RESPONDED'),
    (select count(*) from public.journey_recipients
      where journey_id = journeys.id and status_code = 'ASSIGNED'),
    (select count(*) from public.journey_recipients
      where journey_id = journeys.id and status_code = 'PASSED'),
    (select count(*) from public.journey_recipients
      where journey_id = journeys.id and status_code = 'REPORTED'),
    journeys.relay_deadline_at,
    (select array_agg(distinct
        coalesce(
          nullif(split_part(recipient_locale_tag, '-', 2), ''),
          nullif(split_part(recipient_locale_tag, '_', 2), ''),
          recipient_locale_tag
        )
      )
     from public.journey_recipients
     where journey_id = journeys.id
       and recipient_locale_tag is not null)
  from public.journeys
  where journeys.id = target_journey_id;
end;
$$;

drop function if exists public.list_journey_results(uuid);

create or replace function public.list_journey_results(
  target_journey_id uuid
)
returns table (
  response_id bigint,
  content text,
  created_at timestamptz
)
language plpgsql
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if not exists (
    select 1
    from public.journeys
    where journeys.id = target_journey_id
      and journeys.user_id = auth.uid()
      and journeys.status_code = 'COMPLETED'
  ) then
    raise exception 'unauthorized';
  end if;

  return query
  select journey_responses.id,
         journey_responses.content,
         journey_responses.created_at
  from public.journey_responses
  where journey_responses.journey_id = target_journey_id
    and journey_responses.is_hidden = false
  order by journey_responses.created_at asc;
end;
$$;

drop function if exists public.list_sent_journey_replies(uuid);

create or replace function public.list_sent_journey_replies(
  target_journey_id uuid
)
returns table (
  reply_id bigint,
  content text,
  created_at timestamptz,
  responder_nickname text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if not exists (
    select 1
    from public.journeys
    where journeys.id = target_journey_id
      and journeys.user_id = auth.uid()
      and journeys.status_code = 'COMPLETED'
  ) then
    raise exception 'journey_not_ready';
  end if;

  return query
  select journey_responses.id,
         journey_responses.content,
         journey_responses.created_at,
         journey_responses.snapshot_nickname
  from public.journey_responses
  where journey_responses.journey_id = target_journey_id
    and journey_responses.is_hidden = false
  order by journey_responses.created_at asc;
end;
$$;

drop function if exists public.complete_due_journeys(integer);

create or replace function public.complete_due_journeys(
  batch_size integer
)
returns table (
  journey_id uuid,
  user_id uuid,
  device_token text,
  locale_tag text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  _limit integer := greatest(coalesce(batch_size, 10), 1);
begin
  if auth.role() <> 'service_role' then
    raise exception 'unauthorized';
  end if;

  with due as (
    select journeys.id, journeys.user_id
    from public.journeys
    where journeys.filter_code = 'OK'
      and journeys.status_code <> 'COMPLETED'
      and (
        (select count(*) from public.journey_responses
          where journey_responses.journey_id = journeys.id) >= journeys.response_target
        or now() >= journeys.relay_deadline_at
      )
    order by journeys.created_at asc
    limit _limit
  ),
  updated as (
    update public.journeys
    set status_code = 'COMPLETED',
        updated_at = now()
    where id in (select id from due)
    returning id, user_id
  ),
  notify_targets as (
    select updated.id as journey_id, updated.user_id
    from updated
    where exists (
      select 1
      from public.journeys
      where journeys.id = updated.id
        and journeys.result_notified_at is null
    )
  ),
  marked as (
    update public.journeys
    set result_notified_at = now()
    where id in (select journey_id from notify_targets)
    returning id
  ),
  tokens as (
    select distinct on (notify_targets.user_id)
      notify_targets.journey_id,
      notify_targets.user_id,
      device_tokens.token,
      user_profiles.locale_tag
    from notify_targets
    join public.device_tokens
      on device_tokens.user_id = notify_targets.user_id
    left join public.user_profiles
      on user_profiles.user_id = notify_targets.user_id
    where device_tokens.is_active = true
    order by notify_targets.user_id, device_tokens.last_seen_at desc
  )
  select
    tokens.journey_id,
    tokens.user_id,
    tokens.token,
    tokens.locale_tag
  from tokens;
end;
$$;

drop function if exists public.match_journey(uuid);

create or replace function public.match_journey(
  target_journey_id uuid
)
returns table (
  journey_id uuid,
  recipient_user_id uuid,
  device_token text,
  platform text,
  device_id text,
  locale_tag text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  _journey public.journeys%rowtype;
  _remaining integer;
begin
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;

  select * into _journey
  from public.journeys
  where id = target_journey_id;

  if not found then
    raise exception 'journey_not_found';
  end if;

  if auth.uid() is null and auth.role() <> 'service_role' then
    raise exception 'unauthorized';
  end if;

  if auth.uid() is not null and auth.uid() <> _journey.user_id then
    raise exception 'unauthorized';
  end if;

  if _journey.filter_code <> 'OK' then
    return;
  end if;

  select greatest(_journey.requested_recipient_count - count(*), 0)
  into _remaining
  from public.journey_recipients
  where journey_recipients.journey_id = _journey.id;

  if _remaining <= 0 then
    return;
  end if;

  return query
  with candidates as (
    select
      users.user_id,
      user_profiles.locale_tag
    from public.users
    left join public.user_profiles
      on user_profiles.user_id = users.user_id
    where users.user_id <> _journey.user_id
      and users.is_deleted = false
      and users.is_suspended = false
      and (users.response_suspended_until is null
        or users.response_suspended_until <= now())
      and not exists (
        select 1
        from public.journey_recipients recipients
        where recipients.journey_id = _journey.id
          and recipients.recipient_user_id = users.user_id
      )
      and not exists (
        select 1
        from public.user_blocks blocks
        where (blocks.blocker_user_id = _journey.user_id
          and blocks.blocked_user_id = users.user_id)
          or (blocks.blocker_user_id = users.user_id
          and blocks.blocked_user_id = _journey.user_id)
      )
    order by random()
    limit _remaining
  ),
  -- 스냅샷용 이미지 개수 계산
  journey_image_count as (
    select count(*)::integer as cnt
    from public.journey_images
    where journey_images.journey_id = _journey.id
  ),
  inserted as (
    insert into public.journey_recipients (
      journey_id,
      recipient_user_id,
      recipient_locale_tag,
      -- 스냅샷 필드: journeys JOIN 없이 인박스 조회 가능 (RLS 유지)
      sender_user_id,
      snapshot_content,
      snapshot_image_count
    )
    select
      _journey.id,
      candidates.user_id,
      candidates.locale_tag,
      _journey.user_id,
      _journey.content,
      (select cnt from journey_image_count)
    from candidates
    returning journey_recipients.recipient_user_id
  ),
  tokens as (
    select distinct on (inserted.recipient_user_id)
      inserted.recipient_user_id,
      device_tokens.token,
      device_tokens.platform,
      device_tokens.device_id,
      user_profiles.locale_tag
    from inserted
    join public.device_tokens
      on device_tokens.user_id = inserted.recipient_user_id
    left join public.user_profiles
      on user_profiles.user_id = inserted.recipient_user_id
    where device_tokens.is_active = true
    order by inserted.recipient_user_id, device_tokens.last_seen_at desc
  )
  select
    _journey.id as journey_id,
    tokens.recipient_user_id,
    tokens.token as device_token,
    tokens.platform,
    tokens.device_id,
    tokens.locale_tag
  from tokens;

  if exists (
    select 1
    from public.journey_recipients
    where journey_recipients.journey_id = _journey.id
  ) then
    update public.journeys
    set status_code = 'CREATED',
        updated_at = now()
    where id = _journey.id
      and status_code <> 'COMPLETED';
  end if;
end;
$$;

drop function if exists public.match_pending_journeys(integer);

create or replace function public.match_pending_journeys(
  batch_size integer
)
returns table (
  journey_id uuid,
  recipient_user_id uuid,
  device_token text,
  platform text,
  device_id text,
  locale_tag text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  _journey_id uuid;
  _limit integer := greatest(coalesce(batch_size, 10), 1);
begin
  if auth.role() <> 'service_role' then
    raise exception 'unauthorized';
  end if;

  for _journey_id in
    select journeys.id
    from public.journeys
    where journeys.filter_code = 'OK'
      and journeys.status_code in ('WAITING', 'CREATED')
      and journeys.requested_recipient_count > (
        select count(*)
        from public.journey_recipients
        where journey_recipients.journey_id = journeys.id
      )
    order by journeys.created_at asc
    limit _limit
  loop
    return query
    select *
    from public.match_journey(_journey_id);
  end loop;
end;
$$;

create or replace function public.log_client_error(
  error_context text,
  status_code integer,
  error_message text,
  meta jsonb,
  device_id text
)
returns void
language plpgsql
as $$
begin
  if error_context is null or length(trim(error_context)) = 0 then
    raise exception 'missing_context';
  end if;

  insert into public.client_error_logs (
    user_id,
    device_id,
    error_context,
    status_code,
    error_message,
    meta
  )
  values (
    auth.uid(),
    device_id,
    error_context,
    status_code,
    error_message,
    meta
  );
end;
$$;

create or replace function public.log_ad_reward_event(
  p_journey_id uuid,
  p_placement_code text,
  p_env_code text,
  p_ad_unit_id text,
  p_event_code text,
  p_req_id text default null,
  p_metadata jsonb default null
)
returns void
language plpgsql
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if p_placement_code is null or length(trim(p_placement_code)) = 0 then
    raise exception 'missing_placement';
  end if;
  if p_env_code is null or length(trim(p_env_code)) = 0 then
    raise exception 'missing_env';
  end if;
  if p_event_code is null or length(trim(p_event_code)) = 0 then
    raise exception 'missing_event';
  end if;

  insert into public.ad_reward_logs (
    user_id,
    journey_id,
    placement_code,
    env_code,
    ad_network_code,
    ad_unit_id,
    event_code,
    req_id,
    metadata
  )
  values (
    auth.uid(),
    p_journey_id,
    p_placement_code,
    p_env_code,
    'ADMOB',
    p_ad_unit_id,
    p_event_code,
    p_req_id,
    p_metadata
  );
end;
$$;

drop function if exists public.upsert_reward_unlock(uuid);

create or replace function public.upsert_reward_unlock(
  p_journey_id uuid
)
returns table (
  success boolean,
  journey_id uuid,
  unlocked boolean,
  unlocked_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_journey_id uuid;
  v_unlocked_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if p_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if not exists (
    select 1
    from public.journeys
    where journeys.id = p_journey_id
      and journeys.user_id = auth.uid()
      and journeys.status_code = 'COMPLETED'
  ) then
    raise exception 'journey_not_found';
  end if;

  insert into public.reward_unlocks (
    user_id,
    journey_id,
    unlocked_by_code
  )
  values (
    auth.uid(),
    p_journey_id,
    'ADMOB_REWARDED'
  )
  on conflict (user_id, journey_id) do update
    set unlocked_by_code = reward_unlocks.unlocked_by_code
  returning reward_unlocks.journey_id, reward_unlocks.unlocked_at
  into v_journey_id, v_unlocked_at;

  return query
  select true, v_journey_id, true, v_unlocked_at;
end;
$$;

-- UNREGISTERED FCM 토큰 무효화 (Edge Function에서 호출)
create or replace function public.invalidate_device_token(
  p_token text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- service_role만 호출 가능 (Edge Function에서만 호출)
  if auth.role() <> 'service_role' then
    raise exception 'unauthorized';
  end if;

  -- 토큰을 비활성화
  update public.device_tokens
  set is_active = false,
      updated_at = now()
  where token = p_token;
end;
$$;
