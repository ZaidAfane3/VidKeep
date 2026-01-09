import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vidkeep_mobile/app.dart';
import 'package:vidkeep_mobile/providers/providers.dart';

void main() {
  testWidgets('VidKeep app loads and shows home screen', (WidgetTester tester) async {
    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app with ProviderScope
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const VidKeepApp(),
      ),
    );

    // Pump once for initial build (don't use pumpAndSettle due to animations)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify the app shows the VidKeep title
    expect(find.textContaining('VIDKEEP'), findsWidgets);
    
    // Verify bottom navigation exists
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
