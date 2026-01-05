insert into public.common_codes (code_type, code_value, name, sort_order)
values
  ('login_type', 'kakao', 'Kakao', 10),
  ('login_type', 'google', 'Google', 20),
  ('login_type', 'apple', 'Apple', 30),
  ('login_type', 'unknown', 'Unknown', 90),
  ('login_type', 'dev', 'Developer', 99),
  ('journey_status', 'CREATED', 'Created', 10),
  ('journey_status', 'WAITING', 'Waiting', 20),
  ('journey_status', 'COMPLETED', 'Completed', 90),
  ('journey_recipient_status', 'ASSIGNED', 'Assigned', 10),
  ('journey_recipient_status', 'RESPONDED', 'Responded', 20),
  ('journey_recipient_status', 'PASSED', 'Passed', 30),
  ('journey_recipient_status', 'REPORTED', 'Reported', 40),
  ('report_reason', 'SPAM', 'Spam', 10),
  ('report_reason', 'ABUSE', 'Abuse', 20),
  ('report_reason', 'OTHER', 'Other', 90),
  ('journey_filter_status', 'OK', 'Allowed', 10),
  ('journey_filter_status', 'HELD', 'Held', 20),
  ('journey_filter_status', 'REMOVED', 'Removed', 90)
on conflict (code_type, code_value) do update
set name = excluded.name,
    sort_order = excluded.sort_order,
    updated_at = now();

insert into storage.buckets (id, name, public)
values ('journey-images', 'journey-images', false)
on conflict (id) do update
set name = excluded.name,
    public = excluded.public;
