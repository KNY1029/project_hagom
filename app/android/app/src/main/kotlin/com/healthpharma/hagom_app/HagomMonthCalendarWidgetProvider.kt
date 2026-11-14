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

    private fun darkCellBackground(status: String): Int = when (status) {
        "today", "today_pin", "today_done", "today_done_pin",
        "today_med_done", "today_med_done_pin", "today_med_done_done_pin" ->
            R.drawable.hagom_calendar_dark_today
        "all_done", "all_done_pin" -> R.drawable.hagom_calendar_dark_done
        "mdone", "mdone_pin", "hdone_mdone", "hdone_mdone_pin",
        "hdone_mpartial", "hdone_mpartial_pin" -> R.drawable.hagom_calendar_dark_bar_green
        "missed_med", "missed_med_pin", "hdone_mmissed", "hdone_mmissed_pin" ->
            R.drawable.hagom_calendar_dark_bar_red
        "partial", "partial_pin" -> R.drawable.hagom_calendar_dark_bar_gray
        "pin_only" -> R.drawable.hagom_calendar_dark_pin
        else -> R.drawable.hagom_calendar_dark_base
    }

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
            val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 200)

            // 🌟 사용자 요청: 달력이 줄어들지 않도록 한 열당 무조건 "최대 3줄(58dp)"로 엄격 고정!
            val canShowTaskList = (minH >= 240)
            // 가로 폭이 너무 좁으면(minW < 280) 2열로 쪼개지 않고 1열만 단독 사용!
            val canSupportTwoCol = (minW >= 280)
            val selectedDateStr = widgetData.getString("month_selected_date", "") ?: ""
            val inspectingIso = widgetData.getString("month_inspecting_iso", "") ?: ""
            val todayIso = widgetData.getString("month_today_iso", "") ?: ""
            val isColorVision = widgetData.getString("theme_color_vision", "false") == "true"
            val hasSelectedOtherDay = inspectingIso.isNotEmpty()
            val views = RemoteViews(context.packageName, R.layout.hagom_month_calendar_widget).apply {
                // 🌟 [세로 높이 반응형 3단계 헤더]:
                // 1) minH >= 240 (대형): 전체 타이틀 ("2026년 11월 기록 달력")
                // 2) 180 <= minH < 240 (중형): 슬림 타이틀 ("11월")
                // 3) minH < 180 (소형): 헤더 전체 숨김(GONE)으로 달력 공간 100% 확보!
                if (minH < 180) {
                    setViewVisibility(R.id.widget_month_header, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_month_header, View.VISIBLE)
                    val fullTitle = WidgetBindings.text(widgetData, "month_title")
                    val shortTitle = WidgetBindings.text(widgetData, "month_title_short").ifEmpty { "11월" }
                    val finalTitle = if (minH < 240) shortTitle else fullTitle
                    setTextViewText(R.id.widget_month_title, finalTitle)
                }

                setTextViewText(R.id.widget_month_meds, WidgetBindings.text(widgetData, "month_meds"))
                setTextViewText(R.id.widget_month_habits, WidgetBindings.text(widgetData, "month_habits"))
                val taskLabel = widgetData.getString("month_tasks_label", "오늘의 할일") ?: "오늘의 할일"
                setTextViewText(R.id.widget_month_tasks_label, taskLabel)
                setTextViewText(R.id.widget_month_tasks, WidgetBindings.text(widgetData, "month_tasks"))
                val dark = widgetData.getString("theme_dark", "false") == "true"
                val medsColorHex = if (dark) "#D6C5FF" else "#7B61A8"
                val habitsColorHex = if (dark) "#D6C5FF" else "#7B61A8"
                val tasksColorHex = if (dark) "#D6C5FF" else "#7B61A8"
                val widgetTagBg = if (dark) R.drawable.hagom_widget_tag_bg_dark else R.drawable.hagom_widget_tag_bg
                setInt(R.id.widget_month_tasks_header, "setBackgroundResource", widgetTagBg)
                setInt(R.id.month_tasks_card_box, "setBackgroundResource", widgetTagBg)
                setInt(R.id.widget_month_habits_box, "setBackgroundResource", widgetTagBg)
                setInt(R.id.widget_month_meds_box, "setBackgroundResource", widgetTagBg)
                setTextColor(R.id.widget_month_meds, Color.parseColor(medsColorHex))
                setTextColor(R.id.widget_month_habits, Color.parseColor(habitsColorHex))
                setTextColor(R.id.widget_month_prev_btn, Color.parseColor(medsColorHex))
                setTextColor(R.id.widget_month_next_btn, Color.parseColor(medsColorHex))
                setTextColor(R.id.widget_month_tasks, Color.parseColor(tasksColorHex))
                setTextColor(R.id.widget_month_tasks_label, Color.parseColor(tasksColorHex))
                for (n in 1..6) {
                    val taskId = context.resources.getIdentifier("month_task_$n", "id", context.packageName)
                    if (taskId != 0) {
                        setTextColor(taskId, Color.parseColor(if (dark) "#E8E1F0" else "#374151"))
                    }
                }
                // 🌟 [할일 목록 바인딩: 4개일 때 좌2 + 우2 완벽 분할]:
                // 1) 1~3개: 좌측 1열(1~3개)에만 표시
                // 2) 4개: 좌측 2개(1,2) + 우측 2개(3,4) 균등 분할!
                // 3) 5~6개: 좌측 3개(1,2,3) + 우측 나머지(4,5,6) 분할
                val taskTexts = (1..6).map { widgetData.getString("month_today_task_$it", "") ?: "" }
                val activeTaskCount = taskTexts.count { it.isNotEmpty() }

                if (canShowTaskList) {
                    if (activeTaskCount > 0) {
                        setViewVisibility(R.id.widget_month_tasks_list, View.VISIBLE)

                        // 3개 초과 & 가로 넉넉할 때 2열 모드 가동!
                        val isTwoCol = canSupportTwoCol && (activeTaskCount > 3)

                        setViewVisibility(R.id.month_tasks_col_left, View.VISIBLE)
                        setViewVisibility(R.id.month_tasks_col_right, if (isTwoCol) View.VISIBLE else View.GONE)

                        val leftColTasks = mutableListOf<String>()
                        val rightColTasks = mutableListOf<String>()

                        if (isTwoCol) {
                            if (activeTaskCount == 4) {
                                // 🌟 사용자 요청: 4개일 때는 좌측 2개, 우측 2개로 예쁘게 대칭 분할!
                                leftColTasks.add(taskTexts[0])
                                leftColTasks.add(taskTexts[1])
                                rightColTasks.add(taskTexts[2])
                                rightColTasks.add(taskTexts[3])
                            } else {
                                // 5개 또는 6개일 때: 좌측 3개 + 우측 나머지
                                for (i in 0 until 3) leftColTasks.add(taskTexts[i])
                                for (i in 3 until activeTaskCount) rightColTasks.add(taskTexts[i])
                            }
                        } else {
                            // 1열 모드 (1~3개 또는 좁은 화면)
                            for (i in 0 until activeTaskCount.coerceAtMost(3)) {
                                leftColTasks.add(taskTexts[i])
                            }
                        }

                        // 좌측 열 바인딩 (1, 2, 3)
                        for (i in 0 until 3) {
                            val viewId = context.resources.getIdentifier("month_task_${i + 1}", "id", context.packageName)
                            if (viewId != 0) {
                                val tText = if (i < leftColTasks.size) leftColTasks[i] else ""
                                setTextViewText(viewId, tText)
                                setViewVisibility(viewId, if (tText.isNotEmpty()) View.VISIBLE else View.GONE)
                            }
                        }

                        // 우측 열 바인딩 (4, 5, 6)
                        for (i in 0 until 3) {
                            val viewId = context.resources.getIdentifier("month_task_${i + 4}", "id", context.packageName)
                            if (viewId != 0) {
                                val tText = if (isTwoCol && i < rightColTasks.size) rightColTasks[i] else ""
                                setTextViewText(viewId, tText)
                                setViewVisibility(viewId, if (isTwoCol && tText.isNotEmpty()) View.VISIBLE else View.GONE)
                            }
                        }
                    } else {
                        // 할일이 없는 날: INVISIBLE로 58dp 투명 유지!
                        setViewVisibility(R.id.widget_month_tasks_list, View.INVISIBLE)
                    }
                } else {
                    setViewVisibility(R.id.widget_month_tasks_list, View.GONE)
                }
                // 🌟 [42개 셀(c_0 ~ c_41) 동적 매핑]: 실제 시작 요일 및 말일 반영!
                // 🌟 6주차(c_35~c_41)에 날짜가 하나도 없는 달(11월 등)은 6주차 행을 GONE으로 접어 5개 주가 훨씬 큼직하게 확장!
                val hasWeek6 = (35 until 42).any {
                    (widgetData.getString("cell_${it}_text", "") ?: "").isNotEmpty()
                }
                setViewVisibility(R.id.month_week_row_6, if (hasWeek6) View.VISIBLE else View.GONE)
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
                        val isDark = widgetData.getString("theme_dark", "false") == "true"
                        setTextColor(
                            resId,
                            if (isSunday) Color.parseColor(if (isDark) "#FF8585" else "#EF4444")
                            else Color.parseColor(if (isDark) "#F3F0F7" else "#1F2937")
                        )

                        val isDaySelected = (selectedDateStr.isNotEmpty() && selectedDateStr == cellDate)
                        val bgRes = if (isDaySelected) {
                            // 🌟 선택된 날짜도 원래의 진행 상황(습관 초록 배경, 복약 하단바, 핀)을 100% 보존하고 외곽 보라 테두리만 두름!
                            when (status) {
                                "today" -> R.drawable.hagom_widget_today_bg_sel
                                "today_pin" -> R.drawable.hagom_widget_today_pin_sel
                                "today_done" -> if (isColorVision) R.drawable.hagom_widget_today_done_bg_cv_sel else R.drawable.hagom_widget_today_done_bg_sel
                                "today_done_pin" -> if (isColorVision) R.drawable.hagom_widget_today_done_pin_cv_sel else R.drawable.hagom_widget_today_done_pin_sel
                                "today_med_done" -> if (isColorVision) R.drawable.hagom_widget_today_med_done_cv_sel else R.drawable.hagom_widget_today_med_done_sel
                                "today_med_done_pin" -> if (isColorVision) R.drawable.hagom_widget_today_med_done_pin_cv_sel else R.drawable.hagom_widget_today_med_done_pin_sel
                                "today_med_done_done_pin" -> if (isColorVision) R.drawable.hagom_widget_today_med_done_done_pin_cv_sel else R.drawable.hagom_widget_today_med_done_pin_sel
                                "all_done" -> if (isColorVision) R.drawable.hagom_widget_done_bg_cv_sel else R.drawable.hagom_widget_done_bg_sel
                                "all_done_pin" -> if (isColorVision) R.drawable.hagom_widget_done_pin_green_cv_sel else R.drawable.hagom_widget_done_pin_green_sel
                                "mdone" -> if (isColorVision) R.drawable.hagom_widget_done_med_bar_cv_sel else R.drawable.hagom_widget_done_med_bar_sel
                                "mdone_pin" -> if (isColorVision) R.drawable.hagom_widget_done_med_bar_pin_cv_sel else R.drawable.hagom_widget_done_med_bar_pin_sel
                                "hdone_mdone" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_done_cv_sel else R.drawable.hagom_widget_habit_done_med_done_sel
                                "hdone_mdone_pin" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_done_pin_cv_sel else R.drawable.hagom_widget_habit_done_med_done_pin_sel
                                "hdone_mmissed" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_missed_cv_sel else R.drawable.hagom_widget_habit_done_med_missed_sel
                                "hdone_mmissed_pin" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_missed_pin_cv_sel else R.drawable.hagom_widget_habit_done_med_missed_pin_sel
                                "hdone_mpartial" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_partial_cv else R.drawable.hagom_widget_habit_done_med_partial_sel
                                "hdone_mpartial_pin" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_partial_pin_cv else R.drawable.hagom_widget_habit_done_med_partial_pin_sel
                                "missed_med" -> if (isColorVision) R.drawable.hagom_widget_bar_red_cv_sel else R.drawable.hagom_widget_bar_red_sel
                                "missed_med_pin" -> if (isColorVision) R.drawable.hagom_widget_bar_red_pin_cv_sel else R.drawable.hagom_widget_bar_red_pin_sel
                                "partial" -> R.drawable.hagom_widget_bar_brown_sel
                                "partial_pin" -> R.drawable.hagom_widget_bar_brown_pin_sel
                                "pin_only" -> R.drawable.hagom_widget_pin_lavender_sel
                                else -> R.drawable.hagom_widget_white_bg_sel
                            }
                        } else {
                            when (status) {
                                "today" -> R.drawable.hagom_widget_today_bg
                                "today_pin" -> R.drawable.hagom_widget_today_pin
                                "today_done" -> if (isColorVision) R.drawable.hagom_widget_today_done_bg_cv else R.drawable.hagom_widget_today_done_bg
                                "today_done_pin" -> if (isColorVision) R.drawable.hagom_widget_today_done_pin_cv else R.drawable.hagom_widget_today_done_pin
                                "today_med_done" -> if (isColorVision) R.drawable.hagom_widget_today_med_done_cv else R.drawable.hagom_widget_today_med_done
                                "today_med_done_pin" -> if (isColorVision) R.drawable.hagom_widget_today_med_done_pin_cv else R.drawable.hagom_widget_today_med_done_pin
                                "today_med_done_done_pin" -> if (isColorVision) R.drawable.hagom_widget_today_med_done_done_pin_cv else R.drawable.hagom_widget_today_med_done_pin
                                "all_done" -> if (isColorVision) R.drawable.hagom_widget_done_bg_cv else R.drawable.hagom_widget_done_bg
                                "all_done_pin" -> if (isColorVision) R.drawable.hagom_widget_done_pin_green_cv else R.drawable.hagom_widget_done_pin_green
                                "mdone" -> if (isColorVision) R.drawable.hagom_widget_done_med_bar_cv else R.drawable.hagom_widget_done_med_bar
                                "mdone_pin" -> if (isColorVision) R.drawable.hagom_widget_done_med_bar_pin_cv else R.drawable.hagom_widget_done_med_bar_pin
                                "hdone_mdone" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_done_cv else R.drawable.hagom_widget_habit_done_med_done
                                "hdone_mdone_pin" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_done_pin_cv else R.drawable.hagom_widget_habit_done_med_done_pin
                                "hdone_mmissed" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_missed_cv else R.drawable.hagom_widget_habit_done_med_missed
                                "hdone_mmissed_pin" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_missed_pin_cv else R.drawable.hagom_widget_habit_done_med_missed_pin
                                "hdone_mpartial" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_partial_cv else R.drawable.hagom_widget_habit_done_med_partial
                                "hdone_mpartial_pin" -> if (isColorVision) R.drawable.hagom_widget_habit_done_med_partial_pin_cv else R.drawable.hagom_widget_habit_done_med_partial_pin
                                "missed_med" -> if (isColorVision) R.drawable.hagom_widget_bar_red_cv else R.drawable.hagom_widget_bar_red
                                "missed_med_pin" -> if (isColorVision) R.drawable.hagom_widget_bar_red_pin_cv else R.drawable.hagom_widget_bar_red_pin
                                "partial" -> R.drawable.hagom_widget_bar_brown
                                "partial_pin" -> R.drawable.hagom_widget_bar_brown_pin
                                "pin_only" -> R.drawable.hagom_widget_pin_lavender
                                else -> R.drawable.hagom_widget_white_bg
                            }
                        }
                        setInt(
                            resId,
                            "setBackgroundResource",
                            if (isDark) darkCellBackground(status) else bgRes
                        )

                        // 🌟 [원터치 = 위젯 내 조회 / 투터치 = 앱 달력 해당 날짜로 즉시 진입]:
                        // 1) 다른 날짜: 1차 터치 시 선택(보라 테두리) -> 2차 터치 시 앱의 그날 달력으로 즉시 진입!
                        // 2) 오늘 날짜:
                        //    - 다른 날짜를 보다가 오늘을 터치하면: 오늘 날짜로 위젯 복귀 (selectedDateStr == cellDate 또는 초기화)
                        //    - 이미 오늘을 보고 있는 상태(기본 상태이거나 오늘이 선택된 상태)에서 오늘을 터치하면: 앱의 오늘 달력으로 즉시 진입!
                        val isTodayCell = (todayIso.isNotEmpty() && cellDate == todayIso) || status.startsWith("today")
                        val shouldOpenApp = if (isTodayCell) {
                            // 다른 날짜를 조회 중이 아닐 때(기본 오늘 상태) 오늘을 터치하거나, 오늘이 명시적으로 선택되었을 때 앱 열기!
                            !hasSelectedOtherDay || (selectedDateStr == cellDate)
                        } else {
                            isDaySelected
                        }
                        val cellPending = if (shouldOpenApp) {
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

                // 스마트 라우팅 (오늘 아닌 날짜가 선택되었을 땐 어디 눌러도 달력 탭 해당 날짜로 직행)
                val calTargetUri = if (hasSelectedOtherDay) {
                    "hagomwidget://opencalendar?date=$inspectingIso"
                } else {
                    "hagomwidget://opencalendar"
                }
                val calIntent = WidgetBindings.openAppIntent(context, calTargetUri, 1005)
                setOnClickPendingIntent(R.id.widget_month_tasks_header, calIntent)

                val medsIntent = WidgetBindings.openAppIntent(context, "hagomwidget://openmeds", 1001)
                val habitsIntent = WidgetBindings.openAppIntent(context, "hagomwidget://openhabits", 1002)

                setOnClickPendingIntent(R.id.widget_month_meds_box, medsIntent)
                setOnClickPendingIntent(R.id.widget_month_habits_box, habitsIntent)
                // 제목 영역만 달력 화면으로 연결하고, 하곰이와 빈 공간은 클릭하지 않는다.
                setOnClickPendingIntent(R.id.widget_month_title, calIntent)
            }
            WidgetBindings.applyTheme(
                views, widgetData, R.id.widget_month_container,
                listOf(R.id.widget_month_title, R.id.widget_month_meds, R.id.widget_month_habits,
                    R.id.widget_month_tasks_label, R.id.widget_month_tasks)
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
