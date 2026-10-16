// delete-account request logic, with the Supabase and Apple calls passed
// in (index.ts wires the real ones; handler.test.ts fakes them).
//
// Order: caller → admin check (409) → Apple revocation for accounts with
// an Apple identity (428 until the app sends a fresh authorization code;
// nothing is deleted unless Apple confirms the revoke) → marriage files and
// row → the auth user.

import type { AppleResult } from "./apple.ts";

export type Caller = {
  id: string;
  identities?: { provider: string; id?: string; identity_data?: Record<string, unknown> }[];
};

export type Deps = {
  /** The user behind the bearer token, or null if it isn't valid. */
  getCaller(authHeader: string): Promise<Caller | null>;
  /** true / false, or "error" when the check itself failed. */
  isAdmin(userId: string): Promise<boolean | "error">;
  /** Null when the Apple secrets are missing. */
  revokeApple: ((code: string, appleSub: string) => Promise<AppleResult>) | null;
  /** Marriage-service files and row; false on any failure. */
  clearMarriage(userId: string): Promise<boolean>;
  deleteUser(userId: string): Promise<boolean>;
  log(level: "log" | "error", message: string, fields: Record<string, unknown>): void;
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

/** The Apple identity's subject (Apple's user id), if the account has one. */
export function appleSub(caller: Caller): string | null {
  const identity = caller.identities?.find((i) => i.provider === "apple");
  if (!identity) return null;
  const sub = identity.identity_data?.sub ?? identity.id;
  return typeof sub === "string" && sub ? sub : null;
}

async function appleCode(req: Request): Promise<string | null> {
  try {
    const body = await req.json();
    const code = body?.apple_authorization_code;
    return typeof code === "string" && code.length > 0 && code.length <= 2048 ? code : null;
  } catch {
    // No body (every call before 1.1.0, and every non-Apple account).
    return null;
  }
}

export async function handle(req: Request, deps: Deps): Promise<Response> {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return json({ error: "unauthorized" }, 401);
  }

  // 1. Who is calling? Validated against Supabase Auth; only the optional
  // Apple code is read from the body, never a user id.
  const user = await deps.getCaller(authHeader);
  if (!user) return json({ error: "unauthorized" }, 401);

  // 2. Website admins must not delete their admin account from the app.
  // Checked before Apple, so an admin never sees the Apple sheet.
  const admin = await deps.isAdmin(user.id);
  if (admin === "error") {
    deps.log("error", "delete-account admin check failed", { userId: user.id });
    return json({ error: "delete_failed" }, 500);
  }
  if (admin) return json({ error: "admin_account" }, 409);

  // 3. Sign in with Apple: revoke the user's Apple tokens first.
  const sub = appleSub(user);
  if (sub) {
    const code = await appleCode(req);
    if (!code) return json({ error: "apple_reauth_required" }, 428);
    if (!deps.revokeApple) {
      deps.log("error", "delete-account apple not configured", { userId: user.id });
      return json({ error: "apple_revoke_failed" }, 502);
    }
    const result = await deps.revokeApple(code, sub);
    if (!result.ok) {
      deps.log("error", "delete-account apple revoke failed", { userId: user.id, reason: result.reason });
      return result.error === "apple_mismatch"
        ? json({ error: "apple_mismatch" }, 409)
        : json({ error: "apple_revoke_failed" }, 502);
    }
  }

  // 4. Marriage-service document and application, before the account: if
  // any step fails nothing further is deleted and the user can retry, so a
  // document is never left behind without its owner.
  if (!(await deps.clearMarriage(user.id))) {
    deps.log("error", "delete-account cleanup failed", { userId: user.id });
    return json({ error: "delete_failed" }, 500);
  }

  // 5. Hard delete (not soft) so the account and its profile are removed.
  if (!(await deps.deleteUser(user.id))) {
    deps.log("error", "delete-account failed", { userId: user.id });
    return json({ error: "delete_failed" }, 500);
  }

  deps.log("log", "delete-account ok", { userId: user.id });
  return json({ deleted: true });
}
