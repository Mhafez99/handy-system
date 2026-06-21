import 'package:flutter/material.dart';
import 'package:handy_app/core/auth/authentication_gate.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/core/theme/app_theme.dart';
import 'package:handy_app/features/auth/presentation/backend_setup_page.dart';

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
