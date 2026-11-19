import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/auth/secure_supabase_storage.dart';
import 'core/config/app_environment.dart';
import 'core/state/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = AppEnvironment.fromCompileTime();

  final supabaseUrl = environment.supabaseUrl;
  final publishableKey = environment.supabasePublishableKey;
  if (supabaseUrl != null && publishableKey != null) {
    if (kIsWeb) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: publishableKey,
      );
    } else {
      final secureStorage = SecureSupabaseStorage(supabaseUrl: supabaseUrl);
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: publishableKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: secureStorage,
          pkceAsyncStorage: secureStorage,
        ),
      );
    }
  }

  runApp(
    ProviderScope(
      overrides: [appEnvironmentProvider.overrideWithValue(environment)],
      child: const LearnTzApp(),
    ),
  );
}
