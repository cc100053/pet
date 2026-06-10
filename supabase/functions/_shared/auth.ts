// Shared auth helpers for Edge Functions.

/// Constant-time comparison for shared secrets / bearer tokens. Avoids the
/// timing side-channel of a plain `===` on attacker-influenced input. Returns
/// false for empty expected secrets so an unset env var never authenticates.
export function timingSafeEqual(
  provided: string | null | undefined,
  expected: string | null | undefined,
): boolean {
  if (!expected) {
    return false;
  }
  const a = new TextEncoder().encode(provided ?? "");
  const b = new TextEncoder().encode(expected);
  // Fold the length difference into the result instead of early-returning so
  // the comparison cost does not leak the secret length.
  let mismatch = a.length ^ b.length;
  const max = Math.max(a.length, b.length);
  for (let i = 0; i < max; i += 1) {
    mismatch |= (a[i] ?? 0) ^ (b[i] ?? 0);
  }
  return mismatch === 0;
}
