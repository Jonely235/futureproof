import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'widgets/main_navigation.dart';
import 'providers/transaction_provider.dart';
import 'theme/theme_manager.dart';

String _getEmojiForLevel(Level level) {
  if (level >= Level.SEVERE) return '❌';
  if (level >= Level.WARNING) return '⚠️';
  return 'ℹ️';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final emoji = _getEmojiForLevel(record.level);
    final timestamp = record.time.toIso8601String().substring(11, 23);
    Logger.log(
      record.level,
      '$emoji ${record.level.name} [$timestamp] ${record.loggerName}: ${record.message}',
      record.error,
      record.stackTrace,
    );
  });

  // Initialize theme manager
  final themeManager = ThemeManager();
  await themeManager.init();

  runApp(FutureProofApp(themeManager: themeManager));
}

class FutureProofApp extends StatefulWidget {
  final ThemeManager themeManager;

  const FutureProofApp({super.key, required this.themeManager});

  @override
  State<FutureProofApp> createState() => _FutureProofAppState();
}

class _FutureProofAppState extends State<FutureProofApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        Provider<ThemeManager>.value(value: widget.themeManager),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            title: 'FutureProof',
            debugShowCheckedModeBanner: false,
            theme: themeManager.getThemeData(),
            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}
