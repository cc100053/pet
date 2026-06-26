// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appleSignInRejected =>
      'Apple 로그인에 실패했습니다. Supabase Apple 제공자 클라이언트 ID를 확인해 주세요.';

  @override
  String get authReauthRequired => '다시 로그인해 주세요.';

  @override
  String blockedUserIdTruncated(Object id) {
    return 'ID(일부): $id';
  }

  @override
  String get blockedUsersEmpty => '차단한 사용자가 아직 없습니다.';

  @override
  String blockedUsersLoadFailed(Object error) {
    return '차단 사용자 불러오기 실패: $error';
  }

  @override
  String get blockedUsersTitle => '차단 사용자';

  @override
  String get blockedUserUnblocked => '사용자 차단을 해제했습니다.';

  @override
  String blockedUserUnblockFailed(Object error) {
    return '차단 해제 실패: $error';
  }

  @override
  String get calendarAddMemory => '추억 추가';

  @override
  String get calendarEarlier => '이전';

  @override
  String get calendarLatestPhoto => '최신 사진';

  @override
  String calendarLoadFailed(Object error) {
    return '추억 불러오기 실패: $error';
  }

  @override
  String get calendarNoEarlierMemories => '이전 추억이 아직 없습니다.';

  @override
  String get calendarNoMemoriesForDay => '이 날짜의 추억이 없습니다.';

  @override
  String get calendarNoPhotoYet => '아직 사진이 없습니다';

  @override
  String get calendarTitle => '캘린더';

  @override
  String get calendarToday => '오늘';

  @override
  String chatBlockFailed(Object error) {
    return '차단 실패: $error';
  }

  @override
  String get chatBlockUser => '사용자 차단';

  @override
  String chatCoinsAwarded(Object count) {
    return '+$count 캔디';
  }

  @override
  String get chatEmptyState => '아직 메시지가 없습니다. 아래에서 채팅을 시작해 보세요.';

  @override
  String chatLoadBlockedUsersFailed(Object error) {
    return '차단 사용자 불러오기 실패: $error';
  }

  @override
  String chatLoadCacheFailed(Object error) {
    return '캐시된 메시지 불러오기 실패: $error';
  }

  @override
  String chatLoadMessagesFailed(Object error) {
    return '메시지 불러오기 실패: $error';
  }

  @override
  String chatLoadMoreFailed(Object error) {
    return '더 불러오기 실패: $error';
  }

  @override
  String get chatLoadOlderMessages => '이전 메시지 불러오기';

  @override
  String get chatJumpToLatest => '최신';

  @override
  String get chatMessageHint => '메시지';

  @override
  String get chatCopyAction => '복사';

  @override
  String get chatEditAction => '수정';

  @override
  String get chatDeleteAction => '삭제';

  @override
  String get chatMessageCopied => '메시지를 복사했어요.';

  @override
  String get chatEditMessageTitle => '메시지 수정';

  @override
  String get chatDeleteMessageTitle => '메시지 삭제';

  @override
  String get chatDeleteMessageConfirm =>
      '이 메시지는 삭제됨 표시로 바뀌며 원문은 더 이상 보이지 않습니다.';

  @override
  String get chatMessageEdited => '수정됨';

  @override
  String get chatMessageDeleted => '메시지가 삭제되었습니다';

  @override
  String get chatEditNoChanges => '저장할 변경 사항이 없습니다.';

  @override
  String chatEditFailed(Object error) {
    return '수정 실패: $error';
  }

  @override
  String chatDeleteFailed(Object error) {
    return '삭제 실패: $error';
  }

  @override
  String get chatNoOlderMessages => '이전 메시지가 없습니다.';

  @override
  String get chatPartnerLabel => '파트너';

  @override
  String get chatReplyAction => '답장';

  @override
  String get chatMoreReactionsAction => '더보기';

  @override
  String get chatAllEmojiAction => '모든 이모지';

  @override
  String chatReactionCount(int count) {
    return '$count개의 리액션';
  }

  @override
  String chatReplyingTo(Object name) {
    return '$name에게 답장';
  }

  @override
  String get chatReplyMessageFallback => '원본 메시지';

  @override
  String get chatReplyPhotoFallback => '사진';

  @override
  String chatRefreshFailed(Object error) {
    return '새로고침 실패: $error';
  }

  @override
  String chatReportFailed(Object error) {
    return '신고 실패: $error';
  }

  @override
  String get chatReportHint => '신고 사유를 간단히 적어주세요';

  @override
  String get chatReportMessageTitle => '메시지 신고';

  @override
  String get chatReportNoReason => '사유 없음';

  @override
  String get chatReportSent => '신고가 접수되었습니다.';

  @override
  String chatSendFailed(Object error) {
    return '전송 실패: $error';
  }

  @override
  String get chatSystemUpdate => '시스템 업데이트';

  @override
  String get chatCandyLabel => '캔디';

  @override
  String chatCleanPoopMessage(Object name, Object amount) {
    return '$name님이 배변을 치웠어요: +$amount 캔디.';
  }

  @override
  String chatPetHungryReminderMessage(Object petName) {
    return '$petName가 배고파하고 있어요. 먹이를 주세요!';
  }

  @override
  String chatPetHungryUrgentMessage(Object petName) {
    return '$petName가 매우 배고파요! 지금 바로 먹이를 주세요!';
  }

  @override
  String get chatTitle => '채팅';

  @override
  String get chatRoomMembersTitle => '방 멤버';

  @override
  String get chatRoomMembersEmpty => '멤버를 찾을 수 없어요.';

  @override
  String chatRoomMembersLoadFailed(Object error) {
    return '방 멤버를 불러오지 못했어요: $error';
  }

  @override
  String get chatRoomMemberRoleOwner => '방장';

  @override
  String get chatRoomMemberYou => '나';

  @override
  String get chatUserAlreadyBlocked => '사용자가 차단되었습니다';

  @override
  String get chatUserBlocked => '사용자를 차단했습니다.';

  @override
  String chatMemberCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count명',
      one: '$count명',
    );
    return '$_temp0';
  }

  @override
  String get calendarYesterday => '어제';

  @override
  String get commonBuy => '구매';

  @override
  String get commonBuyMore => '더 구매';

  @override
  String get commonCamera => '카메라';

  @override
  String get commonCancel => '취소';

  @override
  String get commonClose => '닫기';

  @override
  String get commonSkip => '건너뛰기';

  @override
  String get onboardingCreatePetPromptTitle => '새 방에 함께할 펫을 선택해 주세요!';

  @override
  String get onboardingRoomEntryPromptTitle => '새 방을 만들거나 초대 코드를 입력해 참여해 주세요.';

  @override
  String get onboardingRoomEntryPromptBody =>
      '직접 펫 홈을 만들거나, 코드를 입력해 친구의 방에 들어갈 수 있어요.';

  @override
  String get onboardingProfileSetupTitle => '프로필을 먼저 설정해 주세요';

  @override
  String get onboardingProfileSetupSubtitle =>
      '친구에게 보여질 이름을 정해 주세요. 사진은 지금 올리거나 나중에 추가할 수 있어요.';

  @override
  String get onboardingProfileSetupAvatarOptional => '사진은 나중에 추가해도 돼요';

  @override
  String get onboardingProfileSetupContinue => '계속하기';

  @override
  String get onboardingProfileSetupNameRequiredError => '사용할 이름을 입력해 주세요.';

  @override
  String get onboardingProfileSetupNameChangeHint => '계속하기 전에 이름을 정해 주세요.';

  @override
  String get commonGallery => '갤러리';

  @override
  String get commonJoin => '참여';

  @override
  String get commonLeave => '나가기';

  @override
  String get commonOwned => '보유 중';

  @override
  String get commonReload => '다시 불러오기';

  @override
  String get commonSave => '저장';

  @override
  String get photoViewerDownloadTooltip => '다운로드';

  @override
  String get photoViewerEmojiAction => '이모지';

  @override
  String get photoViewerReplyActionTitle => '사진에 답장';

  @override
  String get photoViewerReplySendAction => '전송';

  @override
  String get photoViewerReplySent => '답장을 보냈어요.';

  @override
  String get photoViewerReplySentState => '보냄';

  @override
  String get photoViewerSavedToGallery => '사진이 갤러리에 저장되었어요.';

  @override
  String get photoViewerSaveFailed => '사진을 갤러리에 저장하지 못했어요.';

  @override
  String get commonSend => '보내기';

  @override
  String get commonSending => '보내는 중...';

  @override
  String get commonSignOut => '로그아웃';

  @override
  String get commonSubmit => '확인';

  @override
  String get commonTryAgain => '다시 시도';

  @override
  String get commonUnblock => '차단 해제';

  @override
  String get commonUploading => '업로드 중';

  @override
  String get commonUser => '사용자';

  @override
  String get errorInvalidInviteCode => '초대 코드가 유효하지 않거나 만료되었습니다.';

  @override
  String get errorNetwork => '네트워크 오류입니다. 연결을 확인한 뒤 다시 시도해 주세요.';

  @override
  String get errorNotFound => '요청한 데이터를 찾을 수 없습니다.';

  @override
  String get errorPermissionDenied => '이 작업을 수행할 권한이 없습니다.';

  @override
  String get errorImageTooLarge => '이미지 용량이 너무 큽니다. 더 작은 이미지를 선택해 주세요.';

  @override
  String get errorPetNameInvalid => '사용할 수 없는 펫 이름입니다. 다른 이름을 사용해 주세요.';

  @override
  String get errorUnexpected => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override
  String currencyJpy(Object amount) {
    return 'JPY $amount';
  }

  @override
  String get drawerCreateRoom => '새 방 만들기';

  @override
  String get drawerDebugTools => '디버그 도구';

  @override
  String get drawerDebugCategorySimulation => '시뮬레이션 및 테스트';

  @override
  String get drawerDebugCategoryUser => '사용자 및 플랜';

  @override
  String get drawerDebugCategoryPet => '펫 상태';

  @override
  String get drawerDebugCategoryMemory => '메모리 진단';

  @override
  String get drawerDebugCategorySystem => '업데이트 및 시스템';

  @override
  String get drawerFreePlan => '무료 플랜';

  @override
  String get drawerProPlan => '프로 플랜';

  @override
  String get drawerDebugAddCandy => '+100 캔디';

  @override
  String get drawerDebugAddDiamonds => '+100 다이아몬드';

  @override
  String get drawerDebugTogglePlan => '플랜 전환';

  @override
  String get drawerDebugForceOnboarding => '온보딩 항상 표시';

  @override
  String get drawerDebugForceOnboardingEnabled => '앱 실행마다 표시';

  @override
  String get drawerDebugForceOnboardingDisabled => '기본 1회 표시 동작';

  @override
  String get drawerDebugTestProfileSetupOnboarding => '프로필 설정 테스트';

  @override
  String get drawerDebugTestProfileSetupOnboardingSubtitle =>
      '신규 사용자 이름 및 사진 단계를 지금 열기';

  @override
  String get drawerDebugHungerDown => '펫 배고픔 -10';

  @override
  String get drawerDebugHungerUp => '펫 배고픔 +20';

  @override
  String get drawerDebugAddExp => 'EXP +10';

  @override
  String get drawerDebugSpawnPoop => '펫 배변 생성';

  @override
  String get drawerDebugShowFullBubble => '\"배불러요\" 말풍선 표시';

  @override
  String get drawerDebugShowSocketOverlay => 'Show Socket Overlay';

  @override
  String get drawerDebugDressUpFitTool => 'Dress-up Fit Tool';

  @override
  String get drawerDebugCaptureMemorySnapshot => '메모리 스냅샷 기록';

  @override
  String get drawerDebugClearImageCacheSnapshot => '이미지 캐시 비우고 기록';

  @override
  String get drawerDebugOpenMemoryDiagnostics => '메모리 진단 열기';

  @override
  String get drawerDebugMemorySnapshotCaptured => '메모리 스냅샷을 기록했습니다.';

  @override
  String get drawerDebugImageCacheCleared => '이미지 캐시를 비우고 스냅샷을 기록했습니다.';

  @override
  String get drawerDebugTestSoftUpdate => '소프트 업데이트 안내 테스트';

  @override
  String get drawerDebugTestHardUpdate => '강제 업데이트 안내 테스트';

  @override
  String get drawerDebugTestWhatsNew => 'What\'s New 모달 미리보기';

  @override
  String get drawerDebugTestCrashReport => '크래시 보고 테스트';

  @override
  String get debugMemoryDiagnosticsTitle => '메모리 진단';

  @override
  String get debugMemoryDiagnosticsEmpty => '아직 기록된 메모리 스냅샷이 없습니다.';

  @override
  String drawerInviteCode(Object code) {
    return '코드: $code';
  }

  @override
  String get drawerJoinWithCode => '초대 코드로 참가';

  @override
  String get drawerMyRooms => '내 방';

  @override
  String get drawerNoRooms => '아직 방이 없습니다.';

  @override
  String get drawerPetError => '펫 오류';

  @override
  String get drawerRegenerateInviteCode => '초대 코드 재생성';

  @override
  String get drawerSimulateFeed => '먹이 주기 시뮬레이션';

  @override
  String get drawerTestNotification => '로컬 알림 테스트';

  @override
  String get feedCameraSubtitle => '먹이 사진을 찍어 보내세요.';

  @override
  String get feedCameraTitle => '먹이 카메라';

  @override
  String get feedPickPhotoHint => '사진 선택';

  @override
  String feedCanonicalTags(Object tags) {
    return '표준 태그: $tags';
  }

  @override
  String get feedCaptionLabel => '캡션(선택)';

  @override
  String get feedDetectedLabels => '감지된 라벨';

  @override
  String feedLabelingFailed(Object error) {
    return '라벨링 실패: $error';
  }

  @override
  String get feedLabelingNotSupported => '웹에서는 ML Kit 이미지 라벨링을 지원하지 않습니다.';

  @override
  String feedLabelMappingsFailed(Object error) {
    return '라벨 매핑 불러오기 실패: $error';
  }

  @override
  String get feedLabelMappingsLoading => '라벨 매핑 불러오는 중...';

  @override
  String get feedLabelMappingsReady => '라벨 매핑 준비 완료.';

  @override
  String get feedLabelMappingsUnavailable => '라벨 매핑을 사용할 수 없습니다.';

  @override
  String get feedNoLabels => '아직 감지된 라벨이 없습니다.';

  @override
  String feedResponse(Object response) {
    return '응답: $response';
  }

  @override
  String get feedSelectImageFirst => '먼저 이미지를 선택해 주세요.';

  @override
  String get feedSendButton => '먹이 보내기';

  @override
  String feedSendFailed(Object error) {
    return '전송 실패: $error';
  }

  @override
  String get feedTitle => '먹이';

  @override
  String feedUploadFailed(Object error) {
    return '먹이 업로드 실패: $error';
  }

  @override
  String get feedRecallPhotoAction => '회수';

  @override
  String get feedRecallPhotoTitle => '사진 회수';

  @override
  String get feedRecallPhotoConfirm =>
      '이 사진은 모두에게서 삭제됩니다. 코인과 반려동물의 먹이는 그대로 유지됩니다.';

  @override
  String feedRecallPhotoFailed(Object error) {
    return '회수 실패: $error';
  }

  @override
  String get feedRewardPending => '보상 계산 중...';

  @override
  String get crashRecoveryAction => '확인';

  @override
  String get crashRecoveryMessage =>
      '게임이 방금 예상치 못하게 중단된 것 같아요. 앱을 닫았다가 다시 열어 시도해 주세요. 문제가 계속되면 잠시 후 다시 시도해 주세요.';

  @override
  String get crashRecoveryPetCaption => '펫이 여기서 함께 쉬고 있어요.';

  @override
  String get crashRecoveryPetSemanticLabel => '쉬고 있는 펫';

  @override
  String get crashRecoveryTitle => '게임 오류가 발생했어요';

  @override
  String get forceUpdateAction => '지금 업데이트';

  @override
  String get forceUpdateLinkError => '스토어 링크를 열 수 없습니다.';

  @override
  String get forceUpdateMessage => '계속하려면 새 버전이 필요합니다. 지금 업데이트해 주세요.';

  @override
  String get forceUpdateTitle => '업데이트 필요';

  @override
  String get softUpdateAction => '업데이트';

  @override
  String get softUpdateLater => '나중에';

  @override
  String get softUpdateMessage => '더 부드러운 공동 돌봄 경험을 위해 새 버전이 제공됩니다.';

  @override
  String get softUpdateTitle => '업데이트 가능';

  @override
  String get whatsNewDialogTitle => '버전 업데이트';

  @override
  String get whatsNewContinueAction => '계속';

  @override
  String get whatsNewSuggestFeatureAction => '기능 제안하기';

  @override
  String get whatsNewSuggestFeatureTitle => '어떤 기능을 원하세요?';

  @override
  String get whatsNewSuggestFeaturePlaceholder => '아이디어를 설명해 주세요...';

  @override
  String get whatsNewSuggestFeatureSubmit => '전송';

  @override
  String get whatsNewSuggestFeatureSuccess => '피드백 감사합니다!';

  @override
  String get whatsNewContentLabel => '업데이트 내용';

  @override
  String get whatsNewHighlightsLabel => '이번 버전의 핵심 변경사항';

  @override
  String whatsNewVersionLabel(Object version) {
    return '버전 $version';
  }

  @override
  String get whatsNew105Title => '안정성 및 보안 업데이트';

  @override
  String get whatsNew105Bullet1 => '더 안정적인 사용을 위한 보안 강화。';

  @override
  String get whatsNew105Bullet2 => '기타 버그 수정 및 개선。';

  @override
  String get whatsNew105Bullet3 => '';

  @override
  String get whatsNew106Title => '상점 개편 및 안정성 최적화';

  @override
  String get whatsNew106Bullet1 => '상점 페이지 디자인 대규모 개편';

  @override
  String get whatsNew106Bullet2 => '앱 안정성 및 성능 향상';

  @override
  String get whatsNew106Bullet3 => '기타 알려진 문제점 수정';

  @override
  String get whatsNew110Title => '새로운 호랑이 펫 & 가구 크기 조절';

  @override
  String get whatsNew110Bullet1 => '새로운 \'호랑이\' 펫이 추가되었습니다! 지금 바로 만나보세요.';

  @override
  String get whatsNew110Bullet2 => '상점에 아름다운 새 배경 테마들이 추가되었습니다.';

  @override
  String get whatsNew110Bullet3 => '배치된 가구를 탭한 뒤 하단 크기 조절 바에서 더 정확하게 조정하세요.';

  @override
  String get languageChineseSimplified => '중국어(간체)';

  @override
  String get languageChineseTraditional => '중국어(번체)';

  @override
  String get languageEnglish => '영어';

  @override
  String get languageJapanese => '일본어';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSystem => '시스템';

  @override
  String get languageSystemSubtitle => '기기 언어 따르기';

  @override
  String get languageTitle => '언어';

  @override
  String get launchAppName => 'PetTomo';

  @override
  String get launchTagline => '순간을 공유하고, 함께 성장해요.';

  @override
  String get moodHigh => '좋음';

  @override
  String get moodLow => '낮음';

  @override
  String get moodMid => '보통';

  @override
  String get moodNeutral => '중립';

  @override
  String get moodSad => '슬픔';

  @override
  String petActionFailed(Object error) {
    return '동작 실패: $error';
  }

  @override
  String get petHomeTitle => '펫 홈';

  @override
  String get petNameEditTitle => '펫 이름 수정';

  @override
  String get petNameLabel => '펫 이름';

  @override
  String get petNameHint => '펫 이름 입력';

  @override
  String get petNameEmptyError => '이름을 입력해 주세요.';

  @override
  String petNameUpdateFailed(Object error) {
    return '펫 이름을 변경할 수 없습니다: $error';
  }

  @override
  String chatPetRenamedMessage(Object user, Object oldName, Object petName) {
    return '$user님이 펫 이름을 $oldName에서 $petName(으)로 변경했어요.';
  }

  @override
  String chatBoughtFurnitureMessage(Object user, Object petName) {
    return '$user님이 $petName를 위해 가구를 샀어요.';
  }

  @override
  String chatBoughtBackgroundMessage(Object user, Object petName) {
    return '$user님이 $petName를 위해 배경을 샀어요.';
  }

  @override
  String chatBoughtStoreItemMessage(
    Object user,
    Object itemName,
    Object petName,
  ) {
    return '$user님이 $petName에게 $itemName을 사줬어요.';
  }

  @override
  String get petNameUnnamed => '이름 없음';

  @override
  String get petNotFound => '펫을 찾을 수 없습니다.';

  @override
  String petSyncFailed(Object error) {
    return '펫 동기화 오류: $error';
  }

  @override
  String get photoLabel => '사진';

  @override
  String get profileDefaultNickname => '펫 보호자';

  @override
  String get profileEmpty => '프로필 정보가 없습니다.';

  @override
  String profileLoadFailed(Object error) {
    return '프로필 불러오기 실패: $error';
  }

  @override
  String get profileNicknameLabel => '닉네임';

  @override
  String get profileTitle => '프로필';

  @override
  String get profileSectionAccount => '계정';

  @override
  String get profileSectionAbout => '정보 및 지원';

  @override
  String get profileFeedbackEncouragement =>
      '의견과 요청을 적극적으로 보내 주세요. 보내주신 내용을 바탕으로 더 나은 서비스가 되도록 최선을 다하겠습니다.';

  @override
  String get profileFeedback => '피드백 보내기';

  @override
  String get profileVersionPrefix => '버전: ';

  @override
  String get profileSectionDangerZone => '위험 구역';

  @override
  String get profileUpdated => '프로필이 업데이트되었습니다';

  @override
  String get profileAvatarTitle => '아바타 선택';

  @override
  String get profileAvatarEdit => '아바타 수정';

  @override
  String get profileAvatarUpload => '사진 업로드';

  @override
  String get profileAvatarAdjustCurrent => '현재 사진 조정';

  @override
  String get profileAvatarAdjustUnavailable => '조정할 업로드 사진이 없습니다.';

  @override
  String get profileAvatarAdjustUnsupportedPlatform =>
      '이 플랫폼에서는 현재 사진 조정을 지원하지 않습니다.';

  @override
  String get profileAvatarEditorHint => '드래그로 위치를 조정하고 손가락을 벌려 확대해요.';

  @override
  String get profileAvatarEditorZoom => '확대';

  @override
  String get profileAvatarEditorCenter => '가운데로';

  @override
  String get profileAvatarRemove => '삭제';

  @override
  String profileCoinsLabel(Object amount) {
    return '캔디: $amount';
  }

  @override
  String get profileDeleteAccountSectionTitle => '계정 삭제';

  @override
  String get profileDeleteAccountSectionBody =>
      '계정을 영구 삭제합니다. 공유 방과 펫은 다른 멤버에게 남습니다.';

  @override
  String get profileDeleteAccountAction => '계정 삭제';

  @override
  String get profileDeleteAccountTitle => '계정을 삭제할까요?';

  @override
  String get profileDeleteAccountConfirmBody =>
      '계정과 개인 데이터가 영구 삭제됩니다. 공유 방/펫은 유지되며 소유권은 다른 멤버에게 이전됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get profileDeleteAccountConfirmAction => '삭제';

  @override
  String profileDeleteFailed(Object error) {
    return '계정 삭제 실패: $error';
  }

  @override
  String profileUserId(Object id) {
    return '사용자 ID: $id';
  }

  @override
  String get drawerProfile => '프로필';

  @override
  String get roomCreatedSuccess => '방이 생성되었습니다! 드로어를 확인해 주세요.';

  @override
  String roomCreateFailed(Object error) {
    return '방 생성 실패: $error';
  }

  @override
  String get roomCreateTitle => '방 만들기';

  @override
  String get roomCreateAction => '생성';

  @override
  String get roomNameLabel => '방 이름';

  @override
  String get roomNameHint => '방 이름';

  @override
  String get roomNameEmptyError => '방 이름을 입력해 주세요.';

  @override
  String roomNameUpdateFailed(Object error) {
    return '방 이름을 변경할 수 없습니다: $error';
  }

  @override
  String get roomOptionsTitle => '방 옵션';

  @override
  String get roomOptionRename => '방 이름 변경';

  @override
  String get roomOptionLeave => '방 나가기';

  @override
  String get roomRenameTitle => '방 이름 바꾸기';

  @override
  String get roomRenameMessage => '이 방의 새 이름을 입력해 주세요.';

  @override
  String get roomDefaultName => '새 방';

  @override
  String get roomInviteCta => '초대';

  @override
  String get roomInventoryCta => '인벤토리';

  @override
  String get roomInvitePromptTitle => '누군가를 초대하세요';

  @override
  String get roomInvitePromptBody => '현재 이 방에는 나만 있어요. 코드를 만들어 누군가를 초대해 보세요.';

  @override
  String get roomInvitePromptAction => '코드 생성';

  @override
  String get roomInvitePromptGenerating => '생성 중...';

  @override
  String get roomInviteCodeTitle => '초대 코드';

  @override
  String get roomInviteCodeMessage => '이 코드를 공유해 방에 초대하세요.';

  @override
  String get roomInviteCodeTapHint => '코드를 탭하면 복사돼요.';

  @override
  String get roomInviteCopyCodeAction => '복사';

  @override
  String get roomInviteShareAction => '공유';

  @override
  String get roomInviteShareCaption => 'PetTomo에서 함께해요';

  @override
  String roomInviteShareFailed(Object error) {
    return '초대 공유 실패: $error';
  }

  @override
  String get roomInviteLinkJoining => '초대로 방에 참가하는 중...';

  @override
  String get roomInviteCodeCopiedTitle => '복사 완료';

  @override
  String get roomInviteCodeCopiedMessage => '지금 친구를 초대해서 함께 반려동물을 돌봐요!';

  @override
  String get roomInviteCodeRegenerated => '초대 코드가 재생성되었습니다.';

  @override
  String roomInviteCodeRegenerateFailed(Object error) {
    return '초대 코드 재생성 실패: $error';
  }

  @override
  String roomJoinFailed(Object error) {
    return '방 참가 실패: $error';
  }

  @override
  String get roomJoinHelper => '초대 코드는 대소문자를 구분하지 않습니다.';

  @override
  String get roomJoinHint => '6자리 코드 입력';

  @override
  String get roomJoinSuccess => '방 참가에 성공했습니다.';

  @override
  String get roomJoinTitle => '방 참가';

  @override
  String get roomEnteringLoading => '방에 들어가는 중';

  @override
  String roomLeaveFailed(Object error) {
    return '방 나가기 실패: $error';
  }

  @override
  String roomLeaveMessage(Object name) {
    return '$name에서 나가며, 해당 채팅과 펫에 대한 접근 권한을 잃게 됩니다.';
  }

  @override
  String get roomLeaveSuccess => '방에서 나갔습니다.';

  @override
  String get roomLeaveTitle => '방을 나갈까요?';

  @override
  String get roomLimitReached => '무료 플랜 한도(최대 2개 방)에 도달했습니다. 더 만들려면 업그레이드하세요!';

  @override
  String roomNewInviteCode(Object code) {
    return '새 초대 코드: $code';
  }

  @override
  String get roomSelectionCreatePet => '새 방 만들기';

  @override
  String get roomSelectionCreating => '생성 중...';

  @override
  String get roomSelectionEmptySlot => '빈 슬롯';

  @override
  String get roomSelectionEnterInvite => '초대 코드 입력';

  @override
  String get roomSelectionJoining => '참가 중...';

  @override
  String get roomSelectionRoomFallback => '방';

  @override
  String get roomSelectionSubtitle => '펫 홈을 선택하고 다시 이어서 플레이하세요.';

  @override
  String get roomSelectionTitle => '방 선택';

  @override
  String get signInFailed => '로그인에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get signInNote => '참고: Supabase에서 OAuth 제공자를 설정해야 합니다.';

  @override
  String get signInOpening => '로그인 화면 여는 중...';

  @override
  String signInOpeningProvider(Object provider) {
    return '$provider 로그인 여는 중...';
  }

  @override
  String get signInSubtitle => '함께 펫을 키우려면 로그인하세요.';

  @override
  String get signInWithApple => 'Apple로 계속';

  @override
  String get signInWithGoogle => 'Google로 계속';

  @override
  String storeCoinPrice(Object amount) {
    return '캔디: $amount';
  }

  @override
  String storeCoinsLabel(Object amount) {
    return '캔디: $amount';
  }

  @override
  String storeCoinsReward(Object amount) {
    return '캔디 +$amount';
  }

  @override
  String storeDiamondsLabel(Object amount) {
    return '다이아몬드: $amount';
  }

  @override
  String storeDiamondsReward(Object amount) {
    return '다이아몬드 +$amount';
  }

  @override
  String get shopEmpty => '지금은 샵이 비어 있습니다.';

  @override
  String get storeIapNotConfigured => 'IAP가 설정되지 않았습니다.';

  @override
  String storeIapUnavailable(Object error) {
    return 'IAP를 사용할 수 없음: $error';
  }

  @override
  String shopLoadFailed(Object error) {
    return '샵 불러오기 실패: $error';
  }

  @override
  String get storeNotEnoughCoins => '캔디가 부족합니다.';

  @override
  String get storeNotEnoughDiamonds => '다이아몬드가 부족합니다.';

  @override
  String storeOwnedCount(Object amount) {
    return '보유 x$amount';
  }

  @override
  String get storePriceUnavailable => '가격 정보 없음';

  @override
  String get storeProductNotFound => 'RevenueCat에서 상품을 찾을 수 없습니다.';

  @override
  String get storeProductUnavailable => '상품을 사용할 수 없습니다.';

  @override
  String storePurchaseFailed(Object error) {
    return '구매 실패: $error';
  }

  @override
  String storePurchaseSuccess(Object name) {
    return '$name 구매 완료.';
  }

  @override
  String get shopReturnToRoomCta => '방으로 돌아가기';

  @override
  String get shopReturnToRoomHint => '펫 방으로 돌아가 꾸미기를 시작해 보세요.';

  @override
  String storeRestoreFailed(Object error) {
    return '복원 실패: $error';
  }

  @override
  String get storeRestoreTooltip => '구매 복원';

  @override
  String get shopSectionCoinPacks => '캔디 팩';

  @override
  String get shopSectionCoinShop => '캔디 샵';

  @override
  String get shopSectionDiamondPacks => '다이아몬드 팩';

  @override
  String get shopSectionDiamondShop => '다이아몬드 샵';

  @override
  String get shopSectionSubscription => '구독';

  @override
  String get storeTabPremium => '프리미엄';

  @override
  String get storeTabFurniture => '가구';

  @override
  String get storeTabThemes => '테마';

  @override
  String get storeThemePreviewAction => '미리보기';

  @override
  String storeThemePreviewTitle(Object name) {
    return '$name 미리보기';
  }

  @override
  String get storeItemNameProMonthly => '프로 월간 멤버십';

  @override
  String get storeItemDescProMonthly =>
      '광고 제거, 무제한 방 생성. 더욱 자유롭고 즐거운 펫 라이프를 즐겨보세요.';

  @override
  String get storePremiumBenefitUnlimitedRooms => '방 생성 무제한';

  @override
  String get storePremiumBenefitNoAds => '광고 없는 쾌적함';

  @override
  String get storePremiumBenefitExclusiveItems => '전용 아이템 잠금해제';

  @override
  String get storeItemNameDiamondPack300 => '다이아몬드 300 팩';

  @override
  String get storeItemDescDiamondPack300 => '다이아몬드 300개를 즉시 획득합니다(1회 구매).';

  @override
  String get storeItemNameCandyPack500 => '캔디 500 팩';

  @override
  String get storeItemDescCandyPack500 => '다이아몬드 50개를 캔디 500개로 교환합니다.';

  @override
  String get storeItemNameReturnLetter => '귀환 편지';

  @override
  String get storeItemDescReturnLetter => '떠난 펫을 다시 불러옵니다.';

  @override
  String get storeItemNamePetTicket => '펫 티켓';

  @override
  String get storeItemDescPetTicket => '이 방에 다른 펫을 초대합니다.';

  @override
  String get storeItemNameBackgroundDefault => '기본 배경';

  @override
  String get storeItemDescBackgroundDefault => '원래의 아늑한 방 배경입니다.';

  @override
  String get storeItemNameBackgroundMoonlight => '은하 배경';

  @override
  String get storeItemDescBackgroundMoonlight => '고요한 은하 방 배경입니다.';

  @override
  String get storeItemNameBackgroundSageFrame => '세이지 프레임 배경';

  @override
  String get storeItemDescBackgroundSageFrame =>
      '부드러운 종이 질감 위에 경쾌한 세이지 테두리를 더한 배경입니다.';

  @override
  String get storeItemNameBackgroundLilacFrame => '라일락 프레임 배경';

  @override
  String get storeItemDescBackgroundLilacFrame =>
      '부드러운 종이 질감 위에 은은한 라일락 테두리를 더한 배경입니다.';

  @override
  String get storeItemNameBackgroundBubbleSky => '버블 스카이 배경';

  @override
  String get storeItemDescBackgroundBubbleSky =>
      '구름과 오로라빛 비눗방울이 떠 있는 밝은 하늘 배경입니다.';

  @override
  String get storeItemNameBackgroundStarlitDream => '별빛 드림 배경';

  @override
  String get storeItemDescBackgroundStarlitDream =>
      '파스텔 행성, 구름, 별똥별이 펼쳐진 몽환적인 밤하늘 배경입니다.';

  @override
  String get storeItemNameFurnitureSofa => '소파';

  @override
  String get storeItemDescFurnitureSofa => '편안한 소파.';

  @override
  String get storeItemNameFurniturePlant => '식물';

  @override
  String get storeItemDescFurniturePlant => '싱그러운 초록 코너.';

  @override
  String get storeItemNameFurnitureFrame => '액자';

  @override
  String get storeItemDescFurnitureFrame => '사진 액자.';

  @override
  String get storeItemNameFurnitureTeddy => '테디베어';

  @override
  String get storeItemDescFurnitureTeddy => '폭신한 곰인형.';

  @override
  String get storeItemNameFurnitureBricks => '벽돌';

  @override
  String get storeItemDescFurnitureBricks => '블록 포인트 장식.';

  @override
  String get storeItemNameFurnitureTv => 'TV';

  @override
  String get storeItemDescFurnitureTv => '작은 TV.';

  @override
  String get storeItemNameFurnitureBath => '욕조';

  @override
  String get storeItemDescFurnitureBath => '미니 욕조.';

  @override
  String get storeItemNameFurnitureRibbon => '리본';

  @override
  String get storeItemDescFurnitureRibbon => '장식 리본.';

  @override
  String get storeItemNameFurnitureToilet => '변기';

  @override
  String get storeItemDescFurnitureToilet => '깔끔한 작은 욕실 가구.';

  @override
  String get storeItemNameFurnitureTub => '욕조';

  @override
  String get storeItemDescFurnitureTub => '목욕 시간에 어울리는 아늑한 욕조.';

  @override
  String get storeItemNameEquipmentStrawHat => '밀짚모자';

  @override
  String get storeItemNameEquipmentCrown => '왕관';

  @override
  String get storeItemNameEquipmentSunglasses => '선글라스';

  @override
  String get storeItemNameEquipmentRibbon => '리본';

  @override
  String get shopSignInPrompt => '샵을 이용하려면 로그인해 주세요.';

  @override
  String get storeSubscribe => '구독하기';

  @override
  String get storeSubscriptionActive => '사용 중';

  @override
  String get storeSubscriptionDurationMonthly => '1개월';

  @override
  String get storeSubscriptionRenewalNote => '매달 자동 갱신됩니다. 언제든 취소할 수 있습니다.';

  @override
  String get storeSubscriptionDetailsTitle => '구독 정보';

  @override
  String storeSubscriptionDetailsBody(
    Object title,
    Object duration,
    Object price,
  ) {
    return '상품명: $title\n기간: $duration\n가격: $price';
  }

  @override
  String get storePrivacyPolicy => '개인정보 처리방침';

  @override
  String get storeTermsOfUse => '이용약관';

  @override
  String get storeLegalSeparator => '|';

  @override
  String get storeLegalOpenFailed => '법적 링크를 열 수 없습니다.';

  @override
  String get signInSafetyAgreementLabel =>
      '이용약관 및 개인정보 처리방침에 동의하며, 불쾌하거나 학대적인 콘텐츠/사용자에 대해 무관용 정책이 적용됨을 확인합니다.';

  @override
  String get signInSafetyAgreementRequired =>
      '로그인 전에 이용약관과 개인정보 처리방침에 동의해 주세요.';

  @override
  String get shopTitle => '샵';

  @override
  String get storeTypeConsumable => '소모품';

  @override
  String get storeTypeCosmetic => '꾸미기';

  @override
  String get storeTypeSubscription => '구독';

  @override
  String get furnitureInventoryTitle => '방 인벤토리';

  @override
  String get furnitureInventorySubtitle => '이 방의 가구와 배경을 관리하세요.';

  @override
  String get furnitureInventoryEmpty => '아직 가구가 없습니다. 샵에서 구매해 보세요.';

  @override
  String get furnitureInventoryHint =>
      '가구를 탭해 배치하세요. 배치된 가구를 선택하면 이동, 크기 조절, 뒤집기를 할 수 있어요.';

  @override
  String get furnitureScaleLabel => '크기';

  @override
  String get furnitureScaleDecrease => '작게';

  @override
  String get furnitureScaleIncrease => '크게';

  @override
  String get furnitureFlipHorizontal => '좌우 반전';

  @override
  String furnitureAvailableCount(Object count) {
    return '배치 가능 x$count';
  }

  @override
  String get roomInventoryTitle => '방 인벤토리';

  @override
  String get roomDecorCompatibilityTitle => '최신 방 아이템을 보려면 업데이트하세요';

  @override
  String get roomDecorCompatibilityMessage =>
      '이 방에는 더 새로운 펫, 가구 또는 배경이 사용되고 있습니다. 앱을 업데이트하면 대체 표시 대신 최신 공유 아이템을 볼 수 있습니다.';

  @override
  String get roomDecorHintTitle => '방 꾸미기';

  @override
  String roomDecorHintBody(Object buttonLabel) {
    return '$buttonLabel을 눌러 방 수정 모드로 들어간 뒤 가구를 놓거나 배경을 적용하세요.';
  }

  @override
  String get inventoryTabFurniture => '가구';

  @override
  String get inventoryTabEquipment => '꾸미기';

  @override
  String get backgroundGalleryTab => '배경 갤러리';

  @override
  String get backgroundInventoryEmpty => '아직 배경이 없습니다. 샵에서 획득해 보세요.';

  @override
  String get backgroundInventoryHint => '배경을 탭하면 방의 모든 사용자에게 적용됩니다.';

  @override
  String get equipmentInventoryHint =>
      '여기서 스타일을 미리 보고 공유 펫에게 장비를 착용하거나 해제할 수 있어요.';

  @override
  String get equipmentNoneOwned => '아직 이 부위에 사용할 수 있는 장비가 없습니다.';

  @override
  String get equipmentCopyInUse => '다른 펫이 착용 중';

  @override
  String get equipmentCopyUnavailable =>
      '이 아이템은 모두 다른 펫이 착용 중입니다. 여러 펫에게 입히려면 하나 더 구매하세요.';

  @override
  String get equipmentSlotHead => '머리';

  @override
  String get equipmentSlotFace => '얼굴';

  @override
  String get equipmentSlotBody => '몸';

  @override
  String get equipmentSlotBack => '등';

  @override
  String get equipmentEquipCta => '착용';

  @override
  String get equipmentUnequipCta => '해제';

  @override
  String equipmentEquipSuccess(Object itemName) {
    return '$itemName 착용 완료!';
  }

  @override
  String equipmentUnequipSuccess(Object slotName) {
    return '$slotName 해제됨.';
  }

  @override
  String get backgroundApply => '적용';

  @override
  String get backgroundAppliedLabel => '적용됨';

  @override
  String backgroundApplyFailed(Object error) {
    return '배경 적용 실패: $error';
  }

  @override
  String get shopSectionBackgrounds => '배경';

  @override
  String get shopSectionEquipment => 'Equipment';

  @override
  String get shopSectionItems => '아이템';

  @override
  String get storeBackgroundRoomRequired => '배경을 구매하기 전에 방을 선택해 주세요.';

  @override
  String storeBuyWithCandies(Object price) {
    return '$price 캔디로 구매';
  }

  @override
  String storeBuyWithDiamonds(Object price) {
    return '$price 다이아몬드로 구매';
  }

  @override
  String get furnitureEditMode => '가구 모드';

  @override
  String get petSelectionTitle => '펫을 선택하세요';

  @override
  String get petSelectionSubtitle => '이 방을 시작할 친구를 고르세요.';

  @override
  String get petSelectionHint => '계속하려면 펫을 탭하세요.';

  @override
  String petSelectionSelected(Object name) {
    return '선택됨: $name';
  }

  @override
  String get petSelectionConfirm => '방 시작';

  @override
  String get petTicketUseCta => '사용';

  @override
  String get petTicketSelectionTitle => '펫 초대';

  @override
  String get petTicketSelectionSubtitle => '이 방에 함께할 새 친구를 선택하세요.';

  @override
  String get petTicketSelectionConfirm => '펫 초대';

  @override
  String petTicketUseSuccess(Object petName) {
    return '$petName이(가) 방에 들어왔어요!';
  }

  @override
  String get petTicketRoomFull => '이 방은 이미 펫 수가 최대입니다.';

  @override
  String get multiPetNamingTitle => '새 가족을 환영해요!';

  @override
  String get multiPetNamingSubtitle => '방에 새 이름을 정하고, 첫 번째 펫의 이름도 확인하세요.';

  @override
  String get multiPetNamingRoomLabel => '방 이름';

  @override
  String get multiPetNamingFirstPetLabel => '첫 번째 펫 이름';

  @override
  String get multiPetNamingFirstPetHint => '기존 방 이름을 그대로 사용합니다';

  @override
  String get mainPetSwitcherTitle => '메인 펫 선택';

  @override
  String get equipTargetPickerTitle => '어느 펫에게 장착할까요?';

  @override
  String equipTargetPickerCurrentlyWearing(Object sku) {
    return '현재 장착: $sku';
  }

  @override
  String get petSelectionStarterBadge => '기본';

  @override
  String petSelectionFailed(Object error) {
    return '펫 선택 실패: $error';
  }

  @override
  String get petTypeGhostName => '유령';

  @override
  String get petTypeGhostTagline => '간식을 좋아하는 수줍은 둥둥이.';

  @override
  String get petTypeCatName => '고양이';

  @override
  String get petTypeCatTagline => '따뜻한 골골송의 호기심 많은 점프왕.';

  @override
  String get petTypeFishName => '물고기';

  @override
  String get petTypeFishTagline => '유영을 좋아하는 톡톡 튀는 수영 친구.';

  @override
  String get petTypeTigerName => '호랑이';

  @override
  String get petTypeTigerTagline => '줄무늬 자신감으로 당당히 걷는 작은 탐험가.';

  @override
  String get roomLeaveConfirm => '방 나가기';

  @override
  String get roomLockedBadge => '잠김';

  @override
  String get roomLockedTitle => '무료 플랜에서 잠긴 방';

  @override
  String get roomLockedMessage =>
      '무료 플랜에서는 처음 2개의 방만 활성 상태로 유지됩니다. 이 방에서 펫을 키우고 성장시키려면 Pro로 업그레이드하세요.';

  @override
  String get petDepartureNoteMessage => '왜 나를 이렇게 대했어...';

  @override
  String get petDepartureGuideTitle => '펫이 보낸 편지';

  @override
  String get petDepartureGuideMessage => '샵에서 편지를 구매해 펫을 다시 초대하세요.';

  @override
  String get petDepartureGuideGoShop => '샵으로 이동';

  @override
  String get petDepartureLetterUnavailableTitle => '펫이 아직 집에 있어요';

  @override
  String get petDepartureLetterUnavailableMessage =>
      '펫이 가출하지 않았어요. 지금은 편지가 필요하지 않습니다.';

  @override
  String get petDepartureLetterSelectTitle => '펫 선택';

  @override
  String get petDepartureLetterSelectMessage => '어떤 펫을 편지로 다시 부를까요?';

  @override
  String petDepartureLetterConfirmTitle(Object petName) {
    return '$petName를 다시 부를까요?';
  }

  @override
  String petDepartureLetterConfirmMessage(Object petName) {
    return '편지를 구매해 $petName를 집으로 다시 초대하세요.';
  }

  @override
  String get petDepartureLetterConfirmAction => '편지 구매';

  @override
  String get petDepartureFeedDisabledTitle => '먹일 펫이 없습니다';

  @override
  String get petDepartureFeedDisabledMessage => '펫이 떠나서 지금은 먹이를 줄 수 없어요.';

  @override
  String get petOverfedBubble => '배불러요!';

  @override
  String get petNameUnknown => '당신의 펫';

  @override
  String get roomNameUnknown => '알 수 없는 방';

  @override
  String petReturnFailed(Object error) {
    return '펫 복귀 실패: $error';
  }

  @override
  String get storeAdRewardTitle => '광고 보고 캔디 받기';

  @override
  String storeAdRewardDescription(Object amount) {
    return '짧은 광고를 보고 캔디 +$amount를 받으세요.';
  }

  @override
  String get storeAdRewardAction => '보기';

  @override
  String get storeAdRewardLoading => '불러오는 중...';

  @override
  String get storeAdRewardUnavailable => '광고를 사용할 수 없음';

  @override
  String get storeAdRewardDismissed => '보상 전에 광고가 닫혔습니다.';

  @override
  String get storeAdRewardCooldown => '광고 보상은 지금 쿨다운 중입니다.';

  @override
  String get storeAdRewardRoomRequired => '광고 보상을 받으려면 먼저 방을 선택해 주세요.';

  @override
  String storeAdRewardFailed(Object error) {
    return '광고 보상 지급 실패: $error';
  }

  @override
  String get feedAdDoubleRewardTitle => '먹이 보상을 2배로 받을까요?';

  @override
  String feedAdDoubleRewardMessage(Object amount) {
    return '광고 보고 캔디 +$amount 더 받을까요?';
  }

  @override
  String feedAdDoubleRewardClaimed(Object amount) {
    return 'x2 캔디 +$amount';
  }

  @override
  String feedAdDoubleRewardFailed(Object error) {
    return '2배 보상 지급 실패: $error';
  }

  @override
  String get whatsNew111Title => '안정성 및 성능 업데이트';

  @override
  String get whatsNew111Bullet1 => '앱이 예기치 않게 종료될 수 있는 문제들을 해결했습니다.';

  @override
  String get whatsNew111Bullet2 => '채팅 메시지 처리와 이미지 렌더링 과정을 최적화했습니다.';

  @override
  String get whatsNew111Bullet3 => '전반적인 성능을 개선하여 더욱 쾌적한 환경을 제공합니다.';

  @override
  String get whatsNew112Title => '방 꾸미기 및 @멘션 기능';

  @override
  String get whatsNew112Bullet1 => '새로운 욕실 가구인 \'변기\'와 \'욕조\'가 추가되었습니다.';

  @override
  String get whatsNew112Bullet2 => '가구를 좌우로 반전할 수 있어 더욱 자유로운 방 꾸미기가 가능해졌습니다.';

  @override
  String get whatsNew112Bullet3 => '채팅에서 @멘션을 사용하여 특정 멤버에게 메시지를 강조할 수 있습니 다。';

  @override
  String get whatsNew113Title => '조작 경험 대규모 업그레이드';

  @override
  String get whatsNew113Bullet1 => '📸 사진 전송이 더욱 원활해졌어요';

  @override
  String get whatsNew113Bullet2 => '🔘 버튼 개편! 기분 좋은 터치감';

  @override
  String get whatsNew113Bullet3 => '🛍️ 더욱 빠르고 쾌적한 상점 쇼핑';

  @override
  String get whatsNew114Title => '버그 수정';

  @override
  String get whatsNew114Bullet1 => '게임이 충돌할 수 있는 버그를 수정했습니다.';

  @override
  String get whatsNew120Title => '채팅 및 공유 업그레이드';

  @override
  String get whatsNew120Bullet1 => '✏️ 채팅방에서 메시지 편집 및 삭제 가능';

  @override
  String get whatsNew120Bullet2 => '🔗 초대 링크 공유 개선 — 더 안정적으로';

  @override
  String get whatsNew120Bullet3 => '💡 기능 건의 추가! 앱에서 직접 아이디어를 제출하세요';

  @override
  String get whatsNew130Title => '펫 꾸미기 기능 등장';

  @override
  String get whatsNew130Bullet1 => '펫에게 장비를 착용시킬 수 있어요.';

  @override
  String get whatsNew130Bullet2 => '상점에 밀짚모자가 새로 추가되었습니다.';

  @override
  String get whatsNew130Bullet3 => '펫 미리보기와 방 인벤토리가 더 보기 쉬워졌어요.';

  @override
  String get whatsNew140Title => '더 다양해진 펫 스타일';

  @override
  String get whatsNew140Bullet1 => '상점에 왕관, 선글라스, 리본 장비가 새로 추가되었습니다.';

  @override
  String get whatsNew140Bullet2 => '장비 미리보기가 펫마다 더 자연스럽게 보이도록 개선되었습니다.';

  @override
  String get whatsNew140Bullet3 => '공유 방, 인벤토리, 상점에서 장비 표시가 더 명확해졌습니다.';

  @override
  String get whatsNew200Title => '더 많은 펫을 함께 키워요';

  @override
  String get whatsNew200Bullet1 => '펫 티켓으로 공유 방에 새 펫을 추가할 수 있습니다.';

  @override
  String get whatsNew200Bullet2 => '메인으로 보이는 펫을 언제든 전환할 수 있습니다.';

  @override
  String get whatsNew200Bullet3 => '각 펫을 따로 꾸밀 수 있습니다.';

  @override
  String get whatsNew201Title => '더 부드러운 사진 공유';

  @override
  String get whatsNew201Bullet1 => '보낸 피드 사진을 취소할 수 있습니다.';

  @override
  String get whatsNew201Bullet2 => '아바타와 사진 표시를 개선했습니다.';

  @override
  String get whatsNew201Bullet3 => '안정성과 사용성을 다듬었습니다.';

  @override
  String get whatsNew202Title => '버그 수정';

  @override
  String get whatsNew202Bullet1 => '버그를 수정하고 안정성을 개선했습니다.';

  @override
  String get whatsNew210Title => '가구 배치가 더 편해졌어요';

  @override
  String get whatsNew210Bullet1 => '기기가 달라도 가구 위치가 더 안정적으로 보입니다.';

  @override
  String get whatsNew210Bullet2 => '짧은 화면에서도 방 인벤토리를 더 쉽게 사용할 수 있습니다.';

  @override
  String get whatsNew210Bullet3 => '펫 케어 타이밍과 전반적인 안정성을 개선했습니다.';

  @override
  String get whatsNew220Title => '사진 공유가 더 부드러워졌어요';

  @override
  String get whatsNew220Bullet1 => '먹이 사진을 더 빠르게 보낼 수 있는 새 흐름을 준비했습니다.';

  @override
  String get whatsNew220Bullet2 => '공유 방의 최신 사진과 멤버 수를 더 효율적으로 불러옵니다.';

  @override
  String get whatsNew220Bullet3 => '피드, 아바타, 알림 안정성을 개선했습니다.';

  @override
  String get whatsNew221Title => '먹이 주기 변화가 더 명확해졌어요';

  @override
  String get whatsNew221Bullet1 => '사진 먹이 주기 전에 허기 상태를 갱신해 변화가 더 쉽게 보입니다.';

  @override
  String get whatsNew221Bullet2 => '갱신이 매끄럽지 않아도 사진 먹이 주기가 더 안정적으로 이어집니다.';

  @override
  String get whatsNew221Bullet3 => '공유 펫 먹이 주기 경험을 더 부드럽고 안정적으로 다듬었습니다.';

  @override
  String get whatsNew222Title => '버그 수정';

  @override
  String get whatsNew222Bullet1 => '사진 먹이 주기가 느릴 때도 허기 상태가 더 안정적으로 동기화됩니다.';

  @override
  String get whatsNew222Bullet2 => '공유 펫의 먹이 주기 결과가 더 안정적으로 갱신됩니다.';

  @override
  String get whatsNew222Bullet3 => '더 부드러운 펫 돌봄을 위한 작은 안정성 개선을 적용했습니다.';

  @override
  String get whatsNew223Title => '작은 버그 수정';

  @override
  String get whatsNew223Bullet1 => '공유 펫 돌봄 경험을 개선하기 위해 작은 버그를 수정했습니다.';

  @override
  String get whatsNew223Bullet2 => '매일 더 안정적으로 사용할 수 있도록 세부 안정성을 개선했습니다.';
}
