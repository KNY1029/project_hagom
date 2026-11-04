package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HagomMonthCalendarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_month_calendar_widget).apply {
                setTextViewText(R.id.widget_month_title, WidgetBindings.text(widgetData, "month_title"))
                setTextViewText(R.id.widget_month_meds, WidgetBindings.text(widgetData, "month_meds"))
                setTextViewText(R.id.widget_month_habits, WidgetBindings.text(widgetData, "month_habits"))
                setTextViewText(R.id.widget_month_tasks, WidgetBindings.text(widgetData, "month_tasks"))

                for (day in 1..30) {
                    val resId = context.resources.getIdentifier("d_$day", "id", context.packageName)
                    if (resId != 0) {
                        val status = widgetData.getString("day_status_$day", "")
                        when (status) {
                            "all_done" -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_done_bg)
                            "all_done_pin" -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_done_pin_green)
                            "missed_med" -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_bar_red)
                            "missed_med_pin" -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_bar_red_pin)
                            "partial" -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_bar_brown)
                            "partial_pin" -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_bar_brown_pin)
                            "pin_only" -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_pin_lavender)
                            else -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_white_bg)
                        }
                    }
                }

                setOnClickPendingIntent(
                    R.id.widget_month_container,
                    WidgetBindings.openAppIntent(context, "hagomwidget://opencalendar", 1005)
                )
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
