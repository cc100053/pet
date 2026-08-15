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
import '../../shared/utils/date_parsing.dart';
import '../../shared/utils/supabase_realtime.dart';
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
import '../feed/feed_pet_state_freshness.dart';
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
import 'providers/room_frame_provider.dart';
import 'onboarding_focus_utils.dart';
import 'pet_hunger_projection.dart';
import 'pet_status_snapshot.dart';
import 'room_selection_view.dart';
import 'room_backgrounds.dart';
import 'room_canvas.dart';
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
part 'home_view_room_decor.dart';
part 'home_view_equipment.dart';
part 'home_view_pet_tick.dart';
part 'home_view_debug.dart';
part 'home_view_build.dart';

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
  // Mirrors the server `apply_pet_action('feed')` satiety gain (least(100, +25)).
  // Used for the optimistic local prediction; the authoritative value reconciles.
  static const int _feedHungerGain = 25;
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
  static const _poopEmojiSize = Size(28, 28);
  static const int _profileNicknameMaxLength = 20;
  static const int _onboardingAvatarMaxDimension = 512;
  static const int _onboardingAvatarWebpQuality = 70;

  // Logic State
  bool _profileEnsured = false;
  bool _homeBootstrapCompleted = false;
  // Whether the room list has been fetched from the server at least once this
  // session. A silent `_fetchRooms` failure used to leave an empty list that
  // nothing retried and that `_cacheHomeBootstrapSnapshot` then persisted,
  // turning one transient failure into a permanently blank room selection.
  bool _roomsLoadedFromNetwork = false;
  bool _roomsFetchInFlight = false;
  // Recovery must not run before bootstrap has had its turn: the auth stream
  // replays `initialSession` during `initState`, well before the post-frame
  // callback starts `_bootstrapHome`, and fetching there would pre-empt the
  // cache restore that makes a warm start paint instantly.
  bool _roomsBootstrapAttempted = false;
  int _roomsRetryAttempt = 0;
  Timer? _roomsRetryTimer;
  StreamSubscription<AuthState>? _homeAuthSubscription;
  static const int _roomsMaxRetryAttempts = 4;
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
  // Poops currently being cleaned. Tracked by a position-stable key (not array
  // index, which shifts as the server prunes the list) so the optimistic hide
  // and exit animation survive concurrent cleans and realtime updates.
  final Set<String> _cleaningPoopKeys = {};
  Map<String, dynamic>? _petState;
  bool _petStateReady = false;
  bool _petDeparted = false;
  bool _petDeparturePrompted = false;
  String? _lastDeparturePetId;
  final Map<String, DepartedPetInfo> _departedPetsByRoom = {};
  final Map<String, Map<String, dynamic>> _petStateByRoom = {};
  final Map<String, String> _petIdByRoom = {};
  // Monotonic freshness clock per pet, keyed by the server `last_decay_at`.
  // hunger only ever drops when passive decay advances `last_decay_at`, so a
  // pet_state snapshot whose anchor is strictly older than the last applied one
  // is stale (e.g. a pre-feed tick read arriving after the fed value) and must
  // not overwrite a fresher value. This is the root guard against the
  // intermittent "fed but satiety bar didn't move" race on slow uploads.
  final Map<String, DateTime> _petStateDecayClockByPetId = {};
  final Map<String, List<_RoomPet>> _roomPetsByRoom = {};
  final Map<String, _ExtraPetRuntime> _extraPetRuntime = {};
  // Which pet the equipment panel is currently dressing. Persisted across the
  // panel session so users pick the target pet up front instead of via a
  // per-tap picker. Defaults to the main pet.
  String? _selectedEquipPetId;
  String? _visibleNameTagPetId;
  Timer? _nameTagFadeTimer;
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

  /// Whether 房間選擇 still owes this device the 長按換相框 coach bubble.
  ///
  /// Read at field-init as well as in `initState`: Hive is open before
  /// `runApp`, and a hot reload adds the field without re-running `initState`,
  /// which would otherwise leave the bubble permanently hidden in development.
  bool _roomFrameHintSeen = AppSettingsRepository.instance.roomFrameHintSeen;
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
  Timer? _homeBootstrapCachePersistTimer;
  Timer? _unreadReconcileTimer;
  StreamSubscription<AppNotificationIntent>? _notificationIntentSubscription;
  AppNotificationIntent? _pendingNotificationIntent;
  bool _petAssetsPrecached = false;
  bool _basicOnboardingLoadStarted = false;
  final Set<String> _cachedPetAssets = {};
  bool _departureFontsWarmed = false;
  Future<void>? _departureFontsWarmup;
  static const int _petNameMaxLength = kPetNameMaxLength;
  static const int _freePlanRoomLimit = 2;
  static const String _proEntitlementId = 'Petmonthly';
  static const Duration _networkTimeout = Duration(seconds: 4);

  /// How long a cold room entry may run before the full-screen entry overlay
  /// takes over. Under this, the room scaffold itself is a better placeholder —
  /// it paints the real background and shows a small spinner in the pet's place
  /// (`_buildPetLoadingPlaceholder`) instead of blanking the screen.
  static const Duration _roomEntryOverlayRevealDelay = Duration(
    milliseconds: 120,
  );

  /// Minimum time the entry overlay stays up *once revealed*, so it cannot
  /// flash. Measured from the reveal, not from the start of the entry — an
  /// entry that never revealed the overlay is never padded.
  static const Duration _roomEntryLoadingMinDuration = Duration(
    milliseconds: 150,
  );
  static const Duration _roomEntryFadeDuration = Duration(milliseconds: 420);
  static const Duration _onlineProbeThrottle = Duration(seconds: 10);
  bool _inviteCodeLoading = false;
  bool _roomEntryLoading = false;
  bool _roomEntryOverlayVisible = false;
  DateTime? _roomEntryOverlayShownAt;
  Timer? _roomEntryOverlayRevealTimer;
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
  Offset? _activeFurnitureDragStartCanvasPosition;
  String? _activeFurnitureScaleInteractionItemId;
  Offset? _activeFurnitureScaleInteractionStartCanvasPosition;
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
  // How many copies of each equipment item the room owns (item id -> quantity).
  // Mirrors the capacity the equip_pet_item RPC enforces.
  final Map<String, int> _ownedEquipmentQtyById = {};
  final Map<String, _EquippedPetItem> _equippedItemsBySlot = {};
  // Equipment of the panel's selected pet when it is NOT the main pet. The main
  // pet keeps using _equippedItemsBySlot so the on-screen avatar is untouched.
  final Map<String, _EquippedPetItem> _panelEquippedItemsBySlot = {};
  final Map<String, Map<String, String>> _roomEquippedSkusBySlot = {};
  // Per-pet equipped SKUs by slot for the active room (all pets), so every pet
  // renders its own gear on screen and in the equipment selector.
  final Map<String, Map<String, String>> _equippedSkusByPetId = {};
  RealtimeChannel? _petEquipmentChannel;
  RealtimeChannel? _roomSelectionEquipmentChannel;
  String? _petEquipmentSubscriptionRoomId;

  // Background State
  bool _backgroundLoading = false;
  String? _backgroundError;
  String? _backgroundApplyingItemId;
  final Map<String, List<ShopItem>> _ownedBackgroundsByRoom = {};
  final Map<String, String?> _activeBackgroundByRoom = {};
  // Last resolved background key per room, persisted with the bootstrap
  // snapshot. Painting the real background needs both `room_background_state`
  // and the owned-background list, and the latter is deliberately deferred past
  // first paint — without this the room would flash the default background on
  // every cold entry.
  final Map<String, String> _cachedBackgroundKeyByRoom = {};
  RealtimeChannel? _backgroundStateChannel;
  RealtimeChannel? _backgroundInventoryChannel;
  RealtimeChannel? _roomInventoryRevisionChannel;
  String? _backgroundSubscriptionRoomId;
  RealtimeChannel? _furnitureChannel;

  // Suppress the realtime self-echo that otherwise reloads furniture and makes
  // a just-dragged/scaled piece flash back to its previous DB position. We skip
  // a reload when the change is our own very recent write (its authoritative
  // value is already applied from the RPC response), or while the user is still
  // manipulating a piece. A remote change that arrives mid-gesture is not lost:
  // it is replayed once the gesture finishes.
  static const Duration _furnitureSelfEchoWindow = Duration(seconds: 5);
  final Map<String, DateTime> _recentFurnitureWriteAt = {};
  bool _furnitureReloadPendingAfterGesture = false;
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
  int _petHealthActionEventId = 0;
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
    _roomFrameHintSeen = AppSettingsRepository.instance.roomFrameHintSeen;
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
    // Home can mount during the OAuth deep-link handoff, before the client has
    // the session. Bootstrap is once-only, so the arriving session is the only
    // signal that the initial room fetch needs redoing.
    _homeAuthSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          if (data.session == null) {
            return;
          }
          unawaited(_recoverRoomsIfNeeded('auth_state_change'));
        });
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
    _roomEntryOverlayRevealTimer?.cancel();
    _roomsRetryTimer?.cancel();
    _homeAuthSubscription?.cancel();
    _homeBootstrapCachePersistTimer?.cancel();
    _unreadReconcileTimer?.cancel();
    _notificationIntentSubscription?.cancel();
    _inviteLinkSubscription?.cancel();
    _feedingAnimationToken++;
    _onboardingProfileNicknameController.dispose();
    _petMoveController.dispose();
    _furnitureWiggleController.dispose();
    super.dispose();
  }

  Future<void> _removeRealtimeChannel(RealtimeChannel? channel) =>
      removeRealtimeChannelSafely(channel);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(_refreshDebugAdminAccess());
    unawaited(_refreshProPlanStatus());
    unawaited(_feedUploadQueue.resumePendingJobs());
    // Last line of defence: returning to a blank room list is always a bug.
    unawaited(_recoverRoomsIfNeeded('app_resume'));
    _replayUnacknowledgedFeedUploadEvents();
    unawaited(_fcmService.refreshTokenSync());
    unawaited(_reconcileUnreadStateFromServer());
    _scheduleUnreadReconcile();
    if (!_showRoomSelection) {
      final activeRoomId = _roomId;
      if (activeRoomId != null) {
        unawaited(_refreshLatestFeed(activeRoomId));
        unawaited(_refreshEffectivePetStatusForRooms([activeRoomId]));
        unawaited(_tickPetState());
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

  bool get _isEquipTargetMain =>
      _selectedEquipPetId == null || _selectedEquipPetId == _petId;

  // Source of equipment shown in the inventory panel: the main pet's live map
  // when the selected target is the main pet, otherwise the dedicated panel map.
  Map<String, _EquippedPetItem> get _panelTargetEquippedItemsBySlot =>
      _isEquipTargetMain ? _equippedItemsBySlot : _panelEquippedItemsBySlot;

  Map<String, String> get _panelEquippedSkusBySlot =>
      _equippedSkusFromItemsBySlot(_panelTargetEquippedItemsBySlot);

  Map<String, String> get _panelEquippedItemIdsBySlot =>
      _panelTargetEquippedItemsBySlot.map(
        (slot, item) => MapEntry(slot, item.itemId),
      );

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
    // Pro-plan status only drives room locking, which re-applies reactively via
    // setState — don't let RevenueCat gate first paint.
    unawaited(_refreshProPlanStatus());
    // Rooms are the slow part and don't depend on the profile/coins reads, so
    // fetch them concurrently instead of after them.
    final roomsFuture = _fetchRooms();
    // `_ensureProfile` *inserts* the profile row when it is missing, and
    // `_loadCoins` reads it — so on a first launch they must stay serial or the
    // coins read can miss the row and leave nickname/avatar blank. A restored
    // nickname proves the row already exists, which is the common case; there
    // the two reads are independent and can share one round-trip window.
    final profileFuture = _ensureProfile();
    try {
      if (_myNickname == null) {
        await profileFuture;
        await _loadCoins();
      } else {
        await Future.wait<void>([profileFuture, _loadCoins()]);
      }
      await roomsFuture;
    } finally {
      // Bootstrap has now had its attempt at the room list; from here on an
      // arriving session or an app resume is allowed to retry it. This has to
      // hold even if a read above throws: leaving the flag false would disable
      // both recovery paths for the rest of this mount, which is exactly the
      // blank-room-list failure they exist to undo.
      _roomsBootstrapAttempted = true;
    }
    // `_fetchRooms` now projects decay client-side, so the health bars are
    // already accurate without an extra per-pet `tick_pet_state` round-trip.
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
      _restoreCachedPetStates(
        snapshot['pet_states'],
        savedAt: parseOptionalDate(snapshot['saved_at'])?.toUtc(),
      );
      _restoreCachedBackgroundKeys(snapshot['background_keys']);
      _syncOnboardingProfileDraftFromCurrentData();
      _syncCurrencyProvider();
      _syncRoomProviders();
      _syncUnreadCountsProvider(_myRooms);
      _evaluateBasicOnboardingAgainstCurrentData();
    } catch (_) {
      // Best effort. If cache read fails we continue with network bootstrap.
    }
  }

  /// Rehydrates the last resolved background key per room so a cold entry can
  /// paint the real background immediately. Snapshots written before this field
  /// existed simply have no `background_keys` entry and fall back to the
  /// previous behaviour (default background until the loaders return).
  void _restoreCachedBackgroundKeys(dynamic raw) {
    if (raw is! Map) {
      return;
    }
    for (final entry in raw.entries) {
      final roomId = entry.key;
      final backgroundKey = entry.value;
      if (roomId is! String || backgroundKey is! String) {
        continue;
      }
      // A key from a newer build (or a since-removed background) must not be
      // resurrected as the default — drop anything this build cannot render.
      if (backgroundKey.isEmpty ||
          !RoomBackgrounds.supportsKey(backgroundKey)) {
        continue;
      }
      _cachedBackgroundKeyByRoom[roomId] = backgroundKey;
    }
  }

  /// Rehydrates `_petStateByRoom` / `_petIdByRoom` (and the decay freshness
  /// clock) from the persisted bootstrap snapshot so a previously visited room
  /// can warm-enter instantly after a relaunch. Each pet_state row carries its
  /// own `pet_id`, so no separate id map is needed.
  void _restoreCachedPetStates(dynamic raw, {DateTime? savedAt}) {
    if (raw is! Map) {
      return;
    }
    for (final entry in raw.entries) {
      final roomId = entry.key;
      final value = entry.value;
      if (roomId is! String || value is! Map) {
        continue;
      }
      var state = Map<String, dynamic>.from(value);
      final petId = state['pet_id'] as String?;
      if (petId == null || petId.isEmpty) {
        continue;
      }
      // Old cache payloads stored a projected card value separately from the
      // raw per-room pet_state. Normalize that one-time upgrade path so tapping
      // a card cannot show a different hunger value inside Home.
      if (state[petStatusEffectiveHungerKey] == null) {
        final room = _myRooms.cast<Map<String, dynamic>?>().firstWhere(
          (candidate) => candidate?['id'] == roomId,
          orElse: () => null,
        );
        final cachedHealth = (room?['pet_health'] as num?)?.toDouble();
        if (cachedHealth != null && cachedHealth.isFinite) {
          state = stampAuthoritativePetState({
            ...state,
            'hunger': (cachedHealth.clamp(0.0, 1.0) * 100).round(),
          }, receivedAt: savedAt);
        }
      }
      _petStateByRoom[roomId] = state;
      _petIdByRoom[roomId] = petId;
      _noteAppliedPetStateClock(petId, state);
    }
  }

  Future<void> _cacheHomeBootstrapSnapshot() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    // Never persist a room list we have not actually fetched. `_loadCoins`
    // reaches this before `_fetchRooms` finishes, so without this guard a
    // failed fetch cached an empty list and the blank room selection survived
    // restarts — turning a transient failure into a permanent one.
    if (!_roomsLoadedFromNetwork) {
      return;
    }
    // Persist last-known per-room pet state so the first entry of a previously
    // visited room is "warm" (instant paint) even after an app relaunch, not
    // just within the same session. Scoped to current rooms to bound size.
    final roomIds = _myRooms
        .map((room) => room['id'])
        .whereType<String>()
        .toSet();
    final petStates = <String, dynamic>{
      for (final entry in _petStateByRoom.entries)
        if (roomIds.contains(entry.key)) entry.key: entry.value,
    };
    final backgroundKeys = <String, dynamic>{
      for (final entry in _cachedBackgroundKeyByRoom.entries)
        if (roomIds.contains(entry.key)) entry.key: entry.value,
    };
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
        'pet_states': petStates,
        'background_keys': backgroundKeys,
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
    _scheduleHomeBootstrapCachePersist();
  }

  void _scheduleHomeBootstrapCachePersist() {
    _homeBootstrapCachePersistTimer?.cancel();
    _homeBootstrapCachePersistTimer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_cacheHomeBootstrapSnapshot()),
    );
  }

  /// Whether an incoming `pet_state`/`room_pet_state` snapshot for [petId] is at
  /// least as fresh as the last one applied. Snapshots with a strictly older
  /// `last_decay_at` anchor are stale and dropped. Records without an anchor are
  /// accepted (they cannot be ordered) but do not move the clock.
  bool _isPetStateRecordFresh(String petId, Map<String, dynamic>? record) {
    if (record == null) {
      return false;
    }
    return petStateSnapshotIsFresh(
      held: _petStateDecayClockByPetId[petId],
      incoming: parseOptionalDate(record['last_decay_at'])?.toUtc(),
    );
  }

  void _noteAppliedPetStateClock(String petId, Map<String, dynamic> record) {
    final incoming = parseOptionalDate(record['last_decay_at'])?.toUtc();
    if (incoming == null) {
      return;
    }
    final held = _petStateDecayClockByPetId[petId];
    if (held == null || incoming.isAfter(held)) {
      _petStateDecayClockByPetId[petId] = incoming;
    }
  }

  /// Applies the authoritative committed pet state returned by `feed_validate`
  /// directly, so the satiety bar reflects the just-fed value without depending
  /// on a racy realtime event or refetch. Merged (not replaced) so columns the
  /// edge function does not return (alerts, feed_count, …) are preserved.
  void _applyAuthoritativeFeedPetState(
    String roomId,
    Map<String, dynamic> petState,
  ) {
    if (!mounted || roomId != _roomId) {
      return;
    }
    final petId = _petId;
    if (petId == null || !_isPetStateRecordFresh(petId, petState)) {
      return;
    }
    final merged = stampAuthoritativePetState({...?_petState, ...petState});
    final hunger = merged['hunger'] as num?;
    final healthValue = _healthValueFromHunger(hunger);
    setState(() {
      _petState = merged;
      _petStateReady = true;
      _myRooms = _myRooms
          .map(
            (room) => room['id'] == roomId
                ? {...room, 'pet_health': healthValue}
                : room,
          )
          .toList();
    });
    _noteAppliedPetStateClock(petId, merged);
    _cachePetState(roomId, petId, merged);
    _syncPetStateProvider();
    _handleOverfedState();
  }

  void _applyPetStateUpdate(
    String roomId,
    String petId,
    Map<String, dynamic>? state,
  ) {
    if (state == null) {
      return;
    }
    if (!_isPetStateRecordFresh(petId, state)) {
      return;
    }
    final normalizedState = stampAuthoritativePetState(state);
    _noteAppliedPetStateClock(petId, normalizedState);
    _cachePetState(roomId, petId, normalizedState);
    _subscribeToPetState(petId);
    final hunger = petStatusHunger(normalizedState);
    final healthValue = _healthValueFromHunger(hunger);
    if (!mounted) {
      _petId = petId;
      _petState = normalizedState;
      _petStateReady = true;
      return;
    }
    setState(() {
      _petId = petId;
      _petState = normalizedState;
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
    _handlePetDepartureState(
      roomId: roomId,
      petId: petId,
      state: normalizedState,
    );
  }

  Offset _nextPoopPosition() {
    final x = (_random.nextDouble() * 0.6) + 0.2;
    final y = (_random.nextDouble() * 0.4) + 0.55;
    return Offset(x, y);
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

  void _setStateForRoomDecor(VoidCallback mutation) {
    setState(mutation);
  }

  void _setStateForEquipment(VoidCallback mutation) {
    setState(mutation);
  }

  void _setStateForDebug(VoidCallback mutation) {
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
        // Keep the equipment target valid; fall back to the main pet if the
        // previously selected pet left the room.
        if (_selectedEquipPetId == null ||
            !livePetIds.contains(_selectedEquipPetId)) {
          _selectedEquipPetId = _petId;
        }
      });
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
      final newTarget = _randomExtraPetTarget();
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
    // The pet renders at normalizedTarget, so anchor the drag there to avoid
    // a snap-back to a stale departure point.
    final currentTopLeft = _positionFromNormalized(
      runtime.normalizedTarget,
      fieldSize,
    );
    runtime.arrivalTimer?.cancel();
    setState(() {
      runtime
        ..isDragging = true
        ..isWalking = true
        ..dragOffset = local - currentTopLeft
        ..normalizedPosition = runtime.normalizedTarget
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
    // Compute facing against the previous position before overwriting it
    // (matching the main pet's convention: moving left ⇒ facingRight/no flip).
    final dx = normalized.dx - runtime.normalizedTarget.dx;
    setState(() {
      if (dx.abs() > 0.001) {
        runtime.facingRight = dx < 0;
      }
      runtime
        ..normalizedPosition = normalized
        ..normalizedTarget = normalized
        ..animDuration = Duration.zero;
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
                        equippedSkusBySlot:
                            _equippedSkusByPetId[pet.petId] ?? const {},
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
      // The promoted pet is now the canonical main row. Point active pet
      // state at it explicitly — otherwise _refreshPetState keeps using the
      // stale _petId (the old main, now an extra) and loads the wrong pet.
      _petSubscriptionPetId = null;
      setState(() {
        _petId = selectedId;
        _selectedEquipPetId = selectedId;
        _panelEquippedItemsBySlot.clear();
        _petState = null;
        _petStateReady = false;
      });
      await _loadRoomPets(roomId);
      await _refreshPetState();
    } catch (error) {
      if (!mounted) return;
      // A stale switcher list can reference a pet that already moved; recover
      // by reloading instead of surfacing a scary error.
      if (error.toString().contains('pet_not_found')) {
        await _loadRoomPets(roomId);
        return;
      }
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
      unawaited(_loadAllPetEquipment(roomId));
      _subscribeToRoomPets(roomId);
      _subscribeToPetState(petId);
      _subscribeToPetEquipment(roomId);
      unawaited(_loadPetInfo(petId, roomId: roomId));

      if (tick) {
        // Decay must land before we read health, but alert dispatch is a pure
        // side effect — don't keep the room-entry overlay up for it.
        await _tickPetStateRpc(petId);
        unawaited(_dispatchNewHungerAlerts(petId: petId, roomId: roomId));
      }

      final state = await Supabase.instance.client
          .from('pet_state')
          .select()
          .eq('pet_id', petId)
          .maybeSingle();
      if (!mounted) {
        return;
      }
      // A refetch normally returns the freshest value, but if a newer realtime
      // snapshot already landed, this read can be stale — don't let it clobber.
      final isStaleSnapshot =
          state != null && !_isPetStateRecordFresh(petId, state);
      final normalizedState = state == null
          ? null
          : stampAuthoritativePetState(state);
      final hunger = petStatusHunger(normalizedState);
      final healthValue = _healthValueFromHunger(hunger);

      setState(() {
        _petId = petId;
        if (!isStaleSnapshot) {
          _petState = normalizedState;
          _myRooms = _myRooms
              .map(
                (room) => room['id'] == roomId
                    ? {...room, 'pet_health': healthValue}
                    : room,
              )
              .toList();
        }
        _petStateReady = true;
      });
      _syncPetStateProvider();
      if (normalizedState != null && !isStaleSnapshot) {
        _noteAppliedPetStateClock(petId, normalizedState);
        _cachePetState(roomId, petId, normalizedState);
      }
      _handleOverfedState();
      _handlePetDepartureState(
        roomId: roomId,
        petId: petId,
        state: isStaleSnapshot ? _petState : normalizedState,
      );
      unawaited(_loadPetEquipment(petId: petId, roomId: roomId, silent: true));
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      // A refresh is a revalidation of state the user can already see. Letting
      // a transient failure paint an error over a good pet is the same mistake
      // as replacing a bootstrap snapshot with a stale-room summary: report it,
      // but only surface it when there is nothing on screen to fall back to.
      if (_petStateReady && _petState != null) {
        reportSwallowedError(
          error,
          stackTrace,
          source: 'home_refresh_pet_state',
        );
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
      // Drop stale realtime snapshots (e.g. a pre-feed decay tick arriving after
      // the fed value) so they cannot overwrite a fresher satiety reading.
      if (!_isPetStateRecordFresh(petId, record)) {
        return;
      }
      final nextState = stampAuthoritativePetState(record);
      _noteAppliedPetStateClock(petId, nextState);
      setState(() {
        _petId = petId;
        _petState = nextState;
        _petStateReady = true;
        final hunger = petStatusHunger(_petState);
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
      if (!mounted) {
        return;
      }
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

  Future<void> _openPetNameEditor({_RoomPet? targetPet}) async {
    final isMain = targetPet == null;
    final petId = isMain ? _petId : targetPet.petId;
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
    final currentName = (isMain ? _petName : targetPet.name)?.trim() ?? '';

    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
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
                // Renaming has to honour the same cap as naming: this editor
                // used to accept any length, which is how names longer than the
                // creation limit got into the data in the first place.
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(_petNameMaxLength),
                ],
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
                            textAlign: TextAlign.center,
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
                            textAlign: TextAlign.center,
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
    if (trimmed.isEmpty || trimmed == currentName) {
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
      if (isMain) {
        setState(() {
          _petName = trimmed;
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
      } else if (roomId != null) {
        // Extra pets only carry their own identity name; reload so the on-screen
        // name tag and selector reflect the change.
        await _loadRoomPets(roomId);
      }
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

  /// Refreshes only effective pet status for the room-selection cards. This is
  /// intentionally independent from feeds, equipment, unread, and member-count
  /// reads so a slow non-status request cannot delay the hunger display.
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
    try {
      final roomIds = _myRooms
          .map((room) => room['id'])
          .whereType<String>()
          .toList(growable: false);
      await _refreshEffectivePetStatusForRooms(roomIds);
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

  Future<void> _refreshEffectivePetStatusForRooms(List<String> roomIds) async {
    if (roomIds.isEmpty) {
      return;
    }
    try {
      final statuses = await _fetchEffectivePetStatuses(roomIds);
      if (statuses.isEmpty || !mounted) {
        return;
      }
      final accepted = <String, PetStatusSnapshot>{};
      for (final status in statuses.values) {
        if (_isPetStateRecordFresh(status.petId, status.petState)) {
          accepted[status.roomId] = status;
        }
      }
      if (accepted.isEmpty) {
        return;
      }

      var currentRoomChanged = false;
      setState(() {
        _myRooms = _myRooms
            .map((room) {
              final status = accepted[room['id'] as String?];
              if (status == null) {
                return room;
              }
              return {
                ...room,
                'pet_id': status.petId,
                'pet_health': status.healthValue,
              };
            })
            .toList(growable: false);

        final current = accepted[_roomId];
        if (current != null && (_petId == null || _petId == current.petId)) {
          _petId = current.petId;
          _petState = current.petState;
          _petStateReady = true;
          currentRoomChanged = true;
        }
      });

      for (final status in accepted.values) {
        _noteAppliedPetStateClock(status.petId, status.petState);
        _cachePetState(status.roomId, status.petId, status.petState);
      }
      _syncRoomProviders();
      if (currentRoomChanged) {
        _syncPetStateProvider();
        final current = accepted[_roomId];
        if (current != null) {
          _handlePetDepartureState(
            roomId: current.roomId,
            petId: current.petId,
            state: current.petState,
          );
        }
      }
    } catch (_) {
      // Stale-while-revalidate: keep the last visible snapshot on failure.
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

  List<_PlacedFurniture> _activeFurnitureForRoom() {
    final roomId = _roomId;
    if (roomId == null) {
      return const [];
    }
    return _placedFurnitureByRoom.putIfAbsent(roomId, () => []);
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

    // Lock onto this specific poop so a double-tap (or a re-render mid-clean)
    // can't fire a second RPC for the same one.
    final key = _poopKeyForIndex(index);
    if (_cleaningPoopKeys.contains(key)) {
      return;
    }

    if (!await _ensureOnlineForWrite()) {
      return;
    }

    // Optimistic: vanish + haptic right away. We intentionally do NOT flip the
    // global `_petBusy` flag here, so the pet and any remaining poops stay
    // interactive while this clean completes in the background.
    setState(() {
      _cleaningPoopKeys.add(key);
      _petError = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) {
        if (mounted) setState(() => _cleaningPoopKeys.remove(key));
        return;
      }

      // clean_poop returns a table with poop_count and coins_awarded
      final result = await Supabase.instance.client.rpc(
        'clean_poop',
        params: {'p_pet_id': petId, 'p_poop_index': index},
      );

      // Extract coins_awarded from the result shape safely.
      final actualReward = _extractRewardAmount(result);

      // Lightweight reconcile: pull just the pet_state row so poop_positions
      // settles, and refresh coins/info without blocking or churning the whole
      // scene the way _refreshPetState would.
      await _reconcilePetStateAfterClean(petId, roomId);
      unawaited(_loadCoins(expectedReward: actualReward));
      unawaited(_loadPetInfo(petId, roomId: roomId));
    } catch (error) {
      if (mounted) {
        setState(
          () => _petError = AppLocalizations.of(
            context,
          )!.petActionFailed(userFacingError(context, error)),
        );
      }
    } finally {
      // Drop the optimistic hold last: by now the reconciled state has already
      // dropped this poop, so there's no flicker of it reappearing.
      if (mounted) setState(() => _cleaningPoopKeys.remove(key));
    }
  }

  /// Refresh just the pet_state row after a clean, without the heavy
  /// room/equipment reloads or the `_petBusy` toggle that `_refreshPetState`
  /// performs. Keeps the clean interaction smooth; realtime would also
  /// reconcile, this just makes it deterministic.
  Future<void> _reconcilePetStateAfterClean(String petId, String roomId) async {
    try {
      final state = await Supabase.instance.client
          .from('pet_state')
          .select()
          .eq('pet_id', petId)
          .maybeSingle();
      if (!mounted || state == null) return;
      if (!_isPetStateRecordFresh(petId, state)) {
        return;
      }
      final normalizedState = stampAuthoritativePetState(state);
      _noteAppliedPetStateClock(petId, normalizedState);
      setState(() {
        _petId = petId;
        _petState = normalizedState;
        _petStateReady = true;
      });
      _syncPetStateProvider();
      _cachePetState(roomId, petId, normalizedState);
    } catch (_) {
      // Best-effort only — the pet_state realtime subscription will still
      // deliver the updated poop list.
    }
  }

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
    if (_roomEntryOverlayVisible &&
        _roomEntryLoading &&
        !_showRoomSelection &&
        selectedRoomId != null) {
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
      return _buildRoomSelectionScaffold(
        overlayStyle,
        unreadCountByRoom,
        roomSelectionId,
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
                statusBar: _buildHomeStatusBar(
                  currency,
                  petSnapshot,
                  selectedRoomId,
                  activeRoomId,
                ),
                photoGallery: PetPhotoGallery(
                  roomId: _roomId,
                  imageUrls: _latestFeedImageUrls,
                  captions: _latestFeedCaptions,
                  sentAts: _latestFeedSentAts,
                  messageIds: _latestFeedMessageIds,
                  senderIds: _latestFeedSenderIds,
                  onPhotoRecalled: _handleFeedPhotoRecalled,
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
                  availableEquipmentCount: _availableEquipmentCopies,
                  equippedItemIdsBySlot: _panelEquippedItemIdsBySlot,
                  equippedItemSkusBySlot: _panelEquippedSkusBySlot,
                  equipmentLoading: _equipmentLoading,
                  equipmentErrorText: _equipmentError,
                  equipPets: _equipPetOptionsForRoom(activeRoomId),
                  selectedEquipPetId: _selectedEquipPetId,
                  onSelectEquipPet: _onSelectEquipPet,
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
