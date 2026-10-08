import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/home_ease_app.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ignore: deprecated_member_use
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
    );
  } catch (e) {
    debugPrint('Supabase initial setup notice: $e (Falling back to local offline mode)');
  }

  runApp(const HomeEaseApp());
}
