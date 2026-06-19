#!/usr/bin/env python3
"""Create an App Store version and sync version-localization .strings files.

This is a narrow fallback for ASC CLI wrapper failures such as Apple's generic
`-50` response from `asc versions create` or `asc localizations upload`.
It uses the public App Store Connect API directly with the same ASC_* key envs.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
except ImportError as exc:  # pragma: no cover - environment guard.
    raise SystemExit(
        "Missing dependency: cryptography. In Codex, run with the bundled "
        "Python executable from load_workspace_dependencies, typically "
        "/Users/fatboy/.cache/codex-runtimes/codex-primary-runtime/"
        "dependencies/python/bin/python3."
    ) from exc


ASC_API_BASE = "https://api.appstoreconnect.apple.com/v1"
MANAGED_FIELDS = {
    "description",
    "keywords",
    "marketingUrl",
    "promotionalText",
    "supportUrl",
    "whatsNew",
}
STRING_ENTRY_RE = re.compile(
    r'"(?P<key>[^"]+)"\s*=\s*"(?P<value>(?:[^"\\]|\\.)*)";',
    re.DOTALL,
)


class AppStoreConnectError(RuntimeError):
    pass


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise SystemExit(f"Missing required env var: {name}")
    return value


def _load_private_key() -> Any:
    private_key = os.environ.get("ASC_PRIVATE_KEY")
    private_key_b64 = os.environ.get("ASC_PRIVATE_KEY_B64")
    private_key_path = os.environ.get("ASC_PRIVATE_KEY_PATH")

    if private_key:
        data = private_key.encode("utf-8")
    elif private_key_b64:
        data = base64.b64decode(private_key_b64)
    elif private_key_path:
        data = Path(private_key_path).read_bytes()
    else:
        raise SystemExit(
            "Missing ASC private key. Set ASC_PRIVATE_KEY_PATH, "
            "ASC_PRIVATE_KEY, or ASC_PRIVATE_KEY_B64."
        )

    return serialization.load_pem_private_key(data, password=None)


def make_token() -> str:
    key_id = _env("ASC_KEY_ID")
    issuer_id = _env("ASC_ISSUER_ID")
    private_key = _load_private_key()
    now = int(time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + 20 * 60,
        "aud": "appstoreconnect-v1",
    }
    signing_input = (
        f"{_b64url(json.dumps(header, separators=(',', ':')).encode())}."
        f"{_b64url(json.dumps(payload, separators=(',', ':')).encode())}"
    ).encode("ascii")
    der_sig = private_key.sign(signing_input, ec.ECDSA(hashes.SHA256()))
    r_value, s_value = decode_dss_signature(der_sig)
    signature = r_value.to_bytes(32, "big") + s_value.to_bytes(32, "big")
    return signing_input.decode("ascii") + "." + _b64url(signature)


class AscClient:
    def __init__(self, token: str) -> None:
        self.token = token

    def request(
        self,
        method: str,
        path: str,
        body: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        data = None
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/json",
        }
        if body is not None:
            data = json.dumps(body, ensure_ascii=False).encode("utf-8")
            headers["Content-Type"] = "application/json"

        request = urllib.request.Request(
            ASC_API_BASE + path,
            data=data,
            headers=headers,
            method=method,
        )
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                raw = response.read().decode("utf-8")
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as exc:
            raw = exc.read().decode("utf-8", errors="replace")
            raise AppStoreConnectError(
                f"ASC API {method} {path} failed with HTTP {exc.code}: {raw}"
            ) from exc


def unescape_strings_value(value: str) -> str:
    # Preserve UTF-8 text. Only decode the escapes used by checked-in .strings.
    return (
        value.replace(r"\n", "\n")
        .replace(r"\"", '"')
        .replace(r"\\", "\\")
    )


def read_strings_file(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    entries: dict[str, str] = {}
    for match in STRING_ENTRY_RE.finditer(text):
        key = match.group("key")
        if key in MANAGED_FIELDS:
            entries[key] = unescape_strings_value(match.group("value"))
    missing = {"description", "supportUrl", "marketingUrl", "promotionalText", "whatsNew"} - set(entries)
    if missing:
        raise SystemExit(f"{path} is missing required field(s): {', '.join(sorted(missing))}")
    return entries


def load_localizations(directory: Path) -> dict[str, dict[str, str]]:
    if not directory.is_dir():
        raise SystemExit(f"Localization directory not found: {directory}")
    localizations: dict[str, dict[str, str]] = {}
    for path in sorted(directory.glob("*.strings")):
        locale = path.stem
        localizations[locale] = read_strings_file(path)
    if not localizations:
        raise SystemExit(f"No .strings files found in {directory}")
    return localizations


def find_version(client: AscClient, app_id: str, version: str, platform: str) -> dict[str, Any] | None:
    query = urllib.parse.urlencode({"limit": "200"})
    payload = client.request("GET", f"/apps/{app_id}/appStoreVersions?{query}")
    for row in payload.get("data", []):
        attrs = row.get("attributes", {})
        if attrs.get("versionString") == version and attrs.get("platform") == platform:
            return row
    return None


def create_version(client: AscClient, app_id: str, version: str, platform: str) -> dict[str, Any]:
    body = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {
                "platform": platform,
                "versionString": version,
            },
            "relationships": {
                "app": {
                    "data": {
                        "type": "apps",
                        "id": app_id,
                    },
                },
            },
        },
    }
    return client.request("POST", "/appStoreVersions", body)["data"]


def list_version_localizations(client: AscClient, version_id: str) -> dict[str, dict[str, Any]]:
    payload = client.request(
        "GET",
        f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200",
    )
    by_locale: dict[str, dict[str, Any]] = {}
    for row in payload.get("data", []):
        by_locale[row["attributes"]["locale"]] = row
    return by_locale


def create_localization(
    client: AscClient,
    version_id: str,
    locale: str,
    attributes: dict[str, str],
) -> dict[str, Any]:
    body = {
        "data": {
            "type": "appStoreVersionLocalizations",
            "attributes": {
                "locale": locale,
                **attributes,
            },
            "relationships": {
                "appStoreVersion": {
                    "data": {
                        "type": "appStoreVersions",
                        "id": version_id,
                    },
                },
            },
        },
    }
    return client.request("POST", "/appStoreVersionLocalizations", body)["data"]


def patch_localization(
    client: AscClient,
    localization_id: str,
    attributes: dict[str, str],
) -> dict[str, Any]:
    body = {
        "data": {
            "type": "appStoreVersionLocalizations",
            "id": localization_id,
            "attributes": attributes,
        },
    }
    return client.request(
        "PATCH",
        f"/appStoreVersionLocalizations/{localization_id}",
        body,
    )["data"]


def ensure_eula(localizations: dict[str, dict[str, str]]) -> None:
    failures = [
        locale
        for locale, fields in localizations.items()
        if "itunes/dev/stdeula" not in fields.get("description", "")
    ]
    if failures:
        raise SystemExit(
            "Refusing to sync descriptions without direct Apple EULA URL for: "
            + ", ".join(sorted(failures))
        )


def sync(args: argparse.Namespace) -> int:
    localizations = load_localizations(args.localizations_dir)
    ensure_eula(localizations)
    client = AscClient(make_token())

    version = find_version(client, args.app, args.version, args.platform)
    if version is None:
        if args.dry_run:
            print(f"DRY RUN: would create {args.platform} version {args.version}")
            version_id = "<new-version-id>"
            existing_localizations: dict[str, dict[str, Any]] = {}
        else:
            version = create_version(client, args.app, args.version, args.platform)
            version_id = version["id"]
            print(f"Created {args.platform} version {args.version}: {version_id}")
            existing_localizations = list_version_localizations(client, version_id)
    else:
        version_id = version["id"]
        state = version["attributes"].get("appStoreState")
        print(f"Found {args.platform} version {args.version}: {version_id} ({state})")
        existing_localizations = list_version_localizations(client, version_id)

    for locale, fields in sorted(localizations.items()):
        existing = existing_localizations.get(locale)
        if args.dry_run:
            action = "patch" if existing else "create"
            print(
                f"DRY RUN: would {action} {locale} "
                f"({len(fields['promotionalText'])} promo chars, "
                f"{len(fields['whatsNew'])} whatsNew chars)"
            )
            continue

        if existing:
            row = patch_localization(client, existing["id"], fields)
            action = "Patched"
        else:
            row = create_localization(client, version_id, locale, fields)
            action = "Created"
        attrs = row["attributes"]
        eula_ok = "itunes/dev/stdeula" in attrs.get("description", "")
        whats_new = attrs.get("whatsNew") or ""
        print(
            f"{action} {locale}: id={row['id']} "
            f"whatsNew={whats_new.splitlines()[0] if whats_new else 'MISSING'} "
            f"eula={eula_ok}"
        )

    if args.dry_run:
        return 0

    verified = list_version_localizations(client, version_id)
    missing = set(localizations) - set(verified)
    if missing:
        raise SystemExit(f"Missing ASC localizations after sync: {', '.join(sorted(missing))}")
    for locale in sorted(localizations):
        attrs = verified[locale]["attributes"]
        if not attrs.get("promotionalText") or not attrs.get("whatsNew"):
            raise SystemExit(f"ASC localization {locale} is missing promotionalText or whatsNew")
        if "itunes/dev/stdeula" not in attrs.get("description", ""):
            raise SystemExit(f"ASC localization {locale} is missing direct EULA URL")
    print(f"Verified {len(localizations)} localizations for {args.version} ({version_id})")
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, help="App Store Connect app ID")
    parser.add_argument("--version", required=True, help="Public app version, e.g. 2.2.1")
    parser.add_argument("--platform", default="IOS", help="ASC platform, default IOS")
    parser.add_argument(
        "--localizations-dir",
        type=Path,
        default=Path(".asc/version-localizations"),
        help="Directory containing ASC version-localization .strings files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Inspect ASC state and print intended changes without mutating ASC",
    )
    return parser.parse_args(argv)


if __name__ == "__main__":
    try:
        raise SystemExit(sync(parse_args(sys.argv[1:])))
    except AppStoreConnectError as exc:
        raise SystemExit(str(exc)) from exc
