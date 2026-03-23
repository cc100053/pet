// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appleSignInRejected =>
      'Apple 登录被拒絕，请检查 Supabase Apple 供應商的 Client ID。';

  @override
  String get authReauthRequired => '请重新登录。';

  @override
  String blockedUserIdTruncated(Object id) {
    return 'ID（縮略）：$id';
  }

  @override
  String get blockedUsersEmpty => '目前沒有封鎖的用户。';

  @override
  String blockedUsersLoadFailed(Object error) {
    return '加载封鎖名單失敗：$error';
  }

  @override
  String get blockedUsersTitle => '已封鎖的用户';

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
    return '加载回憶失敗：$error';
  }

  @override
  String get calendarNoEarlierMemories => '暂无較早的回憶。';

  @override
  String get calendarNoMemoriesForDay => '这天沒有回憶。';

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
  String get chatBlockUser => '封鎖用户';

  @override
  String chatCoinsAwarded(Object count) {
    return '+$count 糖果';
  }

  @override
  String get chatEmptyState => '尚無消息，從下方開始聊天吧。';

  @override
  String chatLoadBlockedUsersFailed(Object error) {
    return '加载封鎖名單失敗：$error';
  }

  @override
  String chatLoadCacheFailed(Object error) {
    return '加载快取消息失敗：$error';
  }

  @override
  String chatLoadMessagesFailed(Object error) {
    return '加载消息失敗：$error';
  }

  @override
  String chatLoadMoreFailed(Object error) {
    return '加载更多失敗：$error';
  }

  @override
  String get chatLoadOlderMessages => '加载更早的消息';

  @override
  String get chatJumpToLatest => '最新';

  @override
  String get chatMessageHint => '消息';

  @override
  String get chatCopyAction => '复制';

  @override
  String get chatMessageCopied => '已复制消息。';

  @override
  String get chatNoOlderMessages => '沒有更早的消息。';

  @override
  String get chatPartnerLabel => '對方';

  @override
  String get chatReplyAction => '回覆';

  @override
  String chatReplyingTo(Object name) {
    return '回覆 $name';
  }

  @override
  String get chatReplyMessageFallback => '原消息';

  @override
  String get chatReplyPhotoFallback => '照片';

  @override
  String chatRefreshFailed(Object error) {
    return '更新失敗：$error';
  }

  @override
  String chatReportFailed(Object error) {
    return '举报失敗：$error';
  }

  @override
  String get chatReportHint => '簡單說明原因';

  @override
  String get chatReportMessageTitle => '举报消息';

  @override
  String get chatReportNoReason => '無原因';

  @override
  String get chatReportSent => '已送出举报。';

  @override
  String chatSendFailed(Object error) {
    return '傳送失敗：$error';
  }

  @override
  String get chatSystemUpdate => '系统通知';

  @override
  String get chatCandyLabel => '糖果';

  @override
  String chatCleanPoopMessage(Object name, Object amount) {
    return '$name清理了便便：+$amount 糖果';
  }

  @override
  String chatPetHungryReminderMessage(Object petName) {
    return '$petName有点饿了，记得喂食！';
  }

  @override
  String chatPetHungryUrgentMessage(Object petName) {
    return '$petName非常饿！请立即喂食！';
  }

  @override
  String get chatTitle => '聊天';

  @override
  String get chatRoomMembersTitle => '房间成员';

  @override
  String get chatRoomMembersEmpty => '找不到成员。';

  @override
  String chatRoomMembersLoadFailed(Object error) {
    return '加载房间成员失败：$error';
  }

  @override
  String get chatRoomMemberRoleOwner => '房主';

  @override
  String get chatRoomMemberYou => '你';

  @override
  String get chatUserAlreadyBlocked => '已封鎖';

  @override
  String get chatUserBlocked => '已封鎖用户。';

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
  String get commonClose => '关闭';

  @override
  String get commonSkip => '跳过';

  @override
  String get onboardingCreatePetPromptTitle => '選擇寵物入住你的新房間！';

  @override
  String get onboardingRoomEntryPromptTitle => '创建新房间，或输入邀请码加入。';

  @override
  String get onboardingRoomEntryPromptBody => '你可以自己建立宠物房间，或者用邀请码加入朋友的房间。';

  @override
  String get onboardingProfileSetupTitle => '先設定你的個人資料';

  @override
  String get onboardingProfileSetupSubtitle => '請設定朋友會看到的名稱。照片現在可以上傳，也可以稍後再加。';

  @override
  String get onboardingProfileSetupAvatarOptional => '照片可稍後再加';

  @override
  String get onboardingProfileSetupContinue => '繼續';

  @override
  String get onboardingProfileSetupNameRequiredError => '請輸入你要使用的名稱。';

  @override
  String get onboardingProfileSetupNameChangeHint => '請先設定名稱，再繼續下一步。';

  @override
  String get commonGallery => '相簿';

  @override
  String get commonJoin => '加入';

  @override
  String get commonLeave => '离开';

  @override
  String get commonOwned => '已拥有';

  @override
  String get commonReload => '重新加载';

  @override
  String get commonSave => '保存';

  @override
  String get photoViewerDownloadTooltip => '下载';

  @override
  String get photoViewerEmojiAction => '表情';

  @override
  String get photoViewerReplyActionTitle => '回复这张照片';

  @override
  String get photoViewerReplySendAction => '发送';

  @override
  String get photoViewerReplySent => '已发送回复。';

  @override
  String get photoViewerReplySentState => '已发送';

  @override
  String get photoViewerSavedToGallery => '已保存到你的相簿。';

  @override
  String get photoViewerSaveFailed => '无法保存到你的相簿。';

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
  String get commonUser => '用户';

  @override
  String get errorInvalidInviteCode => '邀请碼無效或已過期。';

  @override
  String get errorNetwork => '网络異常，请检查连接後再試一次。';

  @override
  String get errorNotFound => '找不到指定資料。';

  @override
  String get errorPermissionDenied => '你沒有权限執行这个操作。';

  @override
  String get errorImageTooLarge => '图片档案太大，请选择较小的图片。';

  @override
  String get errorPetNameInvalid => '这个宠物名称不可用，请換一個名称。';

  @override
  String get errorUnexpected => '發生错误，请稍后再試。';

  @override
  String currencyJpy(Object amount) {
    return 'JPY $amount';
  }

  @override
  String get drawerCreateRoom => '建立新房间';

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
  String get drawerDebugForceOnboarding => '每次都顯示新手引導';

  @override
  String get drawerDebugForceOnboardingEnabled => '每次打開 App 都顯示';

  @override
  String get drawerDebugForceOnboardingDisabled => '使用正常一次性顯示';

  @override
  String get drawerDebugHungerDown => '宠物飢餓度 -10';

  @override
  String get drawerDebugAddExp => '+10 經驗';

  @override
  String get drawerDebugSpawnPoop => '讓宠物便便';

  @override
  String get drawerDebugShowFullBubble => '顯示「我吃飽了！」氣泡';

  @override
  String get drawerDebugCaptureMemorySnapshot => '記錄記憶體快照';

  @override
  String get drawerDebugClearImageCacheSnapshot => '清除圖片快取並記錄';

  @override
  String get drawerDebugOpenMemoryDiagnostics => '開啟記憶體診斷';

  @override
  String get drawerDebugMemorySnapshotCaptured => '已記錄記憶體快照。';

  @override
  String get drawerDebugImageCacheCleared => '已清除圖片快取並記錄快照。';

  @override
  String get drawerDebugTestSoftUpdate => '測試可選更新彈窗';

  @override
  String get drawerDebugTestHardUpdate => '測試強制更新彈窗';

  @override
  String get drawerDebugTestWhatsNew => '預覽 What\'s New 視窗';

  @override
  String get drawerDebugTestCrashReport => '測試崩潰上報';

  @override
  String get debugMemoryDiagnosticsTitle => '記憶體診斷';

  @override
  String get debugMemoryDiagnosticsEmpty => '尚未記錄任何記憶體快照。';

  @override
  String drawerInviteCode(Object code) {
    return '代碼：$code';
  }

  @override
  String get drawerJoinWithCode => '使用邀请碼加入';

  @override
  String get drawerMyRooms => '我的房间';

  @override
  String get drawerNoRooms => '目前沒有房间。';

  @override
  String get drawerPetError => '宠物错误';

  @override
  String get drawerRegenerateInviteCode => '重新生成邀请碼';

  @override
  String get drawerSimulateFeed => '模擬喂食';

  @override
  String get drawerTestNotification => '測試本地通知';

  @override
  String get feedCameraSubtitle => '拍照後送出。';

  @override
  String get feedCameraTitle => '喂食相機';

  @override
  String get feedPickPhotoHint => '选择照片';

  @override
  String feedCanonicalTags(Object tags) {
    return '標準标签：$tags';
  }

  @override
  String get feedCaptionLabel => '說明（選填）';

  @override
  String get feedDetectedLabels => '检测到的标签';

  @override
  String feedLabelingFailed(Object error) {
    return '標註失敗：$error';
  }

  @override
  String get feedLabelingNotSupported => 'Web 不支援 ML Kit 影像標註。';

  @override
  String feedLabelMappingsFailed(Object error) {
    return '加载标签对应失敗：$error';
  }

  @override
  String get feedLabelMappingsLoading => '加载标签对应中...';

  @override
  String get feedLabelMappingsReady => '标签对应已就緒。';

  @override
  String get feedLabelMappingsUnavailable => '无法使用标签对应。';

  @override
  String get feedNoLabels => '尚未检测到标签。';

  @override
  String feedResponse(Object response) {
    return '回應：$response';
  }

  @override
  String get feedSelectImageFirst => '请先选择图片。';

  @override
  String get feedSendButton => '送出喂食';

  @override
  String feedSendFailed(Object error) {
    return '送出失敗：$error';
  }

  @override
  String get feedTitle => '喂食';

  @override
  String feedUploadFailed(Object error) {
    return '喂食上傳失敗：$error';
  }

  @override
  String get feedRewardPending => '獎勵計算中...';

  @override
  String get forceUpdateAction => '立即更新';

  @override
  String get forceUpdateLinkError => '无法打开商店連結。';

  @override
  String get forceUpdateMessage => '需要更新到新版本才能繼續使用，请立即更新。';

  @override
  String get forceUpdateTitle => '需要更新';

  @override
  String get softUpdateAction => '更新';

  @override
  String get softUpdateLater => '稍后';

  @override
  String get softUpdateMessage => '有新版本可用，更新後可獲得更順暢的共同養寵体验。';

  @override
  String get softUpdateTitle => '可更新新版本';

  @override
  String get whatsNewDialogTitle => '版本更新';

  @override
  String get whatsNewContinueAction => '继续';

  @override
  String get whatsNewContentLabel => '更新內容';

  @override
  String get whatsNewHighlightsLabel => '這個版本的重點';

  @override
  String whatsNewVersionLabel(Object version) {
    return '版本 $version';
  }

  @override
  String get whatsNew105Title => '分享与照顾体验有了更多提升';

  @override
  String get whatsNew105Bullet1 => '在全屏照片查看器中，也可以直接回复照片消息和添加表情回应。';

  @override
  String get whatsNew105Bullet2 => '商店购买通知现在会显示房间里实际买到的道具名称。';

  @override
  String get whatsNew105Bullet3 => '成功喂食后恢复的饥饿值提升了，从 +20 提高到 +25。';

  @override
  String get whatsNew106Title => 'Major Store Update & Stability';

  @override
  String get whatsNew106Bullet1 => 'Major store redesign and visual update';

  @override
  String get whatsNew106Bullet2 => 'Improved app stability and performance';

  @override
  String get whatsNew106Bullet3 => 'Fixed several minor known issues';

  @override
  String get languageChineseSimplified => '简体中文';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageJapanese => '日语';

  @override
  String get languageKorean => '韩语';

  @override
  String get languageSystem => '系统';

  @override
  String get languageSystemSubtitle => '跟隨裝置语言';

  @override
  String get languageTitle => '语言';

  @override
  String get launchAppName => 'PetTomo';

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
  String get petHomeTitle => '宠物的家';

  @override
  String get petNameEditTitle => '編輯宠物名字';

  @override
  String get petNameLabel => '宠物名字';

  @override
  String get petNameHint => '输入宠物名字';

  @override
  String get petNameEmptyError => '请输入名字。';

  @override
  String petNameUpdateFailed(Object error) {
    return '无法更新宠物名字：$error';
  }

  @override
  String chatPetRenamedMessage(Object user, Object oldName, Object petName) {
    return '$user把宠物名字從$oldName改為$petName。';
  }

  @override
  String chatBoughtFurnitureMessage(Object user, Object petName) {
    return '$user为$petName买了家具。';
  }

  @override
  String chatBoughtBackgroundMessage(Object user, Object petName) {
    return '$user为$petName买了背景。';
  }

  @override
  String chatBoughtStoreItemMessage(
    Object user,
    Object itemName,
    Object petName,
  ) {
    return '$user给$petName买了$itemName。';
  }

  @override
  String get petNameUnnamed => '未命名';

  @override
  String get petNotFound => '找不到宠物。';

  @override
  String petSyncFailed(Object error) {
    return '宠物同步错误：$error';
  }

  @override
  String get photoLabel => '照片';

  @override
  String get profileDefaultNickname => '宠物爸媽';

  @override
  String get profileEmpty => '沒有个人资料。';

  @override
  String profileLoadFailed(Object error) {
    return '加载个人资料失敗：$error';
  }

  @override
  String get profileNicknameLabel => '暱稱';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileSectionAccount => '账号';

  @override
  String get profileSectionAbout => '关于与支持';

  @override
  String get profileFeedbackEncouragement =>
      '欢迎你积极提出意见和需求，团队会尽力完成你的建议，一起把产品做得更好。';

  @override
  String get profileFeedback => '发送反馈';

  @override
  String get profileVersionPrefix => '版本：';

  @override
  String get profileSectionDangerZone => '危险区域';

  @override
  String get profileUpdated => '已更新个人资料';

  @override
  String get profileAvatarTitle => '选择頭像';

  @override
  String get profileAvatarEdit => '編輯頭像';

  @override
  String get profileAvatarUpload => '上傳照片';

  @override
  String get profileAvatarAdjustCurrent => '調整目前照片';

  @override
  String get profileAvatarAdjustUnavailable => '沒有可調整的已上傳照片。';

  @override
  String get profileAvatarAdjustUnsupportedPlatform => '此平台暫不支援調整目前照片。';

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
      '此操作會永久刪除你的帳號。共養房间與宠物會保留並轉移給其他成員。';

  @override
  String get profileDeleteAccountAction => '刪除帳號';

  @override
  String get profileDeleteAccountTitle => '要刪除帳號嗎？';

  @override
  String get profileDeleteAccountConfirmBody =>
      '此操作會永久刪除你的帳號與個人資料。共養房间／宠物會保留並將所有權轉移給其他成員。此操作无法復原。';

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
  String get drawerProfile => '个人资料';

  @override
  String get roomCreatedSuccess => '已建立房间！请查看側邊欄。';

  @override
  String roomCreateFailed(Object error) {
    return '建立房间失敗：$error';
  }

  @override
  String get roomCreateTitle => '建立房间';

  @override
  String get roomCreateAction => '建立';

  @override
  String get roomNameLabel => '房间名称';

  @override
  String get roomNameHint => '房间名称';

  @override
  String get roomNameEmptyError => '请输入房间名称。';

  @override
  String roomNameUpdateFailed(Object error) {
    return '无法更新房间名称：$error';
  }

  @override
  String get roomOptionsTitle => '房间選項';

  @override
  String get roomOptionRename => '重新命名房间';

  @override
  String get roomOptionLeave => '离开房间';

  @override
  String get roomRenameTitle => '變更房间名称';

  @override
  String get roomRenameMessage => '输入新的房间名称。';

  @override
  String get roomDefaultName => '新房间';

  @override
  String get roomInviteCta => '邀请';

  @override
  String get roomInventoryCta => '背包';

  @override
  String get roomInvitePromptTitle => '邀请朋友';

  @override
  String get roomInvitePromptBody => '目前只有你。產生邀请碼來邀请朋友加入。';

  @override
  String get roomInvitePromptAction => '產生邀请碼';

  @override
  String get roomInvitePromptGenerating => '產生中...';

  @override
  String get roomInviteCodeTitle => '邀请碼';

  @override
  String get roomInviteCodeMessage => '分享此邀请碼讓朋友加入房间。';

  @override
  String get roomInviteCodeTapHint => '點擊邀請碼即可複製。';

  @override
  String get roomInviteCodeCopiedTitle => '已複製';

  @override
  String get roomInviteCodeCopiedMessage => '快邀請朋友加入，一起照顧寵物吧！';

  @override
  String get roomInviteCodeRegenerated => '邀请碼已重新生成。';

  @override
  String roomInviteCodeRegenerateFailed(Object error) {
    return '重新生成邀请碼失敗：$error';
  }

  @override
  String roomJoinFailed(Object error) {
    return '加入房间失敗：$error';
  }

  @override
  String get roomJoinHelper => '邀请碼不區分大小寫。';

  @override
  String get roomJoinHint => '输入 6 位邀请碼';

  @override
  String get roomJoinSuccess => '加入房间成功。';

  @override
  String get roomJoinTitle => '加入房间';

  @override
  String get roomEnteringLoading => '正在进入房间';

  @override
  String roomLeaveFailed(Object error) {
    return '离开房间失敗：$error';
  }

  @override
  String roomLeaveMessage(Object name) {
    return '你將离开 $name，並失去聊天室與宠物的存取權。';
  }

  @override
  String get roomLeaveSuccess => '已离开房间。';

  @override
  String get roomLeaveTitle => '要离开房间嗎？';

  @override
  String get roomLimitReached => '已達免費上限（最多 2 個房间）。升級以新增更多！';

  @override
  String roomNewInviteCode(Object code) {
    return '新的邀请碼：$code';
  }

  @override
  String get roomSelectionCreatePet => '建立新房间';

  @override
  String get roomSelectionCreating => '建立中...';

  @override
  String get roomSelectionEmptySlot => '空位';

  @override
  String get roomSelectionEnterInvite => '输入邀请碼';

  @override
  String get roomSelectionJoining => '加入中...';

  @override
  String get roomSelectionRoomFallback => '房间';

  @override
  String get roomSelectionSubtitle => '选择宠物的家並繼續。';

  @override
  String get roomSelectionTitle => '房间选择';

  @override
  String get signInFailed => '登录失敗，请再試一次。';

  @override
  String get signInNote => '注意：需要在 Supabase 設定 OAuth 供應商。';

  @override
  String get signInOpening => '正在打开登录...';

  @override
  String signInOpeningProvider(Object provider) {
    return '正在打开 $provider...';
  }

  @override
  String get signInSubtitle => '登录後開始一起養成宠物。';

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
    return 'IAP 无法使用：$error';
  }

  @override
  String storeLoadFailed(Object error) {
    return '加载商店失敗：$error';
  }

  @override
  String get storeNotEnoughCoins => '糖果不足。';

  @override
  String get storeNotEnoughDiamonds => '鑽石不足。';

  @override
  String storeOwnedCount(Object amount) {
    return '已拥有：$amount';
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
  String get storeItemNameProMonthly => 'Pro 月度會員';

  @override
  String get storeItemDescProMonthly => '广告全面移除、房间数量无上限。享受最完美的共育体验！';

  @override
  String get storeItemNameDiamondPack300 => '300 鑽石禮包';

  @override
  String get storeItemDescDiamondPack300 => '一次購買，立即獲得 300 鑽石。';

  @override
  String get storeItemNameReturnLetter => '回家信';

  @override
  String get storeItemDescReturnLetter => '召回离开的宠物。';

  @override
  String get storeItemNameBackgroundDefault => '預設背景';

  @override
  String get storeItemDescBackgroundDefault => '原始溫馨房间背景。';

  @override
  String get storeItemNameBackgroundMoonlight => '银河背景';

  @override
  String get storeItemDescBackgroundMoonlight => '寧靜银河房间背景。';

  @override
  String get storeItemNameFurnitureSofa => '沙發';

  @override
  String get storeItemDescFurnitureSofa => '舒適沙發。';

  @override
  String get storeItemNameFurniturePlant => '盆栽';

  @override
  String get storeItemDescFurniturePlant => '增添生氣的小綠角。';

  @override
  String get storeItemNameFurnitureFrame => '画框';

  @override
  String get storeItemDescFurnitureFrame => '照片画框。';

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
  String get storeSignInPrompt => '请先登录才能使用商店。';

  @override
  String get storeSubscribe => '訂閱';

  @override
  String get storeSubscriptionActive => '已啟用';

  @override
  String get storeSubscriptionDurationMonthly => '1 個月';

  @override
  String get storeSubscriptionRenewalNote => '每月自動續訂，可隨時取消。';

  @override
  String get storeSubscriptionDetailsTitle => '訂閱資訊';

  @override
  String storeSubscriptionDetailsBody(
    Object title,
    Object duration,
    Object price,
  ) {
    return '方案名稱：$title\n訂閱期間：$duration\n價格：$price';
  }

  @override
  String get storePrivacyPolicy => '隱私政策';

  @override
  String get storeTermsOfUse => '使用條款';

  @override
  String get storeLegalSeparator => '|';

  @override
  String get storeLegalOpenFailed => '无法打开法律連結。';

  @override
  String get signInSafetyAgreementLabel => '我同意使用條款與隱私政策，並確認對不當內容或濫用行為採取零容忍。';

  @override
  String get signInSafetyAgreementRequired => '登入前请先同意使用條款與隱私政策。';

  @override
  String get storeTitle => '商店';

  @override
  String get storeTypeConsumable => '消耗品';

  @override
  String get storeTypeCosmetic => '外觀';

  @override
  String get storeTypeSubscription => '訂閱';

  @override
  String get furnitureInventoryTitle => '房间背包';

  @override
  String get furnitureInventorySubtitle => '管理这个房间的家具與背景。';

  @override
  String get furnitureInventoryEmpty => '目前沒有家具，去商店買一些吧。';

  @override
  String get furnitureInventoryHint => '長按家具可編輯，點擊道具放置，拖曳移動，點空白退出。';

  @override
  String get roomInventoryTitle => '房间背包';

  @override
  String get inventoryTabFurniture => '家具';

  @override
  String get backgroundGalleryTab => '背景圖庫';

  @override
  String get backgroundInventoryEmpty => '還沒有背景，去商店看看吧。';

  @override
  String get backgroundInventoryHint => '點擊背景即可套用到房间所有成員。';

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
  String get storeBackgroundRoomRequired => '購買背景前请先选择房间。';

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
  String get petSelectionTitle => '选择你的宠物';

  @override
  String get petSelectionSubtitle => '為这个房间挑一位夥伴。';

  @override
  String get petSelectionHint => '點一下宠物就能繼續。';

  @override
  String petSelectionSelected(Object name) {
    return '已选择：$name';
  }

  @override
  String get petSelectionConfirm => '開始房间';

  @override
  String get petSelectionStarterBadge => '入門';

  @override
  String petSelectionFailed(Object error) {
    return '选择宠物失敗：$error';
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
  String get roomLeaveConfirm => '离开房间';

  @override
  String get roomLockedBadge => '已鎖定';

  @override
  String get roomLockedTitle => '此房间在免費方案已鎖定';

  @override
  String get roomLockedMessage => '免費方案僅可保留最早的 2 個房间可互動。升級 Pro 可在此房间繼續喂食與成長。';

  @override
  String get petDepartureNoteMessage => '為什麼要這樣對我...';

  @override
  String get petDepartureGuideTitle => '來自宠物的信';

  @override
  String get petDepartureGuideMessage => '前往商店購買「信」來把你的宠物叫回來。';

  @override
  String get petDepartureGuideGoStore => '前往商店';

  @override
  String get petDepartureLetterUnavailableTitle => '无法使用信';

  @override
  String get petDepartureLetterUnavailableMessage => '目前沒有离开的宠物。';

  @override
  String get petDepartureLetterSelectTitle => '选择宠物';

  @override
  String get petDepartureLetterSelectMessage => '要把哪隻宠物叫回來？';

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
  String get petDepartureFeedDisabledTitle => '沒有宠物可以喂食';

  @override
  String get petDepartureFeedDisabledMessage => '宠物已离开，現在沒有可以喂食的對象。';

  @override
  String get petOverfedBubble => '我吃飽了！';

  @override
  String get petNameUnknown => '你的宠物';

  @override
  String get roomNameUnknown => '未知的房间';

  @override
  String petReturnFailed(Object error) {
    return '宠物回來失敗：$error';
  }

  @override
  String get storeAdRewardTitle => '观看广告领糖果';

  @override
  String storeAdRewardDescription(Object amount) {
    return '观看短广告并领取 +$amount 糖果。';
  }

  @override
  String get storeAdRewardAction => '观看';

  @override
  String get storeAdRewardLoading => '加载中...';

  @override
  String get storeAdRewardUnavailable => '广告不可用';

  @override
  String get storeAdRewardDismissed => '奖励发放前已关闭广告。';

  @override
  String get storeAdRewardCooldown => '广告奖励目前冷却中。';

  @override
  String get storeAdRewardRoomRequired => '请先选择房间再领取广告奖励。';

  @override
  String storeAdRewardFailed(Object error) {
    return '领取广告奖励失敗：$error';
  }

  @override
  String get feedAdDoubleRewardTitle => '要把喂食奖励翻倍吗？';

  @override
  String feedAdDoubleRewardMessage(Object amount) {
    return '看广告再拿 +$amount 糖果？';
  }

  @override
  String feedAdDoubleRewardFailed(Object error) {
    return '翻倍奖励领取失敗：$error';
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
  String get chatJumpToLatest => '最新';

  @override
  String get chatMessageHint => '訊息';

  @override
  String get chatCopyAction => '複製';

  @override
  String get chatMessageCopied => '已複製訊息。';

  @override
  String get chatNoOlderMessages => '沒有更早的訊息。';

  @override
  String get chatPartnerLabel => '對方';

  @override
  String get chatReplyAction => '回覆';

  @override
  String chatReplyingTo(Object name) {
    return '回覆 $name';
  }

  @override
  String get chatReplyMessageFallback => '原始訊息';

  @override
  String get chatReplyPhotoFallback => '照片';

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
  String chatPetHungryReminderMessage(Object petName) {
    return '$petName有點餓了，記得餵食！';
  }

  @override
  String chatPetHungryUrgentMessage(Object petName) {
    return '$petName非常餓！請立即餵食！';
  }

  @override
  String get chatTitle => '聊天';

  @override
  String get chatRoomMembersTitle => '房間成員';

  @override
  String get chatRoomMembersEmpty => '找不到成員。';

  @override
  String chatRoomMembersLoadFailed(Object error) {
    return '載入房間成員失敗：$error';
  }

  @override
  String get chatRoomMemberRoleOwner => '房主';

  @override
  String get chatRoomMemberYou => '你';

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
  String get commonSkip => '略過';

  @override
  String get onboardingCreatePetPromptTitle => '選擇寵物入住你的新房間！';

  @override
  String get onboardingRoomEntryPromptTitle => '建立新房間，或輸入邀請碼加入。';

  @override
  String get onboardingRoomEntryPromptBody => '你可以建立新的寵物房間，或使用邀請碼加入朋友的房間。';

  @override
  String get onboardingProfileSetupTitle => '先設定你的個人資料';

  @override
  String get onboardingProfileSetupSubtitle => '請設定朋友會看到的名稱。照片現在可以上傳，也可以稍後再加。';

  @override
  String get onboardingProfileSetupAvatarOptional => '照片可稍後再加';

  @override
  String get onboardingProfileSetupContinue => '繼續';

  @override
  String get onboardingProfileSetupNameRequiredError => '請輸入你要使用的名稱。';

  @override
  String get onboardingProfileSetupNameChangeHint => '請先設定名稱，再繼續下一步。';

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
  String get photoViewerDownloadTooltip => '下載';

  @override
  String get photoViewerEmojiAction => '表情';

  @override
  String get photoViewerReplyActionTitle => '回覆這張相片';

  @override
  String get photoViewerReplySendAction => '傳送';

  @override
  String get photoViewerReplySent => '已傳送回覆。';

  @override
  String get photoViewerReplySentState => '已傳送';

  @override
  String get photoViewerSavedToGallery => '已儲存到你的相簿。';

  @override
  String get photoViewerSaveFailed => '無法儲存到你的相簿。';

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
  String get errorImageTooLarge => '圖片檔案太大，請選擇較小的圖片。';

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
  String get drawerDebugForceOnboarding => '每次都顯示新手引導';

  @override
  String get drawerDebugForceOnboardingEnabled => '每次打開 App 都顯示';

  @override
  String get drawerDebugForceOnboardingDisabled => '使用正常一次性顯示';

  @override
  String get drawerDebugHungerDown => '寵物飢餓度 -10';

  @override
  String get drawerDebugAddExp => '+10 經驗';

  @override
  String get drawerDebugSpawnPoop => '讓寵物便便';

  @override
  String get drawerDebugShowFullBubble => '顯示「我吃飽了！」氣泡';

  @override
  String get drawerDebugCaptureMemorySnapshot => '記錄記憶體快照';

  @override
  String get drawerDebugClearImageCacheSnapshot => '清除圖片快取並記錄';

  @override
  String get drawerDebugOpenMemoryDiagnostics => '開啟記憶體診斷';

  @override
  String get drawerDebugMemorySnapshotCaptured => '已記錄記憶體快照。';

  @override
  String get drawerDebugImageCacheCleared => '已清除圖片快取並記錄快照。';

  @override
  String get drawerDebugTestSoftUpdate => '測試可選更新彈窗';

  @override
  String get drawerDebugTestHardUpdate => '測試強制更新彈窗';

  @override
  String get drawerDebugTestWhatsNew => '預覽 What\'s New 視窗';

  @override
  String get drawerDebugTestCrashReport => '測試崩潰上報';

  @override
  String get debugMemoryDiagnosticsTitle => '記憶體診斷';

  @override
  String get debugMemoryDiagnosticsEmpty => '尚未記錄任何記憶體快照。';

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
  String get feedCameraSubtitle => '拍照後送出。';

  @override
  String get feedCameraTitle => '餵食相機';

  @override
  String get feedPickPhotoHint => '選擇照片';

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
  String get feedRewardPending => '獎勵計算中...';

  @override
  String get forceUpdateAction => '立即更新';

  @override
  String get forceUpdateLinkError => '無法開啟商店連結。';

  @override
  String get forceUpdateMessage => '需要更新到新版本才能繼續使用，請立即更新。';

  @override
  String get forceUpdateTitle => '需要更新';

  @override
  String get softUpdateAction => '更新';

  @override
  String get softUpdateLater => '稍後';

  @override
  String get softUpdateMessage => '有新版本可用，更新後可獲得更順暢的共同養寵體驗。';

  @override
  String get softUpdateTitle => '可更新新版本';

  @override
  String get whatsNewDialogTitle => '版本更新';

  @override
  String get whatsNewContinueAction => '繼續';

  @override
  String get whatsNewContentLabel => '更新內容';

  @override
  String get whatsNewHighlightsLabel => '這個版本的重點';

  @override
  String whatsNewVersionLabel(Object version) {
    return '版本 $version';
  }

  @override
  String get whatsNew105Title => '穩定性與安全性更新';

  @override
  String get whatsNew105Bullet1 => '提升安全性以確保更穩定的使用體驗。';

  @override
  String get whatsNew105Bullet2 => '修復已知問題並最佳化效能。';

  @override
  String get whatsNew105Bullet3 => '';

  @override
  String get whatsNew106Title => '商店頁面大更新與穩定性優化';

  @override
  String get whatsNew106Bullet1 => '商店頁面全新改版與設計';

  @override
  String get whatsNew106Bullet2 => '提升應用程式穩定性與效能';

  @override
  String get whatsNew106Bullet3 => '修復部分已知的小問題';

  @override
  String get languageChineseSimplified => '簡體中文';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get languageEnglish => '英文';

  @override
  String get languageJapanese => '日文';

  @override
  String get languageKorean => '韓文';

  @override
  String get languageSystem => '系統';

  @override
  String get languageSystemSubtitle => '跟隨裝置語言';

  @override
  String get languageTitle => '語言';

  @override
  String get launchAppName => 'PetTomo';

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
  String chatBoughtFurnitureMessage(Object user, Object petName) {
    return '$user為$petName買了家具。';
  }

  @override
  String chatBoughtBackgroundMessage(Object user, Object petName) {
    return '$user為$petName買了背景。';
  }

  @override
  String chatBoughtStoreItemMessage(
    Object user,
    Object itemName,
    Object petName,
  ) {
    return '$user買了$itemName給$petName。';
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
  String get profileSectionAccount => '帳號';

  @override
  String get profileSectionAbout => '關於與支援';

  @override
  String get profileFeedbackEncouragement =>
      '歡迎你積極提供意見同需求，團隊會盡力完成你提出嘅建議，一起把產品變得更好。';

  @override
  String get profileFeedback => '提供意見回饋';

  @override
  String get profileVersionPrefix => '版本：';

  @override
  String get profileSectionDangerZone => '危險區域';

  @override
  String get profileUpdated => '已更新個人檔案';

  @override
  String get profileAvatarTitle => '選擇頭像';

  @override
  String get profileAvatarEdit => '編輯頭像';

  @override
  String get profileAvatarUpload => '上傳照片';

  @override
  String get profileAvatarAdjustCurrent => '調整目前照片';

  @override
  String get profileAvatarAdjustUnavailable => '沒有可調整的已上傳照片。';

  @override
  String get profileAvatarAdjustUnsupportedPlatform => '此平台暫不支援調整目前照片。';

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
  String get roomInventoryCta => '背包';

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
  String get roomInviteCodeTapHint => '點擊邀請碼即可複製。';

  @override
  String get roomInviteCodeCopiedTitle => '已複製';

  @override
  String get roomInviteCodeCopiedMessage => '快邀請朋友加入，一起照顧寵物吧！';

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
  String get roomEnteringLoading => '正在進入房間';

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
  String get roomSelectionCreatePet => '建立新房間';

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
  String get storeItemDescProMonthly => '廣告全面移除、房間數量無上限。享受最完美的共育體驗！';

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
  String get storeItemNameBackgroundMoonlight => '銀河背景';

  @override
  String get storeItemDescBackgroundMoonlight => '寧靜銀河房間背景。';

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
  String get storeSubscriptionDurationMonthly => '1 個月';

  @override
  String get storeSubscriptionRenewalNote => '每月自動續訂，可隨時取消。';

  @override
  String get storeSubscriptionDetailsTitle => '訂閱資訊';

  @override
  String storeSubscriptionDetailsBody(
    Object title,
    Object duration,
    Object price,
  ) {
    return '方案名稱：$title\n訂閱期間：$duration\n價格：$price';
  }

  @override
  String get storePrivacyPolicy => '隱私權政策';

  @override
  String get storeTermsOfUse => '使用條款';

  @override
  String get storeLegalSeparator => '|';

  @override
  String get storeLegalOpenFailed => '無法開啟法律連結。';

  @override
  String get signInSafetyAgreementLabel => '我同意使用條款與隱私權政策，並確認對不當內容或濫用行為採取零容忍。';

  @override
  String get signInSafetyAgreementRequired => '登入前請先同意使用條款與隱私權政策。';

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
  String get roomLockedBadge => '已鎖定';

  @override
  String get roomLockedTitle => '此房間在免費方案已鎖定';

  @override
  String get roomLockedMessage => '免費方案僅可保留最早的 2 個房間可互動。升級 Pro 可在此房間繼續餵食與成長。';

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

  @override
  String get storeAdRewardTitle => '觀看廣告領糖果';

  @override
  String storeAdRewardDescription(Object amount) {
    return '觀看短廣告並領取 +$amount 糖果。';
  }

  @override
  String get storeAdRewardAction => '觀看';

  @override
  String get storeAdRewardLoading => '載入中...';

  @override
  String get storeAdRewardUnavailable => '廣告不可用';

  @override
  String get storeAdRewardDismissed => '尚未領獎前已關閉廣告。';

  @override
  String get storeAdRewardCooldown => '廣告獎勵目前冷卻中。';

  @override
  String get storeAdRewardRoomRequired => '請先選擇房間再領取廣告獎勵。';

  @override
  String storeAdRewardFailed(Object error) {
    return '領取廣告獎勵失敗：$error';
  }

  @override
  String get feedAdDoubleRewardTitle => '要把餵食獎勵加倍嗎？';

  @override
  String feedAdDoubleRewardMessage(Object amount) {
    return '看廣告再拿 +$amount 糖果？';
  }

  @override
  String feedAdDoubleRewardFailed(Object error) {
    return '加倍獎勵領取失敗：$error';
  }
}
