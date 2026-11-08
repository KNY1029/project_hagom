package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class HagomCalendarWidgetProvider : HomeWidgetProvider() {

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
        val targetIds = if (appWidgetIds.isEmpty()) {
            appWidgetManager.getAppWidgetIds(ComponentName(context, HagomCalendarWidgetProvider::class.java))
        } else {
            appWidgetIds
        }

        for (appWidgetId in targetIds) {
            val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
            val is1x1 = (minW in 1..110)
            val openCalIntent = WidgetBindings.openAppIntent(context, "hagomwidget://opencalendar", 1003)

            val views = if (is1x1) {
                // 🌟 1x1 모드: 오늘 할일 몇 개 중 몇 개 완료했는지 표시 & 탭 시 달력(할일) 탭 열기
                RemoteViews(context.packageName, R.layout.hagom_calendar_widget_1x1).apply {
                    val progress = WidgetBindings.text(widgetData, "calendar_progress")
                    val state = WidgetBindings.text(widgetData, "calendar_state")
                    setTextViewText(R.id.widget_calendar_tag, "할일")
                    setTextViewText(R.id.widget_calendar_progress, progress)
                    setTextViewText(R.id.widget_calendar_status, if (state == "done") "완료" else "진행 중")
                    setOnClickPendingIntent(R.id.widget_calendar_container, openCalIntent)
                }
            } else {
                val isNarrow = WidgetBindings.isNarrowWidth(appWidgetManager, appWidgetId)
                val maxRows = WidgetBindings.maxFittingRows(appWidgetManager, appWidgetId)

                RemoteViews(context.packageName, R.layout.hagom_calendar_widget).apply {
                    setViewVisibility(R.id.calendar_celebration_view, View.GONE)
                    setViewVisibility(R.id.calendar_normal_view, View.VISIBLE)
                setViewVisibility(R.id.widget_calendar_tag, if (isNarrow) View.GONE else View.VISIBLE)
                setTextViewText(R.id.widget_calendar_tag, WidgetBindings.text(widgetData, "calendar_tag"))
                setTextViewText(R.id.widget_calendar_progress, WidgetBindings.text(widgetData, "calendar_progress"))
                setTextViewText(R.id.widget_calendar_title, WidgetBindings.text(widgetData, "calendar_title"))

                val tasksColorHex = widgetData.getString("theme_tasks_color", "#7B61A8") ?: "#B58A32"
                setTextColor(R.id.widget_calendar_tag, Color.parseColor(tasksColorHex))
                val sub = if (isNarrow) {
                    WidgetBindings.text(widgetData, "calendar_subtitle_short").ifEmpty {
                        WidgetBindings.text(widgetData, "calendar_subtitle")
                    }
                } else {
                    WidgetBindings.text(widgetData, "calendar_subtitle")
                }
                setTextViewText(R.id.widget_calendar_subtitle, sub)

                val btnTitle = WidgetBindings.text(widgetData, "calendar_btn_title")
                setTextViewText(R.id.widget_calendar_btn_title, btnTitle)
                setTextViewText(R.id.widget_calendar_btn_compact_title, btnTitle)

                setViewVisibility(R.id.widget_calendar_btn, if (isNarrow) View.GONE else View.VISIBLE)
                setViewVisibility(R.id.widget_calendar_btn_compact, if (isNarrow) View.VISIBLE else View.GONE)

                val allDone = widgetData.getString("calendar_all_done", "false") == "true"
                val bgRes = if (allDone) R.drawable.hagom_widget_green_btn_bg else R.drawable.hagom_widget_task_btn_bg
                val txtColor = if (allDone) Color.parseColor("#1B6B46") else Color.WHITE
                setInt(R.id.widget_calendar_btn, "setBackgroundResource", bgRes)
                setTextColor(R.id.widget_calendar_btn_title, txtColor)
                setInt(R.id.widget_calendar_btn_compact, "setBackgroundResource", bgRes)
                setTextColor(R.id.widget_calendar_btn_compact_title, txtColor)

                val openCalIntent = WidgetBindings.openAppIntent(context, "hagomwidget://opencalendar", 1003)
                // 위젯 전체 영역(버튼 제외) 어디를 탭해도 달력 탭으로 부드럽게 이동
                setOnClickPendingIntent(R.id.widget_calendar_container, openCalIntent)
                setOnClickPendingIntent(R.id.widget_calendar_info_area, openCalIntent)
                setOnClickPendingIntent(R.id.widget_calendar_title, openCalIntent)
                setOnClickPendingIntent(R.id.widget_calendar_tag, openCalIntent)

                val mainAction = WidgetBindings.text(widgetData, "calendar_action")
                val btnPending = if (mainAction.isNotEmpty()) {
                    WidgetBindings.actionIntent(context, mainAction)
                } else {
                    // 🌟 할일이 없어서 [열기] 상태이거나 액션이 없을 때는 탭 시 달력 탭(앱)으로 즉시 열기!
                    openCalIntent
                }
                setOnClickPendingIntent(R.id.widget_calendar_btn, btnPending)
                setOnClickPendingIntent(R.id.widget_calendar_btn_compact, btnPending)
                setViewVisibility(R.id.calendar_expanded_list, if (maxRows > 0) View.VISIBLE else View.GONE)

                val rowIds = listOf(
                    Triple(R.id.cal_row_1, R.id.cal_row_1_text, R.id.cal_row_1_btn),
                    Triple(R.id.cal_row_2, R.id.cal_row_2_text, R.id.cal_row_2_btn),
                    Triple(R.id.cal_row_3, R.id.cal_row_3_text, R.id.cal_row_3_btn),
                    Triple(R.id.cal_row_4, R.id.cal_row_4_text, R.id.cal_row_4_btn),
                    Triple(R.id.cal_row_5, R.id.cal_row_5_text, R.id.cal_row_5_btn),
                    Triple(R.id.cal_row_6, R.id.cal_row_6_text, R.id.cal_row_6_btn)
                )
                rowIds.forEachIndexed { idx, (rowId, textId, btnId) ->
                    val n = idx + 1
                    WidgetBindings.bindRow(
                        this, widgetData, context,
                        rowId, textId, btnId,
                        "cal_row_${n}_text",
                        "cal_row_${n}_short",
                        "cal_row_${n}_done",
                        "cal_row_${n}_action",
                        "체크",
                        R.drawable.hagom_widget_task_btn_bg,
                        isNarrow,
                        allowCompletedToggle = true,
                        allowShow = idx < maxRows
                    )
                }
            }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
