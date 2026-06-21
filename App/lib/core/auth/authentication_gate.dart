import 'dart:async';

import 'package:flutter/material.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/core/push/push_notification_service.dart';
import 'package:handy_app/features/auth/presentation/account_home_page.dart';
import 'package:handy_app/features/auth/presentation/reset_password_page.dart';
import 'package:handy_app/features/onboarding/presentation/role_selection_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({super.key});

  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _syncPushForSession(Supabase.instance.client.auth.currentSession);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      authState,
    ) {
      _syncPushForSession(authState.session);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _syncPushForSession(Session? session) async {
    if (session == null) {
      await PushNotificationService.instance.unregisterCurrentToken();
      return;
    }

    if (!BackendConfig.isApiConfigured) {
      return;
    }

    await PushNotificationService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final authState = snapshot.data;
        final session = Supabase.instance.client.auth.currentSession;

        if (authState?.event == AuthChangeEvent.passwordRecovery &&
            session != null) {
          return const ResetPasswordPage();
        }

        if (session == null) {
          return const RoleSelectionPage();
        }

        return const AccountHomePage();
      },
    );
  }
}
