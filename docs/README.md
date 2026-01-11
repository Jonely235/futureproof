# FutureProof Documentation

> **"The finance app that answers 'are we going to be okay?' so you don't have to."**

Welcome to the FutureProof documentation. This directory contains comprehensive documentation for the FutureProof personal finance application.

---

## 📚 Documentation Index

### Getting Started
- **[README.md](../README.md)** - Project overview and quick start guide

### Development
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Developer guidelines, context detection, and coding standards
- **[STATUS.md](STATUS.md)** - Project status, assessment, and code quality analysis
- **[TASKS.md](TASKS.md)** - Active development tasks and improvement roadmap

### Guides
- **[GUIDES/code_quality_guide.md](GUIDES/code_quality_guide.md)** - Code quality best practices and patterns
- **[GUIDES/testing_guide.md](GUIDES/testing_guide.md)** - Comprehensive testing strategy and examples

---

## 🎯 Core Philosophy

**Reassurance over restriction. Narrative over numbers.**

Your girlfriend doesn't want a budget. She wants to know: "Are we going to be okay?"

This app answers that question.

---

## 📱 App Overview

**What is FutureProof?**
- A personal finance application for couples
- Focuses on simple financial health reassurance rather than complex budgeting
- Built with Flutter for cross-platform development
- Uses local SQLite storage for privacy

**Key Features:**
1. "Are We Okay?" Button - One tap financial health check
2. Quick Expense Tracking - Add expenses in 3 seconds
3. Simple Dashboard - Monthly summary with transaction history
4. AI-Powered Analytics - Spending analysis and insights
5. Local Data Storage - All data stays on your device

---

## 🛠️ Tech Stack

```
Frontend:  Flutter 3.27.0 (Dart SDK 3.0+)
Database:  SQLite (mobile), In-Memory (web)
State:     Provider 6.1.1
Utils:     intl, uuid, shared_preferences
```

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
│   │   ├── database_service.dart    # Database operations
│   │   ├── finance_calculator.dart  # Financial calculations
│   │   └── analytics_service.dart   # Analytics & insights
│   └── widgets/
│       ├── charts/                  # Custom chart widgets
│       └── common/                  # Reusable UI components
├── ios/                             # Native iOS code
├── android/                         # Native Android code
├── test/                            # Unit and widget tests
└── docs/                            # This documentation
```

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.27.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/futureproof.git
cd futureproof

# Install dependencies
flutter pub get

# Run on Chrome (for testing)
flutter run -d chrome

# Run on Android
flutter run

# Build for iOS (requires Mac)
flutter build ios --release
```

---

## 📊 Development Status

**Overall Progress:**
- Phase 1 (MVP): ✅ 100% Complete
- Phase 2 (Sync): ✅ 100% Complete
- Phase 3 (AI Analytics): ✅ 100% Complete
- App Store Launch: ⬜ Not Started

**Current Build Status:** iOS build READY

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Analyze code
flutter analyze
```

---

## 📝 Contributing

Please see [DEVELOPMENT.md](DEVELOPMENT.md) for coding standards and contribution guidelines.

---

## 📄 License

[Your License Here]

---

**Last Updated**: January 11, 2026
