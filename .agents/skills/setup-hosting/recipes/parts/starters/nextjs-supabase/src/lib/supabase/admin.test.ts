import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createClient as supabaseCreateClient } from "@supabase/supabase-js";
import { createAdminClient } from "./admin";

vi.mock("@supabase/supabase-js", () => ({ createClient: vi.fn() }));

beforeEach(() => vi.mocked(supabaseCreateClient).mockReset());
afterEach(() => vi.unstubAllEnvs());

describe("server Supabase key", () => {
  it("uses the secret key when set", () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "https://example.supabase.co");
    vi.stubEnv("SUPABASE_SECRET_KEY", "sb_secret_new");
    vi.stubEnv("SUPABASE_SERVICE_ROLE_KEY", "eyJ_legacy");

    createAdminClient();

    expect(supabaseCreateClient).toHaveBeenCalledWith(
      "https://example.supabase.co",
      "sb_secret_new",
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
  });

  it("reads the old service role setting as a fallback", () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "https://example.supabase.co");
    vi.stubEnv("SUPABASE_SECRET_KEY", "");
    vi.stubEnv("SUPABASE_SERVICE_ROLE_KEY", "eyJ_legacy");

    createAdminClient();

    expect(supabaseCreateClient).toHaveBeenCalledWith(
      "https://example.supabase.co",
      "eyJ_legacy",
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
  });
});
