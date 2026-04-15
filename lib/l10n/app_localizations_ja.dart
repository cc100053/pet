// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appleSignInRejected =>
      'Apple サインインが拒否されました。Supabase の Apple プロバイダのクライアントIDを確認してください。';

  @override
  String get authReauthRequired => 'もう一度サインインしてください。';

  @override
  String blockedUserIdTruncated(Object id) {
    return 'ID（省略）: $id';
  }

  @override
  String get blockedUsersEmpty => 'ブロック中のユーザーはいません。';

  @override
  String blockedUsersLoadFailed(Object error) {
    return 'ブロックユーザーの読み込みに失敗しました: $error';
  }

  @override
  String get blockedUsersTitle => 'ブロックしたユーザー';

  @override
  String get blockedUserUnblocked => 'ブロックを解除しました。';

  @override
  String blockedUserUnblockFailed(Object error) {
    return '解除に失敗しました: $error';
  }

  @override
  String get calendarAddMemory => '思い出を追加';

  @override
  String get calendarEarlier => '以前';

  @override
  String get calendarLatestPhoto => '最新の写真';

  @override
  String calendarLoadFailed(Object error) {
    return '思い出の読み込みに失敗しました: $error';
  }

  @override
  String get calendarNoEarlierMemories => '以前の思い出はまだありません。';

  @override
  String get calendarNoMemoriesForDay => 'この日の思い出はありません。';

  @override
  String get calendarNoPhotoYet => 'まだ写真がありません';

  @override
  String get calendarTitle => 'カレンダー';

  @override
  String get calendarToday => '今日';

  @override
  String chatBlockFailed(Object error) {
    return 'ブロックに失敗しました: $error';
  }

  @override
  String get chatBlockUser => 'ユーザーをブロック';

  @override
  String chatCoinsAwarded(Object count) {
    return '+$countキャンディ';
  }

  @override
  String get chatEmptyState => 'まだメッセージがありません。下の入力欄から始めましょう。';

  @override
  String chatLoadBlockedUsersFailed(Object error) {
    return 'ブロックユーザーの読み込みに失敗しました: $error';
  }

  @override
  String chatLoadCacheFailed(Object error) {
    return 'キャッシュの読み込みに失敗しました: $error';
  }

  @override
  String chatLoadMessagesFailed(Object error) {
    return 'メッセージの読み込みに失敗しました: $error';
  }

  @override
  String chatLoadMoreFailed(Object error) {
    return 'さらに読み込めませんでした: $error';
  }

  @override
  String get chatLoadOlderMessages => '過去のメッセージを読み込む';

  @override
  String get chatJumpToLatest => '最新';

  @override
  String get chatMessageHint => 'メッセージ';

  @override
  String get chatCopyAction => 'コピー';

  @override
  String get chatMessageCopied => 'メッセージをコピーしました。';

  @override
  String get chatNoOlderMessages => 'これ以上のメッセージはありません。';

  @override
  String get chatPartnerLabel => '相手';

  @override
  String get chatReplyAction => '返信';

  @override
  String get chatMoreReactionsAction => 'もっと見る';

  @override
  String get chatAllEmojiAction => 'すべての絵文字';

  @override
  String chatReactionCount(int count) {
    return '$count件のリアクション';
  }

  @override
  String chatReplyingTo(Object name) {
    return '$name に返信';
  }

  @override
  String get chatReplyMessageFallback => '元のメッセージ';

  @override
  String get chatReplyPhotoFallback => '写真';

  @override
  String chatRefreshFailed(Object error) {
    return '更新に失敗しました: $error';
  }

  @override
  String chatReportFailed(Object error) {
    return '通報に失敗しました: $error';
  }

  @override
  String get chatReportHint => '理由を簡単に入力してください';

  @override
  String get chatReportMessageTitle => 'メッセージを通報';

  @override
  String get chatReportNoReason => '理由なし';

  @override
  String get chatReportSent => '通報しました。';

  @override
  String chatSendFailed(Object error) {
    return '送信に失敗しました: $error';
  }

  @override
  String get chatSystemUpdate => 'システム通知';

  @override
  String get chatCandyLabel => 'キャンディ';

  @override
  String chatCleanPoopMessage(Object name, Object amount) {
    return '$nameがうんちを掃除した：+$amountキャンディ';
  }

  @override
  String chatPetHungryReminderMessage(Object petName) {
    return '$petNameがお腹を空かせています。ごはんをあげてください！';
  }

  @override
  String chatPetHungryUrgentMessage(Object petName) {
    return '$petNameがとてもお腹を空かせています！今すぐごはんを！';
  }

  @override
  String get chatTitle => 'チャット';

  @override
  String get chatRoomMembersTitle => 'ルームメンバー';

  @override
  String get chatRoomMembersEmpty => 'メンバーが見つかりません。';

  @override
  String chatRoomMembersLoadFailed(Object error) {
    return 'ルームメンバーの読み込みに失敗しました: $error';
  }

  @override
  String get chatRoomMemberRoleOwner => 'オーナー';

  @override
  String get chatRoomMemberYou => 'あなた';

  @override
  String get chatUserAlreadyBlocked => 'ブロック済み';

  @override
  String get chatUserBlocked => 'ユーザーをブロックしました。';

  @override
  String chatMemberCount(num count) {
    return '$count人';
  }

  @override
  String get calendarYesterday => '昨日';

  @override
  String get commonBuy => '購入';

  @override
  String get commonCamera => 'カメラ';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonSkip => 'スキップ';

  @override
  String get onboardingCreatePetPromptTitle => '新しいお部屋に迎えるペットを選ぼう！';

  @override
  String get onboardingRoomEntryPromptTitle => '新しいルームを作成するか、招待コードで参加しよう。';

  @override
  String get onboardingRoomEntryPromptBody =>
      '自分でルームを作るか、コードを入力して友だちのルームに参加できます。';

  @override
  String get onboardingProfileSetupTitle => 'プロフィールを設定しよう';

  @override
  String get onboardingProfileSetupSubtitle =>
      'お友だちに表示される名前を決めましょう。写真は今でも後でも追加できます。';

  @override
  String get onboardingProfileSetupAvatarOptional => '写真はあとでも追加できます';

  @override
  String get onboardingProfileSetupContinue => '続ける';

  @override
  String get onboardingProfileSetupNameRequiredError => '使いたい名前を入力してください。';

  @override
  String get onboardingProfileSetupNameChangeHint => '続ける前に名前を決めてください。';

  @override
  String get commonGallery => 'ギャラリー';

  @override
  String get commonJoin => '参加';

  @override
  String get commonLeave => '退出';

  @override
  String get commonOwned => '所有済み';

  @override
  String get commonReload => '再読み込み';

  @override
  String get commonSave => '保存';

  @override
  String get photoViewerDownloadTooltip => 'ダウンロード';

  @override
  String get photoViewerEmojiAction => '絵文字';

  @override
  String get photoViewerReplyActionTitle => '写真に返信';

  @override
  String get photoViewerReplySendAction => '送信';

  @override
  String get photoViewerReplySent => '返信を送信しました。';

  @override
  String get photoViewerReplySentState => '送信済み';

  @override
  String get photoViewerSavedToGallery => 'フォトライブラリに保存しました。';

  @override
  String get photoViewerSaveFailed => 'フォトライブラリへの保存に失敗しました。';

  @override
  String get commonSend => '送信';

  @override
  String get commonSending => '送信中...';

  @override
  String get commonSignOut => 'サインアウト';

  @override
  String get commonSubmit => '送信';

  @override
  String get commonTryAgain => '再試行';

  @override
  String get commonUnblock => '解除';

  @override
  String get commonUploading => 'アップロード中';

  @override
  String get commonUser => 'ユーザー';

  @override
  String get errorInvalidInviteCode => '招待コードが無効か期限切れです。';

  @override
  String get errorNetwork => '通信エラーです。接続を確認して再試行してください。';

  @override
  String get errorNotFound => '対象のデータが見つかりませんでした。';

  @override
  String get errorPermissionDenied => 'この操作を実行する権限がありません。';

  @override
  String get errorImageTooLarge => '画像サイズが大きすぎます。より小さい画像を選択してください。';

  @override
  String get errorPetNameInvalid => 'そのペット名は使用できません。別の名前を入力してください。';

  @override
  String get errorUnexpected => '問題が発生しました。もう一度お試しください。';

  @override
  String currencyJpy(Object amount) {
    return 'JPY $amount';
  }

  @override
  String get drawerCreateRoom => '新しいルームを作成';

  @override
  String get drawerDebugTools => 'デバッグツール';

  @override
  String get drawerDebugCategorySimulation => 'シミュレーションとテスト';

  @override
  String get drawerDebugCategoryUser => 'ユーザーとプラン';

  @override
  String get drawerDebugCategoryPet => 'ペットのステータス';

  @override
  String get drawerDebugCategoryMemory => 'メモリ診断';

  @override
  String get drawerDebugCategorySystem => 'システムと更新';

  @override
  String get drawerFreePlan => '無料プラン';

  @override
  String get drawerProPlan => 'プロプラン';

  @override
  String get drawerDebugAddCandy => '+100 キャンディ';

  @override
  String get drawerDebugAddDiamonds => '+100 ダイヤ';

  @override
  String get drawerDebugTogglePlan => 'プラン切り替え';

  @override
  String get drawerDebugForceOnboarding => '毎回オンボーディングを表示';

  @override
  String get drawerDebugForceOnboardingEnabled => 'アプリ起動ごとに表示';

  @override
  String get drawerDebugForceOnboardingDisabled => '通常の一回表示動作';

  @override
  String get drawerDebugHungerDown => 'ペット空腹度 -10';

  @override
  String get drawerDebugAddExp => '経験値 +10';

  @override
  String get drawerDebugSpawnPoop => 'うんちさせる';

  @override
  String get drawerDebugShowFullBubble => '「おなかいっぱい！」を表示';

  @override
  String get drawerDebugCaptureMemorySnapshot => 'メモリスナップショットを記録';

  @override
  String get drawerDebugClearImageCacheSnapshot => '画像キャッシュを消去して記録';

  @override
  String get drawerDebugOpenMemoryDiagnostics => 'メモリ診断を開く';

  @override
  String get drawerDebugMemorySnapshotCaptured => 'メモリスナップショットを記録しました。';

  @override
  String get drawerDebugImageCacheCleared => '画像キャッシュを消去してスナップショットを記録しました。';

  @override
  String get drawerDebugTestSoftUpdate => 'ソフト更新ポップアップを確認';

  @override
  String get drawerDebugTestHardUpdate => '必須更新ポップアップを確認';

  @override
  String get drawerDebugTestWhatsNew => 'What\'s New モーダルを確認';

  @override
  String get drawerDebugTestCrashReport => 'クラッシュ報告をテスト';

  @override
  String get debugMemoryDiagnosticsTitle => 'メモリ診断';

  @override
  String get debugMemoryDiagnosticsEmpty => 'まだメモリスナップショットがありません。';

  @override
  String drawerInviteCode(Object code) {
    return 'コード: $code';
  }

  @override
  String get drawerJoinWithCode => '招待コードで参加';

  @override
  String get drawerMyRooms => 'マイルーム';

  @override
  String get drawerNoRooms => 'まだルームがありません。';

  @override
  String get drawerPetError => 'ペットエラー';

  @override
  String get drawerRegenerateInviteCode => '招待コードを再生成';

  @override
  String get drawerSimulateFeed => 'フィードをシミュレーション';

  @override
  String get drawerTestNotification => 'ローカル通知をテスト';

  @override
  String get feedCameraSubtitle => '写真を撮って送信します。';

  @override
  String get feedCameraTitle => 'フィードカメラ';

  @override
  String get feedPickPhotoHint => '写真を選択';

  @override
  String feedCanonicalTags(Object tags) {
    return 'カノニカルタグ: $tags';
  }

  @override
  String get feedCaptionLabel => 'キャプション（任意）';

  @override
  String get feedDetectedLabels => '検出されたラベル';

  @override
  String feedLabelingFailed(Object error) {
    return 'ラベル付けに失敗しました: $error';
  }

  @override
  String get feedLabelingNotSupported => 'Web では ML Kit の画像ラベリングは利用できません。';

  @override
  String feedLabelMappingsFailed(Object error) {
    return 'ラベルマッピングの読み込みに失敗しました: $error';
  }

  @override
  String get feedLabelMappingsLoading => 'ラベルマッピングを読み込み中...';

  @override
  String get feedLabelMappingsReady => 'ラベルマッピング準備完了。';

  @override
  String get feedLabelMappingsUnavailable => 'ラベルマッピングを利用できません。';

  @override
  String get feedNoLabels => 'まだラベルは検出されていません。';

  @override
  String feedResponse(Object response) {
    return '応答: $response';
  }

  @override
  String get feedSelectImageFirst => 'まず画像を選択してください。';

  @override
  String get feedSendButton => 'フィードを送信';

  @override
  String feedSendFailed(Object error) {
    return '送信に失敗しました: $error';
  }

  @override
  String get feedTitle => 'フィード';

  @override
  String feedUploadFailed(Object error) {
    return 'フィードのアップロードに失敗しました: $error';
  }

  @override
  String get feedRewardPending => '報酬を計算中...';

  @override
  String get forceUpdateAction => '今すぐ更新';

  @override
  String get forceUpdateLinkError => 'ストアリンクを開けません。';

  @override
  String get forceUpdateMessage => '続行するには新しいバージョンが必要です。今すぐ更新してください。';

  @override
  String get forceUpdateTitle => '更新が必要です';

  @override
  String get softUpdateAction => '更新する';

  @override
  String get softUpdateLater => 'あとで';

  @override
  String get softUpdateMessage => 'より快適に共同育成を続けるために、新しいバージョンへ更新してください。';

  @override
  String get softUpdateTitle => 'アップデートがあります';

  @override
  String get whatsNewDialogTitle => 'バージョンアップデート';

  @override
  String get whatsNewContinueAction => '続ける';

  @override
  String get whatsNewContentLabel => '更新内容';

  @override
  String get whatsNewHighlightsLabel => 'このバージョンの主な変更';

  @override
  String whatsNewVersionLabel(Object version) {
    return 'バージョン $version';
  }

  @override
  String get whatsNew105Title => '安定性とセキュリティの向上';

  @override
  String get whatsNew105Bullet1 => '安定性向上のためのセキュリティ強化。';

  @override
  String get whatsNew105Bullet2 => '軽微な不具合の修正と改善。';

  @override
  String get whatsNew105Bullet3 => '';

  @override
  String get whatsNew106Title => 'ショップのリニューアルと安定性の向上';

  @override
  String get whatsNew106Bullet1 => 'ショップページのデザインを一新';

  @override
  String get whatsNew106Bullet2 => 'アプリの安定性とパフォーマンスを向上';

  @override
  String get whatsNew106Bullet3 => '軽微な不具合の修正';

  @override
  String get whatsNew110Title => '新ペット「トラ」登場＆家具のサイズ調整';

  @override
  String get whatsNew110Bullet1 => '新しいペット「トラ」が登場！お部屋に迎えてみましょう。';

  @override
  String get whatsNew110Bullet2 => 'ショップに新しい背景が追加されました。';

  @override
  String get whatsNew110Bullet3 => '配置した家具をタップすると、下部のサイズコントロールで細かく調整できます。';

  @override
  String get languageChineseSimplified => '簡体字中国語';

  @override
  String get languageChineseTraditional => '繁体字中国語';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '韓国語';

  @override
  String get languageSystem => 'システム';

  @override
  String get languageSystemSubtitle => '端末の言語に従う';

  @override
  String get languageTitle => '言語';

  @override
  String get launchAppName => 'ぺットモ';

  @override
  String get launchTagline => '思い出を共有して、一緒に育てよう。';

  @override
  String get moodHigh => '最高';

  @override
  String get moodLow => '低い';

  @override
  String get moodMid => 'いい';

  @override
  String get moodNeutral => '普通';

  @override
  String get moodSad => '元気なし';

  @override
  String petActionFailed(Object error) {
    return '操作に失敗しました: $error';
  }

  @override
  String get petHomeTitle => 'ペットの家';

  @override
  String get petNameEditTitle => 'ペット名を編集';

  @override
  String get petNameLabel => 'ペット名';

  @override
  String get petNameHint => 'ペット名を入力';

  @override
  String get petNameEmptyError => '名前を入力してください。';

  @override
  String petNameUpdateFailed(Object error) {
    return 'ペット名を更新できませんでした: $error';
  }

  @override
  String chatPetRenamedMessage(Object user, Object oldName, Object petName) {
    return '$userがペットの名前を$oldNameから$petNameに変更した。';
  }

  @override
  String chatBoughtFurnitureMessage(Object user, Object petName) {
    return '$userが$petNameのために家具を買った。';
  }

  @override
  String chatBoughtBackgroundMessage(Object user, Object petName) {
    return '$userが$petNameのために背景を買った。';
  }

  @override
  String chatBoughtStoreItemMessage(
    Object user,
    Object itemName,
    Object petName,
  ) {
    return '$userが$petNameに$itemNameを買いました。';
  }

  @override
  String get petNameUnnamed => '名前なし';

  @override
  String get petNotFound => 'ペットが見つかりません。';

  @override
  String petSyncFailed(Object error) {
    return 'ペット同期エラー: $error';
  }

  @override
  String get photoLabel => '写真';

  @override
  String get profileDefaultNickname => 'ペットの親';

  @override
  String get profileEmpty => 'プロフィールがありません。';

  @override
  String profileLoadFailed(Object error) {
    return 'プロフィールの読み込みに失敗しました: $error';
  }

  @override
  String get profileNicknameLabel => 'ニックネーム';

  @override
  String get profileTitle => 'プロフィール';

  @override
  String get profileSectionAccount => 'アカウント';

  @override
  String get profileSectionAbout => 'サポートと情報';

  @override
  String get profileFeedbackEncouragement =>
      'ご意見やご要望をぜひお寄せください。いただいた内容の実現に向けて、できる限り対応していきます。';

  @override
  String get profileFeedback => 'フィードバックを送る';

  @override
  String get profileVersionPrefix => 'バージョン：';

  @override
  String get profileSectionDangerZone => '危険エリア';

  @override
  String get profileUpdated => 'プロフィールを更新しました';

  @override
  String get profileAvatarTitle => 'アバターを選択';

  @override
  String get profileAvatarEdit => 'アバターを編集';

  @override
  String get profileAvatarUpload => '写真をアップロード';

  @override
  String get profileAvatarAdjustCurrent => '現在の写真を調整';

  @override
  String get profileAvatarAdjustUnavailable => '調整できるアップロード済み写真がありません。';

  @override
  String get profileAvatarAdjustUnsupportedPlatform =>
      'このプラットフォームでは現在の写真調整に対応していません。';

  @override
  String get profileAvatarRemove => '削除';

  @override
  String profileCoinsLabel(Object amount) {
    return 'キャンディ: $amount';
  }

  @override
  String get profileDeleteAccountSectionTitle => 'アカウント削除';

  @override
  String get profileDeleteAccountSectionBody =>
      'アカウントを完全に削除します。共有ルームとペットは他のメンバーに引き継がれます。';

  @override
  String get profileDeleteAccountAction => 'アカウントを削除';

  @override
  String get profileDeleteAccountTitle => 'アカウントを削除しますか？';

  @override
  String get profileDeleteAccountConfirmBody =>
      'アカウントと個人データを完全に削除します。共有ルーム／ペットは保持され、所有権は他のメンバーに移ります。この操作は取り消せません。';

  @override
  String get profileDeleteAccountConfirmAction => '削除';

  @override
  String profileDeleteFailed(Object error) {
    return 'アカウント削除に失敗しました: $error';
  }

  @override
  String profileUserId(Object id) {
    return 'ユーザーID: $id';
  }

  @override
  String get drawerProfile => 'プロフィール';

  @override
  String get roomCreatedSuccess => 'ルームを作成しました。ドロワーを確認してください。';

  @override
  String roomCreateFailed(Object error) {
    return 'ルーム作成に失敗しました: $error';
  }

  @override
  String get roomCreateTitle => 'ルームを作成';

  @override
  String get roomCreateAction => '作成';

  @override
  String get roomNameLabel => 'ルーム名';

  @override
  String get roomNameHint => 'ルーム名';

  @override
  String get roomNameEmptyError => 'ルーム名を入力してください。';

  @override
  String roomNameUpdateFailed(Object error) {
    return 'ルーム名を更新できませんでした: $error';
  }

  @override
  String get roomOptionsTitle => 'ルームオプション';

  @override
  String get roomOptionRename => 'ルーム名を変更';

  @override
  String get roomOptionLeave => 'ルームを退出';

  @override
  String get roomRenameTitle => 'ルーム名を変更';

  @override
  String get roomRenameMessage => '新しいルーム名を入力してください。';

  @override
  String get roomDefaultName => '新しいルーム';

  @override
  String get roomInviteCta => '招待';

  @override
  String get roomInventoryCta => '在庫';

  @override
  String get roomInvitePromptTitle => '誰かを招待';

  @override
  String get roomInvitePromptBody => 'あなた一人だけです。コードを生成して招待しましょう。';

  @override
  String get roomInvitePromptAction => 'コードを生成';

  @override
  String get roomInvitePromptGenerating => '生成中...';

  @override
  String get roomInviteCodeTitle => '招待コード';

  @override
  String get roomInviteCodeMessage => 'このコードを共有してルームに招待してください。';

  @override
  String get roomInviteCodeTapHint => 'コードをタップするとコピーできます。';

  @override
  String get roomInviteCodeCopiedTitle => 'コピーしました';

  @override
  String get roomInviteCodeCopiedMessage => '今すぐ友だちを招待して、いっしょにペットを育てましょう！';

  @override
  String get roomInviteCodeRegenerated => '招待コードを再生成しました。';

  @override
  String roomInviteCodeRegenerateFailed(Object error) {
    return 'コードの再生成に失敗しました: $error';
  }

  @override
  String roomJoinFailed(Object error) {
    return 'ルーム参加に失敗しました: $error';
  }

  @override
  String get roomJoinHelper => '招待コードは大文字小文字を区別しません。';

  @override
  String get roomJoinHint => '6桁のコードを入力';

  @override
  String get roomJoinSuccess => 'ルームに参加しました。';

  @override
  String get roomJoinTitle => 'ルームに参加';

  @override
  String get roomEnteringLoading => 'ルームに入室中';

  @override
  String roomLeaveFailed(Object error) {
    return '退出に失敗しました：$error';
  }

  @override
  String roomLeaveMessage(Object name) {
    return '$name から退出し、チャットとペットにアクセスできなくなります。';
  }

  @override
  String get roomLeaveSuccess => 'ルームを退出しました。';

  @override
  String get roomLeaveTitle => 'ルームを退出しますか？';

  @override
  String get roomLimitReached => '無料枠に達しました（最大2ルーム）。アップグレードしてください。';

  @override
  String roomNewInviteCode(Object code) {
    return '新しい招待コード: $code';
  }

  @override
  String get roomSelectionCreatePet => '新しいルームを作成';

  @override
  String get roomSelectionCreating => '作成中...';

  @override
  String get roomSelectionEmptySlot => '空きスロット';

  @override
  String get roomSelectionEnterInvite => '招待コードを入力';

  @override
  String get roomSelectionJoining => '参加中...';

  @override
  String get roomSelectionRoomFallback => 'ルーム';

  @override
  String get roomSelectionSubtitle => 'ペットの家を選んで戻りましょう。';

  @override
  String get roomSelectionTitle => 'ルーム選択';

  @override
  String get signInFailed => 'サインインに失敗しました。もう一度お試しください。';

  @override
  String get signInNote => '注: Supabase で OAuth プロバイダの設定が必要です。';

  @override
  String get signInOpening => 'サインイン画面を開いています...';

  @override
  String signInOpeningProvider(Object provider) {
    return '$provider を開いています...';
  }

  @override
  String get signInSubtitle => 'サインインして一緒に育て始めましょう。';

  @override
  String get signInWithApple => 'Apple で続行';

  @override
  String get signInWithGoogle => 'Google で続行';

  @override
  String storeCoinPrice(Object amount) {
    return 'キャンディ: $amount';
  }

  @override
  String storeCoinsLabel(Object amount) {
    return 'キャンディ: $amount';
  }

  @override
  String storeCoinsReward(Object amount) {
    return 'キャンディ +$amount';
  }

  @override
  String storeDiamondsLabel(Object amount) {
    return 'ダイヤ: $amount';
  }

  @override
  String storeDiamondsReward(Object amount) {
    return 'ダイヤ +$amount';
  }

  @override
  String get shopEmpty => '現在ショップは空です。';

  @override
  String get storeIapNotConfigured => 'IAP が設定されていません。';

  @override
  String storeIapUnavailable(Object error) {
    return 'IAP を利用できません: $error';
  }

  @override
  String shopLoadFailed(Object error) {
    return 'ショップの読み込みに失敗しました: $error';
  }

  @override
  String get storeNotEnoughCoins => 'キャンディが足りません。';

  @override
  String get storeNotEnoughDiamonds => 'ダイヤが足りません。';

  @override
  String storeOwnedCount(Object amount) {
    return '所持数: $amount';
  }

  @override
  String get storePriceUnavailable => '価格情報がありません';

  @override
  String get storeProductNotFound => 'RevenueCat に商品が見つかりません。';

  @override
  String get storeProductUnavailable => '商品を利用できません。';

  @override
  String storePurchaseFailed(Object error) {
    return '購入に失敗しました: $error';
  }

  @override
  String storePurchaseSuccess(Object name) {
    return '$name を購入しました。';
  }

  @override
  String get shopReturnToRoomCta => 'ルームに戻る';

  @override
  String get shopReturnToRoomHint => 'ペットルームに戻って模様替えを始めましょう。';

  @override
  String storeRestoreFailed(Object error) {
    return '復元に失敗しました: $error';
  }

  @override
  String get storeRestoreTooltip => '購入を復元';

  @override
  String get shopSectionCoinPacks => 'キャンディパック';

  @override
  String get shopSectionCoinShop => 'キャンディショップ';

  @override
  String get shopSectionDiamondPacks => 'ダイヤパック';

  @override
  String get shopSectionDiamondShop => 'ダイヤショップ';

  @override
  String get shopSectionSubscription => 'サブスクリプション';

  @override
  String get storeTabPremium => 'プレミアム';

  @override
  String get storeTabFurniture => '家具';

  @override
  String get storeTabThemes => 'テーマ';

  @override
  String get storeThemePreviewAction => 'プレビュー';

  @override
  String storeThemePreviewTitle(Object name) {
    return '$name のプレビュー';
  }

  @override
  String get storeItemNameProMonthly => 'Pro 月額メンバーシップ';

  @override
  String get storeItemDescProMonthly => '広告なし、ルーム作成が無制限に。快適なペットライフを楽しもう。';

  @override
  String get storePremiumBenefitUnlimitedRooms => 'ルーム作成が無制限';

  @override
  String get storePremiumBenefitNoAds => '広告なしで快適に';

  @override
  String get storePremiumBenefitExclusiveItems => '限定アイテムの解放';

  @override
  String get storeItemNameDiamondPack300 => '300ダイヤパック';

  @override
  String get storeItemDescDiamondPack300 => '一度の購入で300ダイヤをすぐ獲得できます。';

  @override
  String get storeItemNameReturnLetter => 'おかえりの手紙';

  @override
  String get storeItemDescReturnLetter => '旅立ったペットを呼び戻します。';

  @override
  String get storeItemNameBackgroundDefault => 'デフォルト背景';

  @override
  String get storeItemDescBackgroundDefault => '元の落ち着いた部屋の背景。';

  @override
  String get storeItemNameBackgroundMoonlight => '銀河';

  @override
  String get storeItemDescBackgroundMoonlight => '銀河の静かな部屋背景。';

  @override
  String get storeItemNameBackgroundSageFrame => 'セージフレーム背景';

  @override
  String get storeItemDescBackgroundSageFrame =>
      'やわらかな紙の質感に、遊び心のあるセージ色のふちを合わせた背景。';

  @override
  String get storeItemNameBackgroundLilacFrame => 'ライラックフレーム背景';

  @override
  String get storeItemDescBackgroundLilacFrame =>
      'やわらかな紙の質感に、やさしいライラック色のふちを合わせた背景。';

  @override
  String get storeItemNameBackgroundBubbleSky => 'バブルスカイ背景';

  @override
  String get storeItemDescBackgroundBubbleSky => '雲ときらめくシャボン玉が浮かぶ、明るい青空の背景。';

  @override
  String get storeItemNameBackgroundStarlitDream => 'スターリットドリーム背景';

  @override
  String get storeItemDescBackgroundStarlitDream =>
      'パステルの惑星と雲、流れ星が広がる夢みたいな夜空の背景。';

  @override
  String get storeItemNameFurnitureSofa => 'ソファ';

  @override
  String get storeItemDescFurnitureSofa => '座り心地のよいソファ。';

  @override
  String get storeItemNameFurniturePlant => '観葉植物';

  @override
  String get storeItemDescFurniturePlant => '部屋の角を彩るグリーン。';

  @override
  String get storeItemNameFurnitureFrame => 'フォトフレーム';

  @override
  String get storeItemDescFurnitureFrame => '写真フレーム。';

  @override
  String get storeItemNameFurnitureTeddy => 'ぬいぐるみ';

  @override
  String get storeItemDescFurnitureTeddy => 'やわらかいぬいぐるみ。';

  @override
  String get storeItemNameFurnitureBricks => 'レンガ';

  @override
  String get storeItemDescFurnitureBricks => 'ブロック調のアクセント。';

  @override
  String get storeItemNameFurnitureTv => 'テレビ';

  @override
  String get storeItemDescFurnitureTv => '小さなテレビ。';

  @override
  String get storeItemNameFurnitureBath => 'バス';

  @override
  String get storeItemDescFurnitureBath => 'ミニバス。';

  @override
  String get storeItemNameFurnitureRibbon => 'リボン';

  @override
  String get storeItemDescFurnitureRibbon => '飾りリボン。';

  @override
  String get shopSignInPrompt => 'ショップを利用するにはサインインしてください。';

  @override
  String get storeSubscribe => '購読する';

  @override
  String get storeSubscriptionActive => '有効';

  @override
  String get storeSubscriptionDurationMonthly => '1か月';

  @override
  String get storeSubscriptionRenewalNote => '毎月自動更新。いつでも解約できます。';

  @override
  String get storeSubscriptionDetailsTitle => 'サブスクリプション詳細';

  @override
  String storeSubscriptionDetailsBody(
    Object title,
    Object duration,
    Object price,
  ) {
    return '名称: $title\n期間: $duration\n価格: $price';
  }

  @override
  String get storePrivacyPolicy => 'プライバシーポリシー';

  @override
  String get storeTermsOfUse => '利用規約';

  @override
  String get storeLegalSeparator => '|';

  @override
  String get storeLegalOpenFailed => '法的リンクを開けませんでした。';

  @override
  String get signInSafetyAgreementLabel =>
      '利用規約とプライバシーポリシーに同意し、不適切なコンテンツや迷惑行為に対して一切の許容がないことを確認します。';

  @override
  String get signInSafetyAgreementRequired =>
      'サインインする前に利用規約とプライバシーポリシーに同意してください。';

  @override
  String get shopTitle => 'ショップ';

  @override
  String get storeTypeConsumable => '消耗品';

  @override
  String get storeTypeCosmetic => 'コスメ';

  @override
  String get storeTypeSubscription => 'サブスクリプション';

  @override
  String get furnitureInventoryTitle => 'ルーム在庫';

  @override
  String get furnitureInventorySubtitle => 'このルームの家具と背景を管理します。';

  @override
  String get furnitureInventoryEmpty => 'まだ家具がありません。ショップで購入してください。';

  @override
  String get furnitureInventoryHint =>
      '家具を長押しで編集。アイテムをタップして配置、ドラッグで移動。配置済みの家具を選ぶと下部コントロールでサイズ調整できます。空白をタップで終了。';

  @override
  String get furnitureScaleLabel => 'サイズ';

  @override
  String get furnitureScaleDecrease => '小さくする';

  @override
  String get furnitureScaleIncrease => '大きくする';

  @override
  String get roomInventoryTitle => 'ルーム在庫';

  @override
  String get roomDecorCompatibilityTitle => '最新のルームアイテムを見るにはアップデート';

  @override
  String get roomDecorCompatibilityMessage =>
      'このルームでは新しいペットや家具、背景が使われています。アプリを更新すると、代替表示ではなく最新の共有アイテムが見られます。';

  @override
  String get roomDecorHintTitle => '部屋を飾ろう';

  @override
  String roomDecorHintBody(Object buttonLabel) {
    return '$buttonLabel をタップしてルーム編集モードに入り、家具を置いたり背景を適用したりしましょう。';
  }

  @override
  String get inventoryTabFurniture => '家具';

  @override
  String get backgroundGalleryTab => '背景ギャラリー';

  @override
  String get backgroundInventoryEmpty => '背景がまだありません。ショップで入手できます。';

  @override
  String get backgroundInventoryHint => '背景をタップするとルーム全員に適用されます。';

  @override
  String get backgroundApply => '適用';

  @override
  String get backgroundAppliedLabel => '適用中';

  @override
  String backgroundApplyFailed(Object error) {
    return '背景の適用に失敗しました: $error';
  }

  @override
  String get shopSectionBackgrounds => '背景';

  @override
  String get shopSectionItems => 'アイテム';

  @override
  String get storeBackgroundRoomRequired => '背景を購入する前にルームを選択してください。';

  @override
  String storeBuyWithCandies(Object price) {
    return '$price キャンディで購入';
  }

  @override
  String storeBuyWithDiamonds(Object price) {
    return '$price ダイヤで購入';
  }

  @override
  String get furnitureEditMode => '家具モード';

  @override
  String get petSelectionTitle => 'ペットを選んで';

  @override
  String get petSelectionSubtitle => 'このルームの相棒を選ぼう。';

  @override
  String get petSelectionHint => 'ペットをタップして進みましょう。';

  @override
  String petSelectionSelected(Object name) {
    return '選択中：$name';
  }

  @override
  String get petSelectionConfirm => 'ルームを始める';

  @override
  String get petSelectionStarterBadge => 'スターター';

  @override
  String petSelectionFailed(Object error) {
    return 'ペットの選択に失敗しました：$error';
  }

  @override
  String get petTypeGhostName => 'ゴースト';

  @override
  String get petTypeGhostTagline => 'おやつが大好きな、恥ずかしがり屋のふわふわ。';

  @override
  String get petTypeCatName => 'ネコ';

  @override
  String get petTypeCatTagline => '好奇心旺盛でゴロゴロ上手。';

  @override
  String get petTypeFishName => 'サカナ';

  @override
  String get petTypeFishTagline => 'ぷくぷく泳ぐ、きらきらスイマー。';

  @override
  String get petTypeTigerName => 'トラ';

  @override
  String get petTypeTigerTagline => 'しま模様で堂々と歩く、ちいさな冒険家。';

  @override
  String get roomLeaveConfirm => '退出する';

  @override
  String get roomLockedBadge => 'LOCKED';

  @override
  String get roomLockedTitle => 'このルームは無料プランでロック中';

  @override
  String get roomLockedMessage =>
      '無料プランでは参加・作成が古い順で最初の2ルームのみ利用できます。Proにアップグレードすると、このルームでもフィードと成長アクションを使えます。';

  @override
  String get petDepartureNoteMessage => 'どうしてこんな扱いをするの…';

  @override
  String get petDepartureGuideTitle => 'ペットからの手紙';

  @override
  String get petDepartureGuideMessage => 'ショップで「手紙」を買って、ペットを呼び戻してください。';

  @override
  String get petDepartureGuideGoShop => 'ショップへ';

  @override
  String get petDepartureLetterUnavailableTitle => 'ペットはまだお家にいます';

  @override
  String get petDepartureLetterUnavailableMessage =>
      'ペットは家出していません。今は手紙は必要ありませんよ。';

  @override
  String get petDepartureLetterSelectTitle => 'ペットを選ぶ';

  @override
  String get petDepartureLetterSelectMessage => 'どのペットを呼び戻しますか？';

  @override
  String petDepartureLetterConfirmTitle(Object petName) {
    return '$petNameを呼び戻す？';
  }

  @override
  String petDepartureLetterConfirmMessage(Object petName) {
    return '手紙を購入して$petNameを家に呼び戻しますか？';
  }

  @override
  String get petDepartureLetterConfirmAction => '手紙を購入';

  @override
  String get petDepartureFeedDisabledTitle => 'ごはんをあげる相手がいません';

  @override
  String get petDepartureFeedDisabledMessage => 'ペットがいないため、今はごはんをあげられません。';

  @override
  String get petOverfedBubble => 'おなかいっぱい！';

  @override
  String get petNameUnknown => 'あなたのペット';

  @override
  String get roomNameUnknown => '不明なルーム';

  @override
  String petReturnFailed(Object error) {
    return 'ペットの復帰に失敗しました: $error';
  }

  @override
  String get storeAdRewardTitle => '広告を見てキャンディ獲得';

  @override
  String storeAdRewardDescription(Object amount) {
    return '短い広告を見てキャンディ +$amount を受け取る。';
  }

  @override
  String get storeAdRewardAction => '見る';

  @override
  String get storeAdRewardLoading => '読み込み中...';

  @override
  String get storeAdRewardUnavailable => '広告を利用できません';

  @override
  String get storeAdRewardDismissed => '報酬前に広告を閉じました。';

  @override
  String get storeAdRewardCooldown => '広告報酬は現在クールダウン中です。';

  @override
  String get storeAdRewardRoomRequired => '広告報酬を受け取るには先にルームを選択してください。';

  @override
  String storeAdRewardFailed(Object error) {
    return '広告報酬の受け取りに失敗しました: $error';
  }

  @override
  String get feedAdDoubleRewardTitle => 'フィード報酬を2倍にしますか？';

  @override
  String feedAdDoubleRewardMessage(Object amount) {
    return '広告を見て +$amount キャンディ追加？';
  }

  @override
  String feedAdDoubleRewardClaimed(Object amount) {
    return 'x2 キャンディ +$amount';
  }

  @override
  String feedAdDoubleRewardFailed(Object error) {
    return '2倍報酬の受け取りに失敗しました: $error';
  }

  @override
  String get whatsNew111Title => '安定性とパフォーマンスの向上';

  @override
  String get whatsNew111Bullet1 => 'アプリが予期せず終了する問題を特定し、修正しました。';

  @override
  String get whatsNew111Bullet2 => 'チャットのメッセージ処理や画像の描画を最適化しました。';

  @override
  String get whatsNew111Bullet3 => '全体的なパフォーマンスを改善し、より快適にご利用いただけます。';
}
