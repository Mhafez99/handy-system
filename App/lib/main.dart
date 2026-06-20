import 'package:flutter/widgets.dart';
import 'package:handy_app/app/app.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (BackendConfig.isConfigured) {
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabasePublishableKey,
    );
  }

  runApp(const HandyApp());
}
