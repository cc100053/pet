import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const NOTIFY_WEBHOOK_SECRET = Deno.env.get("NOTIFY_WEBHOOK_SECRET") ?? "";
const HUNGER_TICK_SECRET = Deno.env.get("HUNGER_TICK_SECRET") ??
  NOTIFY_WEBHOOK_SECRET;

const DEFAULT_DUE_LIMIT = 200;
const DEFAULT_TICK_CONCURRENCY = 8;
const DEFAULT_DISPATCH_CONCURRENCY = 5;

type DuePetRow = {
  pet_id: string;
  room_id: string;
};

type PetStateRow = {
  pet_id: string;
  hunger_alert_50_message_id: string | null;
  hunger_alert_30_message_id: string | null;
  hunger_alert_10_message_id: string | null;
};

type AlertCandidate = {
  roomId: string;
  messageId: string;
  level: 50 | 30 | 10;
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

function clampInt(
  input: unknown,
  fallback: number,
  min: number,
  max: number,
): number {
  if (typeof input === "number" && Number.isFinite(input)) {
    return Math.min(max, Math.max(min, Math.trunc(input)));
  }
  if (typeof input === "string") {
    const parsed = Number.parseInt(input, 10);
    if (Number.isFinite(parsed)) {
      return Math.min(max, Math.max(min, Math.trunc(parsed)));
    }
  }
  return fallback;
}

async function runWithConcurrency<T, R>(
  items: readonly T[],
  concurrency: number,
  worker: (item: T) => Promise<R>,
): Promise<R[]> {
  if (items.length === 0) {
    return [];
  }

  const results: R[] = new Array(items.length);
  let cursor = 0;

  const runners = Array.from({ length: Math.min(concurrency, items.length) }, () =>
    (async () => {
      while (true) {
        const index = cursor;
        cursor += 1;
        if (index >= items.length) {
          return;
        }
        results[index] = await worker(items[index]);
      }
    })());

  await Promise.all(runners);
  return results;
}

async function dispatchHungerAlert(
  alert: AlertCandidate,
): Promise<{ ok: boolean; status?: number; error?: string }> {
  const notifyUrl = `${SUPABASE_URL.replace(/\/$/, "")}/functions/v1/notify_friend`;

  try {
    const response = await fetch(notifyUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        "X-Notify-Webhook-Secret": NOTIFY_WEBHOOK_SECRET,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        type: "hunger_alert",
        room_id: alert.roomId,
        message_id: alert.messageId,
        alert_level: alert.level,
      }),
    });

    if (!response.ok) {
      const detail = await response.text().catch(() => "");
      return {
        ok: false,
        status: response.status,
        error: detail ? `${response.status}:${detail}` : String(response.status),
      };
    }

    return { ok: true, status: response.status };
  } catch (error) {
    return { ok: false, error: String(error) };
  }
}

async function resolveSchedulerSecret(
  supabaseAdmin: ReturnType<typeof createClient>,
): Promise<string | null> {
  const { data, error } = await supabaseAdmin.rpc("get_hunger_tick_secret");

  if (error) {
    console.warn(JSON.stringify({
      event: "hunger_tick_dispatch_secret_lookup_failed",
      details: error.message,
    }));
    const fallbackEnvSecret = HUNGER_TICK_SECRET.trim();
    return fallbackEnvSecret.length > 0 ? fallbackEnvSecret : null;
  }

  const vaultSecret = typeof data === "string" ? data.trim() : "";
  if (vaultSecret.length > 0) {
    return vaultSecret;
  }

  const fallbackEnvSecret = HUNGER_TICK_SECRET.trim();
  return fallbackEnvSecret.length > 0 ? fallbackEnvSecret : null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  if (
    !SUPABASE_URL ||
    !SUPABASE_ANON_KEY ||
    !SUPABASE_SERVICE_ROLE_KEY ||
    !NOTIFY_WEBHOOK_SECRET
  ) {
    return jsonResponse(500, {
      error: "server_config_error",
      details:
        "missing SUPABASE_URL/SUPABASE_ANON_KEY/SUPABASE_SERVICE_ROLE_KEY/NOTIFY_WEBHOOK_SECRET",
    });
  }

  let body: Record<string, unknown> = {};
  try {
    body = (await req.json()) as Record<string, unknown>;
  } catch (_) {
    body = {};
  }

  const dueLimit = clampInt(body.due_limit, DEFAULT_DUE_LIMIT, 1, 1000);
  const tickConcurrency = clampInt(
    body.tick_concurrency,
    DEFAULT_TICK_CONCURRENCY,
    1,
    25,
  );
  const dispatchConcurrency = clampInt(
    body.dispatch_concurrency,
    DEFAULT_DISPATCH_CONCURRENCY,
    1,
    25,
  );

  const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const expectedSchedulerSecret = await resolveSchedulerSecret(supabaseAdmin);
  const authHeader = req.headers.get("Authorization") ?? "";
  if (
    !expectedSchedulerSecret ||
    authHeader !== `Bearer ${expectedSchedulerSecret}`
  ) {
    return jsonResponse(401, { error: "unauthorized" });
  }

  const nowIso = new Date().toISOString();
  const { data: dueRows, error: dueRowsError } = await supabaseAdmin
    .from("pet_hunger_tick_schedule")
    .select("pet_id, room_id")
    .lte("next_check_at", nowIso)
    .order("next_check_at", { ascending: true })
    .limit(dueLimit);

  if (dueRowsError) {
    return jsonResponse(500, {
      error: "hunger_schedule_query_failed",
      details: dueRowsError.message,
    });
  }

  const duePets = (dueRows ?? [])
    .map((row) => ({
      pet_id: (row as Record<string, unknown>).pet_id as string,
      room_id: (row as Record<string, unknown>).room_id as string,
    }))
    .filter((row): row is DuePetRow => !!row.pet_id && !!row.room_id);

  if (duePets.length === 0) {
    return jsonResponse(200, {
      ok: true,
      scanned_pets: 0,
      ticked_pets: 0,
      tick_failures: 0,
      alert_candidates: 0,
      dispatch_attempts: 0,
      dispatch_successes: 0,
      dispatch_failures: 0,
    });
  }

  const tickResults = await runWithConcurrency(
    duePets,
    tickConcurrency,
    async (pet) => {
      const { error } = await supabaseAdmin.rpc("tick_pet_state_as_system", {
        p_pet_id: pet.pet_id,
        p_now: nowIso,
      });

      return {
        petId: pet.pet_id,
        roomId: pet.room_id,
        ok: !error,
        error: error?.message,
      };
    },
  );

  const tickedPetIds = tickResults
    .filter((result) => result.ok)
    .map((result) => result.petId);
  const roomIdByPetId = new Map<string, string>();
  for (const result of tickResults) {
    if (result.ok) {
      roomIdByPetId.set(result.petId, result.roomId);
    }
  }

  if (tickedPetIds.length === 0) {
    return jsonResponse(200, {
      ok: true,
      scanned_pets: duePets.length,
      ticked_pets: 0,
      tick_failures: tickResults.length,
      alert_candidates: 0,
      dispatch_attempts: 0,
      dispatch_successes: 0,
      dispatch_failures: 0,
      tick_errors: tickResults
        .filter((result) => !result.ok)
        .slice(0, 10)
        .map((result) => ({
          pet_id: result.petId,
          room_id: result.roomId,
          error: result.error ?? "unknown",
        })),
    });
  }

  const { data: petStateRows, error: stateError } = await supabaseAdmin
    .from("pet_state")
    .select(
      "pet_id, hunger_alert_50_message_id, hunger_alert_30_message_id, hunger_alert_10_message_id",
    )
    .in("pet_id", tickedPetIds);

  if (stateError) {
    return jsonResponse(500, {
      error: "pet_state_query_failed",
      details: stateError.message,
    });
  }

  const alertCandidates: AlertCandidate[] = [];
  const seenMessageIds = new Set<string>();

  for (const row of (petStateRows ?? []) as PetStateRow[]) {
    const roomId = roomIdByPetId.get(row.pet_id);
    if (!roomId) {
      continue;
    }

    const mappings: Array<{ messageId: string | null; level: 50 | 30 | 10 }> = [
      { messageId: row.hunger_alert_50_message_id, level: 50 },
      { messageId: row.hunger_alert_30_message_id, level: 30 },
      { messageId: row.hunger_alert_10_message_id, level: 10 },
    ];

    for (const mapping of mappings) {
      const messageId = (mapping.messageId ?? "").trim();
      if (!messageId || seenMessageIds.has(messageId)) {
        continue;
      }
      seenMessageIds.add(messageId);
      alertCandidates.push({
        roomId,
        messageId,
        level: mapping.level,
      });
    }
  }

  let pendingAlerts = alertCandidates;
  if (alertCandidates.length > 0) {
    const { data: sentRows, error: sentRowsError } = await supabaseAdmin
      .from("notification_delivery_logs")
      .select("message_id")
      .eq("payload_type", "hunger_alert")
      .eq("success", true)
      .in(
        "message_id",
        alertCandidates.map((candidate) => candidate.messageId),
      );

    if (sentRowsError) {
      return jsonResponse(500, {
        error: "delivery_log_query_failed",
        details: sentRowsError.message,
      });
    }

    const sentSet = new Set(
      (sentRows ?? [])
        .map((row) => (row as Record<string, unknown>).message_id as string | null)
        .filter((id): id is string => !!id),
    );

    pendingAlerts = alertCandidates.filter((candidate) =>
      !sentSet.has(candidate.messageId)
    );
  }

  const dispatchResults = await runWithConcurrency(
    pendingAlerts,
    dispatchConcurrency,
    dispatchHungerAlert,
  );

  const dispatchFailures = dispatchResults
    .filter((result) => !result.ok)
    .slice(0, 10)
    .map((result) => ({
      status: result.status ?? null,
      error: result.error ?? "unknown",
    }));

  const tickErrors = tickResults
    .filter((result) => !result.ok)
    .slice(0, 10)
    .map((result) => ({
      pet_id: result.petId,
      room_id: result.roomId,
      error: result.error ?? "unknown",
    }));

  return jsonResponse(200, {
    ok: true,
    scanned_pets: duePets.length,
    ticked_pets: tickedPetIds.length,
    tick_failures: tickResults.length - tickedPetIds.length,
    alert_candidates: alertCandidates.length,
    dispatch_attempts: pendingAlerts.length,
    dispatch_successes: dispatchResults.filter((result) => result.ok).length,
    dispatch_failures: dispatchResults.filter((result) => !result.ok).length,
    tick_errors: tickErrors,
    dispatch_errors: dispatchFailures,
  });
});
