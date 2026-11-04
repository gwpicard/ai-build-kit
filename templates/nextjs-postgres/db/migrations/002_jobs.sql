-- This system role can create and read only its own example outputs.
CREATE POLICY records_system_read ON public.records FOR SELECT TO tool_app
  USING (current_setting('app.role', true) = 'system'
    AND current_setting('app.user_id', true) = '00000000-0000-4000-8000-000000000001'
    AND owner_id = '00000000-0000-4000-8000-000000000001'::uuid);
CREATE POLICY records_system_insert ON public.records FOR INSERT TO tool_app
  WITH CHECK (current_setting('app.role', true) = 'system'
    AND current_setting('app.user_id', true) = '00000000-0000-4000-8000-000000000001'
    AND owner_id = '00000000-0000-4000-8000-000000000001'::uuid);

CREATE SCHEMA job_runtime AUTHORIZATION tool_owner;
REVOKE ALL ON SCHEMA job_runtime FROM PUBLIC;
GRANT USAGE ON SCHEMA job_runtime TO tool_app;
CREATE TABLE job_runtime.schedules (
  name text PRIMARY KEY,
  checked_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE job_runtime.heartbeats (
  id uuid PRIMARY KEY,
  mode text NOT NULL CHECK (mode IN ('worker', 'timer')),
  seen_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  stopped boolean NOT NULL DEFAULT false
);
ALTER TABLE job_runtime.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_runtime.schedules FORCE ROW LEVEL SECURITY;
ALTER TABLE job_runtime.heartbeats ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_runtime.heartbeats FORCE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA job_runtime TO tool_app;
CREATE POLICY schedules_system ON job_runtime.schedules TO tool_app
  USING (current_setting('app.role', true) = 'system'
    AND current_setting('app.user_id', true) = '00000000-0000-4000-8000-000000000001')
  WITH CHECK (current_setting('app.role', true) = 'system'
    AND current_setting('app.user_id', true) = '00000000-0000-4000-8000-000000000001');
CREATE POLICY heartbeats_system ON job_runtime.heartbeats TO tool_app
  USING (current_setting('app.role', true) = 'system'
    AND current_setting('app.user_id', true) = '00000000-0000-4000-8000-000000000001')
  WITH CHECK (current_setting('app.role', true) = 'system'
    AND current_setting('app.user_id', true) = '00000000-0000-4000-8000-000000000001');
