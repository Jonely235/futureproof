# Quick Start Checklist

> Step-by-step guide to start building FutureProof

---

## Before You Start

### Decision Point: What's Your Setup?

**Option A: Windows + CI/CD (Recommended)**
- Develop on Windows with Flutter
- Use GitHub Actions for iOS builds
- Cost: FREE
- Best for: You don't have a Mac

**Option B: Buy Used Mac**
- Mac Mini M1 (~$400-600)
- Native Swift + SwiftUI OR Flutter
- Full control over builds
- Best for: Long-term iOS development

**Option C: Remote Mac**
- MacStadium/AWS/Xcode Cloud (~$20-100/month)
- Remote desktop into Mac
- Best for: Temporary solution

✅ **Choose Option A for now** (can always switch later)

---

## Week 1: Setup (Estimated: 5-10 hours)

### Day 1: Install Flutter (2 hours)

- [ ] **Download Flutter SDK**
  - Go to https://flutter.dev
  - Download Windows zip
  - Extract to `C:\src\flutter` (or your preferred location)

- [ ] **Add Flutter to PATH**
  ```cmd
  # Add to Environment Variables:
  # C:\src\flutter\bin
  ```

- [ ] **Verify installation**
  ```cmd
  flutter doctor
  ```
  You should see Flutter installed successfully

- [ ] **Install VS Code** (if you don't have it)
  - https://code.visualstudio.com

- [ ] **Install Flutter extension**
  - Open VS Code
  - Extensions → Search "Flutter"
  - Install by Dart Code

### Day 2: Set up Firebase (1 hour)

- [ ] **Create Firebase project**
  - Go to https://console.firebase.google.com
  - Click "Add project"
  - Name: "futureproof-app"

- [ ] **Enable Firestore**
  - Build → Firestore Database
  - Click "Create database"
  - Choose "Start in test mode" (for now)
  - Select a location (closest to your users)

- [ ] **Enable Authentication**
  - Build → Authentication
  - Click "Get Started"
  - Enable "Email/Password"

- [ ] **Register iOS app**
  - Project settings → General → Add app
  - iOS bundle ID: `com.yourname.futureproof`
  - Download `GoogleService-Info.plist`
  - Save this file - you'll need it later

### Day 3: Create Flutter Project (1 hour)

- [ ] **Create project**
  ```cmd
  cd C:\Users\US\FutureProof
  flutter create futureproof
  cd futureproof
  ```

- [ ] **Configure Firebase**
  ```cmd
  flutter pub add firebase_core
  flutter pub add cloud_firestore
  flutter pub add firebase_auth
  ```

- [ ] **Add GoogleService-Info.plist**
  - Copy file to `ios/Runner/GoogleService-Info.plist`
  - Open `ios/Runner.xcworkspace` in Xcode (if you have Mac access)
  - Or add to project via text editor

### Day 4: Basic Project Structure (2 hours)

- [ ] **Create folder structure**
  ```cmd
  cd lib
  mkdir models
  mkdir screens
  mkdir services
  mkdir widgets
  ```

- [ ] **Create data models**
  - `lib/models/transaction.dart`
  - `lib/models/user.dart`
  - `lib/models/household.dart`

- [ ] **Create services**
  - `lib/services/firebase_service.dart`
  - `lib/services/ai_service.dart` (stub for now)

### Day 5-7: Learn & Experiment

- [ ] **Watch Flutter tutorials**
  - "Flutter & Firebase Full Course" (YouTube)
  - Focus on: Auth, Firestore, State management

- [ ] **Build a simple test app**
  - Login screen
  - Save data to Firestore
  - Read data back

- [ ] **Test on Android** (easier than iOS on Windows)
  - Enable developer mode on your Android phone
  - Run `flutter run`

---

## Week 2-3: Build MVP Core Features

### Feature 1: "Are We Okay?" Button

- [ ] **Create home screen** (`lib/screens/home_screen.dart`)

```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FutureProof')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Big button
            ElevatedButton(
              onPressed: () {
                // TODO: Calculate status
                _showAreWeOkayDialog(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(40),
                backgroundColor: Colors.blue,
              ),
              child: Text(
                'Are We Okay?',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAreWeOkayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Status'),
        content: Text('Loading...'),
      ),
    );
  }
}
```

- [ ] **Implement calculation logic**
  ```dart
  // lib/services/finance_calculator.dart

  class FinanceCalculator {
    static String getStatus({
      required double income,
      required double expenses,
      required double savingsGoal,
    }) {
      final remaining = income - expenses - savingsGoal;

      if (remaining > 0) {
        return '✅ On track! You have \$${remaining.toStringAsFixed(0)} left.';
      } else if (remaining > -income * 0.1) {
        return '⚠️ Caution. Only \$${(income - expenses).toStringAsFixed(0)} left.';
      } else {
        return '❌ Over budget by \$${abs(remaining).toStringAsFixed(0)}';
      }
    }
  }
  ```

### Feature 2: Quick Add Expense

- [ ] **Create expense screen** (`lib/screens/add_expense_screen.dart`)

```dart
class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  String _category = 'Groceries';

  final List<String> _categories = [
    'Groceries',
    'Dining Out',
    'Transport',
    'Entertainment',
    'Shopping',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Expense')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _category,
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) => setState(() => _category = value!),
              decoration: InputDecoration(labelText: 'Category'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveExpense,
              child: Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveExpense() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    // TODO: Save to Firebase

    Navigator.pop(context);
  }
}
```

- [ ] **Connect to Firebase**
  - Create transaction in Firestore
  - Structure: `{ amount, category, date, household_id }`

### Feature 3: Simple Dashboard

- [ ] **Create dashboard widget**
  - Show current month total
  - Show last 5 transactions
  - Link to "Are We Okay?"

---

## Week 4: Polish & Test

### UI Polish

- [ ] **Add colors and styling**
  - Pick a color scheme (green/blue for finance)
  - Add icons (use `flutter pub add flutter_icons`)
  - Make it look professional

- [ ] **Add loading states**
  - Show spinner when calculating
  - Show skeleton screens while loading data

- [ ] **Add error handling**
  - What if no internet?
  - What if Firebase fails?
  - Show friendly error messages

### Testing

- [ ] **Test on your phone**
  - Install TestFlight app (iOS) or use Android
  - Try all features
  - Break things intentionally

- [ ] **Test with 5 people**
  - Give to friends/family
  - Watch them use it (don't help!)
  - Ask: "What confused you?"
  - Take notes

---

## Week 5-6: Deploy to TestFlight (iOS)

### Prepare for App Store

- [ ] **Get Apple Developer account** ($99/year)
  - https://developer.apple.com
  - Enroll in program

- [ ] **Create App Store Connect listing**
  - App name: FutureProof
  - Bundle ID: com.yourname.futureproof
  - SKU: FUTUREPROOF001

- [ ] **Prepare assets**
  - App icon: 1024x1024 PNG
  - Screenshots: 6.5" display (iPhone 14, 14 Pro)
  - Description, keywords, privacy policy

### Build & Upload

- [ ] **Option A: GitHub Actions (Free)**

Create `.github/workflows/ios.yml`:

```yaml
name: Build iOS

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Build iOS (no codesign)
        run: flutter build ios --release --no-codesign

      - name: Upload build
        uses: actions/upload-artifact@v3
        with:
          name: ios-build
          path: build/ios/iphoneos/Runner.app
```

- [ ] **Option B: Codemagic (Easier)**

  1. Go to https://codemagic.io
  2. Connect GitHub repo
  3. Configure build settings
  4. Upload to TestFlight automatically

- [ ] **TestFlight beta testing**
  - Add up to 10,000 testers
  - Send to your girlfriend + friends
  - Collect feedback

---

## Week 7-8: App Store Submission

### Final Polish

- [ ] **Fix all crashes** (App Store will reject if crashes)
- [ ] **Test on multiple devices** (different screen sizes)
- [ ] **Verify all features work**
- [ ] **Write app description**
  - Be clear about what the app does
  - Highlight privacy features
  - Mention it's designed for couples

### Submit for Review

- [ ] **Submit to App Store**
  - "Prepare for Submission"
  - Fill in all required fields
  - Upload screenshots
  - Submit for review

- [ ] **Wait for review** (1-3 days typically)
  - They might reject you (common!)
  - Fix issues and resubmit
  - Don't take it personally

- [ ] **LAUNCH!** 🎉

---

## Ongoing: Next Steps

### After Launch

- [ ] **Monitor analytics**
  - How many downloads?
  - How many active users?
  - What features do they use?

- [ ] **Gather feedback**
  - Read App Store reviews
  - Talk to users
  - What's confusing?

- [ ] **Iterate**
  - Fix bugs
  - Add requested features
  - Improve AI prompts

### Phase 2: Sync + Sharing

- [ ] Implement Firebase sync
- [ ] Add multi-user households
- [ ] Build iOS widgets
- [ ] Weekly notifications

### Phase 3: Local LLM

- [ ] Set up llama.cpp
- [ ] Convert Llama 3.2 to GGUF
- [ ] Implement Swift plugin
- [ ] Connect to Flutter
- [ ] Test on device

---

## Common Issues & Solutions

### "I don't have a Mac"

**Solution:** Use GitHub Actions for iOS builds (FREE)
- Provides macOS runners
- Automatic builds
- Just push code, get .ipa file

### "Firebase is confusing"

**Solution:** Start simple
- Use Firestore for everything (don't overengineer)
- Security rules can wait
- Focus on getting it working first

### "My app was rejected"

**Common reasons:**
- Crashes on launch → Test thoroughly
- Missing metadata → Fill ALL fields
- Web view apps → Must have native functionality
- "Not enough functionality" → Add more features

**Solution:** Read rejection message carefully, fix, resubmit

### "I don't know Swift"

**Solution:**
- Flutter is fine for MVP
- Learn Swift basics later if needed
- Or stick with Flutter (lots of successful apps do)

---

## Resources

### Must-Read

- [Flutter Fire Documentation](https://firebase.flutter.dev)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [llama.cpp README](https://github.com/ggerganov/llama.cpp)

### Video Tutorials

- [Flutter & Firebase Crash Course](https://www.youtube.com/results?search_query=flutter+firebase+course)
- [iOS App Submission Tutorial](https://www.youtube.com/results?search_query=ios+app+store+submission)

### Communities

- [Flutter Discord](https://flutter.dev/community)
- [r/FlutterDev](https://reddit.com/r/FlutterDev)
- [r/iOSProgramming](https://reddit.com/r/iOSProgramming)

---

## Estimated Costs

### First Year

| Item | Cost |
|------|------|
| Apple Developer Program | $99 |
| Domain (optional) | $10-15 |
| Firebase (free tier) | $0 |
| GitHub Actions (free tier) | $0 |
| CI/CD (Codemagic free) | $0 |
| **Total** | **~$115** |

### Optional (Later)

| Item | Cost |
|------|------|
| Used Mac Mini | $400-600 |
| Remote Mac rental | $20-100/month |
| Hosting (privacy policy) | $5/month |

---

## Final Advice

### Do This First
1. **Build "Are We Okay?" button** - That's the core value
2. **Test with 5 couples** - See if it actually helps
3. **Get feedback** - What do they actually want?

### Don't Do This
1. ❌ Don't build every feature at once
2. ❌ Don't obsess over perfect UI
3. ❌ Don't spend months planning
4. ❌ Don't worry about scaling (yet)

### The Best Time to Start

**Yesterday.** The second best time is now.

Stop reading. Start coding.

---

**Good luck! 🚀**

*Created: January 4, 2025*
