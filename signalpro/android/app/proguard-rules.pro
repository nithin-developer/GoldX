# Keep Flutter classes
-keep class io.flutter.** { *; }

# Keep your app models (avoid JSON issues)
-keep class com.yourpackage.** { *; }

# Prevent removing constructors
-keepclassmembers class * {
    public <init>(...);
}

# Keep Retrofit / Dio models (if using APIs)
-keepattributes Signature
-keepattributes *Annotation*

# Avoid crash due to obfuscation
-dontwarn okhttp3.**
-dontwarn retrofit2.**