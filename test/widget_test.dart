import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const FutureProofApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
