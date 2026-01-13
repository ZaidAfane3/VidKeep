import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/providers.dart';
import 'providers/download_providers.dart';
import 'data/database/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
