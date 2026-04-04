import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/app_config/app_config_service.dart';
import '../../services/app_badge_service.dart';
import '../../services/audio/app_sfx.dart';
import '../../services/auth/session_utils.dart';
import '../../services/crash/crash_reporting_service.dart';
import '../../services/fcm_service.dart';
import '../../services/home/home_bootstrap_cache_repository.dart';
import '../../services/iap/revenuecat_service.dart';
import '../../services/ads/admob_ids.dart';
import '../../services/ads/rewarded_ads_service.dart';
import '../../services/profile/profile_cache_service.dart';
import '../../services/profile/device_timezone_service.dart';
import '../../services/review/review_prompt_service.dart';
import '../../services/settings/app_settings_repository.dart';

import '../../services/label_mapping/label_mapping_service.dart';
import '../../services/performance/memory_diagnostics_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/debug/memory_diagnostics_sheet.dart';
import '../../shared/force_update/force_update_debug_tool.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/juice_wrappers.dart';
import '../../shared/ui/keyboard_dismiss_utils.dart';
import '../../shared/ui/responsive_layout.dart';
import '../../shared/ui/status_bar_style.dart';
import '../../shared/ui/user_avatar.dart';
import '../../shared/upload_limits.dart';
import '../chat/chat_room_view_v2.dart';
import '../ads/admob_banner_slot.dart';
import '../feed/feed_capture_view.dart';
import '../gallery/memory_calendar_view.dart';
import '../pet/pet_catalog.dart';
import '../pet/leveling.dart';
import '../pet/pet_departure.dart';
import '../pet/pet_departure_note_view.dart';
import '../pet/pet_selection_page.dart';
import '../profile/profile_view.dart';
import '../shop/models/shop_item.dart';
import '../shop/shop_view.dart';
import 'home_furniture_math.dart';
import 'home_gallery_feed_utils.dart';
import 'home_unread_rules.dart';
import 'providers/home_currency_provider.dart';
import 'providers/home_pet_state_provider.dart';
import 'providers/home_unread_counts_provider.dart';
import 'providers/home_rooms_provider.dart';
import 'onboarding_focus_utils.dart';
import 'room_selection_view.dart';
import 'room_backgrounds.dart';
import 'widgets/home_bottom_nav_bar.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_furniture_inventory_overlay.dart';
import 'widgets/home_furniture_scale_controls.dart';
import 'widgets/home_room_inventory_panel.dart';
import 'widgets/home_main_content.dart';
import 'widgets/home_room_background.dart';
import 'widgets/home_loading_view.dart';
import 'widgets/home_game_status_bar.dart';
import 'widgets/home_responsive.dart';
import 'widgets/pet_photo_gallery.dart';
import 'widgets/photo_food.dart';

part 'home_view_models.dart';
part 'controllers/home_unread_manager.dart';
part 'controllers/home_pet_movement_controller.dart';
part 'controllers/home_feed_orchestrator.dart';
part 'controllers/home_room_manager.dart';
part 'flows/home_invite_flow.dart';
part 'flows/home_onboarding_flow.dart';

enum _PetStationaryState { staying, sleeping }

enum _FeedDoubleRewardPromptAction { watch, cancel }

enum _BasicOnboardingStep {
  profileSetup,
  createPet,
  inviteFriend,
  feedOnce,
  completed,
}

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _petAvatarSize = Size(100, 100);
  static const double _petCompactVisualScale = 0.74;
  static const double _petRegularVisualScale = 0.74;
  static const double _petExpandedVisualScale = 0.88;
  static const _photoFoodSize = Size(82, 82);
  static const int _optimisticFeedRewardCoins = 10;
  static const double _petMoveSpeed = 30;
  static const int _minMoveMs = 260;
  static const Duration _foodDropDuration = Duration(milliseconds: 760);
  static const Duration _petEatingStayDuration = Duration(seconds: 3);
  static const Duration _idleThreshold = Duration(seconds: 8);
  static const Duration _wanderCooldown = Duration(seconds: 7);
  static const Duration _wanderCheckInterval = Duration(seconds: 4);
  static const Duration _petTickInterval = Duration(minutes: 5);
  static const Duration _roomSelectionRefreshInterval = Duration(seconds: 45);
  static const Duration _overfedFeedEventWindow = Duration(seconds: 45);
  static const _furnitureItemSize = Size(42, 42);
  static const _poopEmojiSize = Size(28, 28);
  static const int _profileNicknameMaxLength = 20;
  static const int _onboardingAvatarMaxDimension = 512;
  static const int _onboardingAvatarWebpQuality = 70;

  // Logic State
  bool _profileEnsured = false;
  bool _homeBootstrapCompleted = false;
  bool _creatingRoom = false;
  bool _joiningRoom = false;
  bool _leavingRoom = false;
  bool _testingFeed = false;
  bool _loadingRoom = false;
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
  DateTime? _overfedFeedEventArmedAt;
  bool _showOverfedBubble = false;
  Timer? _overfedBubbleTimer;
  String? _petName;
  int? _petLevel;
  int? _petExp;
  int _coins = 1234;
  int _diamonds = 0;
  bool _showRoomDecorHint = false;
  String? _roomDecorHintRoomId;
  bool _isDebugAdmin = false;
  bool _debugProPlan = false;
  bool _debugAlwaysShowOnboarding = false;
  bool _revenueCatProPlan = false;
  final RevenueCatService _revenueCatService = RevenueCatService();
  late final FCMService _fcmService;
  late final RewardedAdsService _rewardedAdsService;
  String? _myAvatarUrl;
  String? _myNickname;
  String? _onboardingProfileAvatarUrl;
  String? _onboardingProfileError;
  int? _coinReward; // Triggers coin animation when set
  int _coinRewardEventId = 0;
  int _feedRewardPendingCount = 0;
  bool _coinsLoadInFlight = false;
  int? _pendingCoinsExpectedReward;
  bool _roomSelectionRefreshInFlight = false;
  bool _showRoomSelectionRefreshIndicator = false;
  List<Map<String, dynamic>> _myRooms = []; // Stores room info
  RealtimeChannel? _petStateChannel;
  String? _petSubscriptionPetId;
  final GlobalKey _petFieldKey = GlobalKey();
  final TextEditingController _onboardingProfileNicknameController =
      TextEditingController();
  final ImagePicker _onboardingProfileImagePicker = ImagePicker();
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
  Timer? _unreadReconcileTimer;
  StreamSubscription<AppNotificationIntent>? _notificationIntentSubscription;
  AppNotificationIntent? _pendingNotificationIntent;
  bool _petAssetsPrecached = false;
  bool _basicOnboardingLoadStarted = false;
  final Set<String> _cachedPetAssets = {};
  bool _departureFontsWarmed = false;
  Future<void>? _departureFontsWarmup;
  static const int _petNameMaxLength = 20;
  static const int _freePlanRoomLimit = 2;
  static const String _proEntitlementId = 'Petmonthly';
  static const Duration _networkTimeout = Duration(seconds: 4);
  static const Duration _roomEntryLoadingMinDuration = Duration(
    milliseconds: 550,
  );
  static const Duration _roomEntryFadeDuration = Duration(milliseconds: 420);
  static const Duration _onlineProbeThrottle = Duration(seconds: 10);
  bool _inviteCodeLoading = false;
  bool _roomEntryLoading = false;
  bool _latestFeedRefreshInFlight = false;
  String? _latestFeedRefreshingRoomId;
  int _latestFeedRefreshToken = 0;
  int _roomEntryLoadingToken = 0;
  int _roomEntryFadeVersion = 0;
  bool _showNewRoomInvitePrompt = false;
  String? _newRoomInviteRoomId;
  DateTime? _lastWriteOnlineCheckAt;
  bool _lastWriteOnlineCheckResult = true;

  // Furniture State
  bool _furnitureMode = false;
  bool _furnitureLoading = false;
  String? _furnitureError;
  String? _selectedFurnitureItemId;
  String? _selectedPlacedFurnitureId;
  String? _activeFurnitureDragId;
  Offset? _activeFurnitureDragStartNormalizedPosition;
  String? _activeFurnitureScaleInteractionItemId;
  Offset? _activeFurnitureScaleInteractionStartNormalizedPosition;
  double? _activeFurnitureScaleInteractionStartScale;
  int _furnitureInstanceSeed = 0;
  final Map<String, ShopItem> _furnitureCatalog = {};
  final Map<String, int> _furnitureInventory = {};
  final Map<String, List<_PlacedFurniture>> _placedFurnitureByRoom = {};

  // Background State
  bool _backgroundLoading = false;
  String? _backgroundError;
  String? _backgroundApplyingItemId;
  final Map<String, List<ShopItem>> _ownedBackgroundsByRoom = {};
  final Map<String, String?> _activeBackgroundByRoom = {};
  RealtimeChannel? _backgroundStateChannel;
  RealtimeChannel? _backgroundInventoryChannel;
  String? _backgroundSubscriptionRoomId;
  RealtimeChannel? _furnitureChannel;
  String? _furnitureSubscriptionRoomId;
  final Map<String, RealtimeChannel> _messageChannels = {};
  String? _chatOpenRoomId;
  final Set<String> _notifiedHungerAlertMessageIds = <String>{};
  final Set<String> _shownHungerAlertMessageIds = <String>{};

  // Latest feed (polaroid)
  String? _latestFeedImageUrl;
  List<String> _latestFeedImageUrls = <String>[];
  List<String?> _latestFeedCaptions = <String?>[];
  List<String?> _latestFeedSenderIds = <String?>[];
  List<DateTime?> _latestFeedSentAts = <DateTime?>[];
  List<String?> _latestFeedMessageIds = <String?>[];
  String? _latestFeedSenderId;
  String? _latestFeedCaption;
  String? _latestFeedOptimisticTempId;
  String? _latestFeedOptimisticRoomId;
  String? _latestFeedOptimisticPrevImageUrl;
  List<String>? _latestFeedOptimisticPrevImageUrls;
  List<String?>? _latestFeedOptimisticPrevCaptions;
  List<String?>? _latestFeedOptimisticPrevSenderIds;
  List<DateTime?>? _latestFeedOptimisticPrevSentAts;
  List<String?>? _latestFeedOptimisticPrevMessageIds;
  String? _latestFeedOptimisticPrevSenderId;
  String? _latestFeedOptimisticPrevCaption;
  int _latestFeedJumpToLatestEventId = 0;
  final Map<String, PendingPetHomeOptimisticFeed>
  _pendingOptimisticFeedsByTempId = {};
  String? _photoFoodImageSource;
  Offset? _photoFoodNormalizedPosition;
  bool _photoFoodDropping = false;
  int _photoFoodBiteStage = 0;
  bool _petEating = false;
  int _feedingAnimationToken = 0;
  final Map<String, ProfileSummary> _profileByUserId = {};
  bool _showingFeedDoubleRewardPrompt = false;
  String? _lastCrashContextRoomId;
  String? _lastCrashContextNetworkState;
  final GlobalKey _onboardingCreateRoomCtaKey = GlobalKey();
  final GlobalKey _onboardingJoinRoomCtaKey = GlobalKey();
  _BasicOnboardingStep _basicOnboardingStep = _BasicOnboardingStep.createPet;
  bool _basicOnboardingDismissed = false;
  bool _basicOnboardingCompleted = false;
  bool _basicOnboardingReady = false;
  bool _debugForceOnboardingHidden = false;
  bool _onboardingProfileSaving = false;
  String? _currentAppVersion =
      AppSettingsRepository.instance.lastLaunchedAppVersion;
  final Map<String, String> _unsupportedPetTypesByRoom = {};
  final Map<String, Set<String>> _unsupportedBackgroundItemIdsByRoom = {};
  final Map<String, int> _unsupportedPlacedFurnitureCountByRoom = {};
  final Set<String> _shownDecorCompatibilityPromptKeys = <String>{};
  bool _decorCompatibilityPromptShowing = false;

  @override
  void initState() {
    super.initState();
    _fcmService = ref.read(fcmServiceProvider);
    _rewardedAdsService = ref.read(rewardedAdsServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      CrashReportingService.instance.setContext(
        feature: 'home_view',
        lastAction: 'home_init_state',
      ),
    );
    _debugProPlan = AppSettingsRepository.instance.debugProPlanEnabled;
    _debugAlwaysShowOnboarding =
        AppSettingsRepository.instance.debugAlwaysShowOnboarding;
    unawaited(_refreshDebugAdminAccess());
    _notificationIntentSubscription = _fcmService.notificationIntents.listen((
      intent,
    ) {
      _pendingNotificationIntent = intent;
      _processPendingNotificationIntent();
    });
    _pendingNotificationIntent ??= _fcmService.takePendingNotificationIntent();
    unawaited(_ensureCurrentAppVersion());
    _selectNextPetStationaryState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_profileEnsured) {
        unawaited(_bootstrapHome());
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
                if (_petEating) {
                  _petStationaryState = _PetStationaryState.staying;
                } else {
                  _selectNextPetStationaryState();
                }
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AdMobIds.isSupported) {
        unawaited(_initializeRewardedAds());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_petAssetsPrecached) {
      _petAssetsPrecached = true;
      for (final pet in PetCatalog.pets) {
        _precachePetAssets(pet);
      }
      unawaited(_warmDepartureNoteFonts());
    }
    if (!_basicOnboardingLoadStarted) {
      _basicOnboardingLoadStarted = true;
      unawaited(_loadBasicOnboardingState());
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
    _unreadReconcileTimer?.cancel();
    _notificationIntentSubscription?.cancel();
    _feedingAnimationToken++;
    _onboardingProfileNicknameController.dispose();
    _petMoveController.dispose();
    _furnitureWiggleController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(_refreshDebugAdminAccess());
    unawaited(_refreshProPlanStatus());
    unawaited(_fcmService.refreshTokenSync());
    unawaited(_reconcileUnreadStateFromServer());
    _scheduleUnreadReconcile();
    if (!_showRoomSelection) {
      final activeRoomId = _roomId;
      if (activeRoomId != null) {
        unawaited(_refreshLatestFeed(activeRoomId));
      }
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

  Future<void> _warmDepartureNoteFonts() {
    if (_departureFontsWarmed) {
      return Future<void>.value();
    }
    _departureFontsWarmup ??= _loadDepartureNoteFonts();
    return _departureFontsWarmup!;
  }

  Future<void> _loadDepartureNoteFonts() async {
    const fontAssets = <(String, String)>[
      ('Heiseijyoji', 'assets/font/HeiseijyojiFont.otf'),
      ('ChildJPZh', 'assets/font/child_JP_zh.otf'),
      (
        'LittleKidsHandwriting',
        'assets/font/LittleKidsHandwriting-Regular.otf',
      ),
    ];
    for (final (family, assetPath) in fontAssets) {
      final loader = FontLoader(family)..addFont(rootBundle.load(assetPath));
      await loader.load();
    }
    _departureFontsWarmed = true;
  }

  Future<void> _initializeRewardedAds() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    await _rewardedAdsService.initialize(userId: userId);
    await _rewardedAdsService.preload(RewardedAdPlacement.doubleCoins);
  }

  Future<String?> _ensureCurrentAppVersion() async {
    final cached = _currentAppVersion?.trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final resolved = version.isEmpty ? null : version;
      if (!mounted) {
        _currentAppVersion = resolved;
        return resolved;
      }
      setState(() {
        _currentAppVersion = resolved;
      });
      return resolved;
    } catch (_) {
      return _currentAppVersion;
    }
  }

  void _updatePetType(String? petType) {
    final resolved = PetCatalog.resolveIdForAppVersion(
      petType,
      appVersion: _currentAppVersion,
    );
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
    _precachePetAssets(
      PetCatalog.byIdForAppVersion(resolved, appVersion: _currentAppVersion),
    );
  }

  // --- Logic Methods ---
  Future<void> _bootstrapHome() async {
    await _restoreHomeBootstrapCache();
    await _ensureProfile();
    await _refreshProPlanStatus();
    await _loadCoins();
    await _fetchRooms();
    if (mounted && _showRoomSelection) {
      await _refreshRoomSelectionHealthBars();
    }
    _homeBootstrapCompleted = true;
    _processPendingNotificationIntent();
  }

  void _processPendingNotificationIntent() {
    if (!mounted) {
      return;
    }
    final intent = _pendingNotificationIntent;
    if (intent == null || !_homeBootstrapCompleted) {
      return;
    }

    final roomIds = _myRooms
        .map((room) => room['id'])
        .whereType<String>()
        .toList(growable: false);
    final action = resolveNotificationRoomAction(
      intent: intent,
      roomIds: roomIds,
      currentRoomId: _roomId,
      showRoomSelection: _showRoomSelection,
      roomEntryLoading: _roomEntryLoading || _loadingRoom,
    );

    switch (action) {
      case NotificationRoomAction.ignore:
        return;
      case NotificationRoomAction.showRoomSelection:
        Navigator.of(context).popUntil((route) => route.isFirst);
        _pendingNotificationIntent = null;
        _setStateForRoomManager(() {
          _chatOpenRoomId = null;
          _showRoomSelection = true;
          _roomSelectionId =
              _roomSelectionId ?? (roomIds.isNotEmpty ? roomIds.first : null);
        });
        return;
      case NotificationRoomAction.showPetHome:
        Navigator.of(context).popUntil((route) => route.isFirst);
        _pendingNotificationIntent = null;
        _chatOpenRoomId = null;
        return;
      case NotificationRoomAction.openChat:
        Navigator.of(context).popUntil((route) => route.isFirst);
        if (_chatOpenRoomId == intent.roomId) {
          _pendingNotificationIntent = null;
          return;
        }
        _pendingNotificationIntent = null;
        _chatOpenRoomId = null;
        _openChatRoom();
        return;
      case NotificationRoomAction.switchRoomThenShowPetHome:
        Navigator.of(context).popUntil((route) => route.isFirst);
        _chatOpenRoomId = null;
        if (_showRoomSelection) {
          _enterRoomFromSelection(intent.roomId);
        } else {
          _switchRoom(intent.roomId, showEntryLoading: true);
        }
        return;
      case NotificationRoomAction.switchRoomThenOpenChat:
        Navigator.of(context).popUntil((route) => route.isFirst);
        _chatOpenRoomId = null;
        if (_showRoomSelection) {
          _enterRoomFromSelection(intent.roomId);
        } else {
          _switchRoom(intent.roomId, showEntryLoading: true);
        }
        return;
    }
  }

  Future<void> _restoreHomeBootstrapCache() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingRoom = false;
      });
      return;
    }
    try {
      final snapshot = await HomeBootstrapCacheRepository.instance.loadForUser(
        userId,
      );
      if (snapshot == null || !mounted) {
        return;
      }
      final cachedRoomsRaw = snapshot['rooms'];
      final cachedRooms = <Map<String, dynamic>>[];
      if (cachedRoomsRaw is List) {
        for (final item in cachedRoomsRaw) {
          if (item is Map) {
            cachedRooms.add(Map<String, dynamic>.from(item));
          }
        }
      }
      final sortedRooms = _applyLegacyRoomLocking(cachedRooms);
      final cachedRoomId = snapshot['room_id'] as String?;
      final cachedSelectionId = snapshot['room_selection_id'] as String?;
      setState(() {
        _coins = (snapshot['coins'] as num?)?.toInt() ?? _coins;
        _diamonds = (snapshot['diamonds'] as num?)?.toInt() ?? _diamonds;
        _myAvatarUrl = snapshot['my_avatar_url'] as String?;
        _myNickname = snapshot['my_nickname'] as String?;
        _myRooms = sortedRooms;
        _showRoomSelection = true;
        _roomId = sortedRooms.any((room) => room['id'] == cachedRoomId)
            ? cachedRoomId
            : null;
        _roomSelectionId =
            sortedRooms.any((room) => room['id'] == cachedSelectionId)
            ? cachedSelectionId
            : (sortedRooms.isNotEmpty
                  ? sortedRooms.first['id'] as String?
                  : null);
        _loadingRoom = false;
      });
      _syncOnboardingProfileDraftFromCurrentData();
      _syncCurrencyProvider();
      _syncRoomProviders();
      _syncUnreadCountsProvider(_myRooms);
      _evaluateBasicOnboardingAgainstCurrentData();
    } catch (_) {
      // Best effort. If cache read fails we continue with network bootstrap.
    }
  }

  Future<void> _cacheHomeBootstrapSnapshot() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    await HomeBootstrapCacheRepository.instance.saveForUser(
      userId: userId,
      snapshot: {
        'coins': _coins,
        'diamonds': _diamonds,
        'my_avatar_url': _myAvatarUrl,
        'my_nickname': _myNickname,
        'rooms': _myRooms,
        'room_id': _roomId,
        'room_selection_id': _roomSelectionId,
      },
    );
  }

  Future<T> _withNetworkTimeout<T>(Future<T> future) async {
    return future.timeout(_networkTimeout);
  }

  void _showOfflineSnackBar() {
    if (!mounted) {
      return;
    }
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Text(AppLocalizations.of(context)!.errorNetwork),
      ),
    );
  }

  Future<bool> _ensureOnlineForWrite() async {
    final now = DateTime.now();
    final lastCheck = _lastWriteOnlineCheckAt;
    if (lastCheck != null && now.difference(lastCheck) < _onlineProbeThrottle) {
      if (!_lastWriteOnlineCheckResult) {
        _showOfflineSnackBar();
      }
      return _lastWriteOnlineCheckResult;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _lastWriteOnlineCheckAt = now;
      _lastWriteOnlineCheckResult = false;
      return false;
    }
    try {
      await _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .select('user_id')
            .eq('user_id', userId)
            .maybeSingle(),
      );
      _lastWriteOnlineCheckAt = now;
      _lastWriteOnlineCheckResult = true;
      _syncCrashContextFromHome(networkState: 'online');
      return true;
    } catch (_) {
      _lastWriteOnlineCheckAt = now;
      _lastWriteOnlineCheckResult = false;
      _syncCrashContextFromHome(networkState: 'offline');
      _showOfflineSnackBar();
      return false;
    }
  }

  Future<void> _ensureProfile() async {
    final defaultNickname = AppLocalizations.of(
      context,
    )!.profileDefaultNickname;
    try {
      final localTimezone = await DeviceTimezoneService.instance.getTimezone();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return;
      }

      final profile = await _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .select('user_id,timezone')
            .eq('user_id', user.id)
            .maybeSingle(),
      );

      if (profile == null) {
        final insertPayload = <String, dynamic>{
          'user_id': user.id,
          'nickname': defaultNickname,
        };
        if (localTimezone != null) {
          insertPayload['timezone'] = localTimezone;
        }
        await _withNetworkTimeout(
          Supabase.instance.client.from('profiles').insert(insertPayload),
        );
      } else if (localTimezone != null) {
        final profileTimezone = (profile['timezone'] as String?)?.trim();
        if (profileTimezone == null || profileTimezone != localTimezone) {
          await _withNetworkTimeout(
            Supabase.instance.client
                .from('profiles')
                .update({'timezone': localTimezone})
                .eq('user_id', user.id),
          );
        }
      }
    } catch (_) {
      // Best-effort. Profile creation can be retried on next app open.
    }
  }

  Future<void> _loadCoins({int? expectedReward}) =>
      _loadCoinsInternal(expectedReward: expectedReward);

  Future<void> _loadCoinsInternal({int? expectedReward}) async {
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
      final profile = await _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .select('coins,diamonds,avatar_url,nickname')
            .eq('user_id', user.id)
            .maybeSingle(),
      );
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
      _syncOnboardingProfileDraftFromCurrentData();
      _syncCurrencyProvider();

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
          _syncCurrencyProvider();
        });
      }
      await _cacheHomeBootstrapSnapshot();
    } catch (_) {
      // Best-effort.
    } finally {
      _coinsLoadInFlight = false;

      final pending = _pendingCoinsExpectedReward;
      _pendingCoinsExpectedReward = null;
      if (pending != null && pending > 0) {
        unawaited(_loadCoinsInternal(expectedReward: pending));
      }
    }
  }

  Future<void> _debugUpdateProfileBalances({
    int coinDelta = 0,
    int diamondDelta = 0,
  }) async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
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
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (!await _ensureOnlineForWrite()) {
      return;
    }
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
      await _dispatchNewHungerAlerts(petId: petId, roomId: roomId);
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
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (!await _ensureOnlineForWrite()) {
      return;
    }
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
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (!await _ensureOnlineForWrite()) {
      return;
    }
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

  void _debugShowOverfedBubble() {
    if (!_isDebugAdmin) {
      return;
    }
    _overfedBubbleTimer?.cancel();
    setState(() {
      _lastOverfedAt = DateTime.now().toUtc();
      _showOverfedBubble = true;
    });
    _overfedBubbleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() => _showOverfedBubble = false);
    });
  }

  Future<void> _captureHomeMemorySnapshot({
    required String source,
    String? roomId,
    String? note,
  }) {
    return MemoryDiagnosticsService.instance.captureSnapshot(
      source: source,
      route: 'home_view',
      roomId: roomId ?? _roomId,
      note: note,
    );
  }

  Future<void> _captureDebugMemorySnapshot() async {
    final l10n = AppLocalizations.of(context)!;
    Navigator.pop(context);
    await _captureHomeMemorySnapshot(
      source: 'home_debug_manual_capture',
      note: 'debug_drawer',
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.drawerDebugMemorySnapshotCaptured)),
    );
  }

  Future<void> _clearImageCacheAndCaptureDebugSnapshot() async {
    final l10n = AppLocalizations.of(context)!;
    Navigator.pop(context);
    await MemoryDiagnosticsService.instance.clearImageCacheAndCapture(
      source: 'home_debug_clear_image_cache',
      route: 'home_view',
      roomId: _roomId,
      note: 'debug_drawer',
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.drawerDebugImageCacheCleared)));
  }

  Future<void> _openMemoryDiagnosticsSheet() async {
    Navigator.pop(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => MemoryDiagnosticsSheet(
        snapshotsListenable:
            MemoryDiagnosticsService.instance.snapshotsListenable,
      ),
    );
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
    _syncPetStateProvider();
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
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (_debugProPlan == value) {
      return;
    }
    setState(() {
      _debugProPlan = value;
      _myRooms = _applyLegacyRoomLocking(_myRooms);
    });
    _syncRoomProviders();
    try {
      await AppSettingsRepository.instance.setDebugProPlanEnabled(value);
    } catch (error) {
      debugPrint('[settings] failed to save debug pro plan: $error');
    }
  }

  Future<void> _setDebugAlwaysShowOnboarding(bool value) async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (_debugAlwaysShowOnboarding == value) {
      return;
    }
    setState(() {
      _debugAlwaysShowOnboarding = value;
      _debugForceOnboardingHidden = false;
    });
    if (value) {
      _applyDebugOnboardingOverrideIfNeeded();
    } else {
      unawaited(_loadBasicOnboardingState());
    }
    try {
      await AppSettingsRepository.instance.setDebugAlwaysShowOnboarding(value);
    } catch (error) {
      debugPrint('[settings] failed to save debug onboarding toggle: $error');
    }
  }

  bool get _hasProPlanAccess =>
      (_isDebugAdmin && _debugProPlan) || _revenueCatProPlan;

  Future<void> _refreshProPlanStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) {
        _revenueCatProPlan = false;
        return;
      }
      setState(() {
        _revenueCatProPlan = false;
        _myRooms = _applyLegacyRoomLocking(_myRooms);
      });
      _syncRoomProviders();
      return;
    }

    var hasProEntitlement = false;
    try {
      final configured = await _revenueCatService.configure(appUserId: userId);
      if (configured) {
        final info = await _revenueCatService.getCustomerInfo();
        final activeEntitlements = info?.entitlements.active.keys;
        hasProEntitlement =
            activeEntitlements?.any(
              (id) => id.toLowerCase() == _proEntitlementId.toLowerCase(),
            ) ??
            false;
      }
    } catch (error) {
      debugPrint('[iap] failed to refresh pro status: $error');
    }

    if (!mounted) {
      _revenueCatProPlan = hasProEntitlement;
      return;
    }
    if (_revenueCatProPlan == hasProEntitlement) {
      return;
    }
    setState(() {
      _revenueCatProPlan = hasProEntitlement;
      _myRooms = _applyLegacyRoomLocking(_myRooms);
    });
    _syncRoomProviders();
  }

  bool _isRoomLikelyDeparted(String roomId) {
    if (_departedPetsByRoom.containsKey(roomId)) {
      return true;
    }
    for (final room in _myRooms) {
      if (room['id'] != roomId) {
        continue;
      }
      final health = room['pet_health'] as num?;
      if (health != null && health <= 0) {
        return true;
      }
      break;
    }
    return false;
  }

  void _setRoomsState(List<Map<String, dynamic>> nextRooms) {
    setState(() {
      _myRooms = nextRooms;
    });
    _syncRoomProviders();
    _syncUnreadCountsProvider(nextRooms);
  }

  void _setStateForUnreadMutation(VoidCallback mutation) {
    setState(mutation);
    _syncRoomProviders();
    _syncUnreadCountsProvider(_myRooms);
  }

  void _syncUnreadCountsProvider(List<Map<String, dynamic>> rooms) {
    ref
        .read(homeUnreadCountsProvider.notifier)
        .replaceAll(unreadCountsByRoomFromRooms(rooms));
  }

  void _setStateForPetMovement(VoidCallback mutation) {
    setState(mutation);
  }

  void _refreshPetMovementFrame() {
    setState(() {});
  }

  void _setStateForFeedOrchestrator(VoidCallback mutation) {
    setState(mutation);
    _syncCurrencyProvider();
    _syncRoomProviders();
    _syncPetStateProvider();
    _syncCrashContextFromHome();
  }

  void _setStateForRoomManager(VoidCallback mutation) {
    setState(mutation);
    _syncRoomProviders();
    _syncPetStateProvider();
    _syncCrashContextFromHome();
  }

  void _setStateForOnboarding(VoidCallback mutation) {
    setState(mutation);
  }

  void _syncCrashContextFromHome({String? networkState, String? lastAction}) {
    final roomId = _roomId ?? 'none';
    final resolvedNetworkState =
        networkState ?? (_lastWriteOnlineCheckResult ? 'online' : 'offline');
    final roomChanged = _lastCrashContextRoomId != roomId;
    final networkChanged =
        _lastCrashContextNetworkState != resolvedNetworkState;
    if (!roomChanged && !networkChanged && lastAction == null) {
      return;
    }
    _lastCrashContextRoomId = roomId;
    _lastCrashContextNetworkState = resolvedNetworkState;
    unawaited(
      CrashReportingService.instance.setContext(
        feature: 'home_view',
        roomId: roomId,
        networkState: resolvedNetworkState,
        lastAction: lastAction,
      ),
    );
  }

  void _syncRoomProviders() {
    ref.read(homeRoomsProvider.notifier).replaceAll(_myRooms);
    ref.read(homeCurrentRoomIdProvider.notifier).set(_roomId);
    ref.read(homeRoomSelectionIdProvider.notifier).set(_roomSelectionId);
  }

  void _syncPetStateProvider() {
    ref
        .read(homePetStateProvider.notifier)
        .setSnapshot(
          petId: _petId,
          state: _petState,
          isReady: _petStateReady,
          isDeparted: _petDeparted,
        );
  }

  void _syncCurrencyProvider() {
    ref
        .read(homeCurrencyProvider.notifier)
        .setSnapshot(
          coins: _coins,
          diamonds: _diamonds,
          coinReward: _coinReward,
          coinRewardEventId: _coinRewardEventId,
        );
  }

  Map<String, dynamic>? get _effectivePetState {
    final snapshot = ref.read(homePetStateProvider);
    return snapshot.state ?? _petState;
  }

  bool get _effectivePetStateReady {
    final snapshot = ref.read(homePetStateProvider);
    return snapshot.isReady || _petStateReady;
  }

  bool get _effectivePetDeparted {
    final snapshot = ref.read(homePetStateProvider);
    return snapshot.isDeparted || _petDeparted;
  }

  void _setInviteCodeLoading(bool value) {
    setState(() {
      _inviteCodeLoading = value;
    });
  }

  void _applyGeneratedInviteCode({
    required String roomId,
    required String code,
  }) {
    setState(() {
      _showNewRoomInvitePrompt = false;
      _myRooms = _myRooms
          .map(
            (room) =>
                room['id'] == roomId ? {...room, 'invite_code': code} : room,
          )
          .toList();
    });
  }

  void _dismissNewRoomInvitePromptState() {
    if (!_showNewRoomInvitePrompt) {
      return;
    }
    setState(() {
      _showNewRoomInvitePrompt = false;
    });
  }

  ({int level, String petName})? _parseHungerAlertSystemBody(String? rawBody) {
    final raw = rawBody?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final level = raw.startsWith('hunger_alert_50::')
        ? 50
        : (raw.startsWith('hunger_alert_30::')
              ? 30
              : (raw.startsWith('hunger_alert_10::') ? 10 : null));
    if (level == null) {
      return null;
    }
    final separatorIndex = raw.indexOf('::');
    final petName = separatorIndex >= 0
        ? raw.substring(separatorIndex + 2).trim()
        : '';
    return (level: level, petName: petName.isEmpty ? 'Pet' : petName);
  }

  void _showHungerAlertSnackBar({required int level, required String petName}) {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final message = level <= 10
        ? l10n.chatPetHungryUrgentMessage(petName)
        : l10n.chatPetHungryReminderMessage(petName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  Future<bool> _ensureDebugAdminAccess() async {
    if (_isDebugAdmin) {
      return true;
    }
    await _refreshDebugAdminAccess();
    return _isDebugAdmin;
  }

  Future<void> _refreshDebugAdminAccess() async {
    final auth = Supabase.instance.client.auth;
    final user = auth.currentUser;
    if (user == null) {
      if (!mounted) {
        _isDebugAdmin = false;
      } else if (_isDebugAdmin) {
        setState(() => _isDebugAdmin = false);
      }
      return;
    }

    final debugSession = await ensureValidAccessTokenWithDebug();
    final isAdmin =
        _isAdminClaim(user.appMetadata) || _isAdminClaim(debugSession.claims);
    if (!mounted) {
      _isDebugAdmin = isAdmin;
      if (_isDebugAdmin) {
        _applyDebugOnboardingOverrideIfNeeded();
      }
      return;
    }
    if (_isDebugAdmin == isAdmin) {
      if (_isDebugAdmin) {
        _applyDebugOnboardingOverrideIfNeeded();
      }
      return;
    }
    setState(() {
      _isDebugAdmin = isAdmin;
      _myRooms = _applyLegacyRoomLocking(_myRooms);
    });
    _applyDebugOnboardingOverrideIfNeeded();
    _syncRoomProviders();
  }

  bool _isAdminClaim(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return false;
    }
    final direct =
        _asBool(data['is_admin']) ??
        _asBool(data['admin']) ??
        _asBool(data['isAdmin']);
    if (direct == true) {
      return true;
    }

    final role = data['role'] ?? data['app_role'] ?? data['user_role'];
    if (role is String && role.toLowerCase() == 'admin') {
      return true;
    }

    final roles = data['roles'];
    if (roles is List) {
      for (final roleEntry in roles) {
        if (roleEntry is String && roleEntry.toLowerCase() == 'admin') {
          return true;
        }
      }
    }
    return false;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return null;
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

  Future<void> _runFeedTest() async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
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

  double _healthValueFromHunger(num? hunger) {
    final value = (hunger?.toDouble() ?? 0.0) / 100;
    if (!value.isFinite) {
      return 0.0;
    }
    return value.clamp(0.0, 1.0);
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
      if (!mounted) {
        return;
      }
      if (petId == null) {
        setState(() => _petError = AppLocalizations.of(context)!.petNotFound);
        return;
      }

      _subscribeToPetState(petId);
      unawaited(_loadPetInfo(petId, roomId: roomId));

      if (tick) {
        await _tickPetStateAndDispatchAlerts(petId: petId, roomId: roomId);
      }

      final state = await Supabase.instance.client
          .from('pet_state')
          .select()
          .eq('pet_id', petId)
          .maybeSingle();
      if (!mounted) {
        return;
      }
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
      _syncPetStateProvider();
      if (state != null) {
        _cachePetState(roomId, petId, state);
      }
      _handleOverfedState();
      _handlePetDepartureState(roomId: roomId, petId: petId, state: state);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => _petError = AppLocalizations.of(
          context,
        )!.petSyncFailed(userFacingError(context, error)),
      );
      if (mounted && !_petStateReady) {
        setState(() {
          _petStateReady = true;
          if (_isRoomLikelyDeparted(roomId)) {
            _petDeparted = true;
          }
        });
        _syncPetStateProvider();
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
      _syncPetStateProvider();
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
    if (!await _ensureOnlineForWrite()) {
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
    _markRoomAsRead(roomId);
    _chatOpenRoomId = roomId;
    unawaited(
      _captureHomeMemorySnapshot(
        source: 'home_chat_route_push',
        roomId: roomId,
      ),
    );

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ChatRoomViewV2(
              roomId: roomId,
              backgroundDecoration: backgroundDecoration,
              isDarkBackground: isDarkBackground,
              petName: petName == null || petName.isEmpty
                  ? fallbackName
                  : petName,
              petAssetPath: petAssetPath,
              isPetDeparted: _petDeparted,
              isRoomLocked: isRoomLocked,
              onFeedSendStarted: _handleOptimisticFeed,
              onFeedUploaded: (result, _) => _handleFeedUploadCompleted(result),
              onFeedUploadFailed: _handleFeedUploadFailed,
            ),
          ),
        )
        .then((_) {
          if (_chatOpenRoomId == roomId) {
            _chatOpenRoomId = null;
          }
          unawaited(
            _captureHomeMemorySnapshot(
              source: 'home_chat_route_pop',
              roomId: roomId,
            ),
          );
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 350), () {
              if (!mounted) {
                return Future<void>.value();
              }
              return _captureHomeMemorySnapshot(
                source: 'home_chat_route_pop_settled',
                roomId: roomId,
              );
            }),
          );
          if (!mounted) {
            return;
          }
          _markRoomAsRead(roomId);
          _scheduleUnreadReconcile();
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
                onTapOutside: dismissKeyboardOnTapOutside,
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
    return _healthValueFromHunger(_effectivePetState?['hunger'] as num?);
  }

  String _departureHeroTag(String petId) => 'pet_departure_note_$petId';

  DepartedPetInfo? _currentDepartedPetInfo() {
    final roomId = _roomId;
    if (roomId == null) {
      return null;
    }
    return _departedPetsByRoom[roomId];
  }

  List<DepartedPetInfo> _departedPetsForCurrentRoom() {
    final current = _currentDepartedPetInfo();
    if (current == null) {
      return const <DepartedPetInfo>[];
    }
    return <DepartedPetInfo>[current];
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
      return PetCatalog.resolveIdForAppVersion(
        _petType,
        appVersion: _currentAppVersion,
      );
    }
    for (final room in _myRooms) {
      if (room['id'] != roomId) {
        continue;
      }
      final type = room['pet_type'] as String?;
      return PetCatalog.resolveIdForAppVersion(
        type,
        appVersion: _currentAppVersion,
      );
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
        _syncPetStateProvider();
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
      _syncPetStateProvider();
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
    await _warmDepartureNoteFonts();
    if (!mounted) {
      return;
    }
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

  void _queueRoomDecorHint(String roomId) {
    if (!mounted) {
      _showRoomDecorHint = true;
      _roomDecorHintRoomId = roomId;
      return;
    }
    setState(() {
      _showRoomDecorHint = true;
      _roomDecorHintRoomId = roomId;
    });
  }

  void _dismissRoomDecorHint() {
    if (!mounted) {
      _showRoomDecorHint = false;
      _roomDecorHintRoomId = null;
      return;
    }
    if (!_showRoomDecorHint && _roomDecorHintRoomId == null) {
      return;
    }
    setState(() {
      _showRoomDecorHint = false;
      _roomDecorHintRoomId = null;
    });
  }

  bool _shouldShowRoomDecorHintFor(String roomId) {
    return _showRoomDecorHint && _roomDecorHintRoomId == roomId;
  }

  Future<void> _openStoreWithDepartures() async {
    final result = await Navigator.of(context).push<ShopRouteResult>(
      MaterialPageRoute(
        builder: (_) => ShopView(
          roomId: _roomId,
          isProUser: _hasProPlanAccess,
          departedPets: _departedPetsForCurrentRoom(),
          onReturnPet: _returnDepartedPet,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    final returnedRoomId = result?.roomId;
    if (returnedRoomId != null && returnedRoomId.isNotEmpty) {
      if (_showRoomSelection) {
        setState(() {
          _showRoomSelection = false;
        });
      }
      if (_roomId != returnedRoomId) {
        _switchRoom(returnedRoomId, showEntryLoading: true);
      }
      if (result?.showRoomDecorHint == true) {
        _queueRoomDecorHint(returnedRoomId);
      }
    }
    await _refreshProPlanStatus();
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
      await _dispatchNewHungerAlerts(petId: pet.petId, roomId: pet.roomId);
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
    _syncPetStateProvider();

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
    if (mounted) {
      setState(() {
        _roomSelectionRefreshInFlight = true;
        _showRoomSelectionRefreshIndicator = true;
      });
    } else {
      _roomSelectionRefreshInFlight = true;
      _showRoomSelectionRefreshIndicator = true;
    }
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
            .select('id, room_id')
            .inFilter('room_id', roomIds);
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await Future.wait(
          pets.map((row) async {
            final petId = row['id'] as String?;
            final petRoomId = row['room_id'] as String?;
            if (petId == null || petId.isEmpty) {
              return;
            }
            try {
              await Supabase.instance.client.rpc(
                'tick_pet_state',
                params: {'p_pet_id': petId, 'p_now': nowIso},
              );
              if (petRoomId != null && petRoomId.isNotEmpty) {
                await _dispatchNewHungerAlerts(petId: petId, roomId: petRoomId);
              }
            } catch (_) {
              // Best-effort per room: continue refreshing others.
            }
          }),
        );
      } catch (_) {
        // Best-effort: still reload rooms below.
      }

      await _fetchRooms();
    } finally {
      if (mounted) {
        setState(() {
          _roomSelectionRefreshInFlight = false;
          _showRoomSelectionRefreshIndicator = false;
        });
      } else {
        _roomSelectionRefreshInFlight = false;
        _showRoomSelectionRefreshIndicator = false;
      }
    }
  }

  Future<void> _openStoreFromNav() async {
    await _openStoreWithDepartures();
  }

  Future<ProfileSummary?> _ensureProfileSummary(
    String userId, {
    bool forceRefresh = false,
  }) async {
    final cached = _profileByUserId[userId];
    if (cached != null && !forceRefresh) {
      return cached;
    }
    try {
      final summary = await ProfileCacheService.instance.getProfile(
        userId,
        forceRefresh: forceRefresh,
      );
      if (summary == null) {
        return null;
      }
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
      final supportsPetType = PetCatalog.supportsIdOnAppVersion(
        petType,
        _currentAppVersion,
      );
      final resolvedPetType = PetCatalog.resolveIdForAppVersion(
        petType,
        appVersion: _currentAppVersion,
      );
      final resolvedRoomId = expectedRoomId;
      if (!mounted) {
        _petName = name;
        _petLevel = level;
        _petExp = exp;
        _petType = resolvedPetType;
        if (resolvedRoomId != null) {
          if (supportsPetType) {
            _unsupportedPetTypesByRoom.remove(resolvedRoomId);
          } else if (petType != null && petType.isNotEmpty) {
            _unsupportedPetTypesByRoom[resolvedRoomId] = petType;
          }
        }
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
        if (resolvedRoomId != null) {
          if (supportsPetType) {
            _unsupportedPetTypesByRoom.remove(resolvedRoomId);
          } else if (petType != null && petType.isNotEmpty) {
            _unsupportedPetTypesByRoom[resolvedRoomId] = petType;
          }
        }
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
      _precachePetAssets(
        PetCatalog.byIdForAppVersion(
          resolvedPetType,
          appVersion: _currentAppVersion,
        ),
      );
      if (!supportsPetType && resolvedRoomId != null) {
        await _maybePromptForUnsupportedRoomDecor(resolvedRoomId);
      }
    } catch (_) {
      // Best-effort.
    }
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
      await _tickPetStateAndDispatchAlerts(petId: petId, roomId: roomId);
    } catch (_) {
      // Best-effort. This periodic tick should not disrupt the UI.
    }
  }

  Future<void> _tickPetStateAndDispatchAlerts({
    required String petId,
    required String roomId,
  }) async {
    await Supabase.instance.client.rpc(
      'tick_pet_state',
      params: {
        'p_pet_id': petId,
        'p_now': DateTime.now().toUtc().toIso8601String(),
      },
    );
    await _dispatchNewHungerAlerts(petId: petId, roomId: roomId);
  }

  Future<void> _dispatchNewHungerAlerts({
    required String petId,
    required String roomId,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    try {
      final state = await Supabase.instance.client
          .from('pet_state')
          .select(
            'hunger_alert_50_message_id,'
            'hunger_alert_50_triggered_by,'
            'hunger_alert_30_message_id,'
            'hunger_alert_30_triggered_by,'
            'hunger_alert_10_message_id,'
            'hunger_alert_10_triggered_by',
          )
          .eq('pet_id', petId)
          .maybeSingle();
      if (state == null) {
        return;
      }
      final alertCandidates =
          <({String? messageId, String? triggeredBy, int level})>[
            (
              messageId: state['hunger_alert_50_message_id'] as String?,
              triggeredBy: state['hunger_alert_50_triggered_by'] as String?,
              level: 50,
            ),
            (
              messageId: state['hunger_alert_30_message_id'] as String?,
              triggeredBy: state['hunger_alert_30_triggered_by'] as String?,
              level: 30,
            ),
            (
              messageId: state['hunger_alert_10_message_id'] as String?,
              triggeredBy: state['hunger_alert_10_triggered_by'] as String?,
              level: 10,
            ),
          ];
      for (final alert in alertCandidates) {
        final messageId = alert.messageId;
        if (messageId == null || messageId.isEmpty) {
          continue;
        }
        if (alert.triggeredBy != null && alert.triggeredBy != userId) {
          continue;
        }
        if (_notifiedHungerAlertMessageIds.contains(messageId)) {
          continue;
        }
        final sent = await _sendHungerAlertPush(
          roomId: roomId,
          messageId: messageId,
          level: alert.level,
        );
        if (sent) {
          _notifiedHungerAlertMessageIds.add(messageId);
        }
      }
    } catch (_) {
      // Best-effort. Notification dispatch should not block pet updates.
    }
  }

  Future<bool> _sendHungerAlertPush({
    required String roomId,
    required String messageId,
    required int level,
  }) async {
    try {
      final accessToken = await ensureValidAccessToken();
      if (accessToken == null) {
        return false;
      }
      final response = await Supabase.instance.client.functions.invoke(
        'notify_friend',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'type': 'hunger_alert',
          'room_id': roomId,
          'message_id': messageId,
          'alert_level': level,
        },
      );
      return response.status >= 200 && response.status < 300;
    } catch (_) {
      return false;
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

  List<_PlacedFurniture> _activeFurnitureForRoom() {
    final roomId = _roomId;
    if (roomId == null) {
      return const [];
    }
    return _placedFurnitureByRoom.putIfAbsent(roomId, () => []);
  }

  int _placedCountForItem(String itemId) {
    final placed = _activeFurnitureForRoom();
    return placed.where((item) => item.itemId == itemId).length;
  }

  int _availableFurnitureCount(String itemId) {
    final owned = _furnitureInventory[itemId] ?? 0;
    final placed = _placedCountForItem(itemId);
    return availableRoomFurnitureCount(totalOwned: owned, placedCount: placed);
  }

  Future<void> _loadFurnitureInventory() async {
    if (_furnitureLoading) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null) {
      setState(() {
        _furnitureCatalog.clear();
        _furnitureInventory.clear();
      });
      return;
    }
    if (Supabase.instance.client.auth.currentUser == null) {
      setState(() {
        _furnitureError = AppLocalizations.of(context)!.shopSignInPrompt;
      });
      return;
    }

    setState(() {
      _furnitureLoading = true;
      _furnitureError = null;
    });

    try {
      final appVersion = await _ensureCurrentAppVersion();
      final itemsResponse = appVersion == null || appVersion.isEmpty
          ? await Supabase.instance.client
                .from('items')
                .select(
                  'id,sku,type,name,price_coins,price_diamonds,metadata,is_active',
                )
                .eq('is_active', true)
          : await Supabase.instance.client.rpc(
              'get_visible_shop_items',
              params: {'p_app_version': appVersion},
            );
      final inventoryResponse = await Supabase.instance.client.rpc(
        'get_room_furniture_inventory',
        params: {'p_room_id': roomId},
      );
      if (!mounted) {
        return;
      }

      final items = (itemsResponse as List<dynamic>)
          .map((row) => ShopItem.fromJson(row as Map<String, dynamic>))
          .where((item) => item.isFurniture)
          .toList(growable: false);

      final inventory = <String, int>{};
      for (final row in inventoryResponse as List<dynamic>) {
        final itemId = row['item_id'] as String?;
        final quantity = row['total_quantity'] as int?;
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
      if (!mounted) {
        return;
      }
      setState(() {
        _furnitureError = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
      });
    } finally {
      if (mounted) {
        setState(() => _furnitureLoading = false);
      }
    }
  }

  Future<void> _loadRoomFurniture(String roomId) async {
    try {
      await _ensureCurrentAppVersion();
      final response = await Supabase.instance.client
          .from('room_furniture')
          .select(
            'id,item_id,owner_user_id,position_x,position_y,scale,items(id,sku,type,name,price_coins,price_diamonds,metadata)',
          )
          .eq('room_id', roomId);

      final placed = <_PlacedFurniture>[];
      var unsupportedCount = 0;
      for (final row in response as List<dynamic>) {
        final record = row as Map<String, dynamic>;
        final id = record['id'] as String?;
        final itemId = record['item_id'] as String?;
        if (id == null || itemId == null) {
          continue;
        }
        final itemData = record['items'] as Map<String, dynamic>?;
        if (!_supportsPlacedFurniture(itemData)) {
          unsupportedCount++;
          continue;
        }
        final ownerUserId = record['owner_user_id'] as String?;
        final posX = (record['position_x'] as num?)?.toDouble() ?? 0;
        final posY = (record['position_y'] as num?)?.toDouble() ?? 0;
        final scale = _parseFurnitureScale(record['scale']);
        final emoji = _resolveFurnitureEmoji(itemId, record);
        placed.add(
          _PlacedFurniture(
            id: id,
            itemId: itemId,
            ownerUserId: ownerUserId,
            emoji: emoji,
            normalizedPosition: Offset(posX, posY),
            persistedNormalizedPosition: Offset(posX, posY),
            scale: scale,
            persistedScale: scale,
            isPending: false,
          ),
        );
      }

      if (!mounted || _roomId != roomId) {
        return;
      }
      setState(() {
        _placedFurnitureByRoom[roomId] = placed;
        _unsupportedPlacedFurnitureCountByRoom[roomId] = unsupportedCount;
      });
      unawaited(_maybePromptForUnsupportedRoomDecor(roomId));
    } catch (error) {
      if (mounted) {
        setState(() {
          _furnitureError = AppLocalizations.of(
            context,
          )!.shopLoadFailed(userFacingError(context, error));
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
      callback: (_) => unawaited(_loadRoomFurniture(roomId)),
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
      callback: (_) => unawaited(_loadRoomFurniture(roomId)),
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
      callback: (_) => unawaited(_loadRoomFurniture(roomId)),
    );

    channel.subscribe();
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

  double _clampFurnitureScale(double scale) {
    return clampRoomFurnitureScale(scale);
  }

  double _parseFurnitureScale(dynamic value) {
    if (value is num) {
      return _clampFurnitureScale(value.toDouble());
    }
    if (value is String) {
      return _clampFurnitureScale(double.tryParse(value) ?? 1.0);
    }
    return 1.0;
  }

  Size _furnitureSizeForScale(double scale) {
    return roomFurnitureSizeForScale(
      baseSize: _furnitureItemSize,
      scale: scale,
    );
  }

  bool _isPlacedFurnitureSelected(_PlacedFurniture item) {
    return _selectedPlacedFurnitureId == item.id;
  }

  void _selectPlacedFurniture(_PlacedFurniture item) {
    setState(() {
      _selectedPlacedFurnitureId = item.id;
      _selectedFurnitureItemId = null;
    });
  }

  void _openFurnitureInventory() {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    _dismissRoomDecorHint();
    setState(() {
      _furnitureMode = true;
      _selectedFurnitureItemId = null;
      _selectedPlacedFurnitureId = null;
      _clearFurnitureDragGesture();
      _clearFurnitureScaleInteraction();
    });
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
      _selectedPlacedFurnitureId = null;
      _clearFurnitureDragGesture();
      _clearFurnitureScaleInteraction();
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
      await _ensureCurrentAppVersion();
      final response = await Supabase.instance.client
          .from('room_backgrounds')
          .select('item_id,items(*)')
          .eq('room_id', roomId);

      final items = <ShopItem>[];
      final unsupportedIds = <String>{};
      for (final row in response as List<dynamic>) {
        final record = row as Map<String, dynamic>;
        final itemData = record['items'] as Map<String, dynamic>?;
        if (itemData == null) {
          continue;
        }
        final item = ShopItem.fromJson(itemData);
        if (item.isBackground && _supportsBackgroundItem(item)) {
          items.add(item);
        } else if (item.isBackground) {
          final itemId = record['item_id'] as String?;
          if (itemId != null) {
            unsupportedIds.add(itemId);
          }
        }
      }

      if (!mounted || _roomId != roomId) {
        return;
      }
      setState(() {
        _ownedBackgroundsByRoom[roomId] = items;
        _unsupportedBackgroundItemIdsByRoom[roomId] = unsupportedIds;
      });
      unawaited(_maybePromptForUnsupportedRoomDecor(roomId));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _backgroundError = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
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
      unawaited(_maybePromptForUnsupportedRoomDecor(roomId));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _backgroundError = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
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

  List<ShopItem> _ownedBackgroundsForRoom(String roomId) {
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
    ShopItem? activeItem;
    for (final item in items) {
      if (item.id == activeItemId) {
        activeItem = item;
        break;
      }
    }
    return RoomBackgrounds.resolve(activeItem?.backgroundKey);
  }

  bool _supportsBackgroundItem(ShopItem item) {
    if (!item.isSupportedOnAppVersion(_currentAppVersion)) {
      return false;
    }
    return RoomBackgrounds.supportsKey(item.backgroundKey);
  }

  bool _supportsPlacedFurniture(Map<String, dynamic>? itemData) {
    if (itemData == null) {
      return false;
    }
    final item = ShopItem.fromJson(itemData);
    if (!item.isFurniture) {
      return false;
    }
    return item.isSupportedOnAppVersion(_currentAppVersion);
  }

  Future<void> _maybePromptForUnsupportedRoomDecor(String roomId) async {
    if (!mounted || _roomId != roomId || _decorCompatibilityPromptShowing) {
      return;
    }
    final hasUnsupportedPet = _unsupportedPetTypesByRoom.containsKey(roomId);
    final unsupportedBackgroundIds =
        _unsupportedBackgroundItemIdsByRoom[roomId] ?? const <String>{};
    final activeBackgroundId = _activeBackgroundByRoom[roomId];
    final hasUnsupportedBackground =
        activeBackgroundId != null &&
        unsupportedBackgroundIds.contains(activeBackgroundId);
    final hasUnsupportedFurniture =
        (_unsupportedPlacedFurnitureCountByRoom[roomId] ?? 0) > 0;
    if (!hasUnsupportedPet &&
        !hasUnsupportedBackground &&
        !hasUnsupportedFurniture) {
      return;
    }
    final promptKey =
        '$roomId:${_currentAppVersion ?? 'unknown'}:${hasUnsupportedPet ? 'pet' : 'no-pet'}:${hasUnsupportedBackground ? 'bg' : 'no-bg'}:${hasUnsupportedFurniture ? 'furniture' : 'no-furniture'}';
    if (_shownDecorCompatibilityPromptKeys.contains(promptKey)) {
      return;
    }
    _shownDecorCompatibilityPromptKeys.add(promptKey);
    _decorCompatibilityPromptShowing = true;
    final config = await AppConfigService().fetchForceUpdateConfig();
    final storeUrl = config?.storeUrl ?? AppConfigService.iosAppStoreUrl;
    if (!mounted || _roomId != roomId) {
      _decorCompatibilityPromptShowing = false;
      return;
    }
    try {
      await showAppDialog<void>(
        context: context,
        builder: (dialogContext) => AppDialog(
          tone: AppDialogTone.info,
          title: AppLocalizations.of(
            dialogContext,
          )!.roomDecorCompatibilityTitle,
          message: AppLocalizations.of(
            dialogContext,
          )!.roomDecorCompatibilityMessage,
          actions: [
            AppDialogAction.secondary(
              label: AppLocalizations.of(dialogContext)!.commonClose,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AppDialogAction.primary(
              label: AppLocalizations.of(dialogContext)!.forceUpdateAction,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(_launchCompatibilityUpdate(storeUrl));
              },
            ),
          ],
        ),
      );
    } finally {
      _decorCompatibilityPromptShowing = false;
    }
  }

  Future<void> _launchCompatibilityUpdate(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.forceUpdateLinkError),
          ),
        );
      }
    } catch (_) {}
  }

  SystemUiOverlayStyle _currentOverlayStyle() {
    // Room selection and loading screens use light background themes.
    if (_showRoomSelection || _loadingRoom || _roomEntryLoading) {
      return AppStatusBarStyles.light;
    }
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
      persistedNormalizedPosition: normalized,
      scale: 1.0,
      persistedScale: 1.0,
      isPending: true,
    );

    setState(() {
      _activeFurnitureForRoom().add(placed);
      _selectedPlacedFurnitureId = placed.id;
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

  _PlacedFurniture? _selectedPlacedFurniture() {
    final selectedId = _selectedPlacedFurnitureId;
    if (selectedId == null) {
      return null;
    }
    for (final item in _activeFurnitureForRoom()) {
      if (item.id == selectedId) {
        return item;
      }
    }
    return null;
  }

  void _clearFurnitureDragGesture() {
    _activeFurnitureDragId = null;
    _activeFurnitureDragStartNormalizedPosition = null;
  }

  void _handleFurnitureDragStart(_PlacedFurniture item) {
    setState(() {
      _selectedPlacedFurnitureId = item.id;
      _selectedFurnitureItemId = null;
      _activeFurnitureDragId = item.id;
      _activeFurnitureDragStartNormalizedPosition = item.normalizedPosition;
    });
  }

  void _handleFurnitureDragUpdate(
    _PlacedFurniture item,
    DragUpdateDetails details,
    Size fieldSize,
  ) {
    if (_activeFurnitureDragId != item.id) {
      return;
    }
    final itemSize = _furnitureSizeForScale(item.scale);
    final currentTopLeft = _positionFromNormalizedSized(
      item.normalizedPosition,
      fieldSize,
      itemSize,
    );
    final clampedTopLeft = _clampTopLeftSized(
      currentTopLeft + details.delta,
      fieldSize,
      itemSize,
    );
    final normalized = _normalizedFromTopLeftSized(
      clampedTopLeft,
      fieldSize,
      itemSize,
    );

    setState(() {
      _selectedPlacedFurnitureId = item.id;
      _selectedFurnitureItemId = null;
      item.normalizedPosition = normalized;
    });
  }

  void _handleFurnitureDragEnd(_PlacedFurniture item) {
    if (_activeFurnitureDragId != item.id) {
      return;
    }

    final startPosition = _activeFurnitureDragStartNormalizedPosition;
    _clearFurnitureDragGesture();
    if (item.isPending || startPosition == null) {
      return;
    }
    final positionChanged =
        (item.normalizedPosition - startPosition).distance > 0.001;
    if (!positionChanged) {
      return;
    }
    unawaited(_persistFurnitureTransform(item));
  }

  void _handleFurnitureDragCancel() {
    _clearFurnitureDragGesture();
  }

  void _beginFurnitureScaleInteraction(_PlacedFurniture item) {
    _activeFurnitureScaleInteractionItemId = item.id;
    _activeFurnitureScaleInteractionStartScale = item.scale;
    _activeFurnitureScaleInteractionStartNormalizedPosition =
        item.normalizedPosition;
  }

  void _clearFurnitureScaleInteraction() {
    _activeFurnitureScaleInteractionItemId = null;
    _activeFurnitureScaleInteractionStartScale = null;
    _activeFurnitureScaleInteractionStartNormalizedPosition = null;
  }

  void _applyFurnitureScale(
    _PlacedFurniture item,
    double nextScale, {
    bool persist = false,
  }) {
    final fieldSize = _petFieldSize();
    if (fieldSize == null) {
      return;
    }
    final currentSize = _furnitureSizeForScale(item.scale);
    final roundedScale = roundRoomFurnitureScaleToStep(nextScale);
    final nextSize = _furnitureSizeForScale(roundedScale);
    final nextNormalized = normalizedPositionAfterFurnitureResize(
      normalized: item.normalizedPosition,
      fieldSize: fieldSize,
      currentSize: currentSize,
      nextSize: nextSize,
    );
    setState(() {
      _selectedPlacedFurnitureId = item.id;
      _selectedFurnitureItemId = null;
      item.scale = roundedScale;
      item.normalizedPosition = nextNormalized;
    });
    if (persist) {
      unawaited(_persistFurnitureTransform(item));
    }
  }

  void _stepSelectedFurnitureScale(int stepDelta) {
    final item = _selectedPlacedFurniture();
    if (item == null) {
      return;
    }
    final nextScale = nudgeRoomFurnitureScale(item.scale, stepDelta: stepDelta);
    if ((nextScale - item.scale).abs() <= 0.001) {
      return;
    }
    _applyFurnitureScale(item, nextScale, persist: true);
  }

  void _handleFurnitureScaleChangeStart(double _) {
    final item = _selectedPlacedFurniture();
    if (item == null) {
      return;
    }
    _beginFurnitureScaleInteraction(item);
  }

  void _handleFurnitureScaleChanged(double value) {
    final item = _selectedPlacedFurniture();
    if (item == null) {
      return;
    }
    if (_activeFurnitureScaleInteractionItemId != item.id) {
      _beginFurnitureScaleInteraction(item);
    }
    _applyFurnitureScale(item, value);
  }

  void _handleFurnitureScaleChangeEnd(double _) {
    final item = _selectedPlacedFurniture();
    final startItemId = _activeFurnitureScaleInteractionItemId;
    final startScale = _activeFurnitureScaleInteractionStartScale;
    final startPosition =
        _activeFurnitureScaleInteractionStartNormalizedPosition;
    _clearFurnitureScaleInteraction();
    if (item == null ||
        item.isPending ||
        startItemId != item.id ||
        startScale == null ||
        startPosition == null) {
      return;
    }
    final scaleChanged = (item.scale - startScale).abs() > 0.001;
    final positionChanged =
        (item.normalizedPosition - startPosition).distance > 0.001;
    if (!scaleChanged && !positionChanged) {
      return;
    }
    unawaited(_persistFurnitureTransform(item));
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
          final previousId = list[index].id;
          final localScale = list[index].scale;
          final localPosition = list[index].normalizedPosition;
          final persistedPosition = list[index].persistedNormalizedPosition;
          final persistedScale = _parseFurnitureScale(response['scale']);
          final needsFollowUpPersist =
              (localScale - persistedScale).abs() > 0.001 ||
              (localPosition - persistedPosition).distance > 0.001;
          list[index]
            ..id = newId ?? list[index].id
            ..ownerUserId = response['owner_user_id'] as String?
            ..persistedScale = persistedScale
            ..persistedNormalizedPosition = persistedPosition
            ..isPending = false;
          list[index].scale = needsFollowUpPersist
              ? localScale
              : persistedScale;
          if (_selectedPlacedFurnitureId == previousId) {
            _selectedPlacedFurnitureId = list[index].id;
          }
          if (needsFollowUpPersist) {
            unawaited(_persistFurnitureTransform(list[index]));
          }
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

  Future<void> _persistFurnitureTransform(_PlacedFurniture item) async {
    if (item.isPending) {
      return;
    }
    try {
      await Supabase.instance.client.rpc(
        'update_room_furniture_scale',
        params: {'p_id': item.id, 'p_scale': item.scale},
      );
      await Supabase.instance.client.rpc(
        'update_room_furniture_position',
        params: {
          'p_id': item.id,
          'p_position_x': item.normalizedPosition.dx,
          'p_position_y': item.normalizedPosition.dy,
        },
      );
      item
        ..persistedScale = item.scale
        ..persistedNormalizedPosition = item.normalizedPosition;
    } catch (error) {
      if (mounted) {
        setState(() {
          _furnitureError = AppLocalizations.of(
            context,
          )!.shopLoadFailed(userFacingError(context, error));
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
      if (_selectedPlacedFurnitureId == item.id) {
        _selectedPlacedFurnitureId = null;
      }
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
          )!.shopLoadFailed(userFacingError(context, error));
        });
      }
      unawaited(_loadRoomFurniture(roomId));
    }
  }

  Widget _buildPetHomeCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldSize = constraints.biggest;
        final uiScale = homeUiScale(MediaQuery.sizeOf(context).width);
        final promptInset = 12 * uiScale;
        final furnitureHintLeft = 16 * uiScale;
        final furnitureHintBottom = 12 * uiScale;
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
                  top: promptInset,
                  right: promptInset,
                  child: _buildNewRoomInvitePrompt(),
                ),
              if (_furnitureMode)
                Positioned(
                  left: furnitureHintLeft,
                  bottom: furnitureHintBottom,
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
                  left: promptInset,
                  right: promptInset,
                  bottom: promptInset,
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
            message: l10n.shopTitle,
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
    final petState = _effectivePetState;
    final raw = petState?['poop_positions'];
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
      final poopAt = _parseOptionalDate(petState?['poop_at'])?.toUtc();
      if (poopAt != null && !poopAt.isAfter(DateTime.now().toUtc())) {
        spots.add(const _PoopSpot(index: 0, normalized: Offset(0.62, 0.72)));
      }
    }
    return spots;
  }

  Widget _buildPoopEmoji(int index) {
    final isPetDeparted = _effectivePetDeparted;
    return IgnorePointer(
      ignoring: _petBusy || isPetDeparted,
      child: GestureDetector(
        onTap: (_petBusy || isPetDeparted)
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

  Future<void> _cleanPoopAt(int index) async {
    final roomId = _roomId;
    if (roomId == null) return;
    if (_isRoomLocked(roomId)) {
      await _showRoomLockedDialog();
      return;
    }
    if (_effectivePetDeparted) {
      final info = _currentDepartedPetInfo();
      if (info != null) {
        await _showPetDepartureFlow(info);
      }
      return;
    }
    if (!await _ensureOnlineForWrite()) {
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
    final petState = _effectivePetState;
    if (_effectivePetDeparted) {
      return _buildDepartedPetPlaceholder();
    }
    if (!_effectivePetStateReady || petState == null) {
      return _buildPetLoadingPlaceholder();
    }
    final petVisualScale = _petVisualScale(MediaQuery.sizeOf(context).width);
    final overfedBubbleOffset = _overfedBubbleOffset(petVisualScale);
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
            Positioned(
              left: overfedBubbleOffset.dx,
              top: overfedBubbleOffset.dy,
              child: _buildOverfedBubble(),
            ),
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
                child: Transform.scale(
                  scale: petVisualScale,
                  child: _buildPetAvatar(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _petVisualScale(double screenWidth) {
    final responsive = HomeResponsiveSpec.fromWidth(screenWidth);
    return responsive.pick(
      compact: _petCompactVisualScale,
      regular: _petRegularVisualScale,
      expanded: _petExpandedVisualScale,
    );
  }

  Offset _overfedBubbleOffset(double petVisualScale) {
    final insetX = (_petAvatarSize.width * (1 - petVisualScale)) / 2;
    final insetY = (_petAvatarSize.height * (1 - petVisualScale)) / 2;
    final baseX = -_petAvatarSize.width * 0.06;
    final baseY = -_petAvatarSize.height * 0.54;
    return Offset(baseX + insetX, baseY + insetY);
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
            _furnitureSizeForScale(item.scale),
          ).dx,
          top: _positionFromNormalizedSized(
            item.normalizedPosition,
            fieldSize,
            _furnitureSizeForScale(item.scale),
          ).dy,
          child: _buildFurniturePiece(item, fieldSize),
        ),
    ];
  }

  Widget _buildFurniturePiece(_PlacedFurniture item, Size fieldSize) {
    final canEdit = _furnitureMode;
    final isSelected = _isPlacedFurnitureSelected(item);
    final itemSize = _furnitureSizeForScale(item.scale);
    final iconSize = 26 * _clampFurnitureScale(item.scale);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _openFurnitureInventory,
      onTap: canEdit ? () => _selectPlacedFurniture(item) : null,
      onPanStart: canEdit ? (_) => _handleFurnitureDragStart(item) : null,
      onPanUpdate: canEdit
          ? (details) => _handleFurnitureDragUpdate(item, details, fieldSize)
          : null,
      onPanEnd: canEdit ? (_) => _handleFurnitureDragEnd(item) : null,
      onPanCancel: canEdit ? _handleFurnitureDragCancel : null,
      child: AnimatedBuilder(
        animation: _furnitureWiggleController,
        builder: (context, child) {
          final angle = canEdit ? _furnitureWiggleAngle(item) : 0.0;
          return Transform.rotate(angle: angle, child: child);
        },
        child: AnimatedContainer(
          duration: 150.ms,
          width: itemSize.width,
          height: itemSize.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: canEdit
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: canEdit
                ? Border.all(
                    color: isSelected
                        ? const Color(0xFFFFB74D)
                        : Colors.black12,
                    width: isSelected ? 1.8 : 1,
                  )
                : null,
            boxShadow: canEdit
                ? [
                    BoxShadow(
                      color:
                          (isSelected ? const Color(0xFFFFB74D) : Colors.black)
                              .withValues(alpha: isSelected ? 0.2 : 0.08),
                      blurRadius: isSelected ? 10 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(item.emoji, style: TextStyle(fontSize: iconSize)),
              ),
              if (canEdit && isSelected)
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

  Widget? _buildFurnitureScaleControlBar() {
    if (!_furnitureMode) {
      return null;
    }
    final item = _selectedPlacedFurniture();
    if (item == null) {
      return null;
    }
    final canDecrease = item.scale > roomFurnitureMinScale + 0.001;
    final canIncrease = item.scale < roomFurnitureMaxScale - 0.001;
    final l10n = AppLocalizations.of(context)!;
    return HomeFurnitureScaleControls(
      label: l10n.furnitureScaleLabel,
      scale: item.scale,
      minScale: roomFurnitureMinScale,
      maxScale: roomFurnitureMaxScale,
      step: roomFurnitureScaleStep,
      decreaseLabel: l10n.furnitureScaleDecrease,
      increaseLabel: l10n.furnitureScaleIncrease,
      onDecrease: canDecrease ? () => _stepSelectedFurnitureScale(-1) : null,
      onIncrease: canIncrease ? () => _stepSelectedFurnitureScale(1) : null,
      onChanged: _handleFurnitureScaleChanged,
      onChangeStart: _handleFurnitureScaleChangeStart,
      onChangeEnd: _handleFurnitureScaleChangeEnd,
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
    final currency = ref.watch(homeCurrencyProvider);
    final petSnapshot = ref.watch(homePetStateProvider);
    final unreadCountByRoom = ref.watch(homeUnreadCountsProvider);
    final selectedRoomId = ref.watch(homeCurrentRoomIdProvider) ?? _roomId;
    final roomSelectionId =
        ref.watch(homeRoomSelectionIdProvider) ??
        _roomSelectionId ??
        selectedRoomId;
    if (_loadingRoom) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: const HomeLoadingView(),
      );
    }
    if (_roomEntryLoading && !_showRoomSelection && selectedRoomId != null) {
      final l10n = AppLocalizations.of(context)!;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: HomeLoadingView(
          message: l10n.roomEnteringLoading,
          showProgress: true,
        ),
      );
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (_showRoomSelection || selectedRoomId == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          drawer: _buildSideDrawer(),
          body: Stack(
            children: [
              RoomSelectionView(
                rooms: _myRooms,
                unreadCountByRoom: unreadCountByRoom,
                creatingRoom: _creatingRoom,
                joiningRoom: _joiningRoom,
                refreshingRooms: _showRoomSelectionRefreshIndicator,
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
                selectedRoomId: roomSelectionId,
                userAvatarUrl: _myAvatarUrl,
                currentAppVersion: _currentAppVersion,
                highlightCreateRoomCta: _isCreatePetOnboardingStepActive,
                createRoomCtaKey: _onboardingCreateRoomCtaKey,
                highlightJoinRoomCta: _isCreatePetOnboardingStepActive,
                joinRoomCtaKey: _onboardingJoinRoomCtaKey,
                topBanner: AdMobIds.isSupported && !_hasProPlanAccess
                    ? const AdMobBannerSlot()
                    : null,
              ),
              if (_isProfileSetupOnboardingStepActive)
                _buildProfileSetupOnboardingOverlay(),
              if (_shouldShowCreatePetOnboardingCoachCard)
                _buildBasicOnboardingFocusOverlay(),
              if (_shouldShowCreatePetOnboardingCoachCard)
                _buildBasicOnboardingCoachCard(),
            ],
          ),
        ),
      );
    }
    final activeRoomId = selectedRoomId;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('room-fade-$activeRoomId-$_roomEntryFadeVersion'),
        duration: _roomEntryFadeDuration,
        curve: Curves.easeInOut,
        tween: Tween<double>(begin: 0.0, end: 1.0),
        child: Scaffold(
          drawer: _buildSideDrawer(), // Room List Drawer
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              HomeRoomBackground(
                decoration: _currentBackgroundDefinition().decoration,
              ),
              HomeMainContent(
                bottomInset: bottomInset,
                statusBar: Builder(
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
                              (room) => room?['id'] == selectedRoomId,
                              orElse: () => null,
                            )?['pet_name']
                            as String?;
                    final resolvedPetName =
                        (_petName?.trim().isNotEmpty ?? false)
                        ? _petName!.trim()
                        : ((roomPetName?.trim().isNotEmpty ?? false)
                              ? roomPetName!.trim()
                              : l10n.petNameUnnamed);
                    final healthDebugValue =
                        ((petSnapshot.state ?? _petState)?['hunger'] as num?)
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
                      coins: currency.coins,
                      diamonds: currency.diamonds,
                      coinReward: currency.coinReward,
                      coinRewardEventId: currency.coinRewardEventId,
                      showRewardPending: _feedRewardPendingCount > 0,
                      rewardPendingLabel: l10n.feedRewardPending,
                      onPetTap: () => Scaffold.of(context).openDrawer(),
                      onPetNameTap: _openPetNameEditor,
                      onStoreTap: _openStoreFromNav,
                      onInviteTap: _generateInviteCode,
                      inviteLabel: l10n.roomInviteCta,
                      inviteLoading: _inviteCodeLoading,
                      onInventoryTap: _openFurnitureInventory,
                      inventoryLabel: l10n.roomInventoryCta,
                      showInventoryGuidance: _shouldShowRoomDecorHintFor(
                        activeRoomId,
                      ),
                      inventoryGuidanceTitle: l10n.roomDecorHintTitle,
                      onInventoryGuidanceDismiss: _dismissRoomDecorHint,
                    );
                  },
                ),
                photoGallery: PetPhotoGallery(
                  roomId: _roomId,
                  imageUrls: _latestFeedImageUrls,
                  captions: _latestFeedCaptions,
                  sentAts: _latestFeedSentAts,
                  messageIds: _latestFeedMessageIds,
                  isRefreshing: _latestFeedRefreshInFlight,
                  jumpToLatestEventId: _latestFeedJumpToLatestEventId,
                  senderAvatars: List<String?>.generate(
                    _latestFeedImageUrls.length,
                    (index) {
                      final senderId = index < _latestFeedSenderIds.length
                          ? _latestFeedSenderIds[index]
                          : null;
                      if (senderId == null || senderId.isEmpty) {
                        return null;
                      }
                      return _profileByUserId[senderId]?.avatarUrl;
                    },
                  ),
                  senderFallbackTexts: List<String?>.generate(
                    _latestFeedImageUrls.length,
                    (index) {
                      final senderId = index < _latestFeedSenderIds.length
                          ? _latestFeedSenderIds[index]
                          : null;
                      if (senderId == null || senderId.isEmpty) {
                        return null;
                      }
                      return _profileByUserId[senderId]?.nickname;
                    },
                  ),
                  onPlaceholderTap: _openFeedCamera,
                ),
                petHomeCard: _buildPetHomeCard(),
                bottomOverlay: _buildFurnitureScaleControlBar(),
                bottomNavBar: HomeBottomNavBar(
                  onHome: _onHomeNavPressed,
                  onCalendar: _openCalendar,
                  onCamera: _openFeedCamera,
                  onStore: _openStoreFromNav,
                  onChat: _openChatRoom,
                  cameraEnabled: true,
                  chatHasUnread: (unreadCountByRoom[activeRoomId] ?? 0) > 0,
                ),
              ),
              HomeFurnitureInventoryOverlay(
                visible: _furnitureMode,
                panel: HomeRoomInventoryPanel(
                  furnitureCatalog: _furnitureCatalog,
                  furnitureInventory: _furnitureInventory,
                  selectedFurnitureItemId: _selectedFurnitureItemId,
                  availableFurnitureCount: _availableFurnitureCount,
                  furnitureLoading: _furnitureLoading,
                  furnitureErrorText: _furnitureError,
                  backgroundItems: _ownedBackgroundsForRoom(activeRoomId),
                  activeBackgroundId: _activeBackgroundByRoom[activeRoomId],
                  backgroundLoading: _backgroundLoading,
                  backgroundErrorText: _backgroundError,
                  applyingBackgroundId: _backgroundApplyingItemId,
                  onClose: _closeFurnitureInventory,
                  onFurnitureTap: (itemId) {
                    setState(() {
                      _selectedFurnitureItemId = itemId;
                      _selectedPlacedFurnitureId = null;
                    });
                    _autoPlaceFurnitureFromInventory(itemId);
                  },
                  onBackgroundApply: _applyRoomBackground,
                ),
              ),
            ],
          ),
        ),
        builder: (context, value, child) => Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFFDF4E7))),
            Opacity(opacity: value, child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildPetAvatar() {
    final petColor = _petMoodColor();
    final petDefinition = PetCatalog.byId(_petType);

    final String asset;
    if (_petEating) {
      asset = petDefinition.stayAsset;
    } else if (_petIsMoving) {
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
    final petState = _effectivePetState;
    if (petState != null) {
      final mood = petState['mood'] as String? ?? 'low';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final faceLayout = ResponsiveLayout.fromSize(
          constraints.biggest,
          designSize: _petAvatarSize,
        );
        final eyeTop = faceLayout.y(20);
        final eyeInset = faceLayout.x(16);
        final eyeWidth = faceLayout.s(24);
        final eyeHeight = faceLayout.s(30);
        final highlightInset = faceLayout.s(4);
        final highlightSize = faceLayout.s(8);
        final mouthBottom = faceLayout.y(18);
        final mouthWidth = faceLayout.s(36);
        final mouthHeight = faceLayout.s(14);

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: eyeTop,
              left: eyeInset,
              child: _buildEye(
                width: eyeWidth,
                height: eyeHeight,
                highlightInset: highlightInset,
                highlightSize: highlightSize,
              ),
            ),
            Positioned(
              top: eyeTop,
              right: eyeInset,
              child: _buildEye(
                width: eyeWidth,
                height: eyeHeight,
                highlightInset: highlightInset,
                highlightSize: highlightSize,
              ),
            ),
            Positioned(
              bottom: mouthBottom,
              child: Container(
                width: mouthWidth,
                height: mouthHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(mouthHeight),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEye({
    required double width,
    required double height,
    required double highlightInset,
    required double highlightSize,
  }) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: EdgeInsets.all(highlightInset),
              width: highlightSize,
              height: highlightSize,
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
      debugActions: _isDebugAdmin
          ? ExpansionTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.drawerDebugTools),
              children: [
                ExpansionTile(
                  title: Text(l10n.drawerDebugCategorySimulation),
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
                      onTap: () => _fcmService.showTestNotification(),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(l10n.drawerDebugCategoryUser),
                  children: [
                    ListTile(
                      title: Text(l10n.drawerDebugAddCandy),
                      onTap: () => _debugUpdateProfileBalances(coinDelta: 100),
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugAddDiamonds),
                      onTap: () =>
                          _debugUpdateProfileBalances(diamondDelta: 100),
                    ),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.only(left: 16, right: 8),
                      title: Text(l10n.drawerDebugTogglePlan),
                      subtitle: Text(
                        _hasProPlanAccess
                            ? l10n.drawerProPlan
                            : l10n.drawerFreePlan,
                      ),
                      value: _debugProPlan,
                      onChanged: (value) => unawaited(_setDebugProPlan(value)),
                    ),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.only(left: 16, right: 8),
                      title: Text(l10n.drawerDebugForceOnboarding),
                      subtitle: Text(
                        _debugAlwaysShowOnboarding
                            ? l10n.drawerDebugForceOnboardingEnabled
                            : l10n.drawerDebugForceOnboardingDisabled,
                      ),
                      value: _debugAlwaysShowOnboarding,
                      onChanged: (value) =>
                          unawaited(_setDebugAlwaysShowOnboarding(value)),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(l10n.drawerDebugCategoryPet),
                  children: [
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
                      onTap: (_petBusy || _roomId == null)
                          ? null
                          : _debugSpawnPetPoop,
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugShowFullBubble),
                      onTap:
                          (_effectivePetState == null ||
                              !_effectivePetStateReady ||
                              _effectivePetDeparted)
                          ? null
                          : _debugShowOverfedBubble,
                    ),
                    if (_petError != null)
                      ListTile(
                        title: Text(l10n.drawerPetError),
                        subtitle: Text(_petError!),
                      ),
                  ],
                ),
                ExpansionTile(
                  title: Text(l10n.drawerDebugCategoryMemory),
                  children: [
                    ListTile(
                      title: Text(l10n.drawerDebugCaptureMemorySnapshot),
                      onTap: _captureDebugMemorySnapshot,
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugClearImageCacheSnapshot),
                      onTap: _clearImageCacheAndCaptureDebugSnapshot,
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugOpenMemoryDiagnostics),
                      onTap: _openMemoryDiagnosticsSheet,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(l10n.drawerDebugCategorySystem),
                  children: [
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
                    ListTile(
                      title: Text(l10n.drawerDebugTestWhatsNew),
                      onTap: () {
                        Navigator.pop(context);
                        ForceUpdateDebugTool.instance.showWhatsNewPrompt();
                      },
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugTestCrashReport),
                      onTap: () {
                        Navigator.pop(context);
                        unawaited(
                          CrashReportingService.instance.triggerTestCrash(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            )
          : null,
    );
  }
}

class _PetExpUpdate {
  final int level;
  final int exp;

  const _PetExpUpdate({required this.level, required this.exp});
}

class _FeedDoubleRewardPrompt extends StatelessWidget {
  const _FeedDoubleRewardPrompt({
    required this.title,
    required this.message,
    required this.watchLabel,
    required this.cancelLabel,
    required this.onWatch,
    required this.onCancel,
  });

  final String title;
  final String message;
  final String watchLabel;
  final String cancelLabel;
  final VoidCallback onWatch;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const horizontalPadding = 16.0;
    const bottomNavHeight = 74.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCancel,
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: bottomInset + bottomNavHeight,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF6DC), Color(0xFFFFEDD2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFF4C46A),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7A4C11).withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF9C95F),
                                    Color(0xFFF2A53A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF2A53A,
                                    ).withValues(alpha: 0.34),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'x2',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.35,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: onCancel,
                              borderRadius: BorderRadius.circular(16),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onCancel,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 46),
                                  side: BorderSide(
                                    color: const Color(
                                      0xFFE4C58D,
                                    ).withValues(alpha: 0.95),
                                  ),
                                  foregroundColor: AppTheme.textSecondary,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.48,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(cancelLabel),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: onWatch,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 46),
                                  backgroundColor: const Color(0xFFF2A53A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  watchLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
