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
  String get chatCandyLabel => 'Candys';

  @override
  String chatCleanPoopMessage(Object name, Object amount) {
    return '$name cleaned the poop: +$amount Candys.';
  }

  @override
  String chatPetHungryReminderMessage(Object petName) {
    return '$petName is getting hungry. Time to feed!';
  }

  @override
  String chatPetHungryUrgentMessage(Object petName) {
    return '$petName is very hungry! Please feed now!';
  }

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatUserAlreadyBlocked => 'User blocked';

  @override
  String get chatUserBlocked => 'User blocked.';

  @override
  String chatMemberCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String get calendarYesterday => 'Yesterday';

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
  String get photoViewerDownloadTooltip => 'Download';

  @override
  String get photoViewerSavedToGallery => 'Saved to your photo gallery.';

  @override
  String get photoViewerSaveFailed => 'Couldn\'t save photo to your gallery.';

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
  String get errorInvalidInviteCode =>
      'That invite code is invalid or expired.';

  @override
  String get errorNetwork =>
      'Network error. Please check your connection and try again.';

  @override
  String get errorNotFound => 'Requested data was not found.';

  @override
  String get errorPermissionDenied => 'You don\'t have permission to do that.';

  @override
  String get errorImageTooLarge =>
      'Image is too large. Please choose a smaller image.';

  @override
  String get errorPetNameInvalid =>
      'That pet name is not allowed. Please use a different name.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String currencyJpy(Object amount) {
    return 'JPY $amount';
  }

  @override
  String get drawerCreateRoom => 'Create New Room';

  @override
  String get drawerDebugTools => 'Debug Tools';

  @override
  String get drawerFreePlan => 'Free Plan';

  @override
  String get drawerProPlan => 'Pro Plan';

  @override
  String get drawerDebugAddCandy => '+100 Candy';

  @override
  String get drawerDebugAddDiamonds => '+100 Diamonds';

  @override
  String get drawerDebugTogglePlan => 'Toggle Plan';

  @override
  String get drawerDebugForceOnboarding => 'Always Show Onboarding';

  @override
  String get drawerDebugForceOnboardingEnabled => 'Show on every app open';

  @override
  String get drawerDebugForceOnboardingDisabled =>
      'Use normal one-time behavior';

  @override
  String get drawerDebugHungerDown => '-10 Pet Hunger';

  @override
  String get drawerDebugAddExp => '+10 EXP';

  @override
  String get drawerDebugSpawnPoop => 'Make Pet Poop';

  @override
  String get drawerDebugShowFullBubble => 'Show \"I\'m Full\" Bubble';

  @override
  String get drawerDebugTestSoftUpdate => 'Test Soft Update Prompt';

  @override
  String get drawerDebugTestHardUpdate => 'Test Hard Update Prompt';

  @override
  String get drawerDebugTestCrashReport => 'Test Crash Report';

  @override
  String get onboardingOpenRoomTitle => 'Enter Your Room';

  @override
  String get onboardingOpenRoomDescription =>
      'Tap your room card to start taking care of your pet.';

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
  String get feedCameraSubtitle => 'Capture a feed photo and send it.';

  @override
  String get feedCameraTitle => 'Feed Camera';

  @override
  String get feedPickPhotoHint => 'Pick a photo';

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
  String get feedRewardPending => 'Reward pending...';

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
  String get softUpdateAction => 'Update';

  @override
  String get softUpdateLater => 'Later';

  @override
  String get softUpdateMessage =>
      'A new version is available for a smoother co-petting experience.';

  @override
  String get softUpdateTitle => 'Update available';

  @override
  String get languageChineseSimplified => 'Simplified Chinese';

  @override
  String get languageChineseTraditional => 'Traditional Chinese';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageKorean => 'Korean';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSystemSubtitle => 'Follow device language';

  @override
  String get languageTitle => 'Language';

  @override
  String get launchAppName => 'PetTomo';

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
  String get petNameEditTitle => 'Edit pet name';

  @override
  String get petNameLabel => 'Pet name';

  @override
  String get petNameHint => 'Enter pet name';

  @override
  String get petNameEmptyError => 'Please enter a name.';

  @override
  String petNameUpdateFailed(Object error) {
    return 'Couldn\'t update pet name: $error';
  }

  @override
  String chatPetRenamedMessage(Object user, Object oldName, Object petName) {
    return '$user renamed the pet from $oldName to $petName.';
  }

  @override
  String get petNameUnnamed => 'Unnamed';

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
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionAbout => 'About & Support';

  @override
  String get profileFeedback => 'Send Feedback';

  @override
  String get profileSectionDangerZone => 'Danger Zone';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileAvatarTitle => 'Choose an avatar';

  @override
  String get profileAvatarEdit => 'Edit avatar';

  @override
  String get profileAvatarUpload => 'Upload photo';

  @override
  String get profileAvatarAdjustCurrent => 'Adjust current photo';

  @override
  String get profileAvatarAdjustUnavailable => 'No uploaded photo to adjust.';

  @override
  String get profileAvatarAdjustUnsupportedPlatform =>
      'Adjusting current photo is not supported on this platform.';

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
  String get roomCreateTitle => 'Create room';

  @override
  String get roomCreateAction => 'Create';

  @override
  String get roomNameLabel => 'Room name';

  @override
  String get roomNameHint => 'Room name';

  @override
  String get roomNameEmptyError => 'Please enter a room name.';

  @override
  String roomNameUpdateFailed(Object error) {
    return 'Couldn\'t update room name: $error';
  }

  @override
  String get roomOptionsTitle => 'Room options';

  @override
  String get roomOptionRename => 'Rename room';

  @override
  String get roomOptionLeave => 'Leave room';

  @override
  String get roomRenameTitle => 'Change room name';

  @override
  String get roomRenameMessage => 'Enter a new name for this room.';

  @override
  String get roomDefaultName => 'New Room';

  @override
  String get roomInviteCta => 'Invite';

  @override
  String get roomInventoryCta => 'Inventory';

  @override
  String get roomInvitePromptTitle => 'Invite someone';

  @override
  String get roomInvitePromptBody =>
      'You\'re the only one here. Generate a code to invite someone.';

  @override
  String get roomInvitePromptAction => 'Generate code';

  @override
  String get roomInvitePromptGenerating => 'Generating...';

  @override
  String get roomInviteCodeTitle => 'Invite code';

  @override
  String get roomInviteCodeMessage =>
      'Share this code to invite someone to your room.';

  @override
  String get roomInviteCodeTapHint => 'Tap the code to copy it.';

  @override
  String get roomInviteCodeCopiedTitle => 'Copied';

  @override
  String get roomInviteCodeCopiedMessage =>
      'Invite friends now and raise your pet together!';

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
  String get roomEnteringLoading => 'Entering room';

  @override
  String roomLeaveFailed(Object error) {
    return 'Failed to leave room: $error';
  }

  @override
  String roomLeaveMessage(Object name) {
    return 'You\'ll leave $name and lose access to its chat and pet.';
  }

  @override
  String get roomLeaveSuccess => 'Left the room.';

  @override
  String get roomLeaveTitle => 'Leave room?';

  @override
  String get roomLimitReached =>
      'Free limit reached (2 rooms max). Upgrade to create more!';

  @override
  String roomNewInviteCode(Object code) {
    return 'New invite code: $code';
  }

  @override
  String get roomSelectionCreatePet => 'Create New Room';

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
  String get storeNotEnoughDiamonds => 'Not enough diamonds.';

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
  String get storeTabPremium => 'Premium';

  @override
  String get storeTabFurniture => 'Furniture';

  @override
  String get storeTabThemes => 'Themes';

  @override
  String get storeThemePreviewAction => 'Preview';

  @override
  String storeThemePreviewTitle(Object name) {
    return '$name Preview';
  }

  @override
  String get storeItemNameProMonthly => 'Pro Monthly Membership';

  @override
  String get storeItemDescProMonthly =>
      'Monthly Pro subscription with no ads, unlimited rooms, and auto-renewal.';

  @override
  String get storeItemNameDiamondPack300 => '300 Diamond Pack';

  @override
  String get storeItemDescDiamondPack300 =>
      'Get 300 diamonds instantly (one-time purchase).';

  @override
  String get storeItemNameReturnLetter => 'Return Letter';

  @override
  String get storeItemDescReturnLetter => 'Call back a departed pet.';

  @override
  String get storeItemNameBackgroundDefault => 'Default Background';

  @override
  String get storeItemDescBackgroundDefault => 'Original cozy room backdrop.';

  @override
  String get storeItemNameBackgroundMoonlight => 'Moonlight Background';

  @override
  String get storeItemDescBackgroundMoonlight =>
      'A calm moonlit room backdrop.';

  @override
  String get storeItemNameFurnitureSofa => 'Sofa';

  @override
  String get storeItemDescFurnitureSofa => 'Comfy sofa.';

  @override
  String get storeItemNameFurniturePlant => 'Plant';

  @override
  String get storeItemDescFurniturePlant => 'Fresh green corner.';

  @override
  String get storeItemNameFurnitureFrame => 'Picture Frame';

  @override
  String get storeItemDescFurnitureFrame => 'Picture frame.';

  @override
  String get storeItemNameFurnitureTeddy => 'Teddy Bear';

  @override
  String get storeItemDescFurnitureTeddy => 'Soft teddy.';

  @override
  String get storeItemNameFurnitureBricks => 'Bricks';

  @override
  String get storeItemDescFurnitureBricks => 'Block accent.';

  @override
  String get storeItemNameFurnitureTv => 'TV';

  @override
  String get storeItemDescFurnitureTv => 'Tiny TV.';

  @override
  String get storeItemNameFurnitureBath => 'Bath';

  @override
  String get storeItemDescFurnitureBath => 'Mini bath.';

  @override
  String get storeItemNameFurnitureRibbon => 'Ribbon';

  @override
  String get storeItemDescFurnitureRibbon => 'Decor ribbon.';

  @override
  String get storeSignInPrompt => 'Please sign in to access the store.';

  @override
  String get storeSubscribe => 'Subscribe';

  @override
  String get storeSubscriptionActive => 'Active';

  @override
  String get storeSubscriptionDurationMonthly => '1 month';

  @override
  String get storeSubscriptionRenewalNote =>
      'Auto-renews monthly. Cancel anytime.';

  @override
  String get storeSubscriptionDetailsTitle => 'Subscription details';

  @override
  String storeSubscriptionDetailsBody(
    Object title,
    Object duration,
    Object price,
  ) {
    return 'Title: $title\nLength: $duration\nPrice: $price';
  }

  @override
  String get storePrivacyPolicy => 'Privacy Policy';

  @override
  String get storeTermsOfUse => 'Terms of Use';

  @override
  String get storeLegalSeparator => '|';

  @override
  String get storeLegalOpenFailed => 'Could not open the legal link.';

  @override
  String get signInSafetyAgreementLabel =>
      'I agree to the Terms of Use and Privacy Policy, including zero tolerance for objectionable content or abusive users.';

  @override
  String get signInSafetyAgreementRequired =>
      'Please accept the Terms of Use and Privacy Policy before signing in.';

  @override
  String get storeTitle => 'Store';

  @override
  String get storeTypeConsumable => 'Consumable';

  @override
  String get storeTypeCosmetic => 'Cosmetic';

  @override
  String get storeTypeSubscription => 'Subscription';

  @override
  String get furnitureInventoryTitle => 'Room Inventory';

  @override
  String get furnitureInventorySubtitle =>
      'Manage furniture and backgrounds for this room.';

  @override
  String get furnitureInventoryEmpty =>
      'No furniture yet. Buy some in the store.';

  @override
  String get furnitureInventoryHint =>
      'Long-press furniture to edit. Tap an item to place, drag to move. Tap empty space to exit.';

  @override
  String get roomInventoryTitle => 'Room Inventory';

  @override
  String get inventoryTabFurniture => 'Furniture';

  @override
  String get backgroundGalleryTab => 'Background Gallery';

  @override
  String get backgroundInventoryEmpty =>
      'No backgrounds yet. Pick one up in the store.';

  @override
  String get backgroundInventoryHint =>
      'Tap a background to apply it for everyone in the room.';

  @override
  String get backgroundApply => 'Apply';

  @override
  String get backgroundAppliedLabel => 'Applied';

  @override
  String backgroundApplyFailed(Object error) {
    return 'Failed to apply background: $error';
  }

  @override
  String get storeSectionBackgrounds => 'Backgrounds';

  @override
  String get storeSectionItems => 'Items';

  @override
  String get storeBackgroundRoomRequired =>
      'Choose a room before purchasing a background.';

  @override
  String storeBuyWithCandies(Object price) {
    return 'Buy $price Candy';
  }

  @override
  String storeBuyWithDiamonds(Object price) {
    return 'Buy $price Diamonds';
  }

  @override
  String get furnitureEditMode => 'Furniture Mode';

  @override
  String get petSelectionTitle => 'Choose your pet';

  @override
  String get petSelectionSubtitle => 'Pick a buddy to start this room.';

  @override
  String get petSelectionHint => 'Tap a pet to continue.';

  @override
  String petSelectionSelected(Object name) {
    return 'Selected: $name';
  }

  @override
  String get petSelectionConfirm => 'Start room';

  @override
  String get petSelectionStarterBadge => 'Starter';

  @override
  String petSelectionFailed(Object error) {
    return 'Pet selection failed: $error';
  }

  @override
  String get petTypeGhostName => 'Ghost';

  @override
  String get petTypeGhostTagline => 'A shy floater who loves snacks.';

  @override
  String get petTypeCatName => 'Cat';

  @override
  String get petTypeCatTagline => 'A curious pouncer with a warm purr.';

  @override
  String get petTypeFishName => 'Fish';

  @override
  String get petTypeFishTagline => 'A bubbly swimmer who loves to glide.';

  @override
  String get roomLeaveConfirm => 'Leave room';

  @override
  String get roomLockedBadge => 'LOCKED';

  @override
  String get roomLockedTitle => 'Room locked on Free plan';

  @override
  String get roomLockedMessage =>
      'Only your first 2 rooms stay active on Free. Upgrade to Pro to feed and grow pets in this room.';

  @override
  String get petDepartureNoteMessage => 'Why treat me like this...';

  @override
  String get petDepartureGuideTitle => 'Letter from your pet';

  @override
  String get petDepartureGuideMessage =>
      'Visit the Store and buy a Letter to invite your pet back.';

  @override
  String get petDepartureGuideGoStore => 'Go to Store';

  @override
  String get petDepartureLetterUnavailableTitle => 'Letter unavailable';

  @override
  String get petDepartureLetterUnavailableMessage => 'No pets have left yet.';

  @override
  String get petDepartureLetterSelectTitle => 'Choose a pet';

  @override
  String get petDepartureLetterSelectMessage =>
      'Which pet should the letter call back?';

  @override
  String petDepartureLetterConfirmTitle(Object petName) {
    return 'Call $petName back?';
  }

  @override
  String petDepartureLetterConfirmMessage(Object petName) {
    return 'Buy a Letter to invite $petName back home.';
  }

  @override
  String get petDepartureLetterConfirmAction => 'Buy Letter';

  @override
  String get petDepartureFeedDisabledTitle => 'No pet to feed';

  @override
  String get petDepartureFeedDisabledMessage =>
      'Your pet has left, so there’s no one to feed right now.';

  @override
  String get petOverfedBubble => 'I\'m full!';

  @override
  String get petNameUnknown => 'Your pet';

  @override
  String get roomNameUnknown => 'Unknown room';

  @override
  String petReturnFailed(Object error) {
    return 'Failed to return pet: $error';
  }

  @override
  String get storeAdRewardTitle => 'Watch ad for candies';

  @override
  String storeAdRewardDescription(Object amount) {
    return 'Watch a short ad and claim +$amount candies.';
  }

  @override
  String get storeAdRewardAction => 'Watch';

  @override
  String get storeAdRewardLoading => 'Loading...';

  @override
  String get storeAdRewardUnavailable => 'Ad unavailable';

  @override
  String get storeAdRewardDismissed => 'Ad closed before reward.';

  @override
  String get storeAdRewardCooldown => 'Ad reward is on cooldown right now.';

  @override
  String get storeAdRewardRoomRequired =>
      'Select a room first to claim ad rewards.';

  @override
  String storeAdRewardFailed(Object error) {
    return 'Failed to claim ad reward: $error';
  }

  @override
  String get feedAdDoubleRewardTitle => 'Double your feed reward?';

  @override
  String feedAdDoubleRewardMessage(Object amount) {
    return 'Watch an ad for +$amount extra candies?';
  }

  @override
  String feedAdDoubleRewardFailed(Object error) {
    return 'Double reward failed: $error';
  }
}
