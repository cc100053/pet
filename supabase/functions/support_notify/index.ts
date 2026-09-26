// Called by the support_messages AFTER INSERT trigger (pg_net) with { id }.
//   sender = 'user'  -> email the support inbox via Resend
//   sender = 'admin' -> FCM push the reply to the user's devices
// Deploy with verify_jwt = false; auth is the SUPPORT_NOTIFY_SECRET bearer.
import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

import { timingSafeEqual } from "../_shared/auth.ts";
import { getFcmAccessToken, loadServiceAccount } from "../_shared/fcm.ts";
import { jsonResponse } from "../_shared/http.ts";
import { localizedAppName } from "../notify_friend/l10n.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const SUPPORT_NOTIFY_SECRET = Deno.env.get("SUPPORT_NOTIFY_SECRET") ?? "";
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const SUPPORT_EMAIL = Deno.env.get("SUPPORT_EMAIL") ?? "";
// Without a verified domain Resend only delivers from onboarding@resend.dev
// to the Resend account owner's address.
const SUPPORT_EMAIL_FROM = Deno.env.get("SUPPORT_EMAIL_FROM") ??
  "PetTomo Support <onboarding@resend.dev>";
const PROJECT_REF = "ilxzpszgirhwxpeocygs";

type SupportMessage = {
  id: string;
  user_id: string;
  sender: "user" | "admin";
  body: string;
  meta: Record<string, unknown>;
  created_at: string;
};

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function sqlLiteral(value: string): string {
  return `'${value.replaceAll("'", "''")}'`;
}

async function emailSupport(message: SupportMessage) {
  if (!RESEND_API_KEY || !SUPPORT_EMAIL) {
    return jsonResponse(500, { error: "email_config_missing" });
  }
  const { data: profile } = await supabaseAdmin
    .from("profiles")
    .select("nickname")
    .eq("user_id", message.user_id)
    .maybeSingle();
  const nickname = (profile?.nickname as string | null) ?? "(no nickname)";
  const preview = message.body.replace(/\s+/g, " ").slice(0, 60);

  const text = [
    message.body,
    "",
    "----",
    `User: ${nickname}`,
    `User ID: ${message.user_id}`,
    `Sent: ${message.created_at}`,
    ...Object.entries(message.meta).map(([k, v]) => `${k}: ${v}`),
    "",
    "Reply (Supabase SQL editor):",
    `https://supabase.com/dashboard/project/${PROJECT_REF}/sql/new`,
    "",
    `insert into public.support_messages (user_id, sender, body) values (${
      sqlLiteral(message.user_id)
    }, 'admin', 'YOUR REPLY');`,
    "",
    "Full thread:",
    `select sender, body, created_at from public.support_messages where user_id = ${
      sqlLiteral(message.user_id)
    } order by created_at;`,
  ].join("\n");

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: SUPPORT_EMAIL_FROM,
      to: [SUPPORT_EMAIL],
      subject: `[PetTomo support] ${nickname}: ${preview}`,
      text,
    }),
  });
  if (!res.ok) {
    const details = await res.text();
    console.error(JSON.stringify({ event: "support_email_failed", details }));
    return jsonResponse(502, { error: "email_failed", details });
  }
  return jsonResponse(200, { success: true, channel: "email" });
}

async function pushReply(message: SupportMessage) {
  const serviceAccount = loadServiceAccount();
  if (!serviceAccount) {
    return jsonResponse(500, { error: "fcm_config_missing" });
  }
  const { data: tokenRows, error } = await supabaseAdmin
    .from("device_tokens")
    .select("token, device_locale")
    .eq("user_id", message.user_id);
  if (error) {
    return jsonResponse(500, { error: "db_error", details: error.message });
  }
  if (!tokenRows || tokenRows.length === 0) {
    return jsonResponse(200, { message: "no_device_tokens_found" });
  }

  const accessToken = await getFcmAccessToken(serviceAccount);
  const endpoint =
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
  const body = message.body.slice(0, 500);

  // ponytail: no stale-token cleanup or delivery log; notify_friend prunes
  // stale tokens on the next chat push anyway.
  const results = await Promise.all(tokenRows.map(async (row) => {
    const title = localizedAppName(row.device_locale as string | null);
    const res = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: row.token,
          notification: { title, body },
          // No room_id: current clients open the app without routing.
          data: {
            type: "support_reply",
            message_kind: "support_reply",
            title_full: title,
            body_full: body,
          },
          android: { priority: "high" },
          apns: {
            headers: { "apns-priority": "10", "apns-push-type": "alert" },
            payload: { aps: { sound: "default" } },
          },
        },
      }),
    });
    return res.ok;
  }));
  const sent = results.filter(Boolean).length;
  return jsonResponse(sent > 0 ? 200 : 502, {
    success: sent > 0,
    channel: "push",
    sent_count: sent,
    failure_count: results.length - sent,
  });
}

serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }
  const bearer = (req.headers.get("Authorization") ?? "").replace(
    /^Bearer\s+/i,
    "",
  );
  if (!timingSafeEqual(bearer, SUPPORT_NOTIFY_SECRET)) {
    return jsonResponse(401, { error: "unauthorized" });
  }

  const { id } = await req.json().catch(() => ({ id: null }));
  if (typeof id !== "string") {
    return jsonResponse(400, { error: "missing_id" });
  }
  const { data: message, error } = await supabaseAdmin
    .from("support_messages")
    .select("id, user_id, sender, body, meta, created_at")
    .eq("id", id)
    .maybeSingle();
  if (error) {
    return jsonResponse(500, { error: "db_error", details: error.message });
  }
  if (!message) {
    return jsonResponse(404, { error: "not_found" });
  }

  try {
    return message.sender === "admin"
      ? await pushReply(message as SupportMessage)
      : await emailSupport(message as SupportMessage);
  } catch (e) {
    console.error(JSON.stringify({ event: "support_notify_failed", error: String(e) }));
    return jsonResponse(500, { error: "support_notify_failed" });
  }
});
