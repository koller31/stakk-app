# Stakk - Play Store Publishing Checklist

## What Claude Has Done (COMPLETE)
- [x] Fixed Android manifest (INTERNET, CAMERA permissions)
- [x] Generated production keystore (upload-keystore.jks)
- [x] Configured release signing in build.gradle
- [x] Comprehensive Proguard rules
- [x] Removed all debug print statements
- [x] Added HTTP timeouts
- [x] Fixed TextRecognizer resource leak
- [x] Fixed OAuth null safety
- [x] Added LRU image cache (50 entry cap)
- [x] Added path package dependency
- [x] flutter analyze: 0 errors, 0 warnings
- [x] Written privacy policy (privacy-policy.html)
- [x] Written store listing (store-listing.md)
- [x] Built signed release APK
- [x] Created feature graphic (store-assets/feature-graphic.png)

## What You Need To Do

### Step 1: Host the Privacy Policy -- DONE
- Privacy policy is live at: https://koller31.github.io/stakk-app/privacy-policy.html
- Source repo: https://github.com/koller31/stakk-app

### Step 2: Create a Contact Email
- Contact email: joek331@gmail.com
- This goes in the Play Store listing and privacy policy

### Step 3: Take Screenshots on Your Samsung
Install the release APK and take these screenshots (1080x1920 or similar):
1. Lock screen / PIN entry
2. Home screen with some cards
3. Card detail view (front of an ID)
4. Card scanner in action
5. Store
6. Settings screen
(Minimum 2 required, recommend 4-6)

### Step 4: Play Console Submission
1. Go to https://play.google.com/console
2. Create New App
   - App name: Stakk
   - Default language: English (US)
   - App type: App (not game)
   - Free
3. Store Listing tab:
   - Paste short description from store-listing.md
   - Paste full description from store-listing.md
   - Upload feature graphic (1024x500)
   - Upload phone screenshots
   - Upload app icon (512x512)
4. Content Rating:
   - Fill out IARC questionnaire
   - Answer: No violence, no sexual content, no gambling, no drugs
   - Expected rating: Everyone
5. Data Safety:
   - Follow responses in store-listing.md "Data Safety Responses" section
   - Key answer: App does NOT collect or share data
6. Target Audience:
   - Select: 18+
   - Not designed for children
7. App Release:
   - Upload the APK from: Stakk/build/app/outputs/flutter-apk/app-release.apk
   - OR use App Bundle: Stakk/build/app/outputs/bundle/release/app-release.aab
8. Review and Publish

### Step 5: Wait for Review
- Google typically reviews in 1-7 days for new accounts
- May take longer for first submission

## Important Notes
- Keystore password: idswipe2026 (change this if you want more security)
- Keystore location: android/upload-keystore.jks
- NEVER lose the keystore -- you cannot update the app without it
- Consider backing up the keystore to a secure location
- The key.properties and .jks files are already in .gitignore
