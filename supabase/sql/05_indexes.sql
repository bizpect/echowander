create index if not exists login_logs_user_id_idx
  on public.login_logs (user_id);

create index if not exists login_logs_created_at_idx
  on public.login_logs (created_at desc);

drop index if exists device_tokens_token_uk;
drop index if exists device_tokens_active_token_uk;

create unique index if not exists device_tokens_user_device_uk
  on public.device_tokens (user_id, device_id);
