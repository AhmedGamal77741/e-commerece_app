# Deep Link Server Configuration Guide

## 📋 Files to Upload to Your Server

Both files must be placed in the `/.well-known/` directory on your server:
- `https://www.pang2chocolate.com/.well-known/apple-app-site-association`
- `https://www.pang2chocolate.com/.well-known/assetlinks.json`

Also ensure these same files are accessible on the non-www domain:
- `https://pang2chocolate.com/.well-known/apple-app-site-association`
- `https://pang2chocolate.com/.well-known/assetlinks.json`

### 1. apple-app-site-association (iOS Universal Links)
- **NO file extension** (no .json)
- **Content-Type:** `application/json`
- **Team ID:** `2JL9LPS2CM`
- **App ID:** `2JL9LPS2CM.com.pang2chocolate.app`
- **Supported paths:** `/product/*`, `/item-details*`, `/comment*`, `/bank-registered*`

### 2. assetlinks.json (Android App Links)
- **Content-Type:** `application/json`
- **Package name:** `com.pang2chocolate.pang2chocolate`
- **SHA256 fingerprint:** `07:91:C4:F5:3B:8A:E2:F3:C5:D1:38:60:B9:C6:43:E4:12:59:7A:96:C9:4E:37:52:B8:CF:D7:67:FE:11:3C:10`

> **Note:** If your release signing key changes, you must update the SHA256 fingerprint.

---

## ✅ Verification

After uploading, verify the files are accessible:

### iOS (Apple CDN check, may take up to 24h to update):
```
https://app-site-association.cdn-apple.com/a/v1/www.pang2chocolate.com
```

### Android:
```
https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://www.pang2chocolate.com&relation=delegate_permission/common.handle_all_urls
```

### Direct file check:
```
curl -I https://www.pang2chocolate.com/.well-known/apple-app-site-association
curl -I https://www.pang2chocolate.com/.well-known/assetlinks.json
```

---

## 🔧 iOS Setup Checklist

1. ✅ `Runner.entitlements` created with Associated Domains (`applinks:www.pang2chocolate.com`, `applinks:pang2chocolate.com`)
2. ✅ `project.pbxproj` updated with `CODE_SIGN_ENTITLEMENTS`
3. ✅ `Info.plist` has `FlutterDeepLinkingEnabled = true`
4. ⬜ **Enable "Associated Domains" capability** in Apple Developer Portal:
   - Go to https://developer.apple.com/account/resources/identifiers → select `com.pang2chocolate.app`
   - Enable **Associated Domains**
   - Regenerate / re-download provisioning profile
5. ⬜ Upload `apple-app-site-association` to server

## 🔧 Android Setup Checklist

1. ✅ `AndroidManifest.xml` has `android:autoVerify="true"` intent filters
2. ⬜ Upload `assetlinks.json` to server
