part of 'home_view.dart';

/// build() helpers for [_HomeViewState], extracted verbatim to keep the main
/// build method readable (behavior-preserving).
extension _HomeBuildHelpers on _HomeViewState {
  Widget _buildRoomSelectionScaffold(
    SystemUiOverlayStyle overlayStyle,
    Map<String, int> unreadCountByRoom,
    String? roomSelectionId,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        drawer: _buildSideDrawer(),
        bottomNavigationBar:
            AdMobIds.isBannerViewSupported && !_hasProPlanAccess
            ? const AdMobBannerSlot()
            : null,
        body: Stack(
          children: [
            RoomSelectionView(
              rooms: _myRooms,
              unreadCountByRoom: unreadCountByRoom,
              creatingRoom: _creatingRoom,
              joiningRoom: _joiningRoom,
              refreshingRooms: _showRoomSelectionRefreshIndicator,
              onCreateRoom: _createRoom,
              onJoinRoom: _joinRoomByCode,
              onSelectRoom: _enterRoomFromSelection,
              onLeaveRoom: _confirmLeaveRoom,
              userAvatarById: _profileByUserId.map(
                (key, value) => MapEntry(key, value.avatarUrl),
              ),
              userNameById: _profileByUserId.map(
                (key, value) => MapEntry(key, value.nickname),
              ),
              roomEquippedSkusBySlot: _roomEquippedSkusBySlot,
              selectedRoomId: roomSelectionId,
              userAvatarUrl: _myAvatarUrl,
              currentAppVersion: _currentAppVersion,
              highlightCreateRoomCta: _isCreatePetOnboardingStepActive,
              createRoomCtaKey: _onboardingCreateRoomCtaKey,
              highlightJoinRoomCta: _isCreatePetOnboardingStepActive,
              joinRoomCtaKey: _onboardingJoinRoomCtaKey,
            ),
            if (_isProfileSetupOnboardingStepActive)
              _buildProfileSetupOnboardingOverlay(),
            if (_shouldShowCreatePetOnboardingCoachCard)
              _buildBasicOnboardingFocusOverlay(),
            if (_shouldShowCreatePetOnboardingCoachCard)
              _buildBasicOnboardingCoachCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeStatusBar(
    HomeCurrencySnapshot currency,
    HomePetStateSnapshot petSnapshot,
    String? selectedRoomId,
    String activeRoomId,
  ) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final level = _petLevel;
        final exp = _petExp ?? 0;
        final petDefinition = PetCatalog.byId(_petType);
        final expProgressValue = level == null
            ? 0.0
            : expProgress(level: level, exp: exp);
        final roomPetName =
            _myRooms.cast<Map<String, dynamic>?>().firstWhere(
                  (room) => room?['id'] == selectedRoomId,
                  orElse: () => null,
                )?['pet_name']
                as String?;
        final resolvedPetName = (_petName?.trim().isNotEmpty ?? false)
            ? _petName!.trim()
            : ((roomPetName?.trim().isNotEmpty ?? false)
                  ? roomPetName!.trim()
                  : l10n.petNameUnnamed);
        final healthDebugValue =
            ((petSnapshot.state ?? _petState)?['hunger'] as num?)?.round();
        return HomeGameStatusBar(
          petAvatar: _buildStatusBarPetAvatar(petDefinition),
          expProgress: expProgressValue,
          level: level,
          petName: resolvedPetName,
          healthValue: _healthValue(),
          healthDebugValue: healthDebugValue,
          coins: currency.coins,
          diamonds: currency.diamonds,
          coinReward: currency.coinReward,
          coinRewardEventId: currency.coinRewardEventId,
          coinRewardLabel: currency.coinRewardLabel,
          showRewardPending: _feedRewardPendingCount > 0,
          rewardPendingLabel: l10n.feedRewardPending,
          onPetTap: () => Scaffold.of(context).openDrawer(),
          onPetNameTap: _openPetNameEditor,
          onStoreTap: _openStoreFromNav,
          onInviteTap: _generateInviteCode,
          inviteLabel: l10n.roomInviteCta,
          inviteLoading: _inviteCodeLoading,
          onInventoryTap: _openFurnitureInventory,
          inventoryLabel: l10n.roomInventoryCta,
          showInventoryGuidance: _shouldShowRoomDecorHintFor(activeRoomId),
          inventoryGuidanceTitle: l10n.roomDecorHintTitle,
          onInventoryGuidanceDismiss: _dismissRoomDecorHint,
        );
      },
    );
  }
}
