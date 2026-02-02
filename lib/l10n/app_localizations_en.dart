// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appleSignInRejected =>
      'Apple sign-in rejected. Check Supabase Apple provider client ID.';

  @override
  String get authReauthRequired => 'Please sign in again.';

  @override
  String blockedUserIdTruncated(Object id) {
    return 'ID (truncated): $id';
  }

  @override
  String get blockedUsersEmpty => 'No blocked users yet.';

  @override
  String blockedUsersLoadFailed(Object error) {
    return 'Failed to load blocked users: $error';
  }

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String get blockedUserUnblocked => 'User unblocked.';

  @override
  String blockedUserUnblockFailed(Object error) {
    return 'Unblock failed: $error';
  }

  @override
  String get calendarAddMemory => 'Add memory';

  @override
  String get calendarEarlier => 'Earlier';

  @override
  String get calendarLatestPhoto => 'Latest photo';

  @override
  String calendarLoadFailed(Object error) {
    return 'Failed to load memories: $error';
  }

  @override
  String get calendarNoEarlierMemories => 'No earlier memories yet.';

  @override
  String get calendarNoMemoriesForDay => 'No memories for this day.';

  @override
  String get calendarNoPhotoYet => 'No photo yet';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarToday => 'Today';

  @override
  String chatBlockFailed(Object error) {
    return 'Block failed: $error';
  }

  @override
  String get chatBlockUser => 'Block user';

  @override
  String chatCoinsAwarded(Object count) {
    return '+$count candy';
  }

  @override
  String get chatEmptyState => 'No messages yet. Start the chat below.';

  @override
  String chatLoadBlockedUsersFailed(Object error) {
    return 'Failed to load blocked users: $error';
  }

  @override
  String chatLoadCacheFailed(Object error) {
    return 'Failed to load cached messages: $error';
  }

  @override
  String chatLoadMessagesFailed(Object error) {
    return 'Failed to load messages: $error';
  }

  @override
  String chatLoadMoreFailed(Object error) {
    return 'Failed to load more: $error';
  }

  @override
  String get chatLoadOlderMessages => 'Load older messages';

  @override
  String get chatMessageHint => 'Message';

  @override
  String get chatNoOlderMessages => 'No older messages.';

  @override
  String get chatPartnerLabel => 'Partner';

  @override
  String chatRefreshFailed(Object error) {
    return 'Failed to refresh: $error';
  }

  @override
  String chatReportFailed(Object error) {
    return 'Report failed: $error';
  }

  @override
  String get chatReportHint => 'Share a quick reason';

  @override
  String get chatReportMessageTitle => 'Report message';

  @override
  String get chatReportNoReason => 'No reason';

  @override
  String get chatReportSent => 'Report submitted.';

  @override
  String chatSendFailed(Object error) {
    return 'Send failed: $error';
  }

  @override
  String get chatSystemUpdate => 'System update';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatUserAlreadyBlocked => 'User blocked';

  @override
  String get chatUserBlocked => 'User blocked.';

  @override
  String get commonBuy => 'Buy';

  @override
  String get commonCamera => 'Camera';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonGallery => 'Gallery';

  @override
  String get commonJoin => 'Join';

  @override
  String get commonLeave => 'Leave';

  @override
  String get commonOwned => 'Owned';

  @override
  String get commonReload => 'Reload';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSend => 'Send';

  @override
  String get commonSending => 'Sending...';

  @override
  String get commonSignOut => 'Sign Out';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonUnblock => 'Unblock';

  @override
  String get commonUploading => 'Uploading';

  @override
  String get commonUser => 'User';

  @override
  String currencyJpy(Object amount) {
    return 'JPY $amount';
  }

  @override
  String get drawerCreateRoom => 'Create New Room';

  @override
  String get drawerDebugTools => 'Debug Tools';

  @override
  String get drawerForceRefreshPet => 'Force Refresh Pet';

  @override
  String get drawerFreePlan => 'Free Plan';

  @override
  String drawerInviteCode(Object code) {
    return 'Code: $code';
  }

  @override
  String get drawerJoinWithCode => 'Join with Invite Code';

  @override
  String get drawerMyRooms => 'My Rooms';

  @override
  String get drawerNoRooms => 'No rooms yet.';

  @override
  String get drawerPetError => 'Pet Error';

  @override
  String get drawerRegenerateInviteCode => 'Regenerate invite code';

  @override
  String get drawerSimulateFeed => 'Simulate Feed';

  @override
  String get drawerTestNotification => 'Test Local Notification';

  @override
  String get feedCameraSubtitle =>
      'Capture a feed photo and review labels before sending.';

  @override
  String get feedCameraTitle => 'Feed Camera';

  @override
  String feedCanonicalTags(Object tags) {
    return 'Canonical tags: $tags';
  }

  @override
  String get feedCaptionLabel => 'Caption (optional)';

  @override
  String get feedDetectedLabels => 'Detected labels';

  @override
  String feedLabelingFailed(Object error) {
    return 'Labeling failed: $error';
  }

  @override
  String get feedLabelingNotSupported =>
      'ML Kit image labeling is not supported on web.';

  @override
  String feedLabelMappingsFailed(Object error) {
    return 'Failed to load label mappings: $error';
  }

  @override
  String get feedLabelMappingsLoading => 'Loading label mappings...';

  @override
  String get feedLabelMappingsReady => 'Label mappings ready.';

  @override
  String get feedLabelMappingsUnavailable => 'Label mappings unavailable.';

  @override
  String get feedNoLabels => 'No labels detected yet.';

  @override
  String feedResponse(Object response) {
    return 'Response: $response';
  }

  @override
  String get feedSelectImageFirst => 'Select an image first.';

  @override
  String get feedSendButton => 'Send Feed';

  @override
  String feedSendFailed(Object error) {
    return 'Send failed: $error';
  }

  @override
  String get feedTitle => 'Feed';

  @override
  String feedUploadFailed(Object error) {
    return 'Feed upload failed: $error';
  }

  @override
  String get forceUpdateAction => 'Update now';

  @override
  String get forceUpdateLinkError => 'Unable to open store link.';

  @override
  String get forceUpdateMessage =>
      'A newer version is required to continue. Please update now.';

  @override
  String get forceUpdateTitle => 'Update required';

  @override
  String get languageChineseTraditional => 'Traditional Chinese';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSystemSubtitle => 'Follow device language';

  @override
  String get languageTitle => 'Language';

  @override
  String get launchTagline => 'Share moments. Grow together.';

  @override
  String get moodHigh => 'HIGH';

  @override
  String get moodLow => 'LOW';

  @override
  String get moodMid => 'MID';

  @override
  String get moodNeutral => 'NEUTRAL';

  @override
  String get moodSad => 'SAD';

  @override
  String petActionFailed(Object error) {
    return 'Action failed: $error';
  }

  @override
  String get petHomeTitle => 'Pet Home';

  @override
  String get petNotFound => 'No pet found.';

  @override
  String petSyncFailed(Object error) {
    return 'Pet sync error: $error';
  }

  @override
  String get photoLabel => 'Photo';

  @override
  String get profileDefaultNickname => 'Pet Parent';

  @override
  String get profileEmpty => 'No profile available.';

  @override
  String profileLoadFailed(Object error) {
    return 'Failed to load profile: $error';
  }

  @override
  String get profileNicknameLabel => 'Nickname';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileAvatarTitle => 'Choose an avatar';

  @override
  String get profileAvatarEdit => 'Edit avatar';

  @override
  String get profileAvatarUpload => 'Upload photo';

  @override
  String get profileAvatarRemove => 'Remove';

  @override
  String profileCoinsLabel(Object amount) {
    return 'Candy: $amount';
  }

  @override
  String get profileDeleteAccountSectionTitle => 'Delete account';

  @override
  String get profileDeleteAccountSectionBody =>
      'This permanently deletes your account. Shared rooms and pets stay with other members.';

  @override
  String get profileDeleteAccountAction => 'Delete account';

  @override
  String get profileDeleteAccountTitle => 'Delete account?';

  @override
  String get profileDeleteAccountConfirmBody =>
      'This will permanently delete your account and personal data. Shared rooms/pets remain and ownership transfers to other members. This cannot be undone.';

  @override
  String get profileDeleteAccountConfirmAction => 'Delete';

  @override
  String profileDeleteFailed(Object error) {
    return 'Failed to delete account: $error';
  }

  @override
  String profileUserId(Object id) {
    return 'User ID: $id';
  }

  @override
  String get drawerProfile => 'Profile';

  @override
  String get roomCreatedSuccess => 'Room created! Check the Drawer.';

  @override
  String roomCreateFailed(Object error) {
    return 'Failed to create room: $error';
  }

  @override
  String get roomDefaultName => 'New Room';

  @override
  String get roomInviteCodeRegenerated => 'Invite code regenerated.';

  @override
  String roomInviteCodeRegenerateFailed(Object error) {
    return 'Failed to regenerate code: $error';
  }

  @override
  String roomJoinFailed(Object error) {
    return 'Failed to join room: $error';
  }

  @override
  String get roomJoinHelper => 'Invite codes are case-insensitive.';

  @override
  String get roomJoinHint => 'Enter 6-digit code';

  @override
  String get roomJoinSuccess => 'Joined room successfully.';

  @override
  String get roomJoinTitle => 'Join Room';

  @override
  String roomLeaveFailed(Object error) {
    return 'Failed to leave room: $error';
  }

  @override
  String get roomLeaveMessage =>
      'You will lose access to this pet until you are invited again.';

  @override
  String get roomLeaveSuccess => 'Left room successfully.';

  @override
  String get roomLeaveTitle => 'Leave Room?';

  @override
  String get roomLimitReached =>
      'Free limit reached (2 rooms max). Upgrade to create more!';

  @override
  String roomNewInviteCode(Object code) {
    return 'New invite code: $code';
  }

  @override
  String get roomSelectionCreatePet => 'Create New Pet';

  @override
  String get roomSelectionCreating => 'Creating...';

  @override
  String get roomSelectionEmptySlot => 'Empty slot';

  @override
  String get roomSelectionEnterInvite => 'Enter Invite Code';

  @override
  String get roomSelectionJoining => 'Joining...';

  @override
  String get roomSelectionRoomFallback => 'Room';

  @override
  String get roomSelectionSubtitle => 'Pick a pet home and jump back in.';

  @override
  String get roomSelectionTitle => 'Room Selection';

  @override
  String get signInFailed => 'Sign-in failed. Please try again.';

  @override
  String get signInNote =>
      'Note: OAuth providers must be configured in Supabase.';

  @override
  String get signInOpening => 'Opening sign-in...';

  @override
  String signInOpeningProvider(Object provider) {
    return 'Opening $provider...';
  }

  @override
  String get signInSubtitle => 'Sign in to start co-raising your pet.';

  @override
  String get signInWithApple => 'Continue with Apple';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String storeCoinPrice(Object amount) {
    return 'Candy: $amount';
  }

  @override
  String storeCoinsLabel(Object amount) {
    return 'Candy: $amount';
  }

  @override
  String storeCoinsReward(Object amount) {
    return 'Candy +$amount';
  }

  @override
  String storeDiamondsLabel(Object amount) {
    return 'Diamonds: $amount';
  }

  @override
  String storeDiamondsReward(Object amount) {
    return 'Diamonds +$amount';
  }

  @override
  String get storeEmpty => 'Store is empty for now.';

  @override
  String get storeIapNotConfigured => 'IAP not configured.';

  @override
  String storeIapUnavailable(Object error) {
    return 'IAP unavailable: $error';
  }

  @override
  String storeLoadFailed(Object error) {
    return 'Failed to load store: $error';
  }

  @override
  String get storeNotEnoughCoins => 'Not enough candy.';

  @override
  String storeOwnedCount(Object amount) {
    return 'Owned: $amount';
  }

  @override
  String get storePriceUnavailable => 'Price unavailable';

  @override
  String get storeProductNotFound => 'Product not found in RevenueCat.';

  @override
  String get storeProductUnavailable => 'Product unavailable.';

  @override
  String storePurchaseFailed(Object error) {
    return 'Purchase failed: $error';
  }

  @override
  String storePurchaseSuccess(Object name) {
    return 'Purchased $name.';
  }

  @override
  String storeRestoreFailed(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String get storeRestoreTooltip => 'Restore purchases';

  @override
  String get storeSectionCoinPacks => 'Candy Packs';

  @override
  String get storeSectionCoinStore => 'Candy Store';

  @override
  String get storeSectionDiamondPacks => 'Diamond Packs';

  @override
  String get storeSectionDiamondStore => 'Diamond Store';

  @override
  String get storeSectionSubscription => 'Subscription';

  @override
  String get storeSignInPrompt => 'Please sign in to access the store.';

  @override
  String get storeSubscribe => 'Subscribe';

  @override
  String get storeSubscriptionActive => 'Active';

  @override
  String get storeTitle => 'Store';

  @override
  String get storeTypeConsumable => 'Consumable';

  @override
  String get storeTypeCosmetic => 'Cosmetic';

  @override
  String get storeTypeSubscription => 'Subscription';

  @override
  String get furnitureInventoryTitle => 'Furniture';

  @override
  String get furnitureInventorySubtitle => 'Place items in your pet home.';

  @override
  String get furnitureInventoryEmpty =>
      'No furniture yet. Buy some in the store.';

  @override
  String get furnitureInventoryHint =>
      'Long-press furniture to edit. Tap an item to place, drag to move. Tap empty space to exit.';

  @override
  String get furnitureEditMode => 'Furniture Mode';
}
