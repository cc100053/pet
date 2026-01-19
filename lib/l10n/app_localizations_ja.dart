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
    return '+$countコイン';
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
  String get chatMessageHint => 'メッセージ';

  @override
  String get chatNoOlderMessages => 'これ以上のメッセージはありません。';

  @override
  String get chatPartnerLabel => '相手';

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
  String get chatTitle => 'チャット';

  @override
  String get chatUserAlreadyBlocked => 'ブロック済み';

  @override
  String get chatUserBlocked => 'ユーザーをブロックしました。';

  @override
  String get commonBuy => '購入';

  @override
  String get commonCamera => 'カメラ';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

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
  String currencyJpy(Object amount) {
    return 'JPY $amount';
  }

  @override
  String get drawerCreateRoom => '新しいルームを作成';

  @override
  String get drawerDebugTools => 'デバッグツール';

  @override
  String get drawerForceRefreshPet => 'ペットを強制更新';

  @override
  String get drawerFreePlan => '無料プラン';

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
  String get feedCameraSubtitle => '写真を撮ってラベルを確認してから送信します。';

  @override
  String get feedCameraTitle => 'フィードカメラ';

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
  String get forceUpdateAction => '今すぐ更新';

  @override
  String get forceUpdateLinkError => 'ストアリンクを開けません。';

  @override
  String get forceUpdateMessage => '続行するには新しいバージョンが必要です。今すぐ更新してください。';

  @override
  String get forceUpdateTitle => '更新が必要です';

  @override
  String get languageChineseTraditional => '繁体字中国語';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSystem => 'システム';

  @override
  String get languageSystemSubtitle => '端末の言語に従う';

  @override
  String get languageTitle => '言語';

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
  String get profileUpdated => 'プロフィールを更新しました';

  @override
  String profileUserId(Object id) {
    return 'ユーザーID: $id';
  }

  @override
  String get roomCreatedSuccess => 'ルームを作成しました。ドロワーを確認してください。';

  @override
  String roomCreateFailed(Object error) {
    return 'ルーム作成に失敗しました: $error';
  }

  @override
  String get roomDefaultName => '新しいルーム';

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
  String roomLeaveFailed(Object error) {
    return '退出に失敗しました: $error';
  }

  @override
  String get roomLeaveMessage => '再招待されるまでこのペットにアクセスできません。';

  @override
  String get roomLeaveSuccess => 'ルームから退出しました。';

  @override
  String get roomLeaveTitle => 'ルームを退出しますか？';

  @override
  String get roomLimitReached => '無料枠に達しました（最大2ルーム）。アップグレードしてください。';

  @override
  String roomNewInviteCode(Object code) {
    return '新しい招待コード: $code';
  }

  @override
  String get roomSelectionCreatePet => '新しいペットを作成';

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
    return 'コイン: $amount';
  }

  @override
  String storeCoinsLabel(Object amount) {
    return 'コイン: $amount';
  }

  @override
  String storeCoinsReward(Object amount) {
    return 'コイン +$amount';
  }

  @override
  String get storeEmpty => '現在ストアは空です。';

  @override
  String get storeIapNotConfigured => 'IAP が設定されていません。';

  @override
  String storeIapUnavailable(Object error) {
    return 'IAP を利用できません: $error';
  }

  @override
  String storeLoadFailed(Object error) {
    return 'ストアの読み込みに失敗しました: $error';
  }

  @override
  String get storeNotEnoughCoins => 'コインが足りません。';

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
  String storeRestoreFailed(Object error) {
    return '復元に失敗しました: $error';
  }

  @override
  String get storeRestoreTooltip => '購入を復元';

  @override
  String get storeSectionCoinPacks => 'コインパック';

  @override
  String get storeSectionCoinStore => 'コインストア';

  @override
  String get storeSectionSubscription => 'サブスクリプション';

  @override
  String get storeSignInPrompt => 'ストアを利用するにはサインインしてください。';

  @override
  String get storeSubscribe => '購読する';

  @override
  String get storeSubscriptionActive => '有効';

  @override
  String get storeTitle => 'ストア';

  @override
  String get storeTypeConsumable => '消耗品';

  @override
  String get storeTypeCosmetic => 'コスメ';

  @override
  String get storeTypeSubscription => 'サブスクリプション';
}
