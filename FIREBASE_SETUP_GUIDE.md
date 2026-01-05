# 🔥 Firebase Setup Guide for FutureProof

This guide will walk you through setting up Firebase for FutureProof Phase 2.

---

## 📋 Prerequisites

- Google account
- FutureProof Flutter project
- 10 minutes ⏱️

---

## 🚀 Step-by-Step Setup

### **Step 1: Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `FutureProof` (or your preferred name)
4. **Disable Google Analytics** (not needed for MVP)
   - We can enable it later if desired
5. Click **"Create project"**
6. Wait for project creation (~1 minute)
7. Click **"Continue"** when ready

### **Step 2: Register iOS App**

1. In Firebase Console, click **iOS icon** (📱)
2. **Bundle ID**: Enter your iOS bundle ID
   - In Xcode: `Runner > General > Bundle Identifier`
   - Usually: `com.yourname.FutureProof` or similar
3. **App nickname**: `FutureProof iOS` (optional)
4. **App Store ID**: Leave blank for now
5. Click **"Register app"**

### **Step 3: Download Configuration File**

1. Download `GoogleService-Info.plist`
2. Move it to your Flutter project:
   ```
   FutureProof/ios/Runner/GoogleService-Info.plist
   ```
3. **IMPORTANT**: Add to Xcode project
   - Open `ios/Runner.xcworkspace` in Xcode
   - Right-click `Runner` folder in project navigator
   - Select `Add Files to "Runner"...`
   - Select `GoogleService-Info.plist`
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Check "Add to targets: Runner"
   - Click "Add"

### **Step 4: Install Firebase SDK**

The dependencies are already in `pubspec.yaml`:
```yaml
firebase_core: ^2.24.2
firebase_auth: ^4.16.0
cloud_firestore: ^4.14.0
```

Just run:
```bash
flutter pub get
```

### **Step 5: Enable Authentication**

1. In Firebase Console, go to **Build > Authentication**
2. Click **"Get Started"**
3. Select **Email/Password** provider
4. Enable it
5. Click **"Save"**

### **Step 6: Create Firestore Database**

1. In Firebase Console, go to **Build > Firestore Database**
2. Click **"Create database"**
3. Choose location (closest to your users)
   - US, Europe, Asia, etc.
4. **IMPORTANT**: Start in **Test Mode**
   - This allows development without security rules
   - We'll add proper rules later
5. Click **"Create"**

### **Step 7: Initialize Firebase (Done!)**

Firebase initialization is already in `lib/main.dart`:
```dart
await Firebase.initializeApp();
```

---

## ✅ Verification

### Test Firebase Setup

1. Run the app:
   ```bash
   flutter run
   ```

2. Check console output:
   ```
   Firebase initialized successfully ✓
   Database initialized successfully ✓
   ```

If you see "Firebase not configured yet", ensure:
- `GoogleService-Info.plist` is in the Xcode project
- It's added to the Runner target
- Bundle ID matches Firebase project

---

## 🔒 Security Rules (Test Mode)

Your Firestore is now in **Test Mode**, which means:
- ✅ Anyone can read/write (great for development!)
- ⚠️ NOT secure for production
- ⚠️ Test mode expires after 30 days

### Current Test Rules

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

### Production Rules (Coming Soon)

We'll implement proper security rules in Phase 2 completion:
- Only authenticated users can read/write
- Users can only access their household data
- Validated data types

---

## 📊 Firestore Collections

After setup, these collections will be created automatically:

### `users` Collection
```javascript
users/{userId}
{
  email: string
  name: string
  householdId: string?
  createdAt: timestamp
  lastLogin: timestamp
}
```

### `households` Collection
```javascript
households/{householdId}
{
  name: string
  members: array<string>
  createdAt: timestamp
  monthlyIncome: number
  savingsGoal: number
}
```

### `transactions` Collection
```javascript
transactions/{transactionId}
{
  householdId: string
  amount: number
  category: string
  date: timestamp
  note: string?
  createdBy: string
  createdAt: timestamp
  updatedAt: timestamp
}
```

---

## 🧪 Testing Authentication

### Create a Test User

1. Run the app
2. Go to Signup screen
3. Enter:
   - Name: Test User
   - Email: test@example.com
   - Password: password123
4. Click "Create Account"

### Verify in Firebase Console

1. Go to **Authentication > Users**
2. You should see `test@example.com`
3. Go to **Firestore Database > users**
4. You should see a document with user data

---

## 🎯 Next Steps

### Phase 2 Features (Ready to Build)

1. ✅ Firebase Setup (Complete this guide!)
2. ✅ Authentication (Code ready, needs Firebase config)
3. ⏳ Cloud Sync (Next)
4. ⏳ Household Management (Next)
5. ⏳ Real-time Updates (Next)

### After Firebase is Configured

The following features will work:
- User signup
- User login
- User logout
- Household creation
- Household joining
- Cloud data sync

---

## 🐛 Troubleshooting

### Issue: "Firebase not configured"
**Solution**:
- Ensure `GoogleService-Info.plist` is in Xcode project
- Verify bundle ID matches Firebase
- Clean build: `flutter clean && flutter pub get`

### Issue: "No Firebase App '[DEFAULT]' has been created"
**Solution**:
- Ensure `Firebase.initializeApp()` is called
- Check for errors in console
- Verify `firebase_core` is in pubspec.yaml

### Issue: Authentication fails
**Solution**:
- Enable Email/Password in Firebase Console
- Check Firebase Console > Authentication > Users
- Verify network connection

### Issue: Firestore permission denied
**Solution**:
- Ensure database is in Test Mode
- Check Firestore rules
- Wait a few minutes for rules to propagate

---

## 📚 Additional Resources

- [Firebase Flutter Docs](https://firebase.google.com/docs/flutter/setup)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Auth Flutter](https://firebase.google.com/docs/auth/flutter/start)

---

## 🎉 Ready to Go!

Once Firebase is configured:
- ✅ Authentication will work
- ✅ Users can create accounts
- ✅ Data can sync to cloud
- ✅ Multi-user households enabled

**The code is ready, just needs Firebase configuration!** 🔥

---

*Generated for FutureProof Phase 2*
*Last Updated: January 5, 2026*
