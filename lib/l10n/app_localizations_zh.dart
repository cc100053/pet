// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appleSignInRejected =>
      'Apple 登入被拒絕，請檢查 Supabase Apple 供應商的 Client ID。';

  @override
  String get authReauthRequired => '請重新登入。';

  @override
  String blockedUserIdTruncated(Object id) {
    return 'ID（縮略）：$id';
  }

  @override
  String get blockedUsersEmpty => '目前沒有封鎖的用戶。';

  @override
  String blockedUsersLoadFailed(Object error) {
    return '載入封鎖名單失敗：$error';
  }

  @override
  String get blockedUsersTitle => '已封鎖的用戶';

  @override
  String get blockedUserUnblocked => '已解除封鎖。';

  @override
  String blockedUserUnblockFailed(Object error) {
    return '解除封鎖失敗：$error';
  }

  @override
  String get calendarAddMemory => '新增回憶';

  @override
  String get calendarEarlier => '較早';

  @override
  String get calendarLatestPhoto => '最新的照片';

  @override
  String calendarLoadFailed(Object error) {
    return '載入回憶失敗：$error';
  }

  @override
  String get calendarNoEarlierMemories => '暫無較早的回憶。';

  @override
  String get calendarNoMemoriesForDay => '這天沒有回憶。';

  @override
  String get calendarNoPhotoYet => '尚無照片';

  @override
  String get calendarTitle => '回憶錄';

  @override
  String get calendarToday => '今天';

  @override
  String chatBlockFailed(Object error) {
    return '封鎖失敗：$error';
  }

  @override
  String get chatBlockUser => '封鎖用戶';

  @override
  String chatCoinsAwarded(Object count) {
    return '+$count 金幣';
  }

  @override
  String get chatEmptyState => '尚無訊息，從下方開始聊天吧。';

  @override
  String chatLoadBlockedUsersFailed(Object error) {
    return '載入封鎖名單失敗：$error';
  }

  @override
  String chatLoadCacheFailed(Object error) {
    return '載入快取訊息失敗：$error';
  }

  @override
  String chatLoadMessagesFailed(Object error) {
    return '載入訊息失敗：$error';
  }

  @override
  String chatLoadMoreFailed(Object error) {
    return '載入更多失敗：$error';
  }

  @override
  String get chatLoadOlderMessages => '載入更早的訊息';

  @override
  String get chatMessageHint => '訊息';

  @override
  String get chatNoOlderMessages => '沒有更早的訊息。';

  @override
  String get chatPartnerLabel => '對方';

  @override
  String chatRefreshFailed(Object error) {
    return '更新失敗：$error';
  }

  @override
  String chatReportFailed(Object error) {
    return '檢舉失敗：$error';
  }

  @override
  String get chatReportHint => '簡單說明原因';

  @override
  String get chatReportMessageTitle => '檢舉訊息';

  @override
  String get chatReportNoReason => '無原因';

  @override
  String get chatReportSent => '已送出檢舉。';

  @override
  String chatSendFailed(Object error) {
    return '傳送失敗：$error';
  }

  @override
  String get chatSystemUpdate => '系統通知';

  @override
  String get chatTitle => '聊天';

  @override
  String get chatUserAlreadyBlocked => '已封鎖';

  @override
  String get chatUserBlocked => '已封鎖用戶。';

  @override
  String get commonBuy => '購買';

  @override
  String get commonCamera => '相機';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '關閉';

  @override
  String get commonGallery => '相簿';

  @override
  String get commonJoin => '加入';

  @override
  String get commonLeave => '離開';

  @override
  String get commonOwned => '已擁有';

  @override
  String get commonReload => '重新載入';

  @override
  String get commonSave => '儲存';

  @override
  String get commonSend => '送出';

  @override
  String get commonSending => '送出中...';

  @override
  String get commonSignOut => '登出';

  @override
  String get commonSubmit => '送出';

  @override
  String get commonTryAgain => '再試一次';

  @override
  String get commonUnblock => '解除封鎖';

  @override
  String get commonUploading => '上傳中';

  @override
  String get commonUser => '用戶';

  @override
  String currencyJpy(Object amount) {
    return 'JPY $amount';
  }

  @override
  String get drawerCreateRoom => '建立新房間';

  @override
  String get drawerDebugTools => '除錯工具';

  @override
  String get drawerForceRefreshPet => '強制更新寵物';

  @override
  String get drawerFreePlan => '免費方案';

  @override
  String drawerInviteCode(Object code) {
    return '代碼：$code';
  }

  @override
  String get drawerJoinWithCode => '使用邀請碼加入';

  @override
  String get drawerMyRooms => '我的房間';

  @override
  String get drawerNoRooms => '目前沒有房間。';

  @override
  String get drawerPetError => '寵物錯誤';

  @override
  String get drawerRegenerateInviteCode => '重新產生邀請碼';

  @override
  String get drawerSimulateFeed => '模擬餵食';

  @override
  String get drawerTestNotification => '測試本地通知';

  @override
  String get feedCameraSubtitle => '拍照並檢查標籤後再送出。';

  @override
  String get feedCameraTitle => '餵食相機';

  @override
  String feedCanonicalTags(Object tags) {
    return '標準標籤：$tags';
  }

  @override
  String get feedCaptionLabel => '說明（選填）';

  @override
  String get feedDetectedLabels => '偵測到的標籤';

  @override
  String feedLabelingFailed(Object error) {
    return '標註失敗：$error';
  }

  @override
  String get feedLabelingNotSupported => 'Web 不支援 ML Kit 影像標註。';

  @override
  String feedLabelMappingsFailed(Object error) {
    return '載入標籤對應失敗：$error';
  }

  @override
  String get feedLabelMappingsLoading => '載入標籤對應中...';

  @override
  String get feedLabelMappingsReady => '標籤對應已就緒。';

  @override
  String get feedLabelMappingsUnavailable => '無法使用標籤對應。';

  @override
  String get feedNoLabels => '尚未偵測到標籤。';

  @override
  String feedResponse(Object response) {
    return '回應：$response';
  }

  @override
  String get feedSelectImageFirst => '請先選擇圖片。';

  @override
  String get feedSendButton => '送出餵食';

  @override
  String feedSendFailed(Object error) {
    return '送出失敗：$error';
  }

  @override
  String get feedTitle => '餵食';

  @override
  String feedUploadFailed(Object error) {
    return '餵食上傳失敗：$error';
  }

  @override
  String get forceUpdateAction => '立即更新';

  @override
  String get forceUpdateLinkError => '無法開啟商店連結。';

  @override
  String get forceUpdateMessage => '需要更新到新版本才能繼續使用，請立即更新。';

  @override
  String get forceUpdateTitle => '需要更新';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get languageEnglish => '英文';

  @override
  String get languageJapanese => '日文';

  @override
  String get languageSystem => '系統';

  @override
  String get languageSystemSubtitle => '跟隨裝置語言';

  @override
  String get languageTitle => '語言';

  @override
  String get launchTagline => '分享日常，一起成長。';

  @override
  String get moodHigh => '高';

  @override
  String get moodLow => '低';

  @override
  String get moodMid => '中';

  @override
  String get moodNeutral => '普通';

  @override
  String get moodSad => '難過';

  @override
  String petActionFailed(Object error) {
    return '操作失敗：$error';
  }

  @override
  String get petHomeTitle => '寵物的家';

  @override
  String get petNotFound => '找不到寵物。';

  @override
  String petSyncFailed(Object error) {
    return '寵物同步錯誤：$error';
  }

  @override
  String get photoLabel => '照片';

  @override
  String get profileDefaultNickname => '寵物爸媽';

  @override
  String get profileEmpty => '沒有個人檔案。';

  @override
  String profileLoadFailed(Object error) {
    return '載入個人檔案失敗：$error';
  }

  @override
  String get profileNicknameLabel => '暱稱';

  @override
  String get profileTitle => '個人檔案';

  @override
  String get profileUpdated => '已更新個人檔案';

  @override
  String get profileAvatarTitle => '選擇頭像';

  @override
  String get profileAvatarEdit => '編輯頭像';

  @override
  String get profileAvatarUpload => '上傳照片';

  @override
  String get profileAvatarRemove => '移除';

  @override
  String profileCoinsLabel(Object amount) {
    return '金幣：$amount';
  }

  @override
  String get profileDeleteAccountSectionTitle => '刪除帳號';

  @override
  String get profileDeleteAccountSectionBody =>
      '此操作會永久刪除你的帳號。共養房間與寵物會保留並轉移給其他成員。';

  @override
  String get profileDeleteAccountAction => '刪除帳號';

  @override
  String get profileDeleteAccountTitle => '要刪除帳號嗎？';

  @override
  String get profileDeleteAccountConfirmBody =>
      '此操作會永久刪除你的帳號與個人資料。共養房間／寵物會保留並將所有權轉移給其他成員。此操作無法復原。';

  @override
  String get profileDeleteAccountConfirmAction => '刪除';

  @override
  String profileDeleteFailed(Object error) {
    return '刪除帳號失敗：$error';
  }

  @override
  String profileUserId(Object id) {
    return '使用者 ID：$id';
  }

  @override
  String get drawerProfile => '個人檔案';

  @override
  String get roomCreatedSuccess => '已建立房間！請查看側邊欄。';

  @override
  String roomCreateFailed(Object error) {
    return '建立房間失敗：$error';
  }

  @override
  String get roomDefaultName => '新房間';

  @override
  String get roomInviteCodeRegenerated => '邀請碼已重新產生。';

  @override
  String roomInviteCodeRegenerateFailed(Object error) {
    return '重新產生邀請碼失敗：$error';
  }

  @override
  String roomJoinFailed(Object error) {
    return '加入房間失敗：$error';
  }

  @override
  String get roomJoinHelper => '邀請碼不區分大小寫。';

  @override
  String get roomJoinHint => '輸入 6 位邀請碼';

  @override
  String get roomJoinSuccess => '加入房間成功。';

  @override
  String get roomJoinTitle => '加入房間';

  @override
  String roomLeaveFailed(Object error) {
    return '離開房間失敗：$error';
  }

  @override
  String get roomLeaveMessage => '離開後在重新邀請前將無法存取這隻寵物。';

  @override
  String get roomLeaveSuccess => '已離開房間。';

  @override
  String get roomLeaveTitle => '離開房間？';

  @override
  String get roomLimitReached => '已達免費上限（最多 2 個房間）。升級以新增更多！';

  @override
  String roomNewInviteCode(Object code) {
    return '新的邀請碼：$code';
  }

  @override
  String get roomSelectionCreatePet => '建立新寵物';

  @override
  String get roomSelectionCreating => '建立中...';

  @override
  String get roomSelectionEmptySlot => '空位';

  @override
  String get roomSelectionEnterInvite => '輸入邀請碼';

  @override
  String get roomSelectionJoining => '加入中...';

  @override
  String get roomSelectionRoomFallback => '房間';

  @override
  String get roomSelectionSubtitle => '選擇寵物的家並繼續。';

  @override
  String get roomSelectionTitle => '房間選擇';

  @override
  String get signInFailed => '登入失敗，請再試一次。';

  @override
  String get signInNote => '注意：需要在 Supabase 設定 OAuth 供應商。';

  @override
  String get signInOpening => '正在開啟登入...';

  @override
  String signInOpeningProvider(Object provider) {
    return '正在開啟 $provider...';
  }

  @override
  String get signInSubtitle => '登入後開始一起養成寵物。';

  @override
  String get signInWithApple => '使用 Apple 繼續';

  @override
  String get signInWithGoogle => '使用 Google 繼續';

  @override
  String storeCoinPrice(Object amount) {
    return '金幣：$amount';
  }

  @override
  String storeCoinsLabel(Object amount) {
    return '金幣：$amount';
  }

  @override
  String storeCoinsReward(Object amount) {
    return '金幣 +$amount';
  }

  @override
  String get storeEmpty => '商店目前沒有商品。';

  @override
  String get storeIapNotConfigured => '尚未設定 IAP。';

  @override
  String storeIapUnavailable(Object error) {
    return 'IAP 無法使用：$error';
  }

  @override
  String storeLoadFailed(Object error) {
    return '載入商店失敗：$error';
  }

  @override
  String get storeNotEnoughCoins => '金幣不足。';

  @override
  String storeOwnedCount(Object amount) {
    return '已擁有：$amount';
  }

  @override
  String get storePriceUnavailable => '價格不可用';

  @override
  String get storeProductNotFound => '在 RevenueCat 找不到商品。';

  @override
  String get storeProductUnavailable => '商品不可用。';

  @override
  String storePurchaseFailed(Object error) {
    return '購買失敗：$error';
  }

  @override
  String storePurchaseSuccess(Object name) {
    return '已購買 $name。';
  }

  @override
  String storeRestoreFailed(Object error) {
    return '復原失敗：$error';
  }

  @override
  String get storeRestoreTooltip => '恢復購買';

  @override
  String get storeSectionCoinPacks => '金幣包';

  @override
  String get storeSectionCoinStore => '金幣商店';

  @override
  String get storeSectionSubscription => '訂閱';

  @override
  String get storeSignInPrompt => '請先登入才能使用商店。';

  @override
  String get storeSubscribe => '訂閱';

  @override
  String get storeSubscriptionActive => '已啟用';

  @override
  String get storeTitle => '商店';

  @override
  String get storeTypeConsumable => '消耗品';

  @override
  String get storeTypeCosmetic => '外觀';

  @override
  String get storeTypeSubscription => '訂閱';

  @override
  String get furnitureInventoryTitle => '家具';

  @override
  String get furnitureInventorySubtitle => '把家具放進寵物家裡。';

  @override
  String get furnitureInventoryEmpty => '目前沒有家具，去商店買一些吧。';

  @override
  String get furnitureInventoryHint => '長按家具可編輯，點擊道具放置，拖曳移動，點空白退出。';

  @override
  String get furnitureEditMode => '家具模式';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appleSignInRejected =>
      'Apple 登入被拒絕，請檢查 Supabase Apple 供應商的 Client ID。';

  @override
  String get authReauthRequired => '請重新登入。';

  @override
  String blockedUserIdTruncated(Object id) {
    return 'ID（縮略）：$id';
  }

  @override
  String get blockedUsersEmpty => '目前沒有封鎖的用戶。';

  @override
  String blockedUsersLoadFailed(Object error) {
    return '載入封鎖名單失敗：$error';
  }

  @override
  String get blockedUsersTitle => '已封鎖的用戶';

  @override
  String get blockedUserUnblocked => '已解除封鎖。';

  @override
  String blockedUserUnblockFailed(Object error) {
    return '解除封鎖失敗：$error';
  }

  @override
  String get calendarAddMemory => '新增回憶';

  @override
  String get calendarEarlier => '較早';

  @override
  String get calendarLatestPhoto => '最新的照片';

  @override
  String calendarLoadFailed(Object error) {
    return '載入回憶失敗：$error';
  }

  @override
  String get calendarNoEarlierMemories => '暫無較早的回憶。';

  @override
  String get calendarNoMemoriesForDay => '這天沒有回憶。';

  @override
  String get calendarNoPhotoYet => '尚無照片';

  @override
  String get calendarTitle => '回憶錄';

  @override
  String get calendarToday => '今天';

  @override
  String chatBlockFailed(Object error) {
    return '封鎖失敗：$error';
  }

  @override
  String get chatBlockUser => '封鎖用戶';

  @override
  String chatCoinsAwarded(Object count) {
    return '+$count 金幣';
  }

  @override
  String get chatEmptyState => '尚無訊息，從下方開始聊天吧。';

  @override
  String chatLoadBlockedUsersFailed(Object error) {
    return '載入封鎖名單失敗：$error';
  }

  @override
  String chatLoadCacheFailed(Object error) {
    return '載入快取訊息失敗：$error';
  }

  @override
  String chatLoadMessagesFailed(Object error) {
    return '載入訊息失敗：$error';
  }

  @override
  String chatLoadMoreFailed(Object error) {
    return '載入更多失敗：$error';
  }

  @override
  String get chatLoadOlderMessages => '載入更早的訊息';

  @override
  String get chatMessageHint => '訊息';

  @override
  String get chatNoOlderMessages => '沒有更早的訊息。';

  @override
  String get chatPartnerLabel => '對方';

  @override
  String chatRefreshFailed(Object error) {
    return '更新失敗：$error';
  }

  @override
  String chatReportFailed(Object error) {
    return '檢舉失敗：$error';
  }

  @override
  String get chatReportHint => '簡單說明原因';

  @override
  String get chatReportMessageTitle => '檢舉訊息';

  @override
  String get chatReportNoReason => '無原因';

  @override
  String get chatReportSent => '已送出檢舉。';

  @override
  String chatSendFailed(Object error) {
    return '傳送失敗：$error';
  }

  @override
  String get chatSystemUpdate => '系統通知';

  @override
  String get chatTitle => '聊天';

  @override
  String get chatUserAlreadyBlocked => '已封鎖';

  @override
  String get chatUserBlocked => '已封鎖用戶。';

  @override
  String get commonBuy => '購買';

  @override
  String get commonCamera => '相機';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '關閉';

  @override
  String get commonGallery => '相簿';

  @override
  String get commonJoin => '加入';

  @override
  String get commonLeave => '離開';

  @override
  String get commonOwned => '已擁有';

  @override
  String get commonReload => '重新載入';

  @override
  String get commonSave => '儲存';

  @override
  String get commonSend => '送出';

  @override
  String get commonSending => '送出中...';

  @override
  String get commonSignOut => '登出';

  @override
  String get commonSubmit => '送出';

  @override
  String get commonTryAgain => '再試一次';

  @override
  String get commonUnblock => '解除封鎖';

  @override
  String get commonUploading => '上傳中';

  @override
  String get commonUser => '用戶';

  @override
  String currencyJpy(Object amount) {
    return 'JPY $amount';
  }

  @override
  String get drawerCreateRoom => '建立新房間';

  @override
  String get drawerDebugTools => '除錯工具';

  @override
  String get drawerForceRefreshPet => '強制更新寵物';

  @override
  String get drawerFreePlan => '免費方案';

  @override
  String drawerInviteCode(Object code) {
    return '代碼：$code';
  }

  @override
  String get drawerJoinWithCode => '使用邀請碼加入';

  @override
  String get drawerMyRooms => '我的房間';

  @override
  String get drawerNoRooms => '目前沒有房間。';

  @override
  String get drawerPetError => '寵物錯誤';

  @override
  String get drawerRegenerateInviteCode => '重新產生邀請碼';

  @override
  String get drawerSimulateFeed => '模擬餵食';

  @override
  String get drawerTestNotification => '測試本地通知';

  @override
  String get feedCameraSubtitle => '拍照並檢查標籤後再送出。';

  @override
  String get feedCameraTitle => '餵食相機';

  @override
  String feedCanonicalTags(Object tags) {
    return '標準標籤：$tags';
  }

  @override
  String get feedCaptionLabel => '說明（選填）';

  @override
  String get feedDetectedLabels => '偵測到的標籤';

  @override
  String feedLabelingFailed(Object error) {
    return '標註失敗：$error';
  }

  @override
  String get feedLabelingNotSupported => 'Web 不支援 ML Kit 影像標註。';

  @override
  String feedLabelMappingsFailed(Object error) {
    return '載入標籤對應失敗：$error';
  }

  @override
  String get feedLabelMappingsLoading => '載入標籤對應中...';

  @override
  String get feedLabelMappingsReady => '標籤對應已就緒。';

  @override
  String get feedLabelMappingsUnavailable => '無法使用標籤對應。';

  @override
  String get feedNoLabels => '尚未偵測到標籤。';

  @override
  String feedResponse(Object response) {
    return '回應：$response';
  }

  @override
  String get feedSelectImageFirst => '請先選擇圖片。';

  @override
  String get feedSendButton => '送出餵食';

  @override
  String feedSendFailed(Object error) {
    return '送出失敗：$error';
  }

  @override
  String get feedTitle => '餵食';

  @override
  String feedUploadFailed(Object error) {
    return '餵食上傳失敗：$error';
  }

  @override
  String get forceUpdateAction => '立即更新';

  @override
  String get forceUpdateLinkError => '無法開啟商店連結。';

  @override
  String get forceUpdateMessage => '需要更新到新版本才能繼續使用，請立即更新。';

  @override
  String get forceUpdateTitle => '需要更新';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get languageEnglish => '英文';

  @override
  String get languageJapanese => '日文';

  @override
  String get languageSystem => '系統';

  @override
  String get languageSystemSubtitle => '跟隨裝置語言';

  @override
  String get languageTitle => '語言';

  @override
  String get launchTagline => '分享日常，一起成長。';

  @override
  String get moodHigh => '高';

  @override
  String get moodLow => '低';

  @override
  String get moodMid => '中';

  @override
  String get moodNeutral => '普通';

  @override
  String get moodSad => '難過';

  @override
  String petActionFailed(Object error) {
    return '操作失敗：$error';
  }

  @override
  String get petHomeTitle => '寵物的家';

  @override
  String get petNotFound => '找不到寵物。';

  @override
  String petSyncFailed(Object error) {
    return '寵物同步錯誤：$error';
  }

  @override
  String get photoLabel => '照片';

  @override
  String get profileDefaultNickname => '寵物爸媽';

  @override
  String get profileEmpty => '沒有個人檔案。';

  @override
  String profileLoadFailed(Object error) {
    return '載入個人檔案失敗：$error';
  }

  @override
  String get profileNicknameLabel => '暱稱';

  @override
  String get profileTitle => '個人檔案';

  @override
  String get profileUpdated => '已更新個人檔案';

  @override
  String get profileAvatarTitle => '選擇頭像';

  @override
  String get profileAvatarEdit => '編輯頭像';

  @override
  String get profileAvatarUpload => '上傳照片';

  @override
  String get profileAvatarRemove => '移除';

  @override
  String profileCoinsLabel(Object amount) {
    return '金幣：$amount';
  }

  @override
  String get profileDeleteAccountSectionTitle => '刪除帳號';

  @override
  String get profileDeleteAccountSectionBody =>
      '此操作會永久刪除你的帳號。共養房間與寵物會保留並轉移給其他成員。';

  @override
  String get profileDeleteAccountAction => '刪除帳號';

  @override
  String get profileDeleteAccountTitle => '要刪除帳號嗎？';

  @override
  String get profileDeleteAccountConfirmBody =>
      '此操作會永久刪除你的帳號與個人資料。共養房間／寵物會保留並將所有權轉移給其他成員。此操作無法復原。';

  @override
  String get profileDeleteAccountConfirmAction => '刪除';

  @override
  String profileDeleteFailed(Object error) {
    return '刪除帳號失敗：$error';
  }

  @override
  String profileUserId(Object id) {
    return '使用者 ID：$id';
  }

  @override
  String get drawerProfile => '個人檔案';

  @override
  String get roomCreatedSuccess => '已建立房間！請查看側邊欄。';

  @override
  String roomCreateFailed(Object error) {
    return '建立房間失敗：$error';
  }

  @override
  String get roomDefaultName => '新房間';

  @override
  String get roomInviteCodeRegenerated => '邀請碼已重新產生。';

  @override
  String roomInviteCodeRegenerateFailed(Object error) {
    return '重新產生邀請碼失敗：$error';
  }

  @override
  String roomJoinFailed(Object error) {
    return '加入房間失敗：$error';
  }

  @override
  String get roomJoinHelper => '邀請碼不區分大小寫。';

  @override
  String get roomJoinHint => '輸入 6 位邀請碼';

  @override
  String get roomJoinSuccess => '加入房間成功。';

  @override
  String get roomJoinTitle => '加入房間';

  @override
  String roomLeaveFailed(Object error) {
    return '離開房間失敗：$error';
  }

  @override
  String get roomLeaveMessage => '離開後在重新邀請前將無法存取這隻寵物。';

  @override
  String get roomLeaveSuccess => '已離開房間。';

  @override
  String get roomLeaveTitle => '離開房間？';

  @override
  String get roomLimitReached => '已達免費上限（最多 2 個房間）。升級以新增更多！';

  @override
  String roomNewInviteCode(Object code) {
    return '新的邀請碼：$code';
  }

  @override
  String get roomSelectionCreatePet => '建立新寵物';

  @override
  String get roomSelectionCreating => '建立中...';

  @override
  String get roomSelectionEmptySlot => '空位';

  @override
  String get roomSelectionEnterInvite => '輸入邀請碼';

  @override
  String get roomSelectionJoining => '加入中...';

  @override
  String get roomSelectionRoomFallback => '房間';

  @override
  String get roomSelectionSubtitle => '選擇寵物的家並繼續。';

  @override
  String get roomSelectionTitle => '房間選擇';

  @override
  String get signInFailed => '登入失敗，請再試一次。';

  @override
  String get signInNote => '注意：需要在 Supabase 設定 OAuth 供應商。';

  @override
  String get signInOpening => '正在開啟登入...';

  @override
  String signInOpeningProvider(Object provider) {
    return '正在開啟 $provider...';
  }

  @override
  String get signInSubtitle => '登入後開始一起養成寵物。';

  @override
  String get signInWithApple => '使用 Apple 繼續';

  @override
  String get signInWithGoogle => '使用 Google 繼續';

  @override
  String storeCoinPrice(Object amount) {
    return '金幣：$amount';
  }

  @override
  String storeCoinsLabel(Object amount) {
    return '金幣：$amount';
  }

  @override
  String storeCoinsReward(Object amount) {
    return '金幣 +$amount';
  }

  @override
  String get storeEmpty => '商店目前沒有商品。';

  @override
  String get storeIapNotConfigured => '尚未設定 IAP。';

  @override
  String storeIapUnavailable(Object error) {
    return 'IAP 無法使用：$error';
  }

  @override
  String storeLoadFailed(Object error) {
    return '載入商店失敗：$error';
  }

  @override
  String get storeNotEnoughCoins => '金幣不足。';

  @override
  String storeOwnedCount(Object amount) {
    return '已擁有：$amount';
  }

  @override
  String get storePriceUnavailable => '價格不可用';

  @override
  String get storeProductNotFound => '在 RevenueCat 找不到商品。';

  @override
  String get storeProductUnavailable => '商品不可用。';

  @override
  String storePurchaseFailed(Object error) {
    return '購買失敗：$error';
  }

  @override
  String storePurchaseSuccess(Object name) {
    return '已購買 $name。';
  }

  @override
  String storeRestoreFailed(Object error) {
    return '復原失敗：$error';
  }

  @override
  String get storeRestoreTooltip => '恢復購買';

  @override
  String get storeSectionCoinPacks => '金幣包';

  @override
  String get storeSectionCoinStore => '金幣商店';

  @override
  String get storeSectionSubscription => '訂閱';

  @override
  String get storeSignInPrompt => '請先登入才能使用商店。';

  @override
  String get storeSubscribe => '訂閱';

  @override
  String get storeSubscriptionActive => '已啟用';

  @override
  String get storeTitle => '商店';

  @override
  String get storeTypeConsumable => '消耗品';

  @override
  String get storeTypeCosmetic => '外觀';

  @override
  String get storeTypeSubscription => '訂閱';

  @override
  String get furnitureInventoryTitle => '家具';

  @override
  String get furnitureInventorySubtitle => '把家具放進寵物家裡。';

  @override
  String get furnitureInventoryEmpty => '目前沒有家具，去商店買一些吧。';

  @override
  String get furnitureInventoryHint => '長按家具可編輯，點擊道具放置，拖曳移動，點空白退出。';

  @override
  String get furnitureEditMode => '家具模式';
}
