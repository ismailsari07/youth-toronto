// delete-account — permanently deletes the CALLING user's account.
//
// Called by the mobile app (Profile → Delete account) with the user's own
// JWT. The user id comes only from that verified token, never from the
// request body, so a caller can delete nothing but their own account.
// user_profiles (and profiles) rows go with it via ON DELETE CASCADE; the
// marriage-service document and its row are deleted explicitly first.
//
// The service-role key is provided to hosted Edge Functions as an env var;
// it never leaves the server. Deploy with JWT verification ON (the default):
//   npx supabase functions deploy delete-account --project-ref onczqxxdvmmmdcuhmyio

import { createClient } from "npm:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const cleanupFailed = (userId: string) => {
  console.error("delete-account cleanup failed", { userId });
  return json({ error: "delete_failed" }, 500);
};

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return json({ error: "unauthorized" }, 401);
  }

  const url = Deno.env.get("SUPABASE_URL")!;

  // 1. Who is calling? Validated against Supabase Auth; the body is ignored.
  const asCaller = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const { data: { user }, error: userErr } = await asCaller.auth.getUser();
  if (userErr || !user) return json({ error: "unauthorized" }, 401);

  // 2. Admin client — service-role key, server-side only.
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

  // 3. Website admins must not delete their admin account from the app.
  const { data: adminRow, error: adminErr } = await admin
    .from("profiles")
    .select("id")
    .eq("id", user.id)
    .maybeSingle();
  if (adminErr) {
    console.error("delete-account admin check failed", { userId: user.id });
    return json({ error: "delete_failed" }, 500);
  }
  if (adminRow) return json({ error: "admin_account" }, 409);

  // 4. Marriage-service document and application, before the account: if
  // any step fails nothing further is deleted and the user can retry, so a
  // document is never left behind without its owner. This runs for every
  // user, so neither the log nor the timing shows who used the service, and
  // nothing about the file is ever logged.
  const bucket = admin.storage.from("marriage-documents");
  let cleared = false;
  for (let round = 0; round < 10 && !cleared; round++) {
    const { data: objects, error: listErr } = await bucket.list(user.id, {
      limit: 100,
    });
    if (listErr) return cleanupFailed(user.id);
    if (!objects || objects.length === 0) {
      cleared = true;
      break;
    }
    const { error: rmErr } = await bucket.remove(
      objects.map((o) => `${user.id}/${o.name}`),
    );
    if (rmErr) return cleanupFailed(user.id);
  }
  if (!cleared) return cleanupFailed(user.id);

  const { error: rowErr } = await admin
    .from("marriage_applications")
    .delete()
    .eq("user_id", user.id);
  if (rowErr) return cleanupFailed(user.id);

  // 5. Hard delete (not soft) so the account and its profile are removed.
  const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
  if (delErr) {
    console.error("delete-account failed", { userId: user.id });
    return json({ error: "delete_failed" }, 500);
  }

  console.log("delete-account ok", { userId: user.id });
  return json({ deleted: true });
});
