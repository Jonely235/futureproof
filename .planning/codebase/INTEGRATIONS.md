# Integrations

**Analysis Date:** 2026-01-11

## External APIs

**Status:** No external API integrations detected

**Findings:**
- No HTTP client libraries (http, dio, etc.)
- No API calls to external services
- No REST or GraphQL clients
- No webhooks or callbacks to external services

**Note:** The app is designed as a standalone finance app with no external data dependencies. All financial data is entered manually by the user and stored locally.

## Data Storage

**Primary:** SQLite (sqflite)
- Library: `sqflite ^2.3.0`
- Location: `lib/services/database_service.dart`
- Purpose: Transaction storage and retrieval
- Platform: iOS, Android (native SQLite)
- Web Fallback: In-memory storage (no SQLite on web)

**Secondary:** SharedPreferences
- Library: `shared_preferences ^2.2.2`
- Location: Used throughout services and screens
- Purpose: Key-value storage for app settings
- Stored values:
  - `monthly_income` - User's monthly income
  - `savings_goal` - Savings target amount
  - `category_budgets` - Per-category spending limits (JSON)
  - `selected_theme` - Theme preference index
  - `last_backup_timestamp` - Last backup date

**File System:**
- Libraries: `path ^1.8.3`, `path_provider ^2.1.1`
- Purpose: Export/import backup files
- Used by: `lib/services/backup_service.dart`
- Access: Platform-agnostic paths via path_provider

## Services

**Local Services Only:**

**DatabaseService:**
- Location: `lib/services/database_service.dart`
- Operations: CRUD for transactions
- Platform: SQLite (mobile), in-memory (web)
- No external dependencies

**AnalyticsService:**
- Location: `lib/services/analytics_service.dart`
- Operations: Financial analysis, insights, trends
- Data source: Local database only
- No external analytics services

**BackupService:**
- Location: `lib/services/backup_service.dart`
- Operations: JSON export/import
- Storage: Local file system (user chooses location)
- No cloud backup integration

**FinanceCalculator:**
- Location: `lib/services/finance_calculator.dart`
- Operations: Financial status calculations
- Pure business logic, no external calls

## Third-party Tools

**Not Detected:**
- No payment processing (Stripe, PayPal, Braintree)
- No analytics (Firebase Analytics, Mixpanel, Amplitude)
- No crash reporting (Sentry, Bugsnag, Crashlytics)
- No APM (Datadog, New Relic)
- No push notifications (Firebase Messaging, OneSignal)
- No authentication (Firebase Auth, Auth0)
- No cloud storage (Firebase Storage, AWS S3)

**Note:** The app is privacy-focused with all data stored locally on the device.

## Authentication & Identity

**Status:** No authentication system

**Findings:**
- No user accounts detected
- No login/signup flows
- No multi-user support
- Models exist (`User`, `Household`) but not implemented
- Single-user, single-device design

**Future:** Models suggest potential for household/account sharing in future versions.

## Monitoring & Observability

**Logging:**
- Library: `logging ^1.2.0` (configured but not extensively used)
- Location: `lib/main.dart` (basic logger setup)
- Output: Console with colored messages
- No log aggregation or external logging service

**Error Tracking:**
- No error tracking service
- Errors logged via print statements
- User sees errors via SnackBar messages
- No crash reporting

**Analytics:**
- No usage analytics
- No user behavior tracking
- No A/B testing framework

## CI/CD & Deployment

**Not Detected:**
- No CI/CD configuration files (GitHub Actions, GitLab CI, etc.)
- No automated testing in CI
- No deployment scripts
- Manual build and deployment process

**Deployment Targets:**
- iOS: Requires AltStore/sideloading (no App Store build configured)
- Android: APK build (no Play Store build configured)
- Web: Basic support (for UI testing only)

## Environment Configuration

**No Environment Variables:**
- No .env files detected
- No .env.example
- No environment-specific configuration
- All configuration hardcoded or in SharedPreferences

**Configuration:**
- Financial parameters in `lib/config/finance_config.dart`
- Theme definitions in `lib/theme/app_theme.dart`
- No environment-specific settings (dev/staging/prod)

## Webhooks & Callbacks

**None Detected:**
- No incoming webhook handlers
- No outgoing webhook triggers
- No callback URLs configured
- No third-party integrations requiring callbacks

**Note:** The app operates entirely offline with no server communication.

---

*Integrations analysis: 2026-01-11*
*Update when external services are added*
