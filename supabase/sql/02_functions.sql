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

create or replace function public.get_my_profile()
returns table (
  user_id uuid,
  nickname text,
  avatar_url text,
  bio text,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
as $$
  select p.user_id, p.nickname, p.avatar_url, p.bio, p.created_at, p.updated_at
  from public.user_profiles p
  where p.user_id = auth.uid();
$$;

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
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
as $$
begin
  insert into public.user_profiles (user_id, nickname, avatar_url, bio)
  values (auth.uid(), _nickname, _avatar_url, _bio)
  on conflict on constraint user_profiles_pkey
  do update set
    nickname = excluded.nickname,
    avatar_url = excluded.avatar_url,
    bio = excluded.bio,
    updated_at = now();

  return query
  select p.user_id, p.nickname, p.avatar_url, p.bio, p.created_at, p.updated_at
  from public.user_profiles p
  where p.user_id = auth.uid();
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
