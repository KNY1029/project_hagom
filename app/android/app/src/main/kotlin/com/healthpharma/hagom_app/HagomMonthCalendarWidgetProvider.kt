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
            val taskLines = if (minH > 275) ((minH - 265) / 22).coerceIn(1, 5) else 0

            val selectedDayStr = widgetData.getString("month_selected_day", "") ?: ""
            val selectedDay = selectedDayStr.toIntOrNull()
            val inspectingIso = widgetData.getString("month_inspecting_iso", "") ?: ""
            val hasSelectedOtherDay = inspectingIso.isNotEmpty()

            val views = RemoteViews(context.packageName, R.layout.hagom_month_calendar_widget).apply {
                setTextViewText(R.id.widget_month_title, WidgetBindings.text(widgetData, "month_title"))
                setTextViewText(R.id.widget_month_meds, WidgetBindings.text(widgetData, "month_meds"))
                setTextViewText(R.id.widget_month_habits, WidgetBindings.text(widgetData, "month_habits"))
                setTextViewText(R.id.widget_month_tasks, WidgetBindings.text(widgetData, "month_tasks"))

                // 날짜 그리드 채우기
                for (day in 1..31) {
                    val resId = context.resources.getIdentifier("d_$day", "id", context.packageName)
                    if (resId != 0) {
                        val status = widgetData.getString("day_status_$day", "")
                        val isDaySelected = (selectedDay != null && selectedDay == day)

                        val bgRes = if (isDaySelected) {
                            if (status.contains("pin")) R.drawable.hagom_widget_selected_pin else R.drawable.hagom_widget_selected_bg
                        } else {
                            when (status) {
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
                        }
                        setInt(resId, "setBackgroundResource", bgRes)

                        // 🌟 [핵심 인터랙션]:
                        // 1) 아직 선택되지 않은 날짜를 누르면 -> 위젯 안에서 해당 날짜 선택(selectday)으로 요약만 먼저 갱신!
                        // 2) 이미 선택되어 하이라이트된 날짜를 '한 번 더' 누르면 -> 앱 달력 탭의 해당 날짜로 직행!
                        val cellPending = if (isDaySelected && inspectingIso.isNotEmpty()) {
                            WidgetBindings.openAppIntent(
                                context,
                                "hagomwidget://opencalendar?date=$inspectingIso",
                                2000 + day
                            )
                        } else {
                            WidgetBindings.actionIntent(context, "hagomwidget://selectday?day=$day")
                        }
                        setOnClickPendingIntent(resId, cellPending)
                    }
                }

                // 할일 목록 바인딩
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

                // 이전달 / 다음달 넘김 백그라운드 액션
                setOnClickPendingIntent(
                    R.id.widget_month_prev_btn,
                    WidgetBindings.actionIntent(context, "hagomwidget://prevmonth")
                )
                setOnClickPendingIntent(
                    R.id.widget_month_next_btn,
                    WidgetBindings.actionIntent(context, "hagomwidget://nextmonth")
                )

                // 중앙 하곰이 마스코트 & 헤더 탭 -> 하곰이의 방 또는 달력 탭
                setOnClickPendingIntent(
                    R.id.widget_month_header_center,
                    WidgetBindings.openAppIntent(context, "hagomwidget://openroom", 1004)
                )

                // 🌟 [오늘이 아닌 다른 날짜가 선택된 상태일 때의 스마트 라우팅]:
                // 오늘 날짜가 아닐 때는 복약/습관 배지나 할일 헤더를 눌러도 전부 달력 탭(해당 선택 날짜)으로 직행!
                val calTargetUri = if (hasSelectedOtherDay) {
                    "hagomwidget://opencalendar?date=$inspectingIso"
                } else {
                    "hagomwidget://opencalendar"
                }
                val calIntent = WidgetBindings.openAppIntent(context, calTargetUri, 1005)
                setOnClickPendingIntent(R.id.widget_month_tasks_header, calIntent)

                val medsIntent = if (hasSelectedOtherDay) calIntent else WidgetBindings.openAppIntent(context, "hagomwidget://openmeds", 1001)
                val habitsIntent = if (hasSelectedOtherDay) calIntent else WidgetBindings.openAppIntent(context, "hagomwidget://openhabits", 1002)

                setOnClickPendingIntent(R.id.widget_month_meds_box, medsIntent)
                setOnClickPendingIntent(R.id.widget_month_habits_box, habitsIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
