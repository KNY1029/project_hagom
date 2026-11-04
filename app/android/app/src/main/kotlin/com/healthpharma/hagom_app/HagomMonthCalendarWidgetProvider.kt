package com.healthpharma.hagom_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
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
                val title = widgetData.getString("month_title", "2026년 11월 기록 달력")
                val medsText = widgetData.getString("month_meds", "복약 1/4 완료")
                val habitsText = widgetData.getString("month_habits", "습관 2/3 실천")
                val tasksText = widgetData.getString("month_tasks", "오늘 일정 없음")

                setTextViewText(R.id.widget_month_title, title)
                setTextViewText(R.id.widget_month_meds, medsText)
                setTextViewText(R.id.widget_month_habits, habitsText)
                setTextViewText(R.id.widget_month_tasks, tasksText)

                // 🌟 달력 1~30일 날짜별 상태 배경 바인딩 (완료: 초록 틴트, 누락: 빨간/갈색 틴트)
                for (day in 1..30) {
                    val resId = context.resources.getIdentifier("d_$day", "id", context.packageName)
                    if (resId != 0) {
                        val status = widgetData.getString("day_status_$day", "")
                        when (status) {
                            "all_done" -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_done_bg)
                            "missed_med" -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_missed_bg)
                            "partial" -> setInt(resId, "setBackgroundResource", R.drawable.hagom_widget_partial_bg)
                        }
                    }
                }

                // 터치 시 앱의 달력 탭으로 직행
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("from_widget", "calendar_month")
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    104,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_month_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
