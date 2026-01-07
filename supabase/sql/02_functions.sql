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
  filter_code text
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
    journeys.filter_code
  from public.journeys
  where journeys.user_id = auth.uid()
  order by journeys.created_at desc
  limit least(coalesce(page_size, 20), 50)
  offset greatest(coalesce(page_offset, 0), 0);
end;
$$;

drop function if exists public.list_inbox_journeys(integer, integer);

-- 인박스 조회: journey_recipients 스냅샷 필드 사용 (journeys JOIN 제거, RLS 유지)
create or replace function public.list_inbox_journeys(
  page_size integer,
  page_offset integer
)
returns table (
  journey_id uuid,
  sender_user_id uuid,
  content text,
  created_at timestamptz,
  image_count integer,
  recipient_status text
)
language plpgsql
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;

  return query
  select
    jr.journey_id,
    jr.sender_user_id,
    jr.snapshot_content as content,
    jr.created_at,
    jr.snapshot_image_count as image_count,
    jr.status_code as recipient_status
  from public.journey_recipients jr
  where jr.recipient_user_id = auth.uid()
    -- 스냅샷 필드가 존재하는 경우만 (마이그레이션 이전 데이터 제외)
    and jr.sender_user_id is not null
  order by jr.created_at desc
  limit least(coalesce(page_size, 20), 50)
  offset greatest(coalesce(page_offset, 0), 0);
end;
$$;

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

  insert into public.journey_responses (
    journey_id,
    responder_user_id,
    content
  )
  values (
    target_journey_id,
    auth.uid(),
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

create or replace function public.pass_journey(
  target_journey_id uuid
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
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if not exists (
    select 1
    from public.journey_recipients
    where journey_recipients.journey_id = target_journey_id
      and journey_recipients.recipient_user_id = auth.uid()
      and journey_recipients.status_code = 'ASSIGNED'
  ) then
    raise exception 'unauthorized';
  end if;

  update public.journey_recipients
  set status_code = 'PASSED',
      updated_at = now()
  where journey_id = target_journey_id
    and recipient_user_id = auth.uid();
end;
$$;

drop function if exists public.report_journey(uuid, text);

create or replace function public.report_journey(
  target_journey_id uuid,
  reason_code text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _report_count integer;
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
    from public.common_codes
    where code_type = 'report_reason'
      and code_value = reason_code
  ) then
    raise exception 'missing_code_value';
  end if;
  if not exists (
    select 1
    from public.journey_recipients
    where journey_recipients.journey_id = target_journey_id
      and journey_recipients.recipient_user_id = auth.uid()
  ) then
    raise exception 'unauthorized';
  end if;

  insert into public.journey_reports (
    journey_id,
    reporter_user_id,
    reason_code
  )
  values (
    target_journey_id,
    auth.uid(),
    reason_code
  );

  update public.journey_recipients
  set status_code = 'REPORTED',
      updated_at = now()
  where journey_id = target_journey_id
    and recipient_user_id = auth.uid();

  select count(*)
  into _report_count
  from public.journey_reports
  where journey_id = target_journey_id;

  if _report_count >= 3 then
    update public.journeys
    set filter_code = 'HELD',
        updated_at = now()
    where id = target_journey_id
      and filter_code <> 'REMOVED';
  end if;
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
