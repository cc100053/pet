import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/profile/profile_bootstrap_service.dart';

void main() {
  test('returns null when there is no signed-in user', () async {
    final service = ProfileBootstrapService(
      timezoneProvider: () async => 'Asia/Tokyo',
      currentUserIdProvider: () => null,
      loadProfile: (_, __) async => throw UnimplementedError(),
      updateProfile: (_, __) async => throw UnimplementedError(),
      insertProfile: (_) async => throw UnimplementedError(),
    );

    final profile = await service.ensureProfile(defaultNickname: 'Pet');

    expect(profile, isNull);
  });

  test('creates and reloads a missing profile', () async {
    Map<String, dynamic>? storedProfile;
    final inserts = <Map<String, dynamic>>[];
    final loads = <String>[];
    final service = ProfileBootstrapService(
      timezoneProvider: () async => 'Asia/Tokyo',
      currentUserIdProvider: () => 'user-1',
      loadProfile: (userId, selectClause) async {
        loads.add('$userId|$selectClause');
        return storedProfile == null
            ? null
            : Map<String, dynamic>.from(storedProfile!);
      },
      updateProfile: (_, __) async {},
      insertProfile: (payload) async {
        inserts.add(Map<String, dynamic>.from(payload));
        storedProfile = <String, dynamic>{
          'user_id': payload['user_id'],
          'nickname': payload['nickname'],
          'timezone': payload['timezone'],
          'coins': 0,
        };
      },
    );

    final profile = await service.ensureProfile(
      defaultNickname: 'Pet',
      selectClause: 'user_id,nickname,timezone,coins',
    );

    expect(inserts, hasLength(1));
    expect(inserts.single['user_id'], 'user-1');
    expect(inserts.single['nickname'], 'Pet');
    expect(inserts.single['timezone'], 'Asia/Tokyo');
    expect(loads, hasLength(2));
    expect(profile, isNotNull);
    expect(profile!['nickname'], 'Pet');
    expect(profile['timezone'], 'Asia/Tokyo');
    expect(profile['coins'], 0);
  });

  test('syncs timezone when existing profile is outdated', () async {
    final updates = <Map<String, dynamic>>[];
    final service = ProfileBootstrapService(
      timezoneProvider: () async => 'Asia/Tokyo',
      currentUserIdProvider: () => 'user-1',
      loadProfile: (_, __) async => <String, dynamic>{
        'user_id': 'user-1',
        'nickname': 'Pet',
        'timezone': 'UTC',
      },
      updateProfile: (userId, payload) async {
        updates.add(<String, dynamic>{'user_id': userId, ...payload});
      },
      insertProfile: (_) async => throw UnimplementedError(),
    );

    final profile = await service.ensureProfile(defaultNickname: 'Pet');

    expect(updates, [
      <String, dynamic>{'user_id': 'user-1', 'timezone': 'Asia/Tokyo'},
    ]);
    expect(profile!['timezone'], 'Asia/Tokyo');
  });

  test('does not update timezone when it already matches', () async {
    var updateCalls = 0;
    final service = ProfileBootstrapService(
      timezoneProvider: () async => 'Asia/Tokyo',
      currentUserIdProvider: () => 'user-1',
      loadProfile: (_, __) async => <String, dynamic>{
        'user_id': 'user-1',
        'nickname': 'Pet',
        'timezone': 'Asia/Tokyo',
      },
      updateProfile: (_, __) async {
        updateCalls += 1;
      },
      insertProfile: (_) async => throw UnimplementedError(),
    );

    final profile = await service.ensureProfile(defaultNickname: 'Pet');

    expect(updateCalls, 0);
    expect(profile!['timezone'], 'Asia/Tokyo');
  });
}
