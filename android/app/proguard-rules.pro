# Hablas Virtual Studio ProGuard Rules

# ─── Flutter Wrapper ───────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ─── Hablas Engine ─────────────────────────────────────────────────────
-keep class com.hablas.studio.engine.** { *; }
-keep class com.hablas.studio.MainActivity { *; }

# ─── MethodChannel ─────────────────────────────────────────────────────
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ─── Reflection Support ────────────────────────────────────────────────
-keep class * implements java.lang.reflect.InvocationHandler {
    <init>(...);
    invoke(...);
}

# ─── Android System Services ──────────────────────────────────────────
-keep class android.content.pm.IPackageManager { *; }
-keep class android.app.IActivityManager { *; }
-keep class android.app.IActivityTaskManager { *; }

# ─── Kotlin ────────────────────────────────────────────────────────────
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings {
    <fields>;
}
