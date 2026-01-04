alter table public.common_codes enable row level security;
alter table public.users enable row level security;
alter table public.user_profiles enable row level security;
alter table public.login_logs enable row level security;

create policy "common_codes_select_all"
  on public.common_codes
  for select
  using (true);

create policy "users_select_own"
  on public.users
  for select
  using (auth.uid() = user_id);

create policy "users_insert_own"
  on public.users
  for insert
  with check (auth.uid() = user_id);

create policy "users_update_own"
  on public.users
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "user_profiles_select_own"
  on public.user_profiles
  for select
  using (auth.uid() = user_id);

create policy "user_profiles_insert_own"
  on public.user_profiles
  for insert
  with check (auth.uid() = user_id);

create policy "user_profiles_update_own"
  on public.user_profiles
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "login_logs_insert_success"
  on public.login_logs
  for insert
  with check (auth.uid() = user_id and result = 'success');

create policy "login_logs_insert_failed_anon"
  on public.login_logs
  for insert
  with check (auth.uid() is null and user_id is null and result = 'failed');

create policy "login_logs_select_own"
  on public.login_logs
  for select
  using (auth.uid() = user_id);
