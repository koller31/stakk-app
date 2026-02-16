# Decisions - IDswipe

*Key decisions will be logged here*

## 2026-02-12
**Decision:** Keep AuthService as optional parameter with default construction rather than requiring dependency injection

## 2026-02-12
**Decision:** Use CardCategoryMetadata.getDisplayName() in settings instead of duplicate switch statement

## 2026-02-15
**Decision:** IDswipe will ship to Google Play Store as a standalone app that also serves as a key feature module for CashSwipe adoption. Prioritizing Play Store readiness over new features.
**Rationale:** App is 99% feature-complete. User wants it shippable ASAP. IDswipe's digital ID wallet is a major CashSwipe adoption driver.
**Alternatives considered:**
- Continue adding features before shipping
- Ship as part of CashSwipe only

## 2026-02-15
**Decision:** Ship IDswipe to Play Store as standalone app + CashSwipe adoption driver

## 2026-02-15
**Decision:** Use GitHub Pages for privacy policy hosting (koller31/idswipe-privacy repo)

## 2026-02-15
**Decision:** Production keystore stored at android/upload-keystore.jks with key.properties config

## 2026-02-16
**Decision:** Use time-based grace window for auto-lock suppression instead of one-shot flag

## 2026-02-16
**Decision:** Persist auth session in FlutterSecureStorage with 5-min expiry to survive Android activity recreation

## 2026-02-16
**Decision:** Enable gallery import permanently (was disabled with canUseGallery: false)
