# ProGuard rules for Password Saver app

# Keep all classes in the app package
-keep class com.example.password_saver.** { *; }

# Keep Flutter-related classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep encryption-related classes
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# Keep Hive classes
-keep class com.google.protobuf.** { *; }
-keep class androidx.lifecycle.** { *; }

# Keep local authentication
-keep class androidx.biometric.** { *; }

# Don't warn about missing classes
-dontwarn com.google.**
-dontwarn androidx.**

# Enable optimization
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose

# Keep line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Preserve Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}
