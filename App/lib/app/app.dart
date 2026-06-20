import 'package:flutter/material.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/core/theme/app_theme.dart';
import 'package:handy_app/features/auth/presentation/account_home_page.dart';
import 'package:handy_app/features/auth/presentation/backend_setup_page.dart';
import 'package:handy_app/features/auth/presentation/reset_password_page.dart';
import 'package:handy_app/features/onboarding/presentation/role_selection_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HandyApp extends StatelessWidget {
  const HandyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Handy',
      theme: AppTheme.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: BackendConfig.isConfigured
          ? const AuthenticationGate()
          : const BackendSetupPage(),
    );
  }
}

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({super.key});

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
