# Lessons

## 2026-02-23
- When tightening image-size policy, always profile send latency on real upload path (pick -> compress -> invoke -> reward), not just final byte size.
- Prefer precomputing expensive transforms (compression) before user-confirmed send so reward/UI feedback stays responsive.
- Even when backend timing is unchanged, add explicit pending-state feedback near the affected HUD metric to avoid perceived freezes.
- iOS AppTrackingTransparency (ATT) prompt timing must be lifecycle-gated (`resumed`) instead of delay-based; fixed startup delays can still suppress the system prompt on newer iOS builds.
- Any SDK path that can participate in tracking (analytics/ad SDK init, ad preload, ad request) must be blocked until ATT authorization is resolved, not just the explicit ATT API call site.

## 2026-02-25
- If the user explicitly says not to modify a governance file (for example `AGENTS.md`), treat it as a hard constraint for the rest of the task and implement runtime/code fixes without further edits to that file.
- When MCP login/handshake paths are flaky, retry with project MCP tools directly (`mcp__supabase__*`) and verify real runtime behavior end-to-end (HTTP response + logs), not just job creation.

## 2026-02-28
- When normalizing tablet widths for breakpoint/scale selection, do not collapse to phone-regular width by default; use a tablet content width that preserves the expanded tier unless there is explicit evidence oversized rendering persists.
- Treat real-device iPad validation feedback as authoritative and adjust adaptive constants to match actual layout behavior, then lock with tests.
- Do not rely on viewport width alone for iPad classification; in iPhone-compat mode on iPad, use physical display traits to prevent accidental compact-tier selection.
- Keep scaling architecture consistent across related screens: avoid mixing globally scaled and locally unscaled card dimensions (or vice versa), because users immediately notice mismatched sizing between Room Selection and Pet Home gallery cards.
- When users report limited movement area, verify layout occupancy first: visual transforms (`Transform.scale`) do not free interaction space; adjust parent layout constraints (aspect ratio, gaps, padding) to increase real movement bounds.
