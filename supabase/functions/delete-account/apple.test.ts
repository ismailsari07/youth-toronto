// deno test supabase/functions/delete-account/
import assert from "node:assert/strict";
import { APPLE_CLIENT_ID, appleClientSecret, appleConfigFromEnv, revokeApple } from "./apple.ts";
import type { AppleConfig } from "./apple.ts";

const NOW = 1_800_000_000;

async function testKey() {
  const pair = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const b64 = btoa(String.fromCharCode(...pkcs8)).replace(/(.{64})/g, "$1\n");
  const pem = `-----BEGIN PRIVATE KEY-----\n${b64}\n-----END PRIVATE KEY-----\n`;
  return { pem, publicKey: pair.publicKey };
}

const fromB64url = (s: string): Uint8Array<ArrayBuffer> => Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/")), (c) => c.charCodeAt(0));
const decode = (s: string) => JSON.parse(new TextDecoder().decode(fromB64url(s)));
const fakeJwt = (claims: Record<string, unknown>) =>
  `x.${btoa(JSON.stringify(claims)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")}.y`;

type Call = { url: string; body: URLSearchParams };

function fakeApple(opts: {
  token?: { status: number; body: unknown } | "throw";
  revoke?: { status: number } | "throw";
}) {
  const calls: Call[] = [];
  const fetchFn = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    calls.push({ url, body: new URLSearchParams(String(init?.body)) });
    const r = url.endsWith("/auth/token") ? opts.token : opts.revoke;
    if (r === "throw" || r === undefined) throw new TypeError("network");
    return new Response("body" in r ? JSON.stringify(r.body) : "", { status: r.status });
  }) as typeof fetch;
  return { calls, fetchFn };
}

const goodTokens = (sub = "apple-sub-1", extra: Record<string, unknown> = {}) => ({
  status: 200,
  body: {
    access_token: "acc",
    refresh_token: "ref",
    id_token: fakeJwt({ iss: "https://appleid.apple.com", aud: APPLE_CLIENT_ID, sub }),
    ...extra,
  },
});

async function config(): Promise<AppleConfig> {
  return { teamId: "TEAM123456", keyId: "KEY1234567", privateKey: (await testKey()).pem };
}

Deno.test("config: all three secrets required", () => {
  const env: Record<string, string> = { APPLE_TEAM_ID: "T", APPLE_SIWA_KEY_ID: "K", APPLE_SIWA_PRIVATE_KEY: "P" };
  assert.deepEqual(appleConfigFromEnv((k) => env[k]), { teamId: "T", keyId: "K", privateKey: "P" });
  for (const missing of Object.keys(env)) {
    const partial = { ...env, [missing]: " " };
    assert.equal(appleConfigFromEnv((k) => partial[k]), null, missing);
  }
});

Deno.test("client secret: ES256 JWT Apple accepts, signature verifies", async () => {
  const { pem, publicKey } = await testKey();
  const jwt = await appleClientSecret({ teamId: "TEAM123456", keyId: "KEY1234567", privateKey: pem }, NOW);
  const [h, p, s] = jwt.split(".");
  assert.deepEqual(decode(h), { alg: "ES256", kid: "KEY1234567" });
  assert.deepEqual(decode(p), {
    iss: "TEAM123456",
    iat: NOW,
    exp: NOW + 300,
    aud: "https://appleid.apple.com",
    sub: "ca.papemosque.app",
  });
  const sig = fromB64url(s);
  assert.equal(sig.length, 64, "raw r||s");
  assert.ok(await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    publicKey,
    sig,
    new TextEncoder().encode(`${h}.${p}`),
  ));
});

Deno.test("client secret: a key pasted with literal \\n works", async () => {
  const { pem } = await testKey();
  const oneLine = pem.replace(/\n/g, "\\n");
  const jwt = await appleClientSecret({ teamId: "T", keyId: "K", privateKey: oneLine }, NOW);
  assert.equal(jwt.split(".").length, 3);
});

Deno.test("revoke: code → tokens → refresh token revoked", async () => {
  const apple = fakeApple({ token: goodTokens(), revoke: { status: 200 } });
  const result = await revokeApple("the-code", "apple-sub-1", await config(), apple.fetchFn, NOW);
  assert.deepEqual(result, { ok: true });
  assert.equal(apple.calls.length, 2);
  const [token, revoke] = apple.calls;
  assert.equal(token.url, "https://appleid.apple.com/auth/token");
  assert.equal(token.body.get("grant_type"), "authorization_code");
  assert.equal(token.body.get("code"), "the-code");
  assert.equal(token.body.get("client_id"), "ca.papemosque.app");
  assert.ok(token.body.get("client_secret")?.split(".").length === 3);
  assert.equal(revoke.url, "https://appleid.apple.com/auth/revoke");
  assert.equal(revoke.body.get("token"), "ref");
  assert.equal(revoke.body.get("token_type_hint"), "refresh_token");
  assert.equal(revoke.body.get("client_id"), "ca.papemosque.app");
});

Deno.test("revoke: no refresh token → access token revoked", async () => {
  const apple = fakeApple({ token: goodTokens("apple-sub-1", { refresh_token: undefined }), revoke: { status: 200 } });
  assert.deepEqual(await revokeApple("c", "apple-sub-1", await config(), apple.fetchFn, NOW), { ok: true });
  assert.equal(apple.calls[1].body.get("token"), "acc");
  assert.equal(apple.calls[1].body.get("token_type_hint"), "access_token");
});

Deno.test("revoke: another Apple ID's code → apple_mismatch, nothing revoked", async () => {
  const apple = fakeApple({ token: goodTokens("someone-else"), revoke: { status: 200 } });
  const result = await revokeApple("c", "apple-sub-1", await config(), apple.fetchFn, NOW);
  assert.equal(result.ok, false);
  assert.equal(!result.ok && result.error, "apple_mismatch");
  assert.equal(apple.calls.length, 1);
});

Deno.test("revoke: failures → apple_revoke_failed with a reason that carries no token", async () => {
  const cases: [Parameters<typeof fakeApple>[0], string][] = [
    [{ token: { status: 400, body: { error: "invalid_grant" } } }, "token_400_invalid_grant"],
    [{ token: { status: 401, body: { error: "invalid_client" } } }, "token_401_invalid_client"],
    [{ token: "throw" }, "token_network"],
    [{ token: { status: 200, body: { refresh_token: "r" } } }, "token_bad_id_token"],
    [{ token: { status: 200, body: { id_token: fakeJwt({ aud: "other.app", sub: "apple-sub-1" }), refresh_token: "r" } } }, "token_bad_id_token"],
    [{ token: { status: 200, body: { id_token: fakeJwt({ aud: APPLE_CLIENT_ID, sub: "apple-sub-1" }) } } }, "token_missing"],
    [{ token: goodTokens(), revoke: { status: 400 } }, "revoke_400"],
    [{ token: goodTokens(), revoke: "throw" }, "revoke_network"],
  ];
  for (const [opts, reason] of cases) {
    const apple = fakeApple(opts);
    const result = await revokeApple("secret-code", "apple-sub-1", await config(), apple.fetchFn, NOW);
    assert.deepEqual(result, { ok: false, error: "apple_revoke_failed", reason }, reason);
    assert.ok(!reason.includes("secret-code") && !reason.includes("ref"));
  }
});

Deno.test("revoke: an unusable key → bad_key, Apple never called", async () => {
  const apple = fakeApple({ token: goodTokens(), revoke: { status: 200 } });
  const cfg = { teamId: "T", keyId: "K", privateKey: "-----BEGIN PRIVATE KEY-----\nAAAA\n-----END PRIVATE KEY-----" };
  assert.deepEqual(await revokeApple("c", "apple-sub-1", cfg, apple.fetchFn, NOW),
    { ok: false, error: "apple_revoke_failed", reason: "bad_key" });
  assert.equal(apple.calls.length, 0);
});
