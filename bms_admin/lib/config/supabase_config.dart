/// Supabase Configuration
/// 
/// Replace SUPABASE_API_KEY with your actual anon key from Supabase
/// Found in: Project Settings > API > Project API keys > anon (public)
class SupabaseConfig {
  static const String projectUrl = 'https://lnssskyfwshwextaecdx.supabase.co';
  static const String apiKey = 'sb_publishable_zdoXqwftpRpdWipRszCw5w_gsLC13VY'; // Replace with your actual key
  
  /// Returns the authorization headers for Supabase API requests
  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'apikey': apiKey,
      'Authorization': 'Bearer $apiKey',
    };
  }
}
