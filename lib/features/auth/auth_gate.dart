import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_view.dart';
import 'sign_in_view.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/crash/crash_reporting_service.dart';
import '../../services/fcm_service.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;
  FCMService get _fcmService => ref.read(fcmServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final currentSession = Supabase.instance.client.auth.currentSession;
    AnalyticsService.instance.setUserId(currentSession?.user.id);
    unawaited(
      CrashReportingService.instance.setUserId(currentSession?.user.id),
    );
    if (currentSession != null) {
      unawaited(_fcmService.initialize());
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final session = data.session;
      if (session == null) {
        AnalyticsService.instance.setUserId(null);
        AnalyticsService.instance.logEvent('sign_out');
        unawaited(CrashReportingService.instance.setUserId(null));
      } else {
        AnalyticsService.instance.setUserId(session.user.id);
        AnalyticsService.instance.logEvent('sign_in');
        unawaited(CrashReportingService.instance.setUserId(session.user.id));
        unawaited(_fcmService.initialize());
        unawaited(_fcmService.refreshTokenSync());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    if (Supabase.instance.client.auth.currentSession == null) {
      return;
    }
    unawaited(_fcmService.refreshTokenSync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const SignInView();
        }
        return const HomeView();
      },
    );
  }
}
