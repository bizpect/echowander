create index if not exists login_logs_user_id_idx
  on public.login_logs (user_id);

create index if not exists login_logs_created_at_idx
  on public.login_logs (created_at desc);
