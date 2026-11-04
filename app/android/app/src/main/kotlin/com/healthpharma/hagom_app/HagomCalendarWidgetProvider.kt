package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HagomCalendarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_calendar_widget).apply {
                setTextViewText(R.id.widget_calendar_tag, WidgetBindings.text(widgetData, "calendar_tag"))
                setTextViewText(R.id.widget_calendar_progress, WidgetBindings.text(widgetData, "calendar_progress"))
                setTextViewText(R.id.widget_calendar_title, WidgetBindings.text(widgetData, "calendar_title"))
                setTextViewText(R.id.widget_calendar_subtitle, WidgetBindings.text(widgetData, "calendar_subtitle"))

                val btnTitle = WidgetBindings.text(widgetData, "calendar_btn_title")
                setTextViewText(R.id.widget_calendar_btn_title, btnTitle)

                val allDone = widgetData.getString("calendar_all_done", "false") == "true"
                if (allDone) {
                    setInt(R.id.widget_calendar_btn, "setBackgroundResource", R.drawable.hagom_widget_green_btn_bg)
                    setTextColor(R.id.widget_calendar_btn_title, Color.parseColor("#1B6B46"))
                } else {
                    setInt(R.id.widget_calendar_btn, "setBackgroundResource", R.drawable.hagom_widget_task_btn_bg)
                    setTextColor(R.id.widget_calendar_btn_title, Color.WHITE)
                }

                setOnClickPendingIntent(
                    R.id.widget_calendar_container,
                    WidgetBindings.openAppIntent(context, "hagomwidget://opencalendar", 1003)
                )

                val mainAction = WidgetBindings.text(widgetData, "calendar_action")
                if (mainAction.isNotEmpty()) {
                    setOnClickPendingIntent(R.id.widget_calendar_btn, WidgetBindings.actionIntent(context, mainAction))
                } else {
                    setOnClickPendingIntent(
                        R.id.widget_calendar_btn,
                        WidgetBindings.openAppIntent(context, "hagomwidget://opencalendar", 1003)
                    )
                }

                val rowIds = listOf(
                    Triple(R.id.cal_row_1, R.id.cal_row_1_text, R.id.cal_row_1_btn),
                    Triple(R.id.cal_row_2, R.id.cal_row_2_text, R.id.cal_row_2_btn),
                    Triple(R.id.cal_row_3, R.id.cal_row_3_text, R.id.cal_row_3_btn)
                )
                rowIds.forEachIndexed { idx, (rowId, textId, btnId) ->
                    val n = idx + 1
                    WidgetBindings.bindRow(
                        this, widgetData, context,
                        rowId, textId, btnId,
                        "cal_row_${n}_text",
                        "cal_row_${n}_done",
                        "cal_row_${n}_action",
                        "체크",
                        R.drawable.hagom_widget_task_btn_bg
                    )
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
