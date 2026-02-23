# Play Store Submission Walkthrough for Stakk

You are walking Joseph through submitting Stakk to the Google Play Console. Joseph is NOT a programmer - give clear, simple instructions with exact text to copy-paste.

## Project Context
- App name: **Stakk - Digital ID Wallet**
- Package: com.idswipe.idswipe (unchanged from original)
- Privacy policy URL: https://koller31.github.io/stakk-app/privacy-policy.html
- Contact email: joek331@gmail.com
- Category: Tools
- Content rating: Everyone
- Target audience: 18+ (not designed for children)
- Price: Free
- Security audits: 2 audits passed (30 + 17 findings fixed, Feb 2026)

## Files Available
- Full publishing guide: `PUBLISHING_GUIDE.md` (read this first for all form answers)
- Store listing text: in PUBLISHING_GUIDE.md under "STORE LISTING CONTENT"
- Privacy policy: live at https://koller31.github.io/stakk-app/privacy-policy.html
- Screenshots: `store-assets/screenshots/` (7 phone screenshots)
- Feature graphic: `store-assets/feature-graphic.png` (1024x500)
- App icon: `store-assets/stakk-icon-512.png` (512x512)
- Signed AAB: `build/app/outputs/bundle/release/app-release.aab`
- Keystore: `android/upload-keystore.jks` (NEVER share or commit this)

## Step-by-Step Walkthrough

Guide Joseph through each Play Console section one at a time. After each section:
1. Tell him exactly what to click
2. Give him exact text to copy-paste (use code blocks)
3. Tell him which file to upload and where it is on his computer
4. Wait for him to confirm before moving to the next section

### Section Order:
1. **Create App** - App name "Stakk - Digital ID Wallet", English US, App type, Free, declarations
2. **Store Listing** - Short description, full description, screenshots, feature graphic, icon
3. **Content Rating** - IARC questionnaire (no violence, no sexual content, no gambling, no drugs, no user-generated content)
4. **Data Safety** - No data collected, no data shared, encrypted at rest, deletion available
5. **Target Audience** - 18+, not for children
6. **App Access** - Functionality is restricted (PIN required). Reviewer instructions: "On first launch, create a 4-digit PIN (e.g., 1234). This PIN is required to access the app. You can optionally enable biometric authentication. To test features, use the camera to scan any card or ID, or import from gallery."
7. **Ads Declaration** - No ads
8. **Financial Features** - No financial services
9. **Government Apps** - Not a government app
10. **App Release** - Upload AAB from `build/app/outputs/bundle/release/app-release.aab`, release notes
11. **Review & Publish**

### Data Safety Answers (critical - wrong answers = rejection):
- Does your app collect or share any user data? **No** (all data stays on device)
- Does your app use encryption? **Yes** (AES-256 for card images)
- Can users request data deletion? **Yes** (in-app delete + full reset)
- Is data encrypted in transit? **N/A** (no data transmitted)
- Is data encrypted at rest? **Yes**

### Common Rejection Reasons to Avoid:
- Privacy policy URL must be live and accessible
- Screenshots must show actual app (not mockups)
- App must match store description
- Data safety form must accurately reflect app behavior
- Content rating must match actual content

Be patient. Go one step at a time. If Joseph gets confused, simplify further.
