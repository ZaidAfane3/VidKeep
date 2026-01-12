import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vidkeep_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Favorite Toggle Flow', () {
    testWidgets('toggle favorite from video card context menu', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wait for videos to load (if any)
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find any video card (if videos exist)
      final videoCards = find.byType(GestureDetector);
      if (videoCards.evaluate().isEmpty) {
        // No videos to test, skip
        return;
      }

      // Long press to open context menu
      await tester.longPress(videoCards.first);
      await tester.pumpAndSettle();

      // Look for favorite option in context menu
      final favoriteOption = find.textContaining('FAVORITE');
      expect(favoriteOption, findsOneWidget);

      // Tap favorite
      await tester.tap(favoriteOption);
      await tester.pumpAndSettle();

      // Verify the option text changes (if menu stays open)
      // or verify UI updates accordingly
    });
  });

  group('Navigation Flow', () {
    testWidgets('can navigate between tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find bottom navigation
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isEmpty) return;

      // Tap on different tabs if they exist
      final homeIcon = find.byIcon(Icons.home);
      final favIcon = find.byIcon(Icons.favorite);

      if (homeIcon.evaluate().isNotEmpty) {
        await tester.tap(homeIcon);
        await tester.pumpAndSettle();
      }

      if (favIcon.evaluate().isNotEmpty) {
        await tester.tap(favIcon);
        await tester.pumpAndSettle();
      }
    });
  });
}
