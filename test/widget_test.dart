import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/main.dart';
import 'package:futureproof/theme/theme_manager.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    final themeManager = ThemeManager();
    await tester.pumpWidget(FutureProofApp(themeManager: themeManager));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
