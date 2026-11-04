package com.healthpharma.hagom_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HagomCalendarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_calendar_widget).apply {
                val tag = widgetData.getString("calendar_tag", "오늘의 일정")
                val progress = widgetData.getString("calendar_progress", "오후 2:00")
                val title = widgetData.getString("calendar_title", "약학 실습 보고서 작성")
                val subtitle = widgetData.getString("calendar_subtitle", "카테고리: 과제 및 실습")
                val extra = widgetData.getString("calendar_extra", "상태: 진행 대기")
                val btnTitle = widgetData.getString("calendar_btn_title", "체크")
                val btnSubtitle = widgetData.getString("calendar_btn_subtitle", "1-Tap")

                setTextViewText(R.id.widget_calendar_tag, tag)
                setTextViewText(R.id.widget_calendar_progress, progress)
                setTextViewText(R.id.widget_calendar_title, title)
                setTextViewText(R.id.widget_calendar_subtitle, subtitle)
                setTextViewText(R.id.widget_calendar_extra, extra)
                setTextViewText(R.id.widget_calendar_btn_title, btnTitle)
                setTextViewText(R.id.widget_calendar_btn_subtitle, btnSubtitle)

                // 🚀 위젯 터치 시 앱 달력 탭으로 즉시 열기
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("from_widget", "calendar")
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    103,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_calendar_container, pendingIntent)
                setOnClickPendingIntent(R.id.widget_calendar_btn, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
