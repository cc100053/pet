import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/env.dart';
import '../../services/settings/app_settings_repository.dart';
import '../../shared/ui/app_ui_scale.dart';

const String _googleLogoSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M21.35 11.1H12v2.98h5.35c-.23 1.48-1.79 4.33-5.35 4.33-3.22 0-5.84-2.67-5.84-5.96s2.62-5.96 5.84-5.96c1.83 0 3.06.78 3.76 1.45l2.57-2.49C16.69 3.91 14.56 3 12 3 7.03 3 3 7.03 3 12s4.03 9 9 9c5.2 0 8.65-3.65 8.65-8.8 0-.59-.06-1.04-.15-1.1z" fill="#4285F4"/>
  <path d="M3 7.69l3.03 2.22A5.95 5.95 0 0112 6.04c1.83 0 3.06.78 3.76 1.45l2.57-2.49C16.69 3.91 14.56 3 12 3 8.55 3 5.54 4.96 3.99 7.82L3 7.69z" fill="#EA4335"/>
  <path d="M12 21c2.49 0 4.58-.82 6.11-2.24l-2.82-2.31c-.76.53-1.78.91-3.29.91-3.54 0-5.08-2.39-5.31-3.85L3.64 15.8A8.99 8.99 0 0012 21z" fill="#34A853"/>
  <path d="M3.64 15.8l3.05-2.29a6.25 6.25 0 01-.17-1.51c0-.52.06-1.02.17-1.51L3.64 8.2A9 9 0 003 12c0 1.45.35 2.82.64 3.8z" fill="#FBBC05"/>
</svg>
''';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  bool _signingIn = false;
  String? _activeProvider;
  bool _ugcTermsAccepted = false;
  Uri? _privacyPolicyUri;
  late final Uri _termsOfUseUri;

  @override
  void initState() {
    super.initState();
    _ugcTermsAccepted = AppSettingsRepository.instance.ugcTermsAccepted;
    _initializeLegalUris();
  }

  void _initializeLegalUris() {
    try {
      _privacyPolicyUri = Uri.tryParse(Env.privacyPolicyUrl);
    } catch (_) {
      _privacyPolicyUri = null;
    }
    try {
      _termsOfUseUri = Uri.parse(Env.termsOfUseUrl);
    } catch (_) {
      _termsOfUseUri = Uri.parse(Env.appleStandardEulaUrl);
    }
  }

  Future<void> _openExternalUri(Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.storeLegalOpenFailed)));
    }
  }

  bool _requireTermsAccepted(BuildContext context) {
    if (_ugcTermsAccepted) {
      return true;
    }
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.signInSafetyAgreementRequired)));
    return false;
  }

  Future<void> _signInWithOAuth(
    BuildContext context,
    OAuthProvider provider,
  ) async {
    if (!_requireTermsAccepted(context)) {
      return;
    }
    const redirectUrl = 'com.cc100053.pet://login-callback';
    try {
      if (_signingIn) {
        return;
      }
      setState(() {
        _signingIn = true;
        _activeProvider = provider.name;
      });
      AnalyticsService.instance.logEvent(
        'sign_in_tap',
        parameters: {'provider': provider.name},
      );
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: {'prompt': 'select_account'},
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showError(context, error);
    } finally {
      if (mounted) {
        setState(() {
          _signingIn = false;
          _activeProvider = null;
        });
      }
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    if (!_requireTermsAccepted(context)) {
      return;
    }
    if (kIsWeb || !Platform.isIOS) {
      await _signInWithOAuth(context, OAuthProvider.apple);
      return;
    }

    try {
      if (_signingIn) {
        return;
      }
      setState(() {
        _signingIn = true;
        _activeProvider = OAuthProvider.apple.name;
      });
      AnalyticsService.instance.logEvent(
        'sign_in_tap',
        parameters: {'provider': OAuthProvider.apple.name},
      );
      final rawNonce = Supabase.instance.client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Apple Sign-In failed: missing identity token.');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showError(context, error);
    } finally {
      if (mounted) {
        setState(() {
          _signingIn = false;
          _activeProvider = null;
        });
      }
    }
  }

  void _showError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    String message = l10n.signInFailed;
    final errorText = error.toString();
    if (errorText.contains('Unacceptable audience')) {
      message = l10n.appleSignInRejected;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool isIosAppleButton = !kIsWeb && Platform.isIOS;
    final scale = appUiScale(MediaQuery.sizeOf(context).width);

    return Scaffold(
      body: ColoredBox(
        color: const Color(0xFF80CEF6),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2E1FB),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/app/LoginPage.png',
                          width: 260,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 0),
                        Transform.translate(
                          offset: Offset(0, -18 * scale),
                          child: Column(
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 250,
                                ),
                                child: CheckboxListTile(
                                  value: _ugcTermsAccepted,
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: _signingIn
                                      ? null
                                      : (value) async {
                                          final accepted = value ?? false;
                                          setState(() {
                                            _ugcTermsAccepted = accepted;
                                          });
                                          await AppSettingsRepository.instance
                                              .setUgcTermsAccepted(accepted);
                                        },
                                  title: Text(
                                    l10n.signInSafetyAgreementLabel,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF18435E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 250,
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  children: [
                                    if (_privacyPolicyUri != null)
                                      TextButton(
                                        onPressed: () => _openExternalUri(
                                          _privacyPolicyUri!,
                                        ),
                                        child: Text(l10n.storePrivacyPolicy),
                                      ),
                                    Text(
                                      l10n.storeLegalSeparator,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.black45),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          _openExternalUri(_termsOfUseUri),
                                      child: Text(l10n.storeTermsOfUse),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 250,
                                ),
                                child: isIosAppleButton
                                    ? SizedBox(
                                        height: 46,
                                        child: IgnorePointer(
                                          ignoring:
                                              _signingIn || !_ugcTermsAccepted,
                                          child: Opacity(
                                            opacity:
                                                (_signingIn ||
                                                    !_ugcTermsAccepted)
                                                ? 0.6
                                                : 1,
                                            child: SignInWithAppleButton(
                                              onPressed: () =>
                                                  _signInWithApple(context),
                                            ),
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 46,
                                        child: FilledButton.icon(
                                          onPressed:
                                              (_signingIn || !_ugcTermsAccepted)
                                              ? null
                                              : () => _signInWithApple(context),
                                          icon: const Icon(
                                            Icons.phone_iphone_rounded,
                                          ),
                                          label: Text(l10n.signInWithApple),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF18435E,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 250,
                                ),
                                child: Semantics(
                                  button: true,
                                  enabled: !_signingIn && _ugcTermsAccepted,
                                  label: l10n.signInWithGoogle,
                                  child: SizedBox(
                                    height: 46,
                                    child: OutlinedButton(
                                      onPressed:
                                          (_signingIn || !_ugcTermsAccepted)
                                          ? null
                                          : () => _signInWithOAuth(
                                              context,
                                              OAuthProvider.google,
                                            ),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF6A7781),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.string(
                                            _googleLogoSvg,
                                            width: 20,
                                            height: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              l10n.signInWithGoogle,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF1F1F1F),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_signingIn) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _activeProvider == null
                                      ? l10n.signInOpening
                                      : l10n.signInOpeningProvider(
                                          _activeProvider!,
                                        ),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF18435E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
