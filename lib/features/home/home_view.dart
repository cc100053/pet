import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
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
import '../../services/invite/invite_link_service.dart';
import '../../services/profile/profile_cache_service.dart';
import '../../services/profile/profile_bootstrap_service.dart';
import '../../services/review/review_prompt_service.dart';
import '../../services/settings/app_settings_repository.dart';

import '../../services/label_mapping/label_mapping_service.dart';
import '../../services/performance/memory_diagnostics_service.dart';
import '../../shared/compatibility/shared_decor_compatibility.dart';
import '../../shared/debug/memory_diagnostics_sheet.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/force_update/force_update_debug_tool.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/avatar_position_editor_page.dart';
import '../../shared/ui/juice_wrappers.dart';
import '../../shared/ui/keyboard_dismiss_utils.dart';
import '../../shared/ui/responsive_layout.dart';
import '../../shared/ui/status_bar_style.dart';
import '../../shared/ui/user_avatar.dart';
import '../../shared/upload_limits.dart';
import '../../shared/utils/avatar_display_position.dart';
import '../chat/chat_room_view_v2.dart';
import '../ads/admob_banner_slot.dart';
import '../feed/feed_capture_view.dart';
import '../feed/feed_upload_queue.dart';
import '../gallery/memory_calendar_view.dart';
import '../pet/equipment_catalog.dart';
import '../pet/pet_animation_frames.dart';
import '../pet/pet_animated_image.dart';
import '../pet/pet_catalog.dart';
import '../pet/pet_sockets.dart';
import '../pet/leveling.dart';
import '../pet/pet_departure.dart';
import '../pet/pet_departure_note_view.dart';
import '../pet/pet_selection_page.dart';
import '../profile/profile_view.dart';
import '../shop/models/shop_item.dart';
import '../shop/shop_view.dart';
import 'debug/dress_up_fit_tool_page.dart';
import 'debug/equipment_preview_page.dart';
import 'home_furniture_inventory_utils.dart';
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
import 'widgets/pet_equipment_overlay.dart';
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
part 'home_view_pet_scene_builders.dart';
part 'home_view_drawer.dart';
part 'home_view_data_helpers.dart';

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
  final Map<String, List<_RoomPet>> _roomPetsByRoom = {};
  final Map<String, _ExtraPetRuntime> _extraPetRuntime = {};
  String? _visibleNameTagPetId;
  Timer? _nameTagFadeTimer;
  bool _multiPetNamingShown = false;
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
  String? _coinRewardLabel;
  int _coinRewardEventId = 0;
  int _feedRewardPendingCount = 0;
  bool _coinsLoadInFlight = false;
  int? _pendingCoinsExpectedReward;
  bool _roomSelectionRefreshInFlight = false;
  bool _showRoomSelectionRefreshIndicator = false;
  List<Map<String, dynamic>> _myRooms = []; // Stores room info
  RealtimeChannel? _petStateChannel;
  String? _petSubscriptionPetId;
  RealtimeChannel? _roomPetsChannel;
  String? _roomPetsSubscriptionRoomId;
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

  // Equipment State
  bool _equipmentLoading = false;
  String? _equipmentError;
  bool _showSocketDebug = false;
  final List<ShopItem> _ownedEquipmentItems = <ShopItem>[];
  final Map<String, _EquippedPetItem> _equippedItemsBySlot = {};
  final Map<String, Map<String, String>> _roomEquippedSkusBySlot = {};
  RealtimeChannel? _petEquipmentChannel;
  RealtimeChannel? _roomSelectionEquipmentChannel;
  String? _petEquipmentSubscriptionRoomId;

  // Background State
  bool _backgroundLoading = false;
  String? _backgroundError;
  String? _backgroundApplyingItemId;
  final Map<String, List<ShopItem>> _ownedBackgroundsByRoom = {};
  final Map<String, String?> _activeBackgroundByRoom = {};
  RealtimeChannel? _backgroundStateChannel;
  RealtimeChannel? _backgroundInventoryChannel;
  RealtimeChannel? _roomInventoryRevisionChannel;
  String? _backgroundSubscriptionRoomId;
  RealtimeChannel? _furnitureChannel;
  String? _furnitureSubscriptionRoomId;
  String? _roomInventoryRevisionSubscriptionRoomId;
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
  late final FeedUploadQueueNotifier _feedUploadQueue;
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
  StreamSubscription<String>? _inviteLinkSubscription;
  bool _pendingInviteJoinRunning = false;
  final Set<String> _handledFeedUploadTerminalTempIds = <String>{};

  @override
  void initState() {
    super.initState();
    _fcmService = ref.read(fcmServiceProvider);
    _rewardedAdsService = ref.read(rewardedAdsServiceProvider);
    _feedUploadQueue = ref.read(feedUploadQueueProvider.notifier);
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
    _inviteLinkSubscription = AppInviteLinkService.instance.inviteCodes.listen((
      _,
    ) {
      unawaited(_processPendingInviteLink());
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
    unawaited(_feedUploadQueue.resumePendingJobs());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _replayUnacknowledgedFeedUploadEvents();
      }
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
    final petStateChannel = _petStateChannel;
    final petEquipmentChannel = _petEquipmentChannel;
    final roomSelectionEquipmentChannel = _roomSelectionEquipmentChannel;
    final furnitureChannel = _furnitureChannel;
    final backgroundStateChannel = _backgroundStateChannel;
    final backgroundInventoryChannel = _backgroundInventoryChannel;
    final roomInventoryRevisionChannel = _roomInventoryRevisionChannel;
    final roomPetsChannel = _roomPetsChannel;
    _petStateChannel = null;
    _petEquipmentChannel = null;
    _roomSelectionEquipmentChannel = null;
    _furnitureChannel = null;
    _backgroundStateChannel = null;
    _backgroundInventoryChannel = null;
    _roomInventoryRevisionChannel = null;
    _roomPetsChannel = null;
    _roomPetsSubscriptionRoomId = null;
    unawaited(_removeRealtimeChannel(petStateChannel));
    unawaited(_removeRealtimeChannel(petEquipmentChannel));
    unawaited(_removeRealtimeChannel(roomSelectionEquipmentChannel));
    unawaited(_removeRealtimeChannel(furnitureChannel));
    unawaited(_removeRealtimeChannel(backgroundStateChannel));
    unawaited(_removeRealtimeChannel(backgroundInventoryChannel));
    unawaited(_removeRealtimeChannel(roomInventoryRevisionChannel));
    unawaited(_removeRealtimeChannel(roomPetsChannel));
    _overfedBubbleTimer?.cancel();
    for (final channel in _messageChannels.values) {
      unawaited(_removeRealtimeChannel(channel));
    }
    _messageChannels.clear();
    _wanderTimer?.cancel();
    _petTickTimer?.cancel();
    _nameTagFadeTimer?.cancel();
    for (final runtime in _extraPetRuntime.values) {
      runtime.disposeTimers();
    }
    _roomSelectionRefreshTimer?.cancel();
    _unreadReconcileTimer?.cancel();
    _notificationIntentSubscription?.cancel();
    _inviteLinkSubscription?.cancel();
    _feedingAnimationToken++;
    _onboardingProfileNicknameController.dispose();
    _petMoveController.dispose();
    _furnitureWiggleController.dispose();
    super.dispose();
  }

  Future<void> _removeRealtimeChannel(RealtimeChannel? channel) async {
    if (channel == null) {
      return;
    }
    try {
      await Supabase.instance.client.removeChannel(channel);
    } catch (_) {
      try {
        await channel.unsubscribe();
      } catch (_) {
        // Best-effort cleanup; widget disposal must not fail user flows.
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(_refreshDebugAdminAccess());
    unawaited(_refreshProPlanStatus());
    unawaited(_feedUploadQueue.resumePendingJobs());
    _replayUnacknowledgedFeedUploadEvents();
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
    for (final asset in PetAnimationFrames.frameAssetsForPetSources(
      PetCatalog.assetPaths(pet),
    )) {
      if (_cachedPetAssets.add(asset)) {
        precacheImage(AssetImage(asset), context);
      }
    }
  }

  void _precacheEquippedAssets(Iterable<String> skus) {
    for (final sku in skus) {
      final definition = EquipmentCatalog.bySku(sku);
      final asset = definition?.assetPath.trim();
      if (asset != null && asset.isNotEmpty && _cachedPetAssets.add(asset)) {
        precacheImage(AssetImage(asset), context);
      }
    }
  }

  Map<String, String> _equippedSkusFromItemsBySlot(
    Map<String, _EquippedPetItem> itemsBySlot,
  ) {
    return itemsBySlot.map((slot, item) => MapEntry(slot, item.sku));
  }

  Map<String, String> get _equippedSkusBySlot =>
      _equippedSkusFromItemsBySlot(_equippedItemsBySlot);

  Map<String, String> get _equippedItemIdsBySlot =>
      _equippedItemsBySlot.map((slot, item) => MapEntry(slot, item.itemId));

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
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final resolved = version.isEmpty ? null : version;
      if (!mounted) {
        _currentAppVersion = resolved;
        return resolved;
      }
      if (resolved != cached) {
        setState(() {
          _currentAppVersion = resolved;
        });
      }
      return resolved;
    } catch (_) {
      return cached != null && cached.isNotEmpty ? cached : _currentAppVersion;
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
    unawaited(_processPendingInviteLink());
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
    showJuiceToast(
      context: context,
      message: AppLocalizations.of(context)!.errorNetwork,
      tone: AppDialogTone.warning,
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
    try {
      await _withNetworkTimeout(
        ProfileBootstrapService.instance.ensureProfile(
          defaultNickname: AppLocalizations.of(context)!.profileDefaultNickname,
          selectClause: 'user_id,timezone',
        ),
      );
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
          _coinRewardLabel = null;
        }

        // Trigger animation for reward-expected loads only when the balance
        // actually increased (cooldown/no-op stays quiet).
        if (expectedReward != null && newValue > oldValue) {
          _coinReward = newValue - oldValue;
          _coinRewardLabel = null;
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
            _coinRewardLabel = null;
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
    showJuiceSnackbar(
      context: context,
      message: l10n.drawerDebugMemorySnapshotCaptured,
      tone: AppDialogTone.success,
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
    showJuiceSnackbar(
      context: context,
      message: l10n.drawerDebugImageCacheCleared,
      tone: AppDialogTone.success,
    );
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

  Offset _nextPoopPosition() {
    final x = (_random.nextDouble() * 0.6) + 0.2;
    final y = (_random.nextDouble() * 0.4) + 0.55;
    return Offset(x, y);
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

  void _debugShowProfileSetupOnboarding() {
    if (!_isDebugAdmin) {
      return;
    }
    final defaultNickname = _defaultProfileNickname;
    _onboardingProfileNicknameController
      ..text = defaultNickname
      ..selection = TextSelection.collapsed(offset: defaultNickname.length);

    setState(() {
      _debugAlwaysShowOnboarding = true;
      _debugForceOnboardingHidden = false;
      _basicOnboardingReady = true;
      _basicOnboardingDismissed = false;
      _basicOnboardingCompleted = false;
      _basicOnboardingStep = _BasicOnboardingStep.profileSetup;
      _showRoomSelection = true;
      _onboardingProfileSaving = false;
      _onboardingProfileError = null;
      _onboardingProfileAvatarUrl = '';
    });
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
          coinRewardLabel: _coinRewardLabel,
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
    showJuiceToast(
      context: context,
      message: message,
      tone: AppDialogTone.warning,
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

  Future<void> _signOut() async {
    AnalyticsService.instance.logEvent('sign_out_tap');
    unawaited(Supabase.instance.client.auth.signOut());
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
    final room = await Supabase.instance.client
        .from('rooms')
        .select('main_pet_id')
        .eq('id', roomId)
        .maybeSingle();
    final mainPetId = room?['main_pet_id'] as String?;
    if (mainPetId != null && mainPetId.isNotEmpty) {
      return mainPetId;
    }

    final response = await Supabase.instance.client
        .from('pets')
        .select('id')
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .limit(1);
    if (response.isNotEmpty) {
      return response.first['id'] as String?;
    }
    return null;
  }

  void _subscribeToRoomPets(String roomId) {
    if (_roomPetsSubscriptionRoomId == roomId && _roomPetsChannel != null) {
      return;
    }

    final previousChannel = _roomPetsChannel;
    _roomPetsChannel = null;
    unawaited(_removeRealtimeChannel(previousChannel));
    _roomPetsSubscriptionRoomId = roomId;

    final channel = Supabase.instance.client.channel('room_pets_$roomId');
    _roomPetsChannel = channel;

    void handleChange() {
      if (!mounted || _roomPetsSubscriptionRoomId != roomId) {
        return;
      }
      unawaited(_loadRoomPets(roomId));
    }

    for (final table in const ['pets', 'room_extra_pets']) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (_) => handleChange(),
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (_) => handleChange(),
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (_) => handleChange(),
      );
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'rooms',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: roomId,
      ),
      callback: (_) => handleChange(),
    );

    channel.subscribe();
  }

  Future<void> _loadRoomPets(String roomId) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_room_pets',
        params: {'p_room_id': roomId},
      );
      if (response is! List) {
        return;
      }
      final pets = <_RoomPet>[];
      for (final row in response) {
        if (row is! Map) {
          continue;
        }
        final petId = row['pet_id'] as String?;
        if (petId == null || petId.isEmpty) {
          continue;
        }
        final rawType = PetCatalog.typeFromColorDna(row['color_dna']);
        final resolvedType = PetCatalog.resolveIdForAppVersion(
          rawType,
          appVersion: _currentAppVersion,
        );
        final rawName = row['name'];
        pets.add(
          _RoomPet(
            petId: petId,
            petType: resolvedType,
            isMain: row['is_main'] == true,
            name: rawName is String && rawName.trim().isNotEmpty
                ? rawName.trim()
                : null,
          ),
        );
      }
      if (!mounted || _roomId != roomId) {
        return;
      }
      final livePetIds = pets.map((p) => p.petId).toSet();
      setState(() {
        _roomPetsByRoom[roomId] = pets;
        _extraPetRuntime.removeWhere((id, runtime) {
          final stale = !livePetIds.contains(id);
          if (stale) runtime.disposeTimers();
          return stale;
        });
      });
      _maybeShowMultiPetNamingPrompt(pets);
    } catch (_) {
      // Best-effort: the main pet path can still render the room.
    }
  }

  void _showPetNameTag(String petId) {
    _nameTagFadeTimer?.cancel();
    setState(() {
      _visibleNameTagPetId = petId;
    });
    _nameTagFadeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted || _visibleNameTagPetId != petId) {
        return;
      }
      setState(() {
        _visibleNameTagPetId = null;
      });
    });
  }

  Offset _randomExtraPetTarget() {
    return Offset(
      0.05 + _random.nextDouble() * 0.90,
      0.20 + _random.nextDouble() * 0.70,
    );
  }

  /// Picks a wander target that keeps a small breathing distance from all
  /// other pets' positions. "Lightweight" per design doc: pets may get close
  /// (almost-touching) but never spawn directly on top of each other.
  Offset _pickWanderTargetAvoiding(List<Offset> avoidPositions) {
    const minDistance = 0.08;
    Offset best = _randomExtraPetTarget();
    var bestMinDist = -1.0;
    for (var attempt = 0; attempt < 8; attempt++) {
      final candidate = _randomExtraPetTarget();
      var nearest = double.infinity;
      for (final other in avoidPositions) {
        final d = (candidate - other).distance;
        if (d < nearest) nearest = d;
      }
      if (nearest >= minDistance) {
        return candidate;
      }
      if (nearest > bestMinDist) {
        bestMinDist = nearest;
        best = candidate;
      }
    }
    return best;
  }

  _ExtraPetRuntime _ensureExtraPetRuntime(String petId, int seedIndex) {
    final existing = _extraPetRuntime[petId];
    if (existing != null) {
      return existing;
    }
    // Spawn at a default scattered position so first paint is not (0,0).
    const defaults = [
      Offset(0.32, 0.73),
      Offset(0.70, 0.72),
      Offset(0.50, 0.60),
      Offset(0.22, 0.58),
    ];
    final seed = defaults[seedIndex % defaults.length];
    final runtime = _ExtraPetRuntime(
      normalizedPosition: seed,
      normalizedTarget: seed,
      animDuration: Duration.zero,
    );
    _extraPetRuntime[petId] = runtime;
    return runtime;
  }

  Duration _extraPetTravelDuration(Offset from, Offset to, Size fieldSize) {
    final fromPx = _positionFromNormalized(from, fieldSize);
    final toPx = _positionFromNormalized(to, fieldSize);
    final distance = (toPx - fromPx).distance;
    final ms = (distance / _HomeViewState._petMoveSpeed * 1000).round();
    return Duration(milliseconds: max(_HomeViewState._minMoveMs, ms));
  }

  _PetStationaryState _pickStationaryStateForNow() {
    final probability = _sleepProbabilityForLocalHour(DateTime.now().hour);
    return _random.nextDouble() < probability
        ? _PetStationaryState.sleeping
        : _PetStationaryState.staying;
  }

  /// Marks an extra pet as walking toward its current target, then flips it
  /// back to a stationary (stay/sleep) state once the travel duration elapses
  /// — mirroring the main pet's walk → idle behavior.
  void _beginExtraPetWalk(String petId, Duration duration) {
    final runtime = _extraPetRuntime[petId];
    if (runtime == null) return;
    runtime.isWalking = true;
    runtime.arrivalTimer?.cancel();
    runtime.arrivalTimer = Timer(duration, () {
      if (!mounted) return;
      final rt = _extraPetRuntime[petId];
      if (rt == null || rt.isDragging) return;
      setState(() {
        rt.isWalking = false;
        rt.stationaryState = _pickStationaryStateForNow();
      });
    });
  }

  void _summonExtraPetsToFood(Offset foodTarget, Size fieldSize) {
    if (!mounted) return;
    final roomId = _roomId;
    if (roomId == null) return;
    final pets = _roomPetsByRoom[roomId] ?? const <_RoomPet>[];
    final extras = pets.where((p) => !p.isMain && p.petId != _petId).toList();
    if (extras.isEmpty) return;

    // Stagger extras around the food in a tight ring so they cluster without
    // exact overlap. Main pet eats the food at center; extras hover nearby.
    const ringRadius = 0.10;
    var changed = false;
    for (var i = 0; i < extras.length; i++) {
      final pet = extras[i];
      final runtime = _ensureExtraPetRuntime(pet.petId, i);
      if (runtime.isDragging) continue;
      final angle = (2 * pi * (i + 1)) / (extras.length + 1);
      var scattered = Offset(
        foodTarget.dx + ringRadius * cos(angle),
        foodTarget.dy + ringRadius * sin(angle),
      );
      scattered = _clampNormalized(scattered);
      final duration = _extraPetTravelDuration(
        runtime.normalizedPosition,
        scattered,
        fieldSize,
      );
      runtime
        ..normalizedPosition = runtime.normalizedTarget
        ..normalizedTarget = scattered
        ..animDuration = duration
        ..facingRight = scattered.dx < runtime.normalizedPosition.dx;
      _beginExtraPetWalk(pet.petId, duration);
      changed = true;
    }
    if (changed) {
      setState(() {});
    }
  }

  void _wanderExtraPetsIfIdle() {
    if (!mounted) return;
    if (_petEating || _photoFoodImageSource != null) return;
    final roomId = _roomId;
    if (roomId == null) return;
    final pets = _roomPetsByRoom[roomId] ?? const <_RoomPet>[];
    final extras = pets.where((p) => !p.isMain && p.petId != _petId).toList();
    final fieldSize = _petFieldSize();
    if (fieldSize == null || fieldSize.isEmpty) {
      return;
    }
    var changed = false;
    for (var i = 0; i < extras.length; i++) {
      final pet = extras[i];
      final runtime = _ensureExtraPetRuntime(pet.petId, i);
      if (runtime.isDragging) continue;
      // Each extra pet has ~50% chance to wander on each tick.
      if (_random.nextDouble() < 0.5) continue;
      // Avoid spawning on top of other pets (main + other extras).
      final occupied = <Offset>[_currentPetNormalized()];
      for (var j = 0; j < extras.length; j++) {
        if (j == i) continue;
        final other = _extraPetRuntime[extras[j].petId];
        if (other != null) occupied.add(other.normalizedTarget);
      }
      final newTarget = _pickWanderTargetAvoiding(occupied);
      final duration = _extraPetTravelDuration(
        runtime.normalizedPosition,
        newTarget,
        fieldSize,
      );
      runtime
        ..normalizedPosition = runtime.normalizedTarget
        ..normalizedTarget = newTarget
        ..animDuration = duration
        ..facingRight = newTarget.dx < runtime.normalizedPosition.dx;
      _beginExtraPetWalk(pet.petId, duration);
      changed = true;
    }
    if (changed) {
      setState(() {});
    }
  }

  void _handleExtraPetDragStart(
    String petId,
    DragStartDetails details,
    Size fieldSize,
  ) {
    final runtime = _extraPetRuntime[petId];
    if (runtime == null) return;
    final local = _globalToPetField(details.globalPosition);
    if (local == null) return;
    _markUserInteraction();
    final currentTopLeft = _positionFromNormalized(
      runtime.normalizedPosition,
      fieldSize,
    );
    runtime.arrivalTimer?.cancel();
    setState(() {
      runtime
        ..isDragging = true
        ..isWalking = true
        ..dragOffset = local - currentTopLeft
        ..normalizedTarget = runtime.normalizedPosition
        ..animDuration = Duration.zero;
    });
  }

  void _handleExtraPetDragUpdate(
    String petId,
    DragUpdateDetails details,
    Size fieldSize,
  ) {
    final runtime = _extraPetRuntime[petId];
    if (runtime == null || !runtime.isDragging) return;
    final local = _globalToPetField(details.globalPosition);
    if (local == null) return;
    _markUserInteraction();
    final desiredTopLeft = local - runtime.dragOffset;
    final clamped = _clampTopLeft(desiredTopLeft, fieldSize);
    final normalized = _normalizedFromTopLeft(clamped, fieldSize);
    setState(() {
      runtime
        ..normalizedPosition = normalized
        ..normalizedTarget = normalized
        ..animDuration = Duration.zero
        ..facingRight = normalized.dx < runtime.normalizedPosition.dx;
    });
  }

  void _handleExtraPetDragEnd(String petId) {
    final runtime = _extraPetRuntime[petId];
    if (runtime == null || !runtime.isDragging) return;
    setState(() {
      runtime
        ..isDragging = false
        ..isWalking = false
        ..stationaryState = _pickStationaryStateForNow();
    });
  }

  Future<void> _maybeShowMultiPetNamingPrompt(List<_RoomPet> pets) async {
    if (_multiPetNamingShown) return;
    if (pets.length < 2) return;
    // Show only if no other pet besides the first one has a name yet — i.e.,
    // first time we see two pets where the secondary pet was just added.
    final extras = pets.where((p) => !p.isMain).toList();
    final hasNamedExtra = extras.any((p) => (p.name ?? '').isNotEmpty);
    if (!hasNamedExtra) return;
    final firstPet = pets.firstWhere(
      (p) => p.isMain,
      orElse: () => pets.first,
    );
    if ((firstPet.name ?? '').isNotEmpty) {
      _multiPetNamingShown = true;
      return;
    }
    _multiPetNamingShown = true;
    if (!mounted) return;
    final roomId = _roomId;
    if (roomId == null) return;
    final currentRoomName = (() {
      for (final room in _myRooms) {
        if (room['id'] == roomId) {
          return (room['name'] as String?) ?? '';
        }
      }
      return '';
    })();
    await _showMultiPetNamingDialog(
      roomId: roomId,
      defaultRoomName: currentRoomName,
      inheritedFirstPetName: currentRoomName,
    );
  }

  Future<void> _showMultiPetNamingDialog({
    required String roomId,
    required String defaultRoomName,
    required String inheritedFirstPetName,
  }) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final roomController = TextEditingController(text: defaultRoomName);
    final petController = TextEditingController(text: inheritedFirstPetName);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.multiPetNamingTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.multiPetNamingSubtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  maxLength: 30,
                  decoration: InputDecoration(
                    labelText: l10n.multiPetNamingRoomLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: petController,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: l10n.multiPetNamingFirstPetLabel,
                    hintText: l10n.multiPetNamingFirstPetHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonSkip),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );
    final roomName = roomController.text.trim();
    final petName = petController.text.trim();
    roomController.dispose();
    petController.dispose();
    if (confirmed != true || !mounted) return;
    if (roomName.isEmpty && petName.isEmpty) return;
    try {
      await Supabase.instance.client.rpc(
        'apply_multi_pet_room_naming',
        params: {
          'p_room_id': roomId,
          'p_room_name': roomName.isEmpty ? null : roomName,
          'p_first_pet_name': petName.isEmpty ? null : petName,
        },
      );
      if (!mounted) return;
      if (roomName.isNotEmpty) {
        setState(() {
          _myRooms = _myRooms
              .map(
                (room) =>
                    room['id'] == roomId ? {...room, 'name': roomName} : room,
              )
              .toList();
        });
      }
      unawaited(_loadRoomPets(roomId));
    } catch (error) {
      if (!mounted) return;
      showJuiceToast(
        context: context,
        message: l10n.commonTryAgain,
        tone: AppDialogTone.danger,
      );
    }
  }

  Future<String?> _resolveEquipTargetPetId({
    required String roomId,
    required String defaultPetId,
    required String slot,
  }) async {
    final pets = _roomPetsByRoom[roomId] ?? const <_RoomPet>[];
    if (pets.length < 2) {
      return defaultPetId;
    }
    if (!mounted) return null;
    // Look up what each pet currently wears in this slot for context.
    Map<String, String> currentSkuByPetId = const {};
    try {
      final rows = await Supabase.instance.client
          .from('pet_equipment')
          .select('pet_id, item_id, items(sku)')
          .eq('room_id', roomId)
          .eq('slot', slot);
      final map = <String, String>{};
      for (final row in rows) {
        final petId = row['pet_id'] as String?;
        final items = row['items'];
        if (petId == null || items is! Map) continue;
        final sku = items['sku'] as String?;
        if (sku != null) {
          map[petId] = sku;
        }
      }
      currentSkuByPetId = map;
    } catch (_) {
      // Best-effort enrichment; fall back to no annotations.
    }
    if (!mounted) return null;
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.equipTargetPickerTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 1),
                for (final pet in pets)
                  ListTile(
                    leading: SizedBox(
                      width: 42,
                      height: 42,
                      child: _buildPetVisualForAsset(
                        petId: pet.petType,
                        asset: PetCatalog.byId(pet.petType).stayAsset,
                        size: const Size(42, 42),
                        petFallbackColor: PetCatalog.byId(pet.petType).accent,
                        equippedSkusBySlot: const {},
                      ),
                    ),
                    title: Text(
                      pet.name ?? PetCatalog.byId(pet.petType).name(l10n),
                    ),
                    subtitle: currentSkuByPetId.containsKey(pet.petId)
                        ? Text(
                            l10n.equipTargetPickerCurrentlyWearing(
                              currentSkuByPetId[pet.petId]!,
                            ),
                            style: const TextStyle(fontSize: 11),
                          )
                        : null,
                    trailing: pet.isMain
                        ? const Icon(Icons.star_rounded, color: Colors.amber)
                        : null,
                    onTap: () => Navigator.of(context).pop(pet.petId),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMainPetSwitcher() async {
    final roomId = _roomId;
    if (roomId == null) return;
    final pets = _roomPetsByRoom[roomId] ?? const <_RoomPet>[];
    if (pets.length < 2) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.mainPetSwitcherTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 1),
                for (final pet in pets)
                  ListTile(
                    leading: SizedBox(
                      width: 42,
                      height: 42,
                      child: _buildPetVisualForAsset(
                        petId: pet.petType,
                        asset: PetCatalog.byId(pet.petType).stayAsset,
                        size: const Size(42, 42),
                        petFallbackColor: PetCatalog.byId(pet.petType).accent,
                        equippedSkusBySlot: const {},
                      ),
                    ),
                    title: Text(
                      pet.name ?? PetCatalog.byId(pet.petType).name(l10n),
                    ),
                    trailing: pet.isMain
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () => Navigator.of(context).pop(pet.petId),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selectedId == null || !mounted) return;
    final selectedPet = pets.firstWhere(
      (p) => p.petId == selectedId,
      orElse: () => pets.first,
    );
    if (selectedPet.isMain) return;
    try {
      await Supabase.instance.client.rpc(
        'set_room_main_pet',
        params: {'p_room_id': roomId, 'p_pet_id': selectedId},
      );
      if (!mounted) return;
      // Triggers cascade: realtime will fire, _loadRoomPets/_refreshPetState
      // will re-run. Force immediate refresh too for snappy UX.
      unawaited(_loadRoomPets(roomId));
      await _refreshPetState();
    } catch (error) {
      if (!mounted) return;
      showJuiceToast(
        context: context,
        message: AppLocalizations.of(context)!.commonTryAgain,
        tone: AppDialogTone.danger,
      );
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
      if (!mounted) {
        return;
      }
      if (petId == null) {
        setState(() => _petError = AppLocalizations.of(context)!.petNotFound);
        return;
      }

      unawaited(_loadRoomPets(roomId));
      _subscribeToRoomPets(roomId);
      _subscribeToPetState(petId);
      _subscribeToPetEquipment(roomId);
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
      unawaited(_loadPetEquipment(petId: petId, roomId: roomId, silent: true));
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

    final previousChannel = _petStateChannel;
    _petStateChannel = null;
    unawaited(_removeRealtimeChannel(previousChannel));
    _petSubscriptionPetId = petId;

    final channel = Supabase.instance.client.channel('pet_state_$petId');
    _petStateChannel = channel;

    void handleUpdate(Map<String, dynamic> record) {
      if (!mounted || _petSubscriptionPetId != petId) {
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

  Future<void> _loadPetEquipment({
    String? petId,
    String? roomId,
    bool silent = false,
  }) async {
    final resolvedPetId = petId ?? _petId;
    final expectedRoomId = roomId ?? _roomId;
    if (resolvedPetId == null || expectedRoomId == null) {
      if (!silent && mounted) {
        setState(() {
          _equipmentLoading = false;
          _equipmentError = null;
          _equippedItemsBySlot.clear();
        });
      } else {
        _equippedItemsBySlot.clear();
      }
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _equipmentLoading = true;
        _equipmentError = null;
      });
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'get_pet_equipment',
        params: {'p_pet_id': resolvedPetId, 'p_room_id': expectedRoomId},
      );
      final equipped = <String, _EquippedPetItem>{};
      for (final row in response as List<dynamic>) {
        if (row is! Map<String, dynamic>) {
          continue;
        }
        final slot = row['slot'] as String?;
        final itemId = row['item_id'] as String?;
        final sku = row['item_sku'] as String?;
        if (slot == null || itemId == null || sku == null) {
          continue;
        }
        equipped[slot] = _EquippedPetItem(itemId: itemId, sku: sku);
      }
      _precacheEquippedAssets(equipped.values.map((item) => item.sku));
      if (!mounted) {
        _equippedItemsBySlot
          ..clear()
          ..addAll(equipped);
        _roomEquippedSkusBySlot[expectedRoomId] = _equippedSkusFromItemsBySlot(
          equipped,
        );
        _equipmentLoading = false;
        return;
      }
      if (_roomId != expectedRoomId ||
          (_petId != null && _petId != resolvedPetId)) {
        return;
      }
      setState(() {
        _equippedItemsBySlot
          ..clear()
          ..addAll(equipped);
        _roomEquippedSkusBySlot[expectedRoomId] = _equippedSkusFromItemsBySlot(
          equipped,
        );
      });
    } catch (error) {
      if (!mounted) {
        _equipmentError = error.toString();
        _equipmentLoading = false;
        return;
      }
      setState(() {
        _equipmentError = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
      });
    } finally {
      if (!silent) {
        if (mounted) {
          setState(() => _equipmentLoading = false);
        } else {
          _equipmentLoading = false;
        }
      }
    }
  }

  Future<void> _loadOwnedEquipment({bool silent = false}) async {
    final roomId = _roomId;
    if (Supabase.instance.client.auth.currentUser == null || roomId == null) {
      if (mounted) {
        setState(() {
          _ownedEquipmentItems.clear();
          _equipmentLoading = false;
        });
      } else {
        _ownedEquipmentItems.clear();
      }
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _equipmentLoading = true;
        _equipmentError = null;
      });
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'get_room_equipment_inventory',
        params: {'p_room_id': roomId},
      );
      final items = <ShopItem>[];
      for (final row in response as List<dynamic>) {
        if (row is! Map<String, dynamic>) {
          continue;
        }
        final item = ShopItem.fromJson(row);
        if (!item.isEquipment) {
          continue;
        }
        if (!item.isSupportedOnAppVersion(_currentAppVersion)) {
          continue;
        }
        items.add(item);
      }
      items.sort((a, b) => a.sku.compareTo(b.sku));
      if (!mounted) {
        _ownedEquipmentItems
          ..clear()
          ..addAll(items);
        _equipmentLoading = false;
        return;
      }
      setState(() {
        _ownedEquipmentItems
          ..clear()
          ..addAll(items);
      });
    } catch (error) {
      if (!mounted) {
        _equipmentError = error.toString();
        _equipmentLoading = false;
        return;
      }
      setState(() {
        _equipmentError = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
      });
    } finally {
      if (!silent) {
        if (mounted) {
          setState(() => _equipmentLoading = false);
        } else {
          _equipmentLoading = false;
        }
      }
    }
  }

  void _subscribeToPetEquipment(String roomId) {
    if (_petEquipmentSubscriptionRoomId == roomId) {
      return;
    }

    final previousChannel = _petEquipmentChannel;
    _petEquipmentChannel = null;
    unawaited(_removeRealtimeChannel(previousChannel));
    _petEquipmentSubscriptionRoomId = roomId;

    final channel = Supabase.instance.client.channel('pet_equipment_$roomId');
    _petEquipmentChannel = channel;

    void refreshEquipment() {
      if (!mounted || _roomId != roomId) {
        return;
      }
      unawaited(_loadPetEquipment(roomId: roomId, silent: true));
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'pet_equipment',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => refreshEquipment(),
    );

    channel.subscribe();
  }

  Future<void> _equipItem(String itemId, String slot) async {
    final mainPetId = _petId;
    final roomId = _roomId;
    if (mainPetId == null || roomId == null) {
      return;
    }
    final targetPetId = await _resolveEquipTargetPetId(
      roomId: roomId,
      defaultPetId: mainPetId,
      slot: slot,
    );
    if (targetPetId == null) {
      return;
    }
    try {
      final response = await Supabase.instance.client.rpc(
        'equip_pet_item',
        params: {
          'p_pet_id': targetPetId,
          'p_room_id': roomId,
          'p_item_id': itemId,
          'p_slot': slot,
        },
      );
      await _loadPetEquipment(roomId: roomId, silent: true);
      if (!mounted) {
        return;
      }
      final itemName = _ownedEquipmentItems
          .cast<ShopItem?>()
          .firstWhere((item) => item?.id == itemId, orElse: () => null)
          ?.localizedName(AppLocalizations.of(context)!);
      final responseMap = response is Map<String, dynamic>
          ? response
          : <String, dynamic>{};
      final fallbackSku = responseMap['item_sku'] as String?;
      showJuiceSnackbar(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.equipmentEquipSuccess(itemName ?? fallbackSku ?? ''),
        tone: AppDialogTone.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showJuiceToast(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.storePurchaseFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
    }
  }

  Future<void> _unequipItem(String slot) async {
    final petId = _petId;
    final roomId = _roomId;
    if (petId == null || roomId == null) {
      return;
    }
    try {
      await Supabase.instance.client.rpc(
        'unequip_pet_item',
        params: {'p_pet_id': petId, 'p_room_id': roomId, 'p_slot': slot},
      );
      await _loadPetEquipment(roomId: roomId, silent: true);
      if (!mounted) {
        return;
      }
      showJuiceSnackbar(
        context: context,
        message: AppLocalizations.of(context)!.equipmentUnequipSuccess(
          _localizedEquipmentSlot(slot, AppLocalizations.of(context)!),
        ),
        tone: AppDialogTone.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showJuiceToast(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.storePurchaseFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
    }
  }

  String _localizedEquipmentSlot(String slot, AppLocalizations l10n) {
    switch (slot) {
      case PetEquipmentSlot.head:
        return l10n.equipmentSlotHead;
      case PetEquipmentSlot.face:
        return l10n.equipmentSlotFace;
      case PetEquipmentSlot.body:
        return l10n.equipmentSlotBody;
      case PetEquipmentSlot.back:
        return l10n.equipmentSlotBack;
    }
    return slot;
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
      showJuiceToast(
        context: context,
        message: AppLocalizations.of(context)!.petNotFound,
        tone: AppDialogTone.warning,
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

    final newName = await showJuiceToast<String>(
      context: context,
      message: l10n.petNameEditTitle,
      position: JuicePosition.center,
      body: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                onTapOutside: dismissKeyboardOnTapOutside,
                textInputAction: TextInputAction.done,
                style: GoogleFonts.mPlusRounded1c(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: l10n.petNameHint,
                  errorText: errorText,
                  errorStyle: GoogleFonts.mPlusRounded1c(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorColor,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 3,
                    ),
                  ),
                ),
                onSubmitted: (_) => submit(setState),
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: JuicyScaleButton(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            l10n.commonCancel,
                            style: GoogleFonts.mPlusRounded1c(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: JuicyScaleButton(
                      onTap: () => submit(setState),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            l10n.commonSave,
                            style: GoogleFonts.mPlusRounded1c(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
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
      showJuiceToast(
        context: context,
        message: l10n.petNameUpdateFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
    }
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
    final roomId = _roomId;
    if (roomId != null) {
      await _loadRoomPets(roomId);
    }
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
        showJuiceToast(
          context: context,
          message: l10n.petActionFailed(userFacingError(context, error)),
          tone: AppDialogTone.danger,
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

      final visibleItems = (itemsResponse as List<dynamic>)
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

      final visibleItemIds = visibleItems.map((item) => item.id).toSet();
      final missingInventoryIds = inventory.keys
          .where((itemId) => !visibleItemIds.contains(itemId))
          .toList(growable: false);
      final inventoryItemDetails = <ShopItem>[];
      if (missingInventoryIds.isNotEmpty) {
        final ownedItemsResponse = await Supabase.instance.client
            .from('items')
            .select(
              'id,sku,type,name,price_coins,price_diamonds,metadata,is_active',
            )
            .inFilter('id', missingInventoryIds);
        inventoryItemDetails.addAll(
          (ownedItemsResponse as List<dynamic>)
              .map((row) => ShopItem.fromJson(row as Map<String, dynamic>))
              .where((item) => item.isFurniture),
        );
      }

      if (!mounted) {
        return;
      }

      final catalog = buildRoomFurnitureCatalog(
        visibleShopItems: visibleItems,
        inventoryItemDetails: inventoryItemDetails,
        inventory: inventory,
        appVersion: appVersion,
      );

      setState(() {
        _furnitureCatalog
          ..clear()
          ..addAll(catalog);
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
            'id,item_id,owner_user_id,position_x,position_y,scale,flip_x,items(id,sku,type,name,price_coins,price_diamonds,metadata)',
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
        final flipX = record['flip_x'] == true;
        final emoji = _resolveFurnitureEmoji(itemId, record);
        final assetPath = _resolveFurnitureAssetPath(itemId, record);
        placed.add(
          _PlacedFurniture(
            id: id,
            itemId: itemId,
            ownerUserId: ownerUserId,
            emoji: emoji,
            assetPath: assetPath,
            normalizedPosition: Offset(posX, posY),
            persistedNormalizedPosition: Offset(posX, posY),
            scale: scale,
            persistedScale: scale,
            flipX: flipX,
            persistedFlipX: flipX,
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

    final previousChannel = _furnitureChannel;
    _furnitureChannel = null;
    unawaited(_removeRealtimeChannel(previousChannel));
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

  void _subscribeToRoomInventoryRevisions(String roomId) {
    if (_roomInventoryRevisionSubscriptionRoomId == roomId) {
      return;
    }

    final previousChannel = _roomInventoryRevisionChannel;
    _roomInventoryRevisionChannel = null;
    unawaited(_removeRealtimeChannel(previousChannel));
    _roomInventoryRevisionSubscriptionRoomId = roomId;

    final channel = Supabase.instance.client.channel(
      'room_item_inventory_revisions_$roomId',
    );
    _roomInventoryRevisionChannel = channel;

    void refreshInventory() {
      if (!_furnitureMode || _roomId != roomId) {
        return;
      }
      unawaited(_loadFurnitureInventory());
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_item_inventory_revisions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => refreshInventory(),
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'room_item_inventory_revisions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => refreshInventory(),
    );

    channel.subscribe();
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
    _subscribeToRoomInventoryRevisions(roomId);
    unawaited(_loadFurnitureInventory());
    unawaited(_loadRoomFurniture(roomId));
    unawaited(_loadRoomBackgrounds(roomId));
    unawaited(_loadRoomBackgroundState(roomId));
    unawaited(_loadOwnedEquipment());
    unawaited(_loadPetEquipment(roomId: roomId, silent: true));
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

    final previousStateChannel = _backgroundStateChannel;
    final previousInventoryChannel = _backgroundInventoryChannel;
    _backgroundStateChannel = null;
    _backgroundInventoryChannel = null;
    unawaited(_removeRealtimeChannel(previousStateChannel));
    unawaited(_removeRealtimeChannel(previousInventoryChannel));
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

  Future<void> _maybePromptForUnsupportedRoomDecor(String roomId) async {
    if (!mounted || _roomId != roomId || _decorCompatibilityPromptShowing) {
      return;
    }
    final promptState = SharedDecorCompatibility.promptState(
      unsupportedPetType: _unsupportedPetTypesByRoom[roomId],
      unsupportedBackgroundItemIds:
          _unsupportedBackgroundItemIdsByRoom[roomId] ?? const <String>{},
      activeBackgroundItemId: _activeBackgroundByRoom[roomId],
      unsupportedPlacedFurnitureCount:
          _unsupportedPlacedFurnitureCountByRoom[roomId] ?? 0,
    );
    if (!promptState.shouldPrompt) {
      return;
    }
    final promptKey = promptState.keyFor(
      roomId: roomId,
      appVersion: _currentAppVersion,
    );
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
        showJuiceToast(
          context: context,
          message: AppLocalizations.of(context)!.forceUpdateLinkError,
          tone: AppDialogTone.danger,
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
      assetPath: item.furnitureAssetPath,
      normalizedPosition: normalized,
      persistedNormalizedPosition: normalized,
      scale: 1.0,
      persistedScale: 1.0,
      flipX: false,
      persistedFlipX: false,
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

  void _toggleSelectedFurnitureFlip() {
    final item = _selectedPlacedFurniture();
    if (item == null) {
      return;
    }
    final nextFlipX = !item.flipX;
    setState(() {
      _selectedPlacedFurnitureId = item.id;
      _selectedFurnitureItemId = null;
      item.flipX = nextFlipX;
    });
    if (!item.isPending) {
      unawaited(_persistFurnitureFlip(item));
    }
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
      final response = await Supabase.instance.client.rpc(
        'update_room_furniture_transform',
        params: {
          'p_id': item.id,
          'p_scale': item.scale,
          'p_position_x': item.normalizedPosition.dx,
          'p_position_y': item.normalizedPosition.dy,
        },
      );
      _applyPersistedFurnitureTransformResponse(item, response);
    } catch (error) {
      if (_shouldFallbackToLegacyFurnitureTransform(error)) {
        await _persistFurnitureTransformLegacy(item);
        return;
      }
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

  Future<void> _persistFurnitureFlip(_PlacedFurniture item) async {
    if (item.isPending) {
      return;
    }
    final requestedFlipX = item.flipX;
    try {
      final response = await Supabase.instance.client.rpc(
        'update_room_furniture_flip',
        params: {'p_id': item.id, 'p_flip_x': requestedFlipX},
      );
      final row = _coerceFurnitureTransformResponse(response);
      final persistedFlipX = row == null
          ? requestedFlipX
          : row['flip_x'] == true;
      if (!mounted) {
        item
          ..flipX = persistedFlipX
          ..persistedFlipX = persistedFlipX;
        return;
      }
      setState(() {
        item
          ..flipX = persistedFlipX
          ..persistedFlipX = persistedFlipX;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          item.flipX = item.persistedFlipX;
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

  Future<void> _persistFurnitureTransformLegacy(_PlacedFurniture item) async {
    try {
      final scaleResponse = await Supabase.instance.client.rpc(
        'update_room_furniture_scale',
        params: {'p_id': item.id, 'p_scale': item.scale},
      );
      final positionResponse = await Supabase.instance.client.rpc(
        'update_room_furniture_position',
        params: {
          'p_id': item.id,
          'p_position_x': item.normalizedPosition.dx,
          'p_position_y': item.normalizedPosition.dy,
        },
      );
      _applyPersistedFurnitureTransformResponse(
        item,
        positionResponse,
        fallbackResponse: scaleResponse,
      );
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

  void _applyPersistedFurnitureTransformResponse(
    _PlacedFurniture item,
    dynamic response, {
    dynamic fallbackResponse,
  }) {
    final row =
        _coerceFurnitureTransformResponse(response) ??
        _coerceFurnitureTransformResponse(fallbackResponse);
    final nextScale = _parseFurnitureScale(row?['scale'] ?? item.scale);
    final nextPosition = row == null
        ? item.normalizedPosition
        : Offset(
            (row['position_x'] as num?)?.toDouble() ??
                item.normalizedPosition.dx,
            (row['position_y'] as num?)?.toDouble() ??
                item.normalizedPosition.dy,
          );

    if (!mounted) {
      item
        ..scale = nextScale
        ..normalizedPosition = nextPosition
        ..persistedScale = nextScale
        ..persistedNormalizedPosition = nextPosition;
      return;
    }

    setState(() {
      item
        ..scale = nextScale
        ..normalizedPosition = nextPosition
        ..persistedScale = nextScale
        ..persistedNormalizedPosition = nextPosition;
    });
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

  void _setShowSocketDebug(bool value) {
    setState(() => _showSocketDebug = value);
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    ref.listen<FeedUploadQueueState>(
      feedUploadQueueProvider,
      _handleFeedUploadQueueTransition,
    );
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
                roomEquippedSkusBySlot: _roomEquippedSkusBySlot,
                selectedRoomId: roomSelectionId,
                userAvatarUrl: _myAvatarUrl,
                currentAppVersion: _currentAppVersion,
                highlightCreateRoomCta: _isCreatePetOnboardingStepActive,
                createRoomCtaKey: _onboardingCreateRoomCtaKey,
                highlightJoinRoomCta: _isCreatePetOnboardingStepActive,
                joinRoomCtaKey: _onboardingJoinRoomCtaKey,
                topBanner: AdMobIds.isBannerViewSupported && !_hasProPlanAccess
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
                      petAvatar: _buildStatusBarPetAvatar(petDefinition),
                      expProgress: expProgressValue,
                      level: level,
                      petName: resolvedPetName,
                      healthValue: _healthValue(),
                      healthDebugValue: healthDebugValue,
                      coins: currency.coins,
                      diamonds: currency.diamonds,
                      coinReward: currency.coinReward,
                      coinRewardEventId: currency.coinRewardEventId,
                      coinRewardLabel: currency.coinRewardLabel,
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
                  petType: _petType,
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
                  equipmentItems: _ownedEquipmentItems,
                  equippedItemIdsBySlot: _equippedItemIdsBySlot,
                  equippedItemSkusBySlot: _equippedSkusBySlot,
                  equipmentLoading: _equipmentLoading,
                  equipmentErrorText: _equipmentError,
                  onClose: _closeFurnitureInventory,
                  onFurnitureTap: (itemId) {
                    setState(() {
                      _selectedFurnitureItemId = itemId;
                      _selectedPlacedFurnitureId = null;
                    });
                    _autoPlaceFurnitureFromInventory(itemId);
                  },
                  onBackgroundApply: _applyRoomBackground,
                  onEquipItem: _equipItem,
                  onUnequipItem: _unequipItem,
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
