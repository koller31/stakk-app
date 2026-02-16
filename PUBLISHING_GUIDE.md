# Stakk - Google Play Store Publishing Guide

Everything you need to publish Stakk on Google Play, organized as step-by-step instructions.

---

## PREREQUISITES

### 1. Google Play Developer Account
- **Cost**: One-time $25 USD registration fee (no recurring fees)
- **Sign up**: https://play.google.com/console/signup
- **Identity verification**: Required before you can publish. Takes a few days after submitting documents.
- **What you need**: Google account, credit/debit card for $25 fee, valid government ID for verification
- **IMPORTANT for new accounts**: New developer accounts (created after Nov 2023) require **20 testers to opt-in and run the app for 14 consecutive days** before you can publish to production. Plan for this!

### 2. Contact Email for Store Listing
- **Use**: joek331@gmail.com

### 3. Privacy Policy URL
- **URL**: https://koller31.github.io/stakk-app/privacy-policy.html
- This is hosted via GitHub Pages on the stakk-app repo

### 4. Terms of Service URL (Optional but recommended)
- **URL**: https://koller31.github.io/stakk-app/terms-of-service.html

---

## STORE LISTING CONTENT

### App Name (max 30 characters)
```
Stakk - Digital ID Wallet
```

### Short Description (max 80 characters)
```
Scan, encrypt, and carry all your ID cards securely on your phone. 100% offline.
```

### Full Description (max 4000 characters)
```
Stakk is a free, privacy-first digital ID wallet. Scan your physical cards with your phone camera and store AES-256 encrypted copies you can pull up anytime.

YOUR IDS, ALWAYS WITH YOU
Stop fumbling through your wallet. Stakk lets you digitize every card you carry -- driver's license, insurance cards, membership cards, gift cards, vehicle registration, employee badges, and more. Just point your camera, and Stakk's edge detection automatically crops and encrypts your card.

MILITARY-GRADE SECURITY
Your cards contain sensitive information, and Stakk treats them that way:
- AES-256-GCM encryption for every card image
- Encrypted local database for all card details
- PIN + fingerprint/face authentication
- Auto-lock after configurable timeout
- Screenshot blocking (screen capture disabled inside the app)
- Secure deletion (files overwritten before removal)
- Hardware-backed encryption keys via Android Keystore

100% OFFLINE & PRIVATE
Stakk has no servers, no cloud sync, no accounts to create, no analytics, no tracking, and no ads. Your data never leaves your device. Period.

SMART ORGANIZATION
Cards are automatically sorted into categories: IDs, Insurance, Memberships, Business, Gift Cards, Traffic Documents, and more. Add nicknames and notes to find any card instantly.

PRESENTATION MODE
Need to show your ID? Stakk's full-screen viewer maximizes your screen brightness and displays your card beautifully. Flip between front and back with a smooth 3D animation. Swipe between cards in the same category.

BUILT-IN OCR
Stakk automatically reads text from your cards using on-device optical character recognition. No internet needed -- everything is processed locally on your phone.

BUSINESS BADGES
Connect to your employer's identity system via OAuth and carry your work badge digitally. Tap your phone on NFC badge readers to check in.

FEATURES AT A GLANCE
+ Camera scanning with automatic edge detection
+ Gallery import for existing card photos
+ Front and back capture for every card
+ AES-256 encrypted storage
+ PIN + biometric authentication
+ 7 card categories with smart sorting
+ Full-screen presentation mode with brightness boost
+ On-device OCR text extraction
+ NFC badge emulation for business IDs
+ Multiple themes (dark and light)
+ Completely free, no ads, no in-app purchases

Your wallet, simplified. Your privacy, protected.
```

### App Category
- **Category**: Tools
- **Tags** (pick up to 5): Digital Wallet, ID Scanner, Document Scanner, Encryption, Privacy

---

## GRAPHICS & ASSETS

### App Icon (512 x 512 px PNG)
- Located at: `C:\Users\josep\IDswipe\store-assets\app-icon-512.png`
- **NOTE**: Needs to be regenerated with "Stakk" branding (currently says "ID")
- Upload as full square -- Google applies rounded mask automatically
- Max file size: 1 MB

### Feature Graphic (1024 x 500 px)
- Located at: `C:\Users\josep\IDswipe\store-assets\feature-graphic.png`
- **NOTE**: Needs to be regenerated with "Stakk" branding (currently says "IDswipe")

### Screenshots (min 2, max 8)
- Located at: `C:\Users\jose\IDswipe\store-assets\screenshots\`
- 7 screenshots already captured
- Requirements: JPEG or PNG, 16:9 or 9:16 aspect ratio, min 320px, max 3840px per side

---

## PLAY CONSOLE FORMS

### Data Safety Form

Answer these questions in Play Console:

**Does your app collect or share any user data?**
- Answer: **No** (all data stays on device)

**Data collection details (if they drill down):**

| Data Type | Collected? | Shared? | Notes |
|-----------|-----------|---------|-------|
| Personal info (name, email) | No | No | - |
| Financial info | No | No | - |
| Health and fitness | No | No | - |
| Messages | No | No | - |
| Photos and videos | Yes (on-device only) | No | Camera used for card scanning; images encrypted and stored locally only |
| Audio | No | No | - |
| Files and docs | No | No | - |
| Calendar | No | No | - |
| Contacts | No | No | - |
| App activity | No | No | - |
| Web browsing | No | No | - |
| App info and performance | No | No | - |
| Device or other IDs | No | No | - |
| Location | No | No | - |

**Security practices:**
- Data is encrypted in transit: N/A (no data transmitted)
- Data is encrypted at rest: **Yes** (AES-256-GCM)
- Users can request data deletion: **Yes** (delete individual cards or clear all data in Settings)
- Data deletion is complete when requested: **Yes**

### Content Rating (IARC Questionnaire)

**Does the app contain any of the following?**
- Violence: **No**
- Sexual content: **No**
- Language: **No**
- Controlled substances: **No**
- Gambling: **No**
- User-generated content: **No** (only user's own card images)
- Social/interactive features: **No**
- Shares location with other users: **No**
- Allows purchases: **No**
- Contains advertising: **No**

**Expected rating**: Everyone (E)

### Target Audience
- **Target age group**: 18+ (not designed for children)
- **Is the app designed for children?**: **No**
- **Does the app appeal to children?**: **No**

### Ads Declaration
- **Does this app contain ads?**: **No**

### App Access
- **Does the app require special access or login?**
- Answer: **Yes** -- the app requires a PIN to access (set by the user on first launch)
- **Instructions for reviewers**: "On first launch, create a 6-digit PIN (e.g., 123456). This PIN is required to access the app. You can optionally enable biometric authentication. To test features, use the camera to scan any card or ID."

### Financial Features Declaration
- **Does the app provide financial services?**: **No**
- (Required for all apps -- just select "No" for all options)

### Government Apps Declaration
- **Is this a government app?**: **No**

---

## APP SIGNING & UPLOAD

### Build the AAB
The production AAB needs to be built on the master branch with Stakk branding applied.
- Build command: `flutter build appbundle --release`
- Output location: `build/app/outputs/bundle/release/app-release.aab`

### App Signing
- Google Play App Signing is required (Google manages your signing key)
- You upload with your **upload key** (the keystore already generated)
- Keystore location: `C:\Users\josep\IDswipe\upload-keystore.jks`
- Alias: `upload`

### API Level
- Current target: API 35 (Android 15) -- meets current Play Store requirement
- API 36 (Android 16) required by August 2026

---

## PUBLISHING STEPS (Do This in Play Console)

### Step 1: Create App
1. Go to https://play.google.com/console
2. Click "Create app"
3. App name: **Stakk - Digital ID Wallet**
4. Default language: English (United States)
5. App or game: **App**
6. Free or paid: **Free**
7. Accept declarations and click Create

### Step 2: Set Up Store Listing
1. Go to "Main store listing"
2. Fill in app name, short description, full description (from above)
3. Upload app icon (512x512), feature graphic (1024x500), screenshots
4. Add contact email: joek331@gmail.com
5. Add privacy policy URL: https://koller31.github.io/stakk-app/privacy-policy.html

### Step 3: Complete App Content
1. **Privacy policy**: Enter URL
2. **Ads**: Select "No ads"
3. **App access**: Select "All or some functionality is restricted" -> Provide PIN instructions
4. **Content rating**: Complete IARC questionnaire (answers above)
5. **Target audience**: Select 18+
6. **Data safety**: Complete form (answers above)
7. **Government apps**: Select "No"
8. **Financial features**: Select all "No"

### Step 4: Testing Track (IMPORTANT for New Accounts)
1. Go to "Testing" > "Closed testing"
2. Create a new track
3. Upload the AAB
4. Add at least 20 testers by email
5. Testers must opt-in and run the app for **14 consecutive days**
6. After 14 days, you can promote to production

### Step 5: Release to Production
1. Go to "Production"
2. Create new release
3. Upload the AAB (or promote from testing track)
4. Add release notes: "Initial release of Stakk - your encrypted digital ID wallet"
5. Review and roll out

### Step 6: Post-Launch
1. Monitor the "Reviews" section for user feedback
2. Check "Crash analytics" for any issues
3. Respond to user reviews

---

## TIMELINE ESTIMATE

| Step | Time |
|------|------|
| Developer account signup + verification | 1-3 days |
| Upload AAB + store listing | 30 minutes |
| Complete all forms | 30 minutes |
| Closed testing (14-day requirement) | 14 days |
| Google review after production submission | 1-7 days |
| **Total to live on Play Store** | **~2-3 weeks** |

---

## COMMON REJECTION REASONS TO AVOID

1. **Missing privacy policy** -- We have this covered
2. **Requesting unnecessary permissions** -- Our permissions are minimal and justified
3. **Misleading description** -- Description accurately reflects app capabilities
4. **Login/access without instructions** -- We provide reviewer instructions for PIN setup
5. **Targeting children unintentionally** -- We explicitly target 18+
6. **Missing data safety form** -- Fully documented above

---

## FILES CHECKLIST

- [x] README.md
- [x] PRIVACY_POLICY.md
- [x] TERMS_OF_SERVICE.md
- [x] SECURITY.md
- [x] Privacy policy HTML (GitHub Pages)
- [x] Terms of service HTML (GitHub Pages)
- [x] Landing page HTML (GitHub Pages)
- [ ] App icon with Stakk branding (512x512)
- [ ] Feature graphic with Stakk branding (1024x500)
- [x] Screenshots (7 captured)
- [ ] Production AAB with Stakk branding
- [x] Store listing content (in this guide)
- [x] Data safety form answers (in this guide)
- [x] Content rating answers (in this guide)
- [x] PUBLISHING_GUIDE.md (this file)
