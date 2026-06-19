/// Ordering guard for room-shared pet state (`pet_state` / `room_pet_state`).
///
/// The satiety value (`hunger`) only ever decreases when passive decay advances
/// the `last_decay_at` anchor; feeds raise it and (re)anchor decay at the feed
/// time. So a snapshot whose anchor is strictly older than the last one already
/// applied is stale — e.g. a pre-feed decay tick read that arrives after the
/// fed value on a slow upload. Applying it would regress the bar back to the
/// pre-feed reading, which is the intermittent "fed but satiety didn't move"
/// bug. Snapshots without an anchor cannot be ordered and are accepted.
bool petStateSnapshotIsFresh({DateTime? held, DateTime? incoming}) {
  if (held == null || incoming == null) {
    return true;
  }
  return !incoming.isBefore(held);
}
