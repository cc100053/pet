// FCM HTTP v1 auth helpers.
// ponytail: notify_friend still carries its own copy of this; switch it over
// the next time that function is redeployed for another reason.
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.9.1/mod.ts";

export type ServiceAccount = {
  project_id: string;
  private_key: string;
  client_email: string;
};

/// Reads GOOGLE_SERVICE_ACCOUNT (JSON) or the split FCM_* env vars, the same
/// secrets notify_friend uses. Returns null when neither is configured.
export function loadServiceAccount(): ServiceAccount | null {
  const json = Deno.env.get("GOOGLE_SERVICE_ACCOUNT") ?? "";
  if (json) {
    const parsed = JSON.parse(json) as ServiceAccount;
    parsed.private_key = parsed.private_key.replace(/\\n/g, "\n");
    return parsed;
  }
  const projectId = Deno.env.get("FCM_PROJECT_ID") ?? "";
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL") ?? "";
  const privateKey = (Deno.env.get("FCM_PRIVATE_KEY") ?? "").replace(
    /\\n/g,
    "\n",
  );
  if (!projectId || !clientEmail || !privateKey) return null;
  return {
    project_id: projectId,
    client_email: clientEmail,
    private_key: privateKey,
  };
}

function pemToArrayBuffer(pem: string) {
  const cleaned = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

export async function getFcmAccessToken(
  serviceAccount: ServiceAccount,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: serviceAccount.client_email,
      sub: serviceAccount.client_email,
      aud: "https://oauth2.googleapis.com/token",
      iat: getNumericDate(0),
      exp: getNumericDate(3600),
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    },
    key,
  );
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!response.ok) {
    throw new Error(
      `fcm_token_failed ${response.status} ${await response.text()}`,
    );
  }
  return (await response.json()).access_token;
}
