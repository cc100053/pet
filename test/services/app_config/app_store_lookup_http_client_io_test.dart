import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/app_config/app_store_lookup_http_client_io.dart';

void main() {
  test('reads a slow chunked body before closing the client', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.write('{"results":');
      await request.response.flush();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      request.response.write('[]}');
      await request.response.close();
    });

    final body = await fetchAppStoreLookupBody(
      Uri.parse('http://127.0.0.1:${server.port}/lookup'),
    );

    expect(body, '{"results":[]}');
  });
}
