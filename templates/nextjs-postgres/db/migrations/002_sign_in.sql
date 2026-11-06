CREATE SCHEMA sign_in AUTHORIZATION tool_owner;
REVOKE ALL ON SCHEMA sign_in FROM PUBLIC;
GRANT USAGE ON SCHEMA sign_in TO tool_auth, tool_app;

CREATE TABLE sign_in."user" (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text UNIQUE NOT NULL CHECK (email = lower(email)),
  "emailVerified" boolean NOT NULL DEFAULT false,
  image text,
  "createdAt" timestamptz NOT NULL DEFAULT now(),
  "updatedAt" timestamptz NOT NULL DEFAULT now(),
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member', 'viewer', 'unassigned')),
  kind text NOT NULL DEFAULT 'staff' CHECK (kind IN ('staff', 'outsider'))
);
CREATE TABLE sign_in.session (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "expiresAt" timestamptz NOT NULL,
  token text UNIQUE NOT NULL,
  "createdAt" timestamptz NOT NULL DEFAULT now(),
  "updatedAt" timestamptz NOT NULL DEFAULT now(),
  "ipAddress" text,
  "userAgent" text,
  "userId" uuid NOT NULL REFERENCES sign_in."user"(id) ON DELETE CASCADE
);
CREATE INDEX sessions_by_user ON sign_in.session ("userId");
CREATE TABLE sign_in.account (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "accountId" text NOT NULL,
  "providerId" text NOT NULL,
  "userId" uuid NOT NULL REFERENCES sign_in."user"(id) ON DELETE CASCADE,
  "accessToken" text,
  "refreshToken" text,
  "idToken" text,
  "accessTokenExpiresAt" timestamptz,
  "refreshTokenExpiresAt" timestamptz,
  scope text,
  password text,
  "createdAt" timestamptz NOT NULL DEFAULT now(),
  "updatedAt" timestamptz NOT NULL DEFAULT now(),
  UNIQUE ("providerId", "accountId")
);
CREATE INDEX account_user ON sign_in.account ("userId");
CREATE TABLE sign_in.verification (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  identifier text UNIQUE NOT NULL,
  value text NOT NULL,
  "expiresAt" timestamptz NOT NULL,
  "createdAt" timestamptz NOT NULL DEFAULT now(),
  "updatedAt" timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE sign_in.invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL CHECK (email = lower(email)),
  "expiresAt" timestamptz NOT NULL,
  revoked boolean NOT NULL DEFAULT false
);

DO $$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY['user', 'session', 'account', 'verification'] LOOP
    EXECUTE format('ALTER TABLE sign_in.%I ENABLE ROW LEVEL SECURITY', table_name);
    EXECUTE format('ALTER TABLE sign_in.%I FORCE ROW LEVEL SECURITY', table_name);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON sign_in.%I TO tool_auth', table_name);
    EXECUTE format('CREATE POLICY auth_service ON sign_in.%I TO tool_auth USING (true) WITH CHECK (true)', table_name);
  END LOOP;
END $$;
ALTER TABLE sign_in.invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE sign_in.invitations FORCE ROW LEVEL SECURITY;
GRANT SELECT ON sign_in.invitations TO tool_auth;
GRANT SELECT, INSERT, UPDATE, DELETE ON sign_in.invitations TO tool_app;
CREATE POLICY invitation_lookup ON sign_in.invitations FOR SELECT TO tool_auth USING (true);
CREATE POLICY invitation_admin ON sign_in.invitations TO tool_app
  USING (current_setting('app.role', true) = 'admin')
  WITH CHECK (current_setting('app.role', true) = 'admin');
CREATE TRIGGER invitations_audit AFTER INSERT OR UPDATE OR DELETE ON sign_in.invitations
  FOR EACH ROW EXECUTE FUNCTION audit.record_change();
