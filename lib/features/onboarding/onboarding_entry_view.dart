import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/invite/invite_link_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/balanced_text.dart';
import '../../shared/ui/juice_wrappers.dart';
import '../../shared/ui/mori.dart';
import '../auth/sign_in_view.dart';
import '../pet/pet_animated_image.dart';
import '../pet/pet_catalog.dart';

enum _EntryStep { welcome, newKeeper, codeEntry, invited }

/// Signed-out root: Welcome fork → sign-in, or invite code → invited sign-in.
/// A pending invite (from a link, or typed here) always shows the invited
/// sign-in; the home screen joins with that code after sign-in.
class OnboardingEntryView extends StatefulWidget {
  const OnboardingEntryView({super.key, this.inviteLinkService});

  final AppInviteLinkService? inviteLinkService;

  @override
  State<OnboardingEntryView> createState() => _OnboardingEntryViewState();
}

class _OnboardingEntryViewState extends State<OnboardingEntryView> {
  late final AppInviteLinkService _invites =
      widget.inviteLinkService ?? AppInviteLinkService.instance;
  StreamSubscription<String>? _inviteSubscription;
  late _EntryStep _step;

  @override
  void initState() {
    super.initState();
    final pending = _invites.pendingInviteCode;
    _step = (pending == null || pending.isEmpty)
        ? _EntryStep.welcome
        : _EntryStep.invited;
    if (_step == _EntryStep.invited) {
      _logInviteLanding('link');
    }
    _inviteSubscription = _invites.inviteCodes.listen((_) {
      if (!mounted || _step == _EntryStep.invited) {
        return;
      }
      _logInviteLanding(_step == _EntryStep.codeEntry ? 'code' : 'link');
      setState(() => _step = _EntryStep.invited);
    });
  }

  @override
  void dispose() {
    _inviteSubscription?.cancel();
    super.dispose();
  }

  void _logInviteLanding(String source) {
    AnalyticsService.instance.logEvent(
      'onboarding_invite_landing',
      parameters: {'source': source},
    );
  }

  void _choose(_EntryStep step) {
    AnalyticsService.instance.logEvent(
      'onboarding_fork',
      parameters: {'path': step == _EntryStep.newKeeper ? 'new' : 'invited'},
    );
    setState(() => _step = step);
  }

  void _backToWelcome() {
    if (_step == _EntryStep.invited) {
      unawaited(_invites.clearPendingInviteCode());
    }
    setState(() => _step = _EntryStep.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (_step) {
      _EntryStep.welcome => _WelcomeFork(
        onStartNew: () => _choose(_EntryStep.newKeeper),
        onInvited: () => _choose(_EntryStep.codeEntry),
      ),
      _EntryStep.newKeeper => SignInView(onBack: _backToWelcome),
      _EntryStep.codeEntry => _InviteCodeEntry(
        onBack: _backToWelcome,
        onSubmit: _invites.rememberPendingInviteCode,
      ),
      _EntryStep.invited => SignInView(invited: true, onBack: _backToWelcome),
    };
    return PopScope(
      canPop: _step == _EntryStep.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _backToWelcome();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(_step), child: child),
      ),
    );
  }
}

class _WelcomeFork extends StatelessWidget {
  const _WelcomeFork({required this.onStartNew, required this.onInvited});

  final VoidCallback onStartNew;
  final VoidCallback onInvited;

  static const List<String> _heroPetIds = ['cat', 'ghost', 'fish'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final heroPets = [
      for (final id in _heroPetIds)
        PetCatalog.pets.firstWhere(
          (pet) => pet.id == id,
          orElse: () => PetCatalog.pets.first,
        ),
    ];
    return Scaffold(
      body: MoriPaperBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          Image.asset(
                            'assets/app/LoginPage.png',
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final pet in heroPets)
                                PetAnimatedImage(
                                  sourceAsset: pet.stayAsset,
                                  width: 92,
                                  height: 92,
                                  fit: BoxFit.contain,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Center(child: KanaEyebrow('ようこそ')),
                          BalancedText(
                            l10n.onboardingWelcomeTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          BalancedText(
                            l10n.onboardingWelcomeSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
                          _ForkOption(
                            icon: Icons.add_rounded,
                            iconColor: Colors.white,
                            iconTile: AppTheme.leafStrong,
                            color: const Color(0xFFE8F5EC),
                            title: l10n.onboardingWelcomeStartNew,
                            hint: l10n.onboardingWelcomeStartNewHint,
                            onTap: onStartNew,
                          ),
                          const SizedBox(height: 14),
                          _ForkOption(
                            icon: Icons.vpn_key_rounded,
                            iconColor: AppTheme.textPrimary,
                            iconTile: AppTheme.sky,
                            color: Colors.white,
                            title: l10n.onboardingWelcomeInvited,
                            hint: l10n.onboardingWelcomeInvitedHint,
                            onTap: onInvited,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForkOption extends StatelessWidget {
  const _ForkOption({
    required this.icon,
    required this.iconColor,
    required this.iconTile,
    required this.color,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconTile;
  final Color color;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      hint: hint,
      excludeSemantics: true,
      child: HardShadowPressButton(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        shadowDepth: 4,
        color: color,
        borderWidth: 2.5,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconTile,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeEntry extends StatefulWidget {
  const _InviteCodeEntry({required this.onBack, required this.onSubmit});

  final VoidCallback onBack;
  final Future<void> Function(String code) onSubmit;

  @override
  State<_InviteCodeEntry> createState() => _InviteCodeEntryState();
}

class _InviteCodeEntryState extends State<_InviteCodeEntry> {
  final TextEditingController _controller = TextEditingController();
  bool _showInvalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    // Format check only; whether the room exists is decided by the join
    // after sign-in, which already shows a localized error.
    final code = AppInviteLinkService.normalizeInviteCode(_controller.text);
    if (code == null) {
      setState(() => _showInvalid = true);
      return;
    }
    unawaited(widget.onSubmit(code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: MoriPaperBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OnboardingBackButton(onPressed: widget.onBack),
                  ),
                  const SizedBox(height: 16),
                  BalancedText(
                    l10n.onboardingInviteCodeTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BalancedText(
                    l10n.onboardingInviteCodeSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.go,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    ],
                    onChanged: (_) {
                      if (_showInvalid) {
                        setState(() => _showInvalid = false);
                      }
                    },
                    onSubmitted: (_) => _submit(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: AppTheme.leafDeep,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.roomInviteCodeTitle,
                      hintText: l10n.roomJoinHint,
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                      errorText: _showInvalid
                          ? l10n.errorInvalidInviteCode
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.ink,
                          width: 2.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.ink,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    button: true,
                    label: l10n.onboardingProfileSetupContinue,
                    excludeSemantics: true,
                    child: HardShadowPressButton(
                      onTap: _submit,
                      borderRadius: BorderRadius.circular(18),
                      shadowDepth: 4,
                      color: AppTheme.leafStrong,
                      borderWidth: 2.5,
                      height: 54,
                      child: Text(
                        l10n.onboardingProfileSetupContinue,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 44pt back button shared by the signed-out onboarding screens.
class OnboardingBackButton extends StatelessWidget {
  const OnboardingBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.ink,
        side: const BorderSide(color: AppTheme.ink, width: 2.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
    );
  }
}
