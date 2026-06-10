import 'dart:typed_data';

/// Web/no-IO fallback: signals "unsupported" so the caller uses the base64
/// upload path instead. Returns a negative status code.
Future<int> putBytesToPresignedUrl(
  String uploadUrl,
  Uint8List bytes,
  String contentType,
) async =>
    -1;
