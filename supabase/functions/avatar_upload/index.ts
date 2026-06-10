import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.1";

import { corsHeaders, jsonResponse } from "../_shared/http.ts";
import {
  ALLOWED_IMAGE_CONTENT_TYPES,
  buildDatePath,
  decodeBase64,
  deleteFromR2,
  estimateDecodedBytesFromBase64,
  EXTENSION_BY_CONTENT_TYPE,
  extractBase64Payload,
  MAX_IMAGE_BYTES,
  r2KeyFromPublicUrl,
  uploadToR2,
} from "../_shared/images.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

type AvatarUploadRequest = {
  image_base64?: string;
  image_content_type?: string;
};

serve(async (req) => {
  try {
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

    let payload: AvatarUploadRequest;
    try {
      payload = await req.json();
    } catch (_error) {
      return jsonResponse(400, { error: "invalid_json" });
    }

    const raw = payload.image_base64 ?? "";
    if (!raw) {
      return jsonResponse(400, { error: "missing_image" });
    }

    const extracted = extractBase64Payload(raw);
    const resolvedContentType = payload.image_content_type ??
      extracted.contentType ?? "image/webp";
    if (!ALLOWED_IMAGE_CONTENT_TYPES.has(resolvedContentType)) {
      return jsonResponse(400, { error: "invalid_image_content_type" });
    }
    const estimatedBytes = estimateDecodedBytesFromBase64(extracted.base64);
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
    const key = `avatars/${authData.user.id}/${
      buildDatePath(new Date())
    }/${crypto.randomUUID()}.${extension}`;

    let imageBytes: Uint8Array;
    try {
      imageBytes = decodeBase64(extracted.base64);
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

    // Capture the previous avatar before overwriting it so the now-orphaned R2
    // object can be removed after the profile points at the new one.
    const { data: existingProfile } = await supabase
      .from("profiles")
      .select("avatar_url")
      .eq("user_id", authData.user.id)
      .maybeSingle();
    const previousAvatarUrl = existingProfile?.avatar_url as string | null ??
      null;

    let avatarUrl: string;
    try {
      avatarUrl = await uploadToR2(
        imageBytes,
        resolvedContentType,
        key,
      );
    } catch (error) {
      return jsonResponse(500, {
        error: "avatar_upload_failed",
        detail: String(error?.message ?? error),
      });
    }

    const { error: updateError } = await supabase
      .from("profiles")
      .update({ avatar_url: avatarUrl })
      .eq("user_id", authData.user.id);
    if (updateError) {
      // The new object is now orphaned because the profile still references the
      // old avatar; remove it so failed updates do not leak storage.
      await deleteFromR2(key);
      return jsonResponse(500, {
        error: "profile_update_failed",
        detail: updateError.message,
      });
    }

    // Profile now points at the new avatar; the old R2 object (if any) is safe
    // to delete. Best-effort: a delete failure must not fail the request.
    const previousKey = r2KeyFromPublicUrl(previousAvatarUrl);
    if (previousKey && previousKey !== key) {
      await deleteFromR2(previousKey);
    }

    return jsonResponse(200, { avatar_url: avatarUrl });
  } catch (error) {
    return jsonResponse(500, {
      error: "avatar_upload_unhandled",
      detail: String(error?.message ?? error),
    });
  }
});
