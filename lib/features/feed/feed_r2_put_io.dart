import 'dart:io';
import 'dart:typed_data';

/// PUTs [bytes] to a presigned R2 URL and returns the HTTP status code.
/// Returns -1 if the request could not be made (caller falls back to base64).
Future<int> putBytesToPresignedUrl(
  String uploadUrl,
  Uint8List bytes,
  String contentType,
) async {
  final client = HttpClient();
  try {
    final request = await client.putUrl(Uri.parse(uploadUrl));
    request.headers.set(HttpHeaders.contentTypeHeader, contentType);
    request.headers.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  } catch (_) {
    return -1;
  } finally {
    client.close(force: true);
  }
}
