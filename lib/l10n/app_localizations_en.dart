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
  String get chatJumpToLatest => 'Latest';

  @override
  String get chatMessageHint => 'Message';

  @override
  String get chatCopyAction => 'Copy';

  @override
  String get chatEditAction => 'Edit';

  @override
  String get chatDeleteAction => 'Delete';

  @override
  String get chatMessageCopied => 'Message copied.';

  @override
  String get chatEditMessageTitle => 'Edit message';

  @override
  String get chatDeleteMessageTitle => 'Delete message';

  @override
  String get chatDeleteMessageConfirm =>
      'This message will be replaced with a deleted-message placeholder.';

  @override
  String get chatMessageEdited => 'edited';

  @override
  String get chatMessageDeleted => 'Message deleted';

  @override
  String get chatEditNoChanges => 'No changes to save.';

  @override
  String chatEditFailed(Object error) {
    return 'Edit failed: $error';
  }

  @override
  String chatDeleteFailed(Object error) {
    return 'Delete failed: $error';
  }

  @override
  String get chatNoOlderMessages => 'No older messages.';

  @override
  String get chatPartnerLabel => 'Partner';

  @override
  String get chatReplyAction => 'Reply';

  @override
  String get chatMoreReactionsAction => 'More';

  @override
  String get chatAllEmojiAction => 'All emoji';

  @override
  String chatReactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reactions',
      one: '1 reaction',
    );
    return '$_temp0';
  }

  @override
  String chatReplyingTo(Object name) {
    return 'Replying to $name';
  }

  @override
  String get chatReplyMessageFallback => 'Original message';

  @override
  String get chatReplyPhotoFallback => 'Photo';

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
  String get chatRoomMembersTitle => 'Room members';

  @override
  String get chatRoomMembersEmpty => 'No members found.';

  @override
  String chatRoomMembersLoadFailed(Object error) {
    return 'Failed to load room members: $error';
  }

  @override
  String get chatRoomMemberRoleOwner => 'Owner';

  @override
  String get chatRoomMemberYou => 'You';

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
  String get commonBuyMore => 'Buy more';

  @override
  String get commonCamera => 'Camera';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSkip => 'Skip';

  @override
  String get onboardingCreatePetPromptTitle =>
      'Choose a pet to move into your new room!';

  @override
  String get onboardingRoomEntryPromptTitle =>
      'Create a room or enter an invite code.';

  @override
  String get onboardingRoomEntryPromptBody =>
      'Start your pet home by creating a new room, or join one with a code.';

  @override
  String get onboardingProfileSetupTitle => 'Set up your profile';

  @override
  String get onboardingProfileSetupSubtitle =>
      'Choose the name your friends will see. You can add a photo now or later.';

  @override
  String get onboardingProfileSetupAvatarOptional => 'Photo optional';

  @override
  String get onboardingProfileSetupContinue => 'Continue';

  @override
  String get onboardingProfileSetupNameRequiredError =>
      'Enter the name you want to use.';

  @override
  String get onboardingProfileSetupNameChangeHint =>
      'Choose a name before continuing.';

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
  String get photoViewerEmojiAction => 'Emoji';

  @override
  String get photoViewerReplyActionTitle => 'Reply to photo';

  @override
  String get photoViewerReplySendAction => 'Send';

  @override
  String get photoViewerReplySent => 'Reply sent.';

  @override
  String get photoViewerReplySentState => 'Sent';

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
  String get drawerDebugCategorySimulation => 'Simulation & Testing';

  @override
  String get drawerDebugCategoryUser => 'User & Plan';

  @override
  String get drawerDebugCategoryPet => 'Pet Status';

  @override
  String get drawerDebugCategoryMemory => 'Memory Diagnostics';

  @override
  String get drawerDebugCategorySystem => 'Update & System';

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
  String get drawerDebugTestProfileSetupOnboarding => 'Test Profile Setup';

  @override
  String get drawerDebugTestProfileSetupOnboardingSubtitle =>
      'Open the new-user name and photo step now';

  @override
  String get drawerDebugHungerDown => '-10 Pet Hunger';

  @override
  String get drawerDebugAddExp => '+10 EXP';

  @override
  String get drawerDebugSpawnPoop => 'Make Pet Poop';

  @override
  String get drawerDebugShowFullBubble => 'Show \"I\'m Full\" Bubble';

  @override
  String get drawerDebugCaptureMemorySnapshot => 'Capture Memory Snapshot';

  @override
  String get drawerDebugClearImageCacheSnapshot =>
      'Clear Image Cache + Snapshot';

  @override
  String get drawerDebugOpenMemoryDiagnostics => 'Open Memory Diagnostics';

  @override
  String get drawerDebugMemorySnapshotCaptured => 'Memory snapshot captured.';

  @override
  String get drawerDebugImageCacheCleared =>
      'Image cache cleared and snapshot captured.';

  @override
  String get drawerDebugTestSoftUpdate => 'Test Soft Update Prompt';

  @override
  String get drawerDebugTestHardUpdate => 'Test Hard Update Prompt';

  @override
  String get drawerDebugTestWhatsNew => 'Preview What\'s New Modal';

  @override
  String get drawerDebugTestCrashReport => 'Test Crash Report';

  @override
  String get debugMemoryDiagnosticsTitle => 'Memory Diagnostics';

  @override
  String get debugMemoryDiagnosticsEmpty => 'No memory snapshots captured yet.';

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
  String get crashRecoveryAction => 'Got it';

  @override
  String get crashRecoveryMessage =>
      'The game seems to have stopped unexpectedly. Please close the app and open it again. If the problem continues, try again later.';

  @override
  String get crashRecoveryPetCaption => 'Your pet is resting here with you.';

  @override
  String get crashRecoveryPetSemanticLabel => 'Resting pet';

  @override
  String get crashRecoveryTitle => 'Game error';

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
  String get whatsNewDialogTitle => 'Version update';

  @override
  String get whatsNewContinueAction => 'Continue';

  @override
  String get whatsNewContentLabel => 'What\'s new';

  @override
  String get whatsNewHighlightsLabel => 'Highlights in this release';

  @override
  String whatsNewVersionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get whatsNew105Title => 'Stability & Security Update';

  @override
  String get whatsNew105Bullet1 =>
      'Security enhancements for better stability.';

  @override
  String get whatsNew105Bullet2 => 'Minor bug fixes and improvements.';

  @override
  String get whatsNew105Bullet3 => '';

  @override
  String get whatsNew106Title => 'Major Shop Update & Stability';

  @override
  String get whatsNew106Bullet1 => 'Major shop redesign and visual update';

  @override
  String get whatsNew106Bullet2 => 'Improved app stability and performance';

  @override
  String get whatsNew106Bullet3 => 'Fixed several minor known issues';

  @override
  String get whatsNew110Title => 'New Tiger Pet & Furniture Resize';

  @override
  String get whatsNew110Bullet1 =>
      'Meet the new Tiger pet and choose it for your room!';

  @override
  String get whatsNew110Bullet2 =>
      'Beautiful new backgrounds are now available in the Shop.';

  @override
  String get whatsNew110Bullet3 =>
      'Tap a placed furniture item and use the bottom size controls for a precise layout.';

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
  String chatBoughtFurnitureMessage(Object user, Object petName) {
    return '$user bought furniture for $petName.';
  }

  @override
  String chatBoughtBackgroundMessage(Object user, Object petName) {
    return '$user bought a background for $petName.';
  }

  @override
  String chatBoughtStoreItemMessage(
    Object user,
    Object itemName,
    Object petName,
  ) {
    return '$user bought $itemName for $petName.';
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
  String get profileFeedbackEncouragement =>
      'We welcome your ideas and requests. Share what you want to improve, and we\'ll do our best to make it happen.';

  @override
  String get profileFeedback => 'Send Feedback';

  @override
  String get profileVersionPrefix => 'Version: ';

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
  String get profileAvatarEditorHint => 'Drag to position. Pinch to zoom.';

  @override
  String get profileAvatarEditorZoom => 'Zoom';

  @override
  String get profileAvatarEditorCenter => 'Center';

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
  String get roomInviteCopyCodeAction => 'Copy code';

  @override
  String get roomInviteShareAction => 'Share';

  @override
  String get roomInviteShareCaption => 'Join me in Petttomo';

  @override
  String roomInviteShareFailed(Object error) {
    return 'Failed to share invite: $error';
  }

  @override
  String get roomInviteLinkJoining => 'Joining room from invite...';

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
  String get shopEmpty => 'Shop is empty for now.';

  @override
  String get storeIapNotConfigured => 'IAP not configured.';

  @override
  String storeIapUnavailable(Object error) {
    return 'IAP unavailable: $error';
  }

  @override
  String shopLoadFailed(Object error) {
    return 'Failed to load shop: $error';
  }

  @override
  String get storeNotEnoughCoins => 'Not enough candy.';

  @override
  String get storeNotEnoughDiamonds => 'Not enough diamonds.';

  @override
  String storeOwnedCount(Object amount) {
    return 'Owned x$amount';
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
  String get shopReturnToRoomCta => 'Return to room';

  @override
  String get shopReturnToRoomHint =>
      'Return to your pet room to start decorating.';

  @override
  String storeRestoreFailed(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String get storeRestoreTooltip => 'Restore purchases';

  @override
  String get shopSectionCoinPacks => 'Candy Packs';

  @override
  String get shopSectionCoinShop => 'Candy Shop';

  @override
  String get shopSectionDiamondPacks => 'Diamond Packs';

  @override
  String get shopSectionDiamondShop => 'Diamond Shop';

  @override
  String get shopSectionSubscription => 'Subscription';

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
      'Unlimited rooms and no ads for a smoother pet home.';

  @override
  String get storePremiumBenefitUnlimitedRooms => 'Unlimited rooms';

  @override
  String get storePremiumBenefitNoAds => 'No more ads';

  @override
  String get storePremiumBenefitExclusiveItems => 'Exclusive items';

  @override
  String get storeItemNameDiamondPack300 => '300 Diamond Pack';

  @override
  String get storeItemDescDiamondPack300 =>
      'Get 300 diamonds instantly (one-time purchase).';

  @override
  String get storeItemNameCandyPack500 => '500 Candy Pack';

  @override
  String get storeItemDescCandyPack500 => 'Exchange 50 diamonds for 500 candy.';

  @override
  String get storeItemNameReturnLetter => 'Return Letter';

  @override
  String get storeItemDescReturnLetter => 'Call back a departed pet.';

  @override
  String get storeItemNameBackgroundDefault => 'Default Background';

  @override
  String get storeItemDescBackgroundDefault => 'Original cozy room backdrop.';

  @override
  String get storeItemNameBackgroundMoonlight => 'Galaxy Background';

  @override
  String get storeItemDescBackgroundMoonlight => 'A calm galaxy room backdrop.';

  @override
  String get storeItemNameBackgroundSageFrame => 'Sage Frame Background';

  @override
  String get storeItemDescBackgroundSageFrame =>
      'A soft paper-textured room with a playful sage border.';

  @override
  String get storeItemNameBackgroundLilacFrame => 'Lilac Frame Background';

  @override
  String get storeItemDescBackgroundLilacFrame =>
      'A soft paper-textured room with a gentle lilac border.';

  @override
  String get storeItemNameBackgroundBubbleSky => 'Bubble Sky Background';

  @override
  String get storeItemDescBackgroundBubbleSky =>
      'A bright blue sky filled with clouds and iridescent bubbles.';

  @override
  String get storeItemNameBackgroundStarlitDream => 'Starlit Dream Background';

  @override
  String get storeItemDescBackgroundStarlitDream =>
      'A dreamy night sky with pastel planets, clouds, and shooting stars.';

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
  String get storeItemNameFurnitureToilet => 'Toilet';

  @override
  String get storeItemDescFurnitureToilet => 'A clean little bathroom piece.';

  @override
  String get storeItemNameFurnitureTub => 'Tub';

  @override
  String get storeItemDescFurnitureTub => 'A cozy tub for bath time.';

  @override
  String get shopSignInPrompt => 'Please sign in to access the shop.';

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
  String get shopTitle => 'Shop';

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
      'No furniture yet. Buy some in the shop.';

  @override
  String get furnitureInventoryHint =>
      'Long-press furniture to edit. Tap an item to place, drag to move, select placed furniture to resize with the bottom controls. Tap empty space to exit.';

  @override
  String get furnitureScaleLabel => 'Size';

  @override
  String get furnitureScaleDecrease => 'Make smaller';

  @override
  String get furnitureScaleIncrease => 'Make larger';

  @override
  String get furnitureFlipHorizontal => 'Flip horizontally';

  @override
  String furnitureAvailableCount(Object count) {
    return 'Available x$count';
  }

  @override
  String get roomInventoryTitle => 'Room Inventory';

  @override
  String get roomDecorCompatibilityTitle =>
      'Update to see the latest room items';

  @override
  String get roomDecorCompatibilityMessage =>
      'This room is using a newer pet, furniture, or background. Update the app to see the latest shared items instead of fallback visuals.';

  @override
  String get roomDecorHintTitle => 'Decorate room';

  @override
  String roomDecorHintBody(Object buttonLabel) {
    return 'Tap $buttonLabel to enter room edit mode, then place furniture or apply a background.';
  }

  @override
  String get inventoryTabFurniture => 'Furniture';

  @override
  String get backgroundGalleryTab => 'Background Gallery';

  @override
  String get backgroundInventoryEmpty =>
      'No backgrounds yet. Pick one up in the shop.';

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
  String get shopSectionBackgrounds => 'Backgrounds';

  @override
  String get shopSectionItems => 'Items';

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
  String get petTypeTigerName => 'Tiger';

  @override
  String get petTypeTigerTagline =>
      'A striped prowler with a bold little swagger.';

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
      'Visit the Shop and buy a Letter to invite your pet back.';

  @override
  String get petDepartureGuideGoShop => 'Go to Shop';

  @override
  String get petDepartureLetterUnavailableTitle => 'Your pet is still at home';

  @override
  String get petDepartureLetterUnavailableMessage =>
      'Your pet hasn\'t run away, so you don\'t need this letter right now.';

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
  String feedAdDoubleRewardClaimed(Object amount) {
    return 'x2 candy +$amount';
  }

  @override
  String feedAdDoubleRewardFailed(Object error) {
    return 'Double reward failed: $error';
  }

  @override
  String get whatsNew111Title => 'Stability & Performance Update';

  @override
  String get whatsNew111Bullet1 =>
      'Fixed critical issues that could cause unexpected crashes.';

  @override
  String get whatsNew111Bullet2 =>
      'Optimized chat message processing and image rendering.';

  @override
  String get whatsNew111Bullet3 =>
      'Improved overall performance for a smoother experience.';

  @override
  String get whatsNew112Title => 'Room Decor & @Mentions';

  @override
  String get whatsNew112Bullet1 =>
      'Added two new bathroom furniture items: Toilet and Tub.';

  @override
  String get whatsNew112Bullet2 =>
      'You can now flip furniture horizontally to decorate your room more flexibly.';

  @override
  String get whatsNew112Bullet3 =>
      'You can now @mention room members in the chat to grab their attention.';

  @override
  String get whatsNew113Title => 'Operation Experience Upgrade';

  @override
  String get whatsNew113Bullet1 => '📸 Smoother feeding photo sharing';

  @override
  String get whatsNew113Bullet2 => '🔘 Fun button redesign with better feel';

  @override
  String get whatsNew113Bullet3 => '🛍️ Faster and seamless shop purchases';

  @override
  String get whatsNew114Title => 'Bug Fixes';

  @override
  String get whatsNew114Bullet1 =>
      'Fixed a bug that could cause the game to crash.';
}
