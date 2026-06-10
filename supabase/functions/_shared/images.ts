// Shared image + R2 helpers for Edge Functions.
//
// Previously `feed_validate` and `avatar_upload` each kept private copies of
// base64 decoding, MIME validation, and R2 upload logic. They are unified here
// so size limits, allowed types, and the storage client stay consistent and so
// that orphaned-object cleanup (delete-on-failure) is available everywhere.

import { AwsClient } from "https://esm.sh/aws4fetch@1.0.18";

export const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

export const ALLOWED_IMAGE_CONTENT_TYPES = new Set<string>([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
]);

export const EXTENSION_BY_CONTENT_TYPE: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/heic": "heic",
  "image/heif": "heif",
};

const R2_ENDPOINT = Deno.env.get("R2_ENDPOINT") ?? "";
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID") ?? "";
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY") ?? "";
const R2_BUCKET = Deno.env.get("R2_BUCKET") ?? "";
const R2_PUBLIC_BASE_URL = Deno.env.get("R2_PUBLIC_BASE_URL") ?? "";

export function r2PublicBaseUrl(): string {
  return R2_PUBLIC_BASE_URL.replace(/\/$/, "");
}

export function isR2Configured(): boolean {
  return Boolean(
    R2_ENDPOINT && R2_ACCESS_KEY_ID && R2_SECRET_ACCESS_KEY && R2_BUCKET &&
      R2_PUBLIC_BASE_URL,
  );
}

export function extractBase64Payload(
  value: string,
): { contentType: string | null; base64: string } {
  const match = value.match(/^data:([^;]+);base64,(.*)$/s);
  if (!match) {
    return { contentType: null, base64: value };
  }
  return { contentType: match[1] ?? null, base64: match[2] ?? "" };
}

export function decodeBase64(input: string): Uint8Array {
  const normalized = input.replace(/\s/g, "");
  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

export function estimateDecodedBytesFromBase64(base64: string): number {
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

export function buildDatePath(date: Date): string {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const day = String(date.getUTCDate()).padStart(2, "0");
  return `${year}/${month}/${day}`;
}

function r2Client(): AwsClient {
  return new AwsClient({
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
    service: "s3",
    region: "auto",
  });
}

function r2ObjectUrl(key: string): string {
  const endpoint = R2_ENDPOINT.replace(/\/$/, "");
  return `${endpoint}/${R2_BUCKET}/${key}`;
}

/// Returns the public URL for the uploaded object.
export async function uploadToR2(
  bytes: Uint8Array,
  contentType: string,
  key: string,
): Promise<string> {
  if (!isR2Configured()) {
    throw new Error("r2_not_configured");
  }

  const response = await r2Client().fetch(r2ObjectUrl(key), {
    method: "PUT",
    body: bytes,
    headers: {
      "Content-Type": contentType,
    },
  });

  if (!response.ok) {
    throw new Error(`r2_upload_failed:${response.status}`);
  }

  return `${r2PublicBaseUrl()}/${key}`;
}

/// Best-effort delete of a previously uploaded object. Never throws so callers
/// can use it in cleanup paths without masking the original error.
export async function deleteFromR2(key: string): Promise<boolean> {
  if (!isR2Configured() || !key) {
    return false;
  }
  try {
    const response = await r2Client().fetch(r2ObjectUrl(key), {
      method: "DELETE",
    });
    // R2 returns 204 on delete and 404 if the object was already gone; both are
    // acceptable terminal states for cleanup.
    return response.ok || response.status === 404;
  } catch (error) {
    console.error("[r2] delete_failed", String((error as Error)?.message ?? error));
    return false;
  }
}

/// Extracts the object key from a public R2 URL, or null if the URL is not an
/// object under the configured public base (e.g. a `preset:` avatar).
export function r2KeyFromPublicUrl(url: string | null | undefined): string | null {
  if (!url) {
    return null;
  }
  const base = r2PublicBaseUrl();
  if (!base || !url.startsWith(`${base}/`)) {
    return null;
  }
  const key = url.slice(base.length + 1);
  return key.length > 0 ? key : null;
}
