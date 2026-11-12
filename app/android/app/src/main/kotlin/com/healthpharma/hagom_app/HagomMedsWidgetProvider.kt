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

class HagomMedsWidgetProvider : HomeWidgetProvider() {

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
            appWidgetManager.getAppWidgetIds(ComponentName(context, HagomMedsWidgetProvider::class.java))
        } else {
            appWidgetIds
        }

        for (appWidgetId in targetIds) {
            val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
            val is1x1 = (minW in 1..125) // 1x1 모드 판정
            val allDone = widgetData.getString("meds_all_done", "false") == "true"
            val openMedsIntent = WidgetBindings.openAppIntent(context, "hagomwidget://openmeds", 1001)

            val views = if (is1x1) {
                // 🌟 1x1 모드: "몇 개 중 몇 개 했는지" 심플 표시 & 탭 시 복약 탭 열기
                RemoteViews(context.packageName, R.layout.hagom_meds_widget_1x1).apply {
                    val progress = WidgetBindings.text(widgetData, "meds_progress")
                    setTextViewText(R.id.widget_meds_tag, "복약")
                    setTextViewText(R.id.widget_meds_progress, progress)
                    setTextViewText(R.id.widget_meds_status, if (allDone) "완료" else "복용 중")
                    setOnClickPendingIntent(R.id.widget_meds_container, openMedsIntent)
                }
            } else {
                val isNarrow = WidgetBindings.isNarrowWidth(appWidgetManager, appWidgetId)
                val maxRows = WidgetBindings.maxFittingRows(appWidgetManager, appWidgetId)
                RemoteViews(context.packageName, R.layout.hagom_meds_widget).apply {
                    // 🌟 [터치 오작동 방지]: 위젯 전체(container)에 걸려있던 전체 클릭을 제거하고,
                    // 버튼 주변 빈 공간을 눌러도 앱으로 튀지 않도록 오직 좌측 텍스트 정보 영역(info_area)을 눌렀을 때만 앱으로 이동!
                    setOnClickPendingIntent(R.id.widget_meds_info_area, openMedsIntent)
                    setOnClickPendingIntent(R.id.meds_celebration_view, openMedsIntent)
                if (allDone) {
                    setViewVisibility(R.id.meds_celebration_view, View.VISIBLE)
                    setViewVisibility(R.id.meds_normal_view, View.GONE)
                    val progress = WidgetBindings.text(widgetData, "meds_progress")
                    setTextViewText(R.id.meds_celebration_badge, "오늘 복약 완료 ($progress)")
                } else {
                    setViewVisibility(R.id.meds_celebration_view, View.GONE)
                    setViewVisibility(R.id.meds_normal_view, View.VISIBLE)

                    setViewVisibility(R.id.widget_meds_tag, if (isNarrow) View.GONE else View.VISIBLE)
                    setTextViewText(R.id.widget_meds_tag, WidgetBindings.text(widgetData, "meds_tag"))
                    setTextViewText(R.id.widget_meds_progress, WidgetBindings.text(widgetData, "meds_progress"))
                    setTextViewText(R.id.widget_meds_title, WidgetBindings.text(widgetData, "meds_title"))

                    val medsColorHex = widgetData.getString("theme_meds_color", "#7B61A8") ?: "#7B61A8"
                    setTextColor(R.id.widget_meds_tag, Color.parseColor(medsColorHex))
                    val sub = if (isNarrow) {
                        WidgetBindings.text(widgetData, "meds_subtitle_short").ifEmpty {
                            WidgetBindings.text(widgetData, "meds_subtitle")
                        }
                    } else {
                        WidgetBindings.text(widgetData, "meds_subtitle")
                    }
                    setTextViewText(R.id.widget_meds_subtitle, sub)

                    val btnTitle = WidgetBindings.text(widgetData, "meds_btn_title")
                    setTextViewText(R.id.widget_meds_btn_title, btnTitle)
                    setTextViewText(R.id.widget_meds_btn_compact_title, btnTitle)

                    setViewVisibility(R.id.widget_meds_btn, if (isNarrow) View.GONE else View.VISIBLE)
                    setViewVisibility(R.id.widget_meds_btn_compact, if (isNarrow) View.VISIBLE else View.GONE)

                    // 🌟 복용 완료 시 보라색이 아닌 초록색 완료 버튼(배경 #EAF8F1, 텍스트 #1B6B46)으로 즉시 반영!
                    val isBtnDone = (btnTitle == "완료" || allDone)
                    val isColorVision = widgetData.getString("theme_color_vision", "false") == "true"
                    val bgRes = if (isBtnDone) {
                        if (isColorVision) R.drawable.hagom_widget_blue_btn_bg else R.drawable.hagom_widget_green_btn_bg
                    } else R.drawable.hagom_widget_btn_bg
                    val txtColor = if (isBtnDone) Color.parseColor(if (isColorVision) "#1D4ED8" else "#1B6B46") else Color.WHITE

                    setInt(R.id.widget_meds_btn, "setBackgroundResource", bgRes)
                    setTextColor(R.id.widget_meds_btn_title, txtColor)
                    setInt(R.id.widget_meds_btn_compact, "setBackgroundResource", bgRes)
                    setTextColor(R.id.widget_meds_btn_compact_title, txtColor)
                    val mainAction = WidgetBindings.text(widgetData, "meds_action")
                    val btnPending = if (mainAction.isNotEmpty()) {
                        WidgetBindings.actionIntent(context, mainAction)
                    } else {
                        // 약이 없어서 [열기]이거나 완료 상태일 때는 복약 탭(앱)으로 열기!
                        openMedsIntent
                    }
                    setOnClickPendingIntent(R.id.widget_meds_btn, btnPending)
                    setOnClickPendingIntent(R.id.widget_meds_btn_compact, btnPending)

                    setViewVisibility(R.id.meds_expanded_list, if (maxRows > 0) View.VISIBLE else View.GONE)

                    val rowIds = listOf(
                        Triple(R.id.meds_row_1, R.id.meds_row_1_text, R.id.meds_row_1_btn),
                        Triple(R.id.meds_row_2, R.id.meds_row_2_text, R.id.meds_row_2_btn),
                        Triple(R.id.meds_row_3, R.id.meds_row_3_text, R.id.meds_row_3_btn),
                        Triple(R.id.meds_row_4, R.id.meds_row_4_text, R.id.meds_row_4_btn),
                        Triple(R.id.meds_row_5, R.id.meds_row_5_text, R.id.meds_row_5_btn),
                        Triple(R.id.meds_row_6, R.id.meds_row_6_text, R.id.meds_row_6_btn)
                    )
                    rowIds.forEachIndexed { idx, (rowId, textId, btnId) ->
                        val n = idx + 1
                        WidgetBindings.bindRow(
                            this, widgetData, context,
                            rowId, textId, btnId,
                            "meds_row_${n}_text",
                            "meds_row_${n}_short",
                            "meds_row_${n}_done",
                            "meds_row_${n}_action",
                            "복용",
                            R.drawable.hagom_widget_btn_bg,
                            isNarrow,
                            allowCompletedToggle = false,
                            allowShow = idx < maxRows
                        )
                    }
                }
            }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
