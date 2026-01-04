# Install Flutter on Windows

## Step 1: Download Flutter

1. **Go to**: https://flutter.dev/docs/get-started/install/windows

2. **Download**: Flutter SDK (zip file)
   - Click the latest stable release button
   - Save the file to your Downloads folder

3. **Extract the zip**:
   - Right-click the downloaded zip file
   - Extract to: `C:\src\flutter`
   - (Create the `C:\src` folder if it doesn't exist)

   **Final path should be**: `C:\src\flutter\bin`

---

## Step 2: Add Flutter to PATH

1. **Search for "Edit environment variables"** in Windows

2. **Click "Environment Variables"**

3. **Under "User variables"**:
   - Find "Path"
   - Click "Edit"
   - Click "New"
   - Add: `C:\src\flutter\bin`
   - Click OK on all dialogs

4. **Close and reopen your terminal/command prompt**

---

## Step 3: Verify Installation

Open a NEW command prompt and run:

```cmd
flutter --version
```

You should see something like:
```
Flutter 3.16.0 • channel stable
Engine • revision
```

---

## Step 4: Install Dependencies

Run:
```cmd
flutter doctor
```

It will show you what else you need to install. At minimum:

### Required:
- ✅ **Android Studio** (for Android development)
  - Download: https://developer.android.com/studio
  - Install during setup
  - This will install Android SDK and tools

### Optional (for iOS):
- Xcode (Mac only) - Can't install on Windows
- Visual Studio (for Windows desktop apps) - Optional

---

## Step 5: Accept Android Licenses

```cmd
flutter doctor --android-licenses
```
Press `y` to accept all licenses.

---

## Step 6: Connect Your Android Phone

1. **Enable Developer Mode** on your Android phone:
   - Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back → Settings → System → Developer Options
   - Enable "USB Debugging"

2. **Connect phone to computer** via USB

3. **Verify connection**:
   ```cmd
   flutter devices
   ```
   You should see your phone listed

---

## Step 7: Run the App!

```cmd
cd C:\Users\US\FutureProof
flutter run
```

The app will install and launch on your phone!

---

## Quick Installation (Alternative)

If you want a faster setup, you can use **Git**

```cmd
# 1. Clone Flutter (faster than manual download)
git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter

# 2. Add C:\src\flutter\bin to your PATH (see Step 2 above)

# 3. Run
flutter doctor
```

---

## Still Having Issues?

### Issue: "flutter command not found"
**Solution**: Restart your terminal/command prompt after adding to PATH

### Issue: "No devices found"
**Solution**:
- Make sure USB debugging is enabled on your phone
- Try a different USB cable
- Try a different USB port

### Issue: Download takes too long
**Solution**: Flutter SDK is ~1GB. Use Git clone method instead (faster)

---

## Once Flutter is Installed:

Come back here and run:
```cmd
cd C:\Users\US\FutureProof
flutter run
```

**Your app will launch!** 🚀
