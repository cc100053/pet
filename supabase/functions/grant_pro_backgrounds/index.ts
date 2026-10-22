import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

import { corsHeaders, jsonResponse } from "../_shared/http.ts";

// Adds every Pro-only background (items.metadata.pro_only) to each room the
// caller is an active member of, after RevenueCat confirms the caller's Pro
// entitlement server-side. The client's own Pro flag is never trusted. The
// RevenueCat app user id is the Supabase user id (RevenueCatService.configure).
// Debug admins (public.is_debug_admin(), from JWT app_metadata) skip the
// RevenueCat check so the debug drawer's Pro toggle can exercise the grant.
// Grants persist after the subscription lapses, like a purchase.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const REVENUECAT_SECRET_KEY = Deno.env.get("REVENUECAT_SECRET_KEY") ?? "";
const PRO_ENTITLEMENT_ID = "petmonthly";

type RevenueCatEntitlement = { expires_date?: string | null };

async function hasActiveProEntitlement(userId: string): Promise<boolean> {
  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`,
    { headers: { Authorization: `Bearer ${REVENUECAT_SECRET_KEY}` } },
  );
  if (!response.ok) {
    throw new Error(`revenuecat_${response.status}`);
  }
  const body = await response.json();
  const entitlements: Record<string, RevenueCatEntitlement> =
    body?.subscriber?.entitlements ?? {};
  const now = Date.now();
  // Matches HomeView's case-insensitive check of the "Petmonthly" entitlement.
  return Object.entries(entitlements).some(([id, entitlement]) =>
    id.toLowerCase() === PRO_ENTITLEMENT_ID &&
    (entitlement.expires_date == null ||
      Date.parse(entitlement.expires_date) > now)
  );
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
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
  const userId = authData.user.id;

  const { data: isDebugAdmin } = await supabase.rpc("is_debug_admin");
  let isPro = isDebugAdmin === true;
  if (!isPro && !REVENUECAT_SECRET_KEY) {
    return jsonResponse(500, { error: "revenuecat_not_configured" });
  }
  try {
    isPro ||= await hasActiveProEntitlement(userId);
  } catch (error) {
    console.error("grant_pro_backgrounds revenuecat lookup failed", {
      userId,
      detail: String(error),
    });
    return jsonResponse(502, { error: "entitlement_lookup_failed" });
  }
  if (!isPro) {
    return jsonResponse(403, { error: "not_pro" });
  }

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const [{ data: rooms, error: roomsError }, { data: items, error: itemsError }] =
    await Promise.all([
      admin.from("room_members").select("room_id").eq("user_id", userId).eq(
        "is_active",
        true,
      ),
      admin.from("items").select("id").eq("metadata->>category", "background")
        .eq("metadata->>pro_only", "true"),
    ]);
  if (roomsError || itemsError) {
    console.error("grant_pro_backgrounds lookup failed", {
      userId,
      detail: (roomsError ?? itemsError)?.message,
    });
    return jsonResponse(500, { error: "lookup_failed" });
  }

  const rows = (rooms ?? []).flatMap((room) =>
    (items ?? []).map((item) => ({
      room_id: room.room_id,
      item_id: item.id,
      acquired_by: userId,
    }))
  );
  if (rows.length > 0) {
    const { error: insertError } = await admin.from("room_backgrounds").upsert(
      rows,
      { onConflict: "room_id,item_id", ignoreDuplicates: true },
    );
    if (insertError) {
      console.error("grant_pro_backgrounds insert failed", {
        userId,
        detail: insertError.message,
      });
      return jsonResponse(500, { error: "grant_failed" });
    }
  }

  return jsonResponse(200, { granted: rows.length });
});
