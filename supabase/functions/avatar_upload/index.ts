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
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

const ALLOWED_IMAGE_CONTENT_TYPES = new Set<string>([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
]);

const EXTENSION_BY_CONTENT_TYPE: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/heic": "heic",
  "image/heif": "heif",
};

type AvatarUploadRequest = {
  image_base64?: string;
  image_content_type?: string;
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

function decodeBase64(input: string): Uint8Array {
  const normalized = input.replace(/\s/g, "");
  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function extractBase64Payload(
  value: string,
): { contentType: string | null; base64: string } {
  const match = value.match(/^data:([^;]+);base64,(.*)$/);
  if (!match) {
    return { contentType: null, base64: value };
  }
  return { contentType: match[1] ?? null, base64: match[2] ?? "" };
}

function buildDatePath(date: Date) {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const day = String(date.getUTCDate()).padStart(2, "0");
  return `${year}/${month}/${day}`;
}

function estimateDecodedBytesFromBase64(base64: string): number {
  const sanitized = base64.replace(/\s/g, "");
  if (!sanitized) {
    return 0;
  }
  const padding = sanitized.endsWith("==")
    ? 2
    : (sanitized.endsWith("=") ? 1 : 0);
  const estimated = Math.floor((sanitized.length * 3) / 4) - padding;
  return Math.max(estimated, 0);
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
      return jsonResponse(500, {
        error: "profile_update_failed",
        detail: updateError.message,
      });
    }

    return jsonResponse(200, { avatar_url: avatarUrl });
  } catch (error) {
    return jsonResponse(500, {
      error: "avatar_upload_unhandled",
      detail: String(error?.message ?? error),
    });
  }
});
