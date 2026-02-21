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

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatMessageHint;

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

  /// No description provided for @drawerDebugHungerDown.
  ///
  /// In en, this message translates to:
  /// **'-10 Pet Hunger'**
  String get drawerDebugHungerDown;

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

  /// No description provided for @roomSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a pet home and jump back in.'**
  String get roomSelectionSubtitle;

  /// No description provided for @roomSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Room Selection'**
  String get roomSelectionTitle;

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

  /// No description provided for @storeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Store is empty for now.'**
  String get storeEmpty;

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

  /// No description provided for @storeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load store: {error}'**
  String storeLoadFailed(Object error);

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
  /// **'Owned: {amount}'**
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

  /// No description provided for @storeSectionCoinPacks.
  ///
  /// In en, this message translates to:
  /// **'Candy Packs'**
  String get storeSectionCoinPacks;

  /// No description provided for @storeSectionCoinStore.
  ///
  /// In en, this message translates to:
  /// **'Candy Store'**
  String get storeSectionCoinStore;

  /// No description provided for @storeSectionDiamondPacks.
  ///
  /// In en, this message translates to:
  /// **'Diamond Packs'**
  String get storeSectionDiamondPacks;

  /// No description provided for @storeSectionDiamondStore.
  ///
  /// In en, this message translates to:
  /// **'Diamond Store'**
  String get storeSectionDiamondStore;

  /// No description provided for @storeSectionSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get storeSectionSubscription;

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
  /// **'Monthly Pro subscription with no ads, unlimited rooms, and auto-renewal.'**
  String get storeItemDescProMonthly;

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
  /// **'Moonlight Background'**
  String get storeItemNameBackgroundMoonlight;

  /// No description provided for @storeItemDescBackgroundMoonlight.
  ///
  /// In en, this message translates to:
  /// **'A calm moonlit room backdrop.'**
  String get storeItemDescBackgroundMoonlight;

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

  /// No description provided for @storeSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to access the store.'**
  String get storeSignInPrompt;

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

  /// No description provided for @storeTitle.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get storeTitle;

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
  /// **'No furniture yet. Buy some in the store.'**
  String get furnitureInventoryEmpty;

  /// No description provided for @furnitureInventoryHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press furniture to edit. Tap an item to place, drag to move. Tap empty space to exit.'**
  String get furnitureInventoryHint;

  /// No description provided for @roomInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Room Inventory'**
  String get roomInventoryTitle;

  /// No description provided for @inventoryTabFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get inventoryTabFurniture;

  /// No description provided for @backgroundGalleryTab.
  ///
  /// In en, this message translates to:
  /// **'Background Gallery'**
  String get backgroundGalleryTab;

  /// No description provided for @backgroundInventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backgrounds yet. Pick one up in the store.'**
  String get backgroundInventoryEmpty;

  /// No description provided for @backgroundInventoryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a background to apply it for everyone in the room.'**
  String get backgroundInventoryHint;

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

  /// No description provided for @storeSectionBackgrounds.
  ///
  /// In en, this message translates to:
  /// **'Backgrounds'**
  String get storeSectionBackgrounds;

  /// No description provided for @storeSectionItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get storeSectionItems;

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
  /// **'Visit the Store and buy a Letter to invite your pet back.'**
  String get petDepartureGuideMessage;

  /// No description provided for @petDepartureGuideGoStore.
  ///
  /// In en, this message translates to:
  /// **'Go to Store'**
  String get petDepartureGuideGoStore;

  /// No description provided for @petDepartureLetterUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Letter unavailable'**
  String get petDepartureLetterUnavailableTitle;

  /// No description provided for @petDepartureLetterUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'No pets have left yet.'**
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

  /// No description provided for @feedAdDoubleRewardFailed.
  ///
  /// In en, this message translates to:
  /// **'Double reward failed: {error}'**
  String feedAdDoubleRewardFailed(Object error);
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
