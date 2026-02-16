# IDswipe ProGuard Rules

# Keep app's native Kotlin code (NFC, screen pinning, HCE)
-keep class com.idswipe.idswipe.** { *; }

# Google MLKit - keep all text recognition classes
-keep class com.google.mlkit.vision.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }

# MLKit language-specific text recognizer options (referenced at runtime)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Flutter wrapper for MLKit
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google_mlkit_commons.** { *; }

# flutter_appauth / AppAuth
-keep class net.openid.appauth.** { *; }
-dontwarn net.openid.appauth.**

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Hive
-keep class io.hive.** { *; }
-keep class ** implements io.hive.TypeAdapter { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
