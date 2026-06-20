abstract final class BackendConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
  }
}
