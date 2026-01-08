import 'package:flutter/material.dart';
import 'widgets/main_navigation.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // For iOS/Android, sqflite handles initialization automatically
  print('✅ Running on mobile platform');

  // Initialize SQLite database
  try {
    final dbService = DatabaseService();
    await dbService.database; // Trigger initialization
    print('✅ SQLite database initialized successfully');
  } catch (e) {
    print('❌ Error initializing database: $e');
  }

  runApp(const FutureProofApp());
}

class FutureProofApp extends StatelessWidget {
  const FutureProofApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FutureProof',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MainNavigation(),
    );
  }
}
