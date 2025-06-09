import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://moeqveunnyymcnybirwt.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZXF2ZXVubnl5bWNueWJpcnd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0MDg2OTUsImV4cCI6MjA2NDk4NDY5NX0.l8V4UpPYfgqaCzgiXXEHJDuZZRR1BAVj0EALJCjWtpE';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
