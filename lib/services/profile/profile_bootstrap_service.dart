import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_timezone_service.dart';

typedef ProfileBootstrapTimezoneProvider = Future<String?> Function();
typedef ProfileBootstrapCurrentUserIdProvider = String? Function();
typedef ProfileBootstrapLoadProfile =
    Future<Map<String, dynamic>?> Function(String userId, String selectClause);
typedef ProfileBootstrapUpdateProfile =
    Future<void> Function(String userId, Map<String, dynamic> payload);
typedef ProfileBootstrapInsertProfile =
    Future<void> Function(Map<String, dynamic> payload);

class ProfileBootstrapService {
  ProfileBootstrapService({
    ProfileBootstrapTimezoneProvider? timezoneProvider,
    ProfileBootstrapCurrentUserIdProvider? currentUserIdProvider,
    ProfileBootstrapLoadProfile? loadProfile,
    ProfileBootstrapUpdateProfile? updateProfile,
    ProfileBootstrapInsertProfile? insertProfile,
  }) : _timezoneProvider =
           timezoneProvider ?? DeviceTimezoneService.instance.getTimezone,
       _currentUserIdProvider =
           currentUserIdProvider ??
           (() => Supabase.instance.client.auth.currentUser?.id),
       _loadProfile = loadProfile ?? _defaultLoadProfile,
       _updateProfile = updateProfile ?? _defaultUpdateProfile,
       _insertProfile = insertProfile ?? _defaultInsertProfile;

  static final ProfileBootstrapService instance = ProfileBootstrapService();

  final ProfileBootstrapTimezoneProvider _timezoneProvider;
  final ProfileBootstrapCurrentUserIdProvider _currentUserIdProvider;
  final ProfileBootstrapLoadProfile _loadProfile;
  final ProfileBootstrapUpdateProfile _updateProfile;
  final ProfileBootstrapInsertProfile _insertProfile;

  Future<Map<String, dynamic>?> ensureProfile({
    required String defaultNickname,
    String selectClause = 'user_id,nickname,avatar_url,coins,locale,timezone',
  }) async {
    final userId = _currentUserIdProvider();
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final localTimezone = await _timezoneProvider();
    final existingProfile = await _loadProfile(userId, selectClause);
    if (existingProfile != null) {
      return _syncTimezoneIfNeeded(
        userId: userId,
        profile: existingProfile,
        localTimezone: localTimezone,
      );
    }

    final insertPayload = <String, dynamic>{
      'user_id': userId,
      'nickname': defaultNickname,
    };
    if (localTimezone != null) {
      insertPayload['timezone'] = localTimezone;
    }
    await _insertProfile(insertPayload);

    final createdProfile = await _loadProfile(userId, selectClause);
    if (createdProfile != null) {
      return createdProfile;
    }

    return Map<String, dynamic>.from(insertPayload);
  }

  Future<Map<String, dynamic>> _syncTimezoneIfNeeded({
    required String userId,
    required Map<String, dynamic> profile,
    required String? localTimezone,
  }) async {
    if (localTimezone == null) {
      return profile;
    }
    final profileTimezone = (profile['timezone'] as String?)?.trim();
    if (profileTimezone == localTimezone) {
      return profile;
    }
    await _updateProfile(userId, {'timezone': localTimezone});
    return <String, dynamic>{...profile, 'timezone': localTimezone};
  }

  static Future<Map<String, dynamic>?> _defaultLoadProfile(
    String userId,
    String selectClause,
  ) async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select(selectClause)
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) {
      return null;
    }
    return Map<String, dynamic>.from(response);
  }

  static Future<void> _defaultUpdateProfile(
    String userId,
    Map<String, dynamic> payload,
  ) {
    return Supabase.instance.client
        .from('profiles')
        .update(payload)
        .eq('user_id', userId);
  }

  static Future<void> _defaultInsertProfile(Map<String, dynamic> payload) {
    return Supabase.instance.client.from('profiles').insert(payload);
  }
}
