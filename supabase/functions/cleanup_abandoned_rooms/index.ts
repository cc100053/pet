// cleanup_abandoned_rooms
//
// Human-in-the-loop cleanup of Cloudflare R2 photos for abandoned rooms.
//
//   mode = "scan"  (default): find stale active rooms, count their R2 photos,
//                  and upsert them into room_cleanup_candidates as 'pending'.
//                  NEVER deletes anything.
//   mode = "purge": delete R2 photos ONLY for candidates whose review_status
//                  is 'approved' (set by you in Supabase Studio), then mark the
//                  room 'abandoned' and the candidate 'purged'.
//
// Design notes:
//   * Room photos live under the R2 key prefix `rooms/<room_id>/`
//     (see supabase/functions/notify_friend/feed_validate/index.ts).
//   * Reuses the existing aws4fetch + R2_* secrets (feed_validate/avatar_upload).
//   * Uses the service-role key to bypass RLS (mirrors hunger_tick_dispatch).
//   * Auth: caller must send `Authorization: Bearer <cleanup_rooms_secret>`
//     (Vault secret, read via get_cleanup_rooms_secret()).
//   * purge supports dry_run (defaults TRUE) to list without deleting.

import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { AwsClient } from "https://esm.sh/aws4fetch@1.0.18";
import { crypto as stdCrypto } from "https://deno.land/std@0.203.0/crypto/mod.ts";
import { encodeBase64 } from "https://deno.land/std@0.203.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const R2_ENDPOINT = Deno.env.get("R2_ENDPOINT") ?? "";
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID") ?? "";
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY") ?? "";
const R2_BUCKET = Deno.env.get("R2_BUCKET") ?? "";
const CLEANUP_ROOMS_SECRET = Deno.env.get("CLEANUP_ROOMS_SECRET") ?? "";

const DEFAULT_INACTIVE_DAYS = 30;
const DEFAULT_ROOM_LIMIT = 200;
const DEFAULT_DELETE_CONCURRENCY = 4;
const R2_DELETE_BATCH_SIZE = 1000; // S3 DeleteObjects hard cap.
const R2_LIST_PAGE_SIZE = 1000;

type CleanupBody = {
  mode?: "scan" | "purge";
  dry_run?: boolean;
  inactive_days?: number;
  room_limit?: number;
  delete_concurrency?: number;
  source?: string;
};

function log(event: string, fields: Record<string, unknown> = {}) {
  console.log(JSON.stringify({ event, ...fields }));
}

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function clampInt(input: unknown, fallback: number, min: number, max: number) {
  const n = typeof input === "number"
    ? input
    : (typeof input === "string" ? Number.parseInt(input, 10) : NaN);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, Math.trunc(n)));
}

function r2Client() {
  return new AwsClient({
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
    service: "s3",
    region: "auto",
  });
}

function r2Base() {
  return R2_ENDPOINT.replace(/\/$/, "");
}

function decodeXmlEntities(value: string) {
  return value
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, "&");
}

function escapeXml(value: string) {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

// List every object under a prefix (paginated), returning keys + total bytes.
async function listRoomObjects(
  client: AwsClient,
  prefix: string,
): Promise<{ keys: string[]; totalBytes: number }> {
  const keys: string[] = [];
  let totalBytes = 0;
  let token: string | undefined;

  do {
    const url = new URL(`${r2Base()}/${R2_BUCKET}`);
    url.searchParams.set("list-type", "2");
    url.searchParams.set("prefix", prefix);
    url.searchParams.set("max-keys", String(R2_LIST_PAGE_SIZE));
    if (token) url.searchParams.set("continuation-token", token);

    const res = await client.fetch(url.toString(), { method: "GET" });
    if (!res.ok) {
      const detail = await res.text().catch(() => "");
      throw new Error(`r2_list_failed:${res.status}:${detail.slice(0, 200)}`);
    }
    const xml = await res.text();

    for (const block of xml.matchAll(/<Contents>([\s\S]*?)<\/Contents>/g)) {
      const inner = block[1];
      const keyMatch = inner.match(/<Key>([\s\S]*?)<\/Key>/);
      const sizeMatch = inner.match(/<Size>(\d+)<\/Size>/);
      if (keyMatch) {
        keys.push(decodeXmlEntities(keyMatch[1]));
        if (sizeMatch) totalBytes += Number.parseInt(sizeMatch[1], 10) || 0;
      }
    }

    const truncated = /<IsTruncated>\s*true\s*<\/IsTruncated>/i.test(xml);
    const tokenMatch = xml.match(
      /<NextContinuationToken>([\s\S]*?)<\/NextContinuationToken>/,
    );
    token = truncated && tokenMatch
      ? decodeXmlEntities(tokenMatch[1])
      : undefined;
  } while (token);

  return { keys, totalBytes };
}

// Batch-delete up to 1000 keys via S3 DeleteObjects. Returns failed keys.
async function deleteR2Batch(
  client: AwsClient,
  keys: string[],
): Promise<{ failedKeys: string[] }> {
  const body = `<?xml version="1.0" encoding="UTF-8"?>` +
    `<Delete>${
      keys.map((k) => `<Object><Key>${escapeXml(k)}</Key></Object>`).join("")
    }<Quiet>true</Quiet></Delete>`;

  const bodyBytes = new TextEncoder().encode(body);
  const md5 = encodeBase64(
    new Uint8Array(await stdCrypto.subtle.digest("MD5", bodyBytes)),
  );

  const res = await client.fetch(`${r2Base()}/${R2_BUCKET}?delete`, {
    method: "POST",
    body: bodyBytes,
    headers: { "Content-Type": "application/xml", "Content-MD5": md5 },
  });

  const text = await res.text();
  if (!res.ok) {
    throw new Error(`r2_delete_failed:${res.status}:${text.slice(0, 200)}`);
  }

  const failedKeys: string[] = [];
  for (
    const m of text.matchAll(
      /<Error>[\s\S]*?<Key>([\s\S]*?)<\/Key>[\s\S]*?<\/Error>/g,
    )
  ) {
    failedKeys.push(decodeXmlEntities(m[1]));
  }
  return { failedKeys };
}

function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

async function runWithConcurrency<T, R>(
  items: readonly T[],
  concurrency: number,
  worker: (item: T) => Promise<R>,
): Promise<R[]> {
  if (items.length === 0) return [];
  const results: R[] = new Array(items.length);
  let cursor = 0;
  const runners = Array.from(
    { length: Math.min(concurrency, items.length) },
    () =>
      (async () => {
        while (true) {
          const index = cursor++;
          if (index >= items.length) return;
          results[index] = await worker(items[index]);
        }
      })(),
  );
  await Promise.all(runners);
  return results;
}

// deno-lint-ignore no-explicit-any
type AdminClient = ReturnType<typeof createClient<any, "public", any>>;

async function resolveSchedulerSecret(
  supabaseAdmin: { rpc: (fn: string) => PromiseLike<{ data: unknown; error: { message: string } | null }> },
): Promise<string | null> {
  const { data, error } = await supabaseAdmin.rpc("get_cleanup_rooms_secret");
  if (!error && typeof data === "string" && data.trim().length > 0) {
    return data.trim();
  }
  if (error) log("cleanup_secret_lookup_failed", { detail: error.message });
  const fallback = CLEANUP_ROOMS_SECRET.trim();
  return fallback.length > 0 ? fallback : null;
}

// --- SCAN: record stale rooms into the review queue (no deletion) -----------
async function runScan(
  supabaseAdmin: AdminClient,
  client: AwsClient,
  opts: { inactiveDays: number; roomLimit: number },
) {
  const cutoffIso = new Date(
    Date.now() - opts.inactiveDays * 24 * 60 * 60 * 1000,
  ).toISOString();

  log("cleanup_scan_started", { inactive_days: opts.inactiveDays, cutoff: cutoffIso });

  const { data: roomRows, error } = await supabaseAdmin
    .from("rooms")
    .select("id, last_activity_at")
    .eq("status", "active")
    .lt("last_activity_at", cutoffIso)
    .order("last_activity_at", { ascending: true })
    .limit(opts.roomLimit);

  if (error) {
    log("cleanup_rooms_query_failed", { detail: error.message });
    return jsonResponse(500, { error: "rooms_query_failed", detail: error.message });
  }

  const rooms = (roomRows ?? []) as Array<{ id: string; last_activity_at: string }>;
  let recorded = 0;
  let totalPhotos = 0;
  const errors: Array<{ room_id: string; error: string }> = [];

  for (const room of rooms) {
    try {
      const { keys, totalBytes } = await listRoomObjects(
        client,
        `rooms/${room.id}/`,
      );
      const { error: rpcError } = await supabaseAdmin.rpc(
        "record_room_cleanup_candidate",
        {
          p_room_id: room.id,
          p_photo_count: keys.length,
          p_photo_bytes: totalBytes,
          p_last_activity: room.last_activity_at,
        },
      );
      if (rpcError) {
        errors.push({ room_id: room.id, error: rpcError.message });
        continue;
      }
      recorded += 1;
      totalPhotos += keys.length;
    } catch (e) {
      errors.push({ room_id: room.id, error: String((e as Error)?.message ?? e) });
    }
  }

  const summary = {
    ok: true,
    mode: "scan",
    inactive_days: opts.inactiveDays,
    candidate_rooms: rooms.length,
    recorded,
    total_photos: totalPhotos,
    errors: errors.slice(0, 10),
  };
  log("cleanup_scan_finished", { ...summary, errors: errors.length });
  return jsonResponse(200, summary);
}

// --- PURGE: delete R2 photos for APPROVED candidates only -------------------
async function runPurge(
  supabaseAdmin: AdminClient,
  client: AwsClient,
  opts: { dryRun: boolean; deleteConcurrency: number },
) {
  log("cleanup_purge_started", { dry_run: opts.dryRun });

  const { data: rows, error } = await supabaseAdmin
    .from("room_cleanup_candidates")
    .select("room_id")
    .eq("review_status", "approved");

  if (error) {
    log("cleanup_candidates_query_failed", { detail: error.message });
    return jsonResponse(500, {
      error: "candidates_query_failed",
      detail: error.message,
    });
  }

  const approved = (rows ?? []) as Array<{ room_id: string }>;
  const results: Array<Record<string, unknown>> = [];

  for (const { room_id } of approved) {
    const result: Record<string, unknown> = {
      room_id,
      objects_found: 0,
      objects_deleted: 0,
      delete_failures: 0,
      purged: false,
    };
    try {
      const { keys } = await listRoomObjects(client, `rooms/${room_id}/`);
      result.objects_found = keys.length;

      if (opts.dryRun) {
        log("cleanup_purge_dry_run", { room_id, objects_found: keys.length });
        results.push(result);
        continue;
      }

      let deleted = 0;
      let failures = 0;
      if (keys.length > 0) {
        const batches = chunk(keys, R2_DELETE_BATCH_SIZE);
        const batchResults = await runWithConcurrency(
          batches,
          opts.deleteConcurrency,
          (batch) => deleteR2Batch(client, batch),
        );
        for (let i = 0; i < batches.length; i++) {
          const f = batchResults[i].failedKeys.length;
          deleted += batches[i].length - f;
          failures += f;
        }
      }
      result.objects_deleted = deleted;
      result.delete_failures = failures;

      if (failures === 0) {
        const nowIso = new Date().toISOString();
        await supabaseAdmin
          .from("rooms")
          .update({
            status: "abandoned",
            abandoned_at: nowIso,
            photos_purged_at: nowIso,
            photos_purged_count: deleted,
          })
          .eq("id", room_id)
          .eq("status", "active");
        const { error: candErr } = await supabaseAdmin
          .from("room_cleanup_candidates")
          .update({
            review_status: "purged",
            purged_at: nowIso,
            purged_count: deleted,
          })
          .eq("room_id", room_id);
        if (candErr) {
          result.error = `mark_purged_failed:${candErr.message}`;
        } else {
          result.purged = true;
        }
      } else {
        result.error = "partial_delete_failure"; // stays approved -> retried
      }
      log("cleanup_purge_room_done", { ...result });
    } catch (e) {
      result.error = String((e as Error)?.message ?? e);
      log("cleanup_purge_room_error", { room_id, error: result.error });
    }
    results.push(result);
  }

  const summary = {
    ok: true,
    mode: "purge",
    dry_run: opts.dryRun,
    approved_rooms: approved.length,
    rooms_purged: results.filter((r) => r.purged).length,
    objects_deleted: results.reduce((a, r) => a + (r.objects_deleted as number), 0),
    delete_failures: results.reduce((a, r) => a + (r.delete_failures as number), 0),
    results,
  };
  log("cleanup_purge_finished", { ...summary, results: undefined });
  return jsonResponse(200, summary);
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse(405, { error: "method_not_allowed" });

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return jsonResponse(500, {
      error: "server_config_error",
      detail: "missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY",
    });
  }
  if (!R2_ENDPOINT || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY || !R2_BUCKET) {
    return jsonResponse(500, {
      error: "server_config_error",
      detail: "missing R2_ENDPOINT / R2_ACCESS_KEY_ID / R2_SECRET_ACCESS_KEY / R2_BUCKET",
    });
  }

  const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const expectedSecret = await resolveSchedulerSecret(supabaseAdmin);
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!expectedSecret || authHeader !== `Bearer ${expectedSecret}`) {
    return jsonResponse(401, { error: "unauthorized" });
  }

  let body: CleanupBody = {};
  try {
    body = (await req.json()) as CleanupBody;
  } catch (_) {
    body = {};
  }

  const mode = body.mode === "purge" ? "purge" : "scan";
  const client = r2Client();

  if (mode === "scan") {
    return await runScan(supabaseAdmin, client, {
      inactiveDays: clampInt(body.inactive_days, DEFAULT_INACTIVE_DAYS, 1, 3650),
      roomLimit: clampInt(body.room_limit, DEFAULT_ROOM_LIMIT, 1, 1000),
    });
  }

  return await runPurge(supabaseAdmin, client, {
    dryRun: body.dry_run !== false, // default TRUE
    deleteConcurrency: clampInt(body.delete_concurrency, DEFAULT_DELETE_CONCURRENCY, 1, 16),
  });
});
