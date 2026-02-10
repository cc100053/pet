import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.9.1/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Environment variables
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const NOTIFY_WEBHOOK_SECRET = Deno.env.get("NOTIFY_WEBHOOK_SECRET") ?? "";
const GOOGLE_SERVICE_ACCOUNT = Deno.env.get("GOOGLE_SERVICE_ACCOUNT") ?? "";
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "";
const FCM_CLIENT_EMAIL = Deno.env.get("FCM_CLIENT_EMAIL") ?? "";
const FCM_PRIVATE_KEY = (Deno.env.get("FCM_PRIVATE_KEY") ?? "").replace(
  /\\n/g,
  "\n",
);

// Localization map for push notification strings
type L10nStrings = { title: string; defaultBody: string };

const l10n: Record<string, L10nStrings> = {
  en: { title: "PetTomo", defaultBody: "Someone shared a photo!" },
  ja: { title: "ペットモ", defaultBody: "誰かが写真をシェアしました！" },
  "zh-TW": { title: "PetTomo", defaultBody: "有人分享了一張照片！" },
};

function getL10n(locale: string | null | undefined): L10nStrings {
  if (!locale) return l10n["zh-TW"];
  if (l10n[locale]) return l10n[locale];
  // Language-only fallback: "zh" → "zh-TW", "en-US" → "en"
  const lang = locale.split("-")[0];
  if (lang === "zh") return l10n["zh-TW"];
  if (l10n[lang]) return l10n[lang];
  return l10n["zh-TW"];
}

// Type definitions
type NotifyPayload = {
  type: "feed_event";
  room_id: string;
  sender_id: string;
  recipient_ids: string[];
  message_id: string;
  image_url: string;
  caption: string | null;
  canonical_tags: string[];
  created_at: string | null;
};

type ServiceAccount = {
  project_id: string;
  private_key: string;
  client_email: string;
  token_uri?: string;
};

function pemToArrayBuffer(pem: string) {
  const cleaned = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\\n/g, "")
    .replace(/\\r/g, "")
    .trim();
  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

async function importPrivateKey(privateKey: string) {
  const keyData = pemToArrayBuffer(privateKey);
  return await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const iat = getNumericDate(0);
  const exp = getNumericDate(3600); // 1 hour

  const key = await importPrivateKey(serviceAccount.private_key);
  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: serviceAccount.client_email,
      sub: serviceAccount.client_email,
      aud: "https://oauth2.googleapis.com/token",
      iat,
      exp,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    },
    key,
  );

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Failed to get access token: ${response.status} ${text}`);
  }

  const data = await response.json();
  return data.access_token;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  // 1. Verify Shared Secret for Webhook Security
  const authHeader = req.headers.get("Authorization") ?? "";
  if (NOTIFY_WEBHOOK_SECRET) {
    if (authHeader !== `Bearer ${NOTIFY_WEBHOOK_SECRET}`) {
      return jsonResponse(401, { error: "invalid_webhook_secret" });
    }
  }

  // 2. Validate Payload
  let payload: NotifyPayload;
  try {
    payload = await req.json();
  } catch (_error) {
    return jsonResponse(400, { error: "invalid_json" });
  }

  if (
    !payload.recipient_ids || !Array.isArray(payload.recipient_ids) ||
    payload.recipient_ids.length === 0
  ) {
    return jsonResponse(200, { message: "no_recipients" });
  }

  // 3. Init Supabase Admin Client
  // We need service_role logic to read device_tokens table securely if RLS is strict
  // (Assuming device_tokens might not be public)
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, { error: "server_config_error" });
  }
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // 4. Filter recipients against block list (both directions)
  const senderId = payload.sender_id;
  let recipientIds = payload.recipient_ids.filter((id) =>
    typeof id === "string" && id.length > 0 && id !== senderId
  );

  if (recipientIds.length === 0) {
    return jsonResponse(200, { message: "no_recipients" });
  }

  const { data: blockedBySender, error: blockedBySenderError } = await supabase
    .from("blocks")
    .select("blocked_user_id")
    .eq("blocker_id", senderId)
    .in("blocked_user_id", recipientIds);

  if (blockedBySenderError) {
    return jsonResponse(500, {
      error: "db_error",
      details: blockedBySenderError.message,
    });
  }

  const { data: blockedSender, error: blockedSenderError } = await supabase
    .from("blocks")
    .select("blocker_id")
    .in("blocker_id", recipientIds)
    .eq("blocked_user_id", senderId);

  if (blockedSenderError) {
    return jsonResponse(500, {
      error: "db_error",
      details: blockedSenderError.message,
    });
  }

  const blocked = new Set<string>();
  for (const row of blockedBySender ?? []) {
    if (row.blocked_user_id) {
      blocked.add(row.blocked_user_id);
    }
  }
  for (const row of blockedSender ?? []) {
    if (row.blocker_id) {
      blocked.add(row.blocker_id);
    }
  }

  recipientIds = recipientIds.filter((id) => !blocked.has(id));
  if (recipientIds.length === 0) {
    return jsonResponse(200, { message: "recipients_blocked" });
  }

  // 5. Fetch Device Tokens first (don't depend on profile row existence)
  const { data: tokenRows, error: tokensError } = await supabase
    .from("device_tokens")
    .select("token, user_id")
    .in("user_id", recipientIds);

  if (tokensError) {
    return jsonResponse(500, {
      error: "db_error",
      details: tokensError.message,
    });
  }

  if (!tokenRows || tokenRows.length === 0) {
    return jsonResponse(200, { message: "no_device_tokens_found" });
  }

  // 5b. Fetch recipient locales separately; fallback handles missing rows/locales.
  const { data: profileRows, error: profilesError } = await supabase
    .from("profiles")
    .select("user_id, locale")
    .in("user_id", recipientIds);

  if (profilesError) {
    return jsonResponse(500, {
      error: "db_error",
      details: profilesError.message,
    });
  }

  const localeByUserId = new Map<string, string | null>();
  for (const row of profileRows ?? []) {
    const userId = row.user_id as string | null;
    if (!userId) continue;
    localeByUserId.set(userId, (row.locale as string | null) ?? null);
  }

  // Build token-to-locale list (deduplicated by token)
  const seen = new Set<string>();
  const tokenLocales: { token: string; locale: string | null }[] = [];
  for (const row of tokenRows) {
    const tk = row.token as string;
    if (seen.has(tk)) continue;
    seen.add(tk);
    const userId = row.user_id as string | null;
    tokenLocales.push({
      token: tk,
      locale: userId ? (localeByUserId.get(userId) ?? null) : null,
    });
  }

  let serviceAccount: ServiceAccount;
  if (GOOGLE_SERVICE_ACCOUNT) {
    try {
      serviceAccount = JSON.parse(GOOGLE_SERVICE_ACCOUNT);
      if (serviceAccount.private_key) {
        serviceAccount.private_key = serviceAccount.private_key.replace(
          /\\n/g,
          "\n",
        );
      }
    } catch (_e) {
      return jsonResponse(500, { error: "invalid_service_account_json" });
    }
  } else if (FCM_PROJECT_ID && FCM_CLIENT_EMAIL && FCM_PRIVATE_KEY) {
    serviceAccount = {
      project_id: FCM_PROJECT_ID,
      client_email: FCM_CLIENT_EMAIL,
      private_key: FCM_PRIVATE_KEY,
      token_uri: "https://oauth2.googleapis.com/token",
    };
  } else {
    return jsonResponse(500, { error: "fcm_config_missing" });
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(serviceAccount);
  } catch (e) {
    return jsonResponse(500, {
      error: "fcm_auth_failed",
      details: String(e),
    });
  }

  // 6. Send localized notifications per recipient
  const projectId = serviceAccount.project_id;
  const fcmEndpoint =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const results = await Promise.all(tokenLocales.map(async ({ token, locale }) => {
    const strings = getL10n(locale);
    const message = {
      message: {
        token: token,
        notification: {
          title: strings.title,
          body: payload.caption || strings.defaultBody,
        },
        data: {
          room_id: payload.room_id,
          message_id: payload.message_id,
          type: "feed_event",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        // Apple specific config
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      },
    };

    try {
      const res = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(message),
      });

      if (!res.ok) {
        const txt = await res.text();
        return {
          token,
          ok: false,
          error: `HTTP ${res.status}: ${txt}`,
        };
      }

      const data = await res.json();
      return { token, ok: true, response: data };
    } catch (error) {
      return { token, ok: false, error: String(error) };
    }
  }));

  const failures = results.filter((r) => !r.ok);
  const successes = results.length - failures.length;

  return jsonResponse(200, {
    success: failures.length === 0,
    sent_count: successes,
    failure_count: failures.length,
    total_tokens: tokenLocales.length,
    failures: failures.map((f) => ({
      token: f.token,
      error: f.error,
    })),
  });
});
