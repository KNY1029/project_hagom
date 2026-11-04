package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
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

                // 🌟 [42개 셀(c_0 ~ c_41) 동적 매핑]: 실제 시작 요일 및 말일 반영!
                for (i in 0 until 42) {
                    val resId = context.resources.getIdentifier("c_$i", "id", context.packageName)
                    if (resId != 0) {
                        val cellText = widgetData.getString("cell_${i}_text", "") ?: ""
                        val status = widgetData.getString("cell_${i}_status", "empty") ?: "empty"
                        val dayNum = widgetData.getString("cell_${i}_day", "")?.toIntOrNull()

                        if (status == "empty" || cellText.isEmpty() || dayNum == null) {
                            setTextViewText(resId, "")
                            setInt(resId, "setBackgroundResource", 0)
                            setOnClickPendingIntent(resId, null)
                            continue
                        }

                        setTextViewText(resId, cellText)

                        // 일요일(i % 7 == 0)은 빨간색 글자
                        val isSunday = (i % 7 == 0)
                        setTextColor(resId, if (isSunday) Color.parseColor("#EF4444") else Color.parseColor("#1F2937"))

                        val isDaySelected = (selectedDay != null && selectedDay == dayNum)
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

                        val cellPending = if (isDaySelected && inspectingIso.isNotEmpty()) {
                            WidgetBindings.openAppIntent(
                                context,
                                "hagomwidget://opencalendar?date=$inspectingIso",
                                2000 + dayNum
                            )
                        } else {
                            WidgetBindings.actionIntent(
                                context,
                                "hagomwidget://selectday?day=$dayNum",
                                3000 + dayNum
                            )
                        }
                        setOnClickPendingIntent(resId, cellPending)
                    }
                }


                // 이전달 / 다음달 넘김 백그라운드 액션 (고유 requestCode 지정)
                setOnClickPendingIntent(
                    R.id.widget_month_prev_btn,
                    WidgetBindings.actionIntent(context, "hagomwidget://prevmonth", 1011)
                )
                setOnClickPendingIntent(
                    R.id.widget_month_next_btn,
                    WidgetBindings.actionIntent(context, "hagomwidget://nextmonth", 1012)
                )

                // 중앙 하곰이 마스코트 & 헤더 탭 -> 하곰이의 방
                setOnClickPendingIntent(
                    R.id.widget_month_header_center,
                    WidgetBindings.openAppIntent(context, "hagomwidget://openroom", 1004)
                )

                // 스마트 라우팅 (오늘 아닌 날짜가 선택되었을 땐 어디 눌러도 달력 탭 해당 날짜로 직행)
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
                // 달력 위젯 여백/빈 공간 탭 시에도 달력 탭(또는 선택된 날짜)으로 시원하게 열림
                setOnClickPendingIntent(R.id.widget_month_container, calIntent)
                setOnClickPendingIntent(R.id.widget_month_title, calIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
