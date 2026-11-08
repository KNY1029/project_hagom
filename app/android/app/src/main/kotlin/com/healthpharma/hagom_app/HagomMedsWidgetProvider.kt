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
            val isNarrow = WidgetBindings.isNarrowWidth(appWidgetManager, appWidgetId)
            val maxRows = WidgetBindings.maxFittingRows(appWidgetManager, appWidgetId)
            val allDone = widgetData.getString("meds_all_done", "false") == "true"
            val views = RemoteViews(context.packageName, R.layout.hagom_meds_widget).apply {
                val openMedsIntent = WidgetBindings.openAppIntent(context, "hagomwidget://openmeds", 1001)
                // 위젯 전체 영역(버튼 제외) 어디를 탭해도 복약 탭으로 부드럽게 이동
                setOnClickPendingIntent(R.id.widget_meds_container, openMedsIntent)
                setOnClickPendingIntent(R.id.widget_meds_info_area, openMedsIntent)
                setOnClickPendingIntent(R.id.widget_meds_title, openMedsIntent)
                setOnClickPendingIntent(R.id.widget_meds_tag, openMedsIntent)
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

                    setInt(R.id.widget_meds_btn, "setBackgroundResource", R.drawable.hagom_widget_btn_bg)
                    setTextColor(R.id.widget_meds_btn_title, Color.WHITE)
                    setInt(R.id.widget_meds_btn_compact, "setBackgroundResource", R.drawable.hagom_widget_btn_bg)
                    setTextColor(R.id.widget_meds_btn_compact_title, Color.WHITE)

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
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
