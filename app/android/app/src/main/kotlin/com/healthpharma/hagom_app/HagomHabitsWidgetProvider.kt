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
                val btnTitle = widgetData.getString("habits_btn_title", "실천")

                setTextViewText(R.id.widget_habits_tag, tag)
                setTextViewText(R.id.widget_habits_progress, progress)
                setTextViewText(R.id.widget_habits_title, title)
                setTextViewText(R.id.widget_habits_subtitle, subtitle)
                setTextViewText(R.id.widget_habits_btn_title, btnTitle)

                // 1) 좌측 본문 터치 시: 하곰이 습관 탭 열기
                val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://openHabits")
                )
                setOnClickPendingIntent(R.id.widget_habits_container, openAppPendingIntent)

                // 2) 🌟 우측 [실천] 버튼 터치 시: BroadcastReceiver를 통해 즉각 로컬 데이터 갱신 및 위젯 업데이트!
                val checkHabitIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                    action = "ACTION_CHECK_HABIT"
                }
                val checkHabitPendingIntent = PendingIntent.getBroadcast(
                    context,
                    202,
                    checkHabitIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_habits_btn, checkHabitPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
