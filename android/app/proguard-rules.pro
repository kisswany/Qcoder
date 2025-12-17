# ProGuard Rules for Qcoder App

# Keep Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Keep Mobile Scanner
-keep class com.google.mlkit.** { *; }

# Obfuscation settings
-dontoptimize
-dontpreverify
-ignorewarnings

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Prevent reverse engineering hints
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
