# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# Keep the MainActivity as it's the entry point
-keep class com.eliasantony.workout_habit.MainActivity { *; }
-keep class com.eliasantony.workout_habit.WorkoutWidgetProvider { *; }
-keep class com.eliasantony.workout_habit.WorkoutWidgetBarProvider { *; }
-keep class com.eliasantony.workout_habit.WidgetActionReceiver { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Specific app background callbacks (see line 9 above)

# WorkManager
-keep class be.tramckas.workmanager.** { *; }

# Suppress warnings for missing deferred components (Play Store)
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**
