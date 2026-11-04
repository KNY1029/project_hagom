package com.healthpharma.hagom_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HagomHabitsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hagom_habits_widget).apply {
                setTextViewText(R.id.widget_habits_tag, WidgetBindings.text(widgetData, "habits_tag"))
                setTextViewText(R.id.widget_habits_progress, WidgetBindings.text(widgetData, "habits_progress"))
                setTextViewText(R.id.widget_habits_title, WidgetBindings.text(widgetData, "habits_title"))
                setTextViewText(R.id.widget_habits_subtitle, WidgetBindings.text(widgetData, "habits_subtitle"))

                val btnTitle = WidgetBindings.text(widgetData, "habits_btn_title")
                setTextViewText(R.id.widget_habits_btn_title, btnTitle)

                val state = WidgetBindings.text(widgetData, "habits_state")
                when (state) {
                    "done" -> {
                        setInt(R.id.widget_habits_btn, "setBackgroundResource", R.drawable.hagom_widget_green_btn_bg)
                        setTextColor(R.id.widget_habits_btn_title, Color.parseColor("#1B6B46"))
                    }
                    "partial" -> {
                        setInt(R.id.widget_habits_btn, "setBackgroundResource", R.drawable.hagom_widget_brown_btn_bg)
                        setTextColor(R.id.widget_habits_btn_title, Color.parseColor("#8B5E3C"))
                    }
                    else -> {
                        setInt(R.id.widget_habits_btn, "setBackgroundResource", R.drawable.hagom_widget_habit_btn_bg)
                        setTextColor(R.id.widget_habits_btn_title, Color.WHITE)
                    }
                }

                setOnClickPendingIntent(
                    R.id.widget_habits_container,
                    WidgetBindings.openAppIntent(context, "hagomwidget://openhabits", 1002)
                )

                val mainAction = WidgetBindings.text(widgetData, "habits_action")
                if (mainAction.isNotEmpty()) {
                    setOnClickPendingIntent(R.id.widget_habits_btn, WidgetBindings.actionIntent(context, mainAction))
                } else {
                    setOnClickPendingIntent(
                        R.id.widget_habits_btn,
                        WidgetBindings.openAppIntent(context, "hagomwidget://openhabits", 1002)
                    )
                }

                val rowIds = listOf(
                    Triple(R.id.habits_row_1, R.id.habits_row_1_text, R.id.habits_row_1_btn),
                    Triple(R.id.habits_row_2, R.id.habits_row_2_text, R.id.habits_row_2_btn),
                    Triple(R.id.habits_row_3, R.id.habits_row_3_text, R.id.habits_row_3_btn),
                    Triple(R.id.habits_row_4, R.id.habits_row_4_text, R.id.habits_row_4_btn)
                )
                rowIds.forEachIndexed { idx, (rowId, textId, btnId) ->
                    val n = idx + 1
                    WidgetBindings.bindRow(
                        this, widgetData, context,
                        rowId, textId, btnId,
                        "habits_row_${n}_text",
                        "habits_row_${n}_done",
                        "habits_row_${n}_action",
                        "실천",
                        R.drawable.hagom_widget_habit_btn_bg
                    )
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
