import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/providers.dart';
import 'providers/download_providers.dart';
import 'data/database/database.dart';

/// Custom HttpOverrides to bypass SSL certificate verification
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to landscape orientation on Android (for CarLinkit TBox)
  if (Platform.isAndroid) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  // Initialize SharedPreferences before app starts
  final prefs = await SharedPreferences.getInstance();
  
  // Check if SSL verification should be disabled
  final disableSsl = prefs.getBool('disable_ssl_verify') ?? false;
  if (disableSsl) {
    HttpOverrides.global = MyHttpOverrides();
  }
  
  // Initialize the database
  final database = AppDatabase();
  await database.ensureDefaultSettings();
  
  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences with actual instance
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Override database with initialized instance
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const VidKeepApp(),
    ),
  );
}
