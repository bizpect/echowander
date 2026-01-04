alter table public.common_codes enable row level security;
alter table public.users enable row level security;
alter table public.user_profiles enable row level security;
alter table public.device_tokens enable row level security;
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

create policy "device_tokens_select_own"
  on public.device_tokens
  for select
  using (auth.uid() = user_id);

create policy "device_tokens_insert_own"
  on public.device_tokens
  for insert
  with check (auth.uid() = user_id);

create policy "device_tokens_update_own"
  on public.device_tokens
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

grant select on public.common_codes to anon, authenticated;
grant select, insert, update on public.users to authenticated;
grant select, insert, update on public.user_profiles to authenticated;
grant select, insert, update on public.device_tokens to authenticated;
grant select, insert on public.login_logs to authenticated;
grant insert on public.login_logs to anon;

grant execute on function public.create_or_get_user(text, text, text) to authenticated;
grant execute on function public.log_login_attempt(text, text) to anon, authenticated;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.upsert_my_profile(text, text, text) to authenticated;
grant execute on function public.upsert_device_token(text, text, text) to authenticated;
grant execute on function public.deactivate_device_token(text) to authenticated;

grant usage, select on sequence public.login_logs_id_seq to anon, authenticated;
grant usage, select on sequence public.device_tokens_id_seq to authenticated;
