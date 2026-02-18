import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeRoomsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => const <Map<String, dynamic>>[];

  void replaceAll(List<Map<String, dynamic>> rooms) {
    state = rooms
        .map((room) => Map<String, dynamic>.from(room))
        .toList(growable: false);
  }

  void clear() {
    state = const <Map<String, dynamic>>[];
  }
}

class HomeCurrentRoomIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? roomId) {
    state = roomId;
  }
}

class HomeRoomSelectionIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? roomId) {
    state = roomId;
  }
}

final homeRoomsProvider =
    NotifierProvider<HomeRoomsNotifier, List<Map<String, dynamic>>>(
      HomeRoomsNotifier.new,
    );

final homeCurrentRoomIdProvider =
    NotifierProvider<HomeCurrentRoomIdNotifier, String?>(
      HomeCurrentRoomIdNotifier.new,
    );

final homeRoomSelectionIdProvider =
    NotifierProvider<HomeRoomSelectionIdNotifier, String?>(
      HomeRoomSelectionIdNotifier.new,
    );
