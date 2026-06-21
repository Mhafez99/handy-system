abstract final class BackendConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const handyApiUrl = String.fromEnvironment('HANDY_API_URL');

  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
  }

  static bool get isApiConfigured {
    return handyApiUrl.isNotEmpty;
  }
}
