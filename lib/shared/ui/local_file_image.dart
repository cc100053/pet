import 'package:flutter/widgets.dart';

import 'local_file_image_stub.dart'
    if (dart.library.io) 'local_file_image_io.dart';

Widget? buildLocalFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  return buildLocalFileImageImpl(path, fit: fit, width: width, height: height);
}
