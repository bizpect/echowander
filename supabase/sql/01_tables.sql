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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_profiles_user_fk
    foreign key (user_id)
    references public.users (user_id)
    on delete cascade
);

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
