REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO tool_app;
CREATE SCHEMA audit AUTHORIZATION tool_owner;
GRANT USAGE ON SCHEMA audit TO tool_app;

CREATE TABLE public.records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  title text NOT NULL CHECK (length(title) BETWEEN 1 AND 200)
);
ALTER TABLE public.records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.records FORCE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.records TO tool_app;

CREATE POLICY records_read ON public.records FOR SELECT TO tool_app
  USING (current_setting('app.role', true) = 'admin' OR
    (current_setting('app.role', true) IN ('member', 'viewer') AND
     owner_id = nullif(current_setting('app.user_id', true), '')::uuid));
CREATE POLICY records_insert ON public.records FOR INSERT TO tool_app
  WITH CHECK (current_setting('app.role', true) = 'admin' OR
    (current_setting('app.role', true) = 'member' AND
     owner_id = nullif(current_setting('app.user_id', true), '')::uuid));
CREATE POLICY records_update ON public.records FOR UPDATE TO tool_app
  USING (current_setting('app.role', true) = 'admin' OR
    (current_setting('app.role', true) = 'member' AND
     owner_id = nullif(current_setting('app.user_id', true), '')::uuid))
  WITH CHECK (current_setting('app.role', true) = 'admin' OR
    (current_setting('app.role', true) = 'member' AND
     owner_id = nullif(current_setting('app.user_id', true), '')::uuid));
CREATE POLICY records_delete ON public.records FOR DELETE TO tool_app
  USING (current_setting('app.role', true) = 'admin' OR
    (current_setting('app.role', true) = 'member' AND
     owner_id = nullif(current_setting('app.user_id', true), '')::uuid));

-- This example deliberately has no policy. SQL grants alone cannot expose it.
CREATE TABLE public.withheld (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  title text NOT NULL
);
ALTER TABLE public.withheld ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.withheld FORCE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.withheld TO tool_app;

CREATE TABLE audit.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  record_id uuid NOT NULL,
  operation text NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  actor_id uuid,
  actor_role text,
  old_row jsonb,
  new_row jsonb,
  occurred_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE audit.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit.events FORCE ROW LEVEL SECURITY;
GRANT SELECT ON audit.events TO tool_app;
CREATE POLICY audit_read ON audit.events FOR SELECT TO tool_app
  USING (current_setting('app.role', true) = 'admin');
CREATE POLICY audit_append ON audit.events FOR INSERT TO tool_owner
  WITH CHECK (true);

CREATE FUNCTION audit.record_change() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $$
BEGIN
  INSERT INTO audit.events (table_name, record_id, operation, actor_id,
    actor_role, old_row, new_row)
  VALUES (TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, coalesce(NEW.id, OLD.id),
    TG_OP, nullif(current_setting('app.user_id', true), '')::uuid,
    nullif(current_setting('app.role', true), ''),
    CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END);
  RETURN coalesce(NEW, OLD);
END;
$$;
REVOKE ALL ON FUNCTION audit.record_change() FROM PUBLIC;
CREATE TRIGGER records_audit AFTER INSERT OR UPDATE OR DELETE ON public.records
  FOR EACH ROW EXECUTE FUNCTION audit.record_change();
CREATE TRIGGER withheld_audit AFTER INSERT OR UPDATE OR DELETE ON public.withheld
  FOR EACH ROW EXECUTE FUNCTION audit.record_change();
