package com.example.hydrohabit.hydro_habit

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import java.util.Calendar
import org.json.JSONArray
import org.json.JSONObject

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.example.hydrohabit.ACTION_LOG_EXERCISE" || intent.action == "com.example.hydrohabit.ACTION_ADD_WATER") {
            val amount = intent.getIntExtra("amount", 0)
            if (amount > 0) {
                // 1. Update Flutter main app storage
                val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                
                // Read preferred exercise
                val preferredExercise = flutterPrefs.getString("flutter.preferred_exercise", "push_ups") ?: "push_ups"
                
                // Check if it is a new day
                val lastLogged = if (flutterPrefs.contains("flutter.last_logged_date")) {
                    flutterPrefs.getLong("flutter.last_logged_date", 0L)
                } else {
                    flutterPrefs.getLong("flutter.last_tracked_date", 0L)
                }
                
                val lastDate = Calendar.getInstance().apply { timeInMillis = lastLogged }
                val today = Calendar.getInstance()
                
                var isNewDay = false
                if (lastLogged > 0 && (lastDate.get(Calendar.YEAR) != today.get(Calendar.YEAR) ||
                    lastDate.get(Calendar.DAY_OF_YEAR) != today.get(Calendar.DAY_OF_YEAR))) {
                    isNewDay = true
                }
                
                var currentUnits = if (flutterPrefs.contains("flutter.current_workout_units")) {
                    flutterPrefs.getLong("flutter.current_workout_units", 0L)
                } else {
                    flutterPrefs.getLong("flutter.current_water_ml", 0L)
                }
                
                if (isNewDay) {
                    currentUnits = 0L // Reset for new day
                }
                
                val newCurrentUnits = currentUnits + amount
                
                val flutterEditor = flutterPrefs.edit()
                flutterEditor.putLong("flutter.current_workout_units", newCurrentUnits)
                flutterEditor.putLong("flutter.last_logged_date", today.timeInMillis)
                
                // Maintain legacy keys for backwards compatibility / transition
                flutterEditor.putLong("flutter.current_water_ml", newCurrentUnits)
                flutterEditor.putLong("flutter.last_tracked_date", today.timeInMillis)
                
                // Append log to today_logs SharedPreferences JSON list
                val todayLogsStr = flutterPrefs.getString("flutter.today_logs", "[]") ?: "[]"
                val todayLogsArray = try {
                    JSONArray(todayLogsStr)
                } catch (e: Exception) {
                    JSONArray()
                }

                val logsToSave = if (isNewDay) JSONArray() else todayLogsArray

                try {
                    val newLog = JSONObject().apply {
                        put("id", System.currentTimeMillis().toString())
                        put("exerciseId", preferredExercise)
                        put("amount", amount)
                        put("timestamp", System.currentTimeMillis())
                        put("customName", JSONObject.NULL)
                    }
                    logsToSave.put(newLog)
                    flutterEditor.putString("flutter.today_logs", logsToSave.toString())
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                
                flutterEditor.apply()
                
                // 2. Update HomeWidget storage
                val widgetPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                
                val goalUnits = if (widgetPrefs.contains("goalUnits")) {
                    widgetPrefs.getInt("goalUnits", 50)
                } else {
                    val ml = widgetPrefs.getInt("goalMl", 50)
                    if (ml == 2500) 50 else ml
                }
                
                val todayUnits = if (widgetPrefs.contains("todayUnits")) {
                    widgetPrefs.getInt("todayUnits", 0)
                } else {
                    widgetPrefs.getInt("todayMl", 0)
                }
                
                val newTodayUnits = (if (isNewDay) 0 else todayUnits) + amount
                val progress = if (goalUnits > 0) ((newTodayUnits.toFloat() / goalUnits.toFloat()) * 100).toInt() else 0
                
                widgetPrefs.edit()
                    .putInt("todayUnits", newTodayUnits)
                    .putInt("todayMl", newTodayUnits) // Sync legacy key too
                    .putInt("progress", progress)
                    .apply()
                
                // 3. Force widget redraw
                val appWidgetManager = AppWidgetManager.getInstance(context)
                
                val squareWidget = ComponentName(context, WorkoutWidgetProvider::class.java)
                val squareIds = appWidgetManager.getAppWidgetIds(squareWidget)
                if (squareIds.isNotEmpty()) {
                    val updateIntent = Intent(context, WorkoutWidgetProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, squareIds)
                    }
                    context.sendBroadcast(updateIntent)
                }
                
                val barWidget = ComponentName(context, WorkoutWidgetBarProvider::class.java)
                val barIds = appWidgetManager.getAppWidgetIds(barWidget)
                if (barIds.isNotEmpty()) {
                    val updateIntent = Intent(context, WorkoutWidgetBarProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, barIds)
                    }
                    context.sendBroadcast(updateIntent)
                }
            }
        }
    }
    
    companion object {
        fun getPendingIntent(context: Context, amount: Int): PendingIntent {
            val intent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = "com.example.hydrohabit.ACTION_LOG_EXERCISE"
                putExtra("amount", amount)
            }
            return PendingIntent.getBroadcast(
                context,
                amount, // use amount as unique request code
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}
