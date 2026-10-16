// Sign in with Apple token revocation (App Review 5.1.1(v)).
//
// Supabase keeps no Apple tokens for native signInWithIdToken, so the app
// asks Apple for a fresh authorization code when the user deletes the
// account. This module trades that code for tokens and revokes them:
//   POST https://appleid.apple.com/auth/token   (authorization_code grant)
//   POST https://appleid.apple.com/auth/revoke  (the refresh token)
// The client secret is an ES256 JWT signed with the Sign in with Apple key,
// built per request (5 minutes), so there is no 6-month secret to rotate.
// Key material comes only from Edge Function secrets; codes, tokens and
// keys are never logged.

export const APPLE_CLIENT_ID = "ca.papemosque.app";
const APPLE = "https://appleid.apple.com";

export type AppleConfig = {
  teamId: string;
  keyId: string;
  /** PKCS#8 PEM text of the .p8 key (literal "\n" sequences accepted). */
  privateKey: string;
};

export type AppleResult =
  | { ok: true }
  | { ok: false; error: "apple_mismatch" | "apple_revoke_failed"; reason: string };

/** The secrets, or null when any is missing. */
export function appleConfigFromEnv(get: (k: string) => string | undefined): AppleConfig | null {
  const teamId = get("APPLE_TEAM_ID")?.trim();
  const keyId = get("APPLE_SIWA_KEY_ID")?.trim();
  const privateKey = get("APPLE_SIWA_PRIVATE_KEY");
  if (!teamId || !keyId || !privateKey?.trim()) return null;
  return { teamId, keyId, privateKey };
}

const b64url = (bytes: Uint8Array) =>
  btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const b64urlText = (s: string) => b64url(new TextEncoder().encode(s));

function pemToPkcs8(pem: string): Uint8Array<ArrayBuffer> {
  const body = pem
    .replace(/\\n/g, "\n")
    .replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

/** ES256 client secret for Apple's token and revoke endpoints. */
export async function appleClientSecret(cfg: AppleConfig, nowSeconds: number): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToPkcs8(cfg.privateKey),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const header = b64urlText(JSON.stringify({ alg: "ES256", kid: cfg.keyId }));
  const payload = b64urlText(JSON.stringify({
    iss: cfg.teamId,
    iat: nowSeconds,
    exp: nowSeconds + 300,
    aud: APPLE,
    sub: APPLE_CLIENT_ID,
  }));
  // WebCrypto's ECDSA signature is raw r||s, which is what JWS ES256 wants.
  const sig = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(`${header}.${payload}`),
  );
  return `${header}.${payload}.${b64url(new Uint8Array(sig))}`;
}

/** Payload of a JWT, without verifying it (see revokeApple). */
function jwtPayload(jwt: unknown): Record<string, unknown> | null {
  if (typeof jwt !== "string") return null;
  const part = jwt.split(".")[1];
  if (!part) return null;
  try {
    const json = atob(part.replace(/-/g, "+").replace(/_/g, "/"));
    const bytes = Uint8Array.from(json, (c) => c.charCodeAt(0));
    const v = JSON.parse(new TextDecoder().decode(bytes));
    return v && typeof v === "object" ? v : null;
  } catch {
    return null;
  }
}

const form = (fields: Record<string, string>) => ({
  method: "POST",
  headers: { "Content-Type": "application/x-www-form-urlencoded" },
  body: new URLSearchParams(fields).toString(),
});

/**
 * Trades [code] for tokens, checks that they belong to [expectedSub] (the
 * user's Apple identity), then revokes them. The ID token comes straight
 * from Apple's token endpoint over TLS, so its claims are read without a
 * signature check (OpenID Connect Core 3.1.3.7).
 */
export async function revokeApple(
  code: string,
  expectedSub: string,
  cfg: AppleConfig,
  fetchFn: typeof fetch = fetch,
  nowSeconds = Math.floor(Date.now() / 1000),
): Promise<AppleResult> {
  const fail = (reason: string): AppleResult => ({ ok: false, error: "apple_revoke_failed", reason });
  let secret: string;
  try {
    secret = await appleClientSecret(cfg, nowSeconds);
  } catch {
    return fail("bad_key");
  }

  let tokens: Record<string, unknown>;
  try {
    const res = await fetchFn(`${APPLE}/auth/token`, form({
      client_id: APPLE_CLIENT_ID,
      client_secret: secret,
      code,
      grant_type: "authorization_code",
    }));
    if (!res.ok) {
      // Apple's error is a fixed word (invalid_grant, invalid_client…).
      const body = await res.json().catch(() => null);
      const err = typeof body?.error === "string" ? body.error : "unknown";
      return fail(`token_${res.status}_${err}`);
    }
    tokens = await res.json();
  } catch {
    return fail("token_network");
  }

  const claims = jwtPayload(tokens.id_token);
  if (!claims || claims.aud !== APPLE_CLIENT_ID) return fail("token_bad_id_token");
  if (claims.sub !== expectedSub) {
    return { ok: false, error: "apple_mismatch", reason: "sub_mismatch" };
  }

  const refresh = typeof tokens.refresh_token === "string" ? tokens.refresh_token : null;
  const access = typeof tokens.access_token === "string" ? tokens.access_token : null;
  const token = refresh ?? access;
  if (!token) return fail("token_missing");

  try {
    const res = await fetchFn(`${APPLE}/auth/revoke`, form({
      client_id: APPLE_CLIENT_ID,
      client_secret: secret,
      token,
      token_type_hint: refresh ? "refresh_token" : "access_token",
    }));
    if (!res.ok) return fail(`revoke_${res.status}`);
  } catch {
    return fail("revoke_network");
  }
  return { ok: true };
}
