import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { AwsClient } from "https://esm.sh/aws4fetch@1.0.18";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

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
  "image/heic": "heic",
  "image/heif": "heif",
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
  authHeader,
  roomId,
  messageId,
}: {
  authHeader: string;
  roomId: string;
  messageId: string;
}): Promise<WebhookResult> {
  const notifyUrl = `${SUPABASE_URL.replace(/\/$/, "")}/functions/v1/notify_friend`;
  const headers = {
    Authorization: authHeader,
    "Content-Type": "application/json",
  };

  const payload = {
    type: "feed_event",
    room_id: roomId,
    message_id: messageId,
  };

  try {
    const response = await fetch(notifyUrl, {
      method: "POST",
      headers,
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const detail = await response.text().catch(() => "");
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

  const labelsPayload = labeledInputs.map((label) => ({
    text: label.text,
    confidence: label.confidence,
    canonical_tag: label.canonical_tag,
  }));

  const { data: processFeedData, error: processFeedError } = await supabase.rpc(
    "process_feed_event",
    {
      p_room_id: roomId,
      p_image_url: imageUrl,
      p_caption: payload.caption ?? null,
      p_labels: labelsPayload,
      p_client_created_at: payload.client_created_at ?? null,
    },
  );

  if (processFeedError) {
    return jsonResponse(500, {
      error: "process_feed_event_failed",
      detail: processFeedError.message,
    });
  }

  const processFeedRow =
    Array.isArray(processFeedData) ? processFeedData[0] : processFeedData;
  if (!processFeedRow || typeof processFeedRow !== "object") {
    return jsonResponse(500, { error: "process_feed_event_invalid_response" });
  }
  const processFeedRecord = processFeedRow as Record<string, unknown>;

  const messageId = typeof processFeedRecord.message_id === "string"
    ? processFeedRecord.message_id
    : null;
  if (!messageId) {
    return jsonResponse(500, { error: "process_feed_event_missing_message_id" });
  }

  const baseReward = typeof processFeedRecord.base_reward === "number"
    ? processFeedRecord.base_reward
    : (typeof processFeedRecord.base_reward === "string"
      ? Number.parseInt(processFeedRecord.base_reward, 10) || 0
      : 0);
  const rewardStatus = typeof processFeedRecord.reward_status === "string"
    ? processFeedRecord.reward_status
    : (baseReward > 0 ? "granted" : "cooldown");
  const cooldownLastFedAt = typeof processFeedRecord.last_fed_at === "string"
    ? processFeedRecord.last_fed_at
    : null;
  const cooldownNextEligibleAt =
    typeof processFeedRecord.next_eligible_at === "string"
      ? processFeedRecord.next_eligible_at
      : null;
  const cooldownIsActive = cooldownNextEligibleAt != null &&
    new Date(cooldownNextEligibleAt).getTime() > Date.now();

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

  if (questBonus > 0) {
    const { error: messageRewardError } = await supabase
      .from("messages")
      .update({ coins_awarded: totalReward })
      .eq("id", messageId)
      .eq("room_id", roomId)
      .eq("sender_id", authData.user.id);
    if (messageRewardError) {
      questAwardError = questAwardError == null
        ? "message_reward_sync_failed"
        : `${questAwardError};message_reward_sync_failed`;
    }
  }

  const webhookResult = await notifyPartner({
    authHeader,
    roomId,
    messageId,
  });

  return jsonResponse(200, {
    ok: true,
    message_id: messageId,
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
    reward_status: rewardStatus,
    cooldown_scope: {
      user_id: authData.user.id,
      room_id: roomId,
      action_type: "feed",
    },
    cooldown: {
      is_active: cooldownIsActive,
      last_fed_at: cooldownLastFedAt,
      next_eligible_at: cooldownNextEligibleAt,
    },
  });
});
