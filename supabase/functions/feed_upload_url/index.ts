import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

import { corsHeaders, jsonResponse } from "../_shared/http.ts";
import {
  ALLOWED_IMAGE_CONTENT_TYPES,
  buildDatePath,
  EXTENSION_BY_CONTENT_TYPE,
  isR2Configured,
  presignR2PutUrl,
  r2PublicBaseUrl,
} from "../_shared/images.ts";

// Issues a short-lived presigned R2 PUT URL so the client can upload a feed
// image directly to storage instead of streaming base64 through `feed_validate`.
// The key is always scoped to `rooms/<room_id>/...` and membership is verified,
// so `feed_validate` can later confirm the returned `public_url` belongs to the
// room. Additive + opt-in: nothing calls this until a new client enables it.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const UPLOAD_URL_TTL_SECONDS = 300;

type UploadUrlRequest = {
  room_id?: string;
  roomId?: string;
  image_content_type?: string;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return jsonResponse(500, { error: "supabase_env_missing" });
  }
  if (!isR2Configured()) {
    return jsonResponse(500, { error: "r2_not_configured" });
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

  let payload: UploadUrlRequest;
  try {
    payload = await req.json();
  } catch (_error) {
    return jsonResponse(400, { error: "invalid_json" });
  }

  const roomId = payload.room_id ?? payload.roomId;
  if (!roomId) {
    return jsonResponse(400, { error: "missing_room_id" });
  }

  const contentType = payload.image_content_type ?? "";
  if (!ALLOWED_IMAGE_CONTENT_TYPES.has(contentType)) {
    return jsonResponse(400, { error: "invalid_image_content_type" });
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

  const extension = EXTENSION_BY_CONTENT_TYPE[contentType] ?? "bin";
  const key = `rooms/${roomId}/${
    buildDatePath(new Date())
  }/${crypto.randomUUID()}.${extension}`;

  let uploadUrl: string;
  try {
    uploadUrl = await presignR2PutUrl(key, UPLOAD_URL_TTL_SECONDS);
  } catch (error) {
    return jsonResponse(500, {
      error: "presign_failed",
      detail: String(error?.message ?? error),
    });
  }

  return jsonResponse(200, {
    ok: true,
    upload_url: uploadUrl,
    public_url: `${r2PublicBaseUrl()}/${key}`,
    key,
    content_type: contentType,
    expires_in: UPLOAD_URL_TTL_SECONDS,
  });
});
