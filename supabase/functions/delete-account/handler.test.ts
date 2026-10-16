// deno test supabase/functions/delete-account/
import assert from "node:assert/strict";
import type { AppleResult } from "./apple.ts";
import { appleSub, handle } from "./handler.ts";
import type { Caller, Deps } from "./handler.ts";

const MEMBER: Caller = { id: "u1", identities: [{ provider: "email", id: "u1" }] };
const APPLE_MEMBER: Caller = {
  id: "u2",
  identities: [
    { provider: "email", id: "u2" },
    { provider: "apple", id: "apple-sub-2", identity_data: { sub: "apple-sub-2" } },
  ],
};

type Setup = {
  caller?: Caller | null;
  admin?: boolean | "error";
  apple?: AppleResult | "unconfigured";
  clear?: boolean;
  del?: boolean;
};

function fake(setup: Setup = {}) {
  const steps: string[] = [];
  const logs: string[] = [];
  const deps: Deps = {
    getCaller: async () => (setup.caller === undefined ? MEMBER : setup.caller),
    isAdmin: async () => setup.admin ?? false,
    revokeApple: setup.apple === "unconfigured" ? null : async (code, sub) => {
      steps.push(`revoke:${code}:${sub}`);
      return setup.apple as AppleResult ?? { ok: true };
    },
    clearMarriage: async (id) => {
      steps.push(`clear:${id}`);
      return setup.clear ?? true;
    },
    deleteUser: async (id) => {
      steps.push(`delete:${id}`);
      return setup.del ?? true;
    },
    log: (level, message, fields) => logs.push(`${level} ${message} ${JSON.stringify(fields)}`),
  };
  return { deps, steps, logs };
}

const post = (body?: unknown, auth = "Bearer jwt") =>
  new Request("https://x/functions/v1/delete-account", {
    method: "POST",
    headers: auth ? { Authorization: auth, "Content-Type": "application/json" } : {},
    body: body === undefined ? undefined : JSON.stringify(body),
  });

async function call(req: Request, setup: Setup = {}) {
  const f = fake(setup);
  const res = await handle(req, f.deps);
  return { status: res.status, body: await res.json(), steps: f.steps, logs: f.logs };
}

Deno.test("GET → 405, no bearer → 401, invalid token → 401", async () => {
  assert.equal((await call(new Request("https://x", { method: "GET" }))).status, 405);
  assert.equal((await call(post(undefined, ""))).status, 401);
  const r = await call(post(), { caller: null });
  assert.deepEqual([r.status, r.body, r.steps], [401, { error: "unauthorized" }, []]);
});

Deno.test("member without Apple, no body: deleted as before", async () => {
  const r = await call(post());
  assert.deepEqual([r.status, r.body], [200, { deleted: true }]);
  assert.deepEqual(r.steps, ["clear:u1", "delete:u1"]);
});

Deno.test("member without Apple ignores a sent code", async () => {
  const r = await call(post({ apple_authorization_code: "c" }));
  assert.deepEqual(r.steps, ["clear:u1", "delete:u1"]);
});

Deno.test("admin → 409 before any Apple step, nothing deleted", async () => {
  const r = await call(post(), { caller: APPLE_MEMBER, admin: true });
  assert.deepEqual([r.status, r.body, r.steps], [409, { error: "admin_account" }, []]);
  const withCode = await call(post({ apple_authorization_code: "c" }), { caller: APPLE_MEMBER, admin: true });
  assert.deepEqual([withCode.status, withCode.steps], [409, []]);
});

Deno.test("admin check failing → 500, nothing deleted", async () => {
  const r = await call(post(), { admin: "error" });
  assert.deepEqual([r.status, r.body, r.steps], [500, { error: "delete_failed" }, []]);
});

Deno.test("Apple account without a code → 428, nothing deleted", async () => {
  for (const req of [post(), post({}), post({ apple_authorization_code: "" }), post({ apple_authorization_code: 7 })]) {
    const r = await call(req, { caller: APPLE_MEMBER });
    assert.deepEqual([r.status, r.body, r.steps], [428, { error: "apple_reauth_required" }, []]);
  }
  const notJson = new Request("https://x", { method: "POST", headers: { Authorization: "Bearer jwt" }, body: "{" });
  assert.equal((await call(notJson, { caller: APPLE_MEMBER })).status, 428);
});

Deno.test("Apple account with a code: revoke, then marriage cleanup, then the user", async () => {
  const r = await call(post({ apple_authorization_code: "code-1" }), { caller: APPLE_MEMBER });
  assert.deepEqual([r.status, r.body], [200, { deleted: true }]);
  assert.deepEqual(r.steps, ["revoke:code-1:apple-sub-2", "clear:u2", "delete:u2"]);
  assert.ok(r.logs.every((l) => !l.includes("code-1")), "the code is never logged");
});

Deno.test("Apple ID mismatch → 409 apple_mismatch, nothing deleted", async () => {
  const r = await call(post({ apple_authorization_code: "c" }), {
    caller: APPLE_MEMBER,
    apple: { ok: false, error: "apple_mismatch", reason: "sub_mismatch" },
  });
  assert.deepEqual([r.status, r.body], [409, { error: "apple_mismatch" }]);
  assert.deepEqual(r.steps, ["revoke:c:apple-sub-2"]);
});

Deno.test("revoke failing → 502 apple_revoke_failed, nothing deleted", async () => {
  const r = await call(post({ apple_authorization_code: "c" }), {
    caller: APPLE_MEMBER,
    apple: { ok: false, error: "apple_revoke_failed", reason: "token_400_invalid_grant" },
  });
  assert.deepEqual([r.status, r.body], [502, { error: "apple_revoke_failed" }]);
  assert.deepEqual(r.steps, ["revoke:c:apple-sub-2"]);
  assert.ok(r.logs.some((l) => l.includes("token_400_invalid_grant")));
});

Deno.test("Apple secrets missing → 502, nothing deleted (members without Apple unaffected)", async () => {
  const r = await call(post({ apple_authorization_code: "c" }), { caller: APPLE_MEMBER, apple: "unconfigured" });
  assert.deepEqual([r.status, r.body, r.steps], [502, { error: "apple_revoke_failed" }, []]);
  const plain = await call(post(), { apple: "unconfigured" });
  assert.equal(plain.status, 200);
});

Deno.test("marriage cleanup failing → 500, the user is kept", async () => {
  const r = await call(post(), { clear: false });
  assert.deepEqual([r.status, r.body, r.steps], [500, { error: "delete_failed" }, ["clear:u1"]]);
});

Deno.test("user deletion failing → 500", async () => {
  const r = await call(post(), { del: false });
  assert.deepEqual([r.status, r.body], [500, { error: "delete_failed" }]);
});

Deno.test("appleSub: identity_data.sub, else the identity id, else none", () => {
  assert.equal(appleSub(APPLE_MEMBER), "apple-sub-2");
  assert.equal(appleSub({ id: "u", identities: [{ provider: "apple", id: "from-id" }] }), "from-id");
  assert.equal(appleSub(MEMBER), null);
  assert.equal(appleSub({ id: "u" }), null);
});
