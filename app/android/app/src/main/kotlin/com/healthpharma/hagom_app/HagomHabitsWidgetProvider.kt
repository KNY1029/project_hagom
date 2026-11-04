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

class HagomHabitsWidgetProvider : HomeWidgetProvider() {

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
            val isNarrow = WidgetBindings.isNarrowWidth(appWidgetManager, appWidgetId)
            val maxRows = WidgetBindings.maxFittingRows(appWidgetManager, appWidgetId)
            val allDone = widgetData.getString("habits_all_done", "false") == "true"

            val views = RemoteViews(context.packageName, R.layout.hagom_habits_widget).apply {
                val openHabitsIntent = WidgetBindings.openAppIntent(context, "hagomwidget://openhabits", 1002)
                // 위젯 전체 영역(버튼 제외) 어디를 탭해도 습관 탭으로 부드럽게 이동
                setOnClickPendingIntent(R.id.widget_habits_container, openHabitsIntent)
                setOnClickPendingIntent(R.id.widget_habits_info_area, openHabitsIntent)
                setOnClickPendingIntent(R.id.widget_habits_title, openHabitsIntent)
                setOnClickPendingIntent(R.id.widget_habits_tag, openHabitsIntent)
                setOnClickPendingIntent(R.id.habits_celebration_view, openHabitsIntent)

                if (allDone) {
                    setViewVisibility(R.id.habits_celebration_view, View.VISIBLE)
                    setViewVisibility(R.id.habits_normal_view, View.GONE)
                    val progress = WidgetBindings.text(widgetData, "habits_progress")
                    setTextViewText(R.id.habits_celebration_badge, "오늘 습관 달성 ($progress)")
                } else {
                    setViewVisibility(R.id.habits_celebration_view, View.GONE)
                    setViewVisibility(R.id.habits_normal_view, View.VISIBLE)

                    setViewVisibility(R.id.widget_habits_tag, if (isNarrow) View.GONE else View.VISIBLE)
                    setTextViewText(R.id.widget_habits_tag, WidgetBindings.text(widgetData, "habits_tag"))
                    setTextViewText(R.id.widget_habits_progress, WidgetBindings.text(widgetData, "habits_progress"))
                    setTextViewText(R.id.widget_habits_title, WidgetBindings.text(widgetData, "habits_title"))

                    val sub = if (isNarrow) {
                        WidgetBindings.text(widgetData, "habits_subtitle_short").ifEmpty {
                            WidgetBindings.text(widgetData, "habits_subtitle")
                        }
                    } else {
                        WidgetBindings.text(widgetData, "habits_subtitle")
                    }
                    setTextViewText(R.id.widget_habits_subtitle, sub)

                    val btnTitle = WidgetBindings.text(widgetData, "habits_btn_title")
                    setTextViewText(R.id.widget_habits_btn_title, btnTitle)
                    setTextViewText(R.id.widget_habits_btn_compact_title, btnTitle)

                    setViewVisibility(R.id.widget_habits_btn, if (isNarrow) View.GONE else View.VISIBLE)
                    setViewVisibility(R.id.widget_habits_btn_compact, if (isNarrow) View.VISIBLE else View.GONE)

                    val state = WidgetBindings.text(widgetData, "habits_state")
                    val (bgRes, txtColor) = when (state) {
                        "done" -> R.drawable.hagom_widget_green_btn_bg to Color.parseColor("#1B6B46")
                        "partial" -> R.drawable.hagom_widget_brown_btn_bg to Color.parseColor("#8B5E3C")
                        else -> R.drawable.hagom_widget_habit_btn_bg to Color.WHITE
                    }
                    setInt(R.id.widget_habits_btn, "setBackgroundResource", bgRes)
                    setTextColor(R.id.widget_habits_btn_title, txtColor)
                    setInt(R.id.widget_habits_btn_compact, "setBackgroundResource", bgRes)
                    setTextColor(R.id.widget_habits_btn_compact_title, txtColor)

                    val mainAction = WidgetBindings.text(widgetData, "habits_action")
                    val btnPending = if (state != "done" && mainAction.isNotEmpty()) {
                        WidgetBindings.actionIntent(context, mainAction)
                    } else {
                        WidgetBindings.noopIntent(context)
                    }
                    setOnClickPendingIntent(R.id.widget_habits_btn, btnPending)
                    setOnClickPendingIntent(R.id.widget_habits_btn_compact, btnPending)

                    setViewVisibility(R.id.habits_expanded_list, if (maxRows > 0) View.VISIBLE else View.GONE)

                    val rowIds = listOf(
                        Triple(R.id.habits_row_1, R.id.habits_row_1_text, R.id.habits_row_1_btn),
                        Triple(R.id.habits_row_2, R.id.habits_row_2_text, R.id.habits_row_2_btn),
                        Triple(R.id.habits_row_3, R.id.habits_row_3_text, R.id.habits_row_3_btn),
                        Triple(R.id.habits_row_4, R.id.habits_row_4_text, R.id.habits_row_4_btn),
                        Triple(R.id.habits_row_5, R.id.habits_row_5_text, R.id.habits_row_5_btn),
                        Triple(R.id.habits_row_6, R.id.habits_row_6_text, R.id.habits_row_6_btn)
                    )
                    rowIds.forEachIndexed { idx, (rowId, textId, btnId) ->
                        val n = idx + 1
                        WidgetBindings.bindRow(
                            this, widgetData, context,
                            rowId, textId, btnId,
                            "habits_row_${n}_text",
                            "habits_row_${n}_short",
                            "habits_row_${n}_done",
                            "habits_row_${n}_action",
                            "실천",
                            R.drawable.hagom_widget_habit_btn_bg,
                            isNarrow,
                            allowCompletedToggle = false,
                            allowShow = idx < maxRows
                        )
                    }
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
