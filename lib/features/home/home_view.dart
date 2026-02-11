import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/audio/app_sfx.dart';
import '../../services/auth/session_utils.dart';
import '../../services/fcm_service.dart';
import '../../services/settings/app_settings_repository.dart';

import '../../services/label_mapping/label_mapping_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/force_update/force_update_debug_tool.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/juice_wrappers.dart';
import '../../shared/ui/full_screen_photo_viewer.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/status_bar_style.dart';
import '../chat/chat_message.dart';
import '../chat/chat_room_view.dart';
import '../feed/feed_capture_view.dart';
import '../gallery/memory_calendar_view.dart';
import '../pet/pet_catalog.dart';
import '../pet/leveling.dart';
import '../pet/pet_departure.dart';
import '../pet/pet_departure_note_view.dart';
import '../pet/pet_selection_page.dart';
import '../profile/profile_view.dart';
import '../store/store_view.dart';
import 'room_selection_view.dart';
import 'room_backgrounds.dart';
import 'widgets/home_bottom_nav_bar.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_room_inventory_panel.dart';
import 'widgets/home_game_status_bar.dart';
import 'widgets/home_polaroid_memory_frame.dart';
import 'widgets/photo_food.dart';

part 'home_view_models.dart';

enum _PetStationaryState { staying, sleeping }

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _petAvatarSize = Size(100, 100);
  static const _photoFoodSize = Size(82, 82);
  static const int _optimisticFeedRewardCoins = 10;
  static const Duration _localFeedCooldownFallback = Duration(minutes: 10);
  static const double _petMoveSpeed = 30;
  static const int _minMoveMs = 260;
  static const Duration _foodDropDuration = Duration(milliseconds: 760);
  static const Duration _foodBiteStepDuration = Duration(milliseconds: 280);
  static const Duration _idleThreshold = Duration(seconds: 8);
  static const Duration _wanderCooldown = Duration(seconds: 7);
  static const Duration _wanderCheckInterval = Duration(seconds: 4);
  static const Duration _petTickInterval = Duration(minutes: 5);
  static const Duration _roomSelectionRefreshInterval = Duration(seconds: 45);
  static const _furnitureItemSize = Size(42, 42);
  static const _poopEmojiSize = Size(28, 28);

  // Logic State
  bool _profileEnsured = false;
  bool _creatingRoom = false;
  bool _joiningRoom = false;
  bool _leavingRoom = false;
  bool _testingFeed = false;
  bool _loadingRoom = true;
  bool _showRoomSelection = true;
  String? _roomSelectionId;
  String? _roomId;
  String? _feedResult;
  String? _petId;
  String _petType = PetCatalog.defaultPetId;
  bool _petBusy = false;
  Map<String, dynamic>? _petState;
  bool _petStateReady = false;
  bool _petDeparted = false;
  bool _petDeparturePrompted = false;
  String? _lastDeparturePetId;
  final Map<String, DepartedPetInfo> _departedPetsByRoom = {};
  final Map<String, Map<String, dynamic>> _petStateByRoom = {};
  final Map<String, String> _petIdByRoom = {};
  String? _petError;
  DateTime? _lastOverfedAt;
  bool _showOverfedBubble = false;
  Timer? _overfedBubbleTimer;
  String? _petName;
  int? _petLevel;
  int? _petExp;
  int _coins = 1234;
  int _diamonds = 0;
  bool _debugProPlan = false;
  String? _myAvatarUrl;
  String? _myNickname;
  int? _coinReward; // Triggers coin animation when set
  int _coinRewardEventId = 0;
  bool _coinsLoadInFlight = false;
  int? _pendingCoinsExpectedReward;
  bool _roomSelectionRefreshInFlight = false;
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
  Timer? _roomSelectionRefreshTimer;
  bool _petAssetsPrecached = false;
  final Set<String> _cachedPetAssets = {};
  static const int _petNameMaxLength = 20;
  static const int _freePlanRoomLimit = 2;
  bool _inviteCodeLoading = false;
  bool _showNewRoomInvitePrompt = false;
  String? _newRoomInviteRoomId;

  // Furniture State
  bool _furnitureMode = false;
  bool _furnitureLoading = false;
  String? _furnitureError;
  String? _selectedFurnitureItemId;
  int _furnitureInstanceSeed = 0;
  final Map<String, StoreItem> _furnitureCatalog = {};
  final Map<String, int> _furnitureInventory = {};
  final Map<String, List<_PlacedFurniture>> _placedFurnitureByRoom = {};

  // Background State
  bool _backgroundLoading = false;
  String? _backgroundError;
  String? _backgroundApplyingItemId;
  final Map<String, List<StoreItem>> _ownedBackgroundsByRoom = {};
  final Map<String, String?> _activeBackgroundByRoom = {};
  RealtimeChannel? _backgroundStateChannel;
  RealtimeChannel? _backgroundInventoryChannel;
  String? _backgroundSubscriptionRoomId;
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
  final Map<String, String> _optimisticFeedImageByTempId = {};
  final Map<String, String> _optimisticFeedRoomByTempId = {};
  final Map<String, int> _optimisticFeedCoinsByTempId = {};
  final Map<String, _LocalFeedCooldown> _localFeedCooldownByRoom = {};
  String? _photoFoodImageSource;
  Offset? _photoFoodNormalizedPosition;
  bool _photoFoodDropping = false;
  int _photoFoodBiteStage = 0;
  bool _petEating = false;
  int _feedingAnimationToken = 0;
  final Map<String, _ProfileSummary> _profileByUserId = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _debugProPlan = AppSettingsRepository.instance.debugProPlanEnabled;
    _selectNextPetStationaryState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_profileEnsured) {
        unawaited(() async {
          await _ensureProfile();
          await _loadCoins();
          await _fetchRooms();
          if (mounted && _showRoomSelection) {
            await _refreshRoomSelectionHealthBars();
          }
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
    _startRoomSelectionRefreshTimer();

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
    for (final pet in PetCatalog.pets) {
      _precachePetAssets(pet);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _petStateChannel?.unsubscribe();
    _furnitureChannel?.unsubscribe();
    _backgroundStateChannel?.unsubscribe();
    _backgroundInventoryChannel?.unsubscribe();
    _overfedBubbleTimer?.cancel();
    for (final channel in _messageChannels.values) {
      channel.unsubscribe();
    }
    _messageChannels.clear();
    _wanderTimer?.cancel();
    _petTickTimer?.cancel();
    _roomSelectionRefreshTimer?.cancel();
    _feedingAnimationToken++;
    _petMoveController.dispose();
    _furnitureWiggleController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    if (!_showRoomSelection) {
      return;
    }
    unawaited(_refreshRoomSelectionHealthBars());
  }

  void _precachePetAssets(PetDefinition pet) {
    for (final asset in PetCatalog.assetPaths(pet)) {
      if (_cachedPetAssets.add(asset)) {
        precacheImage(AssetImage(asset), context);
      }
    }
  }

  void _updatePetType(String? petType) {
    final resolved = PetCatalog.resolveId(petType);
    if (!mounted) {
      _petType = resolved;
      return;
    }
    if (resolved == _petType) {
      return;
    }
    setState(() {
      _petType = resolved;
    });
    _precachePetAssets(PetCatalog.byId(resolved));
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
          .select('coins,diamonds,avatar_url,nickname')
          .eq('user_id', user.id)
          .maybeSingle();
      final newValue = (profile?['coins'] as int?) ?? _coins;
      final newDiamonds = (profile?['diamonds'] as int?) ?? _diamonds;
      final newAvatarUrl = profile?['avatar_url'] as String?;
      final newNickname = profile?['nickname'] as String?;
      final oldValue = _coins;
      if (!mounted) {
        _coins = newValue;
        _diamonds = newDiamonds;
        return;
      }

      int? rewardEventIdToClear;
      setState(() {
        _coins = newValue;
        _diamonds = newDiamonds;
        _myAvatarUrl = newAvatarUrl;
        _myNickname = newNickname;

        // Clear any stale reward when this load is expected to represent a
        // reward event (including cooldown/no-op cases).
        if (expectedReward != null) {
          _coinReward = null;
        }

        // Trigger animation for reward-expected loads only when the balance
        // actually increased (cooldown/no-op stays quiet).
        if (expectedReward != null && newValue > oldValue) {
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

  Future<void> _debugUpdateProfileBalances({
    int coinDelta = 0,
    int diamondDelta = 0,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    if (coinDelta == 0 && diamondDelta == 0) {
      return;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('coins,diamonds')
          .eq('user_id', userId)
          .maybeSingle();
      if (profile == null) {
        return;
      }
      final currentCoins = (profile['coins'] as int?) ?? _coins;
      final currentDiamonds = (profile['diamonds'] as int?) ?? _diamonds;
      final updates = <String, dynamic>{};
      if (coinDelta != 0) {
        updates['coins'] = max(0, currentCoins + coinDelta);
      }
      if (diamondDelta != 0) {
        updates['diamonds'] = max(0, currentDiamonds + diamondDelta);
      }
      if (updates.isEmpty) {
        return;
      }
      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('user_id', userId);
      unawaited(_loadCoins(expectedReward: coinDelta > 0 ? coinDelta : null));
    } catch (_) {
      // Best-effort debug tool.
    }
  }

  int _extractRewardAmount(dynamic payload) {
    if (payload == null) {
      return 0;
    }
    if (payload is int) {
      return payload;
    }
    if (payload is num) {
      return payload.round();
    }
    if (payload is String) {
      return int.tryParse(payload) ?? 0;
    }
    if (payload is List) {
      if (payload.isEmpty) {
        return 0;
      }
      return _extractRewardAmount(payload.first);
    }
    if (payload is Map) {
      final dynamic row = payload['coins_awarded'] ?? payload['reward'];
      return _extractRewardAmount(row);
    }
    return 0;
  }

  Future<void> _debugAdjustPetHunger(int delta) async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
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
      final row = await Supabase.instance.client
          .from('pet_state')
          .select('hunger')
          .eq('pet_id', petId)
          .maybeSingle();
      final current = (row?['hunger'] as int?) ?? 0;
      final next = (current + delta).clamp(0, 100);
      await Supabase.instance.client
          .from('pet_state')
          .update({'hunger': next})
          .eq('pet_id', petId);
      final updatedState = await _fetchPetState(petId);
      _applyPetStateUpdate(roomId, petId, updatedState);
    } catch (error) {
      setState(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(userFacingError(context, error)),
      );
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }
  }

  Future<void> _debugAddPetExp(int delta) async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
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
      final row = await Supabase.instance.client
          .from('pets')
          .select('level, exp')
          .eq('id', petId)
          .maybeSingle();
      final currentLevel = (row?['level'] as int?) ?? (_petLevel ?? 1);
      final currentExp = (row?['exp'] as int?) ?? (_petExp ?? 0);
      final updated = _applyExpDelta(
        level: currentLevel,
        exp: currentExp,
        delta: delta,
      );
      await Supabase.instance.client
          .from('pets')
          .update({'level': updated.level, 'exp': updated.exp})
          .eq('id', petId);
      await _loadPetInfo(petId, roomId: roomId);
    } catch (error) {
      setState(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(userFacingError(context, error)),
      );
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }
  }

  Future<void> _debugSpawnPetPoop() async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
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
      final row = await Supabase.instance.client
          .from('pet_state')
          .select('poop_positions, poop_at')
          .eq('pet_id', petId)
          .maybeSingle();
      final positions = _normalizePoopPositions(row?['poop_positions']);
      if (positions.length < 3) {
        final next = _nextPoopPosition();
        positions.add({'x': next.dx, 'y': next.dy});
      }
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final updates = <String, dynamic>{
        'poop_positions': positions,
        'poop_count': positions.length,
        'last_poop_spawn_at': nowIso,
      };
      if (row?['poop_at'] == null && positions.isNotEmpty) {
        updates['poop_at'] = nowIso;
      }
      await Supabase.instance.client
          .from('pet_state')
          .update(updates)
          .eq('pet_id', petId);
      final updatedState = await _fetchPetState(petId);
      _applyPetStateUpdate(roomId, petId, updatedState);
    } catch (error) {
      setState(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(userFacingError(context, error)),
      );
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchPetState(String petId) async {
    return Supabase.instance.client
        .from('pet_state')
        .select()
        .eq('pet_id', petId)
        .maybeSingle();
  }

  void _cachePetState(String roomId, String petId, Map<String, dynamic> state) {
    _petStateByRoom[roomId] = Map<String, dynamic>.from(state);
    _petIdByRoom[roomId] = petId;
  }

  void _applyPetStateUpdate(
    String roomId,
    String petId,
    Map<String, dynamic>? state,
  ) {
    if (state == null) {
      return;
    }
    _cachePetState(roomId, petId, state);
    _subscribeToPetState(petId);
    final hunger = state['hunger'] as num?;
    final healthValue = _healthValueFromHunger(hunger);
    if (!mounted) {
      _petId = petId;
      _petState = state;
      _petStateReady = true;
      return;
    }
    setState(() {
      _petId = petId;
      _petState = state;
      _petStateReady = true;
      _myRooms = _myRooms
          .map(
            (room) => room['id'] == roomId
                ? {...room, 'pet_health': healthValue}
                : room,
          )
          .toList();
    });
    _handleOverfedState();
    _handlePetDepartureState(roomId: roomId, petId: petId, state: state);
  }

  List<Map<String, double>> _normalizePoopPositions(dynamic raw) {
    final positions = <Map<String, double>>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) {
          final x = (entry['x'] as num?)?.toDouble();
          final y = (entry['y'] as num?)?.toDouble();
          if (x == null || y == null) {
            continue;
          }
          positions.add({
            'x': x.clamp(0.05, 0.95).toDouble(),
            'y': y.clamp(0.05, 0.95).toDouble(),
          });
        }
      }
    }
    return positions;
  }

  Offset _nextPoopPosition() {
    final x = (_random.nextDouble() * 0.6) + 0.2;
    final y = (_random.nextDouble() * 0.4) + 0.55;
    return Offset(x, y);
  }

  _PetExpUpdate _applyExpDelta({
    required int level,
    required int exp,
    required int delta,
  }) {
    var nextLevel = level < 1 ? 1 : level;
    var nextExp = exp < 0 ? 0 : exp;
    nextExp += delta;
    if (nextExp < 0) {
      nextExp = 0;
    }
    while (nextLevel < kMaxPetLevel) {
      final required = xpRequiredForNextLevel(nextLevel);
      if (required <= 0 || nextExp < required) {
        break;
      }
      nextExp -= required;
      nextLevel += 1;
    }
    if (nextLevel >= kMaxPetLevel) {
      nextLevel = kMaxPetLevel;
      nextExp = 0;
    }
    return _PetExpUpdate(level: nextLevel, exp: nextExp);
  }

  Future<void> _setDebugProPlan(bool value) async {
    if (_debugProPlan == value) {
      return;
    }
    setState(() {
      _debugProPlan = value;
      _myRooms = _applyLegacyRoomLocking(_myRooms);
    });
    try {
      await AppSettingsRepository.instance.setDebugProPlanEnabled(value);
    } catch (error) {
      debugPrint('[settings] failed to save debug pro plan: $error');
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
          .select('room_id, role, joined_at, rooms(invite_code, created_at)')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('joined_at', ascending: true);

      final List<Map<String, dynamic>> rooms = [];
      for (final r in responses) {
        final roomData = r['rooms'] as Map<String, dynamic>?;
        if (roomData != null) {
          rooms.add({
            'id': r['room_id'],
            'invite_code': roomData['invite_code'],
            'role': r['role'],
            'joined_at': r['joined_at'],
            'room_created_at': roomData['created_at'],
          });
        }
      }

      final roomIds = rooms
          .map((room) => room['id'])
          .whereType<String>()
          .toList(growable: false);
      final senderIds = <String>{};
      if (roomIds.isNotEmpty) {
        final petSummaries = await _fetchRoomPetSummaries(roomIds);
        final feeds = await _fetchRoomLatestFeeds(roomIds);
        final memberCounts = await _fetchRoomMemberCounts(roomIds);
        for (final room in rooms) {
          final roomId = room['id'] as String?;
          if (roomId != null) {
            room['member_count'] = memberCounts[roomId] ?? 0;
          }
          final summary = roomId == null ? null : petSummaries[roomId];
          if (summary != null) {
            room['pet_type'] = summary.petType;
            room['pet_health'] = summary.healthValue;
            room['pet_name'] = summary.petName;
            room['pet_level'] = summary.petLevel;
          }
          if (roomId != null && feeds.containsKey(roomId)) {
            final latest = feeds[roomId]!;
            if (latest.imageUrls.isNotEmpty) {
              room['latest_photo'] = latest.latestImageUrl;
              room['latest_photos'] = latest.imageUrls;
              room['latest_caption'] = latest.latestCaption;
              room['latest_sender_id'] = latest.latestSenderId;
              final senderId = latest.latestSenderId;
              if (senderId != null && senderId.isNotEmpty) {
                senderIds.add(senderId);
              }
            }
          }
        }
      }

      _syncMessageSubscriptions(roomIds);
      final sortedRooms = _applyLegacyRoomLocking(rooms);

      setState(() {
        _myRooms = sortedRooms;
        if (rooms.isEmpty) {
          _showRoomSelection = true;
          _roomSelectionId = null;
        } else {
          _roomSelectionId ??= _roomId ?? sortedRooms.first['id'] as String?;
        }
      });
      for (final senderId in senderIds) {
        unawaited(_ensureProfileSummary(senderId));
      }

      if (_roomId != null) {}

      if (sortedRooms.isNotEmpty) {
        // If no room selected, or selected room not in list, select first
        if (_roomId == null || !sortedRooms.any((r) => r['id'] == _roomId)) {
          _switchRoom(sortedRooms.first['id'] as String);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingRoom = false);
    }
  }

  int _memberCountForRoom(String roomId) {
    for (final room in _myRooms) {
      if (room['id'] == roomId) {
        final raw = room['member_count'];
        if (raw is int) {
          return raw;
        }
        if (raw is num) {
          return raw.round();
        }
        break;
      }
    }
    return 0;
  }

  bool get _isSoloRoom {
    final roomId = _roomId;
    if (roomId == null) {
      return false;
    }
    return _memberCountForRoom(roomId) <= 1;
  }

  DateTime _legacyRoomSortTimestamp(Map<String, dynamic> room) {
    final joinedAt = DateTime.tryParse(room['joined_at'] as String? ?? '');
    final createdAt = DateTime.tryParse(
      room['room_created_at'] as String? ?? '',
    );
    return joinedAt ??
        createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  List<Map<String, dynamic>> _applyLegacyRoomLocking(
    List<Map<String, dynamic>> rooms,
  ) {
    final sorted = rooms.map((room) => {...room}).toList(growable: false)
      ..sort((a, b) {
        final aTime = _legacyRoomSortTimestamp(a);
        final bTime = _legacyRoomSortTimestamp(b);
        final byTime = aTime.compareTo(bTime);
        if (byTime != 0) {
          return byTime;
        }
        final aId = a['id'] as String? ?? '';
        final bId = b['id'] as String? ?? '';
        return aId.compareTo(bId);
      });

    for (var i = 0; i < sorted.length; i++) {
      sorted[i]['legacy_order_index'] = i;
      sorted[i]['is_locked'] = !_debugProPlan && i >= _freePlanRoomLimit;
    }
    return sorted;
  }

  bool _isRoomLocked(String? roomId) {
    if (roomId == null || _debugProPlan) {
      return false;
    }
    for (final room in _myRooms) {
      if (room['id'] == roomId) {
        return room['is_locked'] == true;
      }
    }
    return false;
  }

  bool get _isCurrentRoomLocked => _isRoomLocked(_roomId);

  Future<void> _showRoomLockedDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showAppDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.roomLockedTitle,
        message: l10n.roomLockedMessage,
        actions: [
          AppDialogAction.primary(
            label: l10n.commonClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  bool get _shouldShowNewRoomInvitePrompt {
    final roomId = _roomId;
    if (roomId == null) {
      return false;
    }
    if (!_showNewRoomInvitePrompt) {
      return false;
    }
    if (_newRoomInviteRoomId != roomId) {
      return false;
    }
    return _isSoloRoom;
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
          await _loadPetInfo(petId, roomId: roomId);
        }
      }());
    }

    if (senderId != null && senderId.isNotEmpty) {
      unawaited(_ensureProfileSummary(senderId));
    }
  }

  void _switchRoom(String roomId, {String? petType}) {
    _feedingAnimationToken++;
    final previousRoom = _roomId;
    final roomSnapshot = _myRooms.cast<Map<String, dynamic>?>().firstWhere(
      (room) => room?['id'] == roomId,
      orElse: () => null,
    );
    final roomPetType = roomSnapshot?['pet_type'] as String?;
    final nextPetType = petType ?? roomPetType ?? PetCatalog.defaultPetId;
    setState(() {
      _roomId = roomId;
      _petState = null;
      _petId = null;
      _petStateReady = false;
      _lastOverfedAt = null;
      _showOverfedBubble = false;
      _petDeparted = false;
      _petDeparturePrompted = false;
      _lastDeparturePetId = null;
      _petName = null;
      _petLevel = null;
      _petExp = null;
      _petType = nextPetType;
      _furnitureMode = false;
      _selectedFurnitureItemId = null;
      _photoFoodImageSource = null;
      _photoFoodNormalizedPosition = null;
      _photoFoodDropping = false;
      _photoFoodBiteStage = 0;
      _petEating = false;
    });
    _overfedBubbleTimer?.cancel();
    _furnitureWiggleController.stop();
    _furnitureWiggleController.value = 0;
    _petStateChannel?.unsubscribe();
    _petStateChannel = null;
    _petSubscriptionPetId = null;
    _furnitureChannel?.unsubscribe();
    _furnitureChannel = null;
    _furnitureSubscriptionRoomId = null;
    _backgroundStateChannel?.unsubscribe();
    _backgroundStateChannel = null;
    _backgroundInventoryChannel?.unsubscribe();
    _backgroundInventoryChannel = null;
    _backgroundSubscriptionRoomId = null;
    _refreshPetState(tick: true);
    unawaited(_refreshLatestFeed(roomId));
    unawaited(_loadFurnitureInventory());
    unawaited(_loadRoomFurniture(roomId));
    _subscribeToFurniture(roomId);
    unawaited(_loadRoomBackgrounds(roomId));
    unawaited(_loadRoomBackgroundState(roomId));
    _subscribeToBackgrounds(roomId);
    if (previousRoom != roomId) {
      AnalyticsService.instance.logEvent('room_switch');
    }
  }

  void _enterRoomFromSelection(String roomId, {String? petType}) {
    if (!_showRoomSelection) {
      _switchRoom(roomId, petType: petType);
      return;
    }
    setState(() {
      _showRoomSelection = false;
      _roomSelectionId = roomId;
    });
    _switchRoom(roomId, petType: petType);
  }

  Future<void> _signOut() async {
    AnalyticsService.instance.logEvent('sign_out_tap');
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _openProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileView()));
    if (!mounted) {
      return;
    }
    await _loadCoins();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await _ensureProfileSummary(userId, forceRefresh: true);
    }
  }

  Future<void> _createRoom() async {
    final l10n = AppLocalizations.of(context)!;
    final reachedFreePlanLimit =
        !_debugProPlan && _myRooms.length >= _freePlanRoomLimit;
    if (reachedFreePlanLimit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.roomLimitReached)));
      return;
    }

    final selectedPet = await Navigator.of(
      context,
    ).push<PetDefinition>(PetSelectionPage.route());
    if (!mounted || selectedPet == null) {
      return;
    }

    final creation = await _promptRoomCreationDetails();
    if (!mounted || creation == null) {
      return;
    }

    setState(() => _creatingRoom = true);
    try {
      final response = await Supabase.instance.client
          .rpc('create_room', params: {'p_name': creation.petName.trim()})
          .single();

      final newId = response['room_id'] as String?;
      if (newId == null) {
        throw Exception('room_id_missing');
      }

      // Refresh list and switch
      await _fetchRooms();
      if (!mounted) {
        return;
      }

      final applied = await _applyPetSelection(newId, selectedPet);
      await _applyInitialPetName(newId, creation.petName);
      if (!mounted) {
        return;
      }
      setState(() {
        _newRoomInviteRoomId = newId;
        _showNewRoomInvitePrompt = true;
      });
      if (applied) {
        _enterRoomFromSelection(newId, petType: selectedPet.id);
      } else {
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
        SnackBar(
          content: Text(l10n.roomCreateFailed(userFacingError(context, error))),
        ),
      );
    } finally {
      if (mounted) setState(() => _creatingRoom = false);
    }
  }

  Future<bool> _applyPetSelection(
    String roomId,
    PetDefinition selectedPet,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final petId = await _loadPetId(roomId);
      if (petId == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.petNotFound)));
        }
        return false;
      }

      await Supabase.instance.client
          .from('pets')
          .update({
            'color_dna': {PetCatalog.colorDnaTypeKey: selectedPet.id},
          })
          .eq('id', petId);

      _updatePetType(selectedPet.id);
      unawaited(_loadPetInfo(petId, roomId: roomId));
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.petSelectionFailed(userFacingError(context, error)),
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _applyInitialPetName(String roomId, String petName) async {
    final trimmed = petName.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    try {
      final petId = await _loadPetId(roomId);
      if (petId == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.petNotFound)));
        }
        return;
      }

      await Supabase.instance.client
          .from('pets')
          .update({'name': trimmed})
          .eq('id', petId);

      if (!mounted) {
        return;
      }
      setState(() {
        if (_petId == petId) {
          _petName = trimmed;
        }
        _myRooms = _myRooms
            .map(
              (entry) => entry['id'] == roomId
                  ? {...entry, 'pet_name': trimmed}
                  : entry,
            )
            .toList(growable: false);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.petNameUpdateFailed(userFacingError(context, error)),
          ),
        ),
      );
    }
  }

  Future<_RoomCreationDetails?> _promptRoomCreationDetails() async {
    return showAppDialog<_RoomCreationDetails>(
      context: context,
      builder: (context) =>
          const _RoomCreationDialog(maxPetNameLength: _petNameMaxLength),
    );
  }

  Future<void> _joinRoomByCode() async {
    if (_joiningRoom) return;

    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final code = await showAppDialog<String>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.roomJoinTitle,
        message: l10n.roomJoinHelper,
        body: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.roomJoinHint),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
          ],
        ),
        actions: [
          AppDialogAction.secondary(
            label: l10n.commonCancel,
            onPressed: () => Navigator.pop(context),
          ),
          AppDialogAction.primary(
            label: l10n.commonJoin,
            onPressed: () {
              // Normalize invite code to uppercase for consistent matching.
              final value = controller.text.trim().toUpperCase();
              Navigator.pop(context, value.isEmpty ? null : value);
            },
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
        SnackBar(
          content: Text(l10n.roomJoinFailed(userFacingError(context, error))),
        ),
      );
    } finally {
      if (mounted) setState(() => _joiningRoom = false);
    }
  }

  String? _extractInviteCode(dynamic response) {
    if (response is String) {
      return response;
    }
    if (response is Map) {
      final value = response.values.isNotEmpty ? response.values.first : null;
      if (value is String) {
        return value;
      }
    }
    if (response is List && response.isNotEmpty) {
      final value = response.first;
      if (value is String) {
        return value;
      }
      if (value is Map) {
        final inner = value.values.isNotEmpty ? value.values.first : null;
        if (inner is String) {
          return inner;
        }
      }
    }
    return null;
  }

  Future<void> _showInviteCodeDialog(String code) async {
    final l10n = AppLocalizations.of(context)!;
    await showAppDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.roomInviteCodeTitle,
        message: l10n.roomInviteCodeMessage,
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black87, width: 1.5),
          ),
          child: Center(
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        actions: [
          AppDialogAction.primary(
            label: l10n.commonClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _generateInviteCode() async {
    if (_inviteCodeLoading) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() => _inviteCodeLoading = true);
    try {
      final response = await Supabase.instance.client.rpc(
        'regenerate_invite_code',
        params: {'p_room_id': roomId},
      );
      final code = _extractInviteCode(response);
      if (code == null || code.isEmpty) {
        throw Exception('invite_code_missing');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _showNewRoomInvitePrompt = false;
        _myRooms = _myRooms
            .map(
              (room) =>
                  room['id'] == roomId ? {...room, 'invite_code': code} : room,
            )
            .toList();
      });
      await _showInviteCodeDialog(code);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.roomInviteCodeRegenerateFailed(
              userFacingError(context, error),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _inviteCodeLoading = false);
    }
  }

  Future<void> _confirmLeaveRoom(String roomId) async {
    if (_leavingRoom) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final room = _myRooms.firstWhere(
      (entry) => entry['id'] == roomId,
      orElse: () => const {},
    );
    final petName = (room['pet_name'] as String?)?.trim();
    final petType = room['pet_type'] as String?;
    final fallbackName = PetCatalog.byId(petType).name(l10n);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.warning,
        title: l10n.roomLeaveTitle,
        message: l10n.roomLeaveMessage(
          petName == null || petName.isEmpty ? fallbackName : petName,
        ),
        actions: [
          AppDialogAction.secondary(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppDialogAction.destructive(
            label: l10n.roomLeaveConfirm,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _leaveRoom(roomId);
    }
  }

  Future<void> _leaveRoom(String roomId, {bool showSnackBar = true}) async {
    if (_leavingRoom) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _leavingRoom = true;
      _showRoomSelection = true;
      if (_roomId == roomId) {
        _roomId = null;
        _roomSelectionId = null;
        _petState = null;
        _petId = null;
      }
    });
    try {
      await Supabase.instance.client.rpc(
        'leave_room',
        params: {'p_room_id': roomId},
      );
      await _fetchRooms();
      if (!mounted) {
        return;
      }
      if (showSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.roomLeaveSuccess)));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.roomLeaveFailed(userFacingError(context, error)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _leavingRoom = false);
      }
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

  Future<Map<String, _RoomPetSummary>> _fetchRoomPetSummaries(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) {
      return {};
    }
    final rows = await Supabase.instance.client
        .from('pets')
        .select('room_id, name, level, color_dna, pet_state(hunger)')
        .inFilter('room_id', roomIds);

    final summaries = <String, _RoomPetSummary>{};
    for (final row in rows) {
      final roomId = row['room_id'] as String?;
      if (roomId == null) {
        continue;
      }
      final state = row['pet_state'];
      num? hunger;
      if (state is Map) {
        hunger = state['hunger'] as num?;
      } else if (state is List && state.isNotEmpty) {
        final first = state.first;
        if (first is Map) {
          hunger = first['hunger'] as num?;
        }
      }
      final petType = PetCatalog.resolveId(
        PetCatalog.typeFromColorDna(row['color_dna']),
      );
      summaries[roomId] = _RoomPetSummary(
        petType: petType,
        healthValue: _healthValueFromHunger(hunger),
        petName: (row['name'] as String?)?.trim(),
        petLevel: row['level'] as int?,
      );
    }
    return summaries;
  }

  double _healthValueFromHunger(num? hunger) {
    final value = (hunger?.toDouble() ?? 0.0) / 100;
    if (!value.isFinite) {
      return 0.0;
    }
    return value.clamp(0.0, 1.0);
  }

  Future<Map<String, _RoomLatestFeed>> _fetchRoomLatestFeeds(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) {
      return {};
    }
    final rows = await Supabase.instance.client
        .from('messages')
        .select('room_id, image_url, caption, sender_id, created_at')
        .inFilter('room_id', roomIds)
        .eq('type', 'image_feed')
        .not('image_url', 'is', null)
        .order('created_at', ascending: false)
        .limit(roomIds.length * 12);

    final feeds = <String, _RoomLatestFeed>{};
    for (final row in rows) {
      final roomId = row['room_id'] as String?;
      final imageUrl = row['image_url'] as String?;
      if (roomId == null || imageUrl == null || imageUrl.isEmpty) {
        continue;
      }

      final existing = feeds[roomId];
      if (existing == null) {
        feeds[roomId] = _RoomLatestFeed(
          latestImageUrl: imageUrl,
          latestCaption: row['caption'] as String?,
          latestSenderId: row['sender_id'] as String?,
          imageUrls: [imageUrl],
        );
        continue;
      }
      if (existing.imageUrls.length >= 3 ||
          existing.imageUrls.contains(imageUrl)) {
        continue;
      }
      existing.imageUrls.add(imageUrl);
    }
    return feeds;
  }

  Future<Map<String, int>> _fetchRoomMemberCounts(List<String> roomIds) async {
    if (roomIds.isEmpty) {
      return {};
    }
    final rows = await Supabase.instance.client
        .from('room_members')
        .select('room_id')
        .inFilter('room_id', roomIds)
        .eq('is_active', true);
    final counts = <String, int>{};
    for (final row in rows) {
      final roomId = row['room_id'] as String?;
      if (roomId == null) {
        continue;
      }
      counts[roomId] = (counts[roomId] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _refreshLatestRoomPhoto(String roomId) async {
    try {
      final rows = await Supabase.instance.client
          .from('messages')
          .select('image_url, caption, sender_id, created_at')
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
      final firstRow = rows.first;
      final senderId = firstRow['sender_id'] as String?;
      final caption = firstRow['caption'] as String?;
      setState(() {
        _myRooms = _myRooms
            .map(
              (room) => room['id'] == roomId
                  ? {
                      ...room,
                      'latest_photo': latest.first,
                      'latest_photos': latest,
                      'latest_caption': caption,
                      'latest_sender_id': senderId,
                    }
                  : room,
            )
            .toList();
      });
      if (senderId != null && senderId.isNotEmpty) {
        unawaited(_ensureProfileSummary(senderId));
      }
    } catch (_) {
      // Best-effort. Latest photo updates are also driven by realtime.
    }
  }

  Future<void> _refreshPetState({
    bool tick = false,
    bool refreshCoins = true,
  }) async {
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
      unawaited(_loadPetInfo(petId, roomId: roomId));

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
      final hunger = state?['hunger'] as num?;
      final healthValue = _healthValueFromHunger(hunger);

      setState(() {
        _petId = petId;
        _petState = state;
        _petStateReady = true;
        _myRooms = _myRooms
            .map(
              (room) => room['id'] == roomId
                  ? {...room, 'pet_health': healthValue}
                  : room,
            )
            .toList();
      });
      if (state != null) {
        _cachePetState(roomId, petId, state);
      }
      _handleOverfedState();
      _handlePetDepartureState(roomId: roomId, petId: petId, state: state);
    } catch (error) {
      setState(
        () => _petError = AppLocalizations.of(
          context,
        )!.petSyncFailed(userFacingError(context, error)),
      );
      if (mounted && !_petStateReady) {
        setState(() => _petStateReady = true);
      }
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }

    if (refreshCoins) {
      unawaited(_loadCoins());
    }
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
        _petStateReady = true;
        final hunger = _petState?['hunger'] as num?;
        final healthValue = _healthValueFromHunger(hunger);
        final roomId = _roomId;
        if (roomId != null) {
          _cachePetState(roomId, petId, _petState!);
          _myRooms = _myRooms
              .map(
                (room) => room['id'] == roomId
                    ? {...room, 'pet_health': healthValue}
                    : room,
              )
              .toList();
        }
      });
      _handleOverfedState();
      final roomId = _roomId;
      if (roomId != null) {
        _handlePetDepartureState(
          roomId: roomId,
          petId: petId,
          state: _petState,
        );
      }
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
    if (_isRoomLocked(roomId)) {
      await _showRoomLockedDialog();
      return;
    }
    if (_petDeparted) {
      final info = _currentDepartedPetInfo();
      if (info != null) {
        await _showPetDepartureFlow(info);
      }
      return;
    }

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
      final actualReward = _extractRewardAmount(reward);

      await _refreshPetState(refreshCoins: false);
      await _loadCoins(expectedReward: actualReward);
      await _loadPetInfo(petId, roomId: roomId);
    } catch (error) {
      setState(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(userFacingError(context, error)),
      );
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }
  }

  Future<void> _openFeedCamera() async {
    final roomId = _roomId;
    if (roomId == null) return;
    if (_isRoomLocked(roomId)) {
      await _showRoomLockedDialog();
      return;
    }
    if (_petDeparted) {
      final l10n = AppLocalizations.of(context)!;
      await showAppDialog<void>(
        context: context,
        builder: (context) => AppDialog(
          tone: AppDialogTone.info,
          title: l10n.petDepartureFeedDisabledTitle,
          message: l10n.petDepartureFeedDisabledMessage,
          actions: [
            AppDialogAction.primary(
              label: l10n.commonClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

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

  bool _isLocalFeedCooldownActive(String roomId) {
    final local = _localFeedCooldownByRoom[roomId];
    if (local == null) {
      return false;
    }
    return DateTime.now().toUtc().isBefore(local.nextEligibleAt);
  }

  void _setLocalFeedCooldown({
    required String roomId,
    required DateTime nextEligibleAt,
  }) {
    _localFeedCooldownByRoom[roomId] = _LocalFeedCooldown(
      nextEligibleAt: nextEligibleAt.toUtc(),
    );
  }

  void _updateLocalFeedCooldownFromResult({
    required String roomId,
    required FeedUploadResult result,
  }) {
    DateTime? parseUtc(String? raw) {
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return DateTime.tryParse(raw)?.toUtc();
    }

    final nextEligibleAt = parseUtc(result.nextEligibleAt);
    if (nextEligibleAt != null) {
      _setLocalFeedCooldown(roomId: roomId, nextEligibleAt: nextEligibleAt);
      return;
    }

    if (result.cooldownActive) {
      final fromLastFed = parseUtc(
        result.lastFedAt,
      )?.add(_localFeedCooldownFallback);
      _setLocalFeedCooldown(
        roomId: roomId,
        nextEligibleAt:
            fromLastFed ??
            DateTime.now().toUtc().add(const Duration(minutes: 2)),
      );
      return;
    }

    if (result.coinsAwarded > 0) {
      _setLocalFeedCooldown(
        roomId: roomId,
        nextEligibleAt: DateTime.now().toUtc().add(_localFeedCooldownFallback),
      );
      return;
    }

    _localFeedCooldownByRoom.remove(roomId);
  }

  void _applyOptimisticFeedReward({
    required String tempId,
    required String roomId,
    required String imageSource,
  }) {
    final isActiveRoom = _roomId == roomId;
    final cooldownActive = _isLocalFeedCooldownActive(roomId);
    final optimisticCoins = cooldownActive ? 0 : _optimisticFeedRewardCoins;

    _optimisticFeedCoinsByTempId[tempId] = optimisticCoins;
    if (optimisticCoins > 0) {
      _setLocalFeedCooldown(
        roomId: roomId,
        nextEligibleAt: DateTime.now().toUtc().add(_localFeedCooldownFallback),
      );
    }

    if (!mounted || !isActiveRoom) {
      return;
    }

    if (optimisticCoins > 0) {
      setState(() {
        _coins += optimisticCoins;
        _coinReward = optimisticCoins;
        _coinRewardEventId++;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _coinReward == null) {
          return;
        }
        setState(() => _coinReward = null);
      });
      unawaited(_playFeedSequence(imageSource));
    }
  }

  void _rollbackOptimisticFeedReward(String tempId) {
    final optimisticCoins = _optimisticFeedCoinsByTempId.remove(tempId) ?? 0;
    if (optimisticCoins <= 0) {
      return;
    }
    if (!mounted) {
      _coins = max(0, _coins - optimisticCoins);
      return;
    }
    setState(() {
      _coins = max(0, _coins - optimisticCoins);
    });
  }

  void _handleOptimisticFeed(FeedOptimisticMessage entry) {
    _optimisticFeedImageByTempId[entry.tempId] = entry.localImagePath;
    _optimisticFeedRoomByTempId[entry.tempId] = entry.roomId;
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
    _applyOptimisticFeedReward(
      tempId: entry.tempId,
      roomId: entry.roomId,
      imageSource: entry.localImagePath,
    );
  }

  void _handleFeedUploadCompleted(FeedUploadResult result) {
    _optimisticFeedImageByTempId.remove(result.tempId);
    final optimisticRoomId = _optimisticFeedRoomByTempId.remove(result.tempId);
    _optimisticFeedCoinsByTempId.remove(result.tempId);
    _chatListKey.currentState?.removeOptimisticMessage(result.tempId);
    _chatListKey.currentState?.refreshLatest();

    if (_latestFeedOptimisticTempId == result.tempId) {
      _latestFeedOptimisticTempId = null;
      _latestFeedOptimisticRoomId = null;
      _latestFeedOptimisticPrevImageUrl = null;
      _latestFeedOptimisticPrevSenderId = null;
      _latestFeedOptimisticPrevCaption = null;
    }
    final roomId = _roomId;
    final resultRoomId = optimisticRoomId ?? roomId;
    if (resultRoomId != null) {
      _updateLocalFeedCooldownFromResult(roomId: resultRoomId, result: result);
    }
    unawaited(_loadCoins());
    if (roomId != null) {
      _refreshLatestRoomPhoto(roomId);
      unawaited(_refreshLatestFeed(roomId));

      unawaited(_refreshPetState());
      unawaited(() async {
        final petId = _petId ?? await _loadPetId(roomId);
        if (petId != null) {
          await _loadPetInfo(petId, roomId: roomId);
        }
      }());
    }
  }

  void _handleFeedUploadFailed(String tempId, Object error) {
    _optimisticFeedImageByTempId.remove(tempId);
    final optimisticRoomId = _optimisticFeedRoomByTempId.remove(tempId);
    if (optimisticRoomId != null) {
      _localFeedCooldownByRoom.remove(optimisticRoomId);
    }
    _rollbackOptimisticFeedReward(tempId);
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
          AppLocalizations.of(
            context,
          )!.feedUploadFailed(userFacingError(context, error)),
        ),
      ),
    );
  }

  void _openChatRoom() {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final room = _myRooms.firstWhere(
      (r) => r['id'] == roomId,
      orElse: () => {},
    );
    final petName = (_petName ?? room['pet_name'] as String?)?.trim();
    final fallbackName = PetCatalog.byId(_petType).name(l10n);
    final petAssetPath = PetCatalog.byId(_petType).stayAsset;
    final backgroundDecoration = _currentBackgroundDefinition().decoration;
    final isDarkBackground = _currentBackgroundDefinition().isDark;
    final isRoomLocked = _isRoomLocked(roomId);

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ChatRoomView(
              roomId: roomId,
              backgroundDecoration: backgroundDecoration,
              isDarkBackground: isDarkBackground,
              petName: petName == null || petName.isEmpty
                  ? fallbackName
                  : petName,
              petAssetPath: petAssetPath,
              isPetDeparted: _petDeparted,
              isRoomLocked: isRoomLocked,
            ),
          ),
        )
        .then((_) {
          if (!mounted) {
            return;
          }
          unawaited(_refreshPetState());
        });
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

  Future<void> _openPetNameEditor() async {
    final petId = _petId;
    final roomId = _roomId;
    if (petId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.petNotFound)),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _petName?.trim() ?? '');
    String? errorText;

    Future<void> submit(StateSetter setState) async {
      final next = controller.text.trim();
      if (next.isEmpty) {
        setState(() {
          errorText = l10n.petNameEmptyError;
        });
        return;
      }
      Navigator.of(context).pop(next);
    }

    final newName = await showAppDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AppDialog(
              tone: AppDialogTone.info,
              title: l10n.petNameEditTitle,
              body: TextField(
                controller: controller,
                maxLength: 20,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: l10n.petNameHint,
                  errorText: errorText,
                ),
                onSubmitted: (_) => submit(setState),
              ),
              actions: [
                AppDialogAction.secondary(
                  label: l10n.commonCancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                AppDialogAction.primary(
                  label: l10n.commonSave,
                  onPressed: () => submit(setState),
                ),
              ],
            );
          },
        );
      },
    );

    if (newName == null) {
      return;
    }
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == _petName?.trim()) {
      return;
    }

    try {
      await Supabase.instance.client.rpc(
        'update_pet_name',
        params: {'p_pet_id': petId, 'p_name': trimmed},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _petName = trimmed;
        final roomId = _roomId;
        if (roomId != null) {
          _myRooms = _myRooms
              .map(
                (entry) => entry['id'] == roomId
                    ? {...entry, 'pet_name': trimmed}
                    : entry,
              )
              .toList(growable: false);
        }
      });
      unawaited(_loadPetInfo(petId, roomId: roomId));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.petNameUpdateFailed(userFacingError(context, error)),
          ),
        ),
      );
    }
  }

  double _healthValue() {
    return _healthValueFromHunger(_petState?['hunger'] as num?);
  }

  String _departureHeroTag(String petId) => 'pet_departure_note_$petId';

  DepartedPetInfo? _currentDepartedPetInfo() {
    final roomId = _roomId;
    if (roomId == null) {
      return null;
    }
    return _departedPetsByRoom[roomId];
  }

  List<DepartedPetInfo> _departedPetsList() {
    return _departedPetsByRoom.values.toList(growable: false);
  }

  String _resolvePetNameForRoom(String roomId) {
    if (roomId == _roomId) {
      final name = _petName?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    for (final room in _myRooms) {
      if (room['id'] != roomId) {
        continue;
      }
      final name = (room['pet_name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
      break;
    }
    return AppLocalizations.of(context)!.petNameUnknown;
  }

  String _resolvePetTypeForRoom(String roomId) {
    if (roomId == _roomId) {
      return PetCatalog.resolveId(_petType);
    }
    for (final room in _myRooms) {
      if (room['id'] != roomId) {
        continue;
      }
      final type = room['pet_type'] as String?;
      return PetCatalog.resolveId(type);
    }
    return PetCatalog.defaultPetId;
  }

  void _handlePetDepartureState({
    required String roomId,
    required String petId,
    required Map<String, dynamic>? state,
  }) {
    if (state == null) {
      return;
    }
    final hungerValue = state['hunger'];
    if (hungerValue is! num) {
      return;
    }
    final isDeparted = hungerValue <= 0;
    if (!isDeparted) {
      _departedPetsByRoom.remove(roomId);
      if (roomId == _roomId && _petDeparted && mounted) {
        setState(() => _petDeparted = false);
      }
      if (roomId == _roomId) {
        _petDeparturePrompted = false;
        _lastDeparturePetId = null;
      }
      return;
    }

    final info = DepartedPetInfo(
      petId: petId,
      roomId: roomId,
      petName: _resolvePetNameForRoom(roomId),
      petType: _resolvePetTypeForRoom(roomId),
    );
    _departedPetsByRoom[roomId] = info;

    if (roomId != _roomId || _showRoomSelection) {
      return;
    }

    if (!_petDeparted && mounted) {
      setState(() => _petDeparted = true);
    }

    final shouldPrompt = !_petDeparturePrompted || _lastDeparturePetId != petId;
    if (!shouldPrompt) {
      return;
    }
    _petDeparturePrompted = true;
    _lastDeparturePetId = petId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_showPetDepartureFlow(info));
    });
  }

  Future<void> _showPetDepartureFlow(DepartedPetInfo info) async {
    final l10n = AppLocalizations.of(context)!;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        barrierDismissible: true,
        barrierLabel: l10n.commonClose,
        pageBuilder: (context, animation, secondaryAnimation) =>
            PetDepartureNoteView(
              heroTag: _departureHeroTag(info.petId),
              noteText: l10n.petDepartureNoteMessage,
              onReturnPressed: () {
                Navigator.of(context).pop();
                unawaited(_openStoreWithDepartures());
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _openStoreWithDepartures() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoreView(
          roomId: _roomId,
          departedPets: _departedPetsList(),
          onReturnPet: _returnDepartedPet,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadCoins();
    await _loadFurnitureInventory();
  }

  Future<bool> _returnDepartedPet(DepartedPetInfo pet) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    try {
      await Supabase.instance.client
          .from('pet_state')
          .update({
            'hunger': 40,
            'last_decay_at': nowIso,
            'mood_boost': 0,
            'mood_boost_expires_at': null,
          })
          .eq('pet_id', pet.petId);
      await Supabase.instance.client.rpc(
        'tick_pet_state',
        params: {'p_pet_id': pet.petId, 'p_now': nowIso},
      );
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.petActionFailed(userFacingError(context, error)),
            ),
          ),
        );
      }
      return false;
    }

    if (!mounted) {
      return false;
    }

    setState(() {
      _departedPetsByRoom.remove(pet.roomId);
      if (pet.roomId == _roomId) {
        _petDeparted = false;
        _petDeparturePrompted = false;
        _lastDeparturePetId = null;
      }
    });

    if (pet.roomId == _roomId) {
      await _refreshPetState();
    } else {
      unawaited(_fetchRooms());
    }
    return true;
  }

  void _onHomeNavPressed() {
    if (_furnitureMode) {
      _closeFurnitureInventory();
    }
    // Navigate to room selection page
    setState(() {
      _showRoomSelection = true;
    });
    unawaited(_refreshRoomSelectionHealthBars());
  }

  Future<void> _refreshRoomSelectionHealthBars() async {
    if (_roomSelectionRefreshInFlight) {
      return;
    }
    _roomSelectionRefreshInFlight = true;
    final roomIds = _myRooms
        .map((room) => room['id'])
        .whereType<String>()
        .toList(growable: false);
    try {
      if (roomIds.isEmpty) {
        await _fetchRooms();
        return;
      }

      try {
        final pets = await Supabase.instance.client
            .from('pets')
            .select('id')
            .inFilter('room_id', roomIds);
        final nowIso = DateTime.now().toUtc().toIso8601String();
        for (final row in pets) {
          final petId = row['id'] as String?;
          if (petId == null || petId.isEmpty) {
            continue;
          }
          try {
            await Supabase.instance.client.rpc(
              'tick_pet_state',
              params: {'p_pet_id': petId, 'p_now': nowIso},
            );
          } catch (_) {
            // Best-effort per room: continue refreshing others.
          }
        }
      } catch (_) {
        // Best-effort: still reload rooms below.
      }

      await _fetchRooms();
    } finally {
      _roomSelectionRefreshInFlight = false;
    }
  }

  Future<void> _openStoreFromNav() async {
    await _openStoreWithDepartures();
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
        if (mounted) {
          setState(() {
            _latestFeedImageUrl = null;
            _latestFeedSenderId = null;
            _latestFeedCaption = null;
          });
        } else {
          _latestFeedImageUrl = null;
          _latestFeedSenderId = null;
          _latestFeedCaption = null;
        }
        return;
      }
      final imageUrl = row['image_url'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) {
        if (mounted) {
          setState(() {
            _latestFeedImageUrl = null;
            _latestFeedSenderId = null;
            _latestFeedCaption = null;
          });
        } else {
          _latestFeedImageUrl = null;
          _latestFeedSenderId = null;
          _latestFeedCaption = null;
        }
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

  Future<_ProfileSummary?> _ensureProfileSummary(
    String userId, {
    bool forceRefresh = false,
  }) async {
    final cached = _profileByUserId[userId];
    if (cached != null && !forceRefresh) {
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

  Future<void> _loadPetInfo(String petId, {String? roomId}) async {
    final expectedRoomId = roomId ?? _roomId;
    try {
      final row = await Supabase.instance.client
          .from('pets')
          .select('name, level, exp, color_dna')
          .eq('id', petId)
          .maybeSingle();
      if (row == null) {
        return;
      }
      final name = row['name'] as String?;
      final level = row['level'] as int?;
      final exp = row['exp'] as int?;
      final petType = PetCatalog.typeFromColorDna(row['color_dna']);
      final resolvedPetType = PetCatalog.resolveId(petType);
      if (!mounted) {
        _petName = name;
        _petLevel = level;
        _petExp = exp;
        _petType = resolvedPetType;
        return;
      }
      if (expectedRoomId != null && _roomId != expectedRoomId) {
        return;
      }
      final activePetId = _petId;
      if (activePetId != null && activePetId != petId) {
        return;
      }
      setState(() {
        _petName = name;
        _petLevel = level;
        _petExp = exp;
        _petType = resolvedPetType;
        final activeRoomId = _roomId;
        if (activeRoomId != null) {
          _myRooms = _myRooms
              .map(
                (room) => room['id'] == activeRoomId
                    ? {...room, 'pet_type': resolvedPetType, 'pet_level': level}
                    : room,
              )
              .toList();
        }
      });
      _precachePetAssets(PetCatalog.byId(resolvedPetType));
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

  void _startRoomSelectionRefreshTimer() {
    _roomSelectionRefreshTimer?.cancel();
    _roomSelectionRefreshTimer = Timer.periodic(_roomSelectionRefreshInterval, (
      _,
    ) {
      if (!mounted || !_showRoomSelection) {
        return;
      }
      unawaited(_refreshRoomSelectionHealthBars());
    });
  }

  Future<void> _tickPetState() async {
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

  void _handleOverfedState() {
    final lastOverfed = _parseOptionalDate(
      _petState?['last_overfed_at'],
    )?.toUtc();
    if (lastOverfed == null) {
      return;
    }
    if (_lastOverfedAt != null && !lastOverfed.isAfter(_lastOverfedAt!)) {
      return;
    }
    if (DateTime.now().toUtc().difference(lastOverfed) >
        const Duration(minutes: 10)) {
      _lastOverfedAt = lastOverfed;
      return;
    }
    _lastOverfedAt = lastOverfed;
    _overfedBubbleTimer?.cancel();
    setState(() => _showOverfedBubble = true);
    _overfedBubbleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() => _showOverfedBubble = false);
    });
  }

  void _maybeTriggerWander() {
    if (!mounted || _isDraggingPet || _petDeparted) {
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

  Duration _durationForFoodApproach({
    required double distance,
    required double hunger,
  }) {
    final hungerClamped = hunger.clamp(0.0, 100.0);
    final hungerRatio = hungerClamped / 100.0;
    final speedPxPerSec = lerpDouble(20, 95, hungerRatio) ?? _petMoveSpeed;
    final rawMs = (distance / speedPxPerSec * 1000).round();
    return Duration(milliseconds: max(_minMoveMs, rawMs));
  }

  void _updateFacing(Offset from, Offset to) {
    final dx = to.dx - from.dx;
    if (dx.abs() < 0.001) {
      return;
    }
    _petFacingRight = dx < 0;
  }

  TickerFuture _startPetMove(
    Offset targetNormalized,
    Size fieldSize, {
    bool userInitiated = true,
    Duration? duration,
  }) {
    final clampedTarget = _clampNormalized(targetNormalized);
    final current = _currentPetNormalized();
    final currentPx = _positionFromNormalized(current, fieldSize);
    final targetPx = _positionFromNormalized(clampedTarget, fieldSize);
    _updateFacing(current, clampedTarget);
    _petMoveController.stop();
    _petMoveController.duration =
        duration ?? _durationForDistance((targetPx - currentPx).distance);
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
    final ticker = _petMoveController.forward(from: 0);
    setState(() {});
    return ticker;
  }

  void _animatePetTo(
    Offset targetNormalized,
    Size fieldSize, {
    bool userInitiated = true,
  }) {
    _startPetMove(targetNormalized, fieldSize, userInitiated: userInitiated);
  }

  Future<void> _animatePetToAndWait(
    Offset targetNormalized,
    Size fieldSize, {
    bool userInitiated = true,
    Duration? duration,
  }) async {
    final ticker = _startPetMove(
      targetNormalized,
      fieldSize,
      userInitiated: userInitiated,
      duration: duration,
    );
    try {
      await ticker.orCancel;
    } catch (_) {
      // Movement interrupted by another interaction.
    }
  }

  void _handlePetFieldTap(Offset localPosition, Size fieldSize) {
    if (_petDeparted) {
      return;
    }
    final desiredTopLeft =
        localPosition -
        Offset(_petAvatarSize.width / 2, _petAvatarSize.height / 2);
    final clampedTopLeft = _clampTopLeft(desiredTopLeft, fieldSize);
    final normalizedTarget = _normalizedFromTopLeft(clampedTopLeft, fieldSize);
    _animatePetTo(normalizedTarget, fieldSize);
  }

  Offset _pickFoodPlacement(Size fieldSize) {
    final current = _currentPetNormalized();
    var best = const Offset(0.72, 0.72);
    var bestDistance = -1.0;
    for (var i = 0; i < 16; i++) {
      final candidate = Offset(
        0.12 + (_random.nextDouble() * 0.76),
        0.24 + (_random.nextDouble() * 0.62),
      );
      final candidatePx = _positionFromNormalizedSized(
        candidate,
        fieldSize,
        _photoFoodSize,
      );
      final petPx = _positionFromNormalized(current, fieldSize);
      final distance = (candidatePx - petPx).distance;
      if (distance > bestDistance) {
        bestDistance = distance;
        best = candidate;
      }
    }
    return best;
  }

  Future<void> _playFeedSequence(String? imageSource) async {
    if (!mounted || _petDeparted) {
      return;
    }
    final source = imageSource?.trim();
    if (source == null || source.isEmpty) {
      return;
    }
    final fieldSize = _petFieldSize();
    if (fieldSize == null || fieldSize.isEmpty) {
      return;
    }
    final token = ++_feedingAnimationToken;
    final foodTarget = _pickFoodPlacement(fieldSize);

    setState(() {
      _photoFoodImageSource = source;
      _photoFoodNormalizedPosition = foodTarget;
      _photoFoodBiteStage = 0;
      _photoFoodDropping = true;
      _petEating = false;
    });

    await Future<void>.delayed(24.ms);
    if (!mounted || token != _feedingAnimationToken) {
      return;
    }
    setState(() => _photoFoodDropping = false);

    await Future<void>.delayed(_foodDropDuration + 120.ms);
    if (!mounted || token != _feedingAnimationToken) {
      return;
    }

    final current = _currentPetNormalized();
    final currentPx = _positionFromNormalized(current, fieldSize);
    final targetPx = _positionFromNormalizedSized(
      foodTarget,
      fieldSize,
      _photoFoodSize,
    );
    final hunger = (_petState?['hunger'] as num?)?.toDouble() ?? 50;
    final approachDuration = _durationForFoodApproach(
      distance: (targetPx - currentPx).distance,
      hunger: hunger,
    );

    await _animatePetToAndWait(
      foodTarget,
      fieldSize,
      userInitiated: false,
      duration: approachDuration,
    );
    if (!mounted || token != _feedingAnimationToken) {
      return;
    }

    setState(() => _petEating = true);
    unawaited(AppSfx.playEating());
    for (var stage = 1; stage <= 3; stage++) {
      await Future<void>.delayed(_foodBiteStepDuration);
      if (!mounted || token != _feedingAnimationToken) {
        return;
      }
      setState(() => _photoFoodBiteStage = stage);
    }

    await Future<void>.delayed(180.ms);
    if (!mounted || token != _feedingAnimationToken) {
      return;
    }
    setState(() {
      _photoFoodImageSource = null;
      _photoFoodNormalizedPosition = null;
      _photoFoodDropping = false;
      _photoFoodBiteStage = 0;
      _petEating = false;
      _petStationaryState = _PetStationaryState.staying;
    });
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
    if (_petDeparted) {
      return;
    }
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
    if (_petDeparted) {
      return;
    }
    final localPosition = _globalToPetField(details.globalPosition);
    if (localPosition == null) {
      return;
    }
    _markUserInteraction();
    final desiredTopLeft = localPosition - _dragOffset;
    final clampedTopLeft = _clampTopLeft(desiredTopLeft, fieldSize);
    final normalized = _normalizedFromTopLeft(clampedTopLeft, fieldSize);
    _updateFacing(_petNormalizedPosition, normalized);
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
        )!.storeLoadFailed(userFacingError(context, error));
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
          )!.storeLoadFailed(userFacingError(context, error));
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
    unawaited(_loadRoomBackgrounds(roomId));
    unawaited(_loadRoomBackgroundState(roomId));
  }

  void _closeFurnitureInventory() {
    setState(() {
      _furnitureMode = false;
      _selectedFurnitureItemId = null;
    });
    _furnitureWiggleController.stop();
    _furnitureWiggleController.value = 0;
  }

  Future<void> _loadRoomBackgrounds(String roomId) async {
    if (_backgroundLoading) {
      return;
    }
    setState(() => _backgroundLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('room_backgrounds')
          .select('item_id,items(*)')
          .eq('room_id', roomId);

      final items = <StoreItem>[];
      for (final row in response as List<dynamic>) {
        final record = row as Map<String, dynamic>;
        final itemData = record['items'] as Map<String, dynamic>?;
        if (itemData == null) {
          continue;
        }
        final item = StoreItem.fromJson(itemData);
        if (item.isBackground) {
          items.add(item);
        }
      }

      if (!mounted || _roomId != roomId) {
        return;
      }
      setState(() {
        _ownedBackgroundsByRoom[roomId] = items;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _backgroundError = AppLocalizations.of(
          context,
        )!.storeLoadFailed(userFacingError(context, error));
      });
    } finally {
      if (mounted) {
        setState(() => _backgroundLoading = false);
      } else {
        _backgroundLoading = false;
      }
    }
  }

  Future<void> _loadRoomBackgroundState(String roomId) async {
    try {
      final response = await Supabase.instance.client
          .from('room_background_state')
          .select('active_item_id')
          .eq('room_id', roomId)
          .maybeSingle();

      final activeItemId = response?['active_item_id'] as String?;
      if (!mounted || _roomId != roomId) {
        return;
      }
      setState(() {
        _activeBackgroundByRoom[roomId] = activeItemId;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _backgroundError = AppLocalizations.of(
          context,
        )!.storeLoadFailed(userFacingError(context, error));
      });
    }
  }

  void _subscribeToBackgrounds(String roomId) {
    if (_backgroundSubscriptionRoomId == roomId) {
      return;
    }

    _backgroundStateChannel?.unsubscribe();
    _backgroundInventoryChannel?.unsubscribe();
    _backgroundSubscriptionRoomId = roomId;

    final stateChannel = Supabase.instance.client.channel(
      'room_background_state_$roomId',
    );
    _backgroundStateChannel = stateChannel;
    stateChannel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_background_state',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => unawaited(_loadRoomBackgroundState(roomId)),
    );
    stateChannel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'room_background_state',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => unawaited(_loadRoomBackgroundState(roomId)),
    );
    stateChannel.subscribe();

    final inventoryChannel = Supabase.instance.client.channel(
      'room_backgrounds_$roomId',
    );
    _backgroundInventoryChannel = inventoryChannel;
    inventoryChannel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_backgrounds',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => unawaited(_loadRoomBackgrounds(roomId)),
    );
    inventoryChannel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'room_backgrounds',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => unawaited(_loadRoomBackgrounds(roomId)),
    );
    inventoryChannel.subscribe();
  }

  List<StoreItem> _ownedBackgroundsForRoom(String roomId) {
    return _ownedBackgroundsByRoom[roomId] ?? const [];
  }

  Future<void> _applyRoomBackground(String itemId) async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    final owned = _ownedBackgroundsForRoom(roomId);
    if (!owned.any((item) => item.id == itemId)) {
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    setState(() => _backgroundApplyingItemId = itemId);
    try {
      await Supabase.instance.client.from('room_background_state').upsert({
        'room_id': roomId,
        'active_item_id': itemId,
        'updated_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _activeBackgroundByRoom[roomId] = itemId;
    } finally {
      if (mounted) {
        setState(() => _backgroundApplyingItemId = null);
      } else {
        _backgroundApplyingItemId = null;
      }
    }
  }

  RoomBackgroundDefinition _currentBackgroundDefinition() {
    final roomId = _roomId;
    if (roomId == null) {
      return RoomBackgrounds.resolve(null);
    }
    final activeItemId = _activeBackgroundByRoom[roomId];
    if (activeItemId == null) {
      return RoomBackgrounds.resolve(null);
    }
    final items = _ownedBackgroundsByRoom[roomId];
    if (items == null) {
      return RoomBackgrounds.resolve(null);
    }
    StoreItem? activeItem;
    for (final item in items) {
      if (item.id == activeItemId) {
        activeItem = item;
        break;
      }
    }
    return RoomBackgrounds.resolve(activeItem?.backgroundKey);
  }

  SystemUiOverlayStyle _currentOverlayStyle() {
    final isDark = _currentBackgroundDefinition().isDark;
    return AppStatusBarStyles.forBackground(isDark: isDark);
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
        )!.storePurchaseFailed(userFacingError(context, error));
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
          )!.storeLoadFailed(userFacingError(context, error));
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
          )!.storeLoadFailed(userFacingError(context, error));
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
              if (_photoFoodImageSource != null &&
                  _photoFoodNormalizedPosition != null &&
                  _photoFoodBiteStage < 3)
                _buildPhotoFood(fieldSize),
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
              if (_petEating) _buildEatingHearts(fieldSize),
              if (_shouldShowNewRoomInvitePrompt)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildNewRoomInvitePrompt(),
                ),
              if (_furnitureMode)
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: _buildFurnitureEditHint(),
                ),
              if (_isCurrentRoomLocked)
                Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              if (_isCurrentRoomLocked)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _buildLockedRoomHomePrompt(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockedRoomHomePrompt() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black87, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.lock_rounded, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.roomLockedMessage,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: l10n.storeTitle,
            child: SizedBox(
              width: 34,
              height: 34,
              child: FilledButton(
                onPressed: () => unawaited(_openStoreFromNav()),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const CircleBorder(),
                ),
                child: SvgPicture.asset(
                  'assets/icon/icon-park-outline--shopping-bag.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
      ignoring: _petBusy || _petDeparted,
      child: GestureDetector(
        onTap: (_petBusy || _petDeparted)
            ? null
            : () => unawaited(_cleanPoopAt(index)),
        child: const Text('💩', style: TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildPhotoFood(Size fieldSize) {
    final source = _photoFoodImageSource;
    final normalized = _photoFoodNormalizedPosition;
    if (source == null || normalized == null) {
      return const SizedBox.shrink();
    }
    final target = _positionFromNormalizedSized(
      normalized,
      fieldSize,
      _photoFoodSize,
    );
    final offscreenTop = -_photoFoodSize.height - 12;
    return AnimatedPositioned(
      duration: _foodDropDuration,
      curve: Curves.bounceOut,
      left: target.dx,
      top: _photoFoodDropping ? offscreenTop : target.dy,
      child: PhotoFood(
        imageSource: source,
        biteStage: _photoFoodBiteStage,
        size: _photoFoodSize,
      ),
    );
  }

  Widget _buildEatingHearts(Size fieldSize) {
    final normalized = _currentPetNormalized();
    final petTopLeft = _positionFromNormalized(normalized, fieldSize);
    return Positioned(
      left: petTopLeft.dx + (_petAvatarSize.width * 0.15),
      top: petTopLeft.dy - 24,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _petEating ? 1 : 0),
          duration: 220.ms,
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, -8 * value),
                child: child,
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFFF6D8A)),
              SizedBox(width: 2),
              Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFFF8FA6)),
              SizedBox(width: 2),
              Icon(Icons.favorite_rounded, size: 10, color: Color(0xFFFFB1C2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverfedBubble() {
    final l10n = AppLocalizations.of(context)!;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _showOverfedBubble ? 1 : 0,
        duration: 200.ms,
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: _showOverfedBubble ? 1 : 0.92,
          duration: 200.ms,
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black87, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  l10n.petOverfedBubble,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -2),
                child: Transform.rotate(
                  angle: pi / 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black87, width: 1.2),
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

  void _dismissNewRoomInvitePrompt() {
    if (!_showNewRoomInvitePrompt) {
      return;
    }
    setState(() => _showNewRoomInvitePrompt = false);
  }

  Widget _buildNewRoomInvitePrompt() {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedScale(
      scale: _shouldShowNewRoomInvitePrompt ? 1 : 0.96,
      duration: 220.ms,
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: _shouldShowNewRoomInvitePrompt ? 1 : 0,
        duration: 180.ms,
        curve: Curves.easeOut,
        child: Container(
          width: 220,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black87, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l10n.roomInvitePromptTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismissNewRoomInvitePrompt,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.close_rounded, size: 18),
                    ),
                  ),
                ],
              ),
              const Gap(6),
              Text(
                l10n.roomInvitePromptBody,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
              const Gap(10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _inviteCodeLoading ? null : _generateInviteCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _inviteCodeLoading
                        ? l10n.roomInvitePromptGenerating
                        : l10n.roomInvitePromptAction,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cleanPoopAt(int index) async {
    final roomId = _roomId;
    if (roomId == null) return;
    if (_isRoomLocked(roomId)) {
      await _showRoomLockedDialog();
      return;
    }
    if (_petDeparted) {
      final info = _currentDepartedPetInfo();
      if (info != null) {
        await _showPetDepartureFlow(info);
      }
      return;
    }

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

      // Extract coins_awarded from the result shape safely.
      final actualReward = _extractRewardAmount(result);

      // Refresh state and rewards immediately after clean action
      await _refreshPetState(refreshCoins: false);
      await _loadCoins(expectedReward: actualReward);
      await _loadPetInfo(petId, roomId: roomId);
    } catch (error) {
      setState(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(userFacingError(context, error)),
      );
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }
  }

  Widget _buildDraggablePet(Size fieldSize) {
    if (!_petStateReady) {
      return _buildPetLoadingPlaceholder();
    }
    if (_petDeparted) {
      return _buildDepartedPetPlaceholder();
    }
    return IgnorePointer(
      ignoring: _furnitureMode,
      child: GestureDetector(
        onPanStart: (details) => _handlePetDragStart(details, fieldSize),
        onPanUpdate: (details) => _handlePetDragUpdate(details, fieldSize),
        onPanEnd: (_) => _handlePetDragEnd(),
        onPanCancel: _handlePetDragCancel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: -6, top: -54, child: _buildOverfedBubble()),
            JuicyScaleButton(
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
          ],
        ),
      ),
    );
  }

  Widget _buildPetLoadingPlaceholder() {
    return SizedBox(
      width: _petAvatarSize.width,
      height: _petAvatarSize.height,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildDepartedPetPlaceholder() {
    final l10n = AppLocalizations.of(context)!;
    final info = _currentDepartedPetInfo();
    final heroTag = _departureHeroTag(info?.petId ?? 'pet');
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: info == null
              ? null
              : () => unawaited(_showPetDepartureFlow(info)),
          child: Container(
            width: 95,
            height: 95,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8D8B5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icon/solar--letter-outline.svg',
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF4A3B2A),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.petDepartureGuideTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A3B2A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
    final overlayStyle = _currentOverlayStyle();
    if (_loadingRoom) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: const Scaffold(
          body: ColoredBox(color: AppTheme.backgroundColor),
        ),
      );
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (_showRoomSelection || _roomId == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          drawer: _buildSideDrawer(),
          body: RoomSelectionView(
            rooms: _myRooms,
            creatingRoom: _creatingRoom,
            joiningRoom: _joiningRoom,
            onCreateRoom: _createRoom,
            onJoinRoom: _joinRoomByCode,
            onSelectRoom: _enterRoomFromSelection,
            onLeaveRoom: _confirmLeaveRoom,
            userAvatarById: _profileByUserId.map(
              (key, value) => MapEntry(key, value.avatarUrl),
            ),
            userNameById: _profileByUserId.map(
              (key, value) => MapEntry(key, value.nickname),
            ),
            selectedRoomId: _roomSelectionId ?? _roomId,
            userAvatarUrl: _myAvatarUrl,
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        drawer: _buildSideDrawer(), // Room List Drawer
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Layer 1: Background
            Positioned.fill(
              child: DecoratedBox(
                decoration: _currentBackgroundDefinition().decoration,
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
                      final l10n = AppLocalizations.of(context)!;
                      final level = _petLevel;
                      final exp = _petExp ?? 0;
                      final petDefinition = PetCatalog.byId(_petType);
                      final expProgressValue = level == null
                          ? 0.0
                          : expProgress(level: level, exp: exp);
                      final roomPetName =
                          _myRooms.cast<Map<String, dynamic>?>().firstWhere(
                                (room) => room?['id'] == _roomId,
                                orElse: () => null,
                              )?['pet_name']
                              as String?;
                      final resolvedPetName =
                          (_petName?.trim().isNotEmpty ?? false)
                          ? _petName!.trim()
                          : ((roomPetName?.trim().isNotEmpty ?? false)
                                ? roomPetName!.trim()
                                : l10n.petNameUnnamed);
                      final healthDebugValue = (_petState?['hunger'] as num?)
                          ?.round();
                      return HomeGameStatusBar(
                        petAvatar: Image.asset(
                          petDefinition.stayAsset,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                        expProgress: expProgressValue,
                        level: level,
                        petName: resolvedPetName,
                        healthValue: _healthValue(),
                        healthDebugValue: healthDebugValue,
                        coins: _coins,
                        diamonds: _diamonds,
                        coinReward: _coinReward,
                        coinRewardEventId: _coinRewardEventId,
                        onPetTap: () => Scaffold.of(context).openDrawer(),
                        onPetNameTap: _openPetNameEditor,
                        onStoreTap: _openStoreFromNav,
                        onInviteTap: _generateInviteCode,
                        inviteLabel: l10n.roomInviteCta,
                        inviteLoading: _inviteCodeLoading,
                        onInventoryTap: _openFurnitureInventory,
                        inventoryLabel: l10n.roomInventoryCta,
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
                              : _profileByUserId[_latestFeedSenderId!]
                                    ?.avatarUrl,
                          senderFallbackText: _latestFeedSenderId == null
                              ? null
                              : _profileByUserId[_latestFeedSenderId!]
                                    ?.nickname,
                          onTap: () {
                            final imageUrl = _latestFeedImageUrl ?? '';
                            if (imageUrl.isEmpty) {
                              return;
                            }
                            FullScreenPhotoViewer.open(
                              context,
                              imageUrls: [imageUrl],
                              captions: [
                                (_latestFeedCaption ?? '').trim().isEmpty
                                    ? null
                                    : _latestFeedCaption!.trim(),
                              ],
                            );
                          },
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
                      cameraEnabled: !_petDeparted && !_isCurrentRoomLocked,
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
                    offset: _furnitureMode
                        ? Offset.zero
                        : const Offset(0, -1.1),
                    duration: 220.ms,
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: _furnitureMode ? 1 : 0,
                      duration: 160.ms,
                      child: HomeRoomInventoryPanel(
                        furnitureCatalog: _furnitureCatalog,
                        furnitureInventory: _furnitureInventory,
                        selectedFurnitureItemId: _selectedFurnitureItemId,
                        availableFurnitureCount: _availableFurnitureCount,
                        furnitureLoading: _furnitureLoading,
                        furnitureErrorText: _furnitureError,
                        backgroundItems: _roomId == null
                            ? const []
                            : _ownedBackgroundsForRoom(_roomId!),
                        activeBackgroundId: _roomId == null
                            ? null
                            : _activeBackgroundByRoom[_roomId!],
                        backgroundLoading: _backgroundLoading,
                        backgroundErrorText: _backgroundError,
                        applyingBackgroundId: _backgroundApplyingItemId,
                        onClose: _closeFurnitureInventory,
                        onFurnitureTap: (itemId) {
                          setState(() => _selectedFurnitureItemId = itemId);
                          _autoPlaceFurnitureFromInventory(itemId);
                        },
                        onBackgroundApply: _applyRoomBackground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetAvatar() {
    final petColor = _petMoodColor();
    final petDefinition = PetCatalog.byId(_petType);

    final String asset;
    if (_petIsMoving) {
      asset = petDefinition.walkAsset;
    } else {
      asset = switch (_petStationaryState) {
        _PetStationaryState.staying => petDefinition.stayAsset,
        _PetStationaryState.sleeping => petDefinition.sleepAsset,
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
      userAvatarUrl: _myAvatarUrl,
      userName: _myNickname,
      onProfileTap: () {
        Navigator.pop(context);
        unawaited(_openProfile());
      },
      onSignOut: _signOut,
      debugActions: ExpansionTile(
        leading: const Icon(Icons.bug_report_outlined),
        title: Text(l10n.drawerDebugTools),
        children: [
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
          ListTile(
            title: Text(l10n.drawerDebugAddCandy),
            onTap: () => _debugUpdateProfileBalances(coinDelta: 100),
          ),
          ListTile(
            title: Text(l10n.drawerDebugAddDiamonds),
            onTap: () => _debugUpdateProfileBalances(diamondDelta: 100),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 8),
            title: Text(l10n.drawerDebugTogglePlan),
            subtitle: Text(
              _debugProPlan ? l10n.drawerProPlan : l10n.drawerFreePlan,
            ),
            value: _debugProPlan,
            onChanged: (value) => unawaited(_setDebugProPlan(value)),
          ),
          ListTile(
            title: Text(l10n.drawerDebugHungerDown),
            onTap: (_petBusy || _roomId == null)
                ? null
                : () => _debugAdjustPetHunger(-10),
          ),
          ListTile(
            title: Text(l10n.drawerDebugAddExp),
            onTap: (_petBusy || _roomId == null)
                ? null
                : () => _debugAddPetExp(10),
          ),
          ListTile(
            title: Text(l10n.drawerDebugSpawnPoop),
            onTap: (_petBusy || _roomId == null) ? null : _debugSpawnPetPoop,
          ),
          ListTile(
            title: Text(l10n.drawerDebugTestSoftUpdate),
            onTap: () {
              Navigator.pop(context);
              ForceUpdateDebugTool.instance.showSoftPrompt();
            },
          ),
          ListTile(
            title: Text(l10n.drawerDebugTestHardUpdate),
            onTap: () {
              Navigator.pop(context);
              ForceUpdateDebugTool.instance.showHardPrompt();
            },
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

class _PetExpUpdate {
  final int level;
  final int exp;

  const _PetExpUpdate({required this.level, required this.exp});
}
