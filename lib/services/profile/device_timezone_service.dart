import 'package:flutter_timezone/flutter_timezone.dart';

class DeviceTimezoneService {
  DeviceTimezoneService._();

  static final DeviceTimezoneService instance = DeviceTimezoneService._();

  Future<String?> getTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      final normalized = timezone.trim();
      if (normalized.isEmpty) {
        return null;
      }
      return normalized;
    } catch (_) {
      return null;
    }
  }
}
