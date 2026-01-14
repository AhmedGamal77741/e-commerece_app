# Deep Link Server Configuration Guide

## ⚠️ IMPORTANT: Getting Your Android SHA256 Fingerprint

Before uploading these files, you MUST get your app's SHA256 fingerprint.

### For Debug Build (Testing):
Run this command in PowerShell:
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Look for the line: **SHA256: XXXX:XXXX:XXXX...**

### For Release Build (Production):
You'll need the SHA256 from your signing keystore. Contact your team lead for this.

---

## 📋 Files to Upload to Your Server

### 1. assetlinks.json
- **Destination:** `https://app.pang2chocolate.com/.well-known/assetlinks.json`
- **Content-Type:** application/json
- **Action:** 
  1. Open `assetlinks.json` file
  2. Replace `YOUR_SHA256_FINGERPRINT_HERE` with your actual SHA256 fingerprint
  3. Upload to your server

### 2. apple-app-site-association
- **Destination:** `https://app.pang2chocolate.com/.well-known/apple-app-site-association`
- **NO file extension** (no .json)
- **Content-Type:** application/json
- **Action:**
  1. Open `apple-app-site-association` file
  2. Replace `TEAMID` with your Apple Team ID (10-character code)
  3. If you don't have it, check your Apple Developer Account or ask your team
  4. Upload to your server

### 3. Verify Files Are Accessible
After upload, test these URLs in your browser:
- `https://app.pang2chocolate.com/.well-known/assetlinks.json` - should download as JSON
- `https://app.pang2chocolate.com/.well-known/apple-app-site-association` - should show JSON content

---

## 🔍 How to Find Your Apple Team ID

1. Go to https://developer.apple.com/account/
2. Sign in with your Apple ID
3. Click "Membership" in the sidebar
4. Look for "Team ID" - it's a 10-character code (e.g., ABCD1E2F3G)

---

## Next Steps (After Uploading)

Once you've uploaded these files and verified they're accessible:
1. We'll update your Android manifest
2. We'll update your iOS configuration
3. We'll enhance Flutter's deep link handling
4. We'll test everything

**Let me know when you've uploaded these files and found your Apple Team ID!**
