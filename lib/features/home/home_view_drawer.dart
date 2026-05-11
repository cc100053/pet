part of 'home_view.dart';

extension _HomeDrawerBuilder on _HomeViewState {
  Widget _buildSideDrawer() {
    final l10n = AppLocalizations.of(context)!;
    return HomeDrawer(
      userAvatarUrl: _myAvatarUrl,
      userName: _myNickname,
      onProfileTap: () {
        Navigator.pop(context);
        unawaited(_openProfile());
      },
      onSignOut: _signOut,
      debugActions: _isDebugAdmin
          ? ExpansionTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.drawerDebugTools),
              children: [
                ExpansionTile(
                  title: Text(l10n.drawerDebugCategorySimulation),
                  children: [
                    ListTile(
                      title: Text(l10n.drawerSimulateFeed),
                      subtitle: _feedResult == null ? null : Text(_feedResult!),
                      onTap: _testingFeed ? null : _runFeedTest,
                      trailing: _testingFeed
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    ListTile(
                      title: Text(l10n.drawerTestNotification),
                      onTap: () => _fcmService.showTestNotification(),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(l10n.drawerDebugCategoryUser),
                  children: [
                    ListTile(
                      title: Text(l10n.drawerDebugAddCandy),
                      onTap: () => _debugUpdateProfileBalances(coinDelta: 100),
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugAddDiamonds),
                      onTap: () =>
                          _debugUpdateProfileBalances(diamondDelta: 100),
                    ),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.only(left: 16, right: 8),
                      title: Text(l10n.drawerDebugTogglePlan),
                      subtitle: Text(
                        _hasProPlanAccess
                            ? l10n.drawerProPlan
                            : l10n.drawerFreePlan,
                      ),
                      value: _debugProPlan,
                      onChanged: (value) => unawaited(_setDebugProPlan(value)),
                    ),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.only(left: 16, right: 8),
                      title: Text(l10n.drawerDebugForceOnboarding),
                      subtitle: Text(
                        _debugAlwaysShowOnboarding
                            ? l10n.drawerDebugForceOnboardingEnabled
                            : l10n.drawerDebugForceOnboardingDisabled,
                      ),
                      value: _debugAlwaysShowOnboarding,
                      onChanged: (value) =>
                          unawaited(_setDebugAlwaysShowOnboarding(value)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined),
                      title: Text(l10n.drawerDebugTestProfileSetupOnboarding),
                      subtitle: Text(
                        l10n.drawerDebugTestProfileSetupOnboardingSubtitle,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _debugShowProfileSetupOnboarding();
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(l10n.drawerDebugCategoryPet),
                  children: [
                    ListTile(
                      title: Text(l10n.drawerDebugHungerDown),
                      onTap: (_petBusy || _roomId == null)
                          ? null
                          : () => _debugAdjustPetHunger(-10),
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugAddExp),
                      onTap: (_petBusy || _roomId == null)
                          ? null
                          : () => _debugAddPetExp(10),
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugSpawnPoop),
                      onTap: (_petBusy || _roomId == null)
                          ? null
                          : _debugSpawnPetPoop,
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugShowFullBubble),
                      onTap:
                          (_effectivePetState == null ||
                              !_effectivePetStateReady ||
                              _effectivePetDeparted)
                          ? null
                          : _debugShowOverfedBubble,
                    ),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.only(left: 16, right: 8),
                      title: Text(l10n.drawerDebugShowSocketOverlay),
                      value: _showSocketDebug,
                      onChanged: (value) {
                        _setShowSocketDebug(value);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.straighten_rounded),
                      title: Text(l10n.drawerDebugDressUpFitTool),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DressUpFitToolPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.checkroom_rounded),
                      title: const Text('Equipment Preview'),
                      subtitle: const Text('Test all pets × equipment combos'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EquipmentPreviewPage(),
                          ),
                        );
                      },
                    ),
                    if (_petError != null)
                      ListTile(
                        title: Text(l10n.drawerPetError),
                        subtitle: Text(_petError!),
                      ),
                  ],
                ),
                ExpansionTile(
                  title: Text(l10n.drawerDebugCategoryMemory),
                  children: [
                    ListTile(
                      title: Text(l10n.drawerDebugCaptureMemorySnapshot),
                      onTap: _captureDebugMemorySnapshot,
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugClearImageCacheSnapshot),
                      onTap: _clearImageCacheAndCaptureDebugSnapshot,
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugOpenMemoryDiagnostics),
                      onTap: _openMemoryDiagnosticsSheet,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(l10n.drawerDebugCategorySystem),
                  children: [
                    ListTile(
                      title: Text(l10n.drawerDebugTestSoftUpdate),
                      onTap: () {
                        Navigator.pop(context);
                        ForceUpdateDebugTool.instance.showSoftPrompt();
                      },
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugTestHardUpdate),
                      onTap: () {
                        Navigator.pop(context);
                        ForceUpdateDebugTool.instance.showHardPrompt();
                      },
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugTestWhatsNew),
                      onTap: () {
                        Navigator.pop(context);
                        ForceUpdateDebugTool.instance.showWhatsNewPrompt();
                      },
                    ),
                    ListTile(
                      title: Text(l10n.drawerDebugTestCrashReport),
                      onTap: () {
                        Navigator.pop(context);
                        unawaited(
                          CrashReportingService.instance.triggerTestCrash(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            )
          : null,
    );
  }
}
