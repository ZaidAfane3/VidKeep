import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/providers.dart';
import 'providers/download_providers.dart';
import 'data/database/database.dart';

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
