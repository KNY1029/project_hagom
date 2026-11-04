package com.healthpharma.hagom_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
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
                val btnTitle = widgetData.getString("calendar_btn_title", "체크")

                setTextViewText(R.id.widget_calendar_tag, tag)
                setTextViewText(R.id.widget_calendar_progress, progress)
                setTextViewText(R.id.widget_calendar_title, title)
                setTextViewText(R.id.widget_calendar_subtitle, subtitle)
                setTextViewText(R.id.widget_calendar_btn_title, btnTitle)

                // 🌟 할일 버튼 색상 앱과 100% 동일하게 분기:
                // - 대기 (미완료): 웜브라운 (#8B5E3C) + 흰색 글자
                // - 완료: 소프트 민트초록 (#EAF8F1) + 딥그린 글자 (#1B6B46)
                if (btnTitle == "완료") {
                    setInt(R.id.widget_calendar_btn, "setBackgroundResource", R.drawable.hagom_widget_green_btn_bg)
                    setTextColor(R.id.widget_calendar_btn_title, Color.parseColor("#1B6B46"))
                } else {
                    setInt(R.id.widget_calendar_btn, "setBackgroundResource", R.drawable.hagom_widget_task_btn_bg)
                    setTextColor(R.id.widget_calendar_btn_title, Color.WHITE)
                }

                val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://openCalendar")
                )
                setOnClickPendingIntent(R.id.widget_calendar_container, openAppPendingIntent)

                val checkTaskIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                    action = "ACTION_CHECK_TASK"
                }
                val checkTaskPendingIntent = PendingIntent.getBroadcast(
                    context,
                    203,
                    checkTaskIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_calendar_btn, checkTaskPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
