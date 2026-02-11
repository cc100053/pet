import 'dart:io';
import 'dart:typed_data';

Future<String?> resolveAvatarAdjustSourcePath(String avatarUrl) async {
  final uri = Uri.tryParse(avatarUrl);
  if (uri == null) {
    return null;
  }

  if (uri.scheme == 'file') {
    return uri.toFilePath();
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return null;
  }

  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) {
      return null;
    }

    final file = File(
      '${Directory.systemTemp.path}/avatar_adjust_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
