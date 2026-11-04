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

            // 4x4(약 220~270dp)까지는 달력 격자가 커지고,
            // 4x5 이상(>275dp)으로 길게 늘렸을 때 오늘의 할일 상세 목록이 최대 5개까지 늘어남
            val taskLines = if (minH > 275) ((minH - 265) / 22).coerceIn(1, 5) else 0

            val views = RemoteViews(context.packageName, R.layout.hagom_month_calendar_widget).apply {
                setTextViewText(R.id.widget_month_title, WidgetBindings.text(widgetData, "month_title"))
                setTextViewText(R.id.widget_month_meds, WidgetBindings.text(widgetData, "month_meds"))
                setTextViewText(R.id.widget_month_habits, WidgetBindings.text(widgetData, "month_habits"))
                setTextViewText(R.id.widget_month_tasks, WidgetBindings.text(widgetData, "month_tasks"))

                val currentYear = java.util.Calendar.getInstance().get(java.util.Calendar.YEAR)
                val currentMonth = java.util.Calendar.getInstance().get(java.util.Calendar.MONTH) + 1

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

                        // 🌟 날짜를 탭하면 달력 탭에서 바로 해당 날짜가 선택된 상태로 앱 열기!
                        val monthStr = if (currentMonth < 10) "0$currentMonth" else "$currentMonth"
                        val dayStr = if (day < 10) "0$day" else "$day"
                        val dateIso = "$currentYear-$monthStr-$dayStr"
                        val dayIntent = WidgetBindings.openAppIntent(
                            context,
                            "hagomwidget://opencalendar?date=$dateIso",
                            2000 + day
                        )
                        setOnClickPendingIntent(resId, dayIntent)
                    }
                }

                // 오늘 할일 상세 목록 바인딩 (세로로 길게 늘렸을 때)
                setViewVisibility(R.id.month_extra_container, if (taskLines > 0) View.VISIBLE else View.GONE)
                val taskIds = listOf(
                    R.id.month_task_1,
                    R.id.month_task_2,
                    R.id.month_task_3,
                    R.id.month_task_4,
                    R.id.month_task_5
                )
                taskIds.forEachIndexed { idx, viewId ->
                    val txt = WidgetBindings.text(widgetData, "month_today_task_${idx + 1}")
                    if (idx < taskLines && txt.isNotEmpty()) {
                        setViewVisibility(viewId, View.VISIBLE)
                        setTextViewText(viewId, txt)
                    } else {
                        setViewVisibility(viewId, View.GONE)
                    }
                }

                // 🌟 [원치 않는 앱 열림 완전 차단]:
                // 전체 배경(container)에는 Intent를 걸지 않아 화면 빈 공간을 만져도 앱이 절대 켜지지 않습니다.
                // 오직 명확한 버튼/제목 영역을 눌렀을 때만 해당 목적지로 갑니다:
                // 1) 상단 제목 & 할일 헤더 탭 -> 달력 탭
                val openCalIntent = WidgetBindings.openAppIntent(context, "hagomwidget://opencalendar", 1005)
                setOnClickPendingIntent(R.id.widget_month_title, openCalIntent)
                setOnClickPendingIntent(R.id.widget_month_tasks_header, openCalIntent)
                // 이전달 / 다음달 넘김 백그라운드 액션 연결
                setOnClickPendingIntent(
                    R.id.widget_month_prev_btn,
                    WidgetBindings.actionIntent(context, "hagomwidget://prevmonth")
                )
                setOnClickPendingIntent(
                    R.id.widget_month_next_btn,
                    WidgetBindings.actionIntent(context, "hagomwidget://nextmonth")
                )

                // 2) 마스코트 아이콘 탭 -> 하곰이의 방
                setOnClickPendingIntent(
                    R.id.widget_month_mascot_btn,
                    WidgetBindings.openAppIntent(context, "hagomwidget://openroom", 1004)
                )

                // 3) 복약 배지 탭 -> 복약 탭
                setOnClickPendingIntent(
                    R.id.widget_month_meds_box,
                    WidgetBindings.openAppIntent(context, "hagomwidget://openmeds", 1001)
                )

                // 4) 습관 배지 탭 -> 습관 탭
                setOnClickPendingIntent(
                    R.id.widget_month_habits_box,
                    WidgetBindings.openAppIntent(context, "hagomwidget://openhabits", 1002)
                )
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
