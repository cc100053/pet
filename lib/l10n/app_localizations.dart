import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appleSignInRejected.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in rejected. Check Supabase Apple provider client ID.'**
  String get appleSignInRejected;

  /// No description provided for @authReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get authReauthRequired;

  /// No description provided for @blockedUserIdTruncated.
  ///
  /// In en, this message translates to:
  /// **'ID (truncated): {id}'**
  String blockedUserIdTruncated(Object id);

  /// No description provided for @blockedUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No blocked users yet.'**
  String get blockedUsersEmpty;

  /// No description provided for @blockedUsersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load blocked users: {error}'**
  String blockedUsersLoadFailed(Object error);

  /// No description provided for @blockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsersTitle;

  /// No description provided for @blockedUserUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked.'**
  String get blockedUserUnblocked;

  /// No description provided for @blockedUserUnblockFailed.
  ///
  /// In en, this message translates to:
  /// **'Unblock failed: {error}'**
  String blockedUserUnblockFailed(Object error);

  /// No description provided for @calendarAddMemory.
  ///
  /// In en, this message translates to:
  /// **'Add memory'**
  String get calendarAddMemory;

  /// No description provided for @calendarEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get calendarEarlier;

  /// No description provided for @calendarLatestPhoto.
  ///
  /// In en, this message translates to:
  /// **'Latest photo'**
  String get calendarLatestPhoto;

  /// No description provided for @calendarLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load memories: {error}'**
  String calendarLoadFailed(Object error);

  /// No description provided for @calendarNoEarlierMemories.
  ///
  /// In en, this message translates to:
  /// **'No earlier memories yet.'**
  String get calendarNoEarlierMemories;

  /// No description provided for @calendarNoMemoriesForDay.
  ///
  /// In en, this message translates to:
  /// **'No memories for this day.'**
  String get calendarNoMemoriesForDay;

  /// No description provided for @calendarNoPhotoYet.
  ///
  /// In en, this message translates to:
  /// **'No photo yet'**
  String get calendarNoPhotoYet;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @chatBlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Block failed: {error}'**
  String chatBlockFailed(Object error);

  /// No description provided for @chatBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get chatBlockUser;

  /// No description provided for @chatCoinsAwarded.
  ///
  /// In en, this message translates to:
  /// **'+{count} candy'**
  String chatCoinsAwarded(Object count);

  /// No description provided for @chatEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Start the chat below.'**
  String get chatEmptyState;

  /// No description provided for @chatLoadBlockedUsersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load blocked users: {error}'**
  String chatLoadBlockedUsersFailed(Object error);

  /// No description provided for @chatLoadCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load cached messages: {error}'**
  String chatLoadCacheFailed(Object error);

  /// No description provided for @chatLoadMessagesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages: {error}'**
  String chatLoadMessagesFailed(Object error);

  /// No description provided for @chatLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load more: {error}'**
  String chatLoadMoreFailed(Object error);

  /// No description provided for @chatLoadOlderMessages.
  ///
  /// In en, this message translates to:
  /// **'Load older messages'**
  String get chatLoadOlderMessages;

  /// No description provided for @chatJumpToLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get chatJumpToLatest;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatMessageHint;

  /// No description provided for @chatCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopyAction;

  /// No description provided for @chatEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get chatEditAction;

  /// No description provided for @chatDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatDeleteAction;

  /// No description provided for @chatMessageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied.'**
  String get chatMessageCopied;

  /// No description provided for @chatEditMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get chatEditMessageTitle;

  /// No description provided for @chatDeleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get chatDeleteMessageTitle;

  /// No description provided for @chatDeleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'This message will be replaced with a deleted-message placeholder.'**
  String get chatDeleteMessageConfirm;

  /// No description provided for @chatMessageEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get chatMessageEdited;

  /// No description provided for @chatMessageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get chatMessageDeleted;

  /// No description provided for @chatEditNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes to save.'**
  String get chatEditNoChanges;

  /// No description provided for @chatEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Edit failed: {error}'**
  String chatEditFailed(Object error);

  /// No description provided for @chatDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String chatDeleteFailed(Object error);

  /// No description provided for @chatNoOlderMessages.
  ///
  /// In en, this message translates to:
  /// **'No older messages.'**
  String get chatNoOlderMessages;

  /// No description provided for @chatPartnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get chatPartnerLabel;

  /// No description provided for @chatReplyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReplyAction;

  /// No description provided for @chatMoreReactionsAction.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get chatMoreReactionsAction;

  /// No description provided for @chatAllEmojiAction.
  ///
  /// In en, this message translates to:
  /// **'All emoji'**
  String get chatAllEmojiAction;

  /// No description provided for @chatReactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reaction} other{{count} reactions}}'**
  String chatReactionCount(int count);

  /// No description provided for @chatReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String chatReplyingTo(Object name);

  /// No description provided for @chatReplyMessageFallback.
  ///
  /// In en, this message translates to:
  /// **'Original message'**
  String get chatReplyMessageFallback;

  /// No description provided for @chatReplyPhotoFallback.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatReplyPhotoFallback;

  /// No description provided for @chatRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh: {error}'**
  String chatRefreshFailed(Object error);

  /// No description provided for @chatReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Report failed: {error}'**
  String chatReportFailed(Object error);

  /// No description provided for @chatReportHint.
  ///
  /// In en, this message translates to:
  /// **'Share a quick reason'**
  String get chatReportHint;

  /// No description provided for @chatReportMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get chatReportMessageTitle;

  /// No description provided for @chatReportNoReason.
  ///
  /// In en, this message translates to:
  /// **'No reason'**
  String get chatReportNoReason;

  /// No description provided for @chatReportSent.
  ///
  /// In en, this message translates to:
  /// **'Report submitted.'**
  String get chatReportSent;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String chatSendFailed(Object error);

  /// No description provided for @chatSystemUpdate.
  ///
  /// In en, this message translates to:
  /// **'System update'**
  String get chatSystemUpdate;

  /// No description provided for @chatCandyLabel.
  ///
  /// In en, this message translates to:
  /// **'Candys'**
  String get chatCandyLabel;

  /// System message when a user cleans poop and earns candy.
  ///
  /// In en, this message translates to:
  /// **'{name} cleaned the poop: +{amount} Candys.'**
  String chatCleanPoopMessage(Object name, Object amount);

  /// No description provided for @chatPetHungryReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'{petName} is getting hungry. Time to feed!'**
  String chatPetHungryReminderMessage(Object petName);

  /// No description provided for @chatPetHungryUrgentMessage.
  ///
  /// In en, this message translates to:
  /// **'{petName} is very hungry! Please feed now!'**
  String chatPetHungryUrgentMessage(Object petName);

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatRoomMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Room members'**
  String get chatRoomMembersTitle;

  /// No description provided for @chatRoomMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members found.'**
  String get chatRoomMembersEmpty;

  /// No description provided for @chatRoomMembersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load room members: {error}'**
  String chatRoomMembersLoadFailed(Object error);

  /// No description provided for @chatRoomMemberRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get chatRoomMemberRoleOwner;

  /// No description provided for @chatRoomMemberYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatRoomMemberYou;

  /// No description provided for @chatUserAlreadyBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get chatUserAlreadyBlocked;

  /// No description provided for @chatUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get chatUserBlocked;

  /// No description provided for @chatMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} member} other {{count} members}}'**
  String chatMemberCount(num count);

  /// No description provided for @calendarYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get calendarYesterday;

  /// No description provided for @commonBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get commonBuy;

  /// No description provided for @commonBuyMore.
  ///
  /// In en, this message translates to:
  /// **'Buy more'**
  String get commonBuyMore;

  /// No description provided for @commonCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get commonCamera;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @onboardingCreatePetPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a pet to move into your new room!'**
  String get onboardingCreatePetPromptTitle;

  /// No description provided for @onboardingRoomEntryPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a room or enter an invite code.'**
  String get onboardingRoomEntryPromptTitle;

  /// No description provided for @onboardingRoomEntryPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Start your pet home by creating a new room, or join one with a code.'**
  String get onboardingRoomEntryPromptBody;

  /// No description provided for @onboardingProfileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get onboardingProfileSetupTitle;

  /// No description provided for @onboardingProfileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the name your friends will see. You can add a photo now or later.'**
  String get onboardingProfileSetupSubtitle;

  /// No description provided for @onboardingProfileSetupAvatarOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo optional'**
  String get onboardingProfileSetupAvatarOptional;

  /// No description provided for @onboardingProfileSetupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingProfileSetupContinue;

  /// No description provided for @onboardingProfileSetupNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter the name you want to use.'**
  String get onboardingProfileSetupNameRequiredError;

  /// No description provided for @onboardingProfileSetupNameChangeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a name before continuing.'**
  String get onboardingProfileSetupNameChangeHint;

  /// No description provided for @commonGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get commonGallery;

  /// No description provided for @commonJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get commonJoin;

  /// No description provided for @commonLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get commonLeave;

  /// No description provided for @commonOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get commonOwned;

  /// No description provided for @commonReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get commonReload;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @photoViewerDownloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get photoViewerDownloadTooltip;

  /// No description provided for @photoViewerEmojiAction.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get photoViewerEmojiAction;

  /// No description provided for @photoViewerReplyActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply to photo'**
  String get photoViewerReplyActionTitle;

  /// No description provided for @photoViewerReplySendAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get photoViewerReplySendAction;

  /// No description provided for @photoViewerReplySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent.'**
  String get photoViewerReplySent;

  /// No description provided for @photoViewerReplySentState.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get photoViewerReplySentState;

  /// No description provided for @photoViewerSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to your photo gallery.'**
  String get photoViewerSavedToGallery;

  /// No description provided for @photoViewerSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save photo to your gallery.'**
  String get photoViewerSaveFailed;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @commonSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get commonSending;

  /// No description provided for @commonSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get commonSignOut;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get commonUnblock;

  /// No description provided for @commonUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get commonUploading;

  /// No description provided for @commonUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get commonUser;

  /// No description provided for @errorInvalidInviteCode.
  ///
  /// In en, this message translates to:
  /// **'That invite code is invalid or expired.'**
  String get errorInvalidInviteCode;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Requested data was not found.'**
  String get errorNotFound;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorPermissionDenied;

  /// No description provided for @errorMediaPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera or photo access is off. Please allow it in Settings and try again.'**
  String get errorMediaPermissionDenied;

  /// No description provided for @errorImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. Please choose a smaller image.'**
  String get errorImageTooLarge;

  /// No description provided for @errorPetNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'That pet name is not allowed. Please use a different name.'**
  String get errorPetNameInvalid;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;

  /// No description provided for @currencyJpy.
  ///
  /// In en, this message translates to:
  /// **'JPY {amount}'**
  String currencyJpy(Object amount);

  /// No description provided for @drawerCreateRoom.
  ///
  /// In en, this message translates to:
  /// **'Create New Room'**
  String get drawerCreateRoom;

  /// No description provided for @drawerDebugTools.
  ///
  /// In en, this message translates to:
  /// **'Debug Tools'**
  String get drawerDebugTools;

  /// No description provided for @drawerDebugCategorySimulation.
  ///
  /// In en, this message translates to:
  /// **'Simulation & Testing'**
  String get drawerDebugCategorySimulation;

  /// No description provided for @drawerDebugCategoryUser.
  ///
  /// In en, this message translates to:
  /// **'User & Plan'**
  String get drawerDebugCategoryUser;

  /// No description provided for @drawerDebugCategoryPet.
  ///
  /// In en, this message translates to:
  /// **'Pet Status'**
  String get drawerDebugCategoryPet;

  /// No description provided for @drawerDebugCategoryMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory Diagnostics'**
  String get drawerDebugCategoryMemory;

  /// No description provided for @drawerDebugCategorySystem.
  ///
  /// In en, this message translates to:
  /// **'Update & System'**
  String get drawerDebugCategorySystem;

  /// No description provided for @drawerFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get drawerFreePlan;

  /// No description provided for @drawerProPlan.
  ///
  /// In en, this message translates to:
  /// **'Pro Plan'**
  String get drawerProPlan;

  /// No description provided for @drawerDebugAddCandy.
  ///
  /// In en, this message translates to:
  /// **'+100 Candy'**
  String get drawerDebugAddCandy;

  /// No description provided for @drawerDebugAddDiamonds.
  ///
  /// In en, this message translates to:
  /// **'+100 Diamonds'**
  String get drawerDebugAddDiamonds;

  /// No description provided for @drawerDebugTogglePlan.
  ///
  /// In en, this message translates to:
  /// **'Toggle Plan'**
  String get drawerDebugTogglePlan;

  /// No description provided for @drawerDebugForceOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Always Show Onboarding'**
  String get drawerDebugForceOnboarding;

  /// No description provided for @drawerDebugForceOnboardingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Show on every app open'**
  String get drawerDebugForceOnboardingEnabled;

  /// No description provided for @drawerDebugForceOnboardingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Use normal one-time behavior'**
  String get drawerDebugForceOnboardingDisabled;

  /// No description provided for @drawerDebugTestProfileSetupOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Test Profile Setup'**
  String get drawerDebugTestProfileSetupOnboarding;

  /// No description provided for @drawerDebugTestProfileSetupOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the new-user name and photo step now'**
  String get drawerDebugTestProfileSetupOnboardingSubtitle;

  /// No description provided for @drawerDebugHungerDown.
  ///
  /// In en, this message translates to:
  /// **'-10 Pet Hunger'**
  String get drawerDebugHungerDown;

  /// No description provided for @drawerDebugHungerUp.
  ///
  /// In en, this message translates to:
  /// **'+20 Pet Hunger'**
  String get drawerDebugHungerUp;

  /// No description provided for @drawerDebugAddExp.
  ///
  /// In en, this message translates to:
  /// **'+10 EXP'**
  String get drawerDebugAddExp;

  /// No description provided for @drawerDebugSpawnPoop.
  ///
  /// In en, this message translates to:
  /// **'Make Pet Poop'**
  String get drawerDebugSpawnPoop;

  /// No description provided for @drawerDebugShowFullBubble.
  ///
  /// In en, this message translates to:
  /// **'Show \"I\'m Full\" Bubble'**
  String get drawerDebugShowFullBubble;

  /// No description provided for @drawerDebugShowSocketOverlay.
  ///
  /// In en, this message translates to:
  /// **'Show Socket Overlay'**
  String get drawerDebugShowSocketOverlay;

  /// No description provided for @drawerDebugDressUpFitTool.
  ///
  /// In en, this message translates to:
  /// **'Dress-up Fit Tool'**
  String get drawerDebugDressUpFitTool;

  /// No description provided for @drawerDebugCaptureMemorySnapshot.
  ///
  /// In en, this message translates to:
  /// **'Capture Memory Snapshot'**
  String get drawerDebugCaptureMemorySnapshot;

  /// No description provided for @drawerDebugClearImageCacheSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Clear Image Cache + Snapshot'**
  String get drawerDebugClearImageCacheSnapshot;

  /// No description provided for @drawerDebugOpenMemoryDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Open Memory Diagnostics'**
  String get drawerDebugOpenMemoryDiagnostics;

  /// No description provided for @drawerDebugMemorySnapshotCaptured.
  ///
  /// In en, this message translates to:
  /// **'Memory snapshot captured.'**
  String get drawerDebugMemorySnapshotCaptured;

  /// No description provided for @drawerDebugImageCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Image cache cleared and snapshot captured.'**
  String get drawerDebugImageCacheCleared;

  /// No description provided for @drawerDebugTestSoftUpdate.
  ///
  /// In en, this message translates to:
  /// **'Test Soft Update Prompt'**
  String get drawerDebugTestSoftUpdate;

  /// No description provided for @drawerDebugTestHardUpdate.
  ///
  /// In en, this message translates to:
  /// **'Test Hard Update Prompt'**
  String get drawerDebugTestHardUpdate;

  /// No description provided for @drawerDebugTestWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'Preview What\'s New Modal'**
  String get drawerDebugTestWhatsNew;

  /// No description provided for @drawerDebugTestCrashReport.
  ///
  /// In en, this message translates to:
  /// **'Test Crash Report'**
  String get drawerDebugTestCrashReport;

  /// No description provided for @debugMemoryDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory Diagnostics'**
  String get debugMemoryDiagnosticsTitle;

  /// No description provided for @debugMemoryDiagnosticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No memory snapshots captured yet.'**
  String get debugMemoryDiagnosticsEmpty;

  /// No description provided for @drawerInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String drawerInviteCode(Object code);

  /// No description provided for @drawerJoinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with Invite Code'**
  String get drawerJoinWithCode;

  /// No description provided for @drawerMyRooms.
  ///
  /// In en, this message translates to:
  /// **'My Rooms'**
  String get drawerMyRooms;

  /// No description provided for @drawerNoRooms.
  ///
  /// In en, this message translates to:
  /// **'No rooms yet.'**
  String get drawerNoRooms;

  /// No description provided for @drawerPetError.
  ///
  /// In en, this message translates to:
  /// **'Pet Error'**
  String get drawerPetError;

  /// No description provided for @drawerRegenerateInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Regenerate invite code'**
  String get drawerRegenerateInviteCode;

  /// No description provided for @drawerSimulateFeed.
  ///
  /// In en, this message translates to:
  /// **'Simulate Feed'**
  String get drawerSimulateFeed;

  /// No description provided for @drawerTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Local Notification'**
  String get drawerTestNotification;

  /// No description provided for @feedCameraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture a feed photo and send it.'**
  String get feedCameraSubtitle;

  /// No description provided for @feedCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed Camera'**
  String get feedCameraTitle;

  /// No description provided for @feedPickPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo'**
  String get feedPickPhotoHint;

  /// No description provided for @feedCanonicalTags.
  ///
  /// In en, this message translates to:
  /// **'Canonical tags: {tags}'**
  String feedCanonicalTags(Object tags);

  /// No description provided for @feedCaptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Caption (optional)'**
  String get feedCaptionLabel;

  /// No description provided for @feedDetectedLabels.
  ///
  /// In en, this message translates to:
  /// **'Detected labels'**
  String get feedDetectedLabels;

  /// No description provided for @feedLabelingFailed.
  ///
  /// In en, this message translates to:
  /// **'Labeling failed: {error}'**
  String feedLabelingFailed(Object error);

  /// No description provided for @feedLabelingNotSupported.
  ///
  /// In en, this message translates to:
  /// **'ML Kit image labeling is not supported on web.'**
  String get feedLabelingNotSupported;

  /// No description provided for @feedLabelMappingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load label mappings: {error}'**
  String feedLabelMappingsFailed(Object error);

  /// No description provided for @feedLabelMappingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading label mappings...'**
  String get feedLabelMappingsLoading;

  /// No description provided for @feedLabelMappingsReady.
  ///
  /// In en, this message translates to:
  /// **'Label mappings ready.'**
  String get feedLabelMappingsReady;

  /// No description provided for @feedLabelMappingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Label mappings unavailable.'**
  String get feedLabelMappingsUnavailable;

  /// No description provided for @feedNoLabels.
  ///
  /// In en, this message translates to:
  /// **'No labels detected yet.'**
  String get feedNoLabels;

  /// No description provided for @feedResponse.
  ///
  /// In en, this message translates to:
  /// **'Response: {response}'**
  String feedResponse(Object response);

  /// No description provided for @feedSelectImageFirst.
  ///
  /// In en, this message translates to:
  /// **'Select an image first.'**
  String get feedSelectImageFirst;

  /// No description provided for @feedSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send Feed'**
  String get feedSendButton;

  /// No description provided for @feedSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String feedSendFailed(Object error);

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedTitle;

  /// No description provided for @feedUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Feed upload failed: {error}'**
  String feedUploadFailed(Object error);

  /// No description provided for @feedRecallPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get feedRecallPhotoAction;

  /// No description provided for @feedRecallPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Recall photo'**
  String get feedRecallPhotoTitle;

  /// No description provided for @feedRecallPhotoConfirm.
  ///
  /// In en, this message translates to:
  /// **'This photo will be removed for everyone. Coins and your pet\'s meal are kept.'**
  String get feedRecallPhotoConfirm;

  /// No description provided for @feedRecallPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Recall failed: {error}'**
  String feedRecallPhotoFailed(Object error);

  /// No description provided for @feedRewardPending.
  ///
  /// In en, this message translates to:
  /// **'Reward pending...'**
  String get feedRewardPending;

  /// No description provided for @crashRecoveryAction.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get crashRecoveryAction;

  /// No description provided for @crashRecoveryMessage.
  ///
  /// In en, this message translates to:
  /// **'The game seems to have stopped unexpectedly. Please close the app and open it again. If the problem continues, try again later.'**
  String get crashRecoveryMessage;

  /// No description provided for @crashRecoveryPetCaption.
  ///
  /// In en, this message translates to:
  /// **'Your pet is resting here with you.'**
  String get crashRecoveryPetCaption;

  /// No description provided for @crashRecoveryPetSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Resting pet'**
  String get crashRecoveryPetSemanticLabel;

  /// No description provided for @crashRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Game error'**
  String get crashRecoveryTitle;

  /// No description provided for @forceUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get forceUpdateAction;

  /// No description provided for @forceUpdateLinkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open store link.'**
  String get forceUpdateLinkError;

  /// No description provided for @forceUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A newer version is required to continue. Please update now.'**
  String get forceUpdateMessage;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get forceUpdateTitle;

  /// No description provided for @softUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get softUpdateAction;

  /// No description provided for @softUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get softUpdateLater;

  /// No description provided for @softUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version is available for a smoother co-petting experience.'**
  String get softUpdateMessage;

  /// No description provided for @softUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get softUpdateTitle;

  /// No description provided for @whatsNewDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Version update'**
  String get whatsNewDialogTitle;

  /// No description provided for @whatsNewContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get whatsNewContinueAction;

  /// No description provided for @whatsNewSuggestFeatureAction.
  ///
  /// In en, this message translates to:
  /// **'Suggest a Feature'**
  String get whatsNewSuggestFeatureAction;

  /// No description provided for @whatsNewSuggestFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to see?'**
  String get whatsNewSuggestFeatureTitle;

  /// No description provided for @whatsNewSuggestFeaturePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Describe your idea...'**
  String get whatsNewSuggestFeaturePlaceholder;

  /// No description provided for @whatsNewSuggestFeatureSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get whatsNewSuggestFeatureSubmit;

  /// No description provided for @whatsNewSuggestFeatureSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get whatsNewSuggestFeatureSuccess;

  /// No description provided for @whatsNewContentLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewContentLabel;

  /// No description provided for @whatsNewHighlightsLabel.
  ///
  /// In en, this message translates to:
  /// **'Highlights in this release'**
  String get whatsNewHighlightsLabel;

  /// No description provided for @whatsNewVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String whatsNewVersionLabel(Object version);

  /// No description provided for @whatsNew105Title.
  ///
  /// In en, this message translates to:
  /// **'Stability & Security Update'**
  String get whatsNew105Title;

  /// No description provided for @whatsNew105Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Security enhancements for better stability.'**
  String get whatsNew105Bullet1;

  /// No description provided for @whatsNew105Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Minor bug fixes and improvements.'**
  String get whatsNew105Bullet2;

  /// No description provided for @whatsNew105Bullet3.
  ///
  /// In en, this message translates to:
  /// **''**
  String get whatsNew105Bullet3;

  /// No description provided for @whatsNew106Title.
  ///
  /// In en, this message translates to:
  /// **'Major Shop Update & Stability'**
  String get whatsNew106Title;

  /// No description provided for @whatsNew106Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Major shop redesign and visual update'**
  String get whatsNew106Bullet1;

  /// No description provided for @whatsNew106Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Improved app stability and performance'**
  String get whatsNew106Bullet2;

  /// No description provided for @whatsNew106Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Fixed several minor known issues'**
  String get whatsNew106Bullet3;

  /// No description provided for @whatsNew110Title.
  ///
  /// In en, this message translates to:
  /// **'New Tiger Pet & Furniture Resize'**
  String get whatsNew110Title;

  /// No description provided for @whatsNew110Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Meet the new Tiger pet and choose it for your room!'**
  String get whatsNew110Bullet1;

  /// No description provided for @whatsNew110Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Beautiful new backgrounds are now available in the Shop.'**
  String get whatsNew110Bullet2;

  /// No description provided for @whatsNew110Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Tap a placed furniture item and use the bottom size controls for a precise layout.'**
  String get whatsNew110Bullet3;

  /// No description provided for @languageChineseSimplified.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageChineseSimplified;

  /// No description provided for @languageChineseTraditional.
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get languageChineseTraditional;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageKorean;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow device language'**
  String get languageSystemSubtitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @launchAppName.
  ///
  /// In en, this message translates to:
  /// **'PetTomo'**
  String get launchAppName;

  /// No description provided for @launchTagline.
  ///
  /// In en, this message translates to:
  /// **'Share moments. Grow together.'**
  String get launchTagline;

  /// No description provided for @moodHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get moodHigh;

  /// No description provided for @moodLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get moodLow;

  /// No description provided for @moodMid.
  ///
  /// In en, this message translates to:
  /// **'MID'**
  String get moodMid;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'NEUTRAL'**
  String get moodNeutral;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'SAD'**
  String get moodSad;

  /// No description provided for @petActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed: {error}'**
  String petActionFailed(Object error);

  /// No description provided for @petHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet Home'**
  String get petHomeTitle;

  /// No description provided for @petNameEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit pet name'**
  String get petNameEditTitle;

  /// No description provided for @petNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Pet name'**
  String get petNameLabel;

  /// No description provided for @petNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter pet name'**
  String get petNameHint;

  /// No description provided for @petNameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get petNameEmptyError;

  /// No description provided for @petNameUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update pet name: {error}'**
  String petNameUpdateFailed(Object error);

  /// No description provided for @chatPetRenamedMessage.
  ///
  /// In en, this message translates to:
  /// **'{user} renamed the pet from {oldName} to {petName}.'**
  String chatPetRenamedMessage(Object user, Object oldName, Object petName);

  /// No description provided for @chatBoughtFurnitureMessage.
  ///
  /// In en, this message translates to:
  /// **'{user} bought furniture for {petName}.'**
  String chatBoughtFurnitureMessage(Object user, Object petName);

  /// No description provided for @chatBoughtBackgroundMessage.
  ///
  /// In en, this message translates to:
  /// **'{user} bought a background for {petName}.'**
  String chatBoughtBackgroundMessage(Object user, Object petName);

  /// No description provided for @chatBoughtStoreItemMessage.
  ///
  /// In en, this message translates to:
  /// **'{user} bought {itemName} for {petName}.'**
  String chatBoughtStoreItemMessage(
    Object user,
    Object itemName,
    Object petName,
  );

  /// No description provided for @petNameUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get petNameUnnamed;

  /// No description provided for @petNotFound.
  ///
  /// In en, this message translates to:
  /// **'No pet found.'**
  String get petNotFound;

  /// No description provided for @petSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Pet sync error: {error}'**
  String petSyncFailed(Object error);

  /// No description provided for @photoLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoLabel;

  /// No description provided for @profileDefaultNickname.
  ///
  /// In en, this message translates to:
  /// **'Pet Parent'**
  String get profileDefaultNickname;

  /// No description provided for @profileEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profile available.'**
  String get profileEmpty;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile: {error}'**
  String profileLoadFailed(Object error);

  /// No description provided for @profileNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileNicknameLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About & Support'**
  String get profileSectionAbout;

  /// No description provided for @profileFeedbackEncouragement.
  ///
  /// In en, this message translates to:
  /// **'We welcome your ideas and requests. Share what you want to improve, and we\'ll do our best to make it happen.'**
  String get profileFeedbackEncouragement;

  /// No description provided for @profileFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get profileFeedback;

  /// No description provided for @profileVersionPrefix.
  ///
  /// In en, this message translates to:
  /// **'Version: '**
  String get profileVersionPrefix;

  /// No description provided for @profileSectionDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get profileSectionDangerZone;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an avatar'**
  String get profileAvatarTitle;

  /// No description provided for @profileAvatarEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit avatar'**
  String get profileAvatarEdit;

  /// No description provided for @profileAvatarUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get profileAvatarUpload;

  /// No description provided for @profileAvatarAdjustCurrent.
  ///
  /// In en, this message translates to:
  /// **'Adjust current photo'**
  String get profileAvatarAdjustCurrent;

  /// No description provided for @profileAvatarAdjustUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No uploaded photo to adjust.'**
  String get profileAvatarAdjustUnavailable;

  /// No description provided for @profileAvatarAdjustUnsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Adjusting current photo is not supported on this platform.'**
  String get profileAvatarAdjustUnsupportedPlatform;

  /// No description provided for @profileAvatarEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to position. Pinch to zoom.'**
  String get profileAvatarEditorHint;

  /// No description provided for @profileAvatarEditorZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get profileAvatarEditorZoom;

  /// No description provided for @profileAvatarEditorCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get profileAvatarEditorCenter;

  /// No description provided for @profileAvatarRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get profileAvatarRemove;

  /// No description provided for @profileCoinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Candy: {amount}'**
  String profileCoinsLabel(Object amount);

  /// No description provided for @profileDeleteAccountSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccountSectionTitle;

  /// No description provided for @profileDeleteAccountSectionBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account. Shared rooms and pets stay with other members.'**
  String get profileDeleteAccountSectionBody;

  /// No description provided for @profileDeleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccountAction;

  /// No description provided for @profileDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get profileDeleteAccountTitle;

  /// No description provided for @profileDeleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and personal data. Shared rooms/pets remain and ownership transfers to other members. This cannot be undone.'**
  String get profileDeleteAccountConfirmBody;

  /// No description provided for @profileDeleteAccountConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileDeleteAccountConfirmAction;

  /// No description provided for @profileDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {error}'**
  String profileDeleteFailed(Object error);

  /// No description provided for @profileUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID: {id}'**
  String profileUserId(Object id);

  /// No description provided for @drawerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get drawerProfile;

  /// No description provided for @roomCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Room created! Check the Drawer.'**
  String get roomCreatedSuccess;

  /// No description provided for @roomCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create room: {error}'**
  String roomCreateFailed(Object error);

  /// No description provided for @roomCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get roomCreateTitle;

  /// No description provided for @roomCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get roomCreateAction;

  /// No description provided for @roomNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomNameLabel;

  /// No description provided for @roomNameHint.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomNameHint;

  /// No description provided for @roomNameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a room name.'**
  String get roomNameEmptyError;

  /// No description provided for @roomNameUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update room name: {error}'**
  String roomNameUpdateFailed(Object error);

  /// No description provided for @roomOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Room options'**
  String get roomOptionsTitle;

  /// No description provided for @roomOptionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename room'**
  String get roomOptionRename;

  /// No description provided for @roomOptionLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get roomOptionLeave;

  /// No description provided for @roomRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Change room name'**
  String get roomRenameTitle;

  /// No description provided for @roomRenameMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a new name for this room.'**
  String get roomRenameMessage;

  /// No description provided for @roomDefaultName.
  ///
  /// In en, this message translates to:
  /// **'New Room'**
  String get roomDefaultName;

  /// No description provided for @roomInviteCta.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get roomInviteCta;

  /// No description provided for @roomInventoryCta.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get roomInventoryCta;

  /// No description provided for @roomInvitePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite someone'**
  String get roomInvitePromptTitle;

  /// No description provided for @roomInvitePromptBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re the only one here. Generate a code to invite someone.'**
  String get roomInvitePromptBody;

  /// No description provided for @roomInvitePromptAction.
  ///
  /// In en, this message translates to:
  /// **'Generate code'**
  String get roomInvitePromptAction;

  /// No description provided for @roomInvitePromptGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get roomInvitePromptGenerating;

  /// No description provided for @roomInviteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get roomInviteCodeTitle;

  /// No description provided for @roomInviteCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Share this code to invite someone to your room.'**
  String get roomInviteCodeMessage;

  /// No description provided for @roomInviteCodeTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the code to copy it.'**
  String get roomInviteCodeTapHint;

  /// No description provided for @roomInviteCopyCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get roomInviteCopyCodeAction;

  /// No description provided for @roomInviteShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get roomInviteShareAction;

  /// No description provided for @roomInviteShareCaption.
  ///
  /// In en, this message translates to:
  /// **'Join me in PetTomo'**
  String get roomInviteShareCaption;

  /// No description provided for @roomInviteShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share invite: {error}'**
  String roomInviteShareFailed(Object error);

  /// No description provided for @roomInviteLinkJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining room from invite...'**
  String get roomInviteLinkJoining;

  /// No description provided for @roomInviteCodeCopiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get roomInviteCodeCopiedTitle;

  /// No description provided for @roomInviteCodeCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Invite friends now and raise your pet together!'**
  String get roomInviteCodeCopiedMessage;

  /// No description provided for @roomInviteCodeRegenerated.
  ///
  /// In en, this message translates to:
  /// **'Invite code regenerated.'**
  String get roomInviteCodeRegenerated;

  /// No description provided for @roomInviteCodeRegenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to regenerate code: {error}'**
  String roomInviteCodeRegenerateFailed(Object error);

  /// No description provided for @roomJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to join room: {error}'**
  String roomJoinFailed(Object error);

  /// No description provided for @roomJoinHelper.
  ///
  /// In en, this message translates to:
  /// **'Invite codes are case-insensitive.'**
  String get roomJoinHelper;

  /// No description provided for @roomJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get roomJoinHint;

  /// No description provided for @roomJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined room successfully.'**
  String get roomJoinSuccess;

  /// No description provided for @roomJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Room'**
  String get roomJoinTitle;

  /// No description provided for @roomEnteringLoading.
  ///
  /// In en, this message translates to:
  /// **'Entering room'**
  String get roomEnteringLoading;

  /// No description provided for @roomLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave room: {error}'**
  String roomLeaveFailed(Object error);

  /// Confirmation message when leaving a room.
  ///
  /// In en, this message translates to:
  /// **'You\'ll leave {name} and lose access to its chat and pet.'**
  String roomLeaveMessage(Object name);

  /// No description provided for @roomLeaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Left the room.'**
  String get roomLeaveSuccess;

  /// No description provided for @roomLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave room?'**
  String get roomLeaveTitle;

  /// No description provided for @roomLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Free limit reached (2 rooms max). Upgrade to create more!'**
  String get roomLimitReached;

  /// No description provided for @roomNewInviteCode.
  ///
  /// In en, this message translates to:
  /// **'New invite code: {code}'**
  String roomNewInviteCode(Object code);

  /// No description provided for @roomSelectionCreatePet.
  ///
  /// In en, this message translates to:
  /// **'Create New Room'**
  String get roomSelectionCreatePet;

  /// No description provided for @roomSelectionCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get roomSelectionCreating;

  /// No description provided for @roomSelectionEmptySlot.
  ///
  /// In en, this message translates to:
  /// **'Empty slot'**
  String get roomSelectionEmptySlot;

  /// No description provided for @roomSelectionEnterInvite.
  ///
  /// In en, this message translates to:
  /// **'Enter Invite Code'**
  String get roomSelectionEnterInvite;

  /// No description provided for @roomSelectionJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining...'**
  String get roomSelectionJoining;

  /// No description provided for @roomSelectionRoomFallback.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomSelectionRoomFallback;

  /// No description provided for @roomSelectionStatusHungry.
  ///
  /// In en, this message translates to:
  /// **'Hungry'**
  String get roomSelectionStatusHungry;

  /// No description provided for @roomSelectionStatusNewPhoto.
  ///
  /// In en, this message translates to:
  /// **'New photo'**
  String get roomSelectionStatusNewPhoto;

  /// No description provided for @roomSelectionStatusNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get roomSelectionStatusNoPhoto;

  /// No description provided for @roomSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a pet home and jump back in.'**
  String get roomSelectionSubtitle;

  /// No description provided for @roomSelectionSubtitleFrames.
  ///
  /// In en, this message translates to:
  /// **'Pick a pet home and jump back in. Long-press a card to change its frame.'**
  String get roomSelectionSubtitleFrames;

  /// No description provided for @roomSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Room Selection'**
  String get roomSelectionTitle;

  /// No description provided for @roomFrameSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Frame'**
  String get roomFrameSheetTitle;

  /// No description provided for @roomFrameSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{petName}\'s room'**
  String roomFrameSheetSubtitle(Object petName);

  /// No description provided for @roomFrameStylePolaroidClassic.
  ///
  /// In en, this message translates to:
  /// **'Polaroid · Classic'**
  String get roomFrameStylePolaroidClassic;

  /// No description provided for @roomFrameStyleCorkboard.
  ///
  /// In en, this message translates to:
  /// **'Polaroid · Corkboard'**
  String get roomFrameStyleCorkboard;

  /// No description provided for @roomFrameStyleGoldLeaf.
  ///
  /// In en, this message translates to:
  /// **'Collector · Gold Leaf'**
  String get roomFrameStyleGoldLeaf;

  /// No description provided for @roomFrameStyleNightGlow.
  ///
  /// In en, this message translates to:
  /// **'Collector · Night Glow'**
  String get roomFrameStyleNightGlow;

  /// No description provided for @roomFrameStyleOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get roomFrameStyleOriginal;

  /// No description provided for @roomFrameLongPressHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press a card to change its frame'**
  String get roomFrameLongPressHint;

  /// No description provided for @roomFrameLockedLevel.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String roomFrameLockedLevel(int level);

  /// No description provided for @roomFrameLockedLevelHint.
  ///
  /// In en, this message translates to:
  /// **'{frameName} unlocks at room Lv {level}.'**
  String roomFrameLockedLevelHint(Object frameName, int level);

  /// No description provided for @roomFrameInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get roomFrameInUse;

  /// No description provided for @roomFrameOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get roomFrameOwned;

  /// No description provided for @roomFrameConfirm.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get roomFrameConfirm;

  /// No description provided for @roomFrameChanged.
  ///
  /// In en, this message translates to:
  /// **'Frame changed to {frameName}.'**
  String roomFrameChanged(Object frameName);

  /// No description provided for @roomFrameChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Change frame'**
  String get roomFrameChangeAction;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get signInFailed;

  /// No description provided for @signInNote.
  ///
  /// In en, this message translates to:
  /// **'Note: OAuth providers must be configured in Supabase.'**
  String get signInNote;

  /// No description provided for @signInOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening sign-in...'**
  String get signInOpening;

  /// No description provided for @signInOpeningProvider.
  ///
  /// In en, this message translates to:
  /// **'Opening {provider}...'**
  String signInOpeningProvider(Object provider);

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to start co-raising your pet.'**
  String get signInSubtitle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get signInWithApple;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @storeCoinPrice.
  ///
  /// In en, this message translates to:
  /// **'Candy: {amount}'**
  String storeCoinPrice(Object amount);

  /// No description provided for @storeCoinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Candy: {amount}'**
  String storeCoinsLabel(Object amount);

  /// No description provided for @storeCoinsReward.
  ///
  /// In en, this message translates to:
  /// **'Candy +{amount}'**
  String storeCoinsReward(Object amount);

  /// No description provided for @storeDiamondsLabel.
  ///
  /// In en, this message translates to:
  /// **'Diamonds: {amount}'**
  String storeDiamondsLabel(Object amount);

  /// No description provided for @storeDiamondsReward.
  ///
  /// In en, this message translates to:
  /// **'Diamonds +{amount}'**
  String storeDiamondsReward(Object amount);

  /// No description provided for @shopEmpty.
  ///
  /// In en, this message translates to:
  /// **'Shop is empty for now.'**
  String get shopEmpty;

  /// No description provided for @storeIapNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'IAP not configured.'**
  String get storeIapNotConfigured;

  /// No description provided for @storeIapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'IAP unavailable: {error}'**
  String storeIapUnavailable(Object error);

  /// No description provided for @shopLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load shop: {error}'**
  String shopLoadFailed(Object error);

  /// No description provided for @storeNotEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough candy.'**
  String get storeNotEnoughCoins;

  /// No description provided for @storeNotEnoughDiamonds.
  ///
  /// In en, this message translates to:
  /// **'Not enough diamonds.'**
  String get storeNotEnoughDiamonds;

  /// No description provided for @storeOwnedCount.
  ///
  /// In en, this message translates to:
  /// **'Owned x{amount}'**
  String storeOwnedCount(Object amount);

  /// No description provided for @storePriceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Price unavailable'**
  String get storePriceUnavailable;

  /// No description provided for @storeProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found in RevenueCat.'**
  String get storeProductNotFound;

  /// No description provided for @storeProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Product unavailable.'**
  String get storeProductUnavailable;

  /// No description provided for @storePurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {error}'**
  String storePurchaseFailed(Object error);

  /// No description provided for @storePurchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchased {name}.'**
  String storePurchaseSuccess(Object name);

  /// No description provided for @shopReturnToRoomCta.
  ///
  /// In en, this message translates to:
  /// **'Return to room'**
  String get shopReturnToRoomCta;

  /// No description provided for @shopReturnToRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Return to your pet room to start decorating.'**
  String get shopReturnToRoomHint;

  /// No description provided for @storeRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String storeRestoreFailed(Object error);

  /// No description provided for @storeRestoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get storeRestoreTooltip;

  /// No description provided for @shopSectionCoinPacks.
  ///
  /// In en, this message translates to:
  /// **'Candy Packs'**
  String get shopSectionCoinPacks;

  /// No description provided for @shopSectionCoinShop.
  ///
  /// In en, this message translates to:
  /// **'Candy Shop'**
  String get shopSectionCoinShop;

  /// No description provided for @shopSectionDiamondPacks.
  ///
  /// In en, this message translates to:
  /// **'Diamond Packs'**
  String get shopSectionDiamondPacks;

  /// No description provided for @shopSectionDiamondShop.
  ///
  /// In en, this message translates to:
  /// **'Diamond Shop'**
  String get shopSectionDiamondShop;

  /// No description provided for @shopSectionSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get shopSectionSubscription;

  /// No description provided for @storeTabPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get storeTabPremium;

  /// No description provided for @storeTabFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get storeTabFurniture;

  /// No description provided for @storeTabThemes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get storeTabThemes;

  /// No description provided for @storeThemePreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get storeThemePreviewAction;

  /// No description provided for @storeThemePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Preview'**
  String storeThemePreviewTitle(Object name);

  /// No description provided for @storeItemNameProMonthly.
  ///
  /// In en, this message translates to:
  /// **'Pro Monthly Membership'**
  String get storeItemNameProMonthly;

  /// No description provided for @storeItemDescProMonthly.
  ///
  /// In en, this message translates to:
  /// **'Unlimited rooms and no ads for a smoother pet home.'**
  String get storeItemDescProMonthly;

  /// No description provided for @storePremiumBenefitUnlimitedRooms.
  ///
  /// In en, this message translates to:
  /// **'Unlimited rooms'**
  String get storePremiumBenefitUnlimitedRooms;

  /// No description provided for @storePremiumBenefitNoAds.
  ///
  /// In en, this message translates to:
  /// **'No more ads'**
  String get storePremiumBenefitNoAds;

  /// No description provided for @storePremiumBenefitExclusiveItems.
  ///
  /// In en, this message translates to:
  /// **'Exclusive items'**
  String get storePremiumBenefitExclusiveItems;

  /// No description provided for @storeItemNameDiamondPack300.
  ///
  /// In en, this message translates to:
  /// **'300 Diamond Pack'**
  String get storeItemNameDiamondPack300;

  /// No description provided for @storeItemDescDiamondPack300.
  ///
  /// In en, this message translates to:
  /// **'Get 300 diamonds instantly (one-time purchase).'**
  String get storeItemDescDiamondPack300;

  /// No description provided for @storeItemNameCandyPack500.
  ///
  /// In en, this message translates to:
  /// **'500 Candy Pack'**
  String get storeItemNameCandyPack500;

  /// No description provided for @storeItemDescCandyPack500.
  ///
  /// In en, this message translates to:
  /// **'Exchange 50 diamonds for 500 candy.'**
  String get storeItemDescCandyPack500;

  /// No description provided for @storeItemNameReturnLetter.
  ///
  /// In en, this message translates to:
  /// **'Return Letter'**
  String get storeItemNameReturnLetter;

  /// No description provided for @storeItemDescReturnLetter.
  ///
  /// In en, this message translates to:
  /// **'Call back a departed pet.'**
  String get storeItemDescReturnLetter;

  /// No description provided for @storeItemNamePetTicket.
  ///
  /// In en, this message translates to:
  /// **'Pet Ticket'**
  String get storeItemNamePetTicket;

  /// No description provided for @storeItemDescPetTicket.
  ///
  /// In en, this message translates to:
  /// **'Invite another pet to this room.'**
  String get storeItemDescPetTicket;

  /// No description provided for @storeItemNameBackgroundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default Background'**
  String get storeItemNameBackgroundDefault;

  /// No description provided for @storeItemDescBackgroundDefault.
  ///
  /// In en, this message translates to:
  /// **'Original cozy room backdrop.'**
  String get storeItemDescBackgroundDefault;

  /// No description provided for @storeItemNameBackgroundMoonlight.
  ///
  /// In en, this message translates to:
  /// **'Galaxy Background'**
  String get storeItemNameBackgroundMoonlight;

  /// No description provided for @storeItemDescBackgroundMoonlight.
  ///
  /// In en, this message translates to:
  /// **'A calm galaxy room backdrop.'**
  String get storeItemDescBackgroundMoonlight;

  /// No description provided for @storeItemNameBackgroundSageFrame.
  ///
  /// In en, this message translates to:
  /// **'Sage Frame Background'**
  String get storeItemNameBackgroundSageFrame;

  /// No description provided for @storeItemDescBackgroundSageFrame.
  ///
  /// In en, this message translates to:
  /// **'A soft paper-textured room with a playful sage border.'**
  String get storeItemDescBackgroundSageFrame;

  /// No description provided for @storeItemNameBackgroundLilacFrame.
  ///
  /// In en, this message translates to:
  /// **'Lilac Frame Background'**
  String get storeItemNameBackgroundLilacFrame;

  /// No description provided for @storeItemDescBackgroundLilacFrame.
  ///
  /// In en, this message translates to:
  /// **'A soft paper-textured room with a gentle lilac border.'**
  String get storeItemDescBackgroundLilacFrame;

  /// No description provided for @storeItemNameBackgroundBubbleSky.
  ///
  /// In en, this message translates to:
  /// **'Bubble Sky Background'**
  String get storeItemNameBackgroundBubbleSky;

  /// No description provided for @storeItemDescBackgroundBubbleSky.
  ///
  /// In en, this message translates to:
  /// **'A bright blue sky filled with clouds and iridescent bubbles.'**
  String get storeItemDescBackgroundBubbleSky;

  /// No description provided for @storeItemNameBackgroundStarlitDream.
  ///
  /// In en, this message translates to:
  /// **'Starlit Dream Background'**
  String get storeItemNameBackgroundStarlitDream;

  /// No description provided for @storeItemDescBackgroundStarlitDream.
  ///
  /// In en, this message translates to:
  /// **'A dreamy night sky with pastel planets, clouds, and shooting stars.'**
  String get storeItemDescBackgroundStarlitDream;

  /// No description provided for @storeItemNameFurnitureSofa.
  ///
  /// In en, this message translates to:
  /// **'Sofa'**
  String get storeItemNameFurnitureSofa;

  /// No description provided for @storeItemDescFurnitureSofa.
  ///
  /// In en, this message translates to:
  /// **'Comfy sofa.'**
  String get storeItemDescFurnitureSofa;

  /// No description provided for @storeItemNameFurniturePlant.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get storeItemNameFurniturePlant;

  /// No description provided for @storeItemDescFurniturePlant.
  ///
  /// In en, this message translates to:
  /// **'Fresh green corner.'**
  String get storeItemDescFurniturePlant;

  /// No description provided for @storeItemNameFurnitureFrame.
  ///
  /// In en, this message translates to:
  /// **'Picture Frame'**
  String get storeItemNameFurnitureFrame;

  /// No description provided for @storeItemDescFurnitureFrame.
  ///
  /// In en, this message translates to:
  /// **'Picture frame.'**
  String get storeItemDescFurnitureFrame;

  /// No description provided for @storeItemNameFurnitureTeddy.
  ///
  /// In en, this message translates to:
  /// **'Teddy Bear'**
  String get storeItemNameFurnitureTeddy;

  /// No description provided for @storeItemDescFurnitureTeddy.
  ///
  /// In en, this message translates to:
  /// **'Soft teddy.'**
  String get storeItemDescFurnitureTeddy;

  /// No description provided for @storeItemNameFurnitureBricks.
  ///
  /// In en, this message translates to:
  /// **'Bricks'**
  String get storeItemNameFurnitureBricks;

  /// No description provided for @storeItemDescFurnitureBricks.
  ///
  /// In en, this message translates to:
  /// **'Block accent.'**
  String get storeItemDescFurnitureBricks;

  /// No description provided for @storeItemNameFurnitureTv.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get storeItemNameFurnitureTv;

  /// No description provided for @storeItemDescFurnitureTv.
  ///
  /// In en, this message translates to:
  /// **'Tiny TV.'**
  String get storeItemDescFurnitureTv;

  /// No description provided for @storeItemNameFurnitureBath.
  ///
  /// In en, this message translates to:
  /// **'Bath'**
  String get storeItemNameFurnitureBath;

  /// No description provided for @storeItemDescFurnitureBath.
  ///
  /// In en, this message translates to:
  /// **'Mini bath.'**
  String get storeItemDescFurnitureBath;

  /// No description provided for @storeItemNameFurnitureRibbon.
  ///
  /// In en, this message translates to:
  /// **'Ribbon'**
  String get storeItemNameFurnitureRibbon;

  /// No description provided for @storeItemDescFurnitureRibbon.
  ///
  /// In en, this message translates to:
  /// **'Decor ribbon.'**
  String get storeItemDescFurnitureRibbon;

  /// No description provided for @storeItemNameFurnitureToilet.
  ///
  /// In en, this message translates to:
  /// **'Toilet'**
  String get storeItemNameFurnitureToilet;

  /// No description provided for @storeItemDescFurnitureToilet.
  ///
  /// In en, this message translates to:
  /// **'A clean little bathroom piece.'**
  String get storeItemDescFurnitureToilet;

  /// No description provided for @storeItemNameFurnitureTub.
  ///
  /// In en, this message translates to:
  /// **'Tub'**
  String get storeItemNameFurnitureTub;

  /// No description provided for @storeItemDescFurnitureTub.
  ///
  /// In en, this message translates to:
  /// **'A cozy tub for bath time.'**
  String get storeItemDescFurnitureTub;

  /// No description provided for @storeItemNameFurnitureBalloon.
  ///
  /// In en, this message translates to:
  /// **'Balloons'**
  String get storeItemNameFurnitureBalloon;

  /// No description provided for @storeItemDescFurnitureBalloon.
  ///
  /// In en, this message translates to:
  /// **'A ribbon-tied balloon bunch.'**
  String get storeItemDescFurnitureBalloon;

  /// No description provided for @storeItemNameFurnitureCactus.
  ///
  /// In en, this message translates to:
  /// **'Cactus'**
  String get storeItemNameFurnitureCactus;

  /// No description provided for @storeItemDescFurnitureCactus.
  ///
  /// In en, this message translates to:
  /// **'A potted cactus in bloom.'**
  String get storeItemDescFurnitureCactus;

  /// No description provided for @storeItemNameFurnitureCarpet.
  ///
  /// In en, this message translates to:
  /// **'Rug'**
  String get storeItemNameFurnitureCarpet;

  /// No description provided for @storeItemDescFurnitureCarpet.
  ///
  /// In en, this message translates to:
  /// **'A flower-patterned oval rug.'**
  String get storeItemDescFurnitureCarpet;

  /// No description provided for @storeItemNameFurnitureVinyl.
  ///
  /// In en, this message translates to:
  /// **'Vinyl Records'**
  String get storeItemNameFurnitureVinyl;

  /// No description provided for @storeItemDescFurnitureVinyl.
  ///
  /// In en, this message translates to:
  /// **'Records for a music corner.'**
  String get storeItemDescFurnitureVinyl;

  /// No description provided for @storeItemNameEquipmentStrawHat.
  ///
  /// In en, this message translates to:
  /// **'Straw Hat'**
  String get storeItemNameEquipmentStrawHat;

  /// No description provided for @storeItemNameEquipmentCrown.
  ///
  /// In en, this message translates to:
  /// **'Crown'**
  String get storeItemNameEquipmentCrown;

  /// No description provided for @storeItemNameEquipmentSunglasses.
  ///
  /// In en, this message translates to:
  /// **'Sunglasses'**
  String get storeItemNameEquipmentSunglasses;

  /// No description provided for @storeItemNameEquipmentRibbon.
  ///
  /// In en, this message translates to:
  /// **'Ribbon'**
  String get storeItemNameEquipmentRibbon;

  /// No description provided for @shopSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to access the shop.'**
  String get shopSignInPrompt;

  /// No description provided for @storeSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get storeSubscribe;

  /// No description provided for @storeSubscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get storeSubscriptionActive;

  /// No description provided for @storeSubscriptionDurationMonthly.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get storeSubscriptionDurationMonthly;

  /// No description provided for @storeSubscriptionRenewalNote.
  ///
  /// In en, this message translates to:
  /// **'Auto-renews monthly. Cancel anytime.'**
  String get storeSubscriptionRenewalNote;

  /// No description provided for @storeSubscriptionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription details'**
  String get storeSubscriptionDetailsTitle;

  /// No description provided for @storeSubscriptionDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Title: {title}\nLength: {duration}\nPrice: {price}'**
  String storeSubscriptionDetailsBody(
    Object title,
    Object duration,
    Object price,
  );

  /// No description provided for @storePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get storePrivacyPolicy;

  /// No description provided for @storeTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get storeTermsOfUse;

  /// No description provided for @storeLegalSeparator.
  ///
  /// In en, this message translates to:
  /// **'|'**
  String get storeLegalSeparator;

  /// No description provided for @storeLegalOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the legal link.'**
  String get storeLegalOpenFailed;

  /// No description provided for @signInSafetyAgreementLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Use and Privacy Policy, including zero tolerance for objectionable content or abusive users.'**
  String get signInSafetyAgreementLabel;

  /// No description provided for @signInSafetyAgreementRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Use and Privacy Policy before signing in.'**
  String get signInSafetyAgreementRequired;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @storeTypeConsumable.
  ///
  /// In en, this message translates to:
  /// **'Consumable'**
  String get storeTypeConsumable;

  /// No description provided for @storeTypeCosmetic.
  ///
  /// In en, this message translates to:
  /// **'Cosmetic'**
  String get storeTypeCosmetic;

  /// No description provided for @storeTypeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get storeTypeSubscription;

  /// No description provided for @furnitureInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Room Inventory'**
  String get furnitureInventoryTitle;

  /// No description provided for @furnitureInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage furniture and backgrounds for this room.'**
  String get furnitureInventorySubtitle;

  /// No description provided for @furnitureInventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No furniture yet. Buy some in the shop.'**
  String get furnitureInventoryEmpty;

  /// No description provided for @furnitureInventoryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap furniture to place it. Select placed furniture to move, resize, or flip.'**
  String get furnitureInventoryHint;

  /// No description provided for @furnitureScaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get furnitureScaleLabel;

  /// No description provided for @furnitureScaleDecrease.
  ///
  /// In en, this message translates to:
  /// **'Make smaller'**
  String get furnitureScaleDecrease;

  /// No description provided for @furnitureScaleIncrease.
  ///
  /// In en, this message translates to:
  /// **'Make larger'**
  String get furnitureScaleIncrease;

  /// No description provided for @furnitureFlipHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Flip horizontally'**
  String get furnitureFlipHorizontal;

  /// No description provided for @furnitureAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'Available x{count}'**
  String furnitureAvailableCount(Object count);

  /// No description provided for @roomInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Room Inventory'**
  String get roomInventoryTitle;

  /// No description provided for @roomDecorCompatibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Update to see the latest room items'**
  String get roomDecorCompatibilityTitle;

  /// No description provided for @roomDecorCompatibilityMessage.
  ///
  /// In en, this message translates to:
  /// **'This room is using a newer pet, furniture, or background. Update the app to see the latest shared items instead of fallback visuals.'**
  String get roomDecorCompatibilityMessage;

  /// No description provided for @roomDecorHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Decorate room'**
  String get roomDecorHintTitle;

  /// No description provided for @roomDecorHintBody.
  ///
  /// In en, this message translates to:
  /// **'Tap {buttonLabel} to enter room edit mode, then place furniture or apply a background.'**
  String roomDecorHintBody(Object buttonLabel);

  /// No description provided for @inventoryTabFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get inventoryTabFurniture;

  /// No description provided for @inventoryTabEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get inventoryTabEquipment;

  /// No description provided for @backgroundGalleryTab.
  ///
  /// In en, this message translates to:
  /// **'Background Gallery'**
  String get backgroundGalleryTab;

  /// No description provided for @backgroundInventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backgrounds yet. Pick one up in the shop.'**
  String get backgroundInventoryEmpty;

  /// No description provided for @backgroundInventoryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a background to apply it for everyone in the room.'**
  String get backgroundInventoryHint;

  /// No description provided for @equipmentInventoryHint.
  ///
  /// In en, this message translates to:
  /// **'Preview outfits here, then equip or remove items on the shared pet.'**
  String get equipmentInventoryHint;

  /// No description provided for @equipmentNoneOwned.
  ///
  /// In en, this message translates to:
  /// **'You don\'t own any items for this slot yet.'**
  String get equipmentNoneOwned;

  /// No description provided for @equipmentCopyInUse.
  ///
  /// In en, this message translates to:
  /// **'On another pet'**
  String get equipmentCopyInUse;

  /// No description provided for @equipmentCopyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Every copy of this item is already worn by another pet. Buy another to dress up more than one pet.'**
  String get equipmentCopyUnavailable;

  /// No description provided for @equipmentNotCompatible.
  ///
  /// In en, this message translates to:
  /// **'This equipment isn\'t compatible with this pet.'**
  String get equipmentNotCompatible;

  /// No description provided for @equipmentSlotHead.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get equipmentSlotHead;

  /// No description provided for @equipmentSlotFace.
  ///
  /// In en, this message translates to:
  /// **'Face'**
  String get equipmentSlotFace;

  /// No description provided for @equipmentSlotBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get equipmentSlotBody;

  /// No description provided for @equipmentSlotBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get equipmentSlotBack;

  /// No description provided for @equipmentEquipCta.
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get equipmentEquipCta;

  /// No description provided for @equipmentUnequipCta.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get equipmentUnequipCta;

  /// No description provided for @equipmentEquipSuccess.
  ///
  /// In en, this message translates to:
  /// **'Equipped {itemName}!'**
  String equipmentEquipSuccess(Object itemName);

  /// No description provided for @equipmentUnequipSuccess.
  ///
  /// In en, this message translates to:
  /// **'Removed equipment from {slotName}.'**
  String equipmentUnequipSuccess(Object slotName);

  /// No description provided for @backgroundApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get backgroundApply;

  /// No description provided for @backgroundAppliedLabel.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get backgroundAppliedLabel;

  /// No description provided for @backgroundApplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply background: {error}'**
  String backgroundApplyFailed(Object error);

  /// No description provided for @shopSectionBackgrounds.
  ///
  /// In en, this message translates to:
  /// **'Backgrounds'**
  String get shopSectionBackgrounds;

  /// No description provided for @shopSectionEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get shopSectionEquipment;

  /// No description provided for @shopSectionItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get shopSectionItems;

  /// No description provided for @storeBackgroundRoomRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a room before purchasing a background.'**
  String get storeBackgroundRoomRequired;

  /// No description provided for @storeBuyWithCandies.
  ///
  /// In en, this message translates to:
  /// **'Buy {price} Candy'**
  String storeBuyWithCandies(Object price);

  /// No description provided for @storeBuyWithDiamonds.
  ///
  /// In en, this message translates to:
  /// **'Buy {price} Diamonds'**
  String storeBuyWithDiamonds(Object price);

  /// No description provided for @furnitureEditMode.
  ///
  /// In en, this message translates to:
  /// **'Furniture Mode'**
  String get furnitureEditMode;

  /// No description provided for @petSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your pet'**
  String get petSelectionTitle;

  /// No description provided for @petSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a buddy to start this room.'**
  String get petSelectionSubtitle;

  /// No description provided for @petSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a pet to continue.'**
  String get petSelectionHint;

  /// Label that shows the currently selected pet.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String petSelectionSelected(Object name);

  /// No description provided for @petSelectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start room'**
  String get petSelectionConfirm;

  /// No description provided for @petTicketUseCta.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get petTicketUseCta;

  /// No description provided for @petTicketSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a pet'**
  String get petTicketSelectionTitle;

  /// No description provided for @petTicketSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new buddy to join this room.'**
  String get petTicketSelectionSubtitle;

  /// No description provided for @petTicketSelectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Invite pet'**
  String get petTicketSelectionConfirm;

  /// Success message after using a pet ticket.
  ///
  /// In en, this message translates to:
  /// **'{petName} joined the room!'**
  String petTicketUseSuccess(Object petName);

  /// No description provided for @petTicketRoomFull.
  ///
  /// In en, this message translates to:
  /// **'This room already has the maximum number of pets.'**
  String get petTicketRoomFull;

  /// No description provided for @multiPetNamingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome the new family!'**
  String get multiPetNamingTitle;

  /// No description provided for @multiPetNamingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Give your home a fresh name, and confirm what to call your first pet.'**
  String get multiPetNamingSubtitle;

  /// No description provided for @multiPetNamingRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get multiPetNamingRoomLabel;

  /// No description provided for @multiPetNamingFirstPetLabel.
  ///
  /// In en, this message translates to:
  /// **'First pet name'**
  String get multiPetNamingFirstPetLabel;

  /// No description provided for @multiPetNamingFirstPetHint.
  ///
  /// In en, this message translates to:
  /// **'Inherits your old room name by default'**
  String get multiPetNamingFirstPetHint;

  /// No description provided for @mainPetSwitcherTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your main pet'**
  String get mainPetSwitcherTitle;

  /// No description provided for @equipTargetPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Equip on which pet?'**
  String get equipTargetPickerTitle;

  /// Subtitle showing the SKU a pet currently wears in this slot.
  ///
  /// In en, this message translates to:
  /// **'Currently wearing: {sku}'**
  String equipTargetPickerCurrentlyWearing(Object sku);

  /// No description provided for @petSelectionStarterBadge.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get petSelectionStarterBadge;

  /// Error message when applying selected pet fails.
  ///
  /// In en, this message translates to:
  /// **'Pet selection failed: {error}'**
  String petSelectionFailed(Object error);

  /// No description provided for @petTypeGhostName.
  ///
  /// In en, this message translates to:
  /// **'Ghost'**
  String get petTypeGhostName;

  /// No description provided for @petTypeGhostTagline.
  ///
  /// In en, this message translates to:
  /// **'A shy floater who loves snacks.'**
  String get petTypeGhostTagline;

  /// No description provided for @petTypeCatName.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get petTypeCatName;

  /// No description provided for @petTypeCatTagline.
  ///
  /// In en, this message translates to:
  /// **'A curious pouncer with a warm purr.'**
  String get petTypeCatTagline;

  /// No description provided for @petTypeFishName.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get petTypeFishName;

  /// No description provided for @petTypeFishTagline.
  ///
  /// In en, this message translates to:
  /// **'A bubbly swimmer who loves to glide.'**
  String get petTypeFishTagline;

  /// No description provided for @petTypeTigerName.
  ///
  /// In en, this message translates to:
  /// **'Tiger'**
  String get petTypeTigerName;

  /// No description provided for @petTypeTigerTagline.
  ///
  /// In en, this message translates to:
  /// **'A striped prowler with a bold little swagger.'**
  String get petTypeTigerTagline;

  /// No description provided for @petTypeChickenName.
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get petTypeChickenName;

  /// No description provided for @petTypeChickenTagline.
  ///
  /// In en, this message translates to:
  /// **'A feathery friend with a lively little strut.'**
  String get petTypeChickenTagline;

  /// No description provided for @roomLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get roomLeaveConfirm;

  /// No description provided for @roomLockedBadge.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get roomLockedBadge;

  /// No description provided for @roomLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Room locked on Free plan'**
  String get roomLockedTitle;

  /// No description provided for @roomLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Only your first 2 rooms stay active on Free. Upgrade to Pro to feed and grow pets in this room.'**
  String get roomLockedMessage;

  /// No description provided for @petDepartureNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'Why treat me like this...'**
  String get petDepartureNoteMessage;

  /// No description provided for @petDepartureGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Letter from your pet'**
  String get petDepartureGuideTitle;

  /// No description provided for @petDepartureGuideMessage.
  ///
  /// In en, this message translates to:
  /// **'Visit the Shop and buy a Letter to invite your pet back.'**
  String get petDepartureGuideMessage;

  /// No description provided for @petDepartureGuideGoShop.
  ///
  /// In en, this message translates to:
  /// **'Go to Shop'**
  String get petDepartureGuideGoShop;

  /// No description provided for @petDepartureLetterUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pet is still at home'**
  String get petDepartureLetterUnavailableTitle;

  /// No description provided for @petDepartureLetterUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Your pet hasn\'t run away, so you don\'t need this letter right now.'**
  String get petDepartureLetterUnavailableMessage;

  /// No description provided for @petDepartureLetterSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a pet'**
  String get petDepartureLetterSelectTitle;

  /// No description provided for @petDepartureLetterSelectMessage.
  ///
  /// In en, this message translates to:
  /// **'Which pet should the letter call back?'**
  String get petDepartureLetterSelectMessage;

  /// No description provided for @petDepartureLetterConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Call {petName} back?'**
  String petDepartureLetterConfirmTitle(Object petName);

  /// No description provided for @petDepartureLetterConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Buy a Letter to invite {petName} back home.'**
  String petDepartureLetterConfirmMessage(Object petName);

  /// No description provided for @petDepartureLetterConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Buy Letter'**
  String get petDepartureLetterConfirmAction;

  /// No description provided for @petDepartureFeedDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'No pet to feed'**
  String get petDepartureFeedDisabledTitle;

  /// No description provided for @petDepartureFeedDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Your pet has left, so there’s no one to feed right now.'**
  String get petDepartureFeedDisabledMessage;

  /// No description provided for @petOverfedBubble.
  ///
  /// In en, this message translates to:
  /// **'I\'m full!'**
  String get petOverfedBubble;

  /// No description provided for @petNameUnknown.
  ///
  /// In en, this message translates to:
  /// **'Your pet'**
  String get petNameUnknown;

  /// No description provided for @roomNameUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown room'**
  String get roomNameUnknown;

  /// No description provided for @petReturnFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to return pet: {error}'**
  String petReturnFailed(Object error);

  /// No description provided for @storeAdRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for candies'**
  String get storeAdRewardTitle;

  /// No description provided for @storeAdRewardDescription.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad and claim +{amount} candies.'**
  String storeAdRewardDescription(Object amount);

  /// No description provided for @storeAdRewardAction.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get storeAdRewardAction;

  /// No description provided for @storeAdRewardLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get storeAdRewardLoading;

  /// No description provided for @storeAdRewardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ad unavailable'**
  String get storeAdRewardUnavailable;

  /// No description provided for @storeAdRewardDismissed.
  ///
  /// In en, this message translates to:
  /// **'Ad closed before reward.'**
  String get storeAdRewardDismissed;

  /// No description provided for @storeAdRewardCooldown.
  ///
  /// In en, this message translates to:
  /// **'Ad reward is on cooldown right now.'**
  String get storeAdRewardCooldown;

  /// No description provided for @storeAdRewardRoomRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a room first to claim ad rewards.'**
  String get storeAdRewardRoomRequired;

  /// No description provided for @storeAdRewardFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to claim ad reward: {error}'**
  String storeAdRewardFailed(Object error);

  /// No description provided for @feedAdDoubleRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Double your feed reward?'**
  String get feedAdDoubleRewardTitle;

  /// No description provided for @feedAdDoubleRewardMessage.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad for +{amount} extra candies?'**
  String feedAdDoubleRewardMessage(Object amount);

  /// No description provided for @feedAdDoubleRewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'x2 candy +{amount}'**
  String feedAdDoubleRewardClaimed(Object amount);

  /// No description provided for @feedAdDoubleRewardFailed.
  ///
  /// In en, this message translates to:
  /// **'Double reward failed: {error}'**
  String feedAdDoubleRewardFailed(Object error);

  /// No description provided for @whatsNew111Title.
  ///
  /// In en, this message translates to:
  /// **'Stability & Performance Update'**
  String get whatsNew111Title;

  /// No description provided for @whatsNew111Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Fixed critical issues that could cause unexpected crashes.'**
  String get whatsNew111Bullet1;

  /// No description provided for @whatsNew111Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Optimized chat message processing and image rendering.'**
  String get whatsNew111Bullet2;

  /// No description provided for @whatsNew111Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Improved overall performance for a smoother experience.'**
  String get whatsNew111Bullet3;

  /// No description provided for @whatsNew112Title.
  ///
  /// In en, this message translates to:
  /// **'Room Decor & @Mentions'**
  String get whatsNew112Title;

  /// No description provided for @whatsNew112Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Added two new bathroom furniture items: Toilet and Tub.'**
  String get whatsNew112Bullet1;

  /// No description provided for @whatsNew112Bullet2.
  ///
  /// In en, this message translates to:
  /// **'You can now flip furniture horizontally to decorate your room more flexibly.'**
  String get whatsNew112Bullet2;

  /// No description provided for @whatsNew112Bullet3.
  ///
  /// In en, this message translates to:
  /// **'You can now @mention room members in the chat to grab their attention.'**
  String get whatsNew112Bullet3;

  /// No description provided for @whatsNew113Title.
  ///
  /// In en, this message translates to:
  /// **'Operation Experience Upgrade'**
  String get whatsNew113Title;

  /// No description provided for @whatsNew113Bullet1.
  ///
  /// In en, this message translates to:
  /// **'📸 Smoother feeding photo sharing'**
  String get whatsNew113Bullet1;

  /// No description provided for @whatsNew113Bullet2.
  ///
  /// In en, this message translates to:
  /// **'🔘 Fun button redesign with better feel'**
  String get whatsNew113Bullet2;

  /// No description provided for @whatsNew113Bullet3.
  ///
  /// In en, this message translates to:
  /// **'🛍️ Faster and seamless shop purchases'**
  String get whatsNew113Bullet3;

  /// No description provided for @whatsNew114Title.
  ///
  /// In en, this message translates to:
  /// **'Bug Fixes'**
  String get whatsNew114Title;

  /// No description provided for @whatsNew114Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Fixed a bug that could cause the game to crash.'**
  String get whatsNew114Bullet1;

  /// No description provided for @whatsNew120Title.
  ///
  /// In en, this message translates to:
  /// **'Chat & Sharing Upgrades'**
  String get whatsNew120Title;

  /// No description provided for @whatsNew120Bullet1.
  ///
  /// In en, this message translates to:
  /// **'✏️ Edit or delete your messages in the chat room'**
  String get whatsNew120Bullet1;

  /// No description provided for @whatsNew120Bullet2.
  ///
  /// In en, this message translates to:
  /// **'🔗 Improved invite link sharing — more reliable, fewer errors'**
  String get whatsNew120Bullet2;

  /// No description provided for @whatsNew120Bullet3.
  ///
  /// In en, this message translates to:
  /// **'💡 New Feature Request: share your ideas directly from the app'**
  String get whatsNew120Bullet3;

  /// No description provided for @whatsNew130Title.
  ///
  /// In en, this message translates to:
  /// **'Pet Dress-Up Arrives'**
  String get whatsNew130Title;

  /// No description provided for @whatsNew130Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Dress up your pet with new equipment.'**
  String get whatsNew130Bullet1;

  /// No description provided for @whatsNew130Bullet2.
  ///
  /// In en, this message translates to:
  /// **'The straw hat is now available in the Shop.'**
  String get whatsNew130Bullet2;

  /// No description provided for @whatsNew130Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Pet previews and room inventory are smoother and clearer.'**
  String get whatsNew130Bullet3;

  /// No description provided for @whatsNew140Title.
  ///
  /// In en, this message translates to:
  /// **'More Pet Style'**
  String get whatsNew140Title;

  /// No description provided for @whatsNew140Bullet1.
  ///
  /// In en, this message translates to:
  /// **'New Crown, Sunglasses, and Ribbon equipment is available in the Shop.'**
  String get whatsNew140Bullet1;

  /// No description provided for @whatsNew140Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Equipment previews now fit each pet more naturally.'**
  String get whatsNew140Bullet2;

  /// No description provided for @whatsNew140Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Shared room, inventory, and shop displays are clearer.'**
  String get whatsNew140Bullet3;

  /// No description provided for @whatsNew200Title.
  ///
  /// In en, this message translates to:
  /// **'Raise more pets together'**
  String get whatsNew200Title;

  /// No description provided for @whatsNew200Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Add extra pets to your shared room with pet tickets.'**
  String get whatsNew200Bullet1;

  /// No description provided for @whatsNew200Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Switch your main pet anytime.'**
  String get whatsNew200Bullet2;

  /// No description provided for @whatsNew200Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Dress up each pet separately.'**
  String get whatsNew200Bullet3;

  /// No description provided for @whatsNew201Title.
  ///
  /// In en, this message translates to:
  /// **'Smoother sharing'**
  String get whatsNew201Title;

  /// No description provided for @whatsNew201Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Recall sent feed photos.'**
  String get whatsNew201Bullet1;

  /// No description provided for @whatsNew201Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Smoother avatar and photo display.'**
  String get whatsNew201Bullet2;

  /// No description provided for @whatsNew201Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Stability fixes and polish.'**
  String get whatsNew201Bullet3;

  /// No description provided for @whatsNew202Title.
  ///
  /// In en, this message translates to:
  /// **'Bug Fixes'**
  String get whatsNew202Title;

  /// No description provided for @whatsNew202Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Fixed bugs and improved stability.'**
  String get whatsNew202Bullet1;

  /// No description provided for @whatsNew210Title.
  ///
  /// In en, this message translates to:
  /// **'Furniture feels better'**
  String get whatsNew210Title;

  /// No description provided for @whatsNew210Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Furniture placement now stays more consistent across devices.'**
  String get whatsNew210Bullet1;

  /// No description provided for @whatsNew210Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Room inventory is easier to use on shorter screens.'**
  String get whatsNew210Bullet2;

  /// No description provided for @whatsNew210Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Pet care timing and overall stability have been improved.'**
  String get whatsNew210Bullet3;

  /// No description provided for @whatsNew220Title.
  ///
  /// In en, this message translates to:
  /// **'Photo sharing feels smoother'**
  String get whatsNew220Title;

  /// No description provided for @whatsNew220Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Feeding photos is prepared for a faster upload flow.'**
  String get whatsNew220Bullet1;

  /// No description provided for @whatsNew220Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Shared rooms load latest photos and member counts more efficiently.'**
  String get whatsNew220Bullet2;

  /// No description provided for @whatsNew220Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Feed, avatar, and notification reliability has been improved.'**
  String get whatsNew220Bullet3;

  /// No description provided for @whatsNew221Title.
  ///
  /// In en, this message translates to:
  /// **'Feeding feedback is clearer'**
  String get whatsNew221Title;

  /// No description provided for @whatsNew221Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Hunger refreshes before photo feeds so changes feel easier to understand.'**
  String get whatsNew221Bullet1;

  /// No description provided for @whatsNew221Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Photo feeding handles refresh hiccups more reliably.'**
  String get whatsNew221Bullet2;

  /// No description provided for @whatsNew221Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Shared pet feeding feels smoother and steadier.'**
  String get whatsNew221Bullet3;

  /// No description provided for @whatsNew222Title.
  ///
  /// In en, this message translates to:
  /// **'Bug fixes'**
  String get whatsNew222Title;

  /// No description provided for @whatsNew222Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Hunger now stays in sync after slower photo feeds.'**
  String get whatsNew222Bullet1;

  /// No description provided for @whatsNew222Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Shared pet feeding results update more reliably.'**
  String get whatsNew222Bullet2;

  /// No description provided for @whatsNew222Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Small stability fixes keep pet care smoother.'**
  String get whatsNew222Bullet3;

  /// No description provided for @whatsNew223Title.
  ///
  /// In en, this message translates to:
  /// **'Small bug fixes'**
  String get whatsNew223Title;

  /// No description provided for @whatsNew223Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Fixed minor bugs to improve the shared pet care experience.'**
  String get whatsNew223Bullet1;

  /// No description provided for @whatsNew223Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Small stability improvements keep everyday pet care smoother.'**
  String get whatsNew223Bullet2;

  /// No description provided for @whatsNew224Title.
  ///
  /// In en, this message translates to:
  /// **'Bug fix'**
  String get whatsNew224Title;

  /// No description provided for @whatsNew224Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Fixed a feed-related issue that could cause a crash after uploading a pet photo.'**
  String get whatsNew224Bullet1;

  /// No description provided for @whatsNew224Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Improved stability when returning from feed and chat flows.'**
  String get whatsNew224Bullet2;

  /// No description provided for @whatsNew225Title.
  ///
  /// In en, this message translates to:
  /// **'Bug fix'**
  String get whatsNew225Title;

  /// No description provided for @whatsNew225Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Fixed a crash that could occur while setting up notifications on iOS.'**
  String get whatsNew225Bullet1;

  /// No description provided for @whatsNew226Title.
  ///
  /// In en, this message translates to:
  /// **'Fresher pet status'**
  String get whatsNew226Title;

  /// No description provided for @whatsNew226Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Pet status now stays accurate and consistent between room selection and Pet Home.'**
  String get whatsNew226Bullet1;

  /// No description provided for @whatsNew230Title.
  ///
  /// In en, this message translates to:
  /// **'Meet Chicken!'**
  String get whatsNew230Title;

  /// No description provided for @whatsNew230Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Chicken, a lively new pet, has joined PetTomo.'**
  String get whatsNew230Bullet1;

  /// No description provided for @whatsNew230Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Temporary connection issues are now less likely to interrupt your shared care experience.'**
  String get whatsNew230Bullet2;

  /// No description provided for @whatsNew240Title.
  ///
  /// In en, this message translates to:
  /// **'New Room Decor!'**
  String get whatsNew240Title;

  /// No description provided for @whatsNew240Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Four new furniture pieces have joined the shop: balloons, a potted cactus, a flower rug, and vinyl records.'**
  String get whatsNew240Bullet1;

  /// No description provided for @whatsNew240Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Decorate your shared room with these fresh new styles.'**
  String get whatsNew240Bullet2;

  /// No description provided for @whatsNew234Title.
  ///
  /// In en, this message translates to:
  /// **'Bug Fixes & Improvements'**
  String get whatsNew234Title;

  /// No description provided for @whatsNew234Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Fixed a performance issue that could slow down pet updates.'**
  String get whatsNew234Bullet1;

  /// No description provided for @whatsNew234Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Fixed an issue where declining photo access could show an unexpected error.'**
  String get whatsNew234Bullet2;

  /// No description provided for @whatsNew233Title.
  ///
  /// In en, this message translates to:
  /// **'Bug Fixes & Improvements'**
  String get whatsNew233Title;

  /// No description provided for @whatsNew233Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Fixed an issue where a sender\'s name could go missing in group chat conversations.'**
  String get whatsNew233Bullet1;

  /// No description provided for @whatsNew233Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Improved chat display reliability.'**
  String get whatsNew233Bullet2;

  /// No description provided for @whatsNew232Title.
  ///
  /// In en, this message translates to:
  /// **'Bug Fixes & Improvements'**
  String get whatsNew232Title;

  /// No description provided for @whatsNew232Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Fixed minor bugs to improve app stability.'**
  String get whatsNew232Bullet1;

  /// No description provided for @whatsNew232Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Improved reliability for a smoother everyday experience.'**
  String get whatsNew232Bullet2;

  /// No description provided for @whatsNew231Title.
  ///
  /// In en, this message translates to:
  /// **'Bug Fixes & Stability'**
  String get whatsNew231Title;

  /// No description provided for @whatsNew231Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Fixed minor bugs affecting shared pet care.'**
  String get whatsNew231Bullet1;

  /// No description provided for @whatsNew231Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Improved app stability for a smoother everyday experience.'**
  String get whatsNew231Bullet2;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
