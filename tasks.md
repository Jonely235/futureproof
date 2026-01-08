# FutureProof - Development Tasks & Documentation

> "The finance app that answers 'are we going to be okay?' so you don't have to."

---

## 📊 Project Status

**Overall Progress:**
- Phase 1 (MVP): ✅ 100% Complete
- Phase 2 (Sync): ✅ 100% Complete
- Phase 3 (AI Analytics): ✅ 100% Complete
- App Store Launch: ⬜ Not Started

**Current Build Status:** iOS build blocked - Flutter 3.19.6 failed with CocoaPods dependency issues

---

## 🎯 Core Philosophy

**Reassurance over restriction. Narrative over numbers.**

Your girlfriend doesn't want a budget. She wants to know: "Are we going to be okay?"

This app answers that question.

---

## 📱 App Features

### ✅ Completed Features (MVP)

1. **"Are We Okay?" Button**
   - One tap financial health check
   - Calculates remaining budget
   - Shows status (green/yellow/red)
   - Generates encouraging messages

2. **Quick Expense Tracking**
   - Add expenses in 3 seconds
   - Pre-defined categories
   - Optional notes
   - SQLite database (local storage)

3. **Simple Dashboard**
   - Monthly summary
   - Transaction history (grouped by date)
   - Swipe-to-delete functionality
   - Search and filter
   - Bottom navigation

4. **Firebase Cloud Sync (Phase 2)**
   - Real-time data synchronization
   - Multi-user household support
   - Email/password authentication
   - Household code joining
   - Conflict resolution (last-write-wins)

5. **AI-Powered Analytics (Phase 3)**
   - Spending analysis by category
   - Monthly trend calculations
   - Anomaly detection (2x average threshold)
   - Budget vs actual comparisons
   - Visual pie and bar charts
   - Trend indicators
   - Automated insights and recommendations

### 🔲 Future Features (V2.0+)

- Local LLM integration (Llama 3.2 3B) for offline AI
- Natural language Q&A ("Can we afford a new laptop?")
- Scenario planning
- iOS home screen widgets
- Bank integration (Plaid API)
- Recurring transactions
- Category budget limits with alerts

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** (Dart) - Cross-platform development
- **Material Design 3** - UI theming
- **Provider** - State management

### Backend
- **Firebase Firestore** - Cloud database & sync
- **Firebase Auth** - User authentication
- **SQLite** - Local data persistence

### AI (Planned)
- **Local LLM** (Llama 3.2 3B) - On-device AI
- **llama.cpp** - Inference engine
- **Core ML** - Hardware acceleration

---

## 📂 Project Structure

```
FutureProof/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/
│   │   ├── transaction.dart         # Transaction data model
│   │   ├── user.dart                # User data model
│   │   └── household.dart           # Household data model
│   ├── screens/
│   │   ├── home_screen.dart         # Main dashboard
│   │   ├── add_expense_screen.dart  # Add expense form
│   │   ├── analytics_screen.dart    # Analytics & insights
│   │   └── settings_screen.dart     # Settings & budget
│   ├── services/
│   │   ├── database_service.dart    # Firebase/Firestore operations
│   │   ├── auth_service.dart        # Authentication
│   │   └── finance_calculator.dart  # Financial calculations
│   └── widgets/
│       ├── charts/                  # Custom chart widgets
│       └── common/                  # Reusable UI components
├── ios/
│   └── Runner/                      # Native iOS code
└── test/                            # Unit and widget tests
```

---

## 🚀 Setup & Installation

### For Development (Windows)

1. **Install Flutter SDK**
   ```bash
   # Download from https://flutter.dev
   # Add to PATH
   flutter doctor
   ```

2. **Clone Repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/futureproof.git
   cd futureproof
   flutter pub get
   ```

3. **Run on Chrome (for testing)**
   ```bash
   flutter run -d chrome
   ```

### Firebase Setup (Required for Sync Features)

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com
   - Create project: "futureproof-app"
   - Enable Firestore Database (test mode)
   - Enable Authentication (Email/Password)

2. **Register iOS App**
   - Bundle ID: `com.yourname.FutureProof`
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`

3. **Install Dependencies**
   ```bash
   flutter pub add firebase_core
   flutter pub add cloud_firestore
   flutter pub add firebase_auth
   ```

### iOS Build & Deployment

#### Method 1: GitHub Actions (Recommended - Free)

1. **Push code to GitHub**
2. **GitHub Actions automatically builds iOS app**
3. **Download .ipa from Actions artifacts**
4. **Install via AltStore** (see below)

#### Method 2: AltStore (Testing without Mac)

**Install AltStore on iPhone:**
1. Open Safari on iPhone
2. Go to https://altstore.io/
3. Download and install AltStore
4. Enter Apple ID (free account works)

**Build & Install:**
```bash
# On Windows PC - Start WiFi server
cd C:\Users\US\FutureProof
.\serve_ipa.ps1

# On iPhone (same WiFi):
# 1. Open Safari
# 2. Go to http://YOUR_IP:8000
# 3. Download FutureProof.ipa
# 4. Open in AltStore
```

**Important:** Free AltStore apps expire every 7 days. Refresh in AltStore → My Apps → 🔄

---

## 🐛 Known Issues

### iOS Build Blocked - Flutter/Firebase Incompatibility

**Problem:** Cannot build iOS apps with:
1. Flutter 3.38.5 OR 3.19.6 (both tested)
2. Firebase (Auth, Firestore)
3. ANY Flutter plugin (shared_preferences, etc.)

**Root Cause:** Firebase requires `use_modular_headers!` which breaks ALL Flutter plugins. This is a fundamental Flutter/Firebase ecosystem bug.

**Solutions:**

1. **Option 1: Downgrade Flutter** (RECOMMENDED)
   - Change `.github/workflows/ios.yml`
   - Set `flutter-version: '3.16.0'` or lower
   - Firebase and plugins work fine
   - Low risk, well-tested

2. **Option 2: Wait for Fix**
   - Waiting for Flutter or Firebase team to fix
   - Timeline unknown (weeks/months)

3. **Option 3: Remove Firebase**
   - Breaks authentication, sync, household features
   - Not recommended

**Current Status:** Phase 1-3 features work on web/Android. iOS build blocked.

---

## 📊 Data Models

### Transaction Model
```dart
{
  "id": String,
  "householdId": String,
  "amount": double,  // negative for expenses, positive for income
  "category": String,  // Groceries, Dining, Transport, etc.
  "date": DateTime,
  "note": String?,
  "createdBy": String,
  "createdAt": DateTime,
  "updatedAt": DateTime
}
```

### Household Model
```dart
{
  "id": String,
  "name": String,
  "members": List<String>,  // User IDs
  "monthlyIncome": double,
  "savingsGoal": double,
  "createdAt": DateTime
}
```

### User Model
```dart
{
  "id": String,
  "email": String,
  "name": String,
  "householdId": String?,
  "createdAt": DateTime
}
```

---

## 🎨 UI/UX Guidelines

### Design Principles
- **Simple over complex**: One screen, one purpose
- **Reassurance over restriction**: Encouraging messages
- **Narrative over numbers**: Explain, don't just show data
- **Fast**: Load in <2 seconds
- **Beautiful**: Material Design 3, smooth animations

### Color Scheme
- **Green**: On track / Safe
- **Yellow**: Caution / Warning
- **Red**: Over budget / Danger
- **Primary**: Blue (calm, trustworthy)

---

## 📈 Analytics Features (Phase 3)

### Spending Analysis
- Category breakdowns (pie chart)
- Monthly comparisons
- Trend indicators (up/down arrows)
- Budget health (progress bars)

### Automated Insights
- Overspending alerts
- Unusual transaction detection (2x average)
- Budget optimization suggestions
- Savings rate tracking
- 50/30/20 rule recommendations

### Visualizations
- Pie charts (category spending)
- Bar charts (monthly trends, vertical & horizontal)
- Budget progress indicators
- Trend arrows with percentages

---

## 🔐 Security & Privacy

### Firebase Security Rules (Test Mode)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**Note:** Currently in test mode. Production rules needed before App Store launch.

### Best Practices
- ✅ Encrypt data in transit (HTTPS/TLS)
- ✅ Firebase Authentication required
- ✅ Server-side validation
- ✅ No sensitive data in local logs
- ❌ Don't store bank credentials
- ❌ Don't sell data

---

## 💰 Costs

### Required
- Apple Developer Program: $99/year
- Firebase: Free tier (up to limits)
- GitHub Actions: Free tier (2000 minutes/month)

### Estimated First Year: ~$115

### Optional
- Used Mac Mini: $400-600 (for native builds)
- Remote Mac rental: $20-100/month
- Domain name: $10-15/year

---

## 📅 Development Timeline

### ✅ Completed
- [x] Phase 1: MVP (local storage, basic features)
- [x] Phase 2: Firebase sync & multi-user
- [x] Phase 3: AI analytics & insights

### 🔲 Next Steps
1. **Fix iOS build** (downgrade Flutter or wait for fix)
2. **App Store submission**
   - Apple Developer account
   - App Store Connect listing
   - Screenshots & metadata
   - Privacy policy
3. **TestFlight beta testing**
4. **App Store review**
5. **Launch!** 🎉

---

## 🎯 Success Metrics

### Post-Launch Goals
- Week 1: >100 downloads, >50% Day 1 retention
- Week 4: >500 active users, >30% weekly retention
- Month 3: >2000 active users, >4.0 star rating

### Key Metrics to Track
- Daily active users
- Retention rate
- Feature usage (especially "Are We Okay?" button)
- Crash rate (<1%)

---

## 📚 Resources

### Learning
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Flutter Codelabs](https://firebase.google.com/codelabs)
- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)

### Inspiration
- [Dribbble - Finance App Designs](https://dribbble.com/tags/finance-app)
- [Mobbin - Mobile App Patterns](https://mobbin.com)

---

## 🔧 Quick Commands

```bash
# Install dependencies
flutter pub get

# Run on Chrome (testing)
flutter run -d chrome

# Run on Android
flutter run

# Build for iOS (requires Mac)
flutter build ios --release

# Clean build
flutter clean

# Run tests
flutter test

# Format code
dart format .

# Analyze code
flutter analyze
```

---

## 📝 Notes

### Decisions Made
1. Using Flutter for cross-platform development (iOS first, Android later)
2. Using Provider for state management
3. Material Design 3 for UI theming
4. GitHub Actions for automated iOS .ipa builds
5. AltStore + WiFi installation for testing without Mac
6. Firebase Firestore for cloud sync (Phase 2)
7. SQLite for local persistence (Phase 1)

### Lessons Learned
1. GitHub Actions can automatically build and commit .ipa files
2. Flutter provides excellent cross-platform support
3. Material Design 3 makes theming and dark mode straightforward
4. Can test iOS apps on Windows using AltStore + clever workarounds
5. Firebase integration has critical blocker with Flutter plugins (iOS build issue)

---

## 🚨 Critical Blockers

1. **iOS Build Failure** (HIGH PRIORITY)
   - Flutter 3.19.6 + Firebase + Plugins = Build failure
   - Solution: Downgrade to Flutter 3.16.0 or wait for fix
   - Timeline: Unknown

---

## 💡 Motivation

### Remember

> "The best app is the one that actually exists."

> "Shipping beats perfection."

> "Your girlfriend doesn't need features. She needs reassurance."

### When You're Stuck

1. Take a break (go for a walk)
2. Talk to a potential user
3. Remember why you started
4. Do the smallest possible thing
5. Keep going

---

**Last Updated**: January 8, 2026

**Keep moving forward! 🚀**
