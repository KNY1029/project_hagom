package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class HagomMonthCalendarWidgetProvider : HomeWidgetProvider() {

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 240)
            val extraLines = if (minH > 265) ((minH - 255) / 22).coerceIn(1, 4) else 0

            val views = RemoteViews(context.packageName, R.layout.hagom_month_calendar_widget).apply {
                setTextViewText(R.id.widget_month_title, WidgetBindings.text(widgetData, "month_title"))
                setTextViewText(R.id.widget_month_meds, WidgetBindings.text(widgetData, "month_meds"))
                setTextViewText(R.id.widget_month_habits, WidgetBindings.text(widgetData, "month_habits"))
                setTextViewText(R.id.widget_month_tasks, WidgetBindings.text(widgetData, "month_tasks"))

                for (day in 1..31) {
                    val resId = context.resources.getIdentifier("d_$day", "id", context.packageName)
                    if (resId != 0) {
                        val status = widgetData.getString("day_status_$day", "")
                        val bgRes = when (status) {
                            "today" -> R.drawable.hagom_widget_today_bg
                            "today_pin" -> R.drawable.hagom_widget_today_pin
                            "today_done" -> R.drawable.hagom_widget_today_done_bg
                            "today_done_pin" -> R.drawable.hagom_widget_today_done_pin
                            "all_done" -> R.drawable.hagom_widget_done_bg
                            "all_done_pin" -> R.drawable.hagom_widget_done_pin_green
                            "missed_med" -> R.drawable.hagom_widget_bar_red
                            "missed_med_pin" -> R.drawable.hagom_widget_bar_red_pin
                            "partial" -> R.drawable.hagom_widget_bar_brown
                            "partial_pin" -> R.drawable.hagom_widget_bar_brown_pin
                            "pin_only" -> R.drawable.hagom_widget_pin_lavender
                            else -> R.drawable.hagom_widget_white_bg
                        }
                        setInt(resId, "setBackgroundResource", bgRes)
                    }
                }

                setViewVisibility(R.id.month_extra_container, if (extraLines > 0) View.VISIBLE else View.GONE)
                val detailIds = listOf(
                    R.id.month_detail_1,
                    R.id.month_detail_2,
                    R.id.month_detail_3,
                    R.id.month_detail_4
                )
                detailIds.forEachIndexed { idx, viewId ->
                    val txt = WidgetBindings.text(widgetData, "month_detail_${idx + 1}")
                    if (idx < extraLines && txt.isNotEmpty()) {
                        setViewVisibility(viewId, View.VISIBLE)
                        setTextViewText(viewId, txt)
                    } else {
                        setViewVisibility(viewId, View.GONE)
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
