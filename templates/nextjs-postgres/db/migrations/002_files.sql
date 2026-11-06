CREATE TABLE public.files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  title text NOT NULL CHECK (length(title) BETWEEN 1 AND 200),
  storage_scope text NOT NULL CHECK (length(storage_scope) = 64)
);
ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files FORCE ROW LEVEL SECURITY;
GRANT SELECT, DELETE ON public.files TO tool_app;
GRANT INSERT (id, owner_id, title, storage_scope), UPDATE (title) ON public.files TO tool_app;

CREATE POLICY files_read ON public.files FOR SELECT TO tool_app
  USING (current_setting('app.role', true) = 'admin' OR
    (current_setting('app.role', true) IN ('member', 'viewer') AND
     owner_id = nullif(current_setting('app.user_id', true), '')::uuid));
CREATE POLICY files_insert ON public.files FOR INSERT TO tool_app
  WITH CHECK (current_setting('app.role', true) = 'admin' OR
    (current_setting('app.role', true) = 'member' AND
     owner_id = nullif(current_setting('app.user_id', true), '')::uuid));
CREATE POLICY files_update ON public.files FOR UPDATE TO tool_app
  USING (current_setting('app.role', true) = 'admin' OR
    (current_setting('app.role', true) = 'member' AND
     owner_id = nullif(current_setting('app.user_id', true), '')::uuid))
  WITH CHECK (current_setting('app.role', true) = 'admin' OR
    (current_setting('app.role', true) = 'member' AND
     owner_id = nullif(current_setting('app.user_id', true), '')::uuid));
CREATE POLICY files_delete ON public.files FOR DELETE TO tool_app
  USING (current_setting('app.role', true) = 'admin' OR
    (current_setting('app.role', true) = 'member' AND
     owner_id = nullif(current_setting('app.user_id', true), '')::uuid));
CREATE TRIGGER files_audit AFTER INSERT OR UPDATE OR DELETE ON public.files
  FOR EACH ROW EXECUTE FUNCTION audit.record_change();
