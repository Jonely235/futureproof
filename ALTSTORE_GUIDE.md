# Install FutureProof on iPhone via WiFi

> Test your Flutter app on iPhone over WiFi - No Mac needed!

---

## **Part 1: Install AltStore on iPhone (5 minutes)**

### **What is AltStore?**
AltStore is an alternative to the App Store that lets you install apps on your iPhone without a Mac. It's free and uses WiFi.

---

### **Step 1: Prepare Your iPhone**

1. **Check iOS version:**
   - Settings → General → About
   - Make sure iOS 13.0 or later
   - ✅ Your iPhone: __________

2. **Check available storage:**
   - Settings → General → iPhone Storage
   - Need at least 500MB free

3. **Connect to WiFi:**
   - Make sure your iPhone and Windows PC are on the SAME WiFi network
   - ✅ Network name: __________

---

### **Step 2: Install AltStore on iPhone**

**Method A: Direct Download (Easiest)**

1. **Open Safari on your iPhone**
2. **Go to:** https://altstore.io/
3. **Tap "Download AltStore"**
4. **Follow the on-screen instructions**
5. **Enter your Apple ID and password**
   - This is SAFE - it's just for signing the app
   - Use your regular Apple ID (free is fine!)

**Method B: Use Computer (Alternative)**

If Method A doesn't work:

1. **On your computer:** Download AltServer from https://altstore.io/
2. **Install AltServer** (Windows or Mac)
3. **Connect iPhone to computer via USB**
4. **Open AltStore on iPhone**
5. **It will detect AltServer and install**

---

### **Step 3: Trust AltStore**

1. **Open Settings on iPhone**
2. **Go to:** General → VPN & Device Management
3. **Find your Apple ID email**
4. **Tap "Trust [your email]"**
5. **Tap "Trust" again to confirm**

✅ AltStore is now installed and trusted!

---

## **Part 2: Build & Install FutureProof**

### **Option A: Automatic Build via GitHub (Recommended)**

#### **Step 1: Push Code to GitHub**

1. **Create a GitHub repository:**
   ```cmd
   cd C:\Users\US\FutureProof
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. **Go to https://github.com/new**
   - Repository name: `futureproof`
   - Make it Public
   - Click "Create repository"

3. **Push your code:**
   ```cmd
   git remote add origin https://github.com/YOUR_USERNAME/futureproof.git
   git branch -M main
   git push -u origin main
   ```

#### **Step 2: Trigger Build**

1. **Go to:** https://github.com/YOUR_USERNAME/futureproof/actions
2. **Click "Build iOS" workflow**
3. **Click "Run workflow" button**
4. **Click "Run workflow"**

Wait ~5 minutes for the build to complete ⏳

#### **Step 3: Download IPA File**

1. **Go to:** https://github.com/YOUR_USERNAME/futureproof/actions
2. **Click on the latest build**
3. **Scroll down to "Artifacts"**
4. **Click "FutureProof-iOS"**
5. **Extract the zip file**
6. **Move `FutureProof.ipa` to:**
   ```
   C:\Users\US\FutureProof\build\FutureProof.ipa
   ```

---

### **Option B: Build Locally (Requires Mac)**

Skip this if you don't have a Mac.

---

## **Part 3: Install FutureProof via WiFi**

### **Step 1: Start WiFi Server**

1. **Open PowerShell on Windows**
   - Right-click Start button
   - Windows PowerShell

2. **Navigate to project folder:**
   ```cmd
   cd C:\Users\US\FutureProof
   ```

3. **Run the server:**
   ```cmd
   .\serve_ipa.ps1
   ```

4. **You'll see:**
   ```
   🌐 Starting server on: http://192.168.1.XX:8000
   ```

5. **Write down that URL!** → _____________________

---

### **Step 2: Install on iPhone**

1. **Make sure iPhone is on same WiFi** as your computer

2. **Open Safari on iPhone**

3. **Go to the URL** shown in PowerShell:
   ```
   http://192.168.1.XX:8000
   ```

4. **You'll see:**
   - A file listing
   - Tap "FutureProof.ipa"

5. **Tap "Share" button** (square with arrow up)

6. **Scroll down and tap "AltStore"**

7. **AltStore will open and install the app**
   - Enter Apple ID password if prompted
   - Wait for installation (30 seconds)

8. **Done!** Look for "FutureProof" on your home screen! 🎉

---

## **Part 4: Using FutureProof on iPhone**

### **First Launch:**

1. **Tap "FutureProof" icon**
2. **You might see: "Untrusted Developer"**
3. **Fix:**
   - Settings → General → VPN & Device Management
   - Find your Apple ID
   - Tap "Trust"
   - Open FutureProof again

### **App Refresh (Every 7 Days):**

**Free AltStore expires apps after 7 days.** To refresh:

1. **Open AltStore on iPhone**
2. **Tap "My Apps"**
3. **Find "FutureProof"**
4. **Tap the refresh icon** 🔄
5. **Enter Apple ID password**

Do this once a week and the app keeps working!

---

## **Part 5: Updating the App**

### **When You Make Code Changes:**

1. **Make changes to code**

2. **Test on Chrome:**
   ```cmd
   flutter run -d chrome
   ```

3. **Commit and push:**
   ```cmd
   git add .
   git commit -m "Added new feature"
   git push
   ```

4. **GitHub builds automatically**
   - Wait for green checkmark
   - Download new .ipa file
   - Replace old .ipa in build folder

5. **Reinstall on iPhone:**
   - Delete old app
   - Run `.\serve_ipa.ps1`
   - Install from Safari

---

## **Troubleshooting**

### **Problem: "Cannot connect to server"**

**Solution:**
- Make sure both devices on SAME WiFi
- Check firewall on Windows (allow port 8000)
- Try turning off VPN on iPhone
- Verify IP address is correct

---

### **Problem: "AltStore can't install app"**

**Solution:**
- Make sure you entered correct Apple ID
- Try installing AltStore again
- Check you have enough storage on iPhone
- Restart iPhone and try again

---

### **Problem: "App crashes on launch"**

**Solution:**
- Make sure you're running latest iOS
- Delete and reinstall the app
- Check build succeeded on GitHub
- Look for error logs in GitHub Actions

---

### **Problem: "Python not found"**

**Solution:**
1. Download Python: https://www.python.org/downloads/
2. Install with "Add to PATH" checked
3. Restart PowerShell
4. Run `.\serve_ipa.ps1` again

---

## **Quick Reference Card**

| Task | Command/Action |
|------|----------------|
| **Start WiFi server** | `.\serve_ipa.ps1` |
| **Test on Chrome** | `flutter run -d chrome` |
| **Push changes** | `git push` |
| **Refresh app on iPhone** | AltStore → My Apps → 🔄 |
| **App expires in** | 7 days (free version) |
| **Reinstall** | Delete app → Run server → Install from Safari |

---

## **Need Help?**

### **Check GitHub Actions Status:**
https://github.com/YOUR_USERNAME/futureproof/actions

### **Check Build Logs:**
1. Go to Actions
2. Click on latest build
3. Click on "Build iOS" job
4. Scroll down to see errors

### **Common Issues:**
- **Build fails**: Check code has syntax errors
- **Can't download .ipa**: Make sure build succeeded first
- **App won't install**: Update AltStore on iPhone

---

## **Success Checklist**

- [ ] AltStore installed on iPhone
- [ ] FutureProof.ipa downloaded
- [ ] WiFi server running on PC
- [ ] iPhone on same WiFi as PC
- [ ] Can access http://IP:8000 on iPhone
- [ ] .ipa file downloaded to iPhone
- [ ] App installed via AltStore
- [ ] App launches successfully
- [ ] "Are We Okay?" button works!
- [ ] Can add expenses

**All checked? Congratulations!** 🎉🎉🎉

---

## **Next Steps**

Now that it's on your iPhone:

1. ✅ Test all features
2. ✅ Show your girlfriend
3. ✅ Get feedback
4. ✅ Make improvements
5. ✅ Repeat!

---

**Created:** January 4, 2025
**Status:** Ready to use! ✅
