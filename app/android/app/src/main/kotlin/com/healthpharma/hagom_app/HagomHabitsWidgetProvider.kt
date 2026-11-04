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

class HagomHabitsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_habits_widget).apply {
                val tag = widgetData.getString("habits_tag", "오늘의 습관") ?: "오늘의 습관"
                val progress = widgetData.getString("habits_progress", "2/4 실천 중") ?: "2/4 실천 중"
                val title = widgetData.getString("habits_title", "물 한 컵 마시기") ?: "물 한 컵 마시기"
                val subtitle = widgetData.getString("habits_subtitle", "언제든 자유롭게 · 1컵") ?: "언제든 자유롭게 · 1컵"
                val btnTitle = widgetData.getString("habits_btn_title", "실천") ?: "실천"

                setTextViewText(R.id.widget_habits_tag, tag)
                setTextViewText(R.id.widget_habits_progress, progress)
                setTextViewText(R.id.widget_habits_title, title)
                setTextViewText(R.id.widget_habits_subtitle, subtitle)
                setTextViewText(R.id.widget_habits_btn_title, btnTitle)

                when {
                    btnTitle == "완료" || progress.contains("4/4") -> {
                        setInt(R.id.widget_habits_btn, "setBackgroundResource", R.drawable.hagom_widget_green_btn_bg)
                        setTextColor(R.id.widget_habits_btn_title, Color.parseColor("#1B6B46"))
                    }
                    progress.contains("0/4") || progress.contains("대기") -> {
                        setInt(R.id.widget_habits_btn, "setBackgroundResource", R.drawable.hagom_widget_gray_btn_bg)
                        setTextColor(R.id.widget_habits_btn_title, Color.parseColor("#4B5568"))
                    }
                    else -> {
                        setInt(R.id.widget_habits_btn, "setBackgroundResource", R.drawable.hagom_widget_brown_btn_bg)
                        setTextColor(R.id.widget_habits_btn_title, Color.parseColor("#8B5E3C"))
                    }
                }

                // 1) 바탕 터치 시: 습관 탭(1번)으로 직행
                val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("hagomwidget://openHabits")
                )
                setOnClickPendingIntent(R.id.widget_habits_container, openAppPendingIntent)

                // 2) 메인 실천 버튼 터치 시 브로드캐스트
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

                // 3) 🌟 세로 확장 시 나타나는 작은 습관 버튼들에도 클릭 리스너 연결!
                val habitSlot1Intent = PendingIntent.getBroadcast(
                    context,
                    206,
                    Intent(context, WidgetActionReceiver::class.java).apply { action = "ACTION_CHECK_HABIT" },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.habit_slot_1_btn, habitSlot1Intent)

                val habitSlot4Intent = PendingIntent.getBroadcast(
                    context,
                    207,
                    Intent(context, WidgetActionReceiver::class.java).apply { action = "ACTION_CHECK_HABIT" },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.habit_slot_4_btn, habitSlot4Intent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
