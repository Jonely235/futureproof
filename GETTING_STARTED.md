# Quick Start: Run FutureProof on Your Computer

> You just created your first Flutter app! Let's run it.

---

## What You Just Built

✅ **"Are We Okay?" Button** - The core feature
✅ **Smart Financial Calculator** - Generates personalized messages
✅ **Add Expense Screen** - Quick transaction entry
✅ **Clean UI** - Material Design 3
✅ **Dark Mode Support** - Respects system theme

---

## How to Run the App

### Option 1: On Your Android Phone (Easiest)

1. **Enable Developer Mode on your Android phone**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings → System → Developer Options
   - Enable "USB Debugging"

2. **Connect phone to computer via USB**

3. **Run the app**
   ```cmd
   cd C:\Users\US\FutureProof
   flutter run
   ```

That's it! The app should install and launch on your phone.

---

### Option 2: On Android Emulator

1. **Install Android Studio** (if you don't have it)
   - https://developer.android.com/studio
   - Install during setup

2. **Open Android Studio**
   - Click "More Actions" → "Virtual Device Manager"
   - Click "Create Device"
   - Choose "Pixel 6" → Next
   - Download a system image (Android 13+)
   - Finish

3. **Start the emulator**
   - Click the Play button in AVD Manager

4. **Run the app**
   ```cmd
   cd C:\Users\US\FutureProof
   flutter run
   ```

---

### Option 3: On iOS Simulator (Requires Mac)

If you have access to a Mac:

1. **Open Xcode**
   - Install from Mac App Store

2. **Open iOS Simulator**
   ```cmd
   open -a Simulator
   ```

3. **Run the app**
   ```cmd
   cd C:\Users\US\FutureProof
   flutter run
   ```

---

### Option 4: On Chrome (Web - For Quick Testing)

**Note**: Not production-ready, but good for testing UI.

```cmd
cd C:\Users\US\FutureProof
flutter run -d chrome
```

---

## What You'll See

### Main Screen
- Big "Are We Okay?" button in center
- Tap it to see your financial status
- Currently shows demo data (no Firebase yet)

### Add Expense Screen
- Tap "Add Expense" button
- Enter amount, select category
- Choose Expense or Income
- Add optional note

---

## Testing the App Right Now

1. **Run the app** (use one of the methods above)

2. **Tap "Are We Okay?"**
   - You should see: ✅ "You're doing great! You have $4,000 left."
   - This is demo data (will replace with Firebase later)

3. **Tap "Add Expense"**
   - Enter amount: `50`
   - Category: `Dining Out`
   - Tap "Add Expense"
   - You should see a success message

4. **Try different amounts**
   - Add large expenses to see different status messages
   - Try adding $2000+ to see caution message
   - Try adding $4000+ to see danger message

---

## Next Steps

### Step 1: Set Up Firebase (Optional - For Real Data)

Currently the app uses demo data. To make it work with real data:

1. **Create Firebase project**
   - Go to https://console.firebase.google.com
   - Click "Add project" → Name: "futureproof-app"

2. **Add an iOS app**
   - Click the iOS icon
   - Bundle ID: `com.yourname.futureproof`
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/` folder

3. **Add an Android app**
   - Click the Android icon
   - Package name: `com.yourname.futureproof`
   - Download `google-services.json`
   - Place in `android/app/` folder

4. **Enable services**
   - Firestore Database → Create database
   - Authentication → Enable Email/Password

5. **Update code** (I'll help you with this when ready)

---

### Step 2: Customize for Your Needs

**Change default values** in `lib/screens/home_screen.dart`:

```dart
double _monthlyIncome = 5000.0;  // Change to your income
double _savingsGoal = 1000.0;    // Change to your savings goal
```

**Add more categories** in `lib/screens/add_expense_screen.dart`:

```dart
final List<String> _categories = [
  'Groceries',
  'Dining Out',
  // Add your categories here
];
```

**Customize messages** in `lib/services/finance_calculator.dart`:

```dart
static String _generateGoodMessage(double remaining, double income) {
  // Customize these messages
  final messages = [
    "Your custom message here!",
    "Another message!",
  ];
  // ...
}
```

---

## Common Issues

### Issue: "flutter command not found"

**Solution**: Flutter isn't in your PATH

```cmd
# Add Flutter to PATH (Windows)
setx PATH "%PATH%;C:\path\to\flutter\bin"

# Or restart your terminal after installation
```

### Issue: "No devices found"

**Solution**: Connect a phone or start an emulator

```cmd
# List available devices
flutter devices

# If empty, start an emulator or connect a phone
```

### Issue: "Firebase not configured"

**Solution**: Expected! The app works with demo data for now.

- Firebase integration is coming next
- You can test all features without it
- Just ignore the "TODO: Save to Firebase" comments

### Issue: Build fails on iOS

**Solution**: Common on Windows

- iOS builds require Xcode (Mac only)
- Use Android for testing on Windows
- For iOS builds, use GitHub Actions or borrow a Mac

---

## Project Structure

```
C:\Users\US\FutureProof\
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/
│   │   └── transaction.dart         # Transaction data model
│   ├── screens/
│   │   ├── home_screen.dart         # Main screen with "Are We Okay?" button
│   │   └── add_expense_screen.dart  # Add expense/income
│   └── services/
│       └── finance_calculator.dart  # Financial calculations
├── pubspec.yaml                     # Dependencies
└── GETTING_STARTED.md              # This file
```

---

## Key Files Explained

### **lib/main.dart**
- App initialization
- Firebase setup (when ready)
- Theme configuration

### **lib/screens/home_screen.dart**
- Main screen with "Are We Okay?" button
- Shows financial status
- Navigation to other screens

### **lib/screens/add_expense_screen.dart**
- Form to add expenses/income
- Category selection
- Expense/Income toggle

### **lib/services/finance_calculator.dart**
- Calculates financial status
- Generates personalized messages
- Three levels: Good ✅, Caution ⚠️, Danger ❌

### **lib/models/transaction.dart**
- Transaction data structure
- Firestore conversion methods
- Helper functions (formatting, emoji)

---

## Demo Data vs Real Data

### Current State (Demo Data)
```dart
// In home_screen.dart
final List<Transaction> _transactions = [];  // Empty list
double _monthlyIncome = 5000.0;              // Hardcoded
double _savingsGoal = 1000.0;                // Hardcoded
```

### Future State (Firebase Data)
```dart
// Will replace with:
Stream<QuerySnapshot> _transactionsStream =  // From Firebase
FirebaseFirestore.instance
  .collection('transactions')
  .snapshots();
```

---

## Want to Continue Building?

### Next Features to Add:

1. **Firebase Integration** - Save real data
2. **Transactions List** - View all transactions
3. **Authentication** - Login/signup
4. **Multi-user Sync** - Share with girlfriend
5. **Local LLM** - AI-powered suggestions
6. **iOS Build** - Deploy to App Store

**Just ask!** I can help you build any of these features.

---

## Tips for Learning Flutter

1. **Hot Reload**: While the app is running, press `r` to reload changes
2. **Hot Restart**: Press `R` to fully restart the app
3. **Quit**: Press `q` to stop the app

4. **Debugging**: Use `print()` to see output in terminal
   ```dart
   print('Debug: Amount = $amount');
   ```

5. **UI Inspector**: Android Studio → Tools → Flutter Inspector

---

## You Just Built Something Awesome! 🎉

**What you accomplished:**
- ✅ Flutter project setup
- ✅ Multiple screens with navigation
- ✅ Form with validation
- ✅ Financial calculations
- ✅ Beautiful UI with Material Design 3
- ✅ Dark mode support
- ✅ Reusable components

**Time to next step**: Run the app and show your girlfriend! 💕

---

## Questions?

**Ask me about:**
- "How do I add Firebase?"
- "How do I customize the messages?"
- "How do I build for iOS?"
- "How do I add feature X?"

I'm here to help! 🚀

---

**Created**: January 4, 2025
**Status**: MVP Demo Working ✅
