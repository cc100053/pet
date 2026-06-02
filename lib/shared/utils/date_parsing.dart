/// Parses an optional date value coming from JSON/RPC payloads.
///
/// Accepts `null`, a `DateTime`, or an ISO-8601 `String`; returns `null` for
/// anything else (including unparseable strings).
DateTime? parseOptionalDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

/// Parses a required date value, falling back to the Unix epoch for null,
/// unparseable, or unexpected inputs. Use when a non-null `DateTime` is needed.
DateTime parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
