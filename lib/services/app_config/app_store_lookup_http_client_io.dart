import 'dart:io';

Future<String?> fetchAppStoreLookupBody(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    return response.transform(SystemEncoding().decoder).join();
  } finally {
    client.close(force: true);
  }
}
