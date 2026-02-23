# Stakk - Play Store Publishing Checklist

## Technical Prep (COMPLETE)
- [x] Android manifest permissions (INTERNET, CAMERA, NFC)
- [x] Generated upload keystore (android/upload-keystore.jks)
- [x] Configured release signing in build.gradle
- [x] Comprehensive Proguard rules
- [x] Debug print statements guarded with kDebugMode
- [x] Added HTTP timeouts
- [x] Fixed TextRecognizer resource leak
- [x] Fixed OAuth null safety
- [x] Added LRU image cache (50 entry cap)
- [x] flutter analyze: 0 errors, 0 warnings
- [x] Security audit #1: 30 vulnerabilities fixed (PBKDF2 PIN hashing, brute-force lockout, NFC auto-clear, HTTPS-only, backup disabled)
- [x] Security audit #2: 17 findings fixed (FLAG_SECURE restored, demo PIN removed, biometricOnly, traffic lock PBKDF2, image cache clearing, data extraction rules)
- [x] Built signed release AAB

## Store Assets (COMPLETE)
- [x] App icon with Stakk branding (store-assets/stakk-icon-512.png)
- [x] Feature graphic (store-assets/feature-graphic.png)
- [x] Screenshots captured (store-assets/screenshots/ - 7 images)
- [x] Privacy policy live at GitHub Pages
- [x] Terms of service live at GitHub Pages
- [x] Store listing content written (see PUBLISHING_GUIDE.md)
- [x] Data safety form answers documented
- [x] Content rating answers documented

## What You Need To Do

### Step 1: Google Play Developer Account
1. Go to https://play.google.com/console/signup
2. Pay the $25 one-time fee
3. Complete identity verification (takes 1-3 days)

### Step 2: Submit the App
Use the `/play-store-submit` slash command in Claude Code to get step-by-step guidance through every Play Console form. Or read PUBLISHING_GUIDE.md for all the details.

### Step 3: Closed Testing (14 days required for new accounts)
1. Recruit 12 people to be testers
2. Add their Gmail addresses in Play Console
3. They install the app and use it for 14 days
4. After 14 days, promote to production

## Important Notes
- Keystore location: android/upload-keystore.jks
- Key config: android/key.properties
- NEVER lose the keystore -- you cannot update the app without it
- Both files are gitignored (never pushed to GitHub)
- AAB location: build/app/outputs/bundle/release/app-release.aab
