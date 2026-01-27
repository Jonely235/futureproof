# iCloud Setup and Troubleshooting Guide

## Overview
This guide covers setting up iCloud sync for FutureProof, including Xcode configuration,
container setup, and troubleshooting steps.

---

## CRITICAL: Swift Files Must Be Added to Xcode

### Problem
The Swift files `CloudKitService.swift` and `CloudKitPlugin.swift` exist in `ios/Runner/`
but are **NOT compiled into the app** because they're not added to the Xcode project.

**Without this step, iCloud will NEVER work.**

### Solution: Add Files in Xcode

#### Step 1: Open Xcode
```bash
cd ios
open Runner.xcworkspace
```

#### Step 2: Add Swift Files to Project
In Xcode:
1. Select "Runner" in the project navigator (left sidebar)
2. Right-click on "Runner" group → "Add Files to 'Runner'..."
3. Navigate to the `Runner` folder and select BOTH files:
   - `CloudKitService.swift`
   - `CloudKitPlugin.swift`
4. **IMPORTANT:** UNCHECK "Copy items if needed" (files already exist)
5. Select "Runner" in "Added folders" dropdown
6. Click "Add"

#### Step 3: Verify Files Are Compiled
1. In Xcode, select `CloudKitService.swift`
2. Open File Inspector (right panel, Option+Cmd+4)
3. Verify "Target Membership" includes "Runner"
4. Repeat for `CloudKitPlugin.swift`

#### Step 4: Build and Run
```bash
flutter clean
flutter pub get
flutter run
```

---

## Container ID Configuration

### Current Setup (Development)

The app uses a placeholder container ID that needs to be replaced for production:

| File | Container ID |
|------|--------------|
| `Runner.entitlements` | `iCloud.com.example.futureproof` |
| `CloudKitService.swift` | `iCloud.com.example.futureproof` |
| `Info.plist` | `iCloud.com.example.futureproof` |

### Production Setup Required

1. **Create a real Bundle Identifier** in Xcode:
   - Select Runner target
   - General tab → Bundle Identifier
   - Use something like: `com.yourcompany.futureproof`

2. **Create CloudKit Container** in Apple Developer Portal:
   - Go to: https://developer.apple.com/account/resources/cloudkit/list
   - Click "+" to create container
   - Use format: `iCloud.` + reverse bundle ID
   - Example: `iCloud.com.yourcompany.futureproof`

3. **Update all container ID references**:
   - `Runner.entitlements` (lines 7, 15)
   - `CloudKitService.swift` (line 24)
   - `Info.plist` (line 50)

---

## Using the Diagnostic Tool

The app includes a comprehensive **"Diagnose iCloud"** button:
1. Run app on iOS device
2. Go to Settings → Backup & Sync
3. Tap **"Diagnose iCloud"**

### Reading the Results

| Check | Good Value | Bad Value | Meaning |
|-------|------------|-----------|---------|
| Platform | ios | - | Running on iOS |
| iOS Available | Yes | - | iOS platform detected |
| iCloud Available | Yes | No | iCloud enabled on device |
| Native Method | Working | Not Working | **Swift files compiled** |
| Ubiquity Container | Available | Not Available | Container accessible |
| Documents Directory | Exists | Not Found | Can write to iCloud |
| Account Status | available | noAccount | Logged into iCloud |
| List Files | Success | Failed | Can read iCloud files |
| Vaults File | Exists | Not Found | Backup data exists |

### Common Issues

#### "Native Method: Not Working"
**Cause:** Swift files not added to Xcode project
**Fix:** Follow "Add Swift Files to Project" steps above

#### "Ubiquity Container: Not Available"
**Cause:** Container ID mismatch or iCloud not enabled
**Fix:**
- Verify iCloud is enabled in device Settings
- Check container ID matches in all 3 locations

#### "Account Status: noAccount"
**Cause:** Not logged into iCloud
**Fix:** Log into iCloud in device Settings → Apple ID

---

## Xcode Console Logs

When running the app, check Xcode console for detailed logs:

```
[CloudKit] Setting up iCloud Drive directory...
[CloudKit] Container identifier: iCloud.com.example.futureproof
[CloudKit] Ubiquity container URL: /var/mobile/Library/Mobile%20Documents/...
[CloudKit] saveToiCloudDrive called for file: vaults
[CloudKit] Documents URL: /var/mobile/.../Documents
[CloudKit] JSON data size: 1234 bytes
[CloudKit] SUCCESS: File written to /var/mobile/.../Documents/vaults.json
```

### Error Messages to Watch For

| Error | Cause | Fix |
|-------|-------|-----|
| "iCloud container not available" | Container ID mismatch | Check entitlements |
| "Failed to create Documents directory" | Permissions issue | Enable iCloud Drive in Settings |
| "Ubiquity container URL is nil" | Not signed into iCloud | Sign into iCloud on device |
| "File not found" | No backup yet | Run manual sync first |

---

## Testing iCloud Sync

### Manual Sync Test
1. Create a vault in the app
2. Go to Settings → Backup & Sync
3. Tap the iCloud Sync row
4. Check for "Synced to iCloud" message

### File System Verification
1. Open Files app on device
2. Go to iCloud Drive
3. Look for "FutureProof" folder
4. Verify `vaults.json` exists with your data

### Cross-Device Test
1. Install app on Device A
2. Create vault and sync
3. Install app on Device B (same iCloud account)
4. Run diagnostic on Device B
5. Verify vault data appears

---

## Developer Notes

### What Gets Synced
- Vault metadata (name, type, settings)
- All transactions for each vault
- Last modified timestamps

### Sync Triggers
- After vault creation (automatic if enabled)
- Manual sync via Settings → Backup & Sync
- Future: debounced sync after transaction changes

### File Structure in iCloud
```
iCloud Drive/
└── Documents/
    ├── vaults.json      # All vaults and transactions
    └── settings.json    # App settings (future)
```

---

## Still Having Issues?

1. **Clean build:**
   ```bash
   flutter clean
   cd ios
   rm -rf Pods/ Podfile.lock
   pod install
   cd ..
   flutter run
   ```

2. **Verify Xcode project:**
   ```bash
   grep -c "CloudKit" ios/Runner.xcodeproj/project.pbxproj
   # Should return > 0 if files are added
   ```

3. **Check device logs:**
   - Xcode → Window → Devices and Simulators
   - Select device → Console
   - Search for "CloudKit"

4. **Reset iCloud sync:**
   - Delete app from device
   - Reinstall
   - Run diagnostic before creating any vaults
