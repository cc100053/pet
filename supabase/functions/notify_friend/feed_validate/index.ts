import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { AwsClient } from "https://esm.sh/aws4fetch@1.0.18";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const R2_ENDPOINT = Deno.env.get("R2_ENDPOINT") ?? "";
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID") ?? "";
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY") ?? "";
const R2_BUCKET = Deno.env.get("R2_BUCKET") ?? "";
const R2_PUBLIC_BASE_URL = Deno.env.get("R2_PUBLIC_BASE_URL") ?? "";
const NOTIFY_WEBHOOK_URL = Deno.env.get("NOTIFY_WEBHOOK_URL") ?? "";
const NOTIFY_WEBHOOK_SECRET = Deno.env.get("NOTIFY_WEBHOOK_SECRET") ?? "";

const MIN_CONFIDENCE = 0.6;
const MAX_LABELS = 20;

type LabelInput =
  | string
  | {
      text?: string;
      label?: string;
      description?: string;
      confidence?: number;
      score?: number;
    };

type NormalizedLabel = {
  text: string;
  confidence: number;
};

type FeedRequest = {
  room_id?: string;
  roomId?: string;
  labels?: LabelInput[];
  caption?: string;
  image_base64?: string;
  image_url?: string;
  image_content_type?: string;
  image_filename?: string;
  client_created_at?: string;
};

const EXTENSION_BY_CONTENT_TYPE: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function normalizeLabels(input: unknown): NormalizedLabel[] {
  if (!Array.isArray(input)) {
    return [];
  }

  const normalized: NormalizedLabel[] = [];

  for (const entry of input) {
    if (typeof entry === "string") {
      const text = entry.trim();
      if (text) {
        normalized.push({ text, confidence: 1 });
      }
      continue;
    }

    if (entry && typeof entry === "object") {
      const label = entry.text ?? entry.label ?? entry.description ?? "";
      const text = typeof label === "string" ? label.trim() : "";
      if (!text) {
        continue;
      }
      const confidenceRaw = entry.confidence ?? entry.score;
      const confidence = typeof confidenceRaw === "number"
        ? confidenceRaw
        : 1;
      normalized.push({ text, confidence });
    }
  }

  return normalized.slice(0, MAX_LABELS);
}

function toTitleCase(text: string) {
  return text
    .split(" ")
    .map((part) => {
      if (!part) {
        return "";
      }
      return part[0].toUpperCase() + part.slice(1).toLowerCase();
    })
    .join(" ");
}

function buildLabelVariants(labels: string[]) {
  const variants = new Set<string>();
  for (const label of labels) {
    const trimmed = label.trim();
    if (!trimmed) {
      continue;
    }
    variants.add(trimmed);
    variants.add(trimmed.toLowerCase());
    variants.add(trimmed.toUpperCase());
    variants.add(toTitleCase(trimmed));
  }
  return Array.from(variants);
}

function extractBase64Payload(input: string) {
  if (input.startsWith("data:")) {
    const [header, data] = input.split(",", 2);
    const match = header.match(/^data:(.+);base64$/);
    return {
      contentType: match?.[1],
      base64: data ?? "",
    };
  }
  return {
    contentType: undefined,
    base64: input,
  };
}

function decodeBase64(input: string) {
  const binary = atob(input);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function buildDatePath(now: Date) {
  const yyyy = now.getUTCFullYear();
  const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(now.getUTCDate()).padStart(2, "0");
  return `${yyyy}/${mm}/${dd}`;
}

type WebhookResult = {
  skipped: boolean;
  status?: number;
  error?: string;
};

async function notifyPartner({
  supabase,
  roomId,
  senderId,
  messageId,
  imageUrl,
  caption,
  canonicalTags,
  createdAt,
}: {
  supabase: SupabaseClient;
  roomId: string;
  senderId: string;
  messageId: string;
  imageUrl: string;
  caption: string | null;
  canonicalTags: string[];
  createdAt: string | null;
}): Promise<WebhookResult> {
  if (!NOTIFY_WEBHOOK_URL) {
    return { skipped: true };
  }

  const { data: members, error: membersError } = await supabase
    .from("room_members")
    .select("user_id")
    .eq("room_id", roomId)
    .eq("is_active", true)
    .neq("user_id", senderId);

  if (membersError) {
    return { skipped: true, error: "webhook_members_failed" };
  }

  const recipientIds = (members ?? [])
    .map((member) => member.user_id)
    .filter((id) => typeof id === "string" && id.length > 0);

  if (recipientIds.length === 0) {
    return { skipped: true };
  }

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  if (NOTIFY_WEBHOOK_SECRET) {
    headers["Authorization"] = `Bearer ${NOTIFY_WEBHOOK_SECRET}`;
  }

  const payload = {
    type: "feed_event",
    room_id: roomId,
    sender_id: senderId,
    recipient_ids: recipientIds,
    message_id: messageId,
    image_url: imageUrl,
    caption,
    canonical_tags: canonicalTags,
    created_at: createdAt,
  };

  try {
    const response = await fetch(NOTIFY_WEBHOOK_URL, {
      method: "POST",
      headers,
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      let detail = "";
      try {
        detail = await response.text();
      } catch (_error) {
        detail = "";
      }
      return {
        skipped: false,
        status: response.status,
        error: `webhook_failed:${response.status}${detail ? `:${detail}` : ""}`,
      };
    }

    return { skipped: false, status: response.status };
  } catch (_error) {
    return { skipped: false, error: "webhook_fetch_failed" };
  }
}

async function uploadToR2(
  bytes: Uint8Array,
  contentType: string,
  key: string,
) {
  if (
    !R2_ENDPOINT || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY ||
    !R2_BUCKET || !R2_PUBLIC_BASE_URL
  ) {
    throw new Error("r2_not_configured");
  }

  const client = new AwsClient({
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
    service: "s3",
    region: "auto",
  });

  const endpoint = R2_ENDPOINT.replace(/\/$/, "");
  const url = `${endpoint}/${R2_BUCKET}/${key}`;

  const response = await client.fetch(url, {
    method: "PUT",
    body: bytes,
    headers: {
      "Content-Type": contentType,
    },
  });

  if (!response.ok) {
    throw new Error(`r2_upload_failed:${response.status}`);
  }

  return `${R2_PUBLIC_BASE_URL.replace(/\/$/, "")}/${key}`;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return jsonResponse(500, { error: "supabase_env_missing" });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return jsonResponse(401, { error: "missing_auth" });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData?.user) {
    return jsonResponse(401, { error: "invalid_auth" });
  }

  let payload: FeedRequest;
  try {
    payload = await req.json();
  } catch (_error) {
    return jsonResponse(400, { error: "invalid_json" });
  }

  const roomId = payload.room_id ?? payload.roomId;
  if (!roomId) {
    return jsonResponse(400, { error: "missing_room_id" });
  }

  const { data: membership, error: membershipError } = await supabase
    .from("room_members")
    .select("user_id")
    .eq("room_id", roomId)
    .eq("user_id", authData.user.id)
    .eq("is_active", true)
    .maybeSingle();

  if (membershipError) {
    return jsonResponse(500, { error: "membership_check_failed" });
  }

  if (!membership) {
    return jsonResponse(403, { error: "not_member" });
  }

  const { data: pet, error: petError } = await supabase
    .from("pets")
    .select("id")
    .eq("room_id", roomId)
    .maybeSingle();

  if (petError) {
    return jsonResponse(500, { error: "pet_lookup_failed" });
  }

  if (!pet) {
    return jsonResponse(404, { error: "pet_missing" });
  }

  const normalizedLabels = normalizeLabels(payload.labels);
  const eligibleLabels = normalizedLabels.filter((label) =>
    label.confidence >= MIN_CONFIDENCE
  );

  let imageUrl = payload.image_url ?? "";
  if (!imageUrl && payload.image_base64) {
    const { contentType, base64 } = extractBase64Payload(
      payload.image_base64,
    );
    const resolvedContentType = payload.image_content_type ??
      contentType ??
      "image/webp";
    const extension = EXTENSION_BY_CONTENT_TYPE[resolvedContentType] ?? "bin";
    const key = `rooms/${roomId}/${buildDatePath(new Date())}/${
      crypto.randomUUID()
    }.${extension}`;
    try {
      imageUrl = await uploadToR2(
        decodeBase64(base64),
        resolvedContentType,
        key,
      );
    } catch (error) {
      return jsonResponse(500, {
        error: "image_upload_failed",
        detail: String(error?.message ?? error),
      });
    }
  }

  if (!imageUrl) {
    return jsonResponse(400, { error: "missing_image" });
  }

  const { error: petActionError } = await supabase.rpc("apply_pet_action", {
    p_pet_id: pet.id,
    p_action_type: "feed",
  });

  if (petActionError) {
    return jsonResponse(500, { error: "pet_action_failed" });
  }

  let baseReward = 0;
  if (eligibleLabels.length > 0) {
    const { data: reward, error: rewardError } = await supabase.rpc(
      "claim_action_reward",
      { p_action_type: "feed", p_room_id: roomId },
    );
    if (rewardError) {
      return jsonResponse(500, { error: "reward_failed" });
    }
    baseReward = typeof reward === "number" ? reward : 0;
  }

  const labelVariants = buildLabelVariants(
    eligibleLabels.map((label) => label.text),
  );
  const { data: mappings, error: mappingError } = labelVariants.length
    ? await supabase
      .from("label_mappings")
      .select("label_en, canonical_tag, priority")
      .in("label_en", labelVariants)
    : { data: [], error: null };

  if (mappingError) {
    return jsonResponse(500, { error: "label_mapping_failed" });
  }

  const bestMappingByLabel = new Map<string, { tag: string; priority: number }>();
  for (const mapping of mappings ?? []) {
    const labelKey = mapping.label_en.toLowerCase();
    const current = bestMappingByLabel.get(labelKey);
    if (!current || mapping.priority > current.priority) {
      bestMappingByLabel.set(labelKey, {
        tag: mapping.canonical_tag,
        priority: mapping.priority,
      });
    }
  }

  const labeledInputs = normalizedLabels.map((label) => ({
    text: label.text,
    confidence: label.confidence,
    canonical_tag: bestMappingByLabel.get(label.text.toLowerCase())?.tag ?? null,
  }));

  const canonicalTags = Array.from(
    new Set(
      labeledInputs
        .map((label) => label.canonical_tag)
        .filter((tag): tag is string => Boolean(tag)),
    ),
  );

  const today = new Date().toISOString().slice(0, 10);
  const { data: dailyQuest, error: dailyQuestError } = await supabase
    .from("daily_quests")
    .select(
      "id, quest_id, reward_multiplier, status, quests:quest_id (reward_coins, canonical_tags)",
    )
    .eq("room_id", roomId)
    .eq("quest_date", today)
    .eq("status", "active")
    .maybeSingle();

  if (dailyQuestError) {
    return jsonResponse(500, { error: "daily_quest_failed" });
  }

  let questMatched = false;
  let questBonus = 0;
  let questId: string | null = null;
  let dailyQuestId: string | null = null;
  let questAwardError: string | null = null;

  if (baseReward > 0 && canonicalTags.length > 0 && dailyQuest?.quests) {
    const questTags = Array.isArray(dailyQuest.quests.canonical_tags)
      ? dailyQuest.quests.canonical_tags
      : [];
    questMatched = questTags.some((tag) => canonicalTags.includes(tag));

    if (questMatched) {
      const questReward = Math.round(
        (dailyQuest.quests.reward_coins ?? 0) *
          (dailyQuest.reward_multiplier ?? 1),
      );
      questBonus = Math.max(0, questReward - baseReward);
      questId = dailyQuest.quest_id;
      dailyQuestId = dailyQuest.id;

      if (questBonus > 0) {
        const { error: awardError } = await supabase.rpc(
          "award_quest_reward",
          {
            p_room_id: roomId,
            p_daily_quest_id: dailyQuest.id,
            p_amount: questBonus,
          },
        );
        if (awardError) {
          questAwardError = "quest_award_failed";
          questBonus = 0;
        }
      }
    }
  }

  const totalReward = baseReward + questBonus;
  const labelsPayload = labeledInputs.map((label) => ({
    text: label.text,
    confidence: label.confidence,
    canonical_tag: label.canonical_tag,
  }));

  const { data: message, error: messageError } = await supabase
    .from("messages")
    .insert({
      room_id: roomId,
      sender_id: authData.user.id,
      type: "image_feed",
      body: null,
      image_url: imageUrl,
      caption: payload.caption ?? null,
      labels: labelsPayload,
      coins_awarded: totalReward,
      mood_delta: 0,
      client_created_at: payload.client_created_at ?? null,
    })
    .select("id, created_at")
    .single();

  if (messageError) {
    return jsonResponse(500, { error: "message_insert_failed" });
  }

  const webhookResult = await notifyPartner({
    supabase,
    roomId,
    senderId: authData.user.id,
    messageId: message.id,
    imageUrl,
    caption: payload.caption ?? null,
    canonicalTags,
    createdAt: message.created_at ?? null,
  });

  return jsonResponse(200, {
    ok: true,
    message_id: message.id,
    image_url: imageUrl,
    base_reward: baseReward,
    quest_bonus: questBonus,
    coins_awarded: totalReward,
    quest_matched: questMatched,
    quest_id: questId,
    daily_quest_id: dailyQuestId,
    quest_award_error: questAwardError,
    canonical_tags: canonicalTags,
    webhook_skipped: webhookResult.skipped,
    webhook_status: webhookResult.status ?? null,
    webhook_error: webhookResult.error ?? null,
  });
});
