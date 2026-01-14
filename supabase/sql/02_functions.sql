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

-- 닉네임 가용 여부 체크 RPC
-- 파라미터명 변경을 위해 기존 함수 삭제 후 재생성
drop function if exists public.check_nickname_available(text);

create or replace function public.check_nickname_available(
  nickname text
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_normalized text;
  v_compact text;
  v_exists boolean;
  v_forbidden_word text;
begin
  -- 입력 검증
  -- 함수명을 명시적으로 사용하여 파라미터 참조
  if check_nickname_available.nickname is null or length(trim(check_nickname_available.nickname)) = 0 then
    return false;
  end if;

  -- 정규화 (lower(trim))
  v_normalized := lower(trim(check_nickname_available.nickname));
  -- compact (띄어쓰기/언더스코어 제거)
  v_compact := regexp_replace(v_normalized, '[_\s]+', '', 'g');

  -- 금칙어 체크 (정규화 + compact 기준)
  select word into v_forbidden_word
  from public.forbidden_words
  where is_enabled = true
    and (
      v_normalized like '%' || word || '%'
      or v_compact like '%' || regexp_replace(word, '[_\s]+', '', 'g') || '%'
    )
  limit 1;

  if v_forbidden_word is not null then
    return false; -- 금칙어 포함
  end if;

  -- 현재 사용자의 닉네임과 동일하면 사용 가능
  select exists(
    select 1
    from public.user_profiles
    where user_id = auth.uid()
      and nickname_norm = v_normalized
  ) into v_exists;

  if v_exists then
    return true; -- 자신의 닉네임이면 사용 가능
  end if;

  -- 다른 사용자가 사용 중인지 확인
  select exists(
    select 1
    from public.user_profiles
    where nickname_norm = v_normalized
  ) into v_exists;

  return not v_exists; -- 사용 중이면 false, 없으면 true
end;
$$;

-- 프로필 업데이트 RPC (유니크 보장 포함)
-- 파라미터명 변경을 위해 기존 함수 삭제 후 재생성
drop function if exists public.update_my_profile(text, text, text);

create or replace function public.update_my_profile(
  nickname text default null,
  avatar_url text default null,
  bio text default null
)
returns setof public.user_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_normalized text;
  v_compact text;
  v_nickname text;
  v_avatar_url text;
  v_bio text;
  v_forbidden_word text;
begin
  -- 파라미터를 로컬 변수로 복사 (컬럼명과 충돌 방지)
  -- 함수명을 명시적으로 사용하여 파라미터 참조
  v_nickname := update_my_profile.nickname;
  v_avatar_url := update_my_profile.avatar_url;
  v_bio := update_my_profile.bio;

  -- 닉네임이 변경되는 경우 검증
  if v_nickname is not null then
    v_normalized := lower(trim(v_nickname));
    v_compact := regexp_replace(v_normalized, '[_\s]+', '', 'g');
    
    -- 금칙어 체크 (정규화 + compact 기준)
    select word into v_forbidden_word
    from public.forbidden_words
    where is_enabled = true
      and (
        v_normalized like '%' || word || '%'
        or v_compact like '%' || regexp_replace(word, '[_\s]+', '', 'g') || '%'
      )
    limit 1;

    if v_forbidden_word is not null then
      raise exception using
        errcode = 'P0001',
        message = 'nickname_forbidden',
        detail = 'Nickname contains forbidden word';
    end if;
    
    -- 다른 사용자가 이미 사용 중인지 확인 (자신의 닉네임 제외)
    if exists(
      select 1
      from public.user_profiles
      where nickname_norm = v_normalized
        and user_id != auth.uid()
    ) then
      raise exception using
        errcode = 'P0001',
        message = 'nickname_taken',
        detail = 'Nickname is already taken';
    end if;
  end if;

  -- 프로필 업데이트 (부분 업데이트: null이 아닌 값만 업데이트)
  insert into public.user_profiles (user_id, nickname, avatar_url, bio, locale_tag)
  values (auth.uid(), v_nickname, v_avatar_url, v_bio, null)
  on conflict on constraint user_profiles_pkey
  do update set
    nickname = case when excluded.nickname is not null then excluded.nickname else user_profiles.nickname end,
    avatar_url = case when excluded.avatar_url is not null then excluded.avatar_url else user_profiles.avatar_url end,
    bio = case when excluded.bio is not null then excluded.bio else user_profiles.bio end,
    updated_at = now();

  return query
  select p.*
  from public.user_profiles p
  where p.user_id = auth.uid();
end;
$$;

-- 기존 upsert_my_profile은 하위 호환성을 위해 유지 (내부적으로 update_my_profile 호출)
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
security definer
set search_path = public
as $$
begin
  return query
  select * from public.update_my_profile(_nickname, _avatar_url, _bio);
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

-- ✅ 반환 타입 변경을 위해 기존 함수 DROP
drop function if exists public.unblock_user(uuid);

create or replace function public.unblock_user(
  target_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  _current_uid uuid;
  _restored_count integer := 0;
begin
  -- ✅ auth.uid() 필터 강제 (데이터 노출 방지)
  _current_uid := auth.uid();
  if _current_uid is null then
    raise exception using
      errcode = 'P0001',
      message = 'unauthorized',
      detail = 'User must be authenticated';
  end if;

  if target_user_id is null then
    raise exception using
      errcode = 'P0001',
      message = 'missing_user',
      detail = 'target_user_id is required';
  end if;

  -- 1) user_blocks에서 차단 기록 삭제
  delete from public.user_blocks
  where blocker_user_id = _current_uid
    and blocked_user_id = target_user_id;

  -- 2) block 사유로 숨겨진 journey_recipients 복구
  -- ✅ 조건: recipient_user_id = 현재 사용자 AND sender_user_id = 차단 해제 대상
  -- ✅ hidden_reason_code = 'HIDE_BLOCKED'인 것만 복구 (moderation/report 등 다른 사유는 복구하지 않음)
  -- ✅ RLS 때문에 JOIN 불가하므로 snapshot 필드(sender_user_id)만 사용
  update public.journey_recipients
  set is_hidden = false,
      hidden_reason_code = null,
      hidden_at = null,
      updated_at = now()
  where recipient_user_id = _current_uid
    and sender_user_id = target_user_id
    and is_hidden = true
    and hidden_reason_code = 'HIDE_BLOCKED';

  -- 복구된 row 수 확인
  get diagnostics _restored_count = row_count;

  -- ✅ jsonb로 반환 (운영/검증 가능)
  return jsonb_build_object(
    'ok', true,
    'restored_count', _restored_count
  );
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

-- ============================================================================
-- FCM 발송 결과 UPDATE 함수
-- ============================================================================
create or replace function public.update_notification_fcm_result(
  p_user_id uuid,
  p_journey_id uuid,
  p_fcm_status text,
  p_fcm_error text default null,
  p_fcm_message_id text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- notification_logs를 (user_id, journey_id)로 찾아 FCM 결과를 UPDATE
  update public.notification_logs nl
  set
    fcm_status = p_fcm_status,
    fcm_sent_at = now(),
    fcm_error = p_fcm_error,
    fcm_message_id = p_fcm_message_id,
    updated_at = now()
  where
    nl.user_id = p_user_id
    and (nl.data->>'journey_id') = p_journey_id::text;

  -- row가 없어도 예외 없이 종료 (best-effort)
exception
  when others then
    raise warning '[update_notification_fcm_result] Failed for user=%, journey=%: %',
      p_user_id, p_journey_id, sqlerrm;
end;
$$;

comment on function public.update_notification_fcm_result(uuid, uuid, text, text, text) is
  'Edge Function이 FCM 발송 후 결과를 notification_logs에 UPDATE.
  세션 독립(service_role 전용), best-effort 정책.';

-- service_role이 함수 실행 가능하도록 권한 부여
grant execute on function public.update_notification_fcm_result(uuid, uuid, text, text, text) to service_role;

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
    and logs.read_at is null;
$$;

create or replace function public.get_unread_notification_count()
returns integer
language sql
security definer
set search_path = public
as $$
  select public.count_my_unread_notifications();
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
    from public.common_codes as cc
    where cc.code_type = 'report_reason'
      and cc.code_value = reason_code
  ) then
    raise exception 'missing_code_value';
  end if;

  select jr.journey_id,
         jr.responder_user_id
  into _journey_id, _response_owner
  from public.journey_responses as jr
  where jr.id = target_response_id;

  if _journey_id is null then
    raise exception 'response_not_found';
  end if;
  if _response_owner is null then
    raise exception 'response_not_found';
  end if;

  if not exists (
    select 1
    from public.journeys as j
    where j.id = _journey_id
      and j.user_id = auth.uid()
  ) then
    raise exception 'unauthorized';
  end if;

  insert into public.journey_response_reports as jrr (
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
  from public.journey_response_reports as jrr
  where jrr.response_id = target_response_id;

  if _response_report_count >= 2 then
    update public.journey_responses as jr
    set is_hidden = true,
        updated_at = now()
    where jr.id = target_response_id;
  end if;

  select count(*)
  into _user_report_count
  from public.journey_response_reports as reports
  join public.journey_responses as responses
    on responses.id = reports.response_id
  where responses.responder_user_id = _response_owner;

  if _user_report_count >= 5 then
    update public.users as u
    set response_suspended_until = greatest(
          coalesce(u.response_suspended_until, now()),
          now() + interval '7 days'
        ),
        updated_at = now()
    where u.user_id = _response_owner;
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

drop function if exists public.create_journey(text, text, text[], integer);

create or replace function public.create_journey(
  content text,
  language_tag text,
  image_paths text[],
  recipient_count integer
)
returns table (
  journey_id uuid,
  journey_created_at timestamptz,
  moderation_status text,
  content_clean text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  _journey_id uuid;
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
    from public.common_codes as cc
    where cc.code_type = 'journey_status'
      and cc.code_value = 'WAITING'
  ) then
    raise exception 'missing_code_value';
  end if;
  if not exists (
    select 1
    from public.common_codes as cc
    where cc.code_type = 'journey_filter_status'
      and cc.code_value = 'OK'
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

  insert into public.journeys as j (
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
  returning j.id into _journey_id;

  if image_paths is not null then
    foreach _image_path in array image_paths loop
      insert into public.journey_images as ji (
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

  insert into public.journey_dispatch_jobs as jdj (
    journey_id, status, attempt_count, next_run_at, last_error, created_at, updated_at
  )
  values (
    _journey_id, 'pending', 0, now(), null, now(), now()
  )
  on conflict on constraint journey_dispatch_jobs_pkey do update
  set status = 'pending',
      attempt_count = 0,
      next_run_at = now(),
      last_error = null,
      updated_at = now();

  return query
  select
    j.id as journey_id,
    j.created_at as journey_created_at,
    j.moderation_status,
    j.content_clean
  from public.journeys as j
  where j.id = _journey_id;
end;
$$;

drop function if exists public.process_journey_dispatch_jobs(integer);

create or replace function public.process_journey_dispatch_jobs(
  p_batch integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_batch integer;
  v_job_id uuid;
  v_journey record;
  v_assigned_count integer;
  v_processed_count integer := 0;
  v_failed_count integer := 0;
  v_error_message text;
begin
  if auth.role() <> 'service_role' then
    raise exception using
      errcode = 'P0001',
      message = 'unauthorized',
      detail = 'This function can only be called by service_role';
  end if;

  v_batch := greatest(least(coalesce(p_batch, 20), 100), 1);

  for v_job_id in
    select jdj.journey_id
    from public.journey_dispatch_jobs as jdj
    where jdj.status in ('pending', 'failed')
      and jdj.next_run_at <= now()
    order by jdj.next_run_at asc
    limit v_batch
    for update skip locked
  loop
    begin
      update public.journey_dispatch_jobs as jdj
      set status = 'processing',
          updated_at = now()
      where jdj.journey_id = v_job_id;

      select j.* into v_journey
      from public.journeys as j
      where j.id = v_job_id;

      if not found then
        update public.journey_dispatch_jobs as jdj
        set status = 'done',
            updated_at = now()
        where jdj.journey_id = v_job_id;

        v_processed_count := v_processed_count + 1;
        continue;
      end if;

      select count(*) into v_assigned_count
      from public.journey_recipients as jr
      where jr.journey_id = v_job_id;

      if v_assigned_count >= v_journey.requested_recipient_count then
        update public.journey_dispatch_jobs as jdj
        set status = 'done',
            last_error = null,
            updated_at = now()
        where jdj.journey_id = v_job_id;

        update public.journeys as j
        set status_code = 'CREATED',
            updated_at = now()
        where j.id = v_job_id
          and j.status_code = 'WAITING';

        v_processed_count := v_processed_count + 1;
        continue;
      end if;

      perform public.match_journey(v_job_id);

      select count(*) into v_assigned_count
      from public.journey_recipients as jr
      where jr.journey_id = v_job_id;

      if v_assigned_count > 0 then
        update public.journey_dispatch_jobs as jdj
        set status = 'done',
            last_error = null,
            updated_at = now()
        where jdj.journey_id = v_job_id;

        update public.journeys as j
        set status_code = 'CREATED',
            updated_at = now()
        where j.id = v_job_id
          and j.status_code = 'WAITING';

        v_processed_count := v_processed_count + 1;
      else
        update public.journey_dispatch_jobs as jdj
        set status = 'failed',
            attempt_count = jdj.attempt_count + 1,
            last_error = 'no_recipients_found',
            next_run_at = least(
              now() + (power(2, (jdj.attempt_count + 1))::integer * interval '30 seconds'),
              now() + interval '30 minutes'
            ),
            updated_at = now()
        where jdj.journey_id = v_job_id;

        v_failed_count := v_failed_count + 1;
      end if;
    exception
      when others then
        get stacked diagnostics v_error_message = message_text;

        update public.journey_dispatch_jobs as jdj
        set status = 'failed',
            attempt_count = jdj.attempt_count + 1,
            last_error = v_error_message,
            next_run_at = least(
              now() + (power(2, (jdj.attempt_count + 1))::integer * interval '30 seconds'),
              now() + interval '30 minutes'
            ),
            updated_at = now()
        where jdj.journey_id = v_job_id;

        v_failed_count := v_failed_count + 1;
    end;
  end loop;

  return jsonb_build_object(
    'ok', true,
    'processed', v_processed_count,
    'failed', v_failed_count,
    'batch_size', v_batch
  );
end;
$$;

drop function if exists public.repair_missing_dispatch_jobs(integer);

create or replace function public.repair_missing_dispatch_jobs(
  p_limit integer default 500
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_limit integer;
  v_inserted integer;
begin
  v_limit := greatest(least(coalesce(p_limit, 500), 2000), 1);

  with missing_jobs as (
    select
      j.id as journey_id
    from public.journeys as j
    where j.status_code = 'WAITING'
      and not exists (
        select 1
        from public.journey_dispatch_jobs as jdj
        where jdj.journey_id = j.id
      )
    order by j.created_at desc
    limit v_limit
  )
  insert into public.journey_dispatch_jobs as jdj (
    journey_id, status, attempt_count, next_run_at, last_error, created_at, updated_at
  )
  select
    mj.journey_id,
    'pending',
    0,
    now(),
    null,
    now(),
    now()
  from missing_jobs as mj
  on conflict on constraint journey_dispatch_jobs_pkey do nothing;

  get diagnostics v_inserted = row_count;

  return jsonb_build_object(
    'ok', true,
    'inserted', v_inserted,
    'limit', v_limit
  );
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
  is_reward_unlocked boolean,
  sent_count integer,
  responded_count integer,
  requested_recipient_count integer,
  assigned_count integer
)
language plpgsql
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;

  return query
  select
    j.id as journey_id,
    j.content,
    j.created_at,
    (
      select count(*)
      from public.journey_images ji
      where ji.journey_id = j.id
    )::integer as image_count,
    j.status_code,
    j.filter_code,
    (
      j.status_code = 'COMPLETED'
      and exists (
        select 1
        from public.reward_unlocks ru
        where ru.user_id = auth.uid()
          and ru.journey_id = j.id
      )
    ) as is_reward_unlocked,
    (
      select count(*)
      from public.journey_recipients jr
      where jr.journey_id = j.id
    )::integer as sent_count,
    (
      select count(*)
      from public.journey_responses jresp
      where jresp.journey_id = j.id
        and jresp.is_hidden = false
    )::integer as responded_count,
    j.requested_recipient_count::integer as requested_recipient_count,
    (
      select count(*)
      from public.journey_recipients jr
      where jr.journey_id = j.id
        and jr.status_code = 'ASSIGNED'
    )::integer as assigned_count
  from public.journeys j
  where j.user_id = auth.uid()
    -- 소프트삭제된 여정 제외
    and j.filter_code <> 'REMOVED'
  order by j.created_at desc
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

-- 인박스 journey의 snapshot_image_paths 조회 (전용 RPC)
-- 반환: jsonb { ok, journey_id, recipient_user_id, snapshot_image_count, snapshot_image_paths }
create or replace function public.get_inbox_journey_snapshot_image_paths(
  p_journey_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  _journey_id uuid;
  _recipient_user_id uuid;
  _snapshot_image_count integer;
  _snapshot_image_paths text[];
begin
  if p_journey_id is null then
    raise exception using errcode='P0001', message='missing_journey';
  end if;

  -- auth.uid() 필터 강제 (데이터 노출 방지)
  if auth.uid() is null then
    raise exception using errcode='P0001', message='unauthorized';
  end if;

  -- journey_recipients에서 snapshot_image_paths 조회
  select
    journey_recipients.journey_id,
    journey_recipients.recipient_user_id,
    journey_recipients.snapshot_image_count,
    journey_recipients.snapshot_image_paths
  into
    _journey_id,
    _recipient_user_id,
    _snapshot_image_count,
    _snapshot_image_paths
  from public.journey_recipients
  where journey_recipients.journey_id = p_journey_id
    and journey_recipients.recipient_user_id = auth.uid();

  if not found then
    raise exception using
      errcode='P0001',
      message='inbox_not_found',
      detail=format('journey_id=%s, recipient_user_id=%s', p_journey_id, auth.uid());
  end if;

  -- jsonb 반환
  return jsonb_build_object(
    'ok', true,
    'journey_id', _journey_id,
    'recipient_user_id', _recipient_user_id,
    'snapshot_image_count', coalesce(_snapshot_image_count, 0),
    'snapshot_image_paths', coalesce(_snapshot_image_paths, array[]::text[])
  );
end;
$$;

-- 디버그용: Storage 객체 존재 여부 확인 (로컬 디버깅 전용)
-- kDebugMode에서만 호출하도록 클라이언트에서 가드 필요
create or replace function public.debug_check_storage_objects(
  p_bucket text,
  p_paths text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  _result jsonb := '[]'::jsonb;
  _path text;
  _obj_record record;
begin
  if p_bucket is null or p_paths is null or array_length(p_paths, 1) is null then
    raise exception using errcode='P0001', message='invalid_arguments';
  end if;

  -- 각 path별로 storage.objects 조회
  foreach _path in array p_paths loop
    select
      exists(select 1 from storage.objects where bucket_id = p_bucket and name = _path) as exists,
      (select name from storage.objects where bucket_id = p_bucket and name = _path limit 1) as found_name,
      p_bucket as bucket_id
    into _obj_record;

    _result := _result || jsonb_build_array(
      jsonb_build_object(
        'path', _path,
        'exists', coalesce(_obj_record.exists, false),
        'found_name', _obj_record.found_name,
        'bucket_id', _obj_record.bucket_id
      )
    );
  end loop;

  return _result;
end;
$$;

-- 기존 함수는 유지 (하위 호환성)
create or replace function public.list_inbox_journey_images(
  target_journey_id uuid
)
returns table (
  storage_path text
)
language plpgsql
as $$
declare
  _image_paths text[];
begin
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;

  -- recipients의 snapshot_image_paths 조회 (JOIN 없이 RLS 우회)
  select journey_recipients.snapshot_image_paths
  into _image_paths
  from public.journey_recipients
  where journey_recipients.journey_id = target_journey_id
    and journey_recipients.recipient_user_id = auth.uid();

  if not found then
    -- 수신자가 아닌 경우 발신자인지 확인 (자신이 보낸 메시지 조회)
    if exists (
      select 1
      from public.journeys
      where journeys.id = target_journey_id
        and journeys.user_id = auth.uid()
    ) then
      -- 발신자인 경우 journey_images에서 직접 조회
      return query
      select journey_images.storage_path
      from public.journey_images
      where journey_images.journey_id = target_journey_id
      order by journey_images.created_at asc;
      return;
    else
      raise exception 'unauthorized';
    end if;
  end if;

  -- snapshot_image_paths가 null이거나 비어있으면 빈 결과 반환
  if _image_paths is null or array_length(_image_paths, 1) is null then
    return;
  end if;

  -- 배열을 행으로 변환하여 반환
  return query
  select unnest(_image_paths) as storage_path;
end;
$$;

drop function if exists public.respond_journey(uuid, text);

create or replace function public.respond_journey(
  target_journey_id uuid,
  response_content text
)
returns table (
  journey_id uuid,
  completed boolean,
  moderation_status text,
  content_clean text
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
  from public.journey_responses jr
  where jr.journey_id = target_journey_id;

  -- 트리거가 moderation을 적용한 후 조회
  declare
    _moderation_status text;
    _content_clean text;
  begin
    select jr.moderation_status, jr.content_clean
    into _moderation_status, _content_clean
    from public.journey_responses jr
    where jr.journey_id = target_journey_id
      and jr.responder_user_id = auth.uid()
    order by jr.created_at desc
    limit 1;

    if _response_count >= _target then
      update public.journeys
      set status_code = 'COMPLETED',
          updated_at = now()
      where journeys.id = target_journey_id
        and journeys.status_code <> 'COMPLETED';
      return query
      select target_journey_id, true, _moderation_status, _content_clean;
    else
      return query
      select target_journey_id, false, _moderation_status, _content_clean;
    end if;
  end;
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
  _current_status text;
  _journey public.journeys%rowtype;
  _remaining integer;
  _forwarded_recipient_id uuid;
  _passed_at timestamptz := now();
  _already_processed boolean := false;
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;
  if target_journey_id is null then
    raise exception 'missing_journey';
  end if;

  -- 1) journey_recipient 조회 및 권한 체크 (idempotency: 이미 처리된 경우 감지)
  select jr.id, jr.status_code
  into _recipient_id, _current_status
  from public.journey_recipients jr
  where jr.journey_id = target_journey_id
    and jr.recipient_user_id = auth.uid();

  -- 권한 체크: 해당 recipient가 없으면 unauthorized
  if _recipient_id is null then
    raise exception 'unauthorized';
  end if;

  -- Idempotency: 이미 PASSED 또는 RESPONDED 상태면 forward 건너뛰고 즉시 반환
  if _current_status in ('PASSED', 'RESPONDED') then
    _already_processed := true;
    -- 이미 처리된 경우 passed_at을 현재 시간이 아닌 기존 updated_at 반환
    select jr.updated_at into _passed_at
    from public.journey_recipients jr
    where jr.id = _recipient_id;

    return query
    select true as success, _passed_at as passed_at, null::uuid as forwarded_recipient_id;
    return;
  end if;

  -- 여기부터는 status_code = 'ASSIGNED'인 경우만 도달 (첫 실행)

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
    journey_image_paths as (
      select array_agg(storage_path order by created_at asc) as paths
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
        snapshot_image_count,
        snapshot_image_paths
      )
      select
        _journey.id,
        candidates.user_id,
        candidates.locale_tag,
        _journey.user_id,
        _journey.content,
        (select cnt from journey_image_count),
        (select paths from journey_image_paths)
      from candidates
      returning journey_recipients.recipient_user_id, journey_recipients.id
    )
    select inserted.recipient_user_id into _forwarded_recipient_id
    from inserted
    limit 1;
  end if;

  -- 4) 현재 journey_recipient의 snapshot_content를 placeholder로 redaction
  --    (보안: passed된 메시지는 내용을 볼 수 없도록)
  --    경쟁 조건 방지: status_code가 ASSIGNED인 경우에만 업데이트
  update public.journey_recipients
  set status_code = 'PASSED',
      snapshot_content = '[패스한 메시지]',
      snapshot_image_count = 0,
      snapshot_image_paths = null,
      updated_at = _passed_at
  where id = _recipient_id
    and status_code = 'ASSIGNED';

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
    journey_image_paths as (
      select array_agg(storage_path order by created_at asc) as paths
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
        snapshot_image_count,
        snapshot_image_paths
      )
      select
        _journey.id,
        candidates.user_id,
        candidates.locale_tag,
        _journey.user_id,
        _journey.content,
        (select cnt from journey_image_count),
        (select paths from journey_image_paths)
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
  v_recipient_count integer;
  v_threshold integer;
  v_report_id bigint;
  v_report_created_at timestamptz;
  v_already_reported boolean;
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

  -- 중복 신고 체크: UNIQUE 제약으로 방지되지만, 명시적 에러 메시지를 위해 사전 체크
  select exists (
    select 1
    from public.journey_reports jr
    where jr.journey_id = target_journey_id
      and jr.reporter_user_id = auth.uid()
  ) into v_already_reported;

  if v_already_reported then
    raise exception 'already_reported' using errcode = '23505';
  end if;

  -- 실제 수신자 수 계산
  select count(*)
  into v_recipient_count
  from public.journey_recipients jr
  where jr.journey_id = target_journey_id;

  -- 임계치 계산: floor(N/2)+1
  -- N=1→1, N=2→2, N=3→2, N=4→3, N=5→3
  v_threshold := floor(v_recipient_count::numeric / 2)::integer + 1;

  -- INSERT with RETURNING: 테이블 스키마를 명시적으로 지정하여 ambiguous 제거
  -- UNIQUE 제약으로 중복 신고 방지 (1인 1신고 강제)
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

  -- journey_recipients 업데이트: 신고자에게만 즉시 숨김 처리 (개별 hide)
  update public.journey_recipients jr
  set status_code = 'REPORTED',
      is_hidden = true,
      hidden_reason_code = 'HIDE_REPORTED',
      hidden_at = now(),
      updated_at = now()
  where jr.journey_id = target_journey_id
    and jr.recipient_user_id = auth.uid();

  -- 유니크 신고자 수 계산 (DISTINCT reporter_user_id)
  select count(distinct reporter_user_id)
  into v_report_count
  from public.journey_reports jr
  where jr.journey_id = target_journey_id;

  -- 임계치 도달 시 전체 소프트삭제 (모든 수신자에게 숨김 처리)
  if v_report_count >= v_threshold then
    -- journeys 테이블: filter_code를 'REMOVED'로 설정
    update public.journeys j
    set filter_code = 'REMOVED',
        updated_at = now()
    where j.id = target_journey_id
      and j.filter_code <> 'REMOVED';

    -- 모든 수신자에게 숨김 처리 (전체 소프트삭제 전파)
    update public.journey_recipients jr
    set is_hidden = true,
        hidden_reason_code = 'HIDE_REPORTED',
        hidden_at = now(),
        updated_at = now()
    where jr.journey_id = target_journey_id
      and jr.is_hidden = false;
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
    from public.journeys as j
    where j.id = target_journey_id
      and j.user_id = auth.uid()
  ) then
    raise exception 'unauthorized';
  end if;

  return query
  select
    j.id,
    j.status_code,
    j.response_target,
    (select count(*)
     from public.journey_recipients as jr
     where jr.journey_id = j.id
       and jr.status_code = 'RESPONDED'),
    (select count(*)
     from public.journey_recipients as jr
     where jr.journey_id = j.id
       and jr.status_code = 'ASSIGNED'),
    (select count(*)
     from public.journey_recipients as jr
     where jr.journey_id = j.id
       and jr.status_code = 'PASSED'),
    (select count(*)
     from public.journey_recipients as jr
     where jr.journey_id = j.id
       and jr.status_code = 'REPORTED'),
    j.relay_deadline_at,
    (select array_agg(distinct
        coalesce(
          nullif(split_part(recipient_locale_tag, '-', 2), ''),
          nullif(split_part(recipient_locale_tag, '_', 2), ''),
          recipient_locale_tag
        )
      )
     from public.journey_recipients as jr
     where jr.journey_id = j.id
       and jr.recipient_locale_tag is not null)
  from public.journeys as j
  where j.id = target_journey_id;
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

drop function if exists public.get_sent_journey_detail(uuid);

create or replace function public.get_sent_journey_detail(
  p_journey_id uuid
)
returns table (
  journey_id uuid,
  content text,
  created_at timestamptz,
  status_code text,
  response_count integer,
  image_count integer,
  is_reward_unlocked boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;
  if p_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if not exists (
    select 1
    from public.journeys j
    where j.id = p_journey_id
      and j.user_id = v_user_id
      -- 소프트삭제된 여정 제외
      and j.filter_code <> 'REMOVED'
  ) then
    raise exception 'unauthorized:not_sender';
  end if;

  return query
  select
    j.id as journey_id,
    j.content,
    j.created_at,
    j.status_code,
    (
      select count(*)
      from public.journey_responses jr
      where jr.journey_id = j.id
        and jr.is_hidden = false
    )::integer as response_count,
    (
      select count(*)
      from public.journey_images ji
      where ji.journey_id = j.id
    )::integer as image_count,
    (
      j.status_code = 'COMPLETED'
      and exists (
        select 1
        from public.reward_unlocks ru
        where ru.user_id = v_user_id
          and ru.journey_id = j.id
      )
    ) as is_reward_unlocked
  from public.journeys j
  where j.id = p_journey_id;
end;
$$;

drop function if exists public.list_sent_journey_responses(uuid, integer, integer);

create or replace function public.list_sent_journey_responses(
  p_journey_id uuid,
  page_size integer,
  page_offset integer
)
returns table (
  response_id bigint,
  content text,
  created_at timestamptz,
  responder_nickname text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;
  if p_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if not exists (
    select 1
    from public.journeys j
    where j.id = p_journey_id
      and j.user_id = v_user_id
  ) then
    raise exception 'unauthorized:not_sender';
  end if;
  if not exists (
    select 1
    from public.journeys j
    where j.id = p_journey_id
      and j.status_code = 'COMPLETED'
  ) then
    return;
  end if;
  if not exists (
    select 1
    from public.journey_responses jr
    where jr.journey_id = p_journey_id
      and jr.is_hidden = false
  ) then
    raise exception 'responses_missing';
  end if;

  return query
  select
    jr.id as response_id,
    jr.content,
    jr.created_at,
    jr.snapshot_nickname
  from public.journey_responses jr
  where jr.journey_id = p_journey_id
    and jr.is_hidden = false
  order by jr.created_at asc
  limit least(coalesce(page_size, 50), 50)
  offset greatest(coalesce(page_offset, 0), 0);
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

-- 받은 메시지 상세에서 내가 보낸 최신 답글 조회
create or replace function public.get_my_latest_response(
  p_journey_id uuid
)
returns table (
  response_id bigint,
  content text,
  content_clean text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;
  if p_journey_id is null then
    raise exception 'missing_journey';
  end if;

  -- journey_recipients에서 현재 사용자가 수신자인지 확인
  if not exists (
    select 1
    from public.journey_recipients jr
    where jr.journey_id = p_journey_id
      and jr.recipient_user_id = v_user_id
  ) then
    raise exception 'unauthorized';
  end if;

  -- 현재 사용자가 보낸 최신 답글 조회
  return query
  select
    jr.id as response_id,
    jr.content,
    jr.content_clean,
    jr.created_at
  from public.journey_responses jr
  where jr.journey_id = p_journey_id
    and jr.responder_user_id = v_user_id
    and jr.is_hidden = false
  order by jr.created_at desc
  limit 1;
end;
$$;

-- 완료 상태 전환 시 응답 존재 여부를 보장한다.
create or replace function public.ensure_journey_responses_before_complete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  if new.status_code = 'COMPLETED' then
    select count(*)
      into v_count
      from public.journey_responses jr
      where jr.journey_id = new.id
        and jr.is_hidden = false;
    if v_count = 0 then
      raise exception 'responses_missing' using errcode = 'P0001';
    end if;
  end if;
  return new;
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
  -- 스냅샷용 이미지 개수 및 경로 계산
  journey_image_count as (
    select count(*)::integer as cnt
    from public.journey_images
    where journey_images.journey_id = _journey.id
  ),
  journey_image_paths as (
    select array_agg(storage_path order by created_at asc) as paths
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
      snapshot_image_count,
      snapshot_image_paths
    )
    select
      _journey.id,
      candidates.user_id,
      candidates.locale_tag,
      _journey.user_id,
      _journey.content,
      (select cnt from journey_image_count),
      (select paths from journey_image_paths)
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
returns jsonb
language plpgsql
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
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
    v_user_id,
    p_journey_id,
    p_placement_code,
    p_env_code,
    'ADMOB',
    p_ad_unit_id,
    p_event_code,
    p_req_id,
    p_metadata
  );

  return jsonb_build_object('success', true);
end;
$$;

drop function if exists public.upsert_reward_unlock(uuid);

create or replace function public.upsert_reward_unlock(
  p_journey_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_unlocked_at timestamptz;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;
  if p_journey_id is null then
    raise exception 'missing_journey';
  end if;
  if not exists (
    select 1
    from public.journeys j
    where j.id = p_journey_id
      and j.user_id = v_user_id
      and j.status_code = 'COMPLETED'
  ) then
    raise exception 'journey_not_found';
  end if;

  insert into public.reward_unlocks as ru (
    user_id,
    journey_id,
    unlocked_by_code,
    unlocked_at,
    updated_at
  )
  values (
    v_user_id,
    p_journey_id,
    'ADMOB_REWARDED',
    now(),
    now()
  )
  on conflict (user_id, journey_id) do update
    set unlocked_by_code = excluded.unlocked_by_code,
        unlocked_at = excluded.unlocked_at,
        updated_at = now()
  returning ru.unlocked_at into v_unlocked_at;

  return jsonb_build_object(
    'success', true,
    'journey_id', p_journey_id,
    'unlocked', true,
    'unlocked_at', v_unlocked_at
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

drop function if exists public.list_common_codes(text);

create or replace function public.list_common_codes(
  p_code_type text
)
returns table (
  code_type text,
  code_value text,
  name text,
  labels jsonb,
  sort_order integer
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_code_type is null or length(trim(p_code_type)) = 0 then
    raise exception 'missing_code_type';
  end if;

  return query
  select cc.code_type,
         cc.code_value,
         cc.name,
         cc.labels,
         cc.sort_order
  from public.common_codes cc
  where cc.code_type = p_code_type
    and cc.is_active = true
  order by cc.sort_order asc, cc.code_value asc;
end;
$$;

drop function if exists public.list_board_posts(text, text, integer, integer);

create or replace function public.list_board_posts(
  p_board_key text,
  p_type_code text default null,
  p_limit integer default 20,
  p_offset integer default 0
)
returns table (
  id uuid,
  board_key text,
  type_code text,
  title text,
  content_preview text,
  is_pinned boolean,
  published_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_board_id uuid;
begin
  if p_board_key is null or length(trim(p_board_key)) = 0 then
    raise exception 'missing_board_key';
  end if;

  select b.id
  into v_board_id
  from public.boards b
  where b.board_key = p_board_key
    and b.is_active = true;

  if v_board_id is null then
    return;
  end if;

  return query
  select bp.id,
         p_board_key as board_key,
         bp.type_code,
         bp.title,
         left(bp.content, 120) as content_preview,
         bp.is_pinned,
         bp.published_at
  from public.board_posts bp
  where bp.board_id = v_board_id
    and bp.status = 'PUBLISHED'
    and bp.published_at <= now()
    and (p_type_code is null or bp.type_code = p_type_code)
  order by bp.is_pinned desc, bp.published_at desc
  limit p_limit offset p_offset;
end;
$$;

drop function if exists public.get_board_post(uuid);

create or replace function public.get_board_post(
  p_post_id uuid
)
returns table (
  id uuid,
  board_key text,
  type_code text,
  title text,
  content text,
  is_pinned boolean,
  published_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_post_id is null then
    raise exception 'missing_post_id';
  end if;

  return query
  select bp.id,
         b.board_key,
         bp.type_code,
         bp.title,
         bp.content,
         bp.is_pinned,
         bp.published_at
  from public.board_posts bp
  join public.boards b
    on b.id = bp.board_id
  where bp.id = p_post_id
    and b.is_active = true
    and bp.status = 'PUBLISHED'
    and bp.published_at <= now()
  limit 1;
end;
$$;

-- ============================================================================
-- UGC Moderation Functions
-- ============================================================================

-- 텍스트 정규화 함수
create or replace function public.normalize_text(input text)
returns text
language plpgsql
immutable
as $$
declare
  normalized text;
begin
  if input is null then
    return '';
  end if;
  
  -- 소문자화
  normalized := lower(input);
  
  -- 특수문자 제거/치환 (일부 특수문자는 공백으로)
  normalized := regexp_replace(normalized, '[^\w\s가-힣]', ' ', 'g');
  
  -- 연속 공백을 단일 공백으로 축소
  normalized := regexp_replace(normalized, '\s+', ' ', 'g');
  
  -- 앞뒤 공백 제거
  normalized := trim(normalized);
  
  -- 반복문자 축소 (같은 문자가 3회 이상이면 2회로)
  normalized := regexp_replace(normalized, '(.)\1{2,}', '\1\1', 'g');
  
  return normalized;
end;
$$;

-- 텍스트 판정 함수 (ALLOW/MASK/BLOCK/REVIEW)
create or replace function public.classify_text(input text)
returns table(status text, reason text)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  normalized text;
  compact text; -- 공백 제거 버전
  matched_term record;
  has_block boolean := false;
  has_mask boolean := false;
  matched_category text;
begin
  if input is null or length(trim(input)) = 0 then
    return query select 'ALLOW'::text, null::text;
    return;
  end if;
  
  -- 정규화
  normalized := public.normalize_text(input);
  compact := regexp_replace(normalized, '\s', '', 'g');
  
  -- BLOCK severity 용어 검사 (우선순위 높음)
  for matched_term in
    select term, category, is_regex
    from public.banned_terms
    where enabled = true
      and severity = 'BLOCK'
  loop
    if matched_term.is_regex then
      if normalized ~* matched_term.term or compact ~* matched_term.term then
        has_block := true;
        matched_category := matched_term.category;
        exit;
      end if;
    else
      if normalized like '%' || matched_term.term || '%' 
         or compact like '%' || matched_term.term || '%' then
        has_block := true;
        matched_category := matched_term.category;
        exit;
      end if;
    end if;
  end loop;
  
  if has_block then
    return query select 'BLOCK'::text, matched_category;
    return;
  end if;
  
  -- MASK severity 용어 검사
  for matched_term in
    select term, category, is_regex
    from public.banned_terms
    where enabled = true
      and severity = 'MASK'
  loop
    if matched_term.is_regex then
      if normalized ~* matched_term.term or compact ~* matched_term.term then
        has_mask := true;
        matched_category := matched_term.category;
        exit;
      end if;
    else
      if normalized like '%' || matched_term.term || '%' 
         or compact like '%' || matched_term.term || '%' then
        has_mask := true;
        matched_category := matched_term.category;
        exit;
      end if;
    end if;
  end loop;
  
  if has_mask then
    return query select 'MASK'::text, matched_category;
    return;
  end if;
  
  -- 매칭 없음
  return query select 'ALLOW'::text, null::text;
end;
$$;

-- 텍스트 마스킹 함수
create or replace function public.mask_text(original text)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  normalized text;
  compact text;
  masked text;
  matched_term record;
begin
  if original is null then
    return '';
  end if;
  
  masked := original;
  normalized := public.normalize_text(original);
  compact := regexp_replace(normalized, '\s', '', 'g');
  
  -- MASK severity 용어만 마스킹 (BLOCK은 저장 자체를 막으므로 여기서는 처리 안 함)
  for matched_term in
    select term, is_regex
    from public.banned_terms
    where enabled = true
      and severity = 'MASK'
    order by length(term) desc -- 긴 용어부터 처리 (부분 매칭 방지)
  loop
    if matched_term.is_regex then
      -- 정규식 매칭: 원문에서 매칭된 부분을 ***로 치환
      if normalized ~* matched_term.term then
        masked := regexp_replace(masked, matched_term.term, '***', 'gi');
      end if;
      if compact ~* matched_term.term then
        -- 공백 제거 버전도 체크하여 원문에서 마스킹
        masked := regexp_replace(masked, matched_term.term, '***', 'gi');
      end if;
    else
      -- 일반 문자열 매칭: 원문에서 매칭된 부분을 ***로 치환
      if position(lower(matched_term.term) in lower(masked)) > 0 then
        masked := regexp_replace(masked, matched_term.term, '***', 'gi');
      end if;
      -- 공백 제거 버전도 체크
      if position(lower(matched_term.term) in lower(regexp_replace(masked, '\s', '', 'g'))) > 0 then
        masked := regexp_replace(masked, matched_term.term, '***', 'gi');
      end if;
    end if;
  end loop;
  
  return masked;
end;
$$;

-- journeys 테이블 moderation 적용 함수 (트리거용)
create or replace function public.apply_journey_moderation()
returns trigger
language plpgsql
as $$
declare
  classification record;
begin
  -- content가 변경되지 않았으면 스킵
  if tg_op = 'UPDATE' and old.content is not distinct from new.content then
    return new;
  end if;
  
  -- 판정 수행
  select * into classification
  from public.classify_text(new.content);
  
  new.moderation_status := classification.status;
  new.moderation_reason := classification.reason;
  new.moderated_at := now();
  
  -- BLOCK이면 저장 거부
  if classification.status = 'BLOCK' then
    raise exception using
      errcode = 'P0001',
      message = 'content_blocked',
      detail = format('This content cannot be posted due to moderation policy (reason: %s)', classification.reason);
  end if;
  
  -- MASK면 content_clean에 마스킹된 텍스트 저장
  if classification.status = 'MASK' then
    new.content_clean := public.mask_text(new.content);
  else
    -- ALLOW나 REVIEW면 원문 그대로
    new.content_clean := new.content;
  end if;
  
  return new;
end;
$$;

-- journey_responses 테이블 moderation 적용 함수 (트리거용)
create or replace function public.apply_journey_response_moderation()
returns trigger
language plpgsql
as $$
declare
  classification record;
begin
  -- content가 변경되지 않았으면 스킵
  if tg_op = 'UPDATE' and old.content is not distinct from new.content then
    return new;
  end if;
  
  -- 판정 수행
  select * into classification
  from public.classify_text(new.content);
  
  new.moderation_status := classification.status;
  new.moderation_reason := classification.reason;
  new.moderated_at := now();
  
  -- BLOCK이면 저장 거부
  if classification.status = 'BLOCK' then
    raise exception using
      errcode = 'P0001',
      message = 'content_blocked',
      detail = format('This content cannot be posted due to moderation policy (reason: %s)', classification.reason);
  end if;
  
  -- MASK면 content_clean에 마스킹된 텍스트 저장
  if classification.status = 'MASK' then
    new.content_clean := public.mask_text(new.content);
  else
    -- ALLOW나 REVIEW면 원문 그대로
    new.content_clean := new.content;
  end if;
  
  return new;
end;
$$;

-- PostgREST schema cache 리로드 (함수 시그니처 변경 후 필수)
notify pgrst, 'reload schema';
