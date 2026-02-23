# Lessons

## 2026-02-23
- When tightening image-size policy, always profile send latency on real upload path (pick -> compress -> invoke -> reward), not just final byte size.
- Prefer precomputing expensive transforms (compression) before user-confirmed send so reward/UI feedback stays responsive.
- Even when backend timing is unchanged, add explicit pending-state feedback near the affected HUD metric to avoid perceived freezes.
- iOS AppTrackingTransparency (ATT) prompt timing must be lifecycle-gated (`resumed`) instead of delay-based; fixed startup delays can still suppress the system prompt on newer iOS builds.
- Any SDK path that can participate in tracking (analytics/ad SDK init, ad preload, ad request) must be blocked until ATT authorization is resolved, not just the explicit ATT API call site.
