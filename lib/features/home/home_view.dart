import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/auth/session_utils.dart';
import '../../services/fcm_service.dart';

import '../../services/label_mapping/label_mapping_service.dart';
import '../../shared/ui/juice_wrappers.dart';
import '../chat/chat_message.dart';
import '../chat/chat_room_view.dart';
import '../feed/feed_capture_view.dart';
import '../gallery/memory_calendar_view.dart';
import '../pet/leveling.dart';
import '../profile/profile_view.dart';
import '../store/store_view.dart';
import 'room_selection_view.dart';
import 'widgets/home_bottom_nav_bar.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_furniture_inventory_panel.dart';
import 'widgets/home_game_status_bar.dart';
import 'widgets/home_polaroid_memory_frame.dart';

enum _PetStationaryState { staying, sleeping }

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with TickerProviderStateMixin {
  static const _petStayGifAsset = 'assets/pet/ghost/ghost_stay.gif';
  static const _petSleepGifAsset = 'assets/pet/ghost/ghost_sleep.gif';
  static const _petWalkGifAsset = 'assets/pet/ghost/ghost_walking.gif';
  static const _petAvatarSize = Size(100, 100);
  static const double _petMoveSpeed = 30;
  static const int _minMoveMs = 260;
  static const Duration _idleThreshold = Duration(seconds: 8);
  static const Duration _wanderCooldown = Duration(seconds: 7);
  static const Duration _wanderCheckInterval = Duration(seconds: 4);
  static const Duration _petTickInterval = Duration(minutes: 5);
  static const _furnitureItemSize = Size(42, 42);
  static const _poopEmojiSize = Size(28, 28);

  // Logic State
  bool _profileEnsured = false;
  bool _creatingRoom = false;
  bool _joiningRoom = false;
  bool _testingFeed = false;
  bool _loadingRoom = true;
  bool _showRoomSelection = true;
  String? _roomSelectionId;
  String? _roomId;
  String? _feedResult;
  String? _petId;
  bool _petBusy = false;
  Map<String, dynamic>? _petState;
  String? _petError;
  String? _petName;
  int? _petLevel;
  int? _petExp;
  int _coins = 1234;
  int? _coinReward; // Triggers coin animation when set
  int _coinRewardEventId = 0;
  bool _coinsLoadInFlight = false;
  int? _pendingCoinsExpectedReward;
  List<Map<String, dynamic>> _myRooms = []; // Stores room info
  RealtimeChannel? _petStateChannel;
  String? _petSubscriptionPetId;
  final GlobalKey _petFieldKey = GlobalKey();
  final Random _random = Random();
  late final AnimationController _petMoveController;
  late final AnimationController _furnitureWiggleController;
  Animation<Offset>? _petMoveAnimation;
  Offset _petNormalizedPosition = const Offset(0.5, 0.6);
  Offset _petNormalizedTarget = const Offset(0.5, 0.6);
  bool _petFacingRight = true;
  bool _isDraggingPet = false;
  bool _petIsMoving = false;
  _PetStationaryState _petStationaryState = _PetStationaryState.staying;
  Offset _dragOffset = Offset.zero;
  Timer? _wanderTimer;
  DateTime _lastInteractionAt = DateTime.now();
  DateTime _lastWanderAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _petTickTimer;
  bool _petAssetsPrecached = false;

  // Furniture State
  bool _furnitureMode = false;
  bool _furnitureLoading = false;
  String? _furnitureError;
  String? _selectedFurnitureItemId;
  int _furnitureInstanceSeed = 0;
  final Map<String, StoreItem> _furnitureCatalog = {};
  final Map<String, int> _furnitureInventory = {};
  final Map<String, List<_PlacedFurniture>> _placedFurnitureByRoom = {};
  RealtimeChannel? _furnitureChannel;
  String? _furnitureSubscriptionRoomId;
  final Map<String, RealtimeChannel> _messageChannels = {};

  // Chat State
  final GlobalKey<ChatMessageListState> _chatListKey = GlobalKey();

  // Latest feed (polaroid)
  String? _latestFeedImageUrl;
  String? _latestFeedSenderId;
  String? _latestFeedCaption;
  String? _latestFeedOptimisticTempId;
  String? _latestFeedOptimisticRoomId;
  String? _latestFeedOptimisticPrevImageUrl;
  String? _latestFeedOptimisticPrevSenderId;
  String? _latestFeedOptimisticPrevCaption;
  final Map<String, _ProfileSummary> _profileByUserId = {};

  @override
  void initState() {
    super.initState();
    _selectNextPetStationaryState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_profileEnsured) {
        unawaited(() async {
          await _ensureProfile();
          await _loadCoins();
          await _fetchRooms();
        }());
        _profileEnsured = true;
      }
    });
    _petMoveController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _petNormalizedPosition = _petNormalizedTarget;
          if (mounted) {
            if (!_isDraggingPet) {
              setState(() {
                _petIsMoving = false;
                _selectNextPetStationaryState();
              });
            }
          } else {
            _petIsMoving = false;
          }
        }
      });
    _furnitureWiggleController = AnimationController(
      vsync: this,
      duration: 450.ms,
    );
    _startWanderTimer();
    _startPetTickTimer();

    // Init FCM
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).initialize();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_petAssetsPrecached) {
      return;
    }
    _petAssetsPrecached = true;
    for (final asset in const [
      _petStayGifAsset,
      _petSleepGifAsset,
      _petWalkGifAsset,
    ]) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void dispose() {
    _petStateChannel?.unsubscribe();
    _furnitureChannel?.unsubscribe();
    for (final channel in _messageChannels.values) {
      channel.unsubscribe();
    }
    _messageChannels.clear();
    _wanderTimer?.cancel();
    _petTickTimer?.cancel();
    _petMoveController.dispose();
    _furnitureWiggleController.dispose();
    super.dispose();
  }

  // --- Logic Methods ---
  Future<void> _ensureProfile() async {
    final defaultNickname = AppLocalizations.of(
      context,
    )!.profileDefaultNickname;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile == null) {
        await Supabase.instance.client.from('profiles').insert({
          'user_id': user.id,
          'nickname': defaultNickname,
        });
      }
    } catch (_) {
      // Best-effort. Profile creation can be retried on next app open.
    }
  }

  Future<void> _loadCoins({int? expectedReward}) async {
    final normalizedExpected = expectedReward ?? 0;
    if (_coinsLoadInFlight) {
      if (normalizedExpected > 0) {
        _pendingCoinsExpectedReward =
            (_pendingCoinsExpectedReward ?? 0) + normalizedExpected;
      }
      return;
    }

    _coinsLoadInFlight = true;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return;
      }
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('coins')
          .eq('user_id', user.id)
          .maybeSingle();
      final newValue = (profile?['coins'] as int?) ?? _coins;
      final oldValue = _coins;
      if (!mounted) {
        _coins = newValue;
        return;
      }

      int? rewardEventIdToClear;
      setState(() {
        _coins = newValue;

        // Clear any stale reward when this load is expected to represent a
        // reward event (including cooldown/no-op cases).
        if (expectedReward != null) {
          _coinReward = null;
        }

        // Trigger animation only for expected reward events that actually
        // increased the balance.
        if (normalizedExpected > 0 && newValue > oldValue) {
          _coinReward = newValue - oldValue;
          _coinRewardEventId++;
          rewardEventIdToClear = _coinRewardEventId;
        }
      });

      if (rewardEventIdToClear != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          if (_coinRewardEventId != rewardEventIdToClear) {
            return;
          }
          if (_coinReward == null) {
            return;
          }
          setState(() {
            _coinReward = null;
          });
        });
      }
    } catch (_) {
      // Best-effort.
    } finally {
      _coinsLoadInFlight = false;

      final pending = _pendingCoinsExpectedReward;
      _pendingCoinsExpectedReward = null;
      if (pending != null && pending > 0) {
        unawaited(_loadCoins(expectedReward: pending));
      }
    }
  }

  Future<void> _fetchRooms() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loadingRoom = false);
        return;
      }

      final responses = await Supabase.instance.client
          .from('room_members')
          .select('room_id, role, rooms(name, invite_code)')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('joined_at', ascending: false);

      final List<Map<String, dynamic>> rooms = [];
      for (final r in responses) {
        final roomData = r['rooms'] as Map<String, dynamic>?;
        if (roomData != null) {
          rooms.add({
            'id': r['room_id'],
            'name': roomData['name'],
            'invite_code': roomData['invite_code'],
            'role': r['role'],
          });
        }
      }

      final roomIds = rooms
          .map((room) => room['id'])
          .whereType<String>()
          .toList(growable: false);
      if (roomIds.isNotEmpty) {
        final moods = await _fetchRoomMoods(roomIds);
        final photos = await _fetchRoomLatestPhotos(roomIds);
        for (final room in rooms) {
          final roomId = room['id'] as String?;
          if (roomId != null && moods.containsKey(roomId)) {
            room['mood'] = moods[roomId];
          }
          if (roomId != null && photos.containsKey(roomId)) {
            final latest = photos[roomId];
            if (latest != null && latest.isNotEmpty) {
              room['latest_photo'] = latest.first;
              room['latest_photos'] = latest;
            }
          }
        }
      }

      _syncMessageSubscriptions(roomIds);

      setState(() {
        _myRooms = rooms;
        if (rooms.isEmpty) {
          _showRoomSelection = true;
          _roomSelectionId = null;
        } else {
          _roomSelectionId ??= _roomId ?? rooms.first['id'] as String?;
        }
      });

      if (_roomId != null) {}

      if (rooms.isNotEmpty) {
        // If no room selected, or selected room not in list, select first
        if (_roomId == null || !rooms.any((r) => r['id'] == _roomId)) {
          _switchRoom(rooms.first['id'] as String);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingRoom = false);
    }
  }

  void _syncMessageSubscriptions(List<String> roomIds) {
    final target = roomIds.toSet();
    final existing = _messageChannels.keys.toList(growable: false);
    for (final roomId in existing) {
      if (!target.contains(roomId)) {
        _messageChannels[roomId]?.unsubscribe();
        _messageChannels.remove(roomId);
      }
    }

    for (final roomId in target) {
      if (_messageChannels.containsKey(roomId)) {
        continue;
      }
      final channel = Supabase.instance.client.channel('messages_$roomId');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (payload) => _handleMessageInsert(payload.newRecord),
      );
      channel.subscribe();
      _messageChannels[roomId] = channel;
    }
  }

  void _handleMessageInsert(Map<String, dynamic> record) {
    if (!mounted || record.isEmpty) {
      return;
    }
    final type = record['type'] as String?;
    if (type != 'image_feed') {
      return;
    }
    final roomId = record['room_id'] as String?;
    final imageUrl = record['image_url'] as String?;
    if (roomId == null || imageUrl == null || imageUrl.isEmpty) {
      return;
    }
    final senderId = record['sender_id'] as String?;
    final caption = record['caption'] as String?;
    setState(() {
      if (roomId == _roomId) {
        _latestFeedImageUrl = imageUrl;
        _latestFeedSenderId = senderId;
        _latestFeedCaption = caption;
      }
      _myRooms = _myRooms.map((room) {
        if (room['id'] != roomId) {
          return room;
        }
        final next = <String>[imageUrl];
        final existing = room['latest_photos'];
        if (existing is List) {
          for (final entry in existing) {
            final url = entry as String?;
            if (url == null || url.isEmpty || url == imageUrl) {
              continue;
            }
            next.add(url);
            if (next.length >= 3) {
              break;
            }
          }
        } else {
          final previous = room['latest_photo'] as String?;
          if (previous != null && previous.isNotEmpty && previous != imageUrl) {
            next.add(previous);
          }
        }
        return {...room, 'latest_photo': imageUrl, 'latest_photos': next};
      }).toList();
    });

    if (roomId == _roomId) {
      unawaited(() async {
        final petId = _petId ?? await _loadPetId(roomId);
        if (petId != null) {
          await _loadPetInfo(petId);
        }
      }());
    }

    if (senderId != null && senderId.isNotEmpty) {
      unawaited(_ensureProfileSummary(senderId));
    }
  }

  void _switchRoom(String roomId) {
    final previousRoom = _roomId;
    setState(() {
      _roomId = roomId;
      _petState = null; // Clear old state
      _petId = null;
      _furnitureMode = false;
      _selectedFurnitureItemId = null;
    });
    _furnitureWiggleController.stop();
    _furnitureWiggleController.value = 0;
    _petStateChannel?.unsubscribe();
    _petStateChannel = null;
    _petSubscriptionPetId = null;
    _furnitureChannel?.unsubscribe();
    _furnitureChannel = null;
    _furnitureSubscriptionRoomId = null;
    _refreshPetState();
    unawaited(_refreshLatestFeed(roomId));
    unawaited(_loadFurnitureInventory());
    unawaited(_loadRoomFurniture(roomId));
    _subscribeToFurniture(roomId);
    if (previousRoom != roomId) {
      AnalyticsService.instance.logEvent('room_switch');
    }
  }

  void _enterRoomFromSelection(String roomId) {
    if (!_showRoomSelection) {
      _switchRoom(roomId);
      return;
    }
    setState(() {
      _showRoomSelection = false;
      _roomSelectionId = roomId;
    });
    _switchRoom(roomId);
  }

  Future<void> _signOut() async {
    AnalyticsService.instance.logEvent('sign_out_tap');
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _createRoom() async {
    final l10n = AppLocalizations.of(context)!;
    if (_myRooms.length >= 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.roomLimitReached)));
      return;
    }

    setState(() => _creatingRoom = true);
    try {
      final response = await Supabase.instance.client
          .rpc('create_room', params: {'p_name': l10n.roomDefaultName})
          .single();

      // Refresh list and switch
      await _fetchRooms();
      if (!mounted) {
        return;
      }
      final newId = response['room_id'] as String?;
      if (newId != null) {
        _enterRoomFromSelection(newId);
      }
      AnalyticsService.instance.logEvent(
        'room_create',
        parameters: {'result': 'success'},
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.roomCreatedSuccess)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.roomCreateFailed(error.toString()))),
      );
    } finally {
      if (mounted) setState(() => _creatingRoom = false);
    }
  }

  Future<void> _joinRoomByCode() async {
    if (_joiningRoom) return;

    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.roomJoinTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.roomJoinHint,
            helperText: l10n.roomJoinHelper,
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              // Normalize invite code to uppercase for consistent matching.
              final value = controller.text.trim().toUpperCase();
              Navigator.pop(context, value.isEmpty ? null : value);
            },
            child: Text(l10n.commonJoin),
          ),
        ],
      ),
    );

    if (code == null || code.isEmpty) {
      return;
    }

    setState(() => _joiningRoom = true);
    try {
      final response = await Supabase.instance.client.rpc(
        'join_room_by_code',
        params: {'code': code},
      );

      String? roomId;
      if (response is String) {
        roomId = response;
      } else if (response is Map) {
        final value = response.values.isNotEmpty ? response.values.first : null;
        if (value is String) {
          roomId = value;
        }
      } else if (response is List && response.isNotEmpty) {
        final value = response.first;
        if (value is String) {
          roomId = value;
        } else if (value is Map) {
          final inner = value.values.isNotEmpty ? value.values.first : null;
          if (inner is String) {
            roomId = inner;
          }
        }
      }

      await _fetchRooms();
      if (!mounted) {
        return;
      }
      if (roomId != null) {
        _enterRoomFromSelection(roomId);
      }

      AnalyticsService.instance.logEvent(
        'room_join',
        parameters: {'method': 'invite_code', 'result': 'success'},
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.roomJoinSuccess)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.roomJoinFailed(error.toString()))),
      );
    } finally {
      if (mounted) setState(() => _joiningRoom = false);
    }
  }

  Future<void> _runFeedTest() async {
    final roomId = _roomId;
    if (roomId == null) return;

    setState(() {
      _testingFeed = true;
      _feedResult = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      final debugResult = await ensureValidAccessTokenWithDebug();
      final accessToken = debugResult.token;
      final userId = auth.currentUser?.id;
      String tokenPreview;
      if (accessToken == null) {
        tokenPreview = 'null';
      } else if (accessToken.length <= 16) {
        tokenPreview = accessToken;
      } else {
        tokenPreview =
            '${accessToken.substring(0, 10)}...${accessToken.substring(accessToken.length - 6)}';
      }
      final expiryText = debugResult.expiresAt?.toIso8601String() ?? 'unknown';
      final remainingText =
          debugResult.remaining?.inSeconds.toString() ?? 'unknown';
      final claims = debugResult.claims ?? const {};
      final ref = claims['ref'] ?? 'unknown';
      final aud = claims['aud'] ?? 'unknown';
      final issuer = claims['iss'] ?? 'unknown';
      final sub = claims['sub'] ?? 'unknown';
      final role = claims['role'] ?? 'unknown';

      setState(() {
        _feedResult =
            'auth: user=$userId | token=$tokenPreview | '
            'ref=$ref | aud=$aud | iss=$issuer | sub=$sub | role=$role | '
            'expires=$expiryText | remaining=${remainingText}s | '
            '${debugResult.message}';
      });
      debugPrint('[feed_test] ${_feedResult ?? ''}');

      if (accessToken == null) {
        return;
      }

      final labelObservations = [
        const LabelObservation(text: 'Coffee', confidence: 0.92),
        const LabelObservation(text: 'Cup', confidence: 0.71),
      ];

      final mappingRepository = LabelMappingRepository(
        Supabase.instance.client,
      );
      final mappingEntries = await mappingRepository.fetch();
      final mappingService = LabelMappingService(mappingEntries);

      final mappedLabels = mappingService.matchLabels(labelObservations);
      final matchByLabel = <String, LabelMatch>{};
      for (final match in mappedLabels) {
        matchByLabel[LabelMappingService.normalizeLabel(match.text)] = match;
      }

      final labelPayload = labelObservations.map((label) {
        final normalized = LabelMappingService.normalizeLabel(label.text);
        final match = matchByLabel[normalized];
        return {
          'text': label.text,
          'confidence': label.confidence,
          if (match != null) 'canonical_tag': match.canonicalTag,
        };
      }).toList();

      Future<FunctionResponse> invokeWithToken(String token) {
        return Supabase.instance.client.functions.invoke(
          'feed_validate',
          headers: {'Authorization': 'Bearer $token'},
          body: {
            'room_id': roomId,
            'labels': labelPayload,
            'canonical_tags': mappingService.matchCanonicalTags(
              labelObservations,
            ),
            'caption': 'Test feed',
            'image_url': 'https://example.com/test.jpg',
          },
        );
      }

      FunctionResponse response;
      try {
        response = await invokeWithToken(accessToken);
      } on FunctionException catch (error) {
        if (error.status == 401) {
          final refreshed = await ensureValidAccessTokenWithDebug(
            forceRefresh: true,
          );
          final refreshedToken = refreshed.token;
          if (refreshedToken == null) {
            rethrow;
          }
          response = await invokeWithToken(refreshedToken);
        } else {
          rethrow;
        }
      }

      final data = response.data;
      String details = 'status ${response.status}';
      if (data is Map) {
        final payload = Map<String, dynamic>.from(data);
        final webhookSkipped = payload['webhook_skipped'];
        final webhookStatus = payload['webhook_status'];
        final webhookError = payload['webhook_error'];
        details =
            'status ${response.status} | webhook_skipped=$webhookSkipped | '
            'webhook_status=$webhookStatus | webhook_error=$webhookError';
      }

      setState(() {
        _feedResult = 'Success: $details';
      });
      _chatListKey.currentState?.refreshLatest();
    } on FunctionException catch (error) {
      final detailsText = error.details == null ? '' : ' | ${error.details}';
      setState(
        () => _feedResult =
            'Error: status ${error.status} ${error.reasonPhrase}$detailsText',
      );
    } catch (error) {
      setState(() => _feedResult = 'Error: $error');
    } finally {
      if (mounted) setState(() => _testingFeed = false);
    }
  }

  Future<String?> _loadPetId(String roomId) async {
    final response = await Supabase.instance.client
        .from('pets')
        .select('id')
        .eq('room_id', roomId)
        .maybeSingle();
    return response?['id'] as String?;
  }

  Future<Map<String, String?>> _fetchRoomMoods(List<String> roomIds) async {
    if (roomIds.isEmpty) {
      return {};
    }
    final rows = await Supabase.instance.client
        .from('pets')
        .select('room_id, pet_state(mood)')
        .inFilter('room_id', roomIds);

    final moods = <String, String?>{};
    for (final row in rows) {
      final roomId = row['room_id'] as String?;
      if (roomId == null) {
        continue;
      }
      final state = row['pet_state'];
      String? mood;
      if (state is Map) {
        mood = state['mood'] as String?;
      } else if (state is List && state.isNotEmpty) {
        final first = state.first;
        if (first is Map) {
          mood = first['mood'] as String?;
        }
      }
      moods[roomId] = mood;
    }
    return moods;
  }

  Future<Map<String, List<String>>> _fetchRoomLatestPhotos(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) {
      return {};
    }
    final rows = await Supabase.instance.client
        .from('messages')
        .select('room_id, image_url, created_at')
        .inFilter('room_id', roomIds)
        .eq('type', 'image_feed')
        .not('image_url', 'is', null)
        .order('created_at', ascending: false)
        .limit(roomIds.length * 12);

    final photos = <String, List<String>>{};
    for (final row in rows) {
      final roomId = row['room_id'] as String?;
      final imageUrl = row['image_url'] as String?;
      if (roomId == null || imageUrl == null || imageUrl.isEmpty) {
        continue;
      }

      final existing = photos.putIfAbsent(roomId, () => <String>[]);
      if (existing.length >= 3 || existing.contains(imageUrl)) {
        continue;
      }
      existing.add(imageUrl);
    }
    return photos;
  }

  Future<void> _refreshLatestRoomPhoto(String roomId) async {
    try {
      final rows = await Supabase.instance.client
          .from('messages')
          .select('image_url, created_at')
          .eq('room_id', roomId)
          .eq('type', 'image_feed')
          .not('image_url', 'is', null)
          .order('created_at', ascending: false)
          .limit(3);

      if (rows.isEmpty) {
        return;
      }
      final latest = rows
          .map((row) => row['image_url'] as String?)
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .take(3)
          .toList(growable: false);
      if (latest.isEmpty) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _myRooms = _myRooms
            .map(
              (room) => room['id'] == roomId
                  ? {
                      ...room,
                      'latest_photo': latest.first,
                      'latest_photos': latest,
                    }
                  : room,
            )
            .toList();
      });
    } catch (_) {
      // Best-effort. Latest photo updates are also driven by realtime.
    }
  }

  Future<void> _refreshPetState({bool tick = false}) async {
    final roomId = _roomId;
    if (roomId == null) return;

    setState(() {
      _petBusy = true;
      _petError = null;
    });

    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) {
        setState(() => _petError = AppLocalizations.of(context)!.petNotFound);
        return;
      }

      _subscribeToPetState(petId);
      unawaited(_loadPetInfo(petId));

      if (tick) {
        await Supabase.instance.client.rpc(
          'tick_pet_state',
          params: {
            'p_pet_id': petId,
            'p_now': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }

      final state = await Supabase.instance.client
          .from('pet_state')
          .select()
          .eq('pet_id', petId)
          .maybeSingle();

      setState(() {
        _petId = petId;
        _petState = state;
        final mood = state?['mood'] as String?;
        _myRooms = _myRooms
            .map(
              (room) => room['id'] == roomId ? {...room, 'mood': mood} : room,
            )
            .toList();
      });
    } catch (error) {
      setState(
        () => _petError = AppLocalizations.of(
          context,
        )!.petSyncFailed(error.toString()),
      );
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }

    unawaited(_loadCoins());
  }

  void _subscribeToPetState(String petId) {
    if (_petSubscriptionPetId == petId) {
      return;
    }

    _petStateChannel?.unsubscribe();
    _petSubscriptionPetId = petId;

    final channel = Supabase.instance.client.channel('pet_state_$petId');
    _petStateChannel = channel;

    void handleUpdate(Map<String, dynamic> record) {
      if (!mounted) {
        return;
      }
      if (record.isEmpty) {
        _refreshPetState();
        return;
      }
      setState(() {
        _petId = petId;
        _petState = Map<String, dynamic>.from(record);
        final mood = _petState?['mood'] as String?;
        final roomId = _roomId;
        if (roomId != null) {
          _myRooms = _myRooms
              .map(
                (room) => room['id'] == roomId ? {...room, 'mood': mood} : room,
              )
              .toList();
        }
      });
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'pet_state',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'pet_id',
        value: petId,
      ),
      callback: (payload) => handleUpdate(payload.newRecord),
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'pet_state',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'pet_id',
        value: petId,
      ),
      callback: (payload) => handleUpdate(payload.newRecord),
    );

    channel.subscribe();
  }

  Future<void> _applyPetAction(String action) async {
    final roomId = _roomId;
    if (roomId == null) return;

    setState(() {
      _petBusy = true;
      _petError = null;
    });

    // Haptic Feedback for actions
    HapticFeedback.mediumImpact();

    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) return;

      await Supabase.instance.client.rpc(
        'apply_pet_action',
        params: {'p_pet_id': petId, 'p_action_type': action},
      );

      // Call claim_action_reward to actually grant coins
      final reward = await Supabase.instance.client.rpc(
        'claim_action_reward',
        params: {'p_action_type': action, 'p_room_id': roomId},
      );
      final actualReward = (reward as int?) ?? 0;

      await _refreshPetState();
      await _loadCoins(expectedReward: actualReward);
      await _loadPetInfo(petId);
    } catch (error) {
      setState(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(error.toString()),
      );
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }
  }

  Future<void> _openFeedCamera() async {
    final roomId = _roomId;
    if (roomId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedCaptureView(
          roomId: roomId,
          onOptimisticMessage: _handleOptimisticFeed,
          onUploadCompleted: _handleFeedUploadCompleted,
          onUploadFailed: _handleFeedUploadFailed,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    _chatListKey.currentState?.refreshLatest();
  }

  void _handleOptimisticFeed(FeedOptimisticMessage entry) {
    final optimisticMessage = ChatMessage(
      id: entry.tempId,
      roomId: entry.roomId,
      senderId: entry.senderId,
      type: 'image_feed',
      body: null,
      imageUrl: null,
      caption: entry.caption,
      coinsAwarded: 0,
      createdAt: entry.clientCreatedAt,
      clientCreatedAt: entry.clientCreatedAt,
      labels: entry.labels,
      localImagePath: entry.localImagePath,
    );
    _chatListKey.currentState?.addOptimisticMessage(optimisticMessage);

    final roomId = _roomId;
    if (roomId == null || entry.roomId != roomId) {
      return;
    }
    if (kIsWeb) {
      return;
    }

    setState(() {
      _latestFeedOptimisticTempId = entry.tempId;
      _latestFeedOptimisticRoomId = entry.roomId;
      _latestFeedOptimisticPrevImageUrl = _latestFeedImageUrl;
      _latestFeedOptimisticPrevSenderId = _latestFeedSenderId;
      _latestFeedOptimisticPrevCaption = _latestFeedCaption;
      _latestFeedImageUrl = entry.localImagePath;
      _latestFeedSenderId = entry.senderId;
      _latestFeedCaption = entry.caption;
    });
    unawaited(_ensureProfileSummary(entry.senderId));
  }

  void _handleFeedUploadCompleted(String tempId) {
    _chatListKey.currentState?.removeOptimisticMessage(tempId);
    _chatListKey.currentState?.refreshLatest();

    if (_latestFeedOptimisticTempId == tempId) {
      _latestFeedOptimisticTempId = null;
      _latestFeedOptimisticRoomId = null;
      _latestFeedOptimisticPrevImageUrl = null;
      _latestFeedOptimisticPrevSenderId = null;
      _latestFeedOptimisticPrevCaption = null;
    }
    final roomId = _roomId;
    if (roomId != null) {
      _refreshLatestRoomPhoto(roomId);
      unawaited(_refreshLatestFeed(roomId));
      unawaited(_loadCoins(expectedReward: 10)); // Feed = +10 coins

      unawaited(() async {
        final petId = _petId ?? await _loadPetId(roomId);
        if (petId != null) {
          await _loadPetInfo(petId);
        }
      }());
    }
  }

  void _handleFeedUploadFailed(String tempId, Object error) {
    _chatListKey.currentState?.removeOptimisticMessage(tempId);
    if (_latestFeedOptimisticTempId == tempId) {
      final shouldRestore =
          _roomId != null && _roomId == _latestFeedOptimisticRoomId;
      setState(() {
        if (shouldRestore) {
          _latestFeedImageUrl = _latestFeedOptimisticPrevImageUrl;
          _latestFeedSenderId = _latestFeedOptimisticPrevSenderId;
          _latestFeedCaption = _latestFeedOptimisticPrevCaption;
        }
        _latestFeedOptimisticTempId = null;
        _latestFeedOptimisticRoomId = null;
        _latestFeedOptimisticPrevImageUrl = null;
        _latestFeedOptimisticPrevSenderId = null;
        _latestFeedOptimisticPrevCaption = null;
      });
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.feedUploadFailed(error.toString()),
        ),
      ),
    );
  }

  void _openChatRoom() {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatRoomView(roomId: roomId)));
  }

  void _openCalendar() {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemoryCalendarView(
          roomId: roomId,
          currentUserId: Supabase.instance.client.auth.currentUser?.id,
        ),
      ),
    );
  }

  double _healthValue() {
    final hunger = (_petState?['hunger'] as int?) ?? 0;
    final hygiene = (_petState?['hygiene'] as int?) ?? 0;
    final base = ((hunger + hygiene) / 2).clamp(0, 100);
    final mood = (_petState?['mood'] as String?) ?? 'low';
    final moodFactor = switch (mood) {
      'high' => 1.0,
      'mid' => 0.9,
      'low' => 0.75,
      'sad' => 0.6,
      _ => 0.9,
    };
    return ((base / 100) * moodFactor).clamp(0.0, 1.0);
  }

  void _onHomeNavPressed() {
    if (_furnitureMode) {
      _closeFurnitureInventory();
    }
    final fieldSize = _petFieldSize();
    if (fieldSize != null && !fieldSize.isEmpty) {
      _animatePetTo(const Offset(0.5, 0.7), fieldSize, userInitiated: false);
      return;
    }
    setState(() {
      _petNormalizedPosition = const Offset(0.5, 0.7);
    });
  }

  Future<void> _openStoreFromNav() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StoreView()));
    if (!mounted) {
      return;
    }
    await _loadCoins();
    await _loadFurnitureInventory();
  }

  Future<void> _refreshLatestFeed(String roomId) async {
    try {
      final row = await Supabase.instance.client
          .from('messages')
          .select('sender_id,image_url,caption,created_at')
          .eq('room_id', roomId)
          .eq('type', 'image_feed')
          .not('image_url', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) {
        return;
      }
      final imageUrl = row['image_url'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) {
        return;
      }
      final senderId = row['sender_id'] as String?;
      final caption = row['caption'] as String?;
      if (mounted) {
        setState(() {
          _latestFeedImageUrl = imageUrl;
          _latestFeedSenderId = senderId;
          _latestFeedCaption = caption;
        });
      } else {
        _latestFeedImageUrl = imageUrl;
        _latestFeedSenderId = senderId;
        _latestFeedCaption = caption;
      }
      if (senderId != null && senderId.isNotEmpty) {
        await _ensureProfileSummary(senderId);
      }
    } catch (_) {
      // Best-effort.
    }
  }

  Future<_ProfileSummary?> _ensureProfileSummary(String userId) async {
    final cached = _profileByUserId[userId];
    if (cached != null) {
      return cached;
    }
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('user_id,nickname,avatar_url')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      final summary = _ProfileSummary(
        nickname: row['nickname'] as String?,
        avatarUrl: row['avatar_url'] as String?,
      );
      if (!mounted) {
        _profileByUserId[userId] = summary;
        return summary;
      }
      setState(() {
        _profileByUserId[userId] = summary;
      });
      return summary;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadPetInfo(String petId) async {
    try {
      final row = await Supabase.instance.client
          .from('pets')
          .select('name, level, exp')
          .eq('id', petId)
          .maybeSingle();
      if (row == null) {
        return;
      }
      final name = row['name'] as String?;
      final level = row['level'] as int?;
      final exp = row['exp'] as int?;
      if (!mounted) {
        _petName = name;
        _petLevel = level;
        _petExp = exp;
        return;
      }
      setState(() {
        _petName = name;
        _petLevel = level;
        _petExp = exp;
      });
    } catch (_) {
      // Best-effort.
    }
  }

  void _startWanderTimer() {
    _wanderTimer?.cancel();
    _wanderTimer = Timer.periodic(
      _wanderCheckInterval,
      (_) => _maybeTriggerWander(),
    );
  }

  void _startPetTickTimer() {
    _petTickTimer?.cancel();
    _petTickTimer = Timer.periodic(_petTickInterval, (_) {
      unawaited(_tickPetState());
    });
  }

  Future<void> _tickPetState() async {
    if (_showRoomSelection) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) {
        return;
      }
      await Supabase.instance.client.rpc(
        'tick_pet_state',
        params: {
          'p_pet_id': petId,
          'p_now': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (_) {
      // Best-effort. This periodic tick should not disrupt the UI.
    }
  }

  DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  void _maybeTriggerWander() {
    if (!mounted || _isDraggingPet) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastInteractionAt) < _idleThreshold) {
      return;
    }
    if (now.difference(_lastWanderAt) < _wanderCooldown) {
      return;
    }
    final fieldSize = _petFieldSize();
    if (fieldSize == null || fieldSize.isEmpty) {
      return;
    }
    final target = Offset(
      0.02 + _random.nextDouble() * 0.96,
      0.08 + _random.nextDouble() * 0.84,
    );
    _lastWanderAt = now;
    _animatePetTo(target, fieldSize, userInitiated: false);
  }

  void _markUserInteraction() {
    _lastInteractionAt = DateTime.now();
  }

  Size? _petFieldSize() {
    final context = _petFieldKey.currentContext;
    if (context == null) {
      return null;
    }
    final box = context.findRenderObject() as RenderBox?;
    return box?.size;
  }

  Offset _currentPetNormalized() {
    if (_petMoveController.isAnimating && _petMoveAnimation != null) {
      return _petMoveAnimation!.value;
    }
    return _petNormalizedPosition;
  }

  Offset _positionFromNormalized(Offset normalized, Size fieldSize) {
    final maxX = max(0.0, fieldSize.width - _petAvatarSize.width);
    final maxY = max(0.0, fieldSize.height - _petAvatarSize.height);
    return Offset(normalized.dx * maxX, normalized.dy * maxY);
  }

  Offset _normalizedFromTopLeft(Offset topLeft, Size fieldSize) {
    final maxX = max(0.0, fieldSize.width - _petAvatarSize.width);
    final maxY = max(0.0, fieldSize.height - _petAvatarSize.height);
    final normalizedX = maxX == 0 ? 0.0 : topLeft.dx / maxX;
    final normalizedY = maxY == 0 ? 0.0 : topLeft.dy / maxY;
    return Offset(normalizedX, normalizedY);
  }

  Offset _clampTopLeft(Offset topLeft, Size fieldSize) {
    final maxX = max(0.0, fieldSize.width - _petAvatarSize.width);
    final maxY = max(0.0, fieldSize.height - _petAvatarSize.height);
    final clampedX = topLeft.dx.clamp(0.0, maxX);
    final clampedY = topLeft.dy.clamp(0.0, maxY);
    return Offset(clampedX, clampedY);
  }

  Offset _clampNormalized(Offset normalized) {
    final clampedX = normalized.dx.clamp(0.0, 1.0);
    final clampedY = normalized.dy.clamp(0.0, 1.0);
    return Offset(clampedX, clampedY);
  }

  Duration _durationForDistance(double distance) {
    final rawMs = (distance / _petMoveSpeed * 1000).round();
    return Duration(milliseconds: max(_minMoveMs, rawMs));
  }

  void _updateFacing(Offset from, Offset to, Size fieldSize) {
    final fromPx = _positionFromNormalized(from, fieldSize);
    final toPx = _positionFromNormalized(to, fieldSize);
    final dx = toPx.dx - fromPx.dx;
    if (dx.abs() < 1) {
      return;
    }
    _petFacingRight = dx > 0;
  }

  void _animatePetTo(
    Offset targetNormalized,
    Size fieldSize, {
    bool userInitiated = true,
  }) {
    final clampedTarget = _clampNormalized(targetNormalized);
    final current = _currentPetNormalized();
    final currentPx = _positionFromNormalized(current, fieldSize);
    final targetPx = _positionFromNormalized(clampedTarget, fieldSize);
    _updateFacing(current, clampedTarget, fieldSize);
    _petMoveController.stop();
    _petMoveController.duration = _durationForDistance(
      (targetPx - currentPx).distance,
    );
    _petMoveAnimation = Tween<Offset>(begin: current, end: clampedTarget)
        .animate(
          CurvedAnimation(
            parent: _petMoveController,
            curve: Curves.easeOutCubic,
          ),
        );
    _petNormalizedTarget = clampedTarget;
    if (userInitiated) {
      _markUserInteraction();
    }
    _petIsMoving = true;
    _petMoveController.forward(from: 0);
    setState(() {});
  }

  void _handlePetFieldTap(Offset localPosition, Size fieldSize) {
    final desiredTopLeft =
        localPosition -
        Offset(_petAvatarSize.width / 2, _petAvatarSize.height / 2);
    final clampedTopLeft = _clampTopLeft(desiredTopLeft, fieldSize);
    final normalizedTarget = _normalizedFromTopLeft(clampedTopLeft, fieldSize);
    _animatePetTo(normalizedTarget, fieldSize);
  }

  Offset? _globalToPetField(Offset globalPosition) {
    final context = _petFieldKey.currentContext;
    if (context == null) {
      return null;
    }
    final box = context.findRenderObject() as RenderBox?;
    return box?.globalToLocal(globalPosition);
  }

  void _handlePetDragStart(DragStartDetails details, Size fieldSize) {
    final localPosition = _globalToPetField(details.globalPosition);
    if (localPosition == null) {
      return;
    }
    _markUserInteraction();
    final current = _currentPetNormalized();
    _petMoveController.stop();
    _petNormalizedPosition = current;
    final currentTopLeft = _positionFromNormalized(
      _petNormalizedPosition,
      fieldSize,
    );
    _dragOffset = localPosition - currentTopLeft;
    setState(() {
      _isDraggingPet = true;
      _petIsMoving = true;
    });
  }

  void _handlePetDragUpdate(DragUpdateDetails details, Size fieldSize) {
    final localPosition = _globalToPetField(details.globalPosition);
    if (localPosition == null) {
      return;
    }
    _markUserInteraction();
    final desiredTopLeft = localPosition - _dragOffset;
    final clampedTopLeft = _clampTopLeft(desiredTopLeft, fieldSize);
    final normalized = _normalizedFromTopLeft(clampedTopLeft, fieldSize);
    _updateFacing(_petNormalizedPosition, normalized, fieldSize);
    setState(() {
      _petNormalizedPosition = normalized;
    });
  }

  void _handlePetDragEnd() {
    if (!_isDraggingPet) {
      return;
    }
    setState(() {
      _isDraggingPet = false;
      _petIsMoving = false;
      _selectNextPetStationaryState();
    });
  }

  void _handlePetDragCancel() {
    if (!_isDraggingPet) {
      return;
    }
    setState(() {
      _isDraggingPet = false;
      _petIsMoving = false;
      _selectNextPetStationaryState();
    });
  }

  void _selectNextPetStationaryState() {
    // Cat-like polyphasic sleep: sleep a lot, but not only at night.
    // We approximate "12-16 hours/day" by using higher sleep probability
    // during late night + midday, with crepuscular awake windows.
    final sleepProbability = _sleepProbabilityForLocalHour(DateTime.now().hour);
    _petStationaryState = _random.nextDouble() < sleepProbability
        ? _PetStationaryState.sleeping
        : _PetStationaryState.staying;
  }

  double _sleepProbabilityForLocalHour(int hour) {
    // hour: 0-23
    // Targets ~13-14h/day of sleep when mostly stationary.
    // Crepuscular: more awake at dawn/dusk.
    if (hour >= 22 || hour <= 4) {
      return 0.75;
    }
    if (hour >= 11 && hour <= 16) {
      return 0.65;
    }
    if ((hour >= 5 && hour <= 7) || (hour >= 18 && hour <= 20)) {
      return 0.30;
    }
    return 0.50;
  }

  List<_PlacedFurniture> _activeFurnitureForRoom() {
    final roomId = _roomId;
    if (roomId == null) {
      return const [];
    }
    return _placedFurnitureByRoom.putIfAbsent(roomId, () => []);
  }

  int _placedCountForItem(String itemId) {
    final placed = _activeFurnitureForRoom();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return placed
        .where((item) => item.itemId == itemId && item.ownerUserId == userId)
        .length;
  }

  int _availableFurnitureCount(String itemId) {
    final owned = _furnitureInventory[itemId] ?? 0;
    final placed = _placedCountForItem(itemId);
    return max(0, owned - placed);
  }

  Future<void> _loadFurnitureInventory() async {
    if (_furnitureLoading) {
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _furnitureError = AppLocalizations.of(context)!.storeSignInPrompt;
      });
      return;
    }

    setState(() {
      _furnitureLoading = true;
      _furnitureError = null;
    });

    try {
      final itemsResponse = await Supabase.instance.client
          .from('items')
          .select('id,sku,type,name,price_coins,price_usd,metadata,is_active')
          .eq('is_active', true);
      final inventoryResponse = await Supabase.instance.client
          .from('inventories')
          .select('item_id,quantity')
          .eq('user_id', userId);

      final items = (itemsResponse as List<dynamic>)
          .map((row) => StoreItem.fromJson(row as Map<String, dynamic>))
          .where((item) => item.isFurniture)
          .toList(growable: false);

      final inventory = <String, int>{};
      for (final row in inventoryResponse as List<dynamic>) {
        final itemId = row['item_id'] as String?;
        final quantity = row['quantity'] as int?;
        if (itemId != null && quantity != null) {
          inventory[itemId] = quantity;
        }
      }

      setState(() {
        _furnitureCatalog
          ..clear()
          ..addEntries(items.map((item) => MapEntry(item.id, item)));
        _furnitureInventory
          ..clear()
          ..addAll(inventory);
      });
    } catch (error) {
      setState(() {
        _furnitureError = AppLocalizations.of(
          context,
        )!.storeLoadFailed(error.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _furnitureLoading = false);
      }
    }
  }

  Future<void> _loadRoomFurniture(String roomId) async {
    try {
      final response = await Supabase.instance.client
          .from('room_furniture')
          .select(
            'id,item_id,owner_user_id,position_x,position_y,items(metadata)',
          )
          .eq('room_id', roomId);

      final placed = <_PlacedFurniture>[];
      for (final row in response as List<dynamic>) {
        final record = row as Map<String, dynamic>;
        final id = record['id'] as String?;
        final itemId = record['item_id'] as String?;
        if (id == null || itemId == null) {
          continue;
        }
        final ownerUserId = record['owner_user_id'] as String?;
        final posX = (record['position_x'] as num?)?.toDouble() ?? 0;
        final posY = (record['position_y'] as num?)?.toDouble() ?? 0;
        final emoji = _resolveFurnitureEmoji(itemId, record);
        placed.add(
          _PlacedFurniture(
            id: id,
            itemId: itemId,
            ownerUserId: ownerUserId,
            emoji: emoji,
            normalizedPosition: Offset(posX, posY),
            isPending: false,
          ),
        );
      }

      if (!mounted || _roomId != roomId) {
        return;
      }
      setState(() {
        _placedFurnitureByRoom[roomId] = placed;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _furnitureError = AppLocalizations.of(
            context,
          )!.storeLoadFailed(error.toString());
        });
      }
    }
  }

  void _subscribeToFurniture(String roomId) {
    if (_furnitureSubscriptionRoomId == roomId) {
      return;
    }

    _furnitureChannel?.unsubscribe();
    _furnitureSubscriptionRoomId = roomId;

    final channel = Supabase.instance.client.channel('room_furniture_$roomId');
    _furnitureChannel = channel;

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_furniture',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) => _applyFurnitureRecord(payload.newRecord),
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'room_furniture',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) => _applyFurnitureRecord(payload.newRecord),
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'room_furniture',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) => _removeFurnitureRecord(payload.oldRecord),
    );

    channel.subscribe();
  }

  void _applyFurnitureRecord(Map<String, dynamic> record) {
    if (!mounted || record.isEmpty) {
      return;
    }
    final roomId = record['room_id'] as String?;
    final id = record['id'] as String?;
    final itemId = record['item_id'] as String?;
    if (roomId == null || id == null || itemId == null) {
      return;
    }

    final ownerUserId = record['owner_user_id'] as String?;
    final posX = (record['position_x'] as num?)?.toDouble() ?? 0;
    final posY = (record['position_y'] as num?)?.toDouble() ?? 0;
    final emoji = _resolveFurnitureEmoji(itemId, record);
    final list = _placedFurnitureByRoom.putIfAbsent(roomId, () => []);
    final index = list.indexWhere((item) => item.id == id);

    if (index >= 0) {
      setState(() {
        list[index]
          ..itemId = itemId
          ..ownerUserId = ownerUserId
          ..emoji = emoji
          ..normalizedPosition = Offset(posX, posY)
          ..isPending = false;
      });
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null && ownerUserId == userId) {
      final pendingIndex = list.indexWhere(
        (item) =>
            item.isPending &&
            item.itemId == itemId &&
            (item.normalizedPosition - Offset(posX, posY)).distance < 0.02,
      );
      if (pendingIndex >= 0) {
        setState(() {
          list[pendingIndex]
            ..id = id
            ..ownerUserId = ownerUserId
            ..emoji = emoji
            ..normalizedPosition = Offset(posX, posY)
            ..isPending = false;
        });
        return;
      }
    }

    setState(() {
      list.add(
        _PlacedFurniture(
          id: id,
          itemId: itemId,
          ownerUserId: ownerUserId,
          emoji: emoji,
          normalizedPosition: Offset(posX, posY),
          isPending: false,
        ),
      );
    });
  }

  void _removeFurnitureRecord(Map<String, dynamic> record) {
    if (!mounted || record.isEmpty) {
      return;
    }
    final roomId = record['room_id'] as String?;
    final id = record['id'] as String?;
    if (roomId == null || id == null) {
      return;
    }
    final list = _placedFurnitureByRoom[roomId];
    if (list == null) {
      return;
    }
    setState(() {
      list.removeWhere((item) => item.id == id);
    });
  }

  String _resolveFurnitureEmoji(String itemId, Map<String, dynamic> record) {
    final item = _furnitureCatalog[itemId];
    if (item?.emoji != null && item!.emoji!.isNotEmpty) {
      return item.emoji!;
    }
    final itemData = record['items'] as Map<String, dynamic>?;
    final metadata = (itemData?['metadata'] as Map?)?.cast<String, dynamic>();
    final emoji = metadata?['emoji'] as String?;
    return (emoji != null && emoji.isNotEmpty) ? emoji : '🪑';
  }

  void _openFurnitureInventory() {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    setState(() => _furnitureMode = true);
    _furnitureWiggleController.repeat(reverse: true);
    unawaited(_loadFurnitureInventory());
    unawaited(_loadRoomFurniture(roomId));
  }

  void _closeFurnitureInventory() {
    setState(() {
      _furnitureMode = false;
      _selectedFurnitureItemId = null;
    });
    _furnitureWiggleController.stop();
    _furnitureWiggleController.value = 0;
  }

  void _placeFurnitureAt(Offset localPosition, Size fieldSize) {
    final itemId = _selectedFurnitureItemId;
    if (itemId == null) {
      return;
    }
    final item = _furnitureCatalog[itemId];
    if (item == null) {
      return;
    }
    if (_availableFurnitureCount(itemId) <= 0) {
      return;
    }

    final desiredTopLeft =
        localPosition -
        Offset(_furnitureItemSize.width / 2, _furnitureItemSize.height / 2);
    final clampedTopLeft = _clampTopLeftSized(
      desiredTopLeft,
      fieldSize,
      _furnitureItemSize,
    );
    // Store normalized coordinates (0..1) so layout stays consistent across sizes.
    final normalized = _normalizedFromTopLeftSized(
      clampedTopLeft,
      fieldSize,
      _furnitureItemSize,
    );

    final placed = _PlacedFurniture(
      id: 'f_${_furnitureInstanceSeed++}',
      itemId: itemId,
      ownerUserId: Supabase.instance.client.auth.currentUser?.id,
      emoji: item.emoji ?? '🪑',
      normalizedPosition: normalized,
      isPending: true,
    );

    setState(() {
      _activeFurnitureForRoom().add(placed);
    });
    unawaited(_persistFurniturePlacement(placed));
  }

  void _autoPlaceFurnitureFromInventory(String itemId) {
    final fieldSize = _petFieldSize();
    if (fieldSize == null) {
      return;
    }
    final jitterX = (_random.nextDouble() - 0.5) * 40;
    final jitterY = (_random.nextDouble() - 0.5) * 40;
    final center = Offset(
      fieldSize.width / 2 + jitterX,
      fieldSize.height / 2 + jitterY,
    );
    _placeFurnitureAt(center, fieldSize);
  }

  void _moveFurniture(
    _PlacedFurniture item,
    DragUpdateDetails details,
    Size fieldSize,
  ) {
    final currentTopLeft = _positionFromNormalizedSized(
      item.normalizedPosition,
      fieldSize,
      _furnitureItemSize,
    );
    final desiredTopLeft = currentTopLeft + details.delta;
    final clampedTopLeft = _clampTopLeftSized(
      desiredTopLeft,
      fieldSize,
      _furnitureItemSize,
    );
    // Store normalized coordinates (0..1) so layout stays consistent across sizes.
    final normalized = _normalizedFromTopLeftSized(
      clampedTopLeft,
      fieldSize,
      _furnitureItemSize,
    );
    setState(() {
      item.normalizedPosition = normalized;
    });
  }

  void _handleFurnitureDragEnd(_PlacedFurniture item) {
    unawaited(_persistFurniturePosition(item));
  }

  Offset _positionFromNormalizedSized(
    Offset normalized,
    Size fieldSize,
    Size itemSize,
  ) {
    final maxX = max(0.0, fieldSize.width - itemSize.width);
    final maxY = max(0.0, fieldSize.height - itemSize.height);
    return Offset(normalized.dx * maxX, normalized.dy * maxY);
  }

  Offset _normalizedFromTopLeftSized(
    Offset topLeft,
    Size fieldSize,
    Size itemSize,
  ) {
    final maxX = max(0.0, fieldSize.width - itemSize.width);
    final maxY = max(0.0, fieldSize.height - itemSize.height);
    final normalizedX = maxX == 0 ? 0.0 : topLeft.dx / maxX;
    final normalizedY = maxY == 0 ? 0.0 : topLeft.dy / maxY;
    return Offset(normalizedX, normalizedY);
  }

  Offset _clampTopLeftSized(Offset topLeft, Size fieldSize, Size itemSize) {
    final maxX = max(0.0, fieldSize.width - itemSize.width);
    final maxY = max(0.0, fieldSize.height - itemSize.height);
    final clampedX = topLeft.dx.clamp(0.0, maxX);
    final clampedY = topLeft.dy.clamp(0.0, maxY);
    return Offset(clampedX, clampedY);
  }

  Future<void> _persistFurniturePlacement(_PlacedFurniture item) async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    try {
      final response = await Supabase.instance.client
          .rpc(
            'place_room_furniture',
            params: {
              'p_room_id': roomId,
              'p_item_id': item.itemId,
              'p_position_x': item.normalizedPosition.dx,
              'p_position_y': item.normalizedPosition.dy,
            },
          )
          .single();

      final newId = response['id'] as String?;
      if (!mounted) {
        return;
      }
      setState(() {
        final list = _activeFurnitureForRoom();
        final index = list.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) {
          list[index]
            ..id = newId ?? list[index].id
            ..ownerUserId = response['owner_user_id'] as String?
            ..isPending = false;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _activeFurnitureForRoom().removeWhere((entry) => entry.id == item.id);
        _furnitureError = AppLocalizations.of(
          context,
        )!.storePurchaseFailed(error.toString());
      });
    }
  }

  Future<void> _persistFurniturePosition(_PlacedFurniture item) async {
    if (item.isPending) {
      return;
    }
    try {
      await Supabase.instance.client.rpc(
        'update_room_furniture_position',
        params: {
          'p_id': item.id,
          'p_position_x': item.normalizedPosition.dx,
          'p_position_y': item.normalizedPosition.dy,
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _furnitureError = AppLocalizations.of(
            context,
          )!.storeLoadFailed(error.toString());
        });
      }
      final roomId = _roomId;
      if (roomId != null) {
        unawaited(_loadRoomFurniture(roomId));
      }
    }
  }

  Future<void> _removeFurniture(_PlacedFurniture item) async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    setState(() {
      _activeFurnitureForRoom().removeWhere((entry) => entry.id == item.id);
    });

    if (item.isPending) {
      return;
    }

    try {
      await Supabase.instance.client.rpc(
        'remove_room_furniture',
        params: {'p_id': item.id},
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _furnitureError = AppLocalizations.of(
            context,
          )!.storeLoadFailed(error.toString());
        });
      }
      unawaited(_loadRoomFurniture(roomId));
    }
  }

  Widget _buildPetHomeCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldSize = constraints.biggest;
        return GestureDetector(
          key: _petFieldKey,
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            if (_furnitureMode) {
              _closeFurnitureInventory();
              return;
            }
            _handlePetFieldTap(details.localPosition, fieldSize);
          },
          child: Stack(
            children: [
              ..._buildPlacedFurniture(fieldSize),
              for (final spot in _poopSpots())
                Positioned(
                  left: _positionFromNormalizedSized(
                    spot.normalized,
                    fieldSize,
                    _poopEmojiSize,
                  ).dx,
                  top: _positionFromNormalizedSized(
                    spot.normalized,
                    fieldSize,
                    _poopEmojiSize,
                  ).dy,
                  child: _buildPoopEmoji(spot.index),
                ),
              AnimatedBuilder(
                animation: _petMoveController,
                builder: (context, child) {
                  final normalized = _currentPetNormalized();
                  final topLeft = _positionFromNormalized(
                    normalized,
                    fieldSize,
                  );
                  return Positioned(
                    left: topLeft.dx,
                    top: topLeft.dy,
                    child: child!,
                  );
                },
                child: _buildDraggablePet(fieldSize),
              ),
              if (_furnitureMode)
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: _buildFurnitureEditHint(),
                ),
            ],
          ),
        );
      },
    );
  }

  List<_PoopSpot> _poopSpots() {
    final raw = _petState?['poop_positions'];
    final spots = <_PoopSpot>[];
    if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final entry = raw[i];
        if (entry is Map) {
          final x = (entry['x'] as num?)?.toDouble();
          final y = (entry['y'] as num?)?.toDouble();
          if (x == null || y == null) {
            continue;
          }
          spots.add(
            _PoopSpot(
              index: i,
              normalized: Offset(x.clamp(0.05, 0.95), y.clamp(0.05, 0.95)),
            ),
          );
        }
      }
    }
    if (spots.isEmpty) {
      final poopAt = _parseOptionalDate(_petState?['poop_at'])?.toUtc();
      if (poopAt != null && !poopAt.isAfter(DateTime.now().toUtc())) {
        spots.add(const _PoopSpot(index: 0, normalized: Offset(0.62, 0.72)));
      }
    }
    return spots;
  }

  Widget _buildPoopEmoji(int index) {
    return IgnorePointer(
      ignoring: _petBusy,
      child: GestureDetector(
        onTap: _petBusy ? null : () => unawaited(_cleanPoopAt(index)),
        child: const Text('💩', style: TextStyle(fontSize: 24)),
      ),
    );
  }

  Future<void> _cleanPoopAt(int index) async {
    final roomId = _roomId;
    if (roomId == null) return;

    setState(() {
      _petBusy = true;
      _petError = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) return;

      // clean_poop returns a table with poop_count and coins_awarded
      final result = await Supabase.instance.client.rpc(
        'clean_poop',
        params: {'p_pet_id': petId, 'p_poop_index': index},
      );

      // Extract coins_awarded from the result
      int actualReward = 0;
      if (result is List && result.isNotEmpty) {
        actualReward = (result[0]['coins_awarded'] as int?) ?? 0;
      } else if (result is Map) {
        actualReward = (result['coins_awarded'] as int?) ?? 0;
      }

      // Refresh state and rewards immediately after clean action
      await _refreshPetState();
      await _loadCoins(expectedReward: actualReward);
      await _loadPetInfo(petId);
    } catch (error) {
      setState(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(error.toString()),
      );
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }
  }

  Widget _buildDraggablePet(Size fieldSize) {
    return IgnorePointer(
      ignoring: _furnitureMode,
      child: GestureDetector(
        onPanStart: (details) => _handlePetDragStart(details, fieldSize),
        onPanUpdate: (details) => _handlePetDragUpdate(details, fieldSize),
        onPanEnd: (_) => _handlePetDragEnd(),
        onPanCancel: _handlePetDragCancel,
        child: JuicyScaleButton(
          onTap: _petBusy
              ? null
              : () {
                  _markUserInteraction();
                  _applyPetAction('touch');
                },
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(
              _petFacingRight ? 1.0 : -1.0,
              1.0,
              1.0,
            ),
            child: Transform.scale(scale: 0.88, child: _buildPetAvatar()),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlacedFurniture(Size fieldSize) {
    final placed = _activeFurnitureForRoom();
    if (placed.isEmpty) {
      return const [];
    }
    return [
      for (final item in placed)
        Positioned(
          left: _positionFromNormalizedSized(
            item.normalizedPosition,
            fieldSize,
            _furnitureItemSize,
          ).dx,
          top: _positionFromNormalizedSized(
            item.normalizedPosition,
            fieldSize,
            _furnitureItemSize,
          ).dy,
          child: _buildFurniturePiece(item, fieldSize),
        ),
    ];
  }

  Widget _buildFurniturePiece(_PlacedFurniture item, Size fieldSize) {
    final canEdit = _furnitureMode;
    return GestureDetector(
      onLongPress: _openFurnitureInventory,
      onTap: canEdit ? () {} : null,
      onPanUpdate: canEdit
          ? (details) => _moveFurniture(item, details, fieldSize)
          : null,
      onPanEnd: canEdit ? (_) => _handleFurnitureDragEnd(item) : null,
      child: AnimatedBuilder(
        animation: _furnitureWiggleController,
        builder: (context, child) {
          final angle = canEdit ? _furnitureWiggleAngle(item) : 0.0;
          return Transform.rotate(angle: angle, child: child);
        },
        child: AnimatedContainer(
          duration: 150.ms,
          width: _furnitureItemSize.width,
          height: _furnitureItemSize.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: canEdit
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: canEdit ? Border.all(color: Colors.black12) : null,
            boxShadow: canEdit
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
              ),
              if (canEdit)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Material(
                    color: Colors.redAccent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _removeFurniture(item),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFurnitureEditHint() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        l10n.furnitureEditMode,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  double _furnitureWiggleAngle(_PlacedFurniture item) {
    final phase = (item.id.hashCode % 360) * (pi / 180);
    return sin((_furnitureWiggleController.value * 2 * pi) + phase) * 0.04;
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    if (_loadingRoom) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (_showRoomSelection || _roomId == null) {
      return Scaffold(
        drawer: _buildSideDrawer(),
        body: RoomSelectionView(
          rooms: _myRooms,
          creatingRoom: _creatingRoom,
          joiningRoom: _joiningRoom,
          onCreateRoom: _createRoom,
          onJoinRoom: _joinRoomByCode,
          onSelectRoom: _enterRoomFromSelection,
          selectedRoomId: _roomSelectionId ?? _roomId,
        ),
      );
    }

    return Scaffold(
      drawer: _buildSideDrawer(), // Room List Drawer
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Layer 1: Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFF9E5),
                    Color(0xFFFFECE5),
                  ], // Warm Pudding colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Background Blobs (Floating)
          Positioned(
            bottom: 150,
            left: -20,
            child: JuicyFloat(
              yOffset: 20,
              delay: 500.ms,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 300,
            right: -30,
            child: JuicyFloat(
              yOffset: 30,
              delay: 1000.ms,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    final level = _petLevel ?? 17;
                    final exp = _petExp ?? 0;
                    final expProgressValue = expProgress(
                      level: level,
                      exp: exp,
                    );
                    return HomeGameStatusBar(
                      petAvatar: Image.asset(
                        _petStayGifAsset,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                      expProgress: expProgressValue,
                      level: level,
                      petName: (_petName == null || _petName!.trim().isEmpty)
                          ? '貪吃鬼鬼'
                          : _petName!.trim(),
                      healthValue: _healthValue(),
                      coins: _coins,
                      coinReward: _coinReward,
                      coinRewardEventId: _coinRewardEventId,
                      onPetTap: () => Scaffold.of(context).openDrawer(),
                    );
                  },
                ),
                const Gap(12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: HomePolaroidMemoryFrame(
                        imageUrl: _latestFeedImageUrl ?? '',
                        caption: (_latestFeedCaption ?? '').trim(),
                        userLabel: '',
                        senderAvatar: _latestFeedSenderId == null
                            ? null
                            : _profileByUserId[_latestFeedSenderId!]?.avatarUrl,
                        senderFallbackText: _latestFeedSenderId == null
                            ? null
                            : _profileByUserId[_latestFeedSenderId!]?.nickname,
                        onTap: null,
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildPetHomeCard(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 8, 0, bottomInset + 8),
                  child: HomeBottomNavBar(
                    onHome: _onHomeNavPressed,
                    onCalendar: _openCalendar,
                    onCamera: _openFeedCamera,
                    onStore: _openStoreFromNav,
                    onChat: _openChatRoom,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            child: SafeArea(
              child: IgnorePointer(
                ignoring: !_furnitureMode,
                child: AnimatedSlide(
                  offset: _furnitureMode ? Offset.zero : const Offset(0, -1.1),
                  duration: 220.ms,
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _furnitureMode ? 1 : 0,
                    duration: 160.ms,
                    child: HomeFurnitureInventoryPanel(
                      furnitureCatalog: _furnitureCatalog,
                      furnitureInventory: _furnitureInventory,
                      selectedItemId: _selectedFurnitureItemId,
                      availableCount: _availableFurnitureCount,
                      loading: _furnitureLoading,
                      errorText: _furnitureError,
                      onClose: _closeFurnitureInventory,
                      onItemTap: (itemId) {
                        setState(() => _selectedFurnitureItemId = itemId);
                        _autoPlaceFurnitureFromInventory(itemId);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetAvatar() {
    final petColor = _petMoodColor();

    final String asset;
    if (_petIsMoving) {
      asset = _petWalkGifAsset;
    } else {
      asset = switch (_petStationaryState) {
        _PetStationaryState.staying => _petStayGifAsset,
        _PetStationaryState.sleeping => _petSleepGifAsset,
      };
    }

    return SizedBox(
      width: _petAvatarSize.width,
      height: _petAvatarSize.height,
      child: Image.asset(
        asset,
        key: ValueKey(asset),
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) =>
            _buildPetFallback(petColor),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            return _buildPetFallback(petColor, loading: true);
          }
          return child;
        },
      ),
    );
  }

  Color _petMoodColor() {
    Color petColor = Colors.orangeAccent;
    if (_petState != null) {
      final mood = _petState!['mood'] as String? ?? 'low';
      switch (mood) {
        case 'high':
          petColor = Colors.pinkAccent;
          break;
        case 'mid':
          petColor = Colors.orangeAccent;
          break;
        case 'sad':
          petColor = Colors.blueGrey;
          break;
      }
    }
    return petColor;
  }

  Widget _buildPetFallback(Color petColor, {bool loading = false}) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: petColor.withValues(alpha: 0.6),
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 90, left: 80, child: _buildEye()),
          Positioned(top: 90, right: 80, child: _buildEye()),
          Positioned(
            bottom: 90,
            child: Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
          width: 30,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.all(5),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleY(
          begin: 1.0,
          end: 0.1,
          duration: 200.ms,
          delay: 3000.ms,
          curve: Curves.easeInOut,
        ); // Blink
  }

  Widget _buildSideDrawer() {
    final l10n = AppLocalizations.of(context)!;
    return HomeDrawer(
      rooms: _myRooms,
      currentRoomId: _roomId,
      onNavigateToRoomSelection: () {
        setState(() {
          _roomSelectionId = _roomId;
          _showRoomSelection = true;
          _furnitureMode = false;
          _selectedFurnitureItemId = null;
        });
        Navigator.pop(context);
      },
      onCreateRoom: () {
        Navigator.pop(context);
        _createRoom();
      },
      onJoinRoom: () {
        if (!_joiningRoom) {
          Navigator.pop(context);
          _joinRoomByCode();
        }
      },
      onProfileTap: () {
        Navigator.pop(context);
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileView()));
      },
      onCalendarTap: (roomId) {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryCalendarView(
              roomId: roomId,
              currentUserId: Supabase.instance.client.auth.currentUser?.id,
            ),
          ),
        );
      },
      onStoreTap: () {
        Navigator.pop(context);
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StoreView())).then((_) {
          if (mounted) {
            _loadFurnitureInventory();
          }
        });
      },
      onInventoryTap: () {
        Navigator.pop(context);
        _openFurnitureInventory();
      },
      onSignOut: _signOut,
      debugActions: ExpansionTile(
        leading: const Icon(Icons.bug_report_outlined),
        title: Text(l10n.drawerDebugTools),
        children: [
          ListTile(
            title: Text(l10n.drawerForceRefreshPet),
            onTap: _petBusy ? null : () => _refreshPetState(tick: true),
            trailing: _petBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          ListTile(
            title: Text(l10n.drawerSimulateFeed),
            subtitle: _feedResult == null ? null : Text(_feedResult!),
            onTap: _testingFeed ? null : _runFeedTest,
            trailing: _testingFeed
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          ListTile(
            title: Text(l10n.drawerTestNotification),
            onTap: () => ref.read(fcmServiceProvider).showTestNotification(),
          ),
          if (_petError != null)
            ListTile(
              title: Text(l10n.drawerPetError),
              subtitle: Text(_petError!),
            ),
        ],
      ),
    );
  }
}

class _ProfileSummary {
  const _ProfileSummary({required this.nickname, required this.avatarUrl});

  final String? nickname;
  final String? avatarUrl;
}

class _PlacedFurniture {
  _PlacedFurniture({
    required this.id,
    required this.itemId,
    required this.ownerUserId,
    required this.emoji,
    required this.normalizedPosition,
    required this.isPending,
  });

  String id;
  String itemId;
  String? ownerUserId;
  String emoji;
  Offset normalizedPosition;
  bool isPending;
}

class _PoopSpot {
  const _PoopSpot({required this.index, required this.normalized});

  final int index;
  final Offset normalized;
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
