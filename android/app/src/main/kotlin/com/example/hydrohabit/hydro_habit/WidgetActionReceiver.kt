package com.example.hydrohabit.hydro_habit

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import java.util.Calendar

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.example.hydrohabit.ACTION_ADD_WATER") {
            val amount = intent.getIntExtra("amount", 0)
            if (amount > 0) {
                // 1. Update Flutter main app storage
                val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                
                // Check if it is a new day
                val lastTracked = flutterPrefs.getLong("flutter.last_tracked_date", 0L)
                val lastDate = Calendar.getInstance().apply { timeInMillis = lastTracked }
                val today = Calendar.getInstance()
                
                var isNewDay = false
                if (lastTracked > 0 && (lastDate.get(Calendar.YEAR) != today.get(Calendar.YEAR) ||
                    lastDate.get(Calendar.DAY_OF_YEAR) != today.get(Calendar.DAY_OF_YEAR))) {
                    isNewDay = true
                }
                
                var currentWater = flutterPrefs.getLong("flutter.current_water_ml", 0L)
                if (isNewDay) {
                    currentWater = 0L // Reset for new day
                }
                
                flutterPrefs.edit()
                    .putLong("flutter.current_water_ml", currentWater + amount)
                    .putLong("flutter.last_tracked_date", today.timeInMillis)
                    .apply()
                
                // 2. Update HomeWidget storage
                val widgetPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                var todayMl = widgetPrefs.getInt("todayMl", 0)
                if (isNewDay) {
                    todayMl = 0
                }
                val goalMl = widgetPrefs.getInt("goalMl", 2500)
                
                val newTodayMl = todayMl + amount
                val progress = if (goalMl > 0) ((newTodayMl.toFloat() / goalMl.toFloat()) * 100).toInt() else 0
                
                widgetPrefs.edit()
                    .putInt("todayMl", newTodayMl)
                    .putInt("progress", progress)
                    .apply()
                
                // 3. Force widget redraw
                val appWidgetManager = AppWidgetManager.getInstance(context)
                
                val squareWidget = ComponentName(context, WaterWidgetProvider::class.java)
                val squareIds = appWidgetManager.getAppWidgetIds(squareWidget)
                if (squareIds.isNotEmpty()) {
                    val updateIntent = Intent(context, WaterWidgetProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, squareIds)
                    }
                    context.sendBroadcast(updateIntent)
                }
                
                val barWidget = ComponentName(context, WaterWidgetBarProvider::class.java)
                val barIds = appWidgetManager.getAppWidgetIds(barWidget)
                if (barIds.isNotEmpty()) {
                    val updateIntent = Intent(context, WaterWidgetBarProvider::class.java).apply {
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
                action = "com.example.hydrohabit.ACTION_ADD_WATER"
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
