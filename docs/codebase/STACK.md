# Technology Stack

**Analysis Date:** 2026-01-11

## Languages

**Primary:**
- Dart >=3.0.0 <4.0.0 - All application code

**Secondary:**
- None (Dart-only codebase)

## Runtime

**Environment:**
- Flutter SDK (cross-platform mobile framework)
- Dart SDK >=3.0.0 <4.0.0
- No server-side runtime (client-side only)

**Package Manager:**
- Pub (Flutter's package manager)
- Lockfile: `pubspec.lock` present

## Frameworks

**Core:**
- Flutter - Cross-platform mobile UI framework (iOS, Android, Web)
- Material Design 3 - Design system (uses Material 3 components)

**State Management:**
- Provider ^6.1.1 - Reactive state management with ChangeNotifier

**Testing:**
- Flutter test framework - Widget and integration tests
- flutter_test SDK - Built-in testing utilities

**Build/Dev:**
- Dart compiler - Ahead-of-time (AOT) and JIT compilation
- Flutter build tools - Platform-specific builds

## Key Dependencies

**Critical:**
- Provider ^6.1.1 - State management pattern for reactive UI updates
- sqflite ^2.3.0 - Local SQLite database for transaction storage
- sqflite_common_ffi ^2.3.0 - SQLite FFI for web/testing support
- shared_preferences ^2.2.2 - Key-value storage for app settings

**Infrastructure:**
- path ^1.8.3 - Platform-agnostic path manipulation
- path_provider ^2.1.1 - Access to device file system paths
- intl ^0.18.1 - Internationalization and date/number formatting
- uuid ^4.3.3 - UUID generation for transaction IDs
- logging ^1.2.0 - Structured logging

**UI:**
- google_fonts ^6.1.0 - Access to Google Fonts (Playfair Display, Space Grotesk)
- cupertino_icons ^1.0.6 - iOS-style icons

## Configuration

**Environment:**
- No .env files detected
- Configuration via SharedPreferences (stored locally)
- Hardcoded defaults in `lib/config/finance_config.dart`

**Build:**
- `pubspec.yaml` - Dependency manifest
- Material Design 3 enabled (`uses-material-design: true`)

## Platform Requirements

**Development:**
- Flutter SDK 3.x
- Dart SDK >=3.0.0 <4.0.0
- Android Studio / VS Code with Flutter extension
- iOS: Xcode (for iOS builds)
- Android: Android SDK

**Production:**
- **iOS:** 12.0+ (via Flutter iOS deployment target)
- **Android:** API 21+ (Android 5.0 Lollipop)
- **Web:** Modern browsers with WebGL support (limited functionality)
- **Testing:** In-memory storage for web platform (no SQLite)

---

*Stack analysis: 2026-01-11*
*Update after major dependency changes*
