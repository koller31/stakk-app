# IDswipe - Play Store Production Readiness Plan

## Context
- IDswipe is a digital ID wallet app (Flutter) - scan, store, present ID cards
- 99% feature-complete, B+ architecture grade
- Production-grade security: AES-256 encryption, salted PIN hashing, screenshot prevention
- All features working: auth, card scanning, card detail viewers, NFC badges, OAuth business connections, themes, settings
- Key adoption driver for CashSwipe ecosystem
- Target: Google Play Store publication

## Phase 1 - Play Store Blockers (~1-2 hours)
Status: IN PROGRESS

### 1.1 Fix Android Manifest Permissions
- [ ] Add INTERNET permission to main AndroidManifest.xml (currently only in debug)
- [ ] Add CAMERA permission + uses-feature declaration
- File: android/app/src/main/AndroidManifest.xml

### 1.2 Remove Debug Print Statements
- [ ] Replace 24+ print() calls with debugPrint() or remove entirely
- Files: scan_card_screen.dart, card_metadata_screen.dart, wallet_card_repository.dart, aamva_service_compliant.dart, screen_pinning_service.dart, and others

### 1.3 Production Signing Configuration
- [ ] Generate production keystore (release.jks)
- [ ] Create android/key.properties with credentials
- [ ] Update android/app/build.gradle with release signing config
- [ ] Add key.properties and .jks to .gitignore
- NOTE: User needs to choose keystore password

### 1.4 Proguard Rules
- [ ] Add keep rule for com.idswipe.idswipe.** (native Kotlin)
- [ ] Add rules for flutter_appauth (net.openid.appauth.**)
- [ ] Add rules for Hive
- [ ] Add rules for flutter_secure_storage
- File: android/app/proguard-rules.pro

## Phase 2 - Production Hardening (~2-3 hours)
Status: PENDING

### 2.1 HTTP Timeouts
- [ ] Add 30s timeout to badge_api_service.dart HTTP calls
- [ ] Add 30s timeout to image_download_service.dart HTTP calls

### 2.2 Resource Leak Fixes
- [ ] Fix TextRecognizer not closed on error path (card_metadata_screen.dart)
- [ ] Verify accelerometer subscription disposal (id_card_detail_screen.dart)
- [ ] Fix sync file I/O in scan_card_screen.dart dispose

### 2.3 Null Safety
- [ ] Add null check before force-unwrap in oauth_service.dart (result.accessToken!)

### 2.4 Memory Management
- [ ] Add LRU eviction to image cache in encryption_service.dart (cap at ~50 images)

### 2.5 Crash Reporting
- [ ] Add Firebase Crashlytics dependency
- [ ] Initialize in main.dart
- [ ] Wrap runApp in runZonedGuarded
- [ ] Replace silent catch blocks with Crashlytics.recordError

## Phase 3 - Store Listing (needs user input)
Status: PENDING

### 3.1 Store Assets
- [ ] Feature graphic (1024x500 banner)
- [ ] Screenshots (4-6 phone screenshots)
- [ ] Short description (80 chars)
- [ ] Full description (up to 4000 chars)

### 3.2 Privacy Policy
- [ ] Create privacy policy page (camera, biometrics, NFC, local storage)
- [ ] Host at accessible URL

### 3.3 Play Console Setup
- [ ] Google Play Developer account ($25 one-time) - USER ACTION
- [ ] Content rating (IARC questionnaire)
- [ ] Data safety form
- [ ] Target audience declaration

## Architecture Notes (from audit)

### Strengths
- Feature-based organization (auth, home, card_scanner, card_detail, business, theme, settings)
- Provider state management with 5 ChangeNotifier providers
- Encrypted Hive storage + FlutterSecureStorage for keys
- Multi-layered security: PIN (salted SHA-256), biometrics, auto-lock, FLAG_SECURE, device security check
- Native Kotlin: NFC HCE (BadgeHceService.kt), tag reading (NfcTagReader.kt), screen pinning
- 59 Dart files, ~13,400 lines of code

### Known Limitations (acceptable for v1.0)
- English only (no i18n)
- No cloud sync (local-only storage)
- Export Data is "coming soon" placeholder
- Mixed navigation (GoRouter + imperative push for detail screens)
- No unit tests beyond 1 smoke test
- Demo mode in business connections (clearly labeled)

### Key File Paths
- Main entry: lib/main.dart
- Router: lib/core/router/app_router.dart
- Encryption: lib/core/services/encryption_service.dart
- Auth: lib/core/services/auth_service.dart + lib/features/auth/providers/auth_provider.dart
- Native NFC: android/app/src/main/kotlin/com/idswipe/idswipe/
- Build config: android/app/build.gradle
- Manifest: android/app/src/main/AndroidManifest.xml
- Proguard: android/app/proguard-rules.pro

## Dependencies (pubspec.yaml)
- Flutter SDK ^3.6.0, Dart SDK ^3.6.0
- State: provider ^6.1.1
- Nav: go_router ^13.0.0
- Storage: hive ^2.2.3, hive_flutter ^1.1.0, flutter_secure_storage ^9.0.0
- Camera: camera ^0.10.5+9, edge_detection ^1.1.1, google_mlkit_text_recognition ^0.11.0
- Barcode: barcode_widget ^2.0.4, qr_flutter ^4.1.0, mobile_scanner ^3.5.5
- OAuth: flutter_appauth ^7.0.1, http ^1.2.1
- Security: crypto ^3.0.3, encrypt ^5.0.3, safe_device ^1.1.7
- NFC: native Kotlin (no Flutter plugin)

## Timeline
- Phase 1: Immediate (today)
- Phase 2: Same day or next session
- Phase 3: Requires user action items (Play Console signup, screenshots, privacy policy)
