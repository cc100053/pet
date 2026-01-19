import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PicPet', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                l10n.signInSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _signingIn
                    ? null
                    : () => _signInWithOAuth(context, OAuthProvider.google),
                icon: const Icon(Icons.login),
                label: Text(l10n.signInWithGoogle),
              ),
              const SizedBox(height: 12),
              if (!kIsWeb && Platform.isIOS)
                IgnorePointer(
                  ignoring: _signingIn,
                  child: Opacity(
                    opacity: _signingIn ? 0.6 : 1,
                    child: SignInWithAppleButton(
                      onPressed: () => _signInWithApple(context),
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _signingIn
                      ? null
                      : () => _signInWithApple(context),
                  icon: const Icon(Icons.phone_iphone),
                  label: Text(l10n.signInWithApple),
                ),
              if (_signingIn) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _activeProvider == null
                          ? l10n.signInOpening
                          : l10n.signInOpeningProvider(_activeProvider!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.signInNote,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
