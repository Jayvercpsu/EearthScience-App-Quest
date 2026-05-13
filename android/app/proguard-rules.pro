# Keep Flutter engine/plugin entry points used by reflection.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep firebase/google services bootstrap classes.
-keep class com.google.firebase.provider.FirebaseInitProvider { *; }
-keep class com.google.android.gms.** { *; }

# Flutter deferred-components compatibility shims for release shrinker.
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Strip log noise in release.
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
