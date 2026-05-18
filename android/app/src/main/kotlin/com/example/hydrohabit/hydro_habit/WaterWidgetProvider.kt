package com.example.hydrohabit.hydro_habit

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class WaterWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        try {
            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.widget_layout_square).apply {
                    val todayMl = widgetData.getInt("todayMl", 0)
                    val goalMl = widgetData.getInt("goalMl", 2500)
                    
                    val progressPercent = widgetData.getInt("progress", 0)
                    
                    val streak = widgetData.getInt("streak", 0)
                    val smallAmount = widgetData.getInt("quickAddSmall", 250)
                    val largeAmount = widgetData.getInt("quickAddLarge", 500)

                    setTextViewText(R.id.todayMl, todayMl.toString())
                    setTextViewText(R.id.goalMl, "of $goalMl ml")
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
