# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# Keep the MainActivity as it's the entry point
-keep class com.example.hydrohabit.hydro_habit.MainActivity { *; }
-keep class com.example.hydrohabit.hydro_habit.WorkoutWidgetProvider { *; }
-keep class com.example.hydrohabit.hydro_habit.WorkoutWidgetBarProvider { *; }
-keep class com.example.hydrohabit.hydro_habit.WidgetActionReceiver { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Specific app background callbacks
-keep class com.example.hydrohabit.hydro_habit.MainActivity { *; }

# WorkManager
-keep class be.tramckas.workmanager.** { *; }

# Suppress warnings for missing deferred components (Play Store)
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**
