import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.9.1/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const NOTIFY_WEBHOOK_SECRET = Deno.env.get("NOTIFY_WEBHOOK_SECRET") ?? "";
const GOOGLE_SERVICE_ACCOUNT = Deno.env.get("GOOGLE_SERVICE_ACCOUNT") ?? "";
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "";
const FCM_CLIENT_EMAIL = Deno.env.get("FCM_CLIENT_EMAIL") ?? "";
const FCM_PRIVATE_KEY = (Deno.env.get("FCM_PRIVATE_KEY") ?? "").replace(
  /\\n/g,
  "\n",
);
type PetType = "cat" | "fish" | "ghost";

const PET_AVATAR_URL_BY_TYPE: Record<PetType, string> = {
  cat: "https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/cat_stay.gif",
  fish: "https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/fish_stay.gif",
  ghost:
    "https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/ghost_stay.gif",
};
const PET_AVATAR_ASSET_BY_TYPE: Record<PetType, string> = {
  cat: "assets/pet/cat/cat_stay.gif",
  fish: "assets/pet/fish/fish_stay.gif",
  ghost: "assets/pet/ghost/ghost_stay.gif",
};
const DEFAULT_PET_TYPE: PetType = "ghost";
const DEFAULT_PET_AVATAR_URL = PET_AVATAR_URL_BY_TYPE[DEFAULT_PET_TYPE];

type L10nStrings = {
  defaultTextBody: string;
  defaultPetName: string;
  defaultSenderName: string;
  feedBodyTemplate: string;
  hungerReminderTemplate: string;
  hungerUrgentTemplate: string;
};

const l10n: Record<string, L10nStrings> = {
  en: {
    defaultTextBody: "New message",
    defaultPetName: "Pet",
    defaultSenderName: "Someone",
    feedBodyTemplate: "{sender} fed {pet}",
    hungerReminderTemplate: "{pet} is getting hungry. Time to feed!",
    hungerUrgentTemplate: "{pet} is very hungry! Please feed now!",
  },
  ja: {
    defaultTextBody: "新しいメッセージ",
    defaultPetName: "ペット",
    defaultSenderName: "だれか",
    feedBodyTemplate: "{sender}さんが{pet}にごはんをあげました",
    hungerReminderTemplate: "{pet}がお腹を空かせています。ごはんをあげてください！",
    hungerUrgentTemplate: "{pet}がとてもお腹を空かせています！今すぐごはんを！",
  },
  "zh-TW": {
    defaultTextBody: "新訊息",
    defaultPetName: "寵物",
    defaultSenderName: "某人",
    feedBodyTemplate: "{sender} 餵了 {pet}",
    hungerReminderTemplate: "{pet} 有點餓了，記得餵食！",
    hungerUrgentTemplate: "{pet} 非常餓！請立即餵食！",
  },
};

function normalizeLocale(locale: string | null | undefined): string {
  if (!locale) return "zh-TW";
  const trimmed = locale.trim();
  if (!trimmed) return "zh-TW";
  if (/^ja([_-].+)?$/i.test(trimmed)) return "ja";
  if (/^en([_-].+)?$/i.test(trimmed)) return "en";
  if (/^zh([_-].+)?$/i.test(trimmed)) return "zh-TW";
  const lang = trimmed.split(/[-_]/)[0]?.toLowerCase();
  if (lang === "ja") return "ja";
  if (lang === "en") return "en";
  if (lang === "zh") return "zh-TW";
  return "en";
}

function localizedAppName(locale: string | null | undefined): string {
  return normalizeLocale(locale) === "ja" ? "ペットモ" : "PetTomo";
}

function getL10n(locale: string | null | undefined): L10nStrings {
  const normalized = normalizeLocale(locale);
  return l10n[normalized] ?? l10n.en;
}

type NotifyPayload = {
  type: "feed_event" | "chat_message" | "hunger_alert";
  room_id: string;
  sender_id?: string;
  recipient_ids?: string[];
  message_id: string;
  alert_level?: number;
  image_url?: string | null;
  caption?: string | null;
  body?: string | null;
  canonical_tags?: string[];
  created_at?: string | null;
};

type TokenTarget = {
  token: string;
  userId: string | null;
  locale: string | null;
  platform: string | null;
};

type SendResult = {
  token: string;
  userId: string | null;
  locale: string | null;
  platform: string | null;
  ok: boolean;
  status?: number;
  error?: string;
  response?: unknown;
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
  const exp = getNumericDate(3600);

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

function nonEmptyOrNull(value: string | null | undefined): string | null {
  if (!value) return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function collapseName(value: string, max: number = 7): string {
  if (value.length <= max) {
    return value;
  }
  return `${value.substring(0, max)}...`;
}

function fillTemplate(
  template: string,
  values: Record<string, string>,
): string {
  return template.replace(/\{(\w+)\}/g, (_full, key: string) =>
    values[key] ?? _full
  );
}

function normalizePetType(value: string | null | undefined): PetType {
  const normalized = value?.trim().toLowerCase();
  if (normalized === "cat" || normalized === "fish" || normalized === "ghost") {
    return normalized;
  }
  return DEFAULT_PET_TYPE;
}

function extractPetType(colorDna: unknown): PetType {
  if (!colorDna || typeof colorDna !== "object") {
    return DEFAULT_PET_TYPE;
  }
  const petTypeValue = (colorDna as Record<string, unknown>).pet_type;
  if (typeof petTypeValue !== "string") {
    return DEFAULT_PET_TYPE;
  }
  return normalizePetType(petTypeValue);
}

function tokenPrefix(token: string): string {
  return token.length <= 12 ? token : token.slice(0, 12);
}

function tokenSuffix(token: string): string {
  return token.length <= 12 ? token : token.slice(-12);
}

function truncateText(value: string, max: number): string {
  return value.length <= max ? value : `${value.slice(0, max)}...`;
}

function isStaleTokenFailure(errorText: string | undefined): boolean {
  const normalized = (errorText ?? "").toLowerCase();
  return normalized.includes("registration-token-not-registered") ||
    normalized.includes("\"errorcode\":\"unregistered\"") ||
    normalized.includes("\"status\":\"unregistered\"") ||
    normalized.includes("messaging/registration-token-not-registered");
}

function resolveHungerAlertLevel(
  payloadLevel: number | undefined,
  body: string | null | undefined,
): 50 | 30 | 10 | null {
  if (payloadLevel === 50 || payloadLevel === 30 || payloadLevel === 10) {
    return payloadLevel;
  }
  const normalized = (body ?? "").trim();
  if (normalized.startsWith("hunger_alert_50::")) {
    return 50;
  }
  if (normalized.startsWith("hunger_alert_30::")) {
    return 30;
  }
  if (normalized.startsWith("hunger_alert_10::")) {
    return 10;
  }
  return null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  let payload: NotifyPayload;
  try {
    payload = await req.json();
  } catch (_error) {
    return jsonResponse(400, { error: "invalid_json" });
  }

  const webhookAuthHeader = `Bearer ${NOTIFY_WEBHOOK_SECRET}`;
  const isSignedWebhook = !!NOTIFY_WEBHOOK_SECRET &&
    authHeader === webhookAuthHeader;
  const isUnsignedWebhook = !NOTIFY_WEBHOOK_SECRET &&
    !!payload.sender_id &&
    Array.isArray(payload.recipient_ids);
  const isWebhookRequest = isSignedWebhook || isUnsignedWebhook;

  if (
    !!NOTIFY_WEBHOOK_SECRET &&
    !!payload.sender_id &&
    authHeader !== webhookAuthHeader
  ) {
    return jsonResponse(401, { error: "invalid_webhook_secret" });
  }

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !SUPABASE_ANON_KEY) {
    return jsonResponse(500, { error: "server_config_error" });
  }
  const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const isHungerAlert = payload.type === "hunger_alert";
  let senderId = payload.sender_id ?? null;
  let recipientIds = Array.isArray(payload.recipient_ids)
    ? payload.recipient_ids.filter((id) => typeof id === "string")
    : [];

  if (isWebhookRequest) {
    if (!isHungerAlert && !senderId) {
      return jsonResponse(400, { error: "missing_sender_id" });
    }

    const needsMessageLookup = !nonEmptyOrNull(payload.body) &&
      !nonEmptyOrNull(payload.caption) &&
      !nonEmptyOrNull(payload.image_url);

    if (needsMessageLookup) {
      let messageQuery = supabaseAdmin
        .from("messages")
        .select("id, room_id, sender_id, type, body, caption, image_url")
        .eq("id", payload.message_id)
        .eq("room_id", payload.room_id);
      if (!isHungerAlert && senderId) {
        messageQuery = messageQuery.eq("sender_id", senderId);
      }

      const { data: messageRow, error: messageError } = await messageQuery
        .maybeSingle();
      if (messageError) {
        return jsonResponse(500, {
          error: "db_error",
          details: messageError.message,
        });
      }
      if (messageRow) {
        if (messageRow.type === "text") {
          payload.type = "chat_message";
          payload.body = messageRow.body;
          payload.caption = null;
          payload.image_url = null;
        } else if (messageRow.type === "image_feed") {
          payload.type = "feed_event";
          payload.caption = messageRow.caption;
          payload.image_url = messageRow.image_url;
          payload.body = null;
        } else if (messageRow.type === "system" && payload.type === "hunger_alert") {
          payload.body = messageRow.body;
          payload.caption = null;
          payload.image_url = null;
        }
      }
    }

    if (isHungerAlert) {
      const { data: memberRows, error: membersError } = await supabaseAdmin
        .from("room_members")
        .select("user_id")
        .eq("room_id", payload.room_id)
        .eq("is_active", true);
      if (membersError) {
        return jsonResponse(500, {
          error: "db_error",
          details: membersError.message,
        });
      }
      recipientIds = (memberRows ?? [])
        .map((row) => row.user_id as string | null)
        .filter((id): id is string => !!id);
    }
  } else {
    const supabaseAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: authData, error: authError } = await supabaseAuth.auth
      .getUser();
    if (authError || !authData.user) {
      return jsonResponse(401, { error: "unauthorized" });
    }
    senderId = authData.user.id;

    if (isHungerAlert) {
      const { data: membershipRow, error: membershipError } = await supabaseAdmin
        .from("room_members")
        .select("room_id")
        .eq("room_id", payload.room_id)
        .eq("user_id", senderId)
        .eq("is_active", true)
        .maybeSingle();
      if (membershipError) {
        return jsonResponse(500, {
          error: "db_error",
          details: membershipError.message,
        });
      }
      if (!membershipRow) {
        return jsonResponse(403, { error: "not_room_member" });
      }

      const { data: messageRow, error: messageError } = await supabaseAdmin
        .from("messages")
        .select("id, room_id, type, body")
        .eq("id", payload.message_id)
        .eq("room_id", payload.room_id)
        .eq("type", "system")
        .maybeSingle();
      if (messageError) {
        return jsonResponse(500, {
          error: "db_error",
          details: messageError.message,
        });
      }
      if (!messageRow) {
        return jsonResponse(403, { error: "message_not_found" });
      }

      payload.body = messageRow.body;
      payload.caption = null;
      payload.image_url = null;

      const { data: memberRows, error: membersError } = await supabaseAdmin
        .from("room_members")
        .select("user_id")
        .eq("room_id", payload.room_id)
        .eq("is_active", true);
      if (membersError) {
        return jsonResponse(500, {
          error: "db_error",
          details: membersError.message,
        });
      }
      recipientIds = (memberRows ?? [])
        .map((row) => row.user_id as string | null)
        .filter((id): id is string => !!id);
    } else {
      const { data: messageRow, error: messageError } = await supabaseAdmin
        .from("messages")
        .select("id, room_id, sender_id, type, body, caption, image_url")
        .eq("id", payload.message_id)
        .eq("room_id", payload.room_id)
        .eq("sender_id", senderId)
        .maybeSingle();
      if (messageError) {
        return jsonResponse(500, {
          error: "db_error",
          details: messageError.message,
        });
      }
      if (!messageRow) {
        return jsonResponse(403, { error: "message_not_owned" });
      }

      if (messageRow.type === "text") {
        payload.type = "chat_message";
        payload.body = messageRow.body;
        payload.caption = null;
        payload.image_url = null;
      } else if (messageRow.type === "image_feed") {
        payload.type = "feed_event";
        payload.caption = messageRow.caption;
        payload.image_url = messageRow.image_url;
        payload.body = null;
      } else {
        return jsonResponse(200, { message: "message_type_not_notifiable" });
      }

      const { data: memberRows, error: membersError } = await supabaseAdmin
        .from("room_members")
        .select("user_id")
        .eq("room_id", payload.room_id)
        .eq("is_active", true);
      if (membersError) {
        return jsonResponse(500, {
          error: "db_error",
          details: membersError.message,
        });
      }

      recipientIds = (memberRows ?? [])
        .map((row) => row.user_id as string | null)
        .filter((id): id is string => !!id && id !== senderId);
    }
  }

  if (recipientIds.length === 0) {
    return jsonResponse(200, { message: "no_recipients" });
  }

  recipientIds = recipientIds.filter((id) => typeof id === "string" && id.length > 0);
  if (!isHungerAlert) {
    if (!senderId) {
      return jsonResponse(200, { message: "no_recipients" });
    }
    recipientIds = recipientIds.filter((id) => id !== senderId);
  }

  if (recipientIds.length === 0) {
    return jsonResponse(200, { message: "no_recipients" });
  }

  if (!isHungerAlert && senderId) {
    const { data: blockedBySender, error: blockedBySenderError } = await supabaseAdmin
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

    const { data: blockedSender, error: blockedSenderError } = await supabaseAdmin
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
  }

  if (isHungerAlert) {
    const { data: existingDelivery, error: existingDeliveryError } = await supabaseAdmin
      .from("notification_delivery_logs")
      .select("id")
      .eq("message_id", payload.message_id)
      .eq("payload_type", "hunger_alert")
      .eq("success", true)
      .limit(1);
    if (existingDeliveryError) {
      return jsonResponse(500, {
        error: "db_error",
        details: existingDeliveryError.message,
      });
    }
    if ((existingDelivery ?? []).length > 0) {
      return jsonResponse(200, { message: "already_sent" });
    }
  }

  const { data: tokenRows, error: tokensError } = await supabaseAdmin
    .from("device_tokens")
    .select("token, user_id, device_locale, platform")
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

  const { data: profileRows, error: profilesError } = await supabaseAdmin
    .from("profiles")
    .select("user_id, locale")
    .in("user_id", recipientIds);

  if (profilesError) {
    return jsonResponse(500, {
      error: "db_error",
      details: profilesError.message,
    });
  }

  const { data: petRow, error: petError } = await supabaseAdmin
    .from("pets")
    .select("name, avatar_url, color_dna")
    .eq("room_id", payload.room_id)
    .maybeSingle();

  if (petError) {
    return jsonResponse(500, {
      error: "db_error",
      details: petError.message,
    });
  }

  let senderProfile: { nickname: string | null } | null = null;
  if (senderId) {
    const { data: fetchedSenderProfile, error: senderProfileError } = await supabaseAdmin
      .from("profiles")
      .select("nickname")
      .eq("user_id", senderId)
      .maybeSingle();

    if (senderProfileError) {
      return jsonResponse(500, {
        error: "db_error",
        details: senderProfileError.message,
      });
    }
    senderProfile = fetchedSenderProfile as { nickname: string | null } | null;
  }

  const localeByUserId = new Map<string, string | null>();
  for (const row of profileRows ?? []) {
    const userId = row.user_id as string | null;
    if (!userId) continue;
    localeByUserId.set(userId, (row.locale as string | null) ?? null);
  }

  const seen = new Set<string>();
  const tokenTargets: TokenTarget[] = [];
  for (const row of tokenRows) {
    const tk = row.token as string;
    if (seen.has(tk)) continue;
    seen.add(tk);
    const userId = row.user_id as string | null;
    const deviceLocale = nonEmptyOrNull(row.device_locale as string | null);
    const profileLocale = userId ? localeByUserId.get(userId) ?? null : null;
    tokenTargets.push({
      token: tk,
      userId,
      locale: deviceLocale ?? profileLocale,
      platform: nonEmptyOrNull(row.platform as string | null),
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

  const petName = nonEmptyOrNull(petRow?.name as string | null);
  const petType = extractPetType((petRow?.color_dna as unknown) ?? null);
  const petAvatarUrl = nonEmptyOrNull(petRow?.avatar_url as string | null) ??
    PET_AVATAR_URL_BY_TYPE[petType] ??
    DEFAULT_PET_AVATAR_URL;
  const petAvatarAsset = PET_AVATAR_ASSET_BY_TYPE[petType];
  const petAvatarFallbackUrl = PET_AVATAR_URL_BY_TYPE[petType] ??
    DEFAULT_PET_AVATAR_URL;
  const senderNameRaw = nonEmptyOrNull(senderProfile?.nickname as string | null);
  const hungerAlertLevel = isHungerAlert
    ? resolveHungerAlertLevel(payload.alert_level, nonEmptyOrNull(payload.body))
    : null;
  if (isHungerAlert && hungerAlertLevel == null) {
    return jsonResponse(400, { error: "invalid_hunger_alert_level" });
  }

  const projectId = serviceAccount.project_id;
  const fcmEndpoint =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const results = await Promise.all(tokenTargets.map(async ({
    token,
    userId,
    locale,
    platform,
  }) => {
    let unreadTotal = 0;
    if (userId) {
      const { data: unreadData, error: unreadError } = await supabaseAdmin
        .rpc("get_unread_message_total_for_user", { p_user_id: userId });
      if (unreadError) {
        console.warn(JSON.stringify({
          event: "notify_friend_unread_count_failed",
          user_id: userId,
          details: unreadError.message,
        }));
      } else if (typeof unreadData === "number" && Number.isFinite(unreadData)) {
        unreadTotal = Math.max(0, Math.trunc(unreadData));
      }
    }

    const strings = getL10n(locale);
    const appName = localizedAppName(locale);
    const resolvedPetName = petName ?? strings.defaultPetName;
    const resolvedSenderName = senderNameRaw ?? strings.defaultSenderName;
    const collapsedPetName = collapseName(resolvedPetName, 7);
    const collapsedPetNameForTitle = collapseName(resolvedPetName, 15);
    const collapsedSenderName = collapseName(resolvedSenderName, 7);
    const titleFull = collapsedPetNameForTitle;

    const textBodyRaw = nonEmptyOrNull(payload.body) ?? strings.defaultTextBody;
    const textBody = `${collapsedSenderName}: ${textBodyRaw}`;
    const feedCaption = nonEmptyOrNull(payload.caption);
    const feedBody = fillTemplate(strings.feedBodyTemplate, {
      sender: collapsedSenderName,
      pet: collapsedPetName,
    });
    const hungerBody = hungerAlertLevel === 10
      ? fillTemplate(strings.hungerUrgentTemplate, {
        pet: collapsedPetNameForTitle,
      })
      : fillTemplate(strings.hungerReminderTemplate, {
        pet: collapsedPetNameForTitle,
      });

    const messageType = payload.type === "chat_message"
      ? "text"
      : (payload.type === "hunger_alert"
        ? `hunger_alert_${hungerAlertLevel}`
        : "image_feed");
    const pushBody = payload.type === "chat_message"
      ? textBody
      : (payload.type === "hunger_alert" ? hungerBody : feedBody);
    const pushSenderName = payload.type === "hunger_alert"
      ? ""
      : collapsedSenderName;

    const dataPayload: Record<string, string> = {
      room_id: payload.room_id,
      message_id: payload.message_id,
      // FCM reserves "message_type" as an internal key.
      message_kind: messageType,
      pet_name: collapsedPetNameForTitle,
      sender_name: pushSenderName,
      pet_type: petType,
      pet_avatar_asset: petAvatarAsset,
      pet_avatar_fallback_url: petAvatarFallbackUrl,
      pet_avatar_url: petAvatarUrl,
      image_url: nonEmptyOrNull(payload.image_url) ?? "",
      caption: feedCaption ?? "",
      text_body: textBodyRaw,
      body_full: pushBody,
      title_app_name: appName,
      title_full: titleFull,
      unread_total: String(unreadTotal),
      type: payload.type,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    };

    const message: Record<string, unknown> = {
      message: {
        token,
        notification: {
          title: titleFull,
          body: pushBody,
        },
        data: dataPayload,
        android: {
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
          payload: {
            aps: {
              alert: {
                title: titleFull,
                body: pushBody,
              },
              sound: "default",
              badge: unreadTotal,
              "mutable-content": 1,
              "thread-id": `room_${payload.room_id}`,
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
          userId,
          locale,
          platform,
          ok: false,
          status: res.status,
          error: `HTTP ${res.status}: ${truncateText(txt, 1000)}`,
        };
      }

      const data = await res.json();
      return {
        token,
        userId,
        locale,
        platform,
        ok: true,
        response: data,
      };
    } catch (error) {
      return {
        token,
        userId,
        locale,
        platform,
        ok: false,
        error: truncateText(String(error), 1000),
      };
    }
  })) as SendResult[];

  const failures = results.filter((r) => !r.ok);
  const successes = results.length - failures.length;
  const staleTokens = failures
    .filter((f) => isStaleTokenFailure(f.error))
    .map((f) => f.token)
    .filter((token, index, arr) => arr.indexOf(token) === index);

  if (staleTokens.length > 0) {
    await supabaseAdmin
      .from("device_tokens")
      .delete()
      .in("token", staleTokens);
  }

  const deliveryLogRows = results.map((result) => ({
    room_id: payload.room_id,
    message_id: payload.message_id,
    sender_id: senderId,
    recipient_user_id: result.userId,
    token_prefix: tokenPrefix(result.token),
    token_suffix: tokenSuffix(result.token),
    platform: result.platform,
    locale: result.locale,
    payload_type: payload.type,
    message_kind: payload.type === "chat_message"
      ? "text"
      : (payload.type === "hunger_alert"
        ? `hunger_alert_${hungerAlertLevel ?? 30}`
        : "image_feed"),
    success: result.ok,
    http_status: result.status ?? null,
    error_text: result.ok ? null : result.error ?? "unknown_error",
    provider_response: result.ok ? result.response ?? null : null,
  }));

  if (deliveryLogRows.length > 0) {
    const { error: deliveryLogError } = await supabaseAdmin
      .from("notification_delivery_logs")
      .insert(deliveryLogRows);
    if (deliveryLogError) {
      console.warn(JSON.stringify({
        event: "notify_friend_delivery_log_failed",
        details: deliveryLogError.message,
      }));
    }
  }

  console.log(JSON.stringify({
    event: "notify_friend_result",
    type: payload.type,
    room_id: payload.room_id,
    message_id: payload.message_id,
    recipients: recipientIds.length,
    tokens: tokenTargets.length,
    sent_count: successes,
    failure_count: failures.length,
    stale_tokens_removed: staleTokens.length,
  }));

  if (failures.length > 0) {
    console.warn(JSON.stringify({
      event: "notify_friend_failures",
      failures: failures.slice(0, 5).map((failure) => ({
        token_prefix: tokenPrefix(failure.token),
        status: failure.status ?? null,
        error: failure.error ?? "unknown_error",
      })),
    }));
  }

  const responseStatus = successes === 0 && results.length > 0 ? 502 : 200;

  return jsonResponse(responseStatus, {
    success: failures.length === 0,
    sent_count: successes,
    failure_count: failures.length,
    total_tokens: tokenTargets.length,
    failures: failures.map((f) => ({
      token_prefix: tokenPrefix(f.token),
      status: f.status ?? null,
      error: f.error,
    })),
  });
});
