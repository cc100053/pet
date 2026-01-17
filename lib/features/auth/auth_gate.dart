import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_view.dart';
import 'sign_in_view.dart';
import '../../services/analytics/analytics_service.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final currentSession = Supabase.instance.client.auth.currentSession;
    AnalyticsService.instance.setUserId(currentSession?.user.id);

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        AnalyticsService.instance.setUserId(null);
        AnalyticsService.instance.logEvent('sign_out');
      } else {
        AnalyticsService.instance.setUserId(session.user.id);
        AnalyticsService.instance.logEvent('sign_in');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const SignInView();
        }
        return const HomeView();
      },
    );
  }
}
