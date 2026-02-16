# Lessons Learned - IDswipe

*Lessons will be added here as you work on the project*

## 2026-02-12
- IDswipe scaffold had 12+ cross-file compile errors from AI generation inconsistencies: mismatched constructor params, nonexistent model fields, wrong enum values, missing methods. Always run flutter analyze after scaffolding before attempting builds.

## 2026-02-12
- AGP 8.1.0 is incompatible with Java 21 - upgrade to at least 8.2.1. Flutter template defaults may be outdated.

## 2026-02-16
- Android Activity recreation on Samsung: When Flutter app backgrounds for image picker/camera, Samsung's aggressive memory management can destroy the Flutter Activity. On recreation, all Dart state resets (including auth). Fix: (1) alwaysRetainTaskState=true in manifest, (2) persist critical state in FlutterSecureStorage with short expiry so it auto-restores on init. (Context: IDswipe gallery import was sending user back to lock screen every time. Auto-lock grace period alone wasn't enough -- the Activity was being killed entirely.)
