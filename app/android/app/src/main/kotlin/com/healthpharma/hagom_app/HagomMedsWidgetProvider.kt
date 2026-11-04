package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HagomMedsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_meds_widget).apply {
                setTextViewText(R.id.widget_meds_tag, WidgetBindings.text(widgetData, "meds_tag"))
                setTextViewText(R.id.widget_meds_progress, WidgetBindings.text(widgetData, "meds_progress"))
                setTextViewText(R.id.widget_meds_title, WidgetBindings.text(widgetData, "meds_title"))
                setTextViewText(R.id.widget_meds_subtitle, WidgetBindings.text(widgetData, "meds_subtitle"))

                val btnTitle = WidgetBindings.text(widgetData, "meds_btn_title")
                setTextViewText(R.id.widget_meds_btn_title, btnTitle)

                val allDone = widgetData.getString("meds_all_done", "false") == "true"
                if (allDone) {
                    setInt(R.id.widget_meds_btn, "setBackgroundResource", R.drawable.hagom_widget_green_btn_bg)
                    setTextColor(R.id.widget_meds_btn_title, Color.parseColor("#1B6B46"))
                } else {
                    setInt(R.id.widget_meds_btn, "setBackgroundResource", R.drawable.hagom_widget_btn_bg)
                    setTextColor(R.id.widget_meds_btn_title, Color.WHITE)
                }

                // 바탕 탭 -> 복약 탭으로 이동
                setOnClickPendingIntent(
                    R.id.widget_meds_container,
                    WidgetBindings.openAppIntent(context, "hagomwidget://openmeds", 1001)
                )

                // 대표 버튼 -> 실제 앱 데이터 변경
                val mainAction = WidgetBindings.text(widgetData, "meds_action")
                if (mainAction.isNotEmpty()) {
                    setOnClickPendingIntent(R.id.widget_meds_btn, WidgetBindings.actionIntent(context, mainAction))
                } else {
                    setOnClickPendingIntent(
                        R.id.widget_meds_btn,
                        WidgetBindings.openAppIntent(context, "hagomwidget://openmeds", 1001)
                    )
                }

                val rowIds = listOf(
                    Triple(R.id.meds_row_1, R.id.meds_row_1_text, R.id.meds_row_1_btn),
                    Triple(R.id.meds_row_2, R.id.meds_row_2_text, R.id.meds_row_2_btn),
                    Triple(R.id.meds_row_3, R.id.meds_row_3_text, R.id.meds_row_3_btn)
                )
                rowIds.forEachIndexed { idx, (rowId, textId, btnId) ->
                    val n = idx + 1
                    WidgetBindings.bindRow(
                        this, widgetData, context,
                        rowId, textId, btnId,
                        "meds_row_${n}_text",
                        "meds_row_${n}_done",
                        "meds_row_${n}_action",
                        "복용",
                        R.drawable.hagom_widget_btn_bg
                    )
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
