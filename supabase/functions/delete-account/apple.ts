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

/** What Apple answered, for the log: its fixed error word and its short
 * English description. Never a token, code or key. */
export type AppleAnswer = { status: number; error?: string; description?: string };

export type AppleResult =
  | { ok: true }
  | {
    ok: false;
    error: "apple_mismatch" | "apple_revoke_failed";
    /** step_status_error, e.g. token_400_invalid_client. */
    reason: string;
    apple?: AppleAnswer;
    /** keyShape(), when the key or IDs are the likely cause. */
    key?: Record<string, unknown>;
  };

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

/** The base64 body of the .p8, however it was pasted: real or literal
 * "\n" / "\r\n", surrounding quotes, with or without the BEGIN/END lines. */
function pemBody(pem: string): string {
  return pem
    .replace(/\\r\\n|\\n|\\r/g, "\n")
    .replace(/-----(BEGIN|END) [A-Z ]*PRIVATE KEY-----/g, "")
    .replace(/["'\s]/g, "");
}

function pemToPkcs8(pem: string): Uint8Array<ArrayBuffer> {
  return Uint8Array.from(atob(pemBody(pem)), (c) => c.charCodeAt(0));
}

/**
 * The secrets' shape, safe to log: lengths and yes/no facts, never content.
 * An Apple .p8 (P-256 PKCS#8 with its public key) decodes to 150 bytes;
 * Key and Team IDs are 10 characters.
 */
export function keyShape(cfg: AppleConfig): Record<string, unknown> {
  const pem = cfg.privateKey;
  let keyBytes: number | null = null;
  try {
    keyBytes = atob(pemBody(pem)).length;
  } catch {
    // Not base64 after cleaning.
  }
  return {
    pemLength: pem.length,
    hasBegin: pem.includes("-----BEGIN PRIVATE KEY-----"),
    hasEnd: pem.includes("-----END PRIVATE KEY-----"),
    realNewlines: pem.includes("\n"),
    literalBackslashN: pem.includes("\\n"),
    quoted: /^\s*["']/.test(pem),
    keyBytes,
    keyIdLength: cfg.keyId.length,
    teamIdLength: cfg.teamId.length,
  };
}

/** Apple's error JSON → its fixed word and a short one-line description. */
async function appleAnswer(res: Response): Promise<AppleAnswer> {
  const body = await res.json().catch(() => null);
  const word = (v: unknown) => (typeof v === "string" && /^[a-z_]{1,40}$/.test(v) ? v : undefined);
  const text = (v: unknown) =>
    typeof v === "string" ? v.replace(/\s+/g, " ").slice(0, 200) : undefined;
  return { status: res.status, error: word(body?.error), description: text(body?.error_description) };
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
  const fail = (reason: string, apple?: AppleAnswer): AppleResult => {
    const result: AppleResult = { ok: false, error: "apple_revoke_failed", reason };
    if (apple) result.apple = apple;
    if (reason === "bad_key" || apple?.error === "invalid_client") result.key = keyShape(cfg);
    return result;
  };
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
      const answer = await appleAnswer(res);
      return fail(`token_${res.status}_${answer.error ?? "unknown"}`, answer);
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
    if (!res.ok) {
      const answer = await appleAnswer(res);
      return fail(`revoke_${res.status}_${answer.error ?? "unknown"}`, answer);
    }
  } catch {
    return fail("revoke_network");
  }
  return { ok: true };
}
