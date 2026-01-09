alter table public.common_codes enable row level security;
alter table public.users enable row level security;
alter table public.user_profiles enable row level security;
alter table public.device_tokens enable row level security;
alter table public.login_logs enable row level security;
alter table public.journeys enable row level security;
alter table public.journey_images enable row level security;
alter table public.client_error_logs enable row level security;
alter table public.user_blocks enable row level security;
alter table public.journey_recipients enable row level security;
alter table public.journey_responses enable row level security;
alter table public.journey_reports enable row level security;
alter table public.journey_response_reports enable row level security;
alter table public.journey_actions enable row level security;

drop policy if exists "common_codes_select_all" on public.common_codes;
drop policy if exists "users_select_own" on public.users;
drop policy if exists "users_insert_own" on public.users;
drop policy if exists "users_update_own" on public.users;
drop policy if exists "user_profiles_select_own" on public.user_profiles;
drop policy if exists "user_profiles_insert_own" on public.user_profiles;
drop policy if exists "user_profiles_update_own" on public.user_profiles;
drop policy if exists "device_tokens_select_own" on public.device_tokens;
drop policy if exists "device_tokens_insert_own" on public.device_tokens;
drop policy if exists "device_tokens_update_own" on public.device_tokens;
drop policy if exists "login_logs_insert_success" on public.login_logs;
drop policy if exists "login_logs_insert_failed_anon" on public.login_logs;
drop policy if exists "login_logs_select_own" on public.login_logs;
drop policy if exists "journeys_select_own" on public.journeys;
drop policy if exists "journeys_insert_own" on public.journeys;
drop policy if exists "journeys_update_own" on public.journeys;
drop policy if exists "journey_images_select_own" on public.journey_images;
drop policy if exists "journey_images_insert_own" on public.journey_images;
drop policy if exists "journey_images_update_own" on public.journey_images;
drop policy if exists "journey_images_storage_insert" on storage.objects;
drop policy if exists "journey_images_storage_select" on storage.objects;
drop policy if exists "journey_images_storage_delete" on storage.objects;
drop policy if exists "client_error_logs_insert_auth" on public.client_error_logs;
drop policy if exists "client_error_logs_insert_anon" on public.client_error_logs;
drop policy if exists "user_blocks_select_own" on public.user_blocks;
drop policy if exists "user_blocks_insert_own" on public.user_blocks;
drop policy if exists "user_blocks_delete_own" on public.user_blocks;
drop policy if exists "journey_recipients_select_own" on public.journey_recipients;
drop policy if exists "journey_recipients_insert_owner" on public.journey_recipients;
drop policy if exists "journey_recipients_update_self" on public.journey_recipients;
drop policy if exists "journey_responses_select_owner" on public.journey_responses;
drop policy if exists "journey_responses_insert_recipient" on public.journey_responses;
drop policy if exists "journey_reports_insert_recipient" on public.journey_reports;
drop policy if exists "journey_response_reports_insert_owner" on public.journey_response_reports;
drop policy if exists "journey_actions_select_own" on public.journey_actions;
drop policy if exists "journey_actions_insert_own" on public.journey_actions;

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

create policy "journeys_select_own"
  on public.journeys
  for select
  using (auth.uid() = user_id);

create policy "journeys_insert_own"
  on public.journeys
  for insert
  with check (auth.uid() = user_id);

create policy "journeys_update_own"
  on public.journeys
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "journey_images_select_own"
  on public.journey_images
  for select
  using (auth.uid() = user_id);

create policy "journey_images_insert_own"
  on public.journey_images
  for insert
  with check (auth.uid() = user_id);

create policy "journey_images_update_own"
  on public.journey_images
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "client_error_logs_insert_auth"
  on public.client_error_logs
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "client_error_logs_insert_anon"
  on public.client_error_logs
  for insert
  to anon
  with check (auth.uid() is null and user_id is null);

create policy "user_blocks_select_own"
  on public.user_blocks
  for select
  using (auth.uid() = blocker_user_id);

create policy "user_blocks_insert_own"
  on public.user_blocks
  for insert
  with check (auth.uid() = blocker_user_id);

create policy "user_blocks_delete_own"
  on public.user_blocks
  for delete
  using (auth.uid() = blocker_user_id);

create policy "journey_recipients_select_own"
  on public.journey_recipients
  for select
  using (
    auth.uid() = recipient_user_id
    or exists (
      select 1
      from public.journeys
      where journeys.id = journey_id
        and journeys.user_id = auth.uid()
    )
  );

create policy "journey_recipients_insert_owner"
  on public.journey_recipients
  for insert
  with check (
    exists (
      select 1
      from public.journeys
      where journeys.id = journey_id
        and journeys.user_id = auth.uid()
    )
  );

create policy "journey_recipients_update_self"
  on public.journey_recipients
  for update
  using (auth.uid() = recipient_user_id)
  with check (auth.uid() = recipient_user_id);

create policy "journey_responses_select_owner"
  on public.journey_responses
  for select
  using (
    exists (
      select 1
      from public.journeys
      where journeys.id = journey_id
        and journeys.user_id = auth.uid()
        and journeys.status_code = 'COMPLETED'
    )
  );

create policy "journey_responses_insert_recipient"
  on public.journey_responses
  for insert
  with check (
    exists (
      select 1
      from public.journey_recipients
      where journey_recipients.journey_id = journey_id
        and journey_recipients.recipient_user_id = auth.uid()
    )
  );

create policy "journey_reports_insert_recipient"
  on public.journey_reports
  for insert
  with check (
    exists (
      select 1
      from public.journey_recipients
      where journey_recipients.journey_id = journey_id
        and journey_recipients.recipient_user_id = auth.uid()
    )
  );

create policy "journey_response_reports_insert_owner"
  on public.journey_response_reports
  for insert
  with check (
    reporter_user_id = auth.uid()
    and exists (
      select 1
      from public.journey_responses responses
      join public.journeys
        on journeys.id = responses.journey_id
      where responses.id = journey_response_reports.response_id
        and journeys.user_id = auth.uid()
    )
  );

create policy "journey_actions_select_own"
  on public.journey_actions
  for select
  using (actor_user_id = auth.uid());

create policy "journey_actions_insert_own"
  on public.journey_actions
  for insert
  with check (
    actor_user_id = auth.uid()
    and exists (
      select 1
      from public.journey_recipients
      where journey_recipients.id = journey_actions.journey_recipient_id
        and journey_recipients.recipient_user_id = auth.uid()
    )
  );

create policy "journey_images_storage_insert"
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'journey-images' and auth.uid() = owner);

create policy "journey_images_storage_select"
  on storage.objects
  for select
  to authenticated
  using (bucket_id = 'journey-images' and auth.uid() = owner);

create policy "journey_images_storage_delete"
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'journey-images' and auth.uid() = owner);

grant select on public.common_codes to anon, authenticated;
grant select, insert, update on public.users to authenticated;
grant select, insert, update on public.user_profiles to authenticated;
grant select, insert, update on public.device_tokens to authenticated;
grant select, insert on public.login_logs to authenticated;
grant insert on public.login_logs to anon;
grant select, insert, update on public.journeys to authenticated;
grant select, insert, update on public.journey_images to authenticated;
grant select, insert, update, delete on public.user_blocks to authenticated;
grant select, insert, update on public.journey_recipients to authenticated;
grant select, insert on public.journey_responses to authenticated;
grant insert on public.journey_reports to authenticated;
grant insert on public.journey_response_reports to authenticated;
grant select, insert on public.journey_actions to authenticated;
grant insert on public.client_error_logs to anon, authenticated;

grant execute on function public.create_or_get_user(text, text, text) to authenticated;
grant execute on function public.log_login_attempt(text, text) to anon, authenticated;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.upsert_my_profile(text, text, text) to authenticated;
grant execute on function public.update_my_locale(text) to authenticated;
grant execute on function public.update_my_notification_setting(boolean) to authenticated;
grant execute on function public.upsert_device_token(text, text, text) to authenticated;
grant execute on function public.deactivate_device_token(text) to authenticated;
grant execute on function public.create_journey(text, text, text[], integer) to authenticated;
grant execute on function public.list_journeys(integer, integer) to authenticated;
grant execute on function public.list_inbox_journeys(integer, integer) to authenticated;
grant execute on function public.list_inbox_journey_images(uuid) to authenticated;
grant execute on function public.match_journey(uuid) to authenticated;
grant execute on function public.match_pending_journeys(integer) to authenticated;
grant execute on function public.respond_journey(uuid, text) to authenticated;
grant execute on function public.pass_journey(uuid) to authenticated;
grant execute on function public.pass_inbox_item_and_forward(uuid) to authenticated;
grant execute on function public.block_sender_and_pass(bigint, text) to authenticated;
grant execute on function public.report_journey(uuid, text) to authenticated;
grant execute on function public.report_journey_response(bigint, text) to authenticated;
grant execute on function public.get_journey_progress(uuid) to authenticated;
grant execute on function public.list_journey_results(uuid) to authenticated;
grant execute on function public.complete_due_journeys(integer) to authenticated;
grant execute on function public.list_my_blocks(integer, integer) to authenticated;
grant execute on function public.block_user(uuid) to authenticated;
grant execute on function public.unblock_user(uuid) to authenticated;
grant execute on function public.insert_notification_log(uuid, text, text, text, jsonb) to service_role;
grant execute on function public.list_my_notifications(integer, integer, boolean) to authenticated;
grant execute on function public.count_my_unread_notifications() to authenticated;
grant execute on function public.mark_notification_read(bigint) to authenticated;
grant execute on function public.delete_notification_log(bigint) to authenticated;
grant execute on function public.log_client_error(text, integer, text, jsonb, text) to anon, authenticated;

grant usage, select on sequence public.login_logs_id_seq to anon, authenticated;
grant usage, select on sequence public.device_tokens_id_seq to authenticated;
grant usage, select on sequence public.journey_images_id_seq to authenticated;
grant usage, select on sequence public.journey_recipients_id_seq to authenticated;
grant usage, select on sequence public.journey_responses_id_seq to authenticated;
grant usage, select on sequence public.journey_reports_id_seq to authenticated;
grant usage, select on sequence public.journey_response_reports_id_seq to authenticated;
grant usage, select on sequence public.journey_actions_id_seq to authenticated;
grant usage, select on sequence public.client_error_logs_id_seq to anon, authenticated;
