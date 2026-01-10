import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/main.dart' as app;
import 'package:futureproof/widgets/main_navigation.dart';

void main() {
  group('FutureProof App Integration Tests', () {
    testWidgets('App launches successfully', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app title is present
      expect(find.text('FutureProof'), findsOneWidget);

      // Verify main navigation is present
      expect(find.byType(MainNavigation), findsOneWidget);
    });

    testWidgets('Home screen displays expected UI elements', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check for app title
      expect(find.text('FutureProof'), findsOneWidget);

      // Check for subtitle
      expect(find.text('Financial peace for couples'), findsOneWidget);

      // Check for main button
      expect(find.text('Are We Okay?'), findsOneWidget);

      // Check for heart icon
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('Can access financial status dialog', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap the "Are We Okay?" button
      await tester.tap(find.text('Are We Okay?'));
      await tester.pumpAndSettle();

      // Should show dialog with financial health title
      expect(find.text('Financial Health'), findsOneWidget);

      // Close the dialog
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    });

    testWidgets('All bottom navigation tabs are accessible', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final tabs = ['Home', 'History', 'Analytics', 'Settings'];

      for (final tab in tabs) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();

        // Verify we can tap each tab without errors
        expect(find.text(tab), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Can navigate between tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should start on Home tab
      expect(find.text('FutureProof'), findsOneWidget);

      // Tap on History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Should show history screen
      expect(find.text('Transaction History'), findsOneWidget);

      // Tap on Analytics tab
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Should show analytics screen
      expect(find.text('Analytics'), findsOneWidget);

      // Tap on Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should show settings screen
      expect(find.text('Settings'), findsOneWidget);

      // Return to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('FutureProof'), findsOneWidget);
    });

    testWidgets('App handles back navigation correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start on home
      expect(find.text('FutureProof'), findsOneWidget);

      // Navigate to history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify we're on history screen
      expect(find.text('Transaction History'), findsOneWidget);

      // Navigate back to home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Verify we're back home
      expect(find.text('FutureProof'), findsOneWidget);
    });

    testWidgets('Can access add expense from history', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Look for FAB or add button
      final fab = find.byType(FloatingActionButton);

      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();

        // Should show add expense screen or bottom sheet
        // We verify the app doesn't crash
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Settings screen is accessible', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should show settings title
      expect(find.text('Settings'), findsOneWidget);

      // Should have some settings options (checking for at least one)
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('App handles orientation changes gracefully', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('FutureProof'), findsOneWidget);

      // Change orientation (this simulates device rotation)
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      // App should still be functional
      expect(find.text('FutureProof'), findsOneWidget);

      // Reset to default
      await tester.binding.setSurfaceSize(null);
      await tester.pumpAndSettle();
    });
  });
}
