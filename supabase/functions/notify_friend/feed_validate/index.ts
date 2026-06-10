import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

import { corsHeaders, jsonResponse } from "../../_shared/http.ts";
import {
  ALLOWED_IMAGE_CONTENT_TYPES,
  buildDatePath,
  decodeBase64,
  deleteFromR2,
  estimateDecodedBytesFromBase64,
  EXTENSION_BY_CONTENT_TYPE,
  extractBase64Payload,
  MAX_IMAGE_BYTES,
  r2PublicBaseUrl,
  uploadToR2,
} from "../../_shared/images.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

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
      const confidence = typeof confidenceRaw === "number" ? confidenceRaw : 1;
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

type WebhookResult = {
  skipped: boolean;
  status?: number;
  error?: string;
};

type EdgeRuntimeWithWaitUntil = {
  waitUntil?: (promise: Promise<unknown>) => void;
};

function queueBackgroundTask(task: Promise<unknown>): boolean {
  const guardedTask = task.catch((error) => {
    console.error("[feed_validate] background task failed", error);
  });
  const edgeRuntime = (globalThis as { EdgeRuntime?: EdgeRuntimeWithWaitUntil })
    .EdgeRuntime;
  if (typeof edgeRuntime?.waitUntil === "function") {
    edgeRuntime.waitUntil(guardedTask);
    return true;
  }
  return false;
}

async function notifyPartner({
  authHeader,
  roomId,
  messageId,
}: {
  authHeader: string;
  roomId: string;
  messageId: string;
}): Promise<WebhookResult> {
  const notifyUrl = `${
    SUPABASE_URL.replace(/\/$/, "")
  }/functions/v1/notify_friend`;
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

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const requestStartedAt = Date.now();

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
  // Key of an object we uploaded to R2 in this request. Tracked so it can be
  // removed if a later DB step fails, otherwise the object is orphaned forever
  // (no message row will ever reference it). Stays null when the client passed
  // an existing `image_url` that we do not own.
  let uploadedKey: string | null = null;
  if (!imageUrl && payload.image_base64) {
    const { contentType, base64 } = extractBase64Payload(
      payload.image_base64,
    );
    const resolvedContentType = payload.image_content_type ??
      contentType ??
      "image/webp";
    if (!ALLOWED_IMAGE_CONTENT_TYPES.has(resolvedContentType)) {
      return jsonResponse(400, { error: "invalid_image_content_type" });
    }
    const estimatedBytes = estimateDecodedBytesFromBase64(base64);
    if (estimatedBytes <= 0) {
      return jsonResponse(400, { error: "invalid_image_data" });
    }
    if (estimatedBytes > MAX_IMAGE_BYTES) {
      return jsonResponse(413, {
        error: "image_too_large",
        limit_bytes: MAX_IMAGE_BYTES,
      });
    }
    const extension = EXTENSION_BY_CONTENT_TYPE[resolvedContentType] ?? "bin";
    const key = `rooms/${roomId}/${
      buildDatePath(new Date())
    }/${crypto.randomUUID()}.${extension}`;
    let imageBytes: Uint8Array;
    try {
      imageBytes = decodeBase64(base64);
    } catch (_error) {
      return jsonResponse(400, { error: "invalid_image_data" });
    }
    if (imageBytes.length === 0) {
      return jsonResponse(400, { error: "invalid_image_data" });
    }
    if (imageBytes.length > MAX_IMAGE_BYTES) {
      return jsonResponse(413, {
        error: "image_too_large",
        limit_bytes: MAX_IMAGE_BYTES,
      });
    }
    try {
      imageUrl = await uploadToR2(
        imageBytes,
        resolvedContentType,
        key,
      );
      uploadedKey = key;
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

  // When the client supplies its own image_url (presigned direct-to-R2 upload
  // path) rather than base64, only accept URLs we issued: they must live under
  // our R2 public base and this room's prefix. This keeps the client from
  // recording an arbitrary external URL as the feed image. The base64 path
  // (uploadedKey set) is server-controlled and always trusted.
  if (uploadedKey == null) {
    const base = r2PublicBaseUrl();
    const expectedPrefix = base ? `${base}/rooms/${roomId}/` : "";
    if (!expectedPrefix || !imageUrl.startsWith(expectedPrefix)) {
      return jsonResponse(400, { error: "invalid_image_url" });
    }
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

  const bestMappingByLabel = new Map<
    string,
    { tag: string; priority: number }
  >();
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
    canonical_tag: bestMappingByLabel.get(label.text.toLowerCase())?.tag ??
      null,
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

  const processFeedStartedAt = Date.now();
  const { data: processFeedData, error: processFeedError } = await supabase
    .rpc(
      "process_feed_event",
      {
        p_room_id: roomId,
        p_image_url: imageUrl,
        p_caption: payload.caption ?? null,
        p_labels: labelsPayload,
        p_client_created_at: payload.client_created_at ?? null,
      },
    );
  const processFeedDurationMs = Date.now() - processFeedStartedAt;

  if (processFeedError) {
    console.error(
      "[feed_validate] process_feed_event failed",
      JSON.stringify({
        duration_ms: processFeedDurationMs,
        code: processFeedError.code ?? null,
      }),
    );
    // The RPC runs in a single transaction; on error it is rolled back, so no
    // message row references the just-uploaded image. Reclaim it.
    if (uploadedKey) {
      await deleteFromR2(uploadedKey);
    }
    return jsonResponse(500, {
      error: "process_feed_event_failed",
      detail: processFeedError.message,
    });
  }

  const processFeedRow = Array.isArray(processFeedData)
    ? processFeedData[0]
    : processFeedData;
  if (!processFeedRow || typeof processFeedRow !== "object") {
    return jsonResponse(500, { error: "process_feed_event_invalid_response" });
  }
  const processFeedRecord = processFeedRow as Record<string, unknown>;

  const messageId = typeof processFeedRecord.message_id === "string"
    ? processFeedRecord.message_id
    : null;
  if (!messageId) {
    return jsonResponse(500, {
      error: "process_feed_event_missing_message_id",
    });
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

  const notifyStartedAt = Date.now();
  const webhookQueued = queueBackgroundTask(
    notifyPartner({
      authHeader,
      roomId,
      messageId,
    }).then((webhookResult) => {
      console.log(
        "[feed_validate] notify_partner_complete",
        JSON.stringify({
          duration_ms: Date.now() - notifyStartedAt,
          skipped: webhookResult.skipped,
          status: webhookResult.status ?? null,
          has_error: webhookResult.error != null,
        }),
      );
    }),
  );

  console.log(
    "[feed_validate] response_ready",
    JSON.stringify({
      duration_ms: Date.now() - requestStartedAt,
      process_feed_duration_ms: processFeedDurationMs,
      notify_queued: webhookQueued,
    }),
  );

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
    webhook_queued: webhookQueued,
    webhook_skipped: false,
    webhook_status: null,
    webhook_error: null,
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
