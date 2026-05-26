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
    return '糖果 +$count';
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
  String get chatEditAction => '编辑';

  @override
  String get chatDeleteAction => '删除';

  @override
  String get chatMessageCopied => '已复制消息。';

  @override
  String get chatEditMessageTitle => '编辑消息';

  @override
  String get chatDeleteMessageTitle => '删除消息';

  @override
  String get chatDeleteMessageConfirm => '这条消息会改为“已删除”提示，原内容不会再显示。';

  @override
  String get chatMessageEdited => '已编辑';

  @override
  String get chatMessageDeleted => '消息已删除';

  @override
  String get chatEditNoChanges => '没有需要保存的更改。';

  @override
  String chatEditFailed(Object error) {
    return '编辑失敗：$error';
  }

  @override
  String chatDeleteFailed(Object error) {
    return '删除失敗：$error';
  }

  @override
  String get chatNoOlderMessages => '沒有更早的消息。';

  @override
  String get chatPartnerLabel => '對方';

  @override
  String get chatReplyAction => '回覆';

  @override
  String get chatMoreReactionsAction => '更多';

  @override
  String get chatAllEmojiAction => '全部表情';

  @override
  String chatReactionCount(int count) {
    return '$count 个表情反应';
  }

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
  String get commonBuyMore => '繼續購買';

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
  String get drawerDebugCategorySimulation => '模拟与测试';

  @override
  String get drawerDebugCategoryUser => '用户与方案';

  @override
  String get drawerDebugCategoryPet => '宠物状态';

  @override
  String get drawerDebugCategoryMemory => '内存诊断';

  @override
  String get drawerDebugCategorySystem => '更新与系统';

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
  String get drawerDebugTestProfileSetupOnboarding => '測試個人資料設定';

  @override
  String get drawerDebugTestProfileSetupOnboardingSubtitle =>
      '立即打開新用戶改名與上傳照片步驟';

  @override
  String get drawerDebugHungerDown => '宠物飢餓度 -10';

  @override
  String get drawerDebugHungerUp => '宠物飽食度 +20';

  @override
  String get drawerDebugAddExp => '+10 經驗';

  @override
  String get drawerDebugSpawnPoop => '讓宠物便便';

  @override
  String get drawerDebugShowFullBubble => '顯示「我吃飽了！」氣泡';

  @override
  String get drawerDebugShowSocketOverlay => '顯示掛點調試';

  @override
  String get drawerDebugDressUpFitTool => '裝扮調整工具';

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
  String get feedRecallPhotoAction => '撤回';

  @override
  String get feedRecallPhotoTitle => '撤回照片';

  @override
  String get feedRecallPhotoConfirm => '这张照片将对所有人删除。金币和宠物吃的饭都会保留。';

  @override
  String feedRecallPhotoFailed(Object error) {
    return '撤回失败：$error';
  }

  @override
  String get feedRewardPending => '獎勵計算中...';

  @override
  String get crashRecoveryAction => '知道了';

  @override
  String get crashRecoveryMessage =>
      '游戏刚才似乎异常中断，请关闭 App 后重新打开再试一次。如果问题持续，请稍后再试。';

  @override
  String get crashRecoveryPetCaption => '小宠物先陪你休息一下。';

  @override
  String get crashRecoveryPetSemanticLabel => '正在休息的小宠物';

  @override
  String get crashRecoveryTitle => '游戏发生错误';

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
  String get whatsNewSuggestFeatureAction => '建議新功能';

  @override
  String get whatsNewSuggestFeatureTitle => '你希望有咩新功能？';

  @override
  String get whatsNewSuggestFeaturePlaceholder => '描述你嘅想法...';

  @override
  String get whatsNewSuggestFeatureSubmit => '發送';

  @override
  String get whatsNewSuggestFeatureSuccess => '多謝你嘅建議！';

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
  String get whatsNew106Title => '商店大改版与稳定性提升';

  @override
  String get whatsNew106Bullet1 => '商店全面改版，视觉焕然一新';

  @override
  String get whatsNew106Bullet2 => '提升 App 稳定性与性能';

  @override
  String get whatsNew106Bullet3 => '修复多项已知小问题';

  @override
  String get whatsNew110Title => '全新老虎宠物与家具缩放';

  @override
  String get whatsNew110Bullet1 => '认识全新的老虎宠物，并为你的房间选择它！';

  @override
  String get whatsNew110Bullet2 => '商店上架多款精美新背景。';

  @override
  String get whatsNew110Bullet3 => '点击已放置的家具，使用底部大小控制列进行精确布局。';

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
  String get profileAvatarEditorHint => '拖曳調整位置，雙指縮放。';

  @override
  String get profileAvatarEditorZoom => '縮放';

  @override
  String get profileAvatarEditorCenter => '置中';

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
  String get roomInviteCopyCodeAction => '複製';

  @override
  String get roomInviteShareAction => '分享';

  @override
  String get roomInviteShareCaption => '來 PetTomo 和我一起玩';

  @override
  String roomInviteShareFailed(Object error) {
    return '分享邀請失敗：$error';
  }

  @override
  String get roomInviteLinkJoining => '正在透過邀請加入房間...';

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
  String get shopEmpty => '商店目前沒有商品。';

  @override
  String get storeIapNotConfigured => '尚未設定 IAP。';

  @override
  String storeIapUnavailable(Object error) {
    return 'IAP 无法使用：$error';
  }

  @override
  String shopLoadFailed(Object error) {
    return '加载商店失敗：$error';
  }

  @override
  String get storeNotEnoughCoins => '糖果不足。';

  @override
  String get storeNotEnoughDiamonds => '鑽石不足。';

  @override
  String storeOwnedCount(Object amount) {
    return '已擁有 x$amount';
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
  String get shopReturnToRoomCta => '返回房间';

  @override
  String get shopReturnToRoomHint => '回到宠物房间后就可以开始布置。';

  @override
  String storeRestoreFailed(Object error) {
    return '復原失敗：$error';
  }

  @override
  String get storeRestoreTooltip => '恢復購買';

  @override
  String get shopSectionCoinPacks => '糖果包';

  @override
  String get shopSectionCoinShop => '糖果商店';

  @override
  String get shopSectionDiamondPacks => '鑽石包';

  @override
  String get shopSectionDiamondShop => '鑽石商店';

  @override
  String get shopSectionSubscription => '訂閱';

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
  String get storePremiumBenefitUnlimitedRooms => '房间数量无上限';

  @override
  String get storePremiumBenefitNoAds => '广告全面移除';

  @override
  String get storePremiumBenefitExclusiveItems => '解锁专属商品';

  @override
  String get storeItemNameDiamondPack300 => '300 鑽石禮包';

  @override
  String get storeItemDescDiamondPack300 => '一次購買，立即獲得 300 鑽石。';

  @override
  String get storeItemNameCandyPack500 => '500 糖果包';

  @override
  String get storeItemDescCandyPack500 => '使用 50 鑽石兌換 500 糖果。';

  @override
  String get storeItemNameReturnLetter => '回家信';

  @override
  String get storeItemDescReturnLetter => '召回离开的宠物。';

  @override
  String get storeItemNamePetTicket => '宠物券';

  @override
  String get storeItemDescPetTicket => '邀请另一只宠物加入这个房间。';

  @override
  String get storeItemNameBackgroundDefault => '預設背景';

  @override
  String get storeItemDescBackgroundDefault => '原始溫馨房间背景。';

  @override
  String get storeItemNameBackgroundMoonlight => '银河背景';

  @override
  String get storeItemDescBackgroundMoonlight => '寧靜银河房间背景。';

  @override
  String get storeItemNameBackgroundSageFrame => '鼠尾草花边背景';

  @override
  String get storeItemDescBackgroundSageFrame => '柔和纸感房间背景，搭配俏皮的鼠尾草色花边。';

  @override
  String get storeItemNameBackgroundLilacFrame => '丁香花边背景';

  @override
  String get storeItemDescBackgroundLilacFrame => '柔和纸感房间背景，搭配轻柔的丁香色花边。';

  @override
  String get storeItemNameBackgroundBubbleSky => '泡泡天空背景';

  @override
  String get storeItemDescBackgroundBubbleSky => '明亮蓝天里漂浮着白云与虹彩泡泡的房间背景。';

  @override
  String get storeItemNameBackgroundStarlitDream => '星梦背景';

  @override
  String get storeItemDescBackgroundStarlitDream => '粉彩行星、云朵与流星交织的梦幻夜空背景。';

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
  String get storeItemNameFurnitureToilet => '馬桶';

  @override
  String get storeItemDescFurnitureToilet => '乾淨的小浴室家具。';

  @override
  String get storeItemNameFurnitureTub => '浴缸';

  @override
  String get storeItemDescFurnitureTub => '適合泡澡的舒適浴缸。';

  @override
  String get storeItemNameEquipmentStrawHat => '草帽';

  @override
  String get storeItemNameEquipmentCrown => '皇冠';

  @override
  String get storeItemNameEquipmentSunglasses => '太阳眼镜';

  @override
  String get storeItemNameEquipmentRibbon => '缎带';

  @override
  String get shopSignInPrompt => '请先登录才能使用商店。';

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
  String get shopTitle => '商店';

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
  String get furnitureInventoryHint =>
      '長按家具可編輯，點擊道具放置，拖曳移動，選取已放置家具後可用底部控制列調整大小，點空白退出。';

  @override
  String get furnitureScaleLabel => '大小';

  @override
  String get furnitureScaleDecrease => '缩小';

  @override
  String get furnitureScaleIncrease => '放大';

  @override
  String get furnitureFlipHorizontal => '左右反轉';

  @override
  String furnitureAvailableCount(Object count) {
    return '可放置 x$count';
  }

  @override
  String get roomInventoryTitle => '房间背包';

  @override
  String get roomDecorCompatibilityTitle => '更新后即可查看最新房间物品';

  @override
  String get roomDecorCompatibilityMessage =>
      '这个房间正在使用较新的宠物、家具或背景。更新 App 后，就可以看到最新共享物品，而不是备用显示。';

  @override
  String get roomDecorHintTitle => '装饰房间';

  @override
  String roomDecorHintBody(Object buttonLabel) {
    return '点一下 $buttonLabel 进入房间修改模式，然后摆放家具或套用背景。';
  }

  @override
  String get inventoryTabFurniture => '家具';

  @override
  String get inventoryTabEquipment => '裝扮';

  @override
  String get backgroundGalleryTab => '背景圖庫';

  @override
  String get backgroundInventoryEmpty => '還沒有背景，去商店看看吧。';

  @override
  String get backgroundInventoryHint => '點擊背景即可套用到房间所有成員。';

  @override
  String get equipmentInventoryHint => '先在這裡預覽造型，再為共享寵物穿上或卸下裝備。';

  @override
  String get equipmentNoneOwned => '你還沒有這個部位可用的裝備。';

  @override
  String get equipmentCopyInUse => '其他宠物使用中';

  @override
  String get equipmentCopyUnavailable =>
      '这件装备的所有数量都已装在其他宠物身上。想同时给多只宠物打扮，请再购买一件。';

  @override
  String get equipmentSlotHead => '頭部';

  @override
  String get equipmentSlotFace => '面部';

  @override
  String get equipmentSlotBody => '身體';

  @override
  String get equipmentSlotBack => '背部';

  @override
  String get equipmentEquipCta => '穿上';

  @override
  String get equipmentUnequipCta => '卸下';

  @override
  String equipmentEquipSuccess(Object itemName) {
    return '已穿上 $itemName！';
  }

  @override
  String equipmentUnequipSuccess(Object slotName) {
    return '已卸下 $slotName 的裝備。';
  }

  @override
  String get backgroundApply => '套用';

  @override
  String get backgroundAppliedLabel => '已套用';

  @override
  String backgroundApplyFailed(Object error) {
    return '套用背景失敗：$error';
  }

  @override
  String get shopSectionBackgrounds => '背景';

  @override
  String get shopSectionEquipment => '裝扮';

  @override
  String get shopSectionItems => '商品';

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
  String get petTicketUseCta => '使用';

  @override
  String get petTicketSelectionTitle => '邀请宠物';

  @override
  String get petTicketSelectionSubtitle => '选一位新伙伴加入这个房间。';

  @override
  String get petTicketSelectionConfirm => '邀请宠物';

  @override
  String petTicketUseSuccess(Object petName) {
    return '$petName 已加入房间！';
  }

  @override
  String get petTicketRoomFull => '这个房间的宠物数量已达上限。';

  @override
  String get multiPetNamingTitle => '欢迎新家人！';

  @override
  String get multiPetNamingSubtitle => '为房间取个新名字，并确认第一只宠物的名字。';

  @override
  String get multiPetNamingRoomLabel => '房间名称';

  @override
  String get multiPetNamingFirstPetLabel => '第一只宠物名称';

  @override
  String get multiPetNamingFirstPetHint => '默认沿用旧的房间名';

  @override
  String get mainPetSwitcherTitle => '选择主宠物';

  @override
  String get equipTargetPickerTitle => '给哪只宠物装备？';

  @override
  String equipTargetPickerCurrentlyWearing(Object sku) {
    return '目前穿戴：$sku';
  }

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
  String get petTypeTigerName => '小老虎';

  @override
  String get petTypeTigerTagline => '帶著條紋氣勢大步前進的小探險家。';

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
  String get petDepartureGuideGoShop => '前往商店';

  @override
  String get petDepartureLetterUnavailableTitle => '宠物还在喔';

  @override
  String get petDepartureLetterUnavailableMessage => '宠物并没有离家出走，现在不需要用到这封信喔。';

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
  String feedAdDoubleRewardClaimed(Object amount) {
    return 'x2 糖果 +$amount';
  }

  @override
  String feedAdDoubleRewardFailed(Object error) {
    return '翻倍奖励领取失敗：$error';
  }

  @override
  String get whatsNew111Title => '稳定性与性能优化';

  @override
  String get whatsNew111Bullet1 => '修复可能导致意外崩溃的关键问题。';

  @override
  String get whatsNew111Bullet2 => '优化聊天消息处理与图片渲染。';

  @override
  String get whatsNew111Bullet3 => '全面提升整体性能，带来更流畅的体验。';

  @override
  String get whatsNew112Title => '房间装饰与@提及';

  @override
  String get whatsNew112Bullet1 => '新增两款卫浴家具：马桶与浴缸。';

  @override
  String get whatsNew112Bullet2 => '现在可左右翻转家具，布置房间更灵活。';

  @override
  String get whatsNew112Bullet3 => '现在可在聊天中@提及房间成员以吸引注意。';

  @override
  String get whatsNew113Title => '操作体验升级';

  @override
  String get whatsNew113Bullet1 => '📸 喂食照片分享更顺畅';

  @override
  String get whatsNew113Bullet2 => '🔘 按钮全新设计，手感更好';

  @override
  String get whatsNew113Bullet3 => '🛍️ 购物更快速流畅';

  @override
  String get whatsNew114Title => '问题修复';

  @override
  String get whatsNew114Bullet1 => '修复可能导致游戏崩溃的问题。';

  @override
  String get whatsNew120Title => '聊天与分享升级';

  @override
  String get whatsNew120Bullet1 => '✏️ 可在聊天室编辑或删除消息';

  @override
  String get whatsNew120Bullet2 => '🔗 改善邀请链接分享——更可靠，错误更少';

  @override
  String get whatsNew120Bullet3 => '💡 新功能请求：直接在 App 内分享你的想法';

  @override
  String get whatsNew130Title => '宠物装扮登场';

  @override
  String get whatsNew130Bullet1 => '现在可以为宠物穿戴装备。';

  @override
  String get whatsNew130Bullet2 => '商店新增草帽装备。';

  @override
  String get whatsNew130Bullet3 => '宠物预览与房间库存显示更加顺畅清楚。';

  @override
  String get whatsNew140Title => '更多宠物造型';

  @override
  String get whatsNew140Bullet1 => '商店新增皇冠、太阳眼镜与缎带装备。';

  @override
  String get whatsNew140Bullet2 => '装备预览会依照不同宠物显示得更自然。';

  @override
  String get whatsNew140Bullet3 => '共享房间、库存与商店的装备显示更加清楚。';

  @override
  String get whatsNew200Title => '一起养更多宠物';

  @override
  String get whatsNew200Bullet1 => '使用宠物票券在共享房间加入新宠物。';

  @override
  String get whatsNew200Bullet2 => '随时切换目前显示的主宠物。';

  @override
  String get whatsNew200Bullet3 => '为每只宠物分别穿搭装备。';

  @override
  String get whatsNew201Title => '照片分享更顺畅';

  @override
  String get whatsNew201Bullet1 => '可撤回已发出的动态照片。';

  @override
  String get whatsNew201Bullet2 => '改善头像与照片显示。';

  @override
  String get whatsNew201Bullet3 => '提升稳定性与操作手感。';
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
    return '糖果 +$count';
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
  String get chatEditAction => '編輯';

  @override
  String get chatDeleteAction => '刪除';

  @override
  String get chatMessageCopied => '已複製訊息。';

  @override
  String get chatEditMessageTitle => '編輯訊息';

  @override
  String get chatDeleteMessageTitle => '刪除訊息';

  @override
  String get chatDeleteMessageConfirm => '這則訊息會改為「已刪除」提示，原內容不會再顯示。';

  @override
  String get chatMessageEdited => '已編輯';

  @override
  String get chatMessageDeleted => '訊息已刪除';

  @override
  String get chatEditNoChanges => '沒有需要儲存的變更。';

  @override
  String chatEditFailed(Object error) {
    return '編輯失敗：$error';
  }

  @override
  String chatDeleteFailed(Object error) {
    return '刪除失敗：$error';
  }

  @override
  String get chatNoOlderMessages => '沒有更早的訊息。';

  @override
  String get chatPartnerLabel => '對方';

  @override
  String get chatReplyAction => '回覆';

  @override
  String get chatMoreReactionsAction => '更多';

  @override
  String get chatAllEmojiAction => '全部表情';

  @override
  String chatReactionCount(int count) {
    return '$count 個表情反應';
  }

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
  String get commonBuyMore => '繼續購買';

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
  String get drawerDebugCategorySimulation => '模擬與測試';

  @override
  String get drawerDebugCategoryUser => '用戶與計畫';

  @override
  String get drawerDebugCategoryPet => '寵物狀態';

  @override
  String get drawerDebugCategoryMemory => '記憶體診斷';

  @override
  String get drawerDebugCategorySystem => '更新與系統';

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
  String get drawerDebugTestProfileSetupOnboarding => '測試個人資料設定';

  @override
  String get drawerDebugTestProfileSetupOnboardingSubtitle =>
      '立即打開新用戶改名與上傳照片步驟';

  @override
  String get drawerDebugHungerDown => '寵物飢餓度 -10';

  @override
  String get drawerDebugHungerUp => '寵物飽食度 +20';

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
  String get feedRecallPhotoAction => '收回';

  @override
  String get feedRecallPhotoTitle => '收回照片';

  @override
  String get feedRecallPhotoConfirm => '這張照片將對所有人刪除。金幣和寵物吃的飯都會保留。';

  @override
  String feedRecallPhotoFailed(Object error) {
    return '收回失敗：$error';
  }

  @override
  String get feedRewardPending => '獎勵計算中...';

  @override
  String get crashRecoveryAction => '知道了';

  @override
  String get crashRecoveryMessage =>
      '遊戲剛才似乎異常中斷，請關閉 App 後重新開啟再試一次。若問題持續，請稍後再試。';

  @override
  String get crashRecoveryPetCaption => '小寵物先陪你休息一下。';

  @override
  String get crashRecoveryPetSemanticLabel => '正在休息的小寵物';

  @override
  String get crashRecoveryTitle => '遊戲發生錯誤';

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
  String get whatsNewSuggestFeatureAction => '建議新功能';

  @override
  String get whatsNewSuggestFeatureTitle => '你希望有什麼新功能？';

  @override
  String get whatsNewSuggestFeaturePlaceholder => '描述您的想法...';

  @override
  String get whatsNewSuggestFeatureSubmit => '發送';

  @override
  String get whatsNewSuggestFeatureSuccess => '感謝您的建議！';

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
  String get whatsNew110Title => '老虎寵物登場與家具縮放';

  @override
  String get whatsNew110Bullet1 => '全新「老虎」寵物加入！快來領養你們的新夥伴。';

  @override
  String get whatsNew110Bullet2 => '商店新增多款精美背景，快來佈置你們的家。';

  @override
  String get whatsNew110Bullet3 => '點選已放置家具後，可用底部尺寸控制列精準調整大小。';

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
  String get profileAvatarEditorHint => '拖曳調整位置，雙指縮放。';

  @override
  String get profileAvatarEditorZoom => '縮放';

  @override
  String get profileAvatarEditorCenter => '置中';

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
  String get roomInviteCopyCodeAction => '複製';

  @override
  String get roomInviteShareAction => '分享';

  @override
  String get roomInviteShareCaption => '來 PetTomo 和我一起玩';

  @override
  String roomInviteShareFailed(Object error) {
    return '分享邀請失敗：$error';
  }

  @override
  String get roomInviteLinkJoining => '正在透過邀請加入房間...';

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
  String get shopEmpty => '商店目前沒有商品。';

  @override
  String get storeIapNotConfigured => '尚未設定 IAP。';

  @override
  String storeIapUnavailable(Object error) {
    return 'IAP 無法使用：$error';
  }

  @override
  String shopLoadFailed(Object error) {
    return '載入商店失敗：$error';
  }

  @override
  String get storeNotEnoughCoins => '糖果不足。';

  @override
  String get storeNotEnoughDiamonds => '鑽石不足。';

  @override
  String storeOwnedCount(Object amount) {
    return '已擁有 x$amount';
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
  String get shopReturnToRoomCta => '返回房間';

  @override
  String get shopReturnToRoomHint => '回到寵物房間後就可以開始佈置。';

  @override
  String storeRestoreFailed(Object error) {
    return '復原失敗：$error';
  }

  @override
  String get storeRestoreTooltip => '恢復購買';

  @override
  String get shopSectionCoinPacks => '糖果包';

  @override
  String get shopSectionCoinShop => '糖果商店';

  @override
  String get shopSectionDiamondPacks => '鑽石包';

  @override
  String get shopSectionDiamondShop => '鑽石商店';

  @override
  String get shopSectionSubscription => '訂閱';

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
  String get storePremiumBenefitUnlimitedRooms => '房間數量無上限';

  @override
  String get storePremiumBenefitNoAds => '廣告全面移除';

  @override
  String get storePremiumBenefitExclusiveItems => '解鎖專屬商品';

  @override
  String get storeItemNameDiamondPack300 => '300 鑽石包';

  @override
  String get storeItemDescDiamondPack300 => '一次性 300 鑽石。';

  @override
  String get storeItemNameCandyPack500 => '500 糖果包';

  @override
  String get storeItemDescCandyPack500 => '使用 50 鑽石兌換 500 糖果。';

  @override
  String get storeItemNameReturnLetter => '回家信';

  @override
  String get storeItemDescReturnLetter => '召回離開的寵物。';

  @override
  String get storeItemNamePetTicket => '寵物券';

  @override
  String get storeItemDescPetTicket => '邀請另一隻寵物加入這個房間。';

  @override
  String get storeItemNameBackgroundDefault => '預設背景';

  @override
  String get storeItemDescBackgroundDefault => '原始溫馨房間背景。';

  @override
  String get storeItemNameBackgroundMoonlight => '銀河背景';

  @override
  String get storeItemDescBackgroundMoonlight => '寧靜銀河房間背景。';

  @override
  String get storeItemNameBackgroundSageFrame => '鼠尾草花邊背景';

  @override
  String get storeItemDescBackgroundSageFrame => '柔和紙感房間背景，搭配俏皮的鼠尾草色花邊。';

  @override
  String get storeItemNameBackgroundLilacFrame => '丁香花邊背景';

  @override
  String get storeItemDescBackgroundLilacFrame => '柔和紙感房間背景，搭配輕柔的丁香色花邊。';

  @override
  String get storeItemNameBackgroundBubbleSky => '泡泡天空背景';

  @override
  String get storeItemDescBackgroundBubbleSky => '明亮藍天裡漂浮著白雲與虹彩泡泡的房間背景。';

  @override
  String get storeItemNameBackgroundStarlitDream => '星夢背景';

  @override
  String get storeItemDescBackgroundStarlitDream => '粉彩行星、雲朵與流星交織的夢幻夜空背景。';

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
  String get storeItemNameFurnitureToilet => '馬桶';

  @override
  String get storeItemDescFurnitureToilet => '乾淨的小浴室家具。';

  @override
  String get storeItemNameFurnitureTub => '浴缸';

  @override
  String get storeItemDescFurnitureTub => '適合泡澡的舒適浴缸。';

  @override
  String get storeItemNameEquipmentStrawHat => '草帽';

  @override
  String get storeItemNameEquipmentCrown => '皇冠';

  @override
  String get storeItemNameEquipmentSunglasses => '太陽眼鏡';

  @override
  String get storeItemNameEquipmentRibbon => '緞帶';

  @override
  String get shopSignInPrompt => '請先登入才能使用商店。';

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
  String get shopTitle => '商店';

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
  String get furnitureInventoryHint => '點擊家具即可放置。選取已放置家具後可移動、調整大小或左右反轉。';

  @override
  String get furnitureScaleLabel => '大小';

  @override
  String get furnitureScaleDecrease => '縮小';

  @override
  String get furnitureScaleIncrease => '放大';

  @override
  String get furnitureFlipHorizontal => '左右反轉';

  @override
  String furnitureAvailableCount(Object count) {
    return '可放置 x$count';
  }

  @override
  String get roomInventoryTitle => '房間背包';

  @override
  String get roomDecorCompatibilityTitle => '更新後即可查看最新房間物品';

  @override
  String get roomDecorCompatibilityMessage =>
      '這個房間正在使用較新的寵物、家具或背景。更新 App 後，就可以看到最新共享物品，而不是替代顯示。';

  @override
  String get roomDecorHintTitle => '裝飾房間';

  @override
  String roomDecorHintBody(Object buttonLabel) {
    return '點一下 $buttonLabel 進入房間修改模式，然後擺放家具或套用背景。';
  }

  @override
  String get inventoryTabFurniture => '家具';

  @override
  String get inventoryTabEquipment => '裝扮';

  @override
  String get backgroundGalleryTab => '背景圖庫';

  @override
  String get backgroundInventoryEmpty => '還沒有背景，去商店看看吧。';

  @override
  String get backgroundInventoryHint => '點擊背景即可套用到房間所有成員。';

  @override
  String get equipmentInventoryHint => '先在這裡預覽造型，再為共享寵物穿上或卸下裝備。';

  @override
  String get equipmentNoneOwned => '你還沒有這個部位可用的裝備。';

  @override
  String get equipmentCopyInUse => '其他寵物使用中';

  @override
  String get equipmentCopyUnavailable =>
      '這件裝備的所有數量都已裝在其他寵物身上。想同時幫多隻寵物打扮，請再購買一件。';

  @override
  String get equipmentSlotHead => '頭部';

  @override
  String get equipmentSlotFace => '面部';

  @override
  String get equipmentSlotBody => '身體';

  @override
  String get equipmentSlotBack => '背部';

  @override
  String get equipmentEquipCta => '穿上';

  @override
  String get equipmentUnequipCta => '卸下';

  @override
  String equipmentEquipSuccess(Object itemName) {
    return '已穿上 $itemName！';
  }

  @override
  String equipmentUnequipSuccess(Object slotName) {
    return '已卸下$slotName。';
  }

  @override
  String get backgroundApply => '套用';

  @override
  String get backgroundAppliedLabel => '已套用';

  @override
  String backgroundApplyFailed(Object error) {
    return '套用背景失敗：$error';
  }

  @override
  String get shopSectionBackgrounds => '背景';

  @override
  String get shopSectionItems => '商品';

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
  String get petTicketUseCta => '使用';

  @override
  String get petTicketSelectionTitle => '邀請寵物';

  @override
  String get petTicketSelectionSubtitle => '選一位新夥伴加入這個房間。';

  @override
  String get petTicketSelectionConfirm => '邀請寵物';

  @override
  String petTicketUseSuccess(Object petName) {
    return '$petName 已加入房間！';
  }

  @override
  String get petTicketRoomFull => '這個房間的寵物數量已達上限。';

  @override
  String get multiPetNamingTitle => '歡迎新家人！';

  @override
  String get multiPetNamingSubtitle => '為房間取個新名字，並確認第一隻寵物的名字。';

  @override
  String get multiPetNamingRoomLabel => '房間名稱';

  @override
  String get multiPetNamingFirstPetLabel => '第一隻寵物名稱';

  @override
  String get multiPetNamingFirstPetHint => '預設沿用舊的房間名';

  @override
  String get mainPetSwitcherTitle => '選擇主寵物';

  @override
  String get equipTargetPickerTitle => '幫邊隻寵物著裝？';

  @override
  String equipTargetPickerCurrentlyWearing(Object sku) {
    return '目前著緊：$sku';
  }

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
  String get petTypeTigerName => '小老虎';

  @override
  String get petTypeTigerTagline => '帶著條紋氣勢大步前進的小探險家。';

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
  String get petDepartureGuideGoShop => '前往商店';

  @override
  String get petDepartureLetterUnavailableTitle => '寵物還在喔';

  @override
  String get petDepartureLetterUnavailableMessage => '寵物並沒有離家出走，現在不需要用到這封信喔。';

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
  String feedAdDoubleRewardClaimed(Object amount) {
    return 'x2 糖果 +$amount';
  }

  @override
  String feedAdDoubleRewardFailed(Object error) {
    return '加倍獎勵領取失敗：$error';
  }

  @override
  String get whatsNew111Title => '穩定性與效能更新';

  @override
  String get whatsNew111Bullet1 => '修復了多項可能導致應用程式崩潰的問題。';

  @override
  String get whatsNew111Bullet2 => '優化了聊天訊息傳送及相片解析流程。';

  @override
  String get whatsNew111Bullet3 => '提升整體執行效能，提供更流暢的使用體驗。';

  @override
  String get whatsNew112Title => '房間佈置與 @ 提及功能';

  @override
  String get whatsNew112Bullet1 => '新增了兩款浴室傢俱：馬桶和浴缸。';

  @override
  String get whatsNew112Bullet2 => '現在可以將傢俱左右翻轉，讓佈置房間更自由靈活。';

  @override
  String get whatsNew112Bullet3 => '現在可以在聊天室中使用 @ 提及功能來提醒房內成員。';

  @override
  String get whatsNew113Title => '操作體驗大升級';

  @override
  String get whatsNew113Bullet1 => '📸 優化餵食相片發送體驗';

  @override
  String get whatsNew113Bullet2 => '🔘 按鈕設計全面換裝，點擊感 UP';

  @override
  String get whatsNew113Bullet3 => '🛍️ 商店購買流程更順滑即時';

  @override
  String get whatsNew114Title => '錯誤修復';

  @override
  String get whatsNew114Bullet1 => '修復了可能導致遊戲崩潰的錯誤。';

  @override
  String get whatsNew120Title => '聊天與分享升級';

  @override
  String get whatsNew120Bullet1 => '✏️ 可以在聊天室編輯或刪除訊息';

  @override
  String get whatsNew120Bullet2 => '🔗 優化邀請連結分享，更穩定可靠';

  @override
  String get whatsNew120Bullet3 => '💡 全新功能建議：直接在 App 提交你的想法';

  @override
  String get whatsNew130Title => '寵物裝扮登場';

  @override
  String get whatsNew130Bullet1 => '現在可以為寵物穿戴裝備。';

  @override
  String get whatsNew130Bullet2 => '商店新增草帽裝備。';

  @override
  String get whatsNew130Bullet3 => '寵物預覽與房間庫存顯示更加順暢清楚。';

  @override
  String get whatsNew140Title => '更多寵物造型';

  @override
  String get whatsNew140Bullet1 => '商店新增皇冠、太陽眼鏡與緞帶裝備。';

  @override
  String get whatsNew140Bullet2 => '裝備預覽會依照不同寵物顯示得更自然。';

  @override
  String get whatsNew140Bullet3 => '共享房間、庫存與商店的裝備顯示更加清楚。';

  @override
  String get whatsNew200Title => '一起養更多寵物';

  @override
  String get whatsNew200Bullet1 => '使用寵物票券在共享房間加入新寵物。';

  @override
  String get whatsNew200Bullet2 => '隨時切換目前顯示的主寵物。';

  @override
  String get whatsNew200Bullet3 => '為每隻寵物分別穿搭裝備。';

  @override
  String get whatsNew201Title => '照片分享更順暢';

  @override
  String get whatsNew201Bullet1 => '可收回已送出的動態照片。';

  @override
  String get whatsNew201Bullet2 => '改善頭像與照片顯示。';

  @override
  String get whatsNew201Bullet3 => '提升穩定性與操作手感。';
}
