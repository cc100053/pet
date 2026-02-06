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
    return '+$count 糖果';
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
  String get chatCandyLabel => '糖果';

  @override
  String chatCleanPoopMessage(Object name, Object amount) {
    return '$name清理了便便：+$amount 糖果';
  }

  @override
  String get chatTitle => '聊天';

  @override
  String get chatUserAlreadyBlocked => '已封鎖';

  @override
  String get chatUserBlocked => '已封鎖用戶。';

  @override
  String chatMemberCount(num count) {
    return '$count 位成員';
  }

  @override
  String get calendarYesterday => '昨天';

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
  String get errorInvalidInviteCode => '邀請碼無效或已過期。';

  @override
  String get errorNetwork => '網路異常，請檢查連線後再試一次。';

  @override
  String get errorNotFound => '找不到指定資料。';

  @override
  String get errorPermissionDenied => '你沒有權限執行這個操作。';

  @override
  String get errorPetNameInvalid => '這個寵物名稱不可用，請換一個名稱。';

  @override
  String get errorUnexpected => '發生錯誤，請稍後再試。';

  @override
  String currencyJpy(Object amount) {
    return 'JPY $amount';
  }

  @override
  String get drawerCreateRoom => '建立新房間';

  @override
  String get drawerDebugTools => '除錯工具';

  @override
  String get drawerFreePlan => '免費方案';

  @override
  String get drawerProPlan => 'Pro 方案';

  @override
  String get drawerDebugAddCandy => '+100 糖果';

  @override
  String get drawerDebugAddDiamonds => '+100 鑽石';

  @override
  String get drawerDebugTogglePlan => '切換方案';

  @override
  String get drawerDebugHungerDown => '寵物飢餓度 -10';

  @override
  String get drawerDebugAddExp => '+10 經驗';

  @override
  String get drawerDebugSpawnPoop => '讓寵物便便';

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
  String get petNameEditTitle => '編輯寵物名字';

  @override
  String get petNameLabel => '寵物名字';

  @override
  String get petNameHint => '輸入寵物名字';

  @override
  String get petNameEmptyError => '請輸入名字。';

  @override
  String petNameUpdateFailed(Object error) {
    return '無法更新寵物名字：$error';
  }

  @override
  String chatPetRenamedMessage(Object user, Object oldName, Object petName) {
    return '$user把寵物名字從$oldName改為$petName。';
  }

  @override
  String get petNameUnnamed => '未命名';

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
    return '糖果：$amount';
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
  String get roomCreateTitle => '建立房間';

  @override
  String get roomCreateAction => '建立';

  @override
  String get roomNameLabel => '房間名稱';

  @override
  String get roomNameHint => '房間名稱';

  @override
  String get roomNameEmptyError => '請輸入房間名稱。';

  @override
  String roomNameUpdateFailed(Object error) {
    return '無法更新房間名稱：$error';
  }

  @override
  String get roomOptionsTitle => '房間選項';

  @override
  String get roomOptionRename => '重新命名房間';

  @override
  String get roomOptionLeave => '離開房間';

  @override
  String get roomRenameTitle => '變更房間名稱';

  @override
  String get roomRenameMessage => '輸入新的房間名稱。';

  @override
  String get roomDefaultName => '新房間';

  @override
  String get roomInviteCta => '邀請';

  @override
  String get roomInvitePromptTitle => '邀請朋友';

  @override
  String get roomInvitePromptBody => '目前只有你。產生邀請碼來邀請朋友加入。';

  @override
  String get roomInvitePromptAction => '產生邀請碼';

  @override
  String get roomInvitePromptGenerating => '產生中...';

  @override
  String get roomInviteCodeTitle => '邀請碼';

  @override
  String get roomInviteCodeMessage => '分享此邀請碼讓朋友加入房間。';

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
  String roomLeaveMessage(Object name) {
    return '你將離開 $name，並失去聊天室與寵物的存取權。';
  }

  @override
  String get roomLeaveSuccess => '已離開房間。';

  @override
  String get roomLeaveTitle => '要離開房間嗎？';

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
    return '糖果：$amount';
  }

  @override
  String storeCoinsLabel(Object amount) {
    return '糖果：$amount';
  }

  @override
  String storeCoinsReward(Object amount) {
    return '糖果 +$amount';
  }

  @override
  String storeDiamondsLabel(Object amount) {
    return '鑽石：$amount';
  }

  @override
  String storeDiamondsReward(Object amount) {
    return '鑽石 +$amount';
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
  String get storeNotEnoughCoins => '糖果不足。';

  @override
  String get storeNotEnoughDiamonds => '鑽石不足。';

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
  String get storeSectionCoinPacks => '糖果包';

  @override
  String get storeSectionCoinStore => '糖果商店';

  @override
  String get storeSectionDiamondPacks => '鑽石包';

  @override
  String get storeSectionDiamondStore => '鑽石商店';

  @override
  String get storeSectionSubscription => '訂閱';

  @override
  String get storeTabPremium => '高級';

  @override
  String get storeTabFurniture => '家具';

  @override
  String get storeTabThemes => '主題';

  @override
  String get storeThemePreviewAction => '預覽';

  @override
  String storeThemePreviewTitle(Object name) {
    return '$name 預覽';
  }

  @override
  String get storeItemNameProMonthly => 'Pro 月訂閱';

  @override
  String get storeItemDescProMonthly => '每月 Pro 方案。';

  @override
  String get storeItemNameDiamondPack300 => '300 鑽石包';

  @override
  String get storeItemDescDiamondPack300 => '一次性 300 鑽石。';

  @override
  String get storeItemNameReturnLetter => '回家信';

  @override
  String get storeItemDescReturnLetter => '召回離開的寵物。';

  @override
  String get storeItemNameBackgroundDefault => '預設背景';

  @override
  String get storeItemDescBackgroundDefault => '原始溫馨房間背景。';

  @override
  String get storeItemNameBackgroundMoonlight => '月光背景';

  @override
  String get storeItemDescBackgroundMoonlight => '寧靜月光房間背景。';

  @override
  String get storeItemNameFurnitureSofa => '沙發';

  @override
  String get storeItemDescFurnitureSofa => '舒適沙發。';

  @override
  String get storeItemNameFurniturePlant => '盆栽';

  @override
  String get storeItemDescFurniturePlant => '增添生氣的小綠角。';

  @override
  String get storeItemNameFurnitureFrame => '畫框';

  @override
  String get storeItemDescFurnitureFrame => '照片畫框。';

  @override
  String get storeItemNameFurnitureTeddy => '泰迪熊';

  @override
  String get storeItemDescFurnitureTeddy => '柔軟玩偶。';

  @override
  String get storeItemNameFurnitureBricks => '積木牆';

  @override
  String get storeItemDescFurnitureBricks => '方塊風格點綴。';

  @override
  String get storeItemNameFurnitureTv => '電視';

  @override
  String get storeItemDescFurnitureTv => '迷你電視。';

  @override
  String get storeItemNameFurnitureBath => '浴缸';

  @override
  String get storeItemDescFurnitureBath => '迷你浴缸。';

  @override
  String get storeItemNameFurnitureRibbon => '緞帶';

  @override
  String get storeItemDescFurnitureRibbon => '裝飾緞帶。';

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
  String get furnitureInventoryTitle => '房間背包';

  @override
  String get furnitureInventorySubtitle => '管理這個房間的家具與背景。';

  @override
  String get furnitureInventoryEmpty => '目前沒有家具，去商店買一些吧。';

  @override
  String get furnitureInventoryHint => '長按家具可編輯，點擊道具放置，拖曳移動，點空白退出。';

  @override
  String get roomInventoryTitle => '房間背包';

  @override
  String get inventoryTabFurniture => '家具';

  @override
  String get backgroundGalleryTab => '背景圖庫';

  @override
  String get backgroundInventoryEmpty => '還沒有背景，去商店看看吧。';

  @override
  String get backgroundInventoryHint => '點擊背景即可套用到房間所有成員。';

  @override
  String get backgroundApply => '套用';

  @override
  String get backgroundAppliedLabel => '已套用';

  @override
  String backgroundApplyFailed(Object error) {
    return '套用背景失敗：$error';
  }

  @override
  String get storeSectionBackgrounds => '背景';

  @override
  String get storeSectionItems => '商品';

  @override
  String get storeBackgroundRoomRequired => '購買背景前請先選擇房間。';

  @override
  String storeBuyWithCandies(Object price) {
    return '用 $price 糖果購買';
  }

  @override
  String storeBuyWithDiamonds(Object price) {
    return '用 $price 鑽石購買';
  }

  @override
  String get furnitureEditMode => '家具模式';

  @override
  String get petSelectionTitle => '選擇你的寵物';

  @override
  String get petSelectionSubtitle => '為這個房間挑一位夥伴。';

  @override
  String get petSelectionHint => '點一下寵物就能繼續。';

  @override
  String petSelectionSelected(Object name) {
    return '已選擇：$name';
  }

  @override
  String get petSelectionConfirm => '開始房間';

  @override
  String get petSelectionStarterBadge => '入門';

  @override
  String petSelectionFailed(Object error) {
    return '選擇寵物失敗：$error';
  }

  @override
  String get petTypeGhostName => '小幽靈';

  @override
  String get petTypeGhostTagline => '害羞又愛零食的飄飄。';

  @override
  String get petTypeCatName => '小貓';

  @override
  String get petTypeCatTagline => '好奇又愛撒嬌的小獵手。';

  @override
  String get petTypeFishName => '小魚';

  @override
  String get petTypeFishTagline => '愛滑行的泡泡游泳家。';

  @override
  String get roomLeaveConfirm => '離開房間';

  @override
  String get petDepartureNoteMessage => '為什麼要這樣對我...';

  @override
  String get petDepartureGuideTitle => '來自寵物的信';

  @override
  String get petDepartureGuideMessage => '前往商店購買「信」來把你的寵物叫回來。';

  @override
  String get petDepartureGuideGoStore => '前往商店';

  @override
  String get petDepartureLetterUnavailableTitle => '無法使用信';

  @override
  String get petDepartureLetterUnavailableMessage => '目前沒有離開的寵物。';

  @override
  String get petDepartureLetterSelectTitle => '選擇寵物';

  @override
  String get petDepartureLetterSelectMessage => '要把哪隻寵物叫回來？';

  @override
  String petDepartureLetterConfirmTitle(Object petName) {
    return '要叫回 $petName 嗎？';
  }

  @override
  String petDepartureLetterConfirmMessage(Object petName) {
    return '購買信件來把 $petName 叫回家嗎？';
  }

  @override
  String get petDepartureLetterConfirmAction => '購買信';

  @override
  String get petDepartureFeedDisabledTitle => '沒有寵物可以餵食';

  @override
  String get petDepartureFeedDisabledMessage => '寵物已離開，現在沒有可以餵食的對象。';

  @override
  String get petOverfedBubble => '我吃飽了！';

  @override
  String get petNameUnknown => '你的寵物';

  @override
  String get roomNameUnknown => '未知的房間';

  @override
  String petReturnFailed(Object error) {
    return '寵物回來失敗：$error';
  }
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
    return '+$count 糖果';
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
  String get chatCandyLabel => '糖果';

  @override
  String chatCleanPoopMessage(Object name, Object amount) {
    return '$name清理了便便：+$amount 糖果';
  }

  @override
  String get chatTitle => '聊天';

  @override
  String get chatUserAlreadyBlocked => '已封鎖';

  @override
  String get chatUserBlocked => '已封鎖用戶。';

  @override
  String chatMemberCount(num count) {
    return '$count 位成員';
  }

  @override
  String get calendarYesterday => '昨天';

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
  String get errorInvalidInviteCode => '邀請碼無效或已過期。';

  @override
  String get errorNetwork => '網路異常，請檢查連線後再試一次。';

  @override
  String get errorNotFound => '找不到指定資料。';

  @override
  String get errorPermissionDenied => '你沒有權限執行這個操作。';

  @override
  String get errorPetNameInvalid => '這個寵物名稱不可用，請換一個名稱。';

  @override
  String get errorUnexpected => '發生錯誤，請稍後再試。';

  @override
  String currencyJpy(Object amount) {
    return 'JPY $amount';
  }

  @override
  String get drawerCreateRoom => '建立新房間';

  @override
  String get drawerDebugTools => '除錯工具';

  @override
  String get drawerFreePlan => '免費方案';

  @override
  String get drawerProPlan => 'Pro 方案';

  @override
  String get drawerDebugAddCandy => '+100 糖果';

  @override
  String get drawerDebugAddDiamonds => '+100 鑽石';

  @override
  String get drawerDebugTogglePlan => '切換方案';

  @override
  String get drawerDebugHungerDown => '寵物飢餓度 -10';

  @override
  String get drawerDebugAddExp => '+10 經驗';

  @override
  String get drawerDebugSpawnPoop => '讓寵物便便';

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
  String get petNameEditTitle => '編輯寵物名字';

  @override
  String get petNameLabel => '寵物名字';

  @override
  String get petNameHint => '輸入寵物名字';

  @override
  String get petNameEmptyError => '請輸入名字。';

  @override
  String petNameUpdateFailed(Object error) {
    return '無法更新寵物名字：$error';
  }

  @override
  String chatPetRenamedMessage(Object user, Object oldName, Object petName) {
    return '$user把寵物名字從$oldName改為$petName。';
  }

  @override
  String get petNameUnnamed => '未命名';

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
    return '糖果：$amount';
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
  String get roomCreateTitle => '建立房間';

  @override
  String get roomCreateAction => '建立';

  @override
  String get roomNameLabel => '房間名稱';

  @override
  String get roomNameHint => '房間名稱';

  @override
  String get roomNameEmptyError => '請輸入房間名稱。';

  @override
  String roomNameUpdateFailed(Object error) {
    return '無法更新房間名稱：$error';
  }

  @override
  String get roomOptionsTitle => '房間選項';

  @override
  String get roomOptionRename => '重新命名房間';

  @override
  String get roomOptionLeave => '離開房間';

  @override
  String get roomRenameTitle => '變更房間名稱';

  @override
  String get roomRenameMessage => '輸入新的房間名稱。';

  @override
  String get roomDefaultName => '新房間';

  @override
  String get roomInviteCta => '邀請';

  @override
  String get roomInvitePromptTitle => '邀請朋友';

  @override
  String get roomInvitePromptBody => '目前只有你。產生邀請碼來邀請朋友加入。';

  @override
  String get roomInvitePromptAction => '產生邀請碼';

  @override
  String get roomInvitePromptGenerating => '產生中...';

  @override
  String get roomInviteCodeTitle => '邀請碼';

  @override
  String get roomInviteCodeMessage => '分享此邀請碼讓朋友加入房間。';

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
  String roomLeaveMessage(Object name) {
    return '你將離開 $name，並失去聊天室與寵物的存取權。';
  }

  @override
  String get roomLeaveSuccess => '已離開房間。';

  @override
  String get roomLeaveTitle => '要離開房間嗎？';

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
    return '糖果：$amount';
  }

  @override
  String storeCoinsLabel(Object amount) {
    return '糖果：$amount';
  }

  @override
  String storeCoinsReward(Object amount) {
    return '糖果 +$amount';
  }

  @override
  String storeDiamondsLabel(Object amount) {
    return '鑽石：$amount';
  }

  @override
  String storeDiamondsReward(Object amount) {
    return '鑽石 +$amount';
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
  String get storeNotEnoughCoins => '糖果不足。';

  @override
  String get storeNotEnoughDiamonds => '鑽石不足。';

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
  String get storeSectionCoinPacks => '糖果包';

  @override
  String get storeSectionCoinStore => '糖果商店';

  @override
  String get storeSectionDiamondPacks => '鑽石包';

  @override
  String get storeSectionDiamondStore => '鑽石商店';

  @override
  String get storeSectionSubscription => '訂閱';

  @override
  String get storeTabPremium => '高級';

  @override
  String get storeTabFurniture => '家具';

  @override
  String get storeTabThemes => '主題';

  @override
  String get storeThemePreviewAction => '預覽';

  @override
  String storeThemePreviewTitle(Object name) {
    return '$name 預覽';
  }

  @override
  String get storeItemNameProMonthly => 'Pro 月訂閱';

  @override
  String get storeItemDescProMonthly => '每月 Pro 方案。';

  @override
  String get storeItemNameDiamondPack300 => '300 鑽石包';

  @override
  String get storeItemDescDiamondPack300 => '一次性 300 鑽石。';

  @override
  String get storeItemNameReturnLetter => '回家信';

  @override
  String get storeItemDescReturnLetter => '召回離開的寵物。';

  @override
  String get storeItemNameBackgroundDefault => '預設背景';

  @override
  String get storeItemDescBackgroundDefault => '原始溫馨房間背景。';

  @override
  String get storeItemNameBackgroundMoonlight => '月光背景';

  @override
  String get storeItemDescBackgroundMoonlight => '寧靜月光房間背景。';

  @override
  String get storeItemNameFurnitureSofa => '沙發';

  @override
  String get storeItemDescFurnitureSofa => '舒適沙發。';

  @override
  String get storeItemNameFurniturePlant => '盆栽';

  @override
  String get storeItemDescFurniturePlant => '增添生氣的小綠角。';

  @override
  String get storeItemNameFurnitureFrame => '畫框';

  @override
  String get storeItemDescFurnitureFrame => '照片畫框。';

  @override
  String get storeItemNameFurnitureTeddy => '泰迪熊';

  @override
  String get storeItemDescFurnitureTeddy => '柔軟玩偶。';

  @override
  String get storeItemNameFurnitureBricks => '積木牆';

  @override
  String get storeItemDescFurnitureBricks => '方塊風格點綴。';

  @override
  String get storeItemNameFurnitureTv => '電視';

  @override
  String get storeItemDescFurnitureTv => '迷你電視。';

  @override
  String get storeItemNameFurnitureBath => '浴缸';

  @override
  String get storeItemDescFurnitureBath => '迷你浴缸。';

  @override
  String get storeItemNameFurnitureRibbon => '緞帶';

  @override
  String get storeItemDescFurnitureRibbon => '裝飾緞帶。';

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
  String get furnitureInventoryTitle => '房間背包';

  @override
  String get furnitureInventorySubtitle => '管理這個房間的家具與背景。';

  @override
  String get furnitureInventoryEmpty => '目前沒有家具，去商店買一些吧。';

  @override
  String get furnitureInventoryHint => '長按家具可編輯，點擊道具放置，拖曳移動，點空白退出。';

  @override
  String get roomInventoryTitle => '房間背包';

  @override
  String get inventoryTabFurniture => '家具';

  @override
  String get backgroundGalleryTab => '背景圖庫';

  @override
  String get backgroundInventoryEmpty => '還沒有背景，去商店看看吧。';

  @override
  String get backgroundInventoryHint => '點擊背景即可套用到房間所有成員。';

  @override
  String get backgroundApply => '套用';

  @override
  String get backgroundAppliedLabel => '已套用';

  @override
  String backgroundApplyFailed(Object error) {
    return '套用背景失敗：$error';
  }

  @override
  String get storeSectionBackgrounds => '背景';

  @override
  String get storeSectionItems => '商品';

  @override
  String get storeBackgroundRoomRequired => '購買背景前請先選擇房間。';

  @override
  String storeBuyWithCandies(Object price) {
    return '用 $price 糖果購買';
  }

  @override
  String storeBuyWithDiamonds(Object price) {
    return '用 $price 鑽石購買';
  }

  @override
  String get furnitureEditMode => '家具模式';

  @override
  String get petSelectionTitle => '選擇你的寵物';

  @override
  String get petSelectionSubtitle => '為這個房間挑一位夥伴。';

  @override
  String get petSelectionHint => '點一下寵物就能繼續。';

  @override
  String petSelectionSelected(Object name) {
    return '已選擇：$name';
  }

  @override
  String get petSelectionConfirm => '開始房間';

  @override
  String get petSelectionStarterBadge => '入門';

  @override
  String petSelectionFailed(Object error) {
    return '選擇寵物失敗：$error';
  }

  @override
  String get petTypeGhostName => '小幽靈';

  @override
  String get petTypeGhostTagline => '害羞又愛零食的飄飄。';

  @override
  String get petTypeCatName => '小貓';

  @override
  String get petTypeCatTagline => '好奇又愛撒嬌的小獵手。';

  @override
  String get petTypeFishName => '小魚';

  @override
  String get petTypeFishTagline => '愛滑行的泡泡游泳家。';

  @override
  String get roomLeaveConfirm => '離開房間';

  @override
  String get petDepartureNoteMessage => '為什麼要這樣對我...';

  @override
  String get petDepartureGuideTitle => '來自寵物的信';

  @override
  String get petDepartureGuideMessage => '前往商店購買「信」來把你的寵物叫回來。';

  @override
  String get petDepartureGuideGoStore => '前往商店';

  @override
  String get petDepartureLetterUnavailableTitle => '無法使用信';

  @override
  String get petDepartureLetterUnavailableMessage => '目前沒有離開的寵物。';

  @override
  String get petDepartureLetterSelectTitle => '選擇寵物';

  @override
  String get petDepartureLetterSelectMessage => '要把哪隻寵物叫回來？';

  @override
  String petDepartureLetterConfirmTitle(Object petName) {
    return '要叫回 $petName 嗎？';
  }

  @override
  String petDepartureLetterConfirmMessage(Object petName) {
    return '購買信件來把 $petName 叫回家嗎？';
  }

  @override
  String get petDepartureLetterConfirmAction => '購買信';

  @override
  String get petDepartureFeedDisabledTitle => '沒有寵物可以餵食';

  @override
  String get petDepartureFeedDisabledMessage => '寵物已離開，現在沒有可以餵食的對象。';

  @override
  String get petOverfedBubble => '我吃飽了！';

  @override
  String get petNameUnknown => '你的寵物';

  @override
  String get roomNameUnknown => '未知的房間';

  @override
  String petReturnFailed(Object error) {
    return '寵物回來失敗：$error';
  }
}
