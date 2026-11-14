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
        val targetIds = if (appWidgetIds.isEmpty()) {
            appWidgetManager.getAppWidgetIds(ComponentName(context, HagomHabitsWidgetProvider::class.java))
        } else {
            appWidgetIds
        }

        for (appWidgetId in targetIds) {
            val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
            val is1x1 = (minW in 1..125)
            val allDone = widgetData.getString("habits_all_done", "false") == "true"
            val openHabitsIntent = WidgetBindings.openAppIntent(context, "hagomwidget://openhabits", 1002)

            val views = if (is1x1) {
                // 🌟 1x1 모드: 습관 몇 개 중 몇 개 실천했는지 표시 & 탭 시 습관 탭 열기
                RemoteViews(context.packageName, R.layout.hagom_habits_widget_1x1).apply {
                    val progress = WidgetBindings.text(widgetData, "habits_progress")
                    setTextViewText(R.id.widget_habits_tag, "습관")
                    setTextViewText(R.id.widget_habits_progress, progress)
                    setTextViewText(R.id.widget_habits_status, if (allDone) "완료" else "실천 중")
                    setOnClickPendingIntent(R.id.widget_habits_container, openHabitsIntent)
                }
            } else {
                val isNarrow = WidgetBindings.isNarrowWidth(appWidgetManager, appWidgetId)
                val maxRows = WidgetBindings.maxFittingRows(appWidgetManager, appWidgetId)
                RemoteViews(context.packageName, R.layout.hagom_habits_widget).apply {
                    // 🌟 [터치 오작동 방지]: 위젯 전체(container)에 걸려있던 전체 클릭을 제거하고,
                    // 버튼 주변 빈 공간을 눌러도 앱으로 튀지 않도록 오직 좌측 텍스트 정보 영역(info_area)을 눌렀을 때만 앱으로 이동!
                    setOnClickPendingIntent(R.id.widget_habits_info_area, openHabitsIntent)
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

                    val habitsColorHex = widgetData.getString("theme_habits_color", "#7B61A8") ?: "#8B5E3C"
                    setTextColor(R.id.widget_habits_tag, Color.parseColor(habitsColorHex))
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
                    val isColorVision = widgetData.getString("theme_color_vision", "false") == "true"
                    val (bgRes, txtColor) = when (state) {
                        "done" -> (if (isColorVision) R.drawable.hagom_widget_blue_btn_bg else R.drawable.hagom_widget_green_btn_bg) to Color.parseColor(if (isColorVision) "#1D4ED8" else "#1B6B46")
                        "partial" -> R.drawable.hagom_widget_brown_btn_bg to Color.parseColor("#8B5E3C")
                        else -> R.drawable.hagom_widget_gray_btn_bg to Color.parseColor("#6B7280")
                    }
                    setInt(R.id.widget_habits_btn, "setBackgroundResource", bgRes)
                    setTextColor(R.id.widget_habits_btn_title, txtColor)
                    setInt(R.id.widget_habits_btn_compact, "setBackgroundResource", bgRes)
                    setTextColor(R.id.widget_habits_btn_compact_title, txtColor)

                    val mainAction = WidgetBindings.text(widgetData, "habits_action")
                    val btnPending = if (state != "done" && mainAction.isNotEmpty()) {
                        WidgetBindings.actionIntent(context, mainAction)
                    } else {
                        // 습관이 없어서 [열기]이거나 완료 상태일 때는 습관 탭(앱)으로 열기!
                        openHabitsIntent
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
                            "대기",
                            R.drawable.hagom_widget_gray_btn_bg,
                            isNarrow,
                            allowCompletedToggle = false,
                            allowShow = idx < maxRows,
                            customBtnLabelKey = "habits_row_${n}_btn_label",
                            customBtnStateKey = "habits_row_${n}_state"
                        )
                    }
                }
            }
            }
            WidgetBindings.applyTheme(
                views, widgetData, R.id.widget_habits_container,
                listOf(R.id.widget_habits_tag, R.id.widget_habits_progress, R.id.widget_habits_title,
                    R.id.widget_habits_subtitle, R.id.widget_habits_status)
            )
            if (widgetData.getString("theme_dark", "false") == "true" && !is1x1) {
                views.setInt(R.id.widget_habits_tag, "setBackgroundResource", R.drawable.hagom_widget_tag_bg_dark)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
