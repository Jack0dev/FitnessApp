/// Supabase Configuration
/// 
/// IMPORTANT: Replace these values with your Supabase project credentials
/// Get them from: Supabase Dashboard > Settings > API
class SupabaseConfig {
  /// Supabase Project URL
  /// Example: https://xxxxx.supabase.co
  /// Get from: Supabase Dashboard > Settings > API > Project URL
  static const String supabaseUrl = 'https://dittvvfdbeikqbanpudc.supabase.co';
  
  /// Supabase Anon/Public Key
  /// This is safe to use in client apps
  /// Get from: Supabase Dashboard > Settings > API > Project API keys > anon public
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpdHR2dmZkYmVpa3FiYW5wdWRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwOTY0NDksImV4cCI6MjA3NzY3MjQ0OX0.4NCoI9WT9Vh_QeijCzyzCoZmtxwa2U2PjDcRW54lhZA';
  
  /// Check if Supabase is configured
  /// Returns true if URL and key are set (not empty)
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty &&
           supabaseUrl.startsWith('https://') &&
           supabaseAnonKey.length > 20; // Basic validation
  }
  
  /// Storage bucket name - change this to match your Supabase bucket name
  /// Common names: 'public', 'avatars', 'profile-images', etc.
  static const String storageBucketName = 'DataFitnessApp'; // Change to 'DataFitnessApp' if that's your bucket name
}


