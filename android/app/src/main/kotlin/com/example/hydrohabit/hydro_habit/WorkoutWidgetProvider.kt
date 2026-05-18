package com.eliasantony.workout_habit

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class WorkoutWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        try {
            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.widget_layout_square).apply {
                    val todayUnits = if (widgetData.contains("todayUnits")) {
                        widgetData.getInt("todayUnits", 0)
                    } else {
                        widgetData.getInt("todayMl", 0)
                    }
                    val goalUnits = if (widgetData.contains("goalUnits")) {
                        widgetData.getInt("goalUnits", 50)
                    } else {
                        val ml = widgetData.getInt("goalMl", 50)
                        if (ml == 2500) 50 else ml
                    }
                    
                    val preferredExerciseLabel = widgetData.getString("preferredExerciseLabel", "Push-ups") ?: "Push-ups"
                    val preferredExerciseUnit = widgetData.getString("preferredExerciseUnit", "reps") ?: "reps"
                    
                    val progressPercent = widgetData.getInt("progress", 0)
                    
                    val streak = widgetData.getInt("streak", 0)
                    val smallAmount = widgetData.getInt("quickAddSmall", 5)
                    val largeAmount = widgetData.getInt("quickAddLarge", 10)

                    setTextViewText(R.id.widget_title, preferredExerciseLabel)
                    setTextViewText(R.id.todayMl, todayUnits.toString())
                    setTextViewText(R.id.goalMl, "of $goalUnits $preferredExerciseUnit")
                    setTextViewText(R.id.streak, "\uD83D\uDD25 $streak Day Streak")
                    setProgressBar(R.id.progress_bar, 100, progressPercent, false)

                    // Update Button Text
                    setTextViewText(R.id.btn_add_small, "+$smallAmount")
                    setTextViewText(R.id.btn_add_large, "+$largeAmount")

                    // Add actions to buttons natively
                    val pendingIntentSmall = WidgetActionReceiver.getPendingIntent(context, smallAmount)
                    setOnClickPendingIntent(R.id.btn_add_small, pendingIntentSmall)

                    val pendingIntentLarge = WidgetActionReceiver.getPendingIntent(context, largeAmount)
                    setOnClickPendingIntent(R.id.btn_add_large, pendingIntentLarge)

                    // Open App on widget click
                    val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java
                    )
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
