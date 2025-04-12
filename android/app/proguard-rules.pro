# Flutter related rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Dart related rules
-keep class com.example.smch_mobile.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Third party libraries
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.** { *; }

# Prevent proguard from stripping interface information
-keepclassmembers,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Keep Parcelable classes (required for Android Bundles)
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep setters in Views
-keepclassmembers public class * extends android.view.View {
   void set*(***);
   *** get*();
} 