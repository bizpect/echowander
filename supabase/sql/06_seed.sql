insert into public.common_codes (code_type, code_value, name, sort_order)
values
  ('login_type', 'kakao', 'Kakao', 10),
  ('login_type', 'google', 'Google', 20),
  ('login_type', 'apple', 'Apple', 30),
  ('login_type', 'unknown', 'Unknown', 90),
  ('login_type', 'dev', 'Developer', 99)
on conflict (code_type, code_value) do update
set name = excluded.name,
    sort_order = excluded.sort_order,
    updated_at = now();
