// delete-account — permanently deletes the CALLING user's account.
//
// Called by the mobile app (Profile → Delete account) with the user's own
// JWT. The user id comes only from that verified token, never from the
// request body, so a caller can delete nothing but their own account.
// user_profiles (and profiles) rows go with it via ON DELETE CASCADE; the
// marriage-service document and its row are deleted explicitly first.
// Accounts with a Sign in with Apple identity also need a fresh Apple
// authorization code in the body (`apple_authorization_code`): their Apple
// tokens are revoked before anything is deleted (apple.ts, 5.1.1(v)).
// The request logic is in handler.ts.
//
// Secrets: the service-role key is provided to hosted Edge Functions as an
// env var; APPLE_TEAM_ID, APPLE_SIWA_KEY_ID and APPLE_SIWA_PRIVATE_KEY (the
// .p8 text) are Edge Function secrets set in the dashboard. None of them
// leaves the server. Deploy with JWT verification ON (the default):
//   npx supabase functions deploy delete-account --project-ref onczqxxdvmmmdcuhmyio

import { createClient } from "npm:@supabase/supabase-js@2";
import { appleConfigFromEnv, revokeApple } from "./apple.ts";
import { handle } from "./handler.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const appleConfig = appleConfigFromEnv((k) => Deno.env.get(k));

// Admin client — service-role key, server-side only.
const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});

Deno.serve((req) =>
  handle(req, {
    async getCaller(authHeader) {
      const asCaller = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
        global: { headers: { Authorization: authHeader } },
        auth: { persistSession: false },
      });
      const { data: { user }, error } = await asCaller.auth.getUser();
      return error || !user ? null : user;
    },

    async isAdmin(userId) {
      const { data, error } = await admin
        .from("profiles")
        .select("id")
        .eq("id", userId)
        .maybeSingle();
      return error ? "error" : data !== null;
    },

    revokeApple: appleConfig
      ? (code, sub) => revokeApple(code, sub, appleConfig)
      : null,

    // This runs for every user, so neither the log nor the timing shows who
    // used the service, and nothing about the file is ever logged.
    async clearMarriage(userId) {
      const bucket = admin.storage.from("marriage-documents");
      for (let round = 0; round < 10; round++) {
        const { data: objects, error: listErr } = await bucket.list(userId, {
          limit: 100,
        });
        if (listErr) return false;
        if (!objects || objects.length === 0) {
          const { error: rowErr } = await admin
            .from("marriage_applications")
            .delete()
            .eq("user_id", userId);
          return !rowErr;
        }
        const { error: rmErr } = await bucket.remove(
          objects.map((o) => `${userId}/${o.name}`),
        );
        if (rmErr) return false;
      }
      return false;
    },

    async deleteUser(userId) {
      const { error } = await admin.auth.admin.deleteUser(userId);
      return !error;
    },

    log(level, message, fields) {
      console[level](message, fields);
    },
  })
);
