# Stakk

**Your IDs. Encrypted. Always with you.**

Stakk is a free, privacy-first digital ID wallet for Android. Scan your physical cards with your phone camera and store encrypted copies you can pull up anytime -- no internet required, no cloud sync, no tracking.

---

## Features

### Scan & Store Any Card
- **Camera scanning** with automatic edge detection and cropping
- **Gallery import** -- add card images from your photo library
- **Front and back** capture for every card
- **OCR text extraction** -- automatically reads text from your cards on-device

### Card Types Supported
- Driver's licenses and state IDs
- Insurance cards (health, auto, dental)
- Membership cards (gym, library, rewards)
- Gift cards and loyalty cards
- Vehicle registration and traffic documents
- Employee and business IDs
- Any other card you carry

### Military-Grade Security
- **AES-256-GCM encryption** for all stored card images
- **Encrypted local database** for card metadata
- **PIN + biometric authentication** (fingerprint or face)
- **Auto-lock** with configurable timeout (30s to 15min)
- **Screenshot blocking** -- screen capture is disabled inside the app
- **Secure deletion** -- files are overwritten with random data before removal
- **Hardware-backed keys** stored in Android Keystore
- **Root/jailbreak detection** with user warnings

### Smart Organization
- **7 automatic categories**: IDs, Business, Memberships, Insurance, Gift Cards, Traffic Docs, Other
- **Custom nicknames** and notes for each card
- **Search** across all your cards
- **Recent activity** section for quick access

### Presentation Mode
- **Full-screen card viewer** optimized for showing IDs at checkpoints
- **Auto-brightness boost** when viewing cards
- **3D flip animation** to show front and back
- **Swipe navigation** between cards in the same category

### Business Features
- **OAuth business connections** for employer-issued badges
- **NFC badge emulation** -- tap your phone to badge readers
- **AAMVA-compliant barcodes** on driver's licenses

### Personalization
- **Multiple themes** available in the theme store
- **Dark and light modes**
- **Category visibility controls** -- hide categories you don't use

---

## Privacy

Stakk is built on a simple principle: **your data never leaves your device**.

- No servers, no cloud sync, no accounts to create
- No analytics, no tracking, no advertising
- No internet required (except optional business badge connections)
- All processing happens on-device
- Uninstalling the app deletes everything

Read our full [Privacy Policy](https://koller31.github.io/stakk-app/privacy-policy.html).

---

## Security Architecture

| Layer | Technology |
|-------|-----------|
| Image encryption | AES-256-GCM |
| Database encryption | AES-256 |
| Key storage | Android Keystore (hardware-backed) |
| PIN hashing | Salted SHA-256 with constant-time comparison |
| Biometrics | Device secure hardware (never accessible to app) |
| Screen protection | FLAG_SECURE (blocks screenshots/recording) |
| File deletion | Overwrite with random bytes + zeros |
| Device integrity | Root/jailbreak detection |

---

## Download

Coming soon to the [Google Play Store](https://play.google.com/store).

---

## Contact

- **Email**: joek331@gmail.com
- **Privacy Policy**: [stakk-app Privacy Policy](https://koller31.github.io/stakk-app/privacy-policy.html)
- **Terms of Service**: [stakk-app Terms of Service](https://koller31.github.io/stakk-app/terms-of-service.html)

---

## License

Copyright 2026 Stakk. All rights reserved.
