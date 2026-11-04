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

                // 1) 좌측 본문 터치 시: 하곰이 달력 탭 열기
                val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://openCalendar")
                )
                setOnClickPendingIntent(R.id.widget_calendar_container, openAppPendingIntent)

                // 2) 우측 [체크] 1-Tap 버튼 터치 시: 할일 즉시 완료 토글!
                val checkTaskPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://checkTask")
                )
                setOnClickPendingIntent(R.id.widget_calendar_btn, checkTaskPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
