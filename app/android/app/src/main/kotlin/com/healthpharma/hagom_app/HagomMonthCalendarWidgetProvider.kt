package com.healthpharma.hagom_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
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
                val title = widgetData.getString("month_title", "2026년 11월 기록 달력")
                val medsText = widgetData.getString("month_meds", "복약: 1/4 완료")
                val habitsText = widgetData.getString("month_habits", "습관: 2/3 실천")
                val tasksText = widgetData.getString("month_tasks", "예정된 일정이 없어요")

                setTextViewText(R.id.widget_month_title, title)
                setTextViewText(R.id.widget_month_meds, medsText)
                setTextViewText(R.id.widget_month_habits, habitsText)
                setTextViewText(R.id.widget_month_tasks, tasksText)

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

                // 터치 시 앱의 달력 탭으로 직행
                val openCalendarPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://openCalendar")
                )
                setOnClickPendingIntent(R.id.widget_month_container, openCalendarPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
