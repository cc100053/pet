import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SignInView extends StatelessWidget {
  const SignInView({super.key});

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    const redirectUrl = 'com.cc100053.pet://login-callback';
    await Supabase.instance.client.auth.signInWithOAuth(
      provider,
      redirectTo: redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> _signInWithApple() async {
    if (kIsWeb || !Platform.isIOS) {
      await _signInWithOAuth(OAuthProvider.apple);
      return;
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PicPet',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to start co-raising your pet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _signInWithOAuth(OAuthProvider.google),
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              if (!kIsWeb && Platform.isIOS)
                SignInWithAppleButton(
                  onPressed: _signInWithApple,
                )
              else
                FilledButton.icon(
                  onPressed: _signInWithApple,
                  icon: const Icon(Icons.phone_iphone),
                  label: const Text('Continue with Apple'),
                ),
              const SizedBox(height: 16),
              Text(
                'Note: OAuth providers must be configured in Supabase.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
