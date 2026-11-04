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

class HagomHabitsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_habits_widget).apply {
                val tag = widgetData.getString("habits_tag", "오늘의 습관")
                val progress = widgetData.getString("habits_progress", "2/3 실천 중")
                val title = widgetData.getString("habits_title", "물 한 컵 마시기")
                val subtitle = widgetData.getString("habits_subtitle", "언제든 자유롭게 · 1컵")
                val extra = widgetData.getString("habits_extra", "오늘의 작은 발걸음")
                val btnTitle = widgetData.getString("habits_btn_title", "실천")
                val btnSubtitle = widgetData.getString("habits_btn_subtitle", "1-Tap")

                setTextViewText(R.id.widget_habits_tag, tag)
                setTextViewText(R.id.widget_habits_progress, progress)
                setTextViewText(R.id.widget_habits_title, title)
                setTextViewText(R.id.widget_habits_subtitle, subtitle)
                setTextViewText(R.id.widget_habits_extra, extra)
                setTextViewText(R.id.widget_habits_btn_title, btnTitle)
                setTextViewText(R.id.widget_habits_btn_subtitle, btnSubtitle)

                // 1) 좌측 본문 터치 시: 하곰이 습관 탭 열기
                val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://openHabits")
                )
                setOnClickPendingIntent(R.id.widget_habits_container, openAppPendingIntent)

                // 2) 우측 [실천] 1-Tap 버튼 터치 시: 습관 카운트 즉시 1-Tap 실천!
                val checkHabitPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://checkHabit")
                )
                setOnClickPendingIntent(R.id.widget_habits_btn, checkHabitPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
