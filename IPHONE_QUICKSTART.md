# 📱 Install FutureProof on iPhone - Quick Start

> Get your app on iPhone in 15 minutes! No Mac required!

---

## **What You Need:**

- ✅ iPhone (iOS 13+)
- ✅ Windows PC with your code
- ✅ Same WiFi network for both devices
- ✅ Free Apple ID
- ✅ 15 minutes

---

## **Phase 1: Install AltStore on iPhone (5 min)** ⬇️

### **Step 1: Get AltStore**

1. **Open Safari on your iPhone**
2. **Go to:** https://altstore.io/
3. **Tap "Download AltStore"**
4. **Follow instructions** (enter your Apple ID)
5. **Install AltStore** when prompted

✅ **Done!** Look for the AltStore app on your home screen

---

## **Phase 2: Push Code to GitHub (3 min)** 📤

### **Step 1: Create GitHub Repository**

1. **Go to:** https://github.com/new
2. **Name:** `futureproof`
3. **Make it Public**
4. **Click "Create repository"**

### **Step 2: Push Your Code**

**Open PowerShell on your computer:**

```cmd
cd C:\Users\US\FutureProof
git remote add origin https://github.com/YOUR_USERNAME/futureproof.git
git branch -M main
git push -u origin main
```

**Replace `YOUR_USERNAME` with your actual GitHub username!**

✅ **Done!** Your code is now on GitHub

---

## **Phase 3: Build iOS App (5 min)** 🔨

### **Automatic Build via GitHub Actions**

1. **Go to:** https://github.com/YOUR_USERNAME/futureproof/actions

2. **You'll see: "Build iOS" workflow**

3. **Click "Run workflow"** → **"Run workflow"**

4. **Wait 5 minutes** ⏳

   - Yellow dot = building
   - Green checkmark = done! ✅

5. **Download the .ipa file:**
   - Scroll down to "Artifacts"
   - Click "FutureProof-iOS"
   - Unzip the downloaded file
   - Move `FutureProof.ipa` to: `C:\Users\US\FutureProof\build\`

✅ **Done!** You have the app file!

---

## **Phase 4: Install via WiFi (2 min)** 📶

### **Step 1: Start WiFi Server**

**On your Windows PC:**

1. **Open PowerShell**
2. **Run:**
   ```cmd
   cd C:\Users\US\FutureProof
   .\serve_ipa.ps1
   ```

3. **You'll see:**
   ```
   🌐 Starting server on: http://192.168.1.XX:8000
   ```

4. **Write down that URL!** → _____________________

### **Step 2: Install on iPhone**

**On your iPhone:**

1. **Make sure you're on the SAME WiFi** as your computer

2. **Open Safari**

3. **Go to:** `http://192.168.1.XX:8000` (the URL from step 1)

4. **Tap "FutureProof.ipa"**

5. **Tap "Share" button** (↑ icon)

6. **Tap "AltStore"**

7. **Wait 30 seconds** ⏳

✅ **Done!** Look for "FutureProof" on your home screen!

---

## **Phase 5: Trust and Launch (1 min)** 🚀

### **First Launch:**

1. **Tap "FutureProof" app**
2. **If you see "Untrusted Developer":**
   - Settings → General → VPN & Device Management
   - Tap your Apple ID
   - Tap "Trust"
3. **Open FutureProof again**

4. **You should see:**
   - ❤️ Heart icon
   - "Are We Okay?" button
   - "Add Expense" button

✅ **SUCCESS!** Your app is on your iPhone!

---

## **Weekly Maintenance (Every 7 Days)** 🔄

**Free AltStore expires apps after 7 days.** To refresh:

1. **Open AltStore on iPhone**
2. **Tap "My Apps"**
3. **Find "FutureProof"**
4. **Tap refresh icon** 🔄
5. **Enter Apple ID password**

Do this once a week and it keeps working!

---

## **How to Update the App**

### **When you change the code:**

1. **Test on Chrome first:**
   ```cmd
   flutter run -d chrome
   ```

2. **Push changes:**
   ```cmd
   git add .
   git commit -m "Added feature"
   git push
   ```

3. **GitHub builds automatically** (wait for green checkmark)

4. **Download new .ipa** from GitHub Actions

5. **Delete old app on iPhone**

6. **Run:** `.\serve_ipa.ps1`

7. **Install new version** from Safari

---

## **Troubleshooting**

### **"Can't connect to server"**
- ✅ Both devices on SAME WiFi
- ✅ Check firewall allows port 8000
- ✅ Turn off VPN on iPhone

### **"AltStore won't install"**
- ✅ Reinstall AltStore
- ✅ Check Apple ID password
- ✅ Make sure enough iPhone storage

### **"App crashes on open"**
- ✅ Delete and reinstall
- ✅ Check build succeeded on GitHub
- ✅ Update iOS on iPhone

---

## **Success Checklist**

- [ ] AltStore installed on iPhone
- [ ] Code pushed to GitHub
- [ ] GitHub Actions completed (green ✅)
- [ ] .ipa file downloaded
- [ ] WiFi server running on PC
- [ ] iPhone on same WiFi
- [ ] Accessed http://IP:8000 on iPhone
- [ ] App installed via AltStore
- [ ] App opens successfully
- [ ] "Are We Okay?" button works!

**All done? Congratulations!** 🎉🎉🎉

---

## **What's Next?**

1. ✅ Test all features on iPhone
2. ✅ Show your girlfriend
3. ✅ Get feedback
4. ✅ Make improvements
5. ✅ Repeat!

---

**Need help?** Read the full guide: `ALTSTORE_GUIDE.md`

**Created:** January 4, 2025
**Status:** Ready to install! 📱✨
