# Play Store Submission Walkthrough for Stakk

You are walking Josep through submitting Stakk to the Google Play Console. Josep is NOT a programmer - give clear, simple instructions with exact text to copy-paste.

## Project Context
- App name: **Stakk**
- Package: com.josepmk.idswipe (unchanged from original)
- Privacy policy URL: https://koller31.github.io/stakk-app/privacy-policy.html
- Contact email: joek331@gmail.com
- Category: Tools
- Content rating: Everyone
- Target audience: 18+ (not designed for children)
- Price: Free

## Files Available
- Store listing text: `store-listing.md` (updated to Stakk branding)
- Privacy policy: `privacy-policy.html` (updated to Stakk branding)
- Screenshots: `store-assets/screenshots/` (7 phone screenshots)
- Feature graphic: `store-assets/feature-graphic.png` (1024x500)
- App icon: `store-assets/app-icon-512.png` (512x512)
- Signed AAB: needs to be built on master branch with `flutter build appbundle --release`

## Step-by-Step Walkthrough

Guide Josep through each Play Console section one at a time. After each section:
1. Tell him exactly what to click
2. Give him exact text to copy-paste (use code blocks)
3. Tell him which file to upload and where it is on his computer
4. Wait for him to confirm before moving to the next section

### Section Order:
1. **Create App** - App name "Stakk", English US, App type, Free, declarations
2. **Store Listing** - Short description, full description, screenshots, feature graphic, icon
3. **Content Rating** - IARC questionnaire (no violence, no sexual content, no gambling, no drugs, no user-generated content)
4. **Data Safety** - No data collected, no data shared, encrypted at rest, deletion available
5. **Target Audience** - 18+, not for children
6. **App Access** - All functionality available without special access (unless PIN counts - explain PIN is user-set, not restricted)
7. **Ads Declaration** - No ads
8. **App Release** - Upload AAB, release notes
9. **Review & Publish**

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

Be patient. Go one step at a time. If Josep gets confused, simplify further.
