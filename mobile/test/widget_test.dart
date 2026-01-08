import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vidkeep_mobile/app.dart';

void main() {
  testWidgets('VidKeep app loads and shows home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VidKeepApp());

    // Verify the app shows the VidKeep title
    expect(find.textContaining('VIDKEEP'), findsWidgets);
    
    // Verify bottom navigation exists
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
