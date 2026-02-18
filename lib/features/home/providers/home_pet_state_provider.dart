import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePetStateSnapshot {
  const HomePetStateSnapshot({
    this.petId,
    this.state,
    required this.isReady,
    required this.isDeparted,
  });

  final String? petId;
  final Map<String, dynamic>? state;
  final bool isReady;
  final bool isDeparted;
}

class HomePetStateNotifier extends Notifier<HomePetStateSnapshot> {
  @override
  HomePetStateSnapshot build() {
    return const HomePetStateSnapshot(isReady: false, isDeparted: false);
  }

  void setSnapshot({
    required String? petId,
    required Map<String, dynamic>? state,
    required bool isReady,
    required bool isDeparted,
  }) {
    final sanitizedState = state == null
        ? null
        : Map<String, dynamic>.from(state);
    this.state = HomePetStateSnapshot(
      petId: petId,
      state: sanitizedState,
      isReady: isReady,
      isDeparted: isDeparted,
    );
  }

  void clear() {
    state = const HomePetStateSnapshot(isReady: false, isDeparted: false);
  }
}

final homePetStateProvider =
    NotifierProvider<HomePetStateNotifier, HomePetStateSnapshot>(
      HomePetStateNotifier.new,
    );
