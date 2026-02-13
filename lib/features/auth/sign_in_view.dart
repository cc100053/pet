import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';

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

  Future<void> _signInWithOAuth(
    BuildContext context,
    OAuthProvider provider,
  ) async {
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5DD), Color(0xFFFFEDD0), Color(0xFFFFF9EE)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -52,
              right: -24,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEDFA0).withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -36,
              top: 140,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6C886).withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFF3D8AF),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F8A5D2B),
                            blurRadius: 26,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4DF),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFF2D2A8),
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Image.asset(
                                'assets/app/PetTomo_appicon.png',
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'PetTomo',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.signInSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B5A46),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (isIosAppleButton)
                            Align(
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 230,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: IgnorePointer(
                                    ignoring: _signingIn,
                                    child: Opacity(
                                      opacity: _signingIn ? 0.6 : 1,
                                      child: SignInWithAppleButton(
                                        onPressed: () =>
                                            _signInWithApple(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Align(
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 230,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: FilledButton.icon(
                                    onPressed: _signingIn
                                        ? null
                                        : () => _signInWithApple(context),
                                    icon: const Icon(
                                      Icons.phone_iphone_rounded,
                                    ),
                                    label: Text(l10n.signInWithApple),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Semantics(
                            button: true,
                            enabled: !_signingIn,
                            label: l10n.signInWithGoogle,
                            child: Align(
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 230,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: _signingIn
                                        ? null
                                        : () => _signInWithOAuth(
                                            context,
                                            OAuthProvider.google,
                                          ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF747775),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.string(
                                          _googleLogoSvg,
                                          width: 22,
                                          height: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        const Flexible(
                                          child: Text(
                                            'Sign in with Google',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Color(0xFF1F1F1F),
                                              fontSize: 17,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_signingIn) ...[
                            const SizedBox(height: 16),
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
                                Text(
                                  _activeProvider == null
                                      ? l10n.signInOpening
                                      : l10n.signInOpeningProvider(
                                          _activeProvider!,
                                        ),
                                  style: theme.textTheme.bodySmall,
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
          ],
        ),
      ),
    );
  }
}
