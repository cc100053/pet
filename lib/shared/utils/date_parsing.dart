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
