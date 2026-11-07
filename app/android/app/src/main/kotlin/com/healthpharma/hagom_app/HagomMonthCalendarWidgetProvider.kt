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
            // 위젯 세로 높이가 충분할 때만(minH >= 310) 2열 목록을 펼치고,
            // 좁을 때는(작은 위젯) 달력을 보호하기 위해 목록을 접고 요약 헤더만 깔끔하게 노출!
            val canShowTaskList = (minH >= 310)
            val selectedDateStr = widgetData.getString("month_selected_date", "") ?: ""
            val inspectingIso = widgetData.getString("month_inspecting_iso", "") ?: ""
            val hasSelectedOtherDay = inspectingIso.isNotEmpty()
            val views = RemoteViews(context.packageName, R.layout.hagom_month_calendar_widget).apply {
                setTextViewText(R.id.widget_month_title, WidgetBindings.text(widgetData, "month_title"))
                setTextViewText(R.id.widget_month_meds, WidgetBindings.text(widgetData, "month_meds"))
                setTextViewText(R.id.widget_month_habits, WidgetBindings.text(widgetData, "month_habits"))
                val taskLabel = widgetData.getString("month_tasks_label", "오늘의 할일") ?: "오늘의 할일"
                setTextViewText(R.id.widget_month_tasks_label, taskLabel)
                setTextViewText(R.id.widget_month_tasks, WidgetBindings.text(widgetData, "month_tasks"))
                val medsColorHex = widgetData.getString("theme_meds_color", "#7B61A8") ?: "#7B61A8"
                val habitsColorHex = widgetData.getString("theme_habits_color", "#7B61A8") ?: "#8B5E3C"
                val tasksColorHex = widgetData.getString("theme_tasks_color", "#7B61A8") ?: "#B58A32"

                setTextColor(R.id.widget_month_meds, Color.parseColor(medsColorHex))
                setTextColor(R.id.widget_month_habits, Color.parseColor(habitsColorHex))
                setTextColor(R.id.widget_month_prev_btn, Color.parseColor(medsColorHex))
                setTextColor(R.id.widget_month_next_btn, Color.parseColor(medsColorHex))
                setTextColor(R.id.widget_month_tasks, Color.parseColor(tasksColorHex))
                setTextColor(R.id.widget_month_tasks_label, Color.parseColor(tasksColorHex))
                // 🌟 [2열(좌/우) 반응형 할일 목록 바인딩]:
                // 1) 좌측 열 먼저 1번, 2번 채우고, 넘치는 3번, 4번은 우측 열로!
                // 2) 위젯 크기가 작을 땐 목록 전체를 숨겨서 달력 크기 완벽 보존
                val task1 = widgetData.getString("month_today_task_1", "") ?: ""
                val task2 = widgetData.getString("month_today_task_2", "") ?: ""
                val task3 = widgetData.getString("month_today_task_3", "") ?: ""
                val task4 = widgetData.getString("month_today_task_4", "") ?: ""

                val hasAnyTask = task1.isNotEmpty() || task2.isNotEmpty() || task3.isNotEmpty() || task4.isNotEmpty()

                if (canShowTaskList && hasAnyTask) {
                    setViewVisibility(R.id.widget_month_tasks_list, View.VISIBLE)
                    setViewVisibility(R.id.month_tasks_col_left, View.VISIBLE)

                    // 좌측 열 (1, 2)
                    setTextViewText(R.id.month_task_1, task1)
                    setViewVisibility(R.id.month_task_1, if (task1.isNotEmpty()) View.VISIBLE else View.GONE)

                    setTextViewText(R.id.month_task_2, task2)
                    setViewVisibility(R.id.month_task_2, if (task2.isNotEmpty()) View.VISIBLE else View.GONE)

                    // 우측 열 (3, 4) - 3번 또는 4번이 있을 때만 열 오픈!
                    val hasRightCol = task3.isNotEmpty() || task4.isNotEmpty()
                    setViewVisibility(R.id.month_tasks_col_right, if (hasRightCol) View.VISIBLE else View.GONE)

                    setTextViewText(R.id.month_task_3, task3)
                    setViewVisibility(R.id.month_task_3, if (task3.isNotEmpty()) View.VISIBLE else View.GONE)

                    setTextViewText(R.id.month_task_4, task4)
                    setViewVisibility(R.id.month_task_4, if (task4.isNotEmpty()) View.VISIBLE else View.GONE)
                } else {
                    setViewVisibility(R.id.widget_month_tasks_list, View.GONE)
                }
                // 🌟 [42개 셀(c_0 ~ c_41) 동적 매핑]: 실제 시작 요일 및 말일 반영!
                for (i in 0 until 42) {
                    val resId = context.resources.getIdentifier("c_$i", "id", context.packageName)
                    if (resId != 0) {
                        val cellText = widgetData.getString("cell_${i}_text", "") ?: ""
                        val status = widgetData.getString("cell_${i}_status", "empty") ?: "empty"
                        val dayNum = widgetData.getString("cell_${i}_day", "")?.toIntOrNull()
                        val cellDate = widgetData.getString("cell_${i}_date", "") ?: ""

                        if (status == "empty" || cellText.isEmpty() || dayNum == null || cellDate.isEmpty()) {
                            setTextViewText(resId, "")
                            setInt(resId, "setBackgroundResource", 0)
                            setOnClickPendingIntent(resId, null)
                            continue
                        }
                        setTextViewText(resId, cellText)

                        // 일요일(i % 7 == 0)은 빨간색 글자
                        val isSunday = (i % 7 == 0)
                        setTextColor(resId, if (isSunday) Color.parseColor("#EF4444") else Color.parseColor("#1F2937"))

                        val isDaySelected = (selectedDateStr.isNotEmpty() && selectedDateStr == cellDate)
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
                                "hagomwidget://opencalendar?date=$cellDate",
                                2000 + i
                            )
                        } else {
                            WidgetBindings.actionIntent(
                                context,
                                "hagomwidget://selectday?date=$cellDate",
                                3000 + i
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
                    WidgetBindings.openAppIntent(context, "hagomwidget://opencalendar", 1004)
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
