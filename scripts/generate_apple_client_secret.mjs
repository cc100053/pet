#!/usr/bin/env node
import fs from "node:fs";
import crypto from "node:crypto";

const args = process.argv.slice(2);
const options = {};

for (let i = 0; i < args.length; i += 1) {
  const arg = args[i];
  if (arg.startsWith("--")) {
    const key = arg.slice(2);
    const value = args[i + 1];
    if (!value || value.startsWith("--")) {
      throw new Error(`Missing value for ${arg}`);
    }
    options[key] = value;
    i += 1;
  }
}

const teamId = options["team-id"];
const clientId = options["client-id"];
const keyId = options["key-id"];
const p8Path = options["p8"];
const expiryDays = options["expiry-days"]
  ? Number(options["expiry-days"])
  : 180;

if (!teamId || !clientId || !keyId || !p8Path) {
  console.error("Usage:");
  console.error(
    "  node scripts/generate_apple_client_secret.mjs " +
      "--team-id <TEAM_ID> --client-id <CLIENT_ID> " +
      "--key-id <KEY_ID> --p8 <PATH_TO_P8> [--expiry-days 180]",
  );
  process.exit(1);
}

if (!Number.isFinite(expiryDays) || expiryDays <= 0) {
  throw new Error("expiry-days must be a positive number");
}

const maxDays = 180;
if (expiryDays > maxDays) {
  throw new Error(`expiry-days must be <= ${maxDays}`);
}

const privateKey = fs.readFileSync(p8Path, "utf8");
const now = Math.floor(Date.now() / 1000);
const exp = now + Math.floor(expiryDays * 24 * 60 * 60);

const header = {
  alg: "ES256",
  kid: keyId,
  typ: "JWT",
};

const payload = {
  iss: teamId,
  iat: now,
  exp,
  aud: "https://appleid.apple.com",
  sub: clientId,
};

const base64Url = (input) => {
  const buffer = Buffer.isBuffer(input) ? input : Buffer.from(input);
  return buffer
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
};

const encodedHeader = base64Url(JSON.stringify(header));
const encodedPayload = base64Url(JSON.stringify(payload));
const signingInput = `${encodedHeader}.${encodedPayload}`;

const signer = crypto.createSign("SHA256");
signer.update(signingInput);
signer.end();
const signature = signer.sign({ key: privateKey, dsaEncoding: "ieee-p1363" });

const token = `${signingInput}.${base64Url(signature)}`;
console.log(token);
